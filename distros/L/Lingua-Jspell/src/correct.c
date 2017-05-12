/* -*- Mode: C; c-file-style: "stroustrup" -*- */

/**
 * @file
 * @brief routines to manage the higher-level aspects of spell-checking
 *
 * Copyright 1983, by Pace Willisson
 * Copyright 1992, 1993, Geoff Kuenning, Granada Hills, CA
 * Copyright 1994-2006 Ulisses Pinto & José João Almeida & Alberto Simões
 *                     Projecto Natura, Universidade do Minho
 */

#include <string.h>

#include <ctype.h>
#include "jsconfig.h"
#include "jspell.h"
#include "proto.h"
#include "msgs.h"
#include "version.h"
#include "good.h"

void checkfile(void);
int  casecmp(char *a, char *b, int canonical);
void makepossibilities(ichar_t *word);
int  compoundgood(ichar_t *word);
int  ins_root_cap(ichar_t *word, ichar_t *pattern, int prestrip, int preadd, 
                  int sufstrip, int sufadd, struct dent *firstdent, 
                  struct flagent *pfxent, struct flagent *sufent);
void askmode(void);


/*---------------------------------------------------------------------------*/

void printhelp(register FILE *helpout)        /* File to write help to */
{
    fprintf(helpout, CORR_C_HELP_1);
    fprintf(helpout, CORR_C_HELP_2);
    fprintf(helpout, CORR_C_HELP_3);
    fprintf(helpout, CORR_C_HELP_4);
    fprintf(helpout, CORR_C_HELP_5);
    fprintf(helpout, CORR_C_HELP_6);
    fprintf(helpout, CORR_C_HELP_7);
    fprintf(helpout, CORR_C_HELP_8);
    fprintf(helpout, CORR_C_HELP_9);

    fprintf(helpout, CORR_C_HELP_COMMANDS);

    fprintf(helpout, CORR_C_HELP_R_CMD);
    fprintf(helpout, CORR_C_HELP_E_CMD);
    fprintf(helpout, CORR_C_HELP_BLANK);
    fprintf(helpout, CORR_C_HELP_A_CMD);
    fprintf(helpout, CORR_C_HELP_I_CMD);
    fprintf(helpout, CORR_C_HELP_U_CMD);
    fprintf(helpout, CORR_C_HELP_0_CMD);
    fprintf(helpout, CORR_C_HELP_L_CMD);
    fprintf(helpout, CORR_C_HELP_X_CMD);
    fprintf(helpout, CORR_C_HELP_Q_CMD);
    fprintf(helpout, CORR_C_HELP_BANG);
    fprintf(helpout, CORR_C_HELP_REDRAW);
    fprintf(helpout, CORR_C_HELP_SUSPEND);
    fprintf(helpout, CORR_C_HELP_HELP);
}

/*---------------------------------------------------------------------------*/
/* checkfile                                                                 */
/*---------------------------------------------------------------------------*/

static void init_zero_contextbufs()
{
    int bufno;

    for (bufno = 0;  bufno < contextsize;  bufno++)
        contextbufs[bufno][0] = '\0';
}

/*---------------------------------------------------------------------------*/

static void move_contextbufs_down()
{
    int bufno;

    for (bufno = contextsize;  --bufno > 0;  )
        strcpy(contextbufs[bufno], contextbufs[bufno - 1]);
}

/*---------------------------------------------------------------------------*/

void checkfile(void)
{
    int bufsize, ch;

    init_zero_contextbufs();

    for (  ;  ;  ) {
        move_contextbufs_down();
        if (quit) {       /* quit can't be set in l mode */
            while (fgets(contextbufs[0], sizeof contextbufs[0], infile) != NULL)
                fputs(contextbufs[0], outfile);
            break;
        }
        /*
         * Only read in enough characters to fill half this buffer so that any
         * corrections we make are not likely to cause an overflow.
         */
        if (fgets(contextbufs[0], (sizeof contextbufs[0]) / 2, infile) == NULL)
            break;
        /*
         * If we didn't read to end-of-line, we may have ended the
         * buffer in the middle of a word.  So keep reading until we
         * see some sort of character that can't possibly be part of a
         * word. (or until the buffer is full, which fortunately isn't
         * all that likely).
         */
        bufsize = strlen(contextbufs[0]);
        if (bufsize == (sizeof contextbufs[0]) / 2 - 1) {
            ch = (unsigned char) contextbufs[0][bufsize - 1];
            while (bufsize < sizeof contextbufs[0] - 1
                   && (iswordch((ichar_t) ch)  ||  isboundarych((ichar_t) ch)
                       || isstringstart(ch)))  {
                ch = getc(infile);
                if (ch == EOF)
                    break;
                contextbufs[0][bufsize++] = (char) ch;
                contextbufs[0][bufsize] = '\0';
            }
        }
        checkline(outfile);
    }
}

