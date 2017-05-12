/* -*- Mode: C; c-file-style: "stroustrup" -*- */

/**
 * @file
 * @brief Make a hash table for jspell
 */

/** define we are in the main file */
/* #define MAIN */

#include <string.h>

#include "jsconfig.h"
#include "jspell.h"
#include "proto.h"
#include "msgs.h"
#include <ctype.h>
#include <sys/stat.h>

static char aux_w[3];

/** Size probe-statistics table */
#define NSTAT 100

/** Result of stat-ing dict file */
struct stat dstat;           

/** Result of stat-ing count file */
struct stat cstat;

/** Number of entries to go in hash table */
/* int hashsize; */

/** Header of hash table being built */
/* struct hashheader hashheader;   */

/** Entries to go in hash table */
/* struct dent *hashtbl;        */

/** Name of dictionary file */
char *Dfile;         

/** Name of hash (output) file */
char *Hfile;

/** Name of language file */
char *Lfile;

/** Name of count file */
char  Cfile[MAXPATHLEN];    

/** Name of statistics file */
char  Sfile[MAXPATHLEN];     

/* NZ to suppress count reports */
static int silent = 0;


/* initializes silent, Dfile, Lfile and Hfile */
static char get_param_info(int argc, char *argv[])
{
    while (argc > 1  &&  *argv[1] == '-') {
        argc--;
        argv++;
        switch (argv[0][1]) {
        case 's':
            silent = 1;
            break;
        }
    }

    if (argc == 4) {
        Dfile = argv[1];
        Lfile = argv[2];
        Hfile = argv[3];
    } else {
        fprintf(stderr, BHASH_C_USAGE);
        return 1;   /* Error */
    }
    return 0;     /* OK */
}


static void write_status_file(void) {
    int   avg;
    FILE *statf;
    int   stats[NSTAT];
    int   i, j;

    if ((statf = fopen(Sfile, "w")) == NULL) {
        fprintf(stderr, CANT_CREATE, Sfile);
        exit(1);
    }

    for (i = 0; i < NSTAT; i++)
        stats[i] = 0;

    for (i = 0; i < hashsize; i++) {
        struct dent *dp;
        dp = &hashtbl[i];
        if ((dp->flagfield & USED) != 0) {
            for (j = 0;  dp != NULL;  j++, dp = dp->next) {
                if (j >= NSTAT)
                    j = NSTAT - 1;
                stats[j]++;
            }
        }
    }

    for (i = 0, j = 0, avg = 0;  i < NSTAT;  i++) {
        j += stats[i];
        avg += stats[i] * (i + 1);
        if (j == 0)
            fprintf(statf, "%d:\t%d\t0\t0.0\n", i + 1, stats[i]);
        else
            fprintf(statf, "%d:\t%d\t%d\t%f\n", i + 1, stats[i], j,
                    (double) avg / j);
    }
    fclose(statf);
}


static void read_hassize(void) 
{
    FILE *countf;

    if ((countf = fopen(Cfile, "r")) == NULL) {
        fprintf(stderr, BHASH_C_NO_COUNT);
        exit(1);
    }
    hashsize = 0;
    if (fscanf(countf, "%d", &hashsize) != 1) {
        fprintf(stderr, "Error reading hash.\n");
        exit(1);
    }
    fclose(countf);
    if (hashsize == 0) {
        fprintf(stderr, BHASH_C_BAD_COUNT);
        exit(1);
    }
}


static void act_files_Dfile(void)
{
    sprintf(Cfile, "%s.cnt", Dfile);
    sprintf(Sfile, "%s.stat", Dfile);

    if (stat(Dfile, &dstat) < 0) {
        fprintf(stderr, BHASH_C_NO_DICT, Dfile);
        exit(1);
    }
}

static FILE *houtfile;

