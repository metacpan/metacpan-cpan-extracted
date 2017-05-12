/*
*
*    Copyright (C) 2007 Ask Solem <ask@0x61736b.net>
*
*    This file is part of gbsed
*
*    gbsed is free software; you can redistribute it and/or modify
*    it under the terms of the GNU General Public License as published by
*    the Free Software Foundation; either version 3 of the License, or
*    (at your option) any later version.
*
*    gbsed is distributed in the hope that it will be useful,
*    but WITHOUT ANY WARRANTY; without even the implied warranty of
*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*    GNU General Public License for more details.
*
*    You should have received a copy of the GNU General Public License
*    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

/*
* $Id: libgbsed.c,v 1.2 2007/07/14 14:58:07 ask Exp $
* $Source: /opt/CVS/File-BSED/libgbsed.c,v $
* $Author: ask $
* $HeadURL$
* $Revision: 1.2 $
* $Date: 2007/07/14 14:58:07 $
*/

#ifdef HAVE_CONFIG_H
#   include <config.h>
#endif /* HAVE_CONFIG_H */

#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <assert.h>
#include <ctype.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <math.h>
#include <ctype.h>

#ifdef HAVE_MALLOC_H
#   include <malloc.h>
#endif /* HAVE_MALLOC_H */

#include "libgbsed.h"

#ifndef VERSION
#   error "Missing -DVERSION!"
#endif /* VERSION */

#define GBSED_MAX_WARNINGS            128
#define GBSED_BYTE_SIZE               2
#define VRWMODE     (S_IRUSR|S_IWUSR)
#define UN_FILEMODE ((VRWMODE)|(VRWMODE>>3)|(VRWMODE>>6))

/* stores the error code */
int  gbsed_errno       = 0;

/* stored the warning code */
int  gbsed_warn_index  = 0;
int  gbsed_warnings[GBSED_MAX_WARNINGS];

/* if a file couldn't be open, the error message is stored */
char gbsed_file_error[1024+1];

/* from errno.h */
extern int  errno;

/* Return the current libgbsed version */
const char*
gbsed_version (void)
{ 
    const char *version_string = VERSION;
    return version_string;
}

/* Return a error description for a error code in gbsed_errno */
const char*
gbsed_errtostr (int gbsed_errno_val)
{
    char *retval;

    switch (gbsed_errno_val) {
        case GBSED_ENULL_SEARCH:
            retval = "Missing search string.";
            break;
        case GBSED_ENULL_REPLACE:
            retval = "Missing replace string.";
            break;
        case GBSED_EMISSING_INPUT:
            retval = "Missing input filename.";
            break;
        case GBSED_EMISSING_OUTPUT:
            retval = "Missing outupt filename.";
            break;
        case GBSED_EINVALID_CHAR:
            retval = "Only hex values or the wildcard (\'\?\?\') allowed.";
            break;
        case GBSED_ENIBBLE_NOT_BYTE:
            retval = "Only wild bytes are allowed, not nibbles.";
            break;
        case GBSED_EOPEN_OUTFILE:
            retval = gbsed_file_error;
            break;
        case GBSED_EOPEN_INFILE:
            retval = gbsed_file_error;
            break;
        case GBSED_ENOSTAT_FDES:
            retval = gbsed_file_error;
            break;
        case GBSED_EMINMAX_BALANCE:
            retval = "Maxmatch must not be less than minmatch.";
            break;
        case GBSED_ENOMEM:
            retval = "Out of memory!";
            break;

        default:
            retval = NULL;
            break;
    }

    return retval;
}

/* Return a description for a warning code in gbsed_warnings[]. */
char*
gbsed_warntostr (int gbsed_warno_val)
{
    char *retval;

    switch (gbsed_warno_val) {

        case GBSED_WBALANCE:
            retval = "Search and replace strings is not of the same length.";
            break;
    
        default:
            retval = NULL;
            break;
    }

    return retval;
}

#define gbsed_push_warning(w) do {                                  \
    if (gbsed_warn_index < GBSED_MAX_WARNINGS)                      \
        gbsed_warnings[gbsed_warn_index++] = w;                     \
} while(0)

#define gbsed_print_warnings() do {                                 \
    register int i;                                                 \
    for (i = 0; i < gbsed_warn_index; i++) {                        \
        const char *w = gbsed_warntostr(gbsed_warnings[i]);         \
        fprintf(stderr, "WARNING: %s\n", w);                        \
    }                                                               \
} while(0);

