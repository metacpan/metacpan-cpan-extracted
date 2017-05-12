#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "const-c.inc"

#include "locatedb.h"

#include <config.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <time.h>
#include <fnmatch.h>
#include <regex.h>
#include <unistd.h>
#include <fcntl.h>

#define NDEBUG
#include <assert.h>

#ifdef STDC_HEADERS
#include <stdlib.h>
#else
char *getenv ();
#endif

#ifdef STDC_HEADERS
#include <errno.h>
#include <stdlib.h>
#else
extern int errno;
#endif


#define WARNING	    0
#define MIN_CHUNK   64
#define MIN_BLK	    4096
#define ALLOC_SIZE  4096
#define SLOC_ESC    -0x80

#ifndef call_sv
#   define call_sv perl_call_sv
#endif

uid_t UID;
gid_t GID;

typedef enum {false, true} boolean;

static char * last_literal_end (char *name) {
    static char *globfree = NULL;	/* A copy of the subpattern in NAME.  */
    static size_t gfalloc = 0;	    /* Bytes allocated for `globfree'.  */
    register char *subp;		    /* Return value.  */
    register char *p;		        /* Search location in NAME.  */

    /* Find the end of the subpattern.
     Skip trailing metacharacters and [] ranges. */
    for (p = name + strlen (name) - 1; 
         p >= name && strchr ("*?]", *p) != NULL;
         p--) {
        
        if (*p == ']')
            while (p >= name && *p != '[')
                p--;
    }
    
    if (p < name)
        p = name;

    if (p - name + 3 > gfalloc) {
        gfalloc = p - name + 3 + 64; /* Room to grow.  */
	Renew(globfree, gfalloc, char);
    }
    
    subp = globfree;
    *subp++ = '\0';

    /* If the pattern has only metacharacters, make every path match the
     subpattern, so it gets checked the slow way.  */
    if (p == name && strchr ("?*[]", *p) != NULL)
        *subp++ = '/';
    else {
        char *endmark;
        /* Find the start of the metacharacter-free subpattern.  */
        for (endmark = p; p >= name && strchr ("]*?", *p) == NULL; p--)
            ;
        /* Copy the subpattern into globfree.  */
        for (++p; p <= endmark; )
            *subp++ = *p++;
    }
    
    *subp-- = '\0';		/* Null terminate, though it's not needed.  */

    return subp;
}

int getstr (char **lineptr, size_t *n, FILE *stream, 
            char terminator, int offset) {
    int nchars_avail;		/* Allocated but unused chars in *LINEPTR.  */
    char *read_pos;		/* Where we're reading into *LINEPTR. */
    int ret;

    if (!lineptr || !n || !stream)
        return -1;

    if (!*lineptr) {
        *n = MIN_CHUNK;
	New(0, *lineptr, *n, char);
        if (!*lineptr)
            return -1;
    }

    nchars_avail = *n - offset;
    read_pos = *lineptr + offset;

    for (;;) {
        register int c = getc (stream);

        /* We always want at least one char left in the buffer, since we
           always (unless we get an error while reading the first char)
           NULL-terminate the line buffer.  */

        assert(*n - nchars_avail == read_pos - *lineptr);
        if (nchars_avail < 1) {
            if (*n > MIN_CHUNK)
                *n *= 2;
            else
                *n += MIN_CHUNK;

            nchars_avail = *n + *lineptr - read_pos;
            Renew(*lineptr, *n, char);
            if (!*lineptr)
                return -1;
            read_pos = *n - nchars_avail + *lineptr;
            assert(*n - nchars_avail == read_pos - *lineptr);
        }

        if (c == EOF || ferror (stream)) {
            /* Return partial line, if any.  */
            if (read_pos == *lineptr)
                return -1;
            else
                break;
        }

        *read_pos++ = c;
        nchars_avail--;

        if (c == terminator)
            /* Return the line.  */
            break;
    }

    /* Done - NUL terminate and return the number of chars read.  */
    *read_pos = '\0';

    ret = read_pos - (*lineptr + offset);
    return ret;
}

static int get_short (FILE *fp) {
    char x[2];
    fread((void*)&x, 2, 1, fp);
    return ((x[0]<<8)|(x[1]&0xff));
}