/*---------------------------------------------------------------------------*/
/*---------------------------------------------------------------------------*/

static int posscmp(char *a, char *b)
{
    return casecmp(a, b, 0);
}

/*---------------------------------------------------------------------------*/

int casecmp(char *a, char *b, int canonical)
/* int canonical - NZ for canonical string chars */
{
    register ichar_t *ap, *bp;
    ichar_t inta[INPUTWORDLEN + 4 * MAXAFFIXLEN + 4];
    ichar_t intb[INPUTWORDLEN + 4 * MAXAFFIXLEN + 4];

    strtoichar(inta, a, sizeof inta, canonical);
    strtoichar(intb, b, sizeof intb, canonical);
    for (ap = inta, bp = intb;  *ap != 0;  ap++, bp++) {
        if (*ap != *bp) {
            if (*bp == '\0')
                return hashheader.sortorder[*ap];
            else if (mylower(*ap)) {
                if (mylower(*bp)  ||  mytoupper(*ap) != *bp)
                    return (int) hashheader.sortorder[*ap]
                        - (int) hashheader.sortorder[*bp];
            }
            else {
                if (myupper(*bp)  ||  mytolower(*ap) != *bp)
                    return (int) hashheader.sortorder[*ap]
                        - (int) hashheader.sortorder[*bp];
            }
        }
      }
    if (*bp != '\0')
      return -(int) hashheader.sortorder[*bp];
    for (ap = inta, bp = intb;  *ap;  ap++, bp++) {
        if (*ap != *bp) {
            return (int) hashheader.sortorder[*ap]
                - (int) hashheader.sortorder[*bp];
        }
    }
    return 0;
}

/*---------------------------------------------------------------------------*/
/* makepossibilities                                                         */
/*---------------------------------------------------------------------------*/

static int insert(register ichar_t *word)
{
    register int   i;
    register char *realword;

    realword = ichartosstr(word, 0);
    for (i = 0; i < pcount; i++) {
        if (strcmp(possibilities[i], realword) == 0)
            return 0;
    }

    strcpy(possibilities[pcount++], realword);
    i = strlen(realword);
    if (i > maxposslen)
        maxposslen = i;
    if (pcount >= MAXPOSSIBLE)
        return -1;
    else
        return 0;
}

/*---------------------------------------------------------------------------*/

/* Insert one or more correctly capitalized versions of word */
static int ins_cap(ichar_t *word, ichar_t *pattern)
{
    int prestrip, preadd, sufstrip, sufadd, hitno;

    if (*word == 0)
        return 0;

    for (hitno = numhits;  --hitno >= 0;  ) {
        if (hits[hitno].prefix) {
            prestrip = hits[hitno].prefix->stripl;
            preadd = hits[hitno].prefix->affl;
        }
        else
            prestrip = preadd = 0;
        if (hits[hitno].suffix) {
            sufstrip = hits[hitno].suffix->stripl;
            sufadd = hits[hitno].suffix->affl;
        }
        else
            sufadd = sufstrip = 0;
        if (ins_root_cap(word, pattern, prestrip, preadd, sufstrip, sufadd,
                         hits[hitno].dictent, hits[hitno].prefix, hits[hitno].suffix)
            < 0)
            return -1;
    }
    return 0;
}

/*---------------------------------------------------------------------------*/

#ifndef NO_CAPITALIZATION_SUPPORT
static void wrongcapital(register ichar_t *word)
{
    ichar_t newword[MAXWLEN];

    /* When the third parameter to "good" is nonzero, it ignores case.
       If the word matches this way, "ins_cap" will recapitalize it correctly.
    */
    if (bgood(word, 0, 1, 1)) {
        icharcpy(newword, word);
        upcase(newword);
        ins_cap(newword, word);
    }
}
#endif