static void write_gentable(void)
{
    int i;
    ichar_t *aux;

    aux = strtosichar("", 0);
    for (i = 0; i < MASKBITS; i++) {
        /* printf("gentable[i].classl = %d", gentable[i].classl); */
        fwrite((char *) &(gentable[i].classl), 1, sizeof(short), houtfile);
        if (gentable[i].jclass)
            fwrite((char *) gentable[i].jclass, gentable[i].classl + 1,
                   sizeof(ichar_t), houtfile);
        else
            fwrite((char *) aux, 1, sizeof(ichar_t), houtfile);
    }
}

static int write_suffixs(long int *st)
{
    int maxslen, i, n;
    long int strptr;
    struct flagent *fentry;

    strptr = *st;
    maxslen = 0;
    for (i = numsflags, fentry = sflaglist;  --i >= 0;  fentry++) {
        if (fentry->stripl) {
            fwrite((char *) fentry->strip, fentry->stripl + 1,
                   sizeof(ichar_t), houtfile);
            fentry->strip = (ichar_t *) strptr;
            strptr += (fentry->stripl + 1) * sizeof(ichar_t);
        }

        if (fentry->affl) {
            fwrite((char *) fentry->affix, fentry->affl + 1,
                   sizeof(ichar_t), houtfile);
            fentry->affix = (ichar_t *) strptr;
            strptr += (fentry->affl + 1) * sizeof(ichar_t);
        }

        if (fentry->classl) {
            fwrite((char *) fentry->jclass, fentry->classl + 1,
                   sizeof(ichar_t), houtfile);
            fentry->jclass = (ichar_t *) strptr;
            strptr += (fentry->classl + 1) * sizeof(ichar_t);
        }

        n = fentry->affl - fentry->stripl;

        if (n < 0)       n = -n;
        if (n > maxslen) maxslen = n;
    }
    *st = strptr;
    return maxslen;
}



static int write_prefixs(long int *st)
{
    long int strptr;
    int maxplen, i, n;
    struct flagent *fentry;

    strptr = *st;
    maxplen = 0;
    for (i = numpflags, fentry = pflaglist;  --i >= 0;  fentry++) {
        if (fentry->stripl) {
            fwrite((char *) fentry->strip, fentry->stripl + 1,
                   sizeof(ichar_t), houtfile);
            fentry->strip = (ichar_t *) strptr;
            strptr += (fentry->stripl + 1) * sizeof(ichar_t);
        }

        if (fentry->affl) {
            fwrite((char *) fentry->affix, fentry->affl + 1,
                   sizeof(ichar_t), houtfile);
            fentry->affix = (ichar_t *) strptr;
            strptr += (fentry->affl + 1) * sizeof(ichar_t);
        }

        if (fentry->classl) {
            fwrite((char *) fentry->jclass, fentry->classl + 1,
                   sizeof(ichar_t), houtfile);
            fentry->jclass = (ichar_t *) strptr;
            strptr += (fentry->classl + 1) * sizeof(ichar_t);
        }

        n = fentry->affl - fentry->stripl;

        if (n < 0)       n = -n;
        if (n > maxplen) maxplen = n;
    }
    *st = strptr;
    return maxplen;
}

static void write_str_type_tables(int maxslen, int maxplen, long int *st)
{
    /* Write out the string character type tables. */
    int i, n;
    long int strptr;

    strptr = *st;
    hashheader.strtypestart = strptr;
    for (i = 0;  i < hashheader.nstrchartype;  i++) {
        n = strlen(chartypes[i].name) + 1;
        fwrite(chartypes[i].name, n, 1, houtfile);
        strptr += n;
        n = strlen(chartypes[i].deformatter) + 1;
        fwrite(chartypes[i].deformatter, n, 1, houtfile);
        strptr += n;
        for (n = 0;  chartypes[i].suffixes[n] != '\0';
             n += strlen(&chartypes[i].suffixes[n]) + 1)
            ;
        n++;
        fwrite(chartypes[i].suffixes, n, 1, houtfile);
        strptr += n;
    }
    hashheader.lstringsize = strptr;
    /* We allow one extra byte because missingletter() may add one byte */
    maxslen += maxplen + 1;
    if (maxslen > MAXAFFIXLEN) {
        fprintf(stderr, BHASH_C_BAFF_1(MAXAFFIXLEN, maxslen-MAXAFFIXLEN));
        fprintf(stderr, BHASH_C_BAFF_2);
    }
    *st = strptr;
}