static int s_get_short (char **fp) {
    register short x;
    x = **fp;
    /* move pointer one byte ahead */
    (*fp)++;
    return (x << 8) | (*((*fp)++) & 0xff);
}
    
int check_path_access(char *codedpath) {
    char *dir = NULL;
    char *path = NULL;
    int res;
    char *str_ptr;

    if (access(codedpath, R_OK) != 0) {
	Safefree(codedpath);
	return 0;
    }

    New(0, path, strlen(codedpath)+1, char);
    *path = 0;

    res = 1;
    str_ptr = codedpath;

    while ((dir = strtok(str_ptr, "/"))) {
	strcat(path,"/");
	strcat(path,dir);
	if (access(path, R_OK) != 0) {
	    res = 0;
	    break;
	}
	str_ptr = NULL;
    }

    Safefree(codedpath);

    Safefree(path);

    return res;
}

void call_coderef (SV *coderef, char *path) {
    dSP;

    /* FIXME We aren't yet prepared for lexical $_ as coming in 5.9.1 */
    SAVESPTR(DEFSV);

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    DEFSV = sv_2mortal(newSVpvn(path, strlen(path)));
    PUTBACK;
    (void) call_sv(coderef, G_DISCARD);
    
    FREETMPS;
    LEAVE;
}
#define WARN fprintf(stderr, "%i\n", __LINE__);

MODULE = File::Locate		PACKAGE = File::Locate		

INCLUDE: const-xs.inc

BOOT:
    {
	UID = getuid();
	GID = getgid();
    }