/*---------------------------------------------------------------------------*/

static void wrongletter(register ichar_t *word)
{
    register int i, j, n;
    ichar_t savechar;
    ichar_t newword[MAXWLEN];
    
    n = icharlen(word);
    icharcpy(newword, word);
#ifndef NO_CAPITALIZATION_SUPPORT
    upcase(newword);
#endif
    
    for (i = 0; i < n; i++) {
        savechar = newword[i];
        for (j = 0; j < Trynum; ++j) {
            if (Try[j] == savechar)
                continue;
            newword[i] = Try[j];
            if (bgood(newword, 0, 1, 1)) {
                if (ins_cap(newword, word) < 0)
                    return;
            }
        }
        newword[i] = savechar;
    }
}

/*---------------------------------------------------------------------------*/

static void extraletter(register ichar_t *word)
{
    ichar_t newword[MAXWLEN];
    register ichar_t *p, *r;
    
    if (icharlen(word) < 2)
        return;
    
    icharcpy(newword, word + 1);
    for (p = word, r = newword;  *p != 0;  ) {
        if (bgood(newword, 0, 1, 1)) {
            if (ins_cap(newword, word) < 0)
                return;
        }
        *r++ = *p++;
    }
}

/*---------------------------------------------------------------------------*/

static void missingletter(ichar_t *word)
{
    ichar_t newword[MAXWLEN + 1];
    register ichar_t *p, *r;
    register int      i;

    icharcpy(newword + 1, word);
    for (p = word, r = newword;  *p != 0; ) {   /* for each char. in the word */
        for (i = 0;  i < Trynum;  i++) {         /* try all possible chars */
            *r = Try[i];
            if (bgood(newword, 0, 1, 1)) {  /* the new word exists in dictionary */
                if (ins_cap(newword, word) < 0)
                    return;
            }
        }
        *r++ = *p++;
    }
    for (i = 0;  i < Trynum;  i++) {
        *r = Try[i];
        if (bgood(newword, 0, 1, 1)) {
            if (ins_cap(newword, word) < 0)
                return;
        }
    }
}

/*---------------------------------------------------------------------------*/

static void missingspace(ichar_t *word)
{
   ichar_t newword[MAXWLEN + 1];
   register ichar_t *p, savech;

   /*
   ** We don't do words of length less than 3;  this keeps us from
   ** splitting all two-letter words into two single letters.
   ** Also, we just duplicate the existing capitalizations, rather
   ** than try to reconstruct both, which would require a smarter
   ** version of ins_cap.
   */
   if (word[0] == 0  ||  word[1] == 0  ||  word[2] == 0)
      return;
   icharcpy(newword, word);
   for (p = newword + 1;  *p != 0;  p++) {
      savech = *p;
      *p = 0;
      if (bgood(newword, 0, 1, 1)) {  /* left word correct */
         *p = savech;
         if (bgood(p, 0, 1, 1)) {     /* right word correct */
            *p = ' ';
            icharcpy(p + 1, word + (p - newword));
            if (insert(newword) < 0)
               return;
            *p = '-';
            if (insert(newword) < 0)
               return;
            icharcpy(p, word + (p - newword));
         }
      }
      *p = savech;
   }
}

/*---------------------------------------------------------------------------*/

static void transposedletter(register ichar_t *word)
{
   ichar_t newword[MAXWLEN];
   register ichar_t *p, temp;

   icharcpy(newword, word);
   for (p = newword;  p[1] != 0;  p++) {
      temp = *p;
      *p = p[1];
      p[1] = temp;
      if (bgood(newword, 0, 1, 1)) {
         if (ins_cap(newword, word) < 0)
            return;
      }
      temp = *p;
      *p = p[1];
      p[1] = temp;
   }
}

/*---------------------------------------------------------------------------*/

static void tryveryhard(ichar_t *word)
{
   bgood(word, 1, 0, 1);   /* the second parameter is 1 to ignoreflagbits */
}

/*---------------------------------------------------------------------------*/