/* Put out the dictionary strings.
 * it writes all the words on disk, and also changes dp->word, in
 * order to make it an index rather than a memory pointer */
static long int put_dict_strings(long int strptr)
{
    register struct dent *dp;
    int i, n;
    
    for (i = 0, dp = hashtbl;  i < hashsize;  i++, dp++) {
        if (dp->word == NULL)
            dp->word = (char *) -1;
        else {
            n = strlen(dp->word) + 1;
            fwrite(dp->word, n, 1, houtfile);
            dp->word = (char *) strptr;
            strptr += n;
        }
    }
    return strptr;
}


static long int put_class_strings(long int strptr)
{
    register struct dent *dp;
    int i, n;

    for (i = 0, dp = hashtbl;  i < hashsize;  i++, dp++) {
        if (dp->jclass == NULL)
            dp->jclass = (char *) -1;
        else {
            n = strlen(dp->jclass) + 1;
            fwrite(dp->jclass, n, 1, houtfile);
            dp->jclass = (char *) strptr;
            strptr += n;
        }
    }
    return strptr;
}


#if 0
static int put_comm_strings(int strptr)
{
    register struct dent *dp;
    int i, n;

    for (i = 0, dp = hashtbl;  i < hashsize;  i++, dp++) {
        if (dp->comm == NULL)
            dp->comm = (char *) -1;
        else {
            n = strlen(dp->comm) + 1;
            fwrite(dp->comm, n, 1, houtfile);
            dp->comm = (char *) strptr;
            strptr += n;
        }
    }
    return strptr;
}
#endif

#if 0
static int pad_file(int strptr)
{
    int n;
    
    n = (strptr + sizeof hashheader) % sizeof(struct dent);
    if (n != 0) {
        n = sizeof(struct dent) - n;
        strptr += n;
        while (--n >= 0)
            putc('\0', houtfile);
    }
    return strptr;
}
#endif


static int write_dent(register struct dent *dp)
{
    long int ind[3];
    char i, sz = 0;

    if (dp->word != (char *) -1) {   /* word exists */

        ind[0] = (long int) dp->word;
        i = 1;
        if (dp->jclass != (char *) -1) {
            ind[(int)i] = (long int) dp->jclass;
            i++;
        }

        if (dp->next != (struct dent *)-1) {
            ind[(int)i] = (long int) dp->next;
            i++;
        }

        if (i == 2 && dp->next != (struct dent *)-1)
            aux_w[1] = 4;
        else 
            aux_w[1] = i;

        fwrite(aux_w+1, 1, 1, houtfile);  /* write 1 - entry found */
        fwrite(ind, sizeof(long int), i, houtfile);
        fwrite(dp->mask, sizeof(MASKTYPE), MASKSIZE, houtfile);
        sz = 1 + i * sizeof(long int) + sizeof(MASKTYPE) * MASKSIZE;
#ifdef FULLMASKSET
        fwrite(&(dp->flags), 1, 1, houtfile);
        sz++;
#endif
        return sz;
    }
    else {
        fwrite(aux_w, 1, 1, houtfile);  /* write_null - no entry */
        return 1;
    }
}

static unsigned int put_hash_table(void)
{
    register struct dent *dp;
    int i;
    unsigned int thashsize;

    thashsize = 0;
    aux_w[0] = 0;  aux_w[1] = 1;
    for (i = 0, dp = hashtbl;  i < hashsize;  i++, dp++) {
        if (dp->next != 0) {
            long int  x;
            x = dp->next - hashtbl;
            dp->next = (struct dent *)x;
        } else {
            dp->next = (struct dent *) - 1;
        }

        thashsize += write_dent(dp);
    }
    return thashsize;
}