#define gbsed_reset_warnings() (gbsed_warn_index = 0)

void * _gbsed_alloczero (size_t count,  size_t size)
{
    void *new_pointer;
    new_pointer = calloc(count, size);
    memset(new_pointer, '\0', size);
    return new_pointer;
}


/* see libgbsed.h for struct bsed_arguments */
int
gbsed_binary_search_replace (struct gbsed_arguments *arg)
{
    fGBSEDargs *farg;
    FILE       *infile          = NULL;
    FILE       *outfile         = NULL;
    char*       search          = arg->search;
    char*       replace         = arg->replace;
    char*       infilename      = arg->infilename;
    char*       outfilename     = arg->outfilename;
    int         minmatch        = arg->minmatch;
    int         maxmatch        = arg->maxmatch;
    int         matches;

    /* Must have input file */
    if (infilename == NULL) {
        gbsed_errno = GBSED_EMISSING_INPUT;
        return GBSED_ERROR;
    }

    /* Open input file */
    if (strcmp(infilename, "-") == 0) {
        /* if filename is '-' (dash), we get input from STDIN */
        infile = stdin;
    } 
    else if ((infile = fopen(infilename, "r")) == NULL) {
        snprintf(gbsed_file_error, sizeof(gbsed_file_error),
            "Could not open %s: %s",
            infilename, strerror(errno)
        );
        gbsed_errno = GBSED_EOPEN_INFILE;
        return GBSED_ERROR;
    }

    /* Open output file */
    if (outfilename != NULL) {
        mode_t preserve_exec;
    
        if (strcmp(outfilename, "-") == 0) {
            outfile = stdout;
        }
        else {
            if ((outfile = fopen(outfilename, "w")) == NULL) {
                snprintf(gbsed_file_error, sizeof(gbsed_file_error),
                    "Could not open %s: %s",
                    outfilename, strerror(errno)
                );
                gbsed_errno = GBSED_EOPEN_OUTFILE;
                return GBSED_ERROR;
            }
            /* setvbuf(outfile, 0, _IONBF, BUFSIZ); */
        }

        /* preserve the exec bits from input file. */
        if ((preserve_exec = _gbsed_preserve_execbit(infile)) != 0)
            fchmod(fileno(outfile), preserve_exec);
        else 
            return GBSED_ERROR;
    }

    farg      = _gbsed_alloc(farg, 1, fGBSEDargs);
    if (farg == NULL) {
        gbsed_errno = GBSED_ENOMEM;
        return GBSED_ERROR;
    }
    farg->search    = search;
    farg->replace   = replace;
    farg->infile    = infile;
    farg->outfile   = outfile;
    farg->minmatch  = minmatch;
    farg->maxmatch  = maxmatch;

    matches         = gbsed_fbinary_search_replace(farg);

    fclose(infile);
    if (outfile != NULL)
        fclose(outfile);
    free(farg);

    return (matches);
}

/* Poor mans garbage collection :-) */

typedef struct gbsed_garbage_collection {
        int search;
        int replace;
        int to_be_written;
} gbsedGC;

#define _gbsed_gc_init()                          \
        COLLECT.search        = 0;                \
        COLLECT.replace       = 0;                \
        COLLECT.to_be_written = 0;                \
        

#define _gbsed_gc_collect()                                         \
    do {                                                            \
        if (COLLECT.search)         _gbsed_safefree(search);        \
        if (COLLECT.replace)        _gbsed_safefree(replace);       \
        if (COLLECT.to_be_written)  _gbsed_safefree(to_be_written); \
    } while(0);

