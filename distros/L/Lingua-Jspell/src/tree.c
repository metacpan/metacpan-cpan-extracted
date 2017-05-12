/*
 * tree.c - a hash style dictionary for user's personal words
 *
 * Pace Willisson, 1983
 * Hash support added by Geoff Kuenning, 1987
 *
 * Copyright 1987, 1988, 1989, 1992, 1993, Geoff Kuenning, Granada Hills, CA
 * All rights reserved.
 */

#include <unistd.h>
#include <string.h>
#include <ctype.h>
#include <errno.h>
#include "jsconfig.h"
#include "jspell.h"
#include "proto.h"
#include "msgs.h"

void         treeinit(char *p, char *LibDict);
static FILE *trydict(char *dictname, char *home, char *prefix, char *suffix);
static void  treeload(FILE * dictf);
void         treeinsert(char * word, int wordlen, int keep);
static struct dent *tinsert(struct dent *proto, hash_info *dic);
struct dent *treelookup(register ichar_t *word, hash_info *dic);
#if SORTPERSONAL != 0
static int   pdictcmp(struct dent ** enta, struct dent **entb);
#endif /* SORTPERSONAL != 0 */
void         treeoutput(void);
VOID *       mymalloc(unsigned int size);
void         myfree(VOID * ptr);
#ifdef REGEX_LOOKUP
char *       do_regex_lookup(char * expr, int whence);
#endif /* REGEX_LOOKUP */



/*
 * Hash table sizes.  Prime is probably a good idea, though in truth I
 * whipped the algorithm up on the spot rather than looking it up, so
 * who knows what's really best?  If we overflow the table, we just
 * use a double-and-add-1 algorithm.
 */
static int goodsizes[] =
    {
    53, 223, 907, 3631
    };

static char  personaldict[MAXPATHLEN];
static FILE *dictf;
static int   newwords = 0;

static int repl_inited = 0;

/*---------------------------------------------------------------------------*/

void init_dic(hash_info *dic)
{
   dic->cantexpand = 0;
   dic->hsize = 0;
   dic->hcount = 0;
}

/*
 * p - Value specified in -p switch
 * LibDict - Root of default dict name
 */