void
_locate (pathpart, ...) 
        char *pathpart;
    PROTOTYPE: DISABLE
    PREINIT:
        char *dbfile = NULL;
        SV   *coderef = NULL;
        FILE *fp;           /* The pathname database.  */
        int c;              /* An input byte.  */
        int nread;          /* Number of bytes read from an entry.  */
        boolean globflag;   /* true if PATHPART contains globbing 
                               metacharacters.  */
        char *patend;       /* The end of the last glob-free subpattern 
                               in PATHPART.  */
        char *path;         /* The current input database entry.  */
        size_t pathsize;    /* Amount allocated for it.  */
        int count = 0;      /* The length of the prefix shared with 
                               the previous database entry.  */
        char *cutoff;       /* Where in `path' to stop the backward search for
                               the last character in the subpattern.  Set
                               according to `count'.  */
        boolean prev_fast_match = false;    /* true if we found a fast match
                                               (of patend) on the previous
                                               path.  */
        int printed = 0;                    /* The return value.  */
        boolean old_format = false;         /* true if reading a bigram-encoded
                                               database.  */
        char bigram1[128], bigram2[128];    /* For the old database format, the
                                               first and second characters of
                                               the most common bigrams.  */
	/* regex stuff */
	int REGEX = 0;
	int NOCASE = 0;
	int EXTENDED = 0;
	int reg_res;
	int nmatch = 32;
	regex_t *preg = NULL;
	char errbuf[1024];
	regmatch_t pmatch[32];
        STRLEN n_a;
	register int i;
    PPCODE:
    
	for (i = 1; i < items; i++) {
            if (SvROK(ST(i)) && SvTYPE((SV*)SvRV(ST(i))) == SVt_PVCV) {
                coderef = newSVsv(ST(i));
            }
            else {
		char *key = SvPV(ST(i), n_a);
		if (*key == '-') {
		    if (strnEQ(key+1, "rexopt", 6)) {
			char *val;
			i++;
			val = SvPV(ST(i), n_a);
			if (strchr(val, (int)'e'))
			    EXTENDED = 1;
			if (strchr(val, (int)'i'))
			    NOCASE = 1;
			continue;
		    }
		    else if (strnEQ(key+1, "rex", 3)) {
			i++;
			REGEX = SvTRUE(ST(i));
			continue;
		    }
		}
		if (!dbfile) {
		    dbfile = savepv(key);
		}
	    }
        }
    
	if (!dbfile) 
	    croak("No database (shouldn't happen)");

        if ((fp = fopen (dbfile, "r")) == NULL) 
            XSRETURN_UNDEF;

        pathsize = 1026;		/* Increased as necessary by getstr.  */
	New(0, path, pathsize, char);

        nread = fread (path, 1, sizeof (LOCATEDB_MAGIC), fp);
        if (nread != sizeof (LOCATEDB_MAGIC) || 
            memcmp (path, LOCATEDB_MAGIC, sizeof (LOCATEDB_MAGIC))) {
            int i;
            /* Read the list of the most common bigrams in the database.  */
            fseek (fp, 0, 0);
            for (i = 0; i < 128; i++) {
                bigram1[i] = getc (fp);
                bigram2[i] = getc (fp);
            }
            old_format = true;
        }

        globflag =  strchr (pathpart, '*') || 
                    strchr (pathpart, '?') || 
                    strchr (pathpart, '[');

        patend = last_literal_end (pathpart);
	
	if (REGEX) {
	    int flags = 0;
	    if (EXTENDED)
		flags |= REG_EXTENDED;
	    if (NOCASE)
		flags |= REG_ICASE;
	    New(0, preg, 1, regex_t);
	    if ((reg_res = regcomp(preg, pathpart, flags)) != 0) {
		    regerror(reg_res, preg, errbuf,1024);
		    croak("Invalid regular expression: %s\n", errbuf);
	    }
	}

        c = getc (fp);
	
        while (c != EOF) {
            register char *s;		/* Scan the path we read in.  */

            if (old_format) {
                /* Get the offset in the path where this path info starts.  */
                if (c == LOCATEDB_OLD_ESCAPE)
                    count += getw (fp) - LOCATEDB_OLD_OFFSET;
                else
                    count += c - LOCATEDB_OLD_OFFSET;

                /* Overlay the old path with the remainder of the new.  */
                for (s = path + count; (c = getc (fp)) > LOCATEDB_OLD_ESCAPE;)
                    if (c < 0200)
                        *s++ = c;		/* An ordinary character.  */
                    else {
                        /* Bigram markers have the high bit set. */
                        c &= 0177;
                        *s++ = bigram1[c];
                        *s++ = bigram2[c];
                    }
                *s-- = '\0';
            }
            else {
                if (c == LOCATEDB_ESCAPE)
                    count += get_short (fp);
                else if (c > 127)
                    count += c - 256;
                else
                    count += c;

                /* Overlay the old path with the remainder of the new.  */
                nread = getstr (&path, &pathsize, fp, '\0', count);
                if (nread < 0)
                    break;
                c = getc (fp);
                /* Move to the last char in path. */
                s = path + count + nread - 2; 
                assert (s[0] != '\0');
                assert (s[1] == '\0'); /* Our terminator.  */
                assert (s[2] == '\0'); /* Added by getstr.  */
            }

            /* If the previous path matched, scan the whole path for the last
               char in the subpattern.  If not, the shared prefix doesn't match
               the pattern, so don't scan it for the last char.  */
            cutoff = prev_fast_match ? path : path + count;
	    
	    if (REGEX) {
		if (regexec(preg,path,nmatch,pmatch,0) == 0) {
		    ++printed;
		    if (coderef) {
			call_coderef(coderef, path);
		    }
		    else if (GIMME_V == G_ARRAY) 
			XPUSHs(sv_2mortal(newSVpvn(path, strlen(path))));
		    else {
                        goto clean_up;
		    }
		}
	    }
	    else {
		
		/* Search backward starting at the end of the path we just read in,
		   for the character at the end of the last glob-free subpattern in
		   PATHPART.  */
		for (prev_fast_match = false; s >= cutoff; s--) {
		    /* Fast first char check. */
		    if (*s == *patend) {
			char *s2;		/* Scan the path we read in. */
			register char *p2;	/* Scan `patend'.  */

			for (s2 = s - 1, p2 = patend - 1; 
			     *p2 != '\0' && *s2 == *p2;
			     s2--, p2--)
			    ;
			if (*p2 == '\0') {
			    /* Success on the fast match.  Compare the whole pattern
			       if it contains globbing characters.  */
			    prev_fast_match = true;
			    
			    if (globflag == false || 
				    fnmatch (pathpart, path, 0) == 0) {
                                printed++;
				if (coderef) {
				    call_coderef(coderef, path);
				}
				else if (GIMME_V == G_ARRAY) {
				    XPUSHs(sv_2mortal(newSVpvn(path, strlen(path))));
				}
				else {
                                    goto clean_up;
				}
			    }
			    break;
			}
		    }
		}
	    } /* else (fnmatch)*/
        }