int
gbsed_fbinary_search_replace (struct fgbsed_arguments *arg)
{
    char  *searchstr     = arg->search;
    char  *replacestr    = arg->replace;
    FILE  *infile        = arg->infile;
    FILE  *outfile       = arg->outfile;
    int    minmatch      = arg->minmatch;
    int    maxmatch      = arg->maxmatch;

    UCHAR *search        = NULL;
    UCHAR *replace       = NULL;
    UCHAR *to_be_written = NULL;

    int    bytematch     = 0;
    int    matches       = 0;
    int    i             = 0;

    size_t slen = 0;   /* length of search  string */
    size_t rlen = 0;   /* length of replace string */
    
    gbsedGC COLLECT;

    gbsed_reset_warnings();
    _gbsed_gc_init();

    if (!minmatch)
        minmatch = 1;
    if (!maxmatch)
        maxmatch = GBSED_MMAX_NO_LIMIT;

    if (maxmatch > GBSED_MMAX_NO_LIMIT && maxmatch < minmatch) {
        gbsed_errno = GBSED_EMINMAX_BALANCE;
        goto ERROR;
    }

    search   = _gbsed_hexstr2bin(searchstr, &slen);
    if (search == NULL)
        goto ERROR;
    if (slen <= 0) {
        gbsed_errno = GBSED_ENULL_SEARCH;
        goto ERROR;
    }
    COLLECT.search++;

    /* Prepare replace string */
    if (replacestr != NULL) {
        replace = _gbsed_hexstr2bin(replacestr, &rlen);
        if (replace == NULL)
            goto ERROR;
       
        if (rlen <= 0) { 
            gbsed_errno = GBSED_ENULL_REPLACE;
            goto ERROR;
        }
        if ((slen != rlen)) {
            gbsed_push_warning(GBSED_WBALANCE);
        }
        COLLECT.replace++;
    }

    /* Must have input file */
    if (infile == NULL) {
        gbsed_errno = GBSED_EMISSING_INPUT;
        goto ERROR;
    }

    if (outfile != NULL) {
        to_be_written = _gbsed_alloc(to_be_written, rlen+1, UCHAR);
        COLLECT.to_be_written++;
    }

    while (true) {
        int byte;

        if (bytematch && bytematch == slen) {
            /* when all of search string has been matched */
            if (outfile != NULL && matches < minmatch) { 
                for (i = 0; i < rlen; i++) {
                    search[i] == '?' ? putc(to_be_written[i], outfile)
                                     : putc(replace[i], outfile);
                }
            }
            matches++;
            bytematch = 0;
        }

        byte = getc(infile);
        if (feof(infile))
            break;
        
        if (outfile != NULL)
            to_be_written[bytematch] = byte;

        if (byte == search[bytematch] || search[bytematch] == '?') {
            if (maxmatch == GBSED_MMAX_NO_LIMIT || matches < maxmatch) {
                /* while it matches */
                bytematch++;
                continue;
            }
        }

        /* write buffer */
        if (outfile != NULL) {
            for (i = 0; i <= bytematch; i++)
                putc(to_be_written[i], outfile);
        }

        bytematch     = 0;
    }
     

    fflush(outfile);

    /*matches -= (minmatch - 1);*/
  
    _gbsed_gc_collect();
            
    return matches;

    ERROR:
        _gbsed_gc_collect();
        return GBSED_ERROR;
}

char *
gbsed_string2hexstring (char *orig)
{
    char   *hexstr;
    char   *strp;
    char    buf[GBSED_BYTE_SIZE + 1];
    size_t  size_of_hex;
    int     i;

    size_of_hex = (strlen(orig) * GBSED_BYTE_SIZE);
    hexstr      = _gbsed_alloc(hexstr, size_of_hex + 1, char);
    strp        = orig;

    for (i = 0; *strp != '\0'; strp++, i += GBSED_BYTE_SIZE) {
        int j;
        snprintf(buf, GBSED_BYTE_SIZE+1, "%x", *strp);
        for (j = 0; j < GBSED_BYTE_SIZE; j++)
            hexstr[i + j] = buf[j];
    }
    hexstr[i] = '\0';

    return hexstr;
}

#define hexvalue(c)     (isdigit(c) ? ((c) & 0xf) : (((c) & 0xf) + 9))
#define iswild(c)       ((c) == '?')
#define is0xsequence(c)    (*c == '0' && ( *(c+1) == 'x' || *(c+1) == 'X'))
UCHAR *
_gbsed_hexstr2bin (char *in, size_t *len_buf)
{
    int    i   = 0;
    char  *p   = NULL;
    UCHAR *out = NULL;
    size_t len;

    len   = (size_t)ceil(((double)strlen(in)/2));
    out   = _gbsed_alloc(out, len, sizeof(UCHAR));

    p = in;

    /* skip the first two chars if they are '0x' */ 
    if (is0xsequence(p)) {
        *(p   += 2);
         len--;
    }

    while (*p != '\0') {
        UCHAR byte;

        if (isxdigit(*p)) {
             byte = hexvalue(*p);
            *p++;
            if (isxdigit(*p)) {
                byte = (byte << 4) + hexvalue(*p);
                *p++;
            }
            out[i++] = byte;
        }
        else if (iswild(*p)) {
            out[i++] = *p++;
            if (! iswild(*p)) {
                gbsed_errno = GBSED_ENIBBLE_NOT_BYTE;
                return NULL;
            }
            *p++;
        }
        else {
            gbsed_errno = GBSED_EINVALID_CHAR;
            return NULL;
        }

    }

    *len_buf = len;

    return out;
}