void treeinit(char *p, char *LibDict) {
   int   abspath;                 /* NZ if p is abs path name */
   char *h;                       /* Home directory name */
   char  seconddict[MAXPATHLEN];  /* Name of secondary dict */
   FILE *secondf;                 /* Access to second dict file */

   init_dic(&pers);
   /*
   ** If -p was not specified, try to get a default name from the
   ** environment.  After this point, if p is null, the the value in
   ** personaldict is the only possible name for the personal dictionary.
   ** If p is non-null, then there is a possibility that we should
   ** prepend HOME to get the correct dictionary name.
   */
   if (p == NULL)
      p = getenv(PDICTVAR);
   /*
   ** if p exists and begins with '/' we don't really need HOME,
   ** but it's not very likely that HOME isn't set anyway.
   */
   if ((h = getenv("HOME")) == NULL)
      return;

   if (p == NULL) {
      /*
       * No -p and no PDICTVAR.  We will use LibDict and DEFPAFF to
       * figure out the name of the personal dictionary and where it
       * is.  The rules are as follows:
       *
       * (1) If there is a local dictionary and a HOME dictionary,
       *     both are loaded, but changes are saved in the local one.
       *     The dictionary to save changes in is named "personaldict".
       * (2) Dictionaries named after the affix file take precedence
       *     over dictionaries with the default suffix (DEFPAFF).
       * (3) Dictionaries named with the new default names
       *     (DEFPDICT/DEFPAFF) take precedence over the old ones
       *     (OLDPDICT/OLDPAFF).
       * (4) Dictionaries aren't combined unless they follow the same
       *     naming scheme.
       * (5) If no dictionary can be found, a new one is created in
       *     the home directory, named after DEFPDICT and the affix
       *     file.
       */
      dictf = trydict(personaldict, (char *) NULL, DEFPDICT, LibDict);
      secondf = trydict(seconddict, h, DEFPDICT, LibDict);
      if (dictf == NULL  &&  secondf == NULL) {
         dictf = trydict(personaldict, (char *) NULL, DEFPDICT, DEFPAFF);
         secondf = trydict(seconddict, h, DEFPDICT, DEFPAFF);
      }
      if (dictf == NULL  &&  secondf == NULL) {
         dictf = trydict(personaldict, (char *) NULL, OLDPDICT, LibDict);
         secondf = trydict(seconddict, h, OLDPDICT, LibDict);
      }
      if (dictf == NULL  &&  secondf == NULL) {
         dictf = trydict(personaldict, (char *) NULL, OLDPDICT, OLDPAFF);
         secondf = trydict(seconddict, h, OLDPDICT, OLDPAFF);
      }
      if (personaldict[0] == '\0') {
         if (seconddict[0] != '\0')
            strcpy(personaldict, seconddict);
         else
            sprintf(personaldict, "%s/%s%s", h, DEFPDICT, LibDict);
      }
      if (dictf != NULL) {
         treeload(dictf);
         fclose(dictf);
      }
      if (secondf != NULL) {
         treeload(secondf);
         fclose(secondf);
      }
   }
   else {
      /*
      ** Figure out if p is an absolute path name.  Note that beginning
      ** with "./" and "../" is considered an absolute path, since this
      ** still means we can't prepend HOME.
      */
      abspath = (*p == '/'  ||  strncmp(p, "./", 2) == 0
                 ||  strncmp(p, "../", 3) == 0);
      if (abspath) {
         strcpy(personaldict, p);
         if ((dictf = fopen(personaldict, "r")) != NULL) {
            treeload(dictf);
            fclose(dictf);
         }
      }
      else {
         /*
         ** The user gave us a relative pathname.  We will try it
         ** locally, and if that doesn't work, we'll try the home
         ** directory.  If neither exists, it will be created in
         ** the home directory if words are added.
         */
         strcpy(personaldict, p);
         if ((dictf = fopen(personaldict, "r")) != NULL) {
            treeload(dictf);
            fclose(dictf);
         }
         else if (!abspath) {
            /* Try the home */
            sprintf(personaldict, "%s/%s", h, p);
            if ((dictf = fopen(personaldict, "r")) != NULL) {
               treeload(dictf);
               fclose(dictf);
            }
         }
         /*
          * If dictf is null, we couldn't open the dictionary
          * specified in the -p switch.  Complain.
          */
         if (dictf == NULL) {
            fprintf(stderr, CANT_OPEN, p);
            perror("");
            return;
         }
      }
   }

   if (!lflag  &&  !aflag
       &&  access(personaldict, 2) < 0  &&  errno != ENOENT) {
       fprintf(stderr, TREE_C_CANT_UPDATE, personaldict);
       sleep((unsigned) 2);
   }
}

/*---------------------------------------------------------------------------*/
/*
 * Try to open a dictionary.  As a side effect, leaves the dictionary
 * name in "filename" if one is found, and leaves a null string there
 * otherwise.
 */
static FILE *trydict(
     char *filename,        /* Where to store the file name */
     char *home,            /* Home directory */
     char *prefix,          /* Prefix for dictionary */
     char *suffix)          /* Suffix for dictionary */
{
   FILE *dictf;           /* Access to dictionary file */

   if (home == NULL)
      sprintf(filename, "%s%s", prefix, suffix);
   else
      sprintf(filename, "%s/%s%s", home, prefix, suffix);
   dictf = fopen(filename, "r");
   if (dictf == NULL)
      filename[0] = '\0';
   return dictf;
}

/*---------------------------------------------------------------------------*/

static void treeload(register FILE *loadfile  /* File to load words from */)
{
   char buf[BUFSIZ];        /* Buffer for reading pers dict */

   while (fgets(buf, sizeof buf, loadfile) != NULL)
      treeinsert(buf, sizeof buf, 1);
   newwords = 0;
}

/*---------------------------------------------------------------------------*/