void makepossibilities(register ichar_t *word)
{
    register int i;

    for (i = 0; i < MAXPOSSIBLE; i++)
        possibilities[i][0] = 0;
    pcount = 0;
    maxposslen = 0;
    easypossibilities = 0;   /* number of possiblities using 4 usual errors */
    my_poss_count = 0;

#ifndef NO_CAPITALIZATION_SUPPORT
    wrongcapital(word);
#endif

    /*
     * according to Pollock and Zamora, CACM April 1984 (V. 27, No. 4),
     * page 363, the correct order for this is:
     * OMISSION = TRANSPOSITION > INSERTION > SUBSTITUTION
     * thus, it was exactly backwards in the old version. -- PWP
     */
    if (!yflag) {  /* not supressing typing errors */
        if (pcount < MAXPOSSIBLE)
            missingletter(word);               /* omission */
        if (pcount < MAXPOSSIBLE)
            transposedletter(word);       /* transposition */
        if (pcount < MAXPOSSIBLE)
            extraletter(word);                /* insertion */
        if (pcount < MAXPOSSIBLE)
            wrongletter(word);             /* substitution */

        if (missingspaceflag  &&  pcount < MAXPOSSIBLE && !aflag)
            missingspace(word);        /* two words */
    }
    easypossibilities = pcount;

    if (tryhardflag)
        tryveryhard(word);

    if ((sortit  || (pcount > easypossibilities))  &&  pcount) {
        if (easypossibilities > 0  &&  sortit)
            qsort((char *) possibilities, (unsigned) easypossibilities,
                  sizeof(possibilities[0]),
                  (int (*) (const void *, const void *)) posscmp);
        if (pcount > easypossibilities)
            qsort((char *) &possibilities[easypossibilities][0],
                  (unsigned) (pcount - easypossibilities), sizeof (possibilities[0]),
                  (int (*) (const void *, const void *)) posscmp);
    }
}

/*---------------------------------------------------------------------------*/
/*---------------------------------------------------------------------------*/

int compoundgood(ichar_t *word)
{
   ichar_t newword[MAXWLEN];
   register ichar_t *p, savech;
   long secondcap;        /* Capitalization of 2nd half */

   /*
   ** If missingspaceflag is set, compound words are never ok.
   */
   if (missingspaceflag)
       return 0;
   /*
   ** Test for a possible compound word (for languages like German that
   ** form lots of compounds).
   **
   ** This is similar to missingspace, except we quit on the first hit,
   ** and we won't allow either member of the compound to be a single
   ** letter.
   **
   ** We don't do words of length less than 2 * compoundmin, since
   ** both halves must at least compoundmin letters.
   */
   if (icharlen(word) < 2 * hashheader.compoundmin)
       return 0;
   icharcpy(newword, word);
   p = newword + hashheader.compoundmin;
   for (  ;  p[hashheader.compoundmin - 1] != 0;  p++) {
      savech = *p;
      *p = 0;
      if (bgood(newword, 0, 0, 0)) {
         *p = savech;
         if (bgood(p, 0, 1, 0)) {      /* Accept any case variant in 2nd */
            secondcap = whatcap(p);
            switch (whatcap(newword)) {
               case ANYCASE:
               case CAPITALIZED:
               case FOLLOWCASE:        /* Followcase can have l.c. suffix */
                   return secondcap == ANYCASE;
               case ALLCAPS:
                   return secondcap == ALLCAPS;
            }
         }
      }
      else
         *p = savech;
   }
   return 0;
}

/*---------------------------------------------------------------------------*/
/*---------------------------------------------------------------------------*/

/* ARGSUSED */
int ins_root_cap(ichar_t *word, ichar_t *pattern,
                 int prestrip, int preadd, int sufstrip, int sufadd,
                 struct dent *firstdent,
                 struct flagent *pfxent, struct flagent *sufent)
{
#ifndef NO_CAPITALIZATION_SUPPORT
   register struct dent * dent;
#endif /* NO_CAPITALIZATION_SUPPORT */
   int     firstisupper;
   ichar_t newword[INPUTWORDLEN + 4 * MAXAFFIXLEN + 4];
#ifndef NO_CAPITALIZATION_SUPPORT
   register ichar_t *p;
   int len, i, limit;
#endif /* NO_CAPITALIZATION_SUPPORT */