mode_t
_gbsed_preserve_execbit (FILE *file)
{
    struct stat *filestat;
    mode_t       cur_umask      = 00;
    mode_t       filemode       = 00;
    mode_t       retmode        = 00;
    int          statret        = -1;

    /* get the permissions for the file */
    filestat = _gbsed_alloc(filestat, 1, struct stat);
    if (filestat == NULL) {
        gbsed_errno = GBSED_ENOMEM;
        goto CLEANUP;
    }
    statret = fstat(fileno(file), filestat);
    if (statret == -1) {
        gbsed_errno = GBSED_ENOSTAT_FDES;
        snprintf(gbsed_file_error, sizeof(gbsed_file_error),
            "Could not stat open file descriptor: %s",
            strerror(errno)
        );
        goto CLEANUP;
    }
    filemode = filestat->st_mode;

    /* get current umask. */
    cur_umask = umask(S_IRWXG|S_IRWXO);
    /* have to set the umask back to what it was before */
    umask(cur_umask);

    /* apply the umask to the mode we return */
    retmode = UN_FILEMODE & ~cur_umask;

    /* apply exec bits from the files mode to the mode we return */
    if (filemode  &  S_IXUSR)
        retmode   |= S_IXUSR;
    if (filemode  &  S_IXGRP)
        retmode   |= S_IXGRP;
    if (filemode  &  S_IXOTH)
        retmode   |= S_IXOTH;

    CLEANUP:
    _gbsed_safefree(filestat);

    return retmode;
}