void treat_overflow(hash_info *dic, int oldhsize, struct dent *oldhtab)
{
   fprintf(stderr, TREE_C_NO_SPACE);
   /*
    * Try to continue anyway, since our overflow
    * algorithm can handle an overfull (100%+) table,
    * and the malloc very likely failed because we
    * already have such a huge table, so small mallocs
    * for overflow entries will still work.
    */
   if (oldhtab == NULL)
      exit(1);                  /* No old table, can't go on */
   fprintf(stderr, TREE_C_TRY_ANYWAY);
   dic->cantexpand = 1;              /* Suppress further messages */
   dic->hsize = oldhsize;        /* Put things back */
   dic->htab = oldhtab;                /* ... */
   newwords = 1;                /* And pretend it worked */
}

/*---------------------------------------------------------------------------*/

/* Re-insert old entries into new table */
void reinsert_old_entries(hash_info *dic, int oldhsize, struct dent *oldhtab)
{
   int i;
   register struct dent * dp;
   struct dent *olddp;
#ifndef NO_CAPITALIZATION_SUPPORT
   struct dent *newdp;
   int isvariant;
#endif

   for (i = 0;  i < oldhsize;  i++) {
      dp = &oldhtab[i];
      if (dp->flagfield & USED) {
#ifdef NO_CAPITALIZATION_SUPPORT
         tinsert(dp, dic);
#else
         newdp = tinsert(dp, dic);
         isvariant = (dp->flagfield & MOREVARIANTS);
#endif
         dp = dp->next;
#ifdef NO_CAPITALIZATION_SUPPORT
         while (dp != NULL) {
            tinsert(dp, dic);
            olddp = dp;
            dp = dp->next;
            free((char *) olddp);
         }
#else
         while (dp != NULL) {
            if (isvariant) {
               isvariant = dp->flagfield & MOREVARIANTS;
               olddp = newdp->next;
               newdp->next = dp;
               newdp = dp;
               dp = dp->next;
               newdp->next = olddp;
            }
            else {
               isvariant = dp->flagfield & MOREVARIANTS;
               newdp = tinsert(dp, dic);
               olddp = dp;
               dp = dp->next;
               free((char *) olddp);
            }
         }
#endif
      }
   }
   if (oldhtab != NULL)
      free((char *) oldhtab);
}

/*---------------------------------------------------------------------------*/

void new_hsize(hash_info *dic)
{
   int i;

   for (i = 0;  i < sizeof goodsizes / sizeof(goodsizes[0]);  i++) {
      if (goodsizes[i] > dic->hsize)
         break;
   }
   if (i >= sizeof goodsizes / sizeof goodsizes[0])
      dic->hsize += dic->hsize + 1;
   else
      dic->hsize = goodsizes[i];
}

/*---------------------------------------------------------------------------*/

void new_hash_space(hash_info *dic)
{
    /* register int i; */
   struct dent *oldhtab;
   int oldhsize;

   /*
    * Expand hash table when it is MAXPCT % full.
    */
   if (!dic->cantexpand  &&  (dic->hcount * 100) / MAXPCT >= dic->hsize) {
      oldhsize = dic->hsize;
      oldhtab = dic->htab;
      new_hsize(dic);
      dic->htab =
        (struct dent *) calloc((unsigned) dic->hsize, sizeof(struct dent));
      if (dic->htab == NULL)
         treat_overflow(dic, oldhsize, oldhtab);
      else
         reinsert_old_entries(dic, oldhsize, oldhtab);
   }
}

/*---------------------------------------------------------------------------*/

void ins_repl_all(char *word, char *st_repl)
{
   struct dent wordent;
   char ent[255];

   if (repl_inited == 0) {init_dic(&repl); repl_inited = 1;}

   new_hash_space(&repl);

   sprintf(ent, "%s/%s", word, st_repl);
/*   printf("DEB-Vou inserir %s\n\r", ent); */
   if (makedent(ent, ICHARTOSSTR_SIZE, &wordent) < 0) {
      putchar(7);
      return;                      /* Word must be too big or something */
   }
   tinsert(&wordent, &repl);
}