static void put_out_lang_tables(void)
{
    fwrite((char *) sflaglist, sizeof(struct flagent), numsflags, houtfile);
    hashheader.stblsize = numsflags;

    fwrite((char *) pflaglist, sizeof(struct flagent), numpflags, houtfile);
    hashheader.ptblsize = numpflags;
}


static void output(void)
{
    long int strptr;
    unsigned int thashsize;
    int maxplen, maxslen;

    if ((houtfile = fopen(Hfile, "wb")) == NULL) {
        fprintf(stderr, CANT_CREATE, Hfile);
        return;
    }
    hashheader.stringsize = 0;
    hashheader.lstringsize = 0;
    hashheader.tblsize = hashsize;
    fwrite((char *) &hashheader, sizeof hashheader, 1, houtfile);
    strptr = 0;

    /* Put out the strings from the flags table.  This code assumes that the
     * size of the hash header is a multiple of the size of ichar_t, and that
     * any integer can be converted to an (ichar_t *) and back without damage.
     */
    maxslen = write_suffixs(&strptr);
    maxplen = write_prefixs(&strptr);
    write_str_type_tables(maxslen, maxplen, &strptr);
    strptr = put_dict_strings(strptr);
    strptr = put_class_strings(strptr);
    /* strptr = put_comm_strings(strptr);*/

    /* Pad file to a struct dent boundary for efficiency. */
    /* strptr = pad_file(strptr); */

    /* Put out the hash table itself */
    thashsize = put_hash_table();

    write_gentable();

    /* Put out the language tables */
    put_out_lang_tables();

    /* Finish filling in the hash header. */
    hashheader.stringsize = strptr;
    hashheader.thashsize = thashsize;

    rewind(houtfile);
    fwrite((char *) &hashheader, sizeof hashheader, 1, houtfile);
    fclose(houtfile);
}


static void filltable(void)
{
    /* since some dic. entries are not directed linked to the hash
     * table, lets put them on free slots */
    struct dent *freepointer;   /* free slot in the hash table */
    struct dent *nextword, *dp;
    struct dent *hashend;
    int i;
    int overflows;

    hashend = hashtbl + hashsize;
    /* look for first free slot in the hash table */
    for (freepointer = hashtbl;
         (freepointer->flagfield & USED) && freepointer < hashend;
         freepointer++)
        ;
    overflows = 0;
    /* for each entrie on the hast table ... */
    for (nextword = hashtbl, i = hashsize; i != 0; nextword++, i--) {
        if ((nextword->flagfield & USED) == 0)   /* if it isn't used, there is nothing to be done */
            continue;

        if (nextword->next >= hashtbl  &&  nextword->next < hashend)
            continue;

        dp = nextword;
        while (dp->next) {   
            /* there are more than one dictionary entries in the
             * current hashtable position */

            if (freepointer >= hashend) {  
                /* there isn't enouth room in the hash table for all
                 * the entries */
                overflows++;
                break;
            } else {
                /* put the second dic. entrie into a free slot of the
                 * hash table */
                *freepointer = *(dp->next);  
                dp->next = freepointer;
                dp = freepointer;

                /* look for another free space on the hashtable */
                while ((freepointer->flagfield & USED) &&  freepointer < hashend)
                    freepointer++;
            }
        }
    }
    if (overflows)
        fprintf(stderr, BHASH_C_OVERFLOW, overflows);
}


#if 0
#if MALLOC_INCREMENT == 0
static VOID *jbuild_malloc(unsigned int size)
{
    return malloc(size);
}

/* ARGSUSED */
static VOID * myrealloc(VOID *ptr, unsigned int size, unsigned int oldsize)
{
   return realloc(ptr, size);
}

static void jbuild_free(VOID *ptr)
{
    free(ptr);
}

#else