clean_up:
	if (preg) {
	    regfree(preg);
            Safefree(preg);
        }
	
	Safefree(dbfile);
        Safefree(path);

        fclose(fp);
        
        if(GIMME_V == G_ARRAY)
            XSRETURN(printed);
        else if (printed && GIMME_V == G_SCALAR)
            XSRETURN_YES;

        XSRETURN_NO;

void
_slocate (str, ...)
	char *str;
    PREINIT:
	char *dbfile = NULL;
	SV *coderef = NULL;
	int fd;
	short code_num;
	int pathlen=0;
	register char ch;
	int jump=0;
	int first=1;
	char *codedpath=NULL;
	char *code_ptr;
	int printit=0;
	int globflag=0;
	char *globptr1;
	struct stat statres;
	regex_t *preg=NULL;
	char errbuf[1024];
	int nmatch=32;
	regmatch_t pmatch[32];
	int reg_res;
	int bytes = -1;
	int ptr_offset;
	char one_char[1];
	char *begin_ptr;
        int begin_offset=0;
	int tot_size = MIN_BLK;
	int cur_size;
	int code_tot_size = MIN_BLK;

	char *bucket_of_holding=NULL;
	STRLEN n_a;
	/* these vars were global in slocate/main.c */
	int REGEX = 0;
	int NOCASE  = 0;
	int EXTENDED = 0;

	char slevel = '1';
	int res = 0;

        boolean prev_fast_match = false;    /* true if we found a fast match
                                               (of patend) on the previous
                                               path.  */
	register int i;
    PPCODE:
    {
	for (i = 1; i < items; i++) {
            if (SvROK(ST(i)) && SvTYPE((SV*)SvRV(ST(i))) == SVt_PVCV) {
                coderef = newSVsv(ST(i));
            }
            else {
		char *key = SvPV(ST(i), n_a);
		if (*key == '-') {
		    if (strnEQ(key+1, "rexopt", 6)) {
			char *val;
			i++;
			val = SvPV(ST(i), n_a);
			if (strchr(val, (int)'e'))
			    EXTENDED = 1;
			if (strchr(val, (int)'i'))
			    NOCASE = 1;
			continue;
		    }
		    else if (strnEQ(key+1, "rex", 3)) {
			i++;
			REGEX = SvTRUE(ST(i));
			continue;
		    }
		}
		if (!dbfile) {
		    dbfile = savepv(key);
		}
	    }
        }

	if (!dbfile) 
	    croak("No database (shouldn't happen)");
		    
	if ((fd = open(dbfile,O_RDONLY)) == -1) {
	    croak("Can't open dbfile '%s': %s\n", dbfile, strerror(errno));
	}
	
	lstat(dbfile,&statres);
	
	if (S_ISDIR(statres.st_mode)) {
	    croak("Database '%s' is a directory\n", dbfile); 
	}
	
	read(fd,one_char,1);
	slevel = *one_char;

	New(0, codedpath, MIN_BLK, char);
	*codedpath = 0;
	code_ptr = codedpath;

	if ((globptr1 = strchr(str,'*'))  != NULL ||
	    (globptr1 = strchr(str,'?'))  != NULL ||
	    ((globptr1 = strchr(str,'[')) != NULL && 
	    strchr(str,']') != NULL))
	    globflag = 1;

	if (REGEX) {
	    New(0, preg, 1, regex_t);
	    if ((reg_res = regcomp(preg, str, NOCASE ? REG_ICASE : 0)) != 0) {
		    regerror(reg_res, preg, errbuf,1024);
		    croak("Invalid regular expression: %s\n", errbuf);
	    }
	}
	
	New(0, bucket_of_holding, MIN_BLK, char);
	*bucket_of_holding = 0;
	begin_ptr = bucket_of_holding;
	tot_size = MIN_BLK;
	cur_size = 0;
	while (first || begin_ptr < bucket_of_holding+cur_size) {

	    /* No 1 byte reads! */

	    if (cur_size + MIN_BLK > tot_size) {
		    while (cur_size + MIN_BLK > tot_size)
			tot_size <<= 1;
		    begin_offset = begin_ptr - bucket_of_holding;
		    Renew(bucket_of_holding, tot_size, char);
		    begin_ptr = bucket_of_holding + begin_offset;
	    }
	    
	    
	    if (bytes != 0)
		bytes = read(fd,bucket_of_holding+cur_size,MIN_BLK-1);
	    
	    if (bytes == -1) {
		croak("Error reading from database: %s\n", strerror(errno));
	    }

	    cur_size += bytes;

	    code_num = (short)*begin_ptr;
	    begin_ptr += 1;

	    if (code_num == SLOC_ESC) {
		    code_num = s_get_short(&begin_ptr);
	    } else if (code_num > 127)
		code_num = code_num - 256;

	    /* FIXME sometimes pathlen is < 0 but it shouldn't be.
	     * corrupt database file? 
	     * This could be from a bug in frcode() or decode_db(). I
	     * am leaning toward frcode() at the moment */

	    code_ptr += code_num;
	    pathlen = code_ptr - codedpath;
	    
	    if (pathlen < 0) {
		croak("Error in dbfile '%s' (maybe corrupted?)\n", dbfile);
	    }
	    
	    jump = 0;
	    while (!jump) {
		
		ch = *begin_ptr;
		begin_ptr++;
		pathlen++;

		if (pathlen < 0)
		    croak("Error in dbfile '%s': pathlen == %d\n", dbfile, pathlen);

		if (pathlen > code_tot_size) {
		    code_tot_size = pathlen * 2;
		    ptr_offset = code_ptr - codedpath;
		    Renew(codedpath, code_tot_size, char);
		    code_ptr = codedpath+ptr_offset;
		}

		*(codedpath+(pathlen-1)) = ch;

		if (!ch)
		    jump = 1;

		/* FIXME: Handle if begin_ptr runs past buffer */

		/* not quite sure what to do with this:
		   if (begin_ptr > bucket_of_holding+cur_size-1 && bytes) {
		   fprintf(stderr,"slocate fluky bug found.\n");
		   fprintf(stderr,"Ack! This shouldn't happen unless you have a path over 4096.\n");
		   fprintf(stderr,"This could also be a bogus or corrupt database.\n");
		   fprintf(stderr,"Report this as a bug to klindsay@mkintraweb.com\n");
		   exit(1);
		   }
		   */

	    } /* while(!jump) */

	    if (first) {
		code_ptr = code_ptr+strlen(codedpath);
		first=0;
	    }

	    pathlen--;

	    printit=0;

	    if (REGEX) {
		if (regexec(preg,codedpath,nmatch,pmatch,0) == 0) {
		    if (slevel == '1') {
			if (UID == 0 || check_path_access(savepv(codedpath))) {
			    printit = 1;
			}
		    } else
			printit = 1;
		}
	    }
	    else {
		if (fnmatch(str, codedpath, 0) == 0) {
		    if (slevel == '1') {
			if (UID == 0 || check_path_access(savepv(codedpath))) {
			    printit = 1;
			}
		    } else
			printit = 1;
		}
	    }
	    if (printit) {
		res++;
		if (coderef) 
		    call_coderef(coderef, codedpath);
		else if (GIMME_V == G_ARRAY) {
		    XPUSHs(sv_2mortal(newSVpvn(codedpath, strlen(codedpath))));
		}
		else {
		    goto clean_up;
		}
	    }
	}
clean_up:

	close(fd);
	if (preg) {
	    regfree(preg);
            Safefree(preg);
        }

	Safefree(dbfile);
        Safefree(bucket_of_holding);
        Safefree(codedpath);

	if (GIMME_V == G_ARRAY)
	    XSRETURN(res);
	else {
	    if (res > 0)
		XSRETURN_YES;
	    XSRETURN_NO;
	}
    }