/*---------------------------------------------------------------------------*/

void treeinsert(char *word,     /* Word to insert - must be canonical */
                int wordlen,     /* Length of the word buffer */
                int keep)
{
   struct dent  wordent;
   register struct dent * dp;
   ichar_t nword[INPUTWORDLEN + MAXAFFIXLEN];

   new_hash_space(&pers);

   /*
   ** We're ready to do the insertion.  Start by creating a sample
   ** entry for the word.
   */
   if (makedent(word, wordlen, &wordent) < 0)
      return;                        /* Word must be too big or something */
   if (keep)
      wordent.flagfield |= KEEP;
   /*
   ** Now see if word or a variant is already in the table.  We use the
   ** capitalized version so we'll find the header, if any.
   **/
   strtoichar(nword, word, sizeof nword, 1);
   upcase(nword);
   if ((dp = lookup(nword, 1)) != NULL) {
      /* It exists.  Combine caps and set the keep flag. */
      if (combinecaps(dp, &wordent) < 0) {
         free(wordent.word);
         return;
      }
   }
   else {
      /* It's new. Insert the word. */
      dp = tinsert(&wordent, &pers);
#ifndef NO_CAPITALIZATION_SUPPORT
       if (captype(dp->flagfield) == FOLLOWCASE)
          addvheader(dp);
#endif
   }
   newwords |= keep;
}

/*---------------------------------------------------------------------------*/

static struct dent *tinsert(struct dent *proto,  /* Prototype entry to copy */
                            hash_info *dic)
{
   ichar_t iword[INPUTWORDLEN + MAXAFFIXLEN];
   register int hcode;
   register struct dent *hp;    /* Next trial entry in hash table */
   register struct dent *php;   /* Prev. value of hp, for chaining */

   if (strtoichar(iword, proto->word, sizeof iword, 1)) {
      fprintf(stderr, WORD_TOO_LONG (proto->word));
      return NULL;
   }
#ifdef NO_CAPITALIZATION_SUPPORT
   upcase(iword);
#endif
   hcode = hash(iword, dic->hsize);
   php = NULL;
   hp = &(dic->htab[hcode]);
   if (hp->flagfield & USED) {
      while (hp != NULL) {
         php = hp;
         hp = hp->next;
      }
      hp = (struct dent *) calloc(1, sizeof(struct dent));
      if (hp == NULL) {
         fprintf(stderr, TREE_C_NO_SPACE);
         exit(1);
      }
   }
   *hp = *proto;
   if (php != NULL)
      php->next = hp;
   hp->next = NULL;
   return hp;
}



/**
 * search in dic dictionary 
 */
struct dent *treelookup(register ichar_t *word, hash_info *dic) {
    register int hcode;
    register struct dent * hp;
    char chword[INPUTWORDLEN + MAXAFFIXLEN];

    if (dic->hsize <= 0) return NULL;
    ichartostr(chword, word, sizeof chword, 1);
    hcode = hash(word, dic->hsize);
    hp = &(dic->htab[hcode]);
    while (hp != NULL  &&  (hp->flagfield & USED)) {
	/* printf("DEB- hp->word=%s\n", hp->word); */
	if (strcmp(chword, hp->word) == 0 && (!(hp->saw) || !saw_mode)) {  /* found */
	    if (saw_mode) hp->saw = 1;
	    break;
	}
#ifndef NO_CAPITALIZATION_SUPPORT
	while (hp->flagfield & MOREVARIANTS)
	    hp = hp->next;
#endif
	hp = hp->next;
    }

    if (hp != NULL  &&  (hp->flagfield & USED))
	return hp;
    else
	return NULL;
}


/**
 * put saw off in personal dictionary
 */