   icharcpy(newword, word);
   firstisupper = myupper(pattern[0]);
#ifdef NO_CAPITALIZATION_SUPPORT
   /*
   ** Apply the old, simple-minded capitalization rules.
   */
   if (firstisupper) {
      if (myupper(pattern[1]))
         upcase(newword);
      else {
         lowcase(newword);
         newword[0] = mytoupper(newword[0]);
      }
   }
   else
      lowcase(newword);
   return insert(newword);
#else /* NO_CAPITALIZATION_SUPPORT */
#define flagsareok(dent)    \
    ((pfxent == NULL ||  TSTMASKBIT(dent->mask, pfxent->flagbit)) \
      &&  (sufent == NULL ||  TSTMASKBIT(dent->mask, sufent->flagbit)))

    dent = firstdent;
    if ((dent->flagfield & (CAPTYPEMASK | MOREVARIANTS)) == ALLCAPS) {
       upcase(newword);        /* Uppercase required */
       return insert(newword);
    }
    for (p = pattern;  *p;  p++) {
       if (mylower(*p))
          break;
    }
    if (*p == 0) {
       upcase(newword);        /* Pattern was all caps */
       return insert(newword);
    }
    for (p = pattern + 1;  *p;  p++) {
       if (myupper(*p))
          break;
    }
    if (*p == 0) {
       /*
       ** The pattern was all-lower or capitalized.  If that's
       ** legal, insert only that version.
       */
       if (firstisupper) {
          if (captype(dent->flagfield) == CAPITALIZED
              ||  captype(dent->flagfield) == ANYCASE) {
             lowcase(newword);
             newword[0] = mytoupper(newword[0]);
             return insert(newword);
          }
        }
        else {
           if (captype(dent->flagfield) == ANYCASE) {
              lowcase(newword);
              return insert(newword);
           }
        }
        while (dent->flagfield & MOREVARIANTS) {
           dent = dent->next;
           if (captype(dent->flagfield) == FOLLOWCASE
               ||  !flagsareok(dent))
              continue;
           if (firstisupper) {
              if (captype(dent->flagfield) == CAPITALIZED) {
                 lowcase(newword);
                 newword[0] = mytoupper(newword[0]);
                 return insert(newword);
              }
           }
           else {
              if (captype (dent->flagfield) == ANYCASE) {
                 lowcase(newword);
                 return insert(newword);
              }
           }
       }
   }
    /*
    ** Either the sample had complex capitalization, or the simple
    ** capitalizations (all-lower or capitalized) are illegal.
    ** Insert all legal capitalizations, including those that are
    ** all-lower or capitalized.  If the prototype is capitalized,
    ** capitalized all-lower samples.  Watch out for affixes.
    */
    dent = firstdent;
    p = strtosichar(dent->word, 1);
    len = icharlen(p);
    if (dent->flagfield & MOREVARIANTS)
       dent = dent->next;        /* Skip place-holder entry */
    for (  ;  ;  ) {
       if (flagsareok(dent)) {
          if (captype(dent->flagfield) != FOLLOWCASE) {
             lowcase(newword);
             if (firstisupper  ||  captype(dent->flagfield) == CAPITALIZED)
                newword[0] = mytoupper(newword[0]);
             if (insert(newword) < 0)
                return -1;
          }
          else {
             /* Followcase is the tough one. */
             p = strtosichar(dent->word, 1);
             bcopy((char *) (p + prestrip),  (char *) (newword + preadd),
                   (len - prestrip - sufstrip) * sizeof(ichar_t));
             if (myupper(p[prestrip])) {
                for (i = 0;  i < preadd;  i++)
                   newword[i] = mytoupper(newword[i]);
             }
             else {
                for (i = 0;  i < preadd;  i++)
                   newword[i] = mytolower(newword[i]);
             }
             limit = len + preadd + sufadd - prestrip - sufstrip;
             i = len + preadd - prestrip - sufstrip;
             p += len - sufstrip - 1;
             if (myupper(*p)) {
                for (p = newword + i;  i < limit;  i++, p++)
                   *p = mytoupper(*p);
             }
             else {
                for (p = newword + i;  i < limit;  i++, p++)
                   *p = mytolower(*p);
             }
             if (insert(newword) < 0)
                return -1;
          }
      }
      if ((dent->flagfield & MOREVARIANTS) == 0)
         break;                /* End of the line */
      dent = dent->next;
   }
   return 0;
#endif /* NO_CAPITALIZATION_SUPPORT */
}