/* Fast, unfree-able variant of malloc */
static VOID * jbuild_malloc(unsigned int size)
{
    VOID *retval;
    static int bytesleft = 0;
    static VOID *nextspace;

    if (size < 4)
        size = 4;
    size = (size + 7) & ~7;        /* Assume doubleword boundaries are enough */
    if (bytesleft < size) {
        bytesleft = (size < MALLOC_INCREMENT) ? MALLOC_INCREMENT : size;
        nextspace = malloc((unsigned) bytesleft);
        if (nextspace == NULL) {
            bytesleft = 0;
            return NULL;
        }
    }
    retval = nextspace;
    nextspace = (VOID *) ((char *) nextspace + size);
    bytesleft -= size;
    return retval;
}

static VOID *myrealloc(VOID *ptr, unsigned int size, unsigned int oldsize)
{
    VOID *nptr;
    
    nptr = mymalloc(size);
    if (nptr == NULL) return NULL;
    bcopy(ptr, nptr, oldsize);
    return nptr;
}

static void jbuild_free(VOID *ptr)
{
}

#endif
#endif



static void alloc_hashtbl(void)
{
    hashtbl = (struct dent *) calloc((unsigned) hashsize, sizeof(struct dent));
    if (hashtbl == NULL) {
        fprintf(stderr, BHASH_C_NO_SPACE);
        exit(1);
    }
}

static void possible_write_i(int i)
{
    if (!silent  &&  (i % 1000) == 0) {
        fprintf(stderr, "%d ", i);
        fflush(stdout);
    }
}

static void add_entry_with_correct_capitalization(struct dent *d,
                                                  register struct dent *dp)
{
    /* If it's a followcase word, we need to make this a special dummy
     * entry, and add a second with the correct capitalization.
     */
    if (captype(d->flagfield) == FOLLOWCASE) {
        if (addvheader(dp))
            exit(1);
    }
}

static void collision_treatement(struct dent *d, register struct dent *dp, int h)
{
    /* Collision.  Skip to the end of the collision chain, or to a
     * pre-existing entry for this word.  Note that d.word always
     * exists at this point.
     */
    char ucbuf[INPUTWORDLEN + MAXAFFIXLEN + 2 * MASKBITS];
    struct dent *lastdp;

    strcpy(ucbuf, d->word);
    chupcase(ucbuf);
    while (dp != NULL) {
        if (strcmp(dp->word, ucbuf) == 0)
            break;
#ifndef NO_CAPITALIZATION_SUPPORT
        while (dp->flagfield & MOREVARIANTS)
            dp = dp->next;
#endif /* NO_CAPITALIZATION_SUPPORT */
        dp = dp->next;
    }

    if (dp != NULL && strcmp(d->jclass, dp->jclass) == 0) {  /* we should combine only if class is equal */
        /* A different capitalization is already in the dictionary.
         * Combine capitalizations.  */
        if (combinecaps(dp, d) < 0)
            exit(1);
    } else {
        /* Insert a new word into the dictionary */
        for (dp = &hashtbl[h];  dp->next != NULL;  )
            dp = dp->next;
        lastdp = dp;
        dp = (struct dent *) mymalloc(sizeof(struct dent));
        if (dp == NULL) {
            fprintf(stderr, BHASH_C_COLLISION_SPACE);
            exit(1);
        }
        *dp = *d;
        lastdp->next = dp;
        dp->next = NULL;
#ifndef NO_CAPITALIZATION_SUPPORT
        /* If it's a followcase word, we need to make this a special
         * dummy entry, and add a second with the correct
         * capitalization.
         */
        if (captype(d->flagfield) == FOLLOWCASE) {
            if (addvheader(dp))
                exit(1);
        }
#endif
    }
}