void tree_saw_off(register ichar_t *word) {
    register int hcode;
    register struct dent * hp;
    char chword[INPUTWORDLEN + MAXAFFIXLEN];

    if (pers.hsize <= 0) return;
    ichartostr(chword, word, sizeof chword, 1);
    hcode = hash(word, pers.hsize);
    hp = &(pers.htab[hcode]);
    while (hp != NULL  &&  (hp->flagfield & USED)) {
	if (strcmp(chword, hp->word) == 0)   /* found */
	    hp->saw = 0;
#ifndef NO_CAPITALIZATION_SUPPORT
	while (hp->flagfield & MOREVARIANTS)
	    hp = hp->next;
#endif
	hp = hp->next;
    }
}

/*---------------------------------------------------------------------------*/

#if SORTPERSONAL != 0
/* Comparison routine for sorting the personal dictionary with qsort */
static int pdictcmp(struct dent **enta, struct dent **entb) {
    /* The parentheses around *enta / *entb below are NECESSARY!
     * Otherwise the compiler reads it as *(enta->word), or enta->word[0], 
     * which is illegal (but gcc takes it and produces wrong code).
     */
    return casecmp((*enta)->word, (*entb)->word, 1);
}
#endif

/*---------------------------------------------------------------------------*/

void treeoutput(void) {
    register struct dent *cent;       /* Current entry */
    register struct dent *lent;       /* Linked entry */
#if SORTPERSONAL != 0
    int pdictsize;                    /* Number of entries to write */
    struct dent **sortlist;           /* List of entries to be sorted */
    register struct dent **sortptr;   /* Handy pointer into sortlist */
#endif
    register struct dent *ehtab;      /* End of pershtab, for fast looping */

    if (newwords == 0)
       return;

    if ((dictf = fopen(personaldict, "w")) == NULL) {
       fprintf(stderr, CANT_CREATE, personaldict);
       return;
    }

#if SORTPERSONAL != 0
    /*
     * If we are going to sort the personal dictionary, we must know
     * how many items are going to be sorted.
     */
    pdictsize = 0;
    if (pers.hcount >= SORTPERSONAL)
       sortlist = NULL;
    else {
        for (cent = pers.htab, ehtab = pers.htab + pers.hsize;
             cent < ehtab; cent++) {
            for (lent = cent;  lent != NULL;  lent = lent->next) {
                if ((lent->flagfield & (USED | KEEP)) == (USED | KEEP))
                    pdictsize++;
#ifndef NO_CAPITALIZATION_SUPPORT
                while (lent->flagfield & MOREVARIANTS)
                  lent = lent->next;
#endif
            }
        }
        for (cent = hashtbl, ehtab = hashtbl + hashsize;
             cent < ehtab; cent++)  {
            if ((cent->flagfield & (USED | KEEP)) == (USED | KEEP)) {
                /*
                ** We only want to count variant headers
                ** and standalone entries.  These happen
                ** to share the characteristics in the
                ** test below.  This test will appear
                ** several more times in this routine.
                */
#ifndef NO_CAPITALIZATION_SUPPORT
                if (captype (cent->flagfield) != FOLLOWCASE
                  &&  cent->word != NULL)
#endif
                    pdictsize++;
            }
        }
        sortlist = (struct dent **) malloc(pdictsize * sizeof(struct dent));
    }
    if (sortlist == NULL) {
#endif
        for (cent = pers.htab, ehtab = pers.htab + pers.hsize;
             cent < ehtab; cent++) {
            for (lent = cent;  lent != NULL;  lent = lent->next) {
                if ((lent->flagfield & (USED | KEEP)) == (USED | KEEP)) {
                    toutent(dictf, lent, 1);
#ifndef NO_CAPITALIZATION_SUPPORT
                    while (lent->flagfield & MOREVARIANTS)
                        lent = lent->next;
#endif
                }
            }
        }
        for (cent = hashtbl, ehtab = hashtbl + hashsize;
             cent < ehtab; cent++) {
            if ((cent->flagfield & (USED | KEEP)) == (USED | KEEP)) {
#ifndef NO_CAPITALIZATION_SUPPORT
                if (captype(cent->flagfield) != FOLLOWCASE
                    &&  cent->word != NULL)
#endif
                    toutent(dictf, cent, 1);
            }
        }
#if SORTPERSONAL != 0
        return;
    }
    /*
     * Produce dictionary in sorted order.  We used to do this
     * destructively, but that turns out to fail because in some modes
     * the dictionary is written more than once.  So we build an
     * auxiliary pointer table (in sortlist) and sort that.  This is
     * faster anyway, though it uses more memory.
     */
    sortptr = sortlist;
    for (cent = pers.htab, ehtab = pers.htab + pers.hsize; cent < ehtab; cent++) {
       for (lent = cent;  lent != NULL;  lent = lent->next) {
          if ((lent->flagfield & (USED | KEEP)) == (USED | KEEP)) {
             *sortptr++ = lent;
#ifndef NO_CAPITALIZATION_SUPPORT
             while (lent->flagfield & MOREVARIANTS)
                lent = lent->next;
#endif
          }
       }
    }
    for (cent = hashtbl, ehtab = hashtbl + hashsize;  cent < ehtab;  cent++) {
       if ((cent->flagfield & (USED | KEEP)) == (USED | KEEP)) {
#ifndef NO_CAPITALIZATION_SUPPORT
          if (captype(cent->flagfield) != FOLLOWCASE  &&  cent->word != NULL)
#endif
             *sortptr++ = cent;
       }
    }
    /* Sort the list */
    qsort((char *) sortlist, (unsigned) pdictsize, sizeof(sortlist[0]),
          (int (*) (const void *, const void *)) pdictcmp);
    /* Write it out */
    for (sortptr = sortlist;  --pdictsize >= 0;  )
       toutent(dictf, *sortptr++, 1);
    free((char *) sortlist);
#endif

    newwords = 0;

    fclose(dictf);
}