static void save_pers_dic()
{
    /* this is also part of the library */
    treeoutput();
    math_mode = 0;
    LaTeX_Mode = 'P';
}

/*---------------------------------------------------------------------------*/

/*
 *
 */
static void init_modes(char *strg) {
    int i;
    
    for (i = 0; i < strlen(strg); i++) {
	switch(strg[i]) {
	case 'g':
	    gflag = 1;
	    break;
	case 'G': /* default */
	    gflag = 0;
	    break;    
	case 'P':
	    tryhardflag = 0;
	    break;
	case 'm':
	    tryhardflag = 1;
	    break;
	case 'y':
	    yflag = 1;
	    break;
	case 'Y': /* default */
	    yflag = 0;
	    break;
	case 'z':
	    showflags = 1;
	    break;
	case 'Z': /* default */
	    showflags = 0;
	    break; 
	}
    }
}

/*---------------------------------------------------------------------------*/

void askmode()
{
   register char *cp1, *cp2;
   ichar_t *itok;                /* Ichar version of current word */

   if (fflag) {
      if (freopen(askfilename, "w", stdout) == NULL) {
         fprintf(stderr, CANT_CREATE, askfilename);
         exit(1);
      }
   }

   printf("%s\n", Version_ID[0]);

   while (fflush(stdout),
      xgets(contextbufs[0], sizeof contextbufs[0], stdin) != NULL) {
      /*
      ** *line is like `i', 
      ** @line is like `a', 
      ** &line is like 'u'
      ** $... init options do Ulisses
      ** $"... jj
      ** `#' is like `Q' (writes personal dictionary)
      ** `+' sets tflag, 
      ** `-' clears tflag
      ** `!' sets terse mode, 
      ** `%' clears terse
      ** `~' followed by a filename sets parameters according to file name
      ** `^' causes rest of line to be checked after stripping 1st char
      */
      if (contextbufs[0][0] == '*'  ||  contextbufs[0][0] == '@')
         treeinsert(ichartosstr(strtosichar(contextbufs[0] + 1, 0), 1),
                    ICHARTOSSTR_SIZE, contextbufs[0][0] == '*');
      else if (contextbufs[0][0] == '&') {
             itok = strtosichar(contextbufs[0] + 1, 0);
             lowcase(itok);
             treeinsert(ichartosstr(itok, 1), ICHARTOSSTR_SIZE, 1);
         }
      else if (contextbufs[0][0] == '#' && contextbufs[0][1] == '#')
              save_pers_dic();
      else if (contextbufs[0][0] == '#')   /* JJoao 2002 */
              printf("%s\n\n",contextbufs[0]);
      else if (contextbufs[0][0] == '!')
          terse = 1;
      else if (contextbufs[0][0] == '%')
          terse = 0;
      else if (contextbufs[0][0] == '+' || contextbufs[0][0] == '-') {
          math_mode = 0;
          LaTeX_Mode = 'P';
          tflag = (contextbufs[0][0] == '+');
          prefstringchar =
            findfiletype(tflag ? "tex" : "nroff", 1, (int *) NULL);
          if (prefstringchar < 0)
             prefstringchar = 0;
          defdupchar = prefstringchar;
      }
      else if (contextbufs[0][0] == '~') {
          defdupchar = findfiletype(&contextbufs[0][1], 1, &tflag);
          if (defdupchar < 0)
             defdupchar = 0;
      }
      else if (contextbufs[0][0] == '$' && contextbufs[0][1] == '"') {
          jjflags(contextbufs[0] + 2);
      }
      else if (contextbufs[0][0] == '$') {
          init_modes(contextbufs[0] + 1);
      }
      else {
         if (contextbufs[0][0] == '^') {
            /* Strip off leading uparrow */
            for (cp1 = contextbufs[0], cp2 = contextbufs[0] + 1;
                 (*cp1++ = *cp2++) != '\0'; )
              ;
         }
         checkline(stdout);
      }
   }
}



/**
 * @brief Copy/ignore "cnt" number of characters pointed to by *cc.
 * 
 */
void copyout(register char **cc, register int  cnt)
{
    while (--cnt >= 0) {
        if (**cc == '\0')
            break;
        if (!aflag && !lflag)
            putc(**cc, outfile);
        (*cc)++;
    }
}