/*

=pod

=head1 NAME

libgbsed - Search/Replace in binary files.

=head1 SYNOPSIS

    #include <libgbsed.h>

    // using file names.
    struct gbsed_arguments
    {
        char *search;
        char *replace;
        char *infilename;
        char *outfilename;
        int  minmatch;
        int  maxmatch;
    };

    typedef struct gbsed_arguments GBSEDargs;
    
    int
    gbsed_binary_search_replace(struct gbsed_arguments *)

    // using FILE*s 
    struct fgbsed_arguments
    {
        char *search;
        char *replace;
        FILE *infile;
        FILE *outfile;
        int   minmatch;
        int   maxmatch;
    };
    typedef struct fgbsed_arguments fGBSEDargs;

    int
    gbsed_fbinary_search_replace(struct fgbsed_arguments *);

    // Error handling

    extern int
    gbsed_errno;

    const char*
    gbsed_errtostr(int);

=head1 DESCRIPTION

This is <libgbsed>, a binary stream editor.

C<gbsed> lets you search and replace binary data in binary files by using hex
values in text strings as search patterns. You can also use wildcard matches
with C<??>, which will match any wide byte.

These are all valid search strings:

    search = "0xffc300193ab2f63a";
    search = "0xff??00??3ab2f??a";
    search = "FF??00??3AB2F??A";

while these are not:

    search = "the quick brown fox"; // only hex, no text. you would have to
                                    // convert the text to hex first.
    search = "0xff?c33ab3?accc";    // no nybbles only wide bytes. (?? not ?).

=head1 FUNCTIONS

=head2 C<gbsed_binary_search_replace(struct gbsed_arguments *)>

=head3 ARGUMENTS

C<gbsed_binary_search_replace> uses a struct for it's arguments.
The members of the argument struct is as follows:

=over 4

=item C<char *search>

What to search for. This must be a string with hex values or the wildcard
character sequence C<??>, which will match any byte. The string
can start with C<0x>, but this is optional.

=item C<char *replace>

What to replace with. Must also be a string with hex values,
but no wildcards allowed. It must also be of the same length
as the search string (This is by intention, as binary data is always
in structured form. If you add extra information to a binary executable
it will be rendered useless as address offsets will be shifted and
relocation tables and internal address references will point to the
wrong place).

=item C<char *infilename>

The file name of the file to search in.

=item C<char *outfilename>

The file name to save the modified binary as.

=item C<int minmatch>

Need at least C<minmatch> matches before any work.

=item C<int maxmatch>

Stop after C<maxmatch> matches. A value of C<-1> means no limit.

=back


=head3 EXAMPLE USAGE
    
    #include <stdlib.h>
    #include <stdio.h>
    #include <libgbsed.h>
    
    extern int gbsed_errno;

    int main(int argc, char **argv) {

        int         gbsed_ret;
        int         sysret;
        const char *errmessage;
        GBSEDargs   *bargs;

        sysret  = EXIT_SUCCESS;
        bargs   = (GBSEDargs *)malloc(sizeof(GBSEDargs));
        if (bargs == NULL) {
            fprintf(stderr, "Out of memory!\n");
            exit(1);
        }

        bargs->search      = "0xff";
        bargs->replace     = "0x00";
        bargs->infilename  = "/bin/ls";
        bargs->outfilename = "bsed.out";
        bargs->minmatch    =  1;                        // atleast one match.
        bargs->maxmatch    = GBSED_MMAX_NO_LIMIT;   // no limit.

        if (argc > 1)
            bargs->infilename  = argv[1];

        gbsed_ret = gbsed_binary_search_replace(bargs);

        switch (gbsed_ret) {
            
            case GBSED_ERROR:
                errmessage = gbsed_errtostr(gbsed_errno);
                fprintf(stderr, "ERROR: %s\n", errmessage);
                sysret = EXIT_FAILURE;
                break;
            case GBSED_NO_MATCH:
                fprintf(stderr, "No match for %s found in %s\n",
                    bargs->search, bargs->infilename
                );
                sysret = EXIT_FAILURE;
                break;
            
            default:
                printf("Search for '%s' in '%s' matched %d times.\n",
                    bargs->search, bargs->infilename, gbsed_ret
                );
                break;
        }
        
        free(bargs);
        return sysret;
    }

=head2 C<const char * gbsed_errtostr(int)>

This function returns a string describing what happened.
if an error has occurred with either C<gbsed_binary_search_replace> or
C<binary_file_matches>.

Example:
    
    extern int gbsed_errno;

    const char *errmessage;
    errmessage = gbsed_errtostr(gbsed_errno);
    fprintf(stderr, "ERROR: %s\n", errmessage);

=head1 RETURN VALUES

C<gbsed_binary_search_replace> returns C<GBSED_ERROR> on failure.
The error code can then be found in C<gbsed_errno>, error codes are defined in I<libgbsed.h>.
and they all start with C<GBSED_> and is C<int>. To get a string containing the
error message you have to call C<bsed_errtomsg> with C<bsed_errno> as argument.

=head2 Error codes returned by C<gbsed_binary_search_replace()>

=head3 C<GBSED_NO_MATCH>

No matches found.

=head3 C<GBSED_ERROR>

An error has occurred and a error code has been left in C<gbsed_errno>.

=head2 Error codes found in C<gbsed_errno>

=head3 C<GBSED_ESEARCH_TOO_LONG>

Search string was longer than the limit.

=head3 C<GBSED_EREPLACE_TOO_LONG>

Replace string was longer than the limit.

=head3 C<GBSED_ENULL_SEARCH>

Missing search string.

=head3 C<GBSED_ENULL_REPLACE>

Missing replace string.

=head3 C<GBSED_EMISSING_INPUT>

Missing input filename.

=head3 C<GBSED_EMISSING_OUTPUT>

Missing output filename.

=head3 C<GBSED_EINVALID_CHAR>

Invalid characters in search string. Only hex values and wildcards
are allowed.

=head3 C<GBSED_ENIBBLE_NOT_BYTE>

Wildcard must be wild byte, not nibble.  (C<??> not C<?>).

=head1 CONFIGURATION AND ENVIRONMENT

C<libgbsed> requires no configuration file or environment variables.

=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-file-bsed@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 SEE ALSO

=over 4

=item * L<gbsed>

=back

=head1 AUTHOR

Ask Solem,   C<< ask@0x61736b.net >>.

=head1 ACKNOWLEDGEMENTS

Dave Dykstra C<< dwdbsed@drdykstra.us >>.
for C<bsed> the original program,

I<0xfeedface>
for the wildcards patch.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2007 Ask Solem <ask@0x61736b.net>


gbsed is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.

gbsed is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE
SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE
STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE
SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND
PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE,
YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY
COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE
SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO
LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR
THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER
SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES.

=cut

*/

/*
# Local Variables:
#   mode: cperl
#   indent-level: 4
#   fill-column: 78
# End:
# vim: expandtab tabstop=4 shiftwidth=4 shiftround
*/