/*---------------------------------------------------------------------------*/

VOID *mymalloc(unsigned int size) {
    return malloc((unsigned) size);
}

/*---------------------------------------------------------------------------*/

void myfree(VOID *ptr) {
    if (hashstrings != NULL  &&  (char *) ptr >= hashstrings
	&&  (char *) ptr <= hashstrings + hashheader.stringsize)
	return;                        /* Can't free stuff in hashstrings */
    free(ptr);
}

/*---------------------------------------------------------------------------*/

#ifdef REGEX_LOOKUP

/** 
 * check the hashed dictionary for words matching the regex. return
 * the a matching string if found else return NULL 
 *
 * expr - regular expression to use in the match
 * whence - 0 = start at the beg with new regx, else
 *          continue from cur point w/ old regex
 */
char *do_regex_lookup(char *expr, int whence) {
    static struct dent *curent;
    static int          curindex;
    static struct dent *curpersent;
    static int          curpersindex;
    static char *       cmp_expr;
    char                dummy[INPUTWORDLEN + MAXAFFIXLEN];
    ichar_t *           is;

    if (whence == 0) {
	is = strtosichar(expr, 0);
	upcase (is);
	expr = ichartosstr(is, 1);
	cmp_expr = REGCMP(expr);
	curent = hashtbl;
	curindex = 0;
	curpersent = pershtab;
	curpersindex = 0;
    }

    /* search the dictionary until the word is found or the words run out */
    for (  ; curindex < hashsize;  curent++, curindex++) {
	if (curent->word != NULL
	    &&  REGEX (cmp_expr, curent->word, dummy) != NULL) {
	    curindex++;
	    /* Everybody's gotta write a wierd expression once in a while! */
	    return curent++->word;
	}
    }
    /* Try the personal dictionary too */
    for (  ; curpersindex < pershsize;  curpersent++, curpersindex++) {
	if ((curpersent->flagfield & USED) != 0
	    &&  curpersent->word != NULL
	    &&  REGEX(cmp_expr, curpersent->word, dummy) != NULL) {
	    curpersindex++;
	    /* Everybody's gotta write a wierd expression once in a while! */
	    return curpersent++->word;
	}
    }
    return NULL;
}
#endif /* REGEX_LOOKUP */