static void readdict(void)
{
    struct dent d;
    register struct dent *dp;
    char lbuf[INPUTWORDLEN + MAXAFFIXLEN + 2 * MASKBITS];
    FILE *dictf;
    int i;
    int h;

    if ((dictf = fopen(Dfile, "r")) == NULL) {
        fprintf(stderr, BHASH_C_CANT_OPEN_DICT);
        exit(1);
    }

    alloc_hashtbl();

    i = 0;
    while (fgets(lbuf, sizeof lbuf, dictf) != NULL) {  /* for every line in dictionary ... */
        possible_write_i(i);
        i++;

        if (makedent(lbuf, sizeof lbuf, &d) < 0)   /* alloc dic. entry */
            continue;
        
        h = hash(strtosichar(d.word, 1), hashsize);

        dp = &hashtbl[h];
        if ((dp->flagfield & USED) == 0) {   /* no collision */
            *dp = d;   /* add new dic. entry to the hash table */
#ifndef NO_CAPITALIZATION_SUPPORT
            add_entry_with_correct_capitalization(&d, dp);  /**CHANGE*/
#endif
        } else {
            collision_treatement(&d, dp, h);
        }
    }
    if (!silent)
        fprintf(stderr, "\n");
    fclose(dictf);
}


static void write_i_in_Cfile(int i)
{
    register FILE *d;
    
    if (!silent)
        fprintf(stderr, BHASH_C_WORD_COUNT, i);
    if ((d = fopen(Cfile, "w")) == NULL) {
        fprintf(stderr, CANT_CREATE, Cfile);
        exit(1);
    }
    fprintf(d, "%d\n", i);
    fclose(d);
}

static void newcount(void)
{
    char buf[INPUTWORDLEN + MAXAFFIXLEN + 2 * MASKBITS];
#ifndef NO_CAPITALIZATION_SUPPORT
    ichar_t ibuf[INPUTWORDLEN + MAXAFFIXLEN + 2 * MASKBITS];
#endif
    register FILE *d;
    register int i;
#ifndef NO_CAPITALIZATION_SUPPORT
    ichar_t lastibuf[sizeof ibuf / sizeof(ichar_t)];
    int headercounted;
    int followcase;
    register char *cp;
#endif

    if (!silent)
        fprintf(stderr, BHASH_C_COUNTING);

    if ((d = fopen(Dfile, "r")) == NULL) {
        fprintf(stderr, BHASH_C_CANT_OPEN_DICT);
        exit(1);
    }

#ifndef NO_CAPITALIZATION_SUPPORT
    headercounted = 0;
    lastibuf[0] = 0;
#endif
    for (i = 0;  fgets(buf, sizeof buf, d);  ) {
        possible_write_i(++i);
#ifndef NO_CAPITALIZATION_SUPPORT
        cp = index(buf, hashheader.flagmarker);
        if (cp != NULL)
            *cp = '\0';
        if (strtoichar(ibuf, buf, INPUTWORDLEN * sizeof(ichar_t), 1))
          fprintf(stderr, WORD_TOO_LONG(buf));
        followcase = (whatcap(ibuf) == FOLLOWCASE);
        upcase(ibuf);
        if (icharcmp(ibuf, lastibuf) != 0)
            headercounted = 0;
        else if (!headercounted) {
            /* First duplicate will take two entries */
            possible_write_i(++i);
            headercounted = 1;
        }
        if (!headercounted  &&  followcase) {
            /* It's followcase and the first entry -- count again */
            if ((++i % 1000) == 0  &&  !silent) {
                fprintf(stderr, "%d ", i);
                fflush(stdout);
            }
            headercounted = 1;
        }
        icharcpy(lastibuf, ibuf);
#endif
    }
    fclose(d);
    write_i_in_Cfile(i);
}



/**
 * @brief Main jbuild code
 *
 * @param argc number of arguments in the command line
 * @param argv array of the arguments passed in the command line
 */
int main(int argc, char *argv[])
{
    if (get_param_info(argc, argv))
        return 1;

    if (yyopen(Lfile))                    /* Open the language file */
        return 1;

    yyinit();                             /* Set up for the parse */

    if (yyparse())        /* Parse the language tables - put rules in a table */
        exit(1);

    act_files_Dfile();

    if (stat(Cfile, &cstat) < 0 || dstat.st_mtime > cstat.st_mtime)
        newcount();

    read_hassize();

    readdict();
 
    write_status_file();

    filltable();

    output();

    return 0;
}
