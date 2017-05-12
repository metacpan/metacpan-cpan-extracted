/*
 * Copyright 1987, 1988, 1989, 1992, 1993, Geoff Kuenning, Granada Hills, CA
 * All rights reserved.
 */

#include <string.h>
#include <ctype.h>
#include "jsconfig.h"
#include "jspell.h"
#include "proto.h"
#include "msgs.h"
#include "defmt.h"

void     chk_aff(ichar_t *word, ichar_t *ucword, int len,
                 int ignoreflagbits, int allhits, int add_poss, int reconly);
int      expand_pre(char *croot, ichar_t *rootword, MASKTYPE mask[],
                    int option, char *extra);
int      expand_suf(char *croot, ichar_t *rootword, MASKTYPE mask[],
                    int crossonly, int option, char *extra, char *pre_class);

/*---------------------------------------------------------------------------*/
/* Force to lowercase */
static void forcelc(register ichar_t *dst,      /* Destination to modify */
                    register int      len)      /* Length to copy */
{
   for (  ;  --len >= 0;  dst++)
      *dst = mytolower (*dst);
}

/*---------------------------------------------------------------------------*/
/*---------------------------------------------------------------------------*/

void add_my_poss(ichar_t *word, struct dent *dent, struct flagent *pflent,
                 struct flagent *sflent, struct flagent *sflent2)
{
   ichartostr(my_poss[my_poss_count].word, word, icharlen(word)+1, 0);  /* it must be 0 */
   if (my_poss_count < MAXPOSSIBLE &&
       (my_poss_count == 0 ||
        my_poss[my_poss_count-1].suc.dictent != dent  ||
        my_poss[my_poss_count-1].suc.prefix != pflent ||
        my_poss[my_poss_count-1].suc.suffix != sflent ||
        my_poss[my_poss_count-1].suc.suffix2 != sflent ||   /* CHANGE */
        strcmp(my_poss[my_poss_count].word, my_poss[my_poss_count-1].word))) {
      /* if the two last entries are not equal */
      my_poss[my_poss_count].suc.dictent = dent;
      my_poss[my_poss_count].suc.prefix = pflent;
      my_poss[my_poss_count].suc.suffix = sflent;
      my_poss[my_poss_count].suc.suffix2 = sflent2;
      my_poss_count++;
   }
}

/*---------------------------------------------------------------------------*/
/*---------------------------------------------------------------------------*/

static void treat_cflag_see2(
      register struct flagent *flent,   /* Current table entry */
      ichar_t *tword,                   /* Tmp cpy */
      int      crossonly,               /* NZ to do only cross-products */
      struct flagent *pfxent)           /* Prefix flag entry if crossonly */
{
/*   printf("DEB-chamada 2 tword(new root)=%s\r\n", ichartosstr(tword, 0)); */

   if (crossonly)
      flagpr(tword, BITTOCHAR(pfxent->flagbit), pfxent->stripl, pfxent->affl,
             pfxent->jclass,
             BITTOCHAR(flent->flagbit), flent->affl, flent->jclass);
   else
      flagpr(tword, -1, 0, 0, 0,
             BITTOCHAR(flent->flagbit), flent->affl, flent->jclass);
}

/*---------------------------------------------------------------------------*/

static void treat_ignoreflagbits(struct flagent *flent, struct flagent *pfxent,
                                ichar_t *tword, ichar_t *word, ichar_t *ucword,
                                int tlen, int crossonly, int add_poss)
{
   struct dent *dent;                /* Dictionary entry we found */
   ichar_t tword2[INPUTWORDLEN + 4 * MAXAFFIXLEN + 4];  /* 2nd copy for ins_root_cap */
   register ichar_t *cp;             /* Pointer into end of ucword */
   int    preadd;                    /* Length added to tword2 as prefix */

   if ((dent = lookup(tword, 1)) != NULL) {
      if (add_poss)
         add_my_poss(word, dent, pfxent, flent, NULL);

      cp = tword2;
      if (crossonly  &&  pfxent->affl != 0) {
         icharcpy(cp, pfxent->affix);
         cp += pfxent->affl;
         *cp++ = '+';
      }
      preadd = cp - tword2;
      icharcpy (cp, tword);
      cp += tlen;
      if (crossonly  &&  pfxent->stripl != 0) {
         *cp++ = '-';
         icharcpy(cp, pfxent->strip);
         cp += pfxent->stripl;
      }
      if (flent->stripl) {
         *cp++ = '-';
         icharcpy(cp, flent->strip);
         cp += flent->stripl;
      }
      if (flent->affl) {
         *cp++ = '+';
         icharcpy(cp, flent->affix);
         cp += flent->affl;
      }
      ins_root_cap(tword2, word, crossonly ? pfxent->stripl : 0, preadd,
                   flent->stripl, (cp - tword2) - tlen - preadd, dent,
                   pfxent, flent);
   }
}

/*---------------------------------------------------------------------------*/

static void see2_word_in_dict(struct flagent *flent, struct flagent *pfxent,
                              ichar_t *tword, ichar_t *word, ichar_t *ucword,
                              int tlen, int crossonly, int ignoreflagbits,
                              int allhits, int add_poss)
/* the result will be in the array hits (a word may have several possible bases) */
{
   struct dent *dent;                /* Dictionary entry we found */
   struct flagent *suf2;

   if (cflag)
      treat_cflag_see2(flent, tword, crossonly, pfxent);
   else if (ignoreflagbits)
      treat_ignoreflagbits(flent, pfxent, tword, word, ucword, tlen, crossonly,
                           add_poss); /* used when trying to find near misses*/
    else {
       saw_mode = 1;
       while ((dent = lookup(tword, 1)) && (allhits || (numhits == 0))) {
          if (TSTMASKBIT (dent->mask, flent->flagbit) &&
              (!crossonly || TSTMASKBIT(dent->mask, pfxent->flagbit)) &&
              (act_rec == -1 || TSTMASKBIT(dent->mask, rhits[act_rec]->flagbit)) &&
              numhits < MAX_HITS) {
             if (act_rec == -1) suf2 = NULL;
             else suf2 = rhits[act_rec];
             if (add_poss)
                add_my_poss(ucword, dent, pfxent, flent, suf2);
             if (numhits < MAX_HITS) {
                hits[numhits].dictent = dent;
                hits[numhits].prefix = pfxent;
                hits[numhits].suffix = flent;
                hits[numhits].suffix2 = suf2;
                numhits++;
             }
             else fprintf(stderr, "%c MAX_HITS reached\n", 7);
          }
       }
      put_saws_off(tword, 1);
      saw_mode = 0;
      if (!allhits)
         return;
   }
}

/*---------------------------------------------------------------------------*/

int creat_root_word(ichar_t *tword, ichar_t *ucword,
                           struct flagent *flent,   /* Current table entry */
                           int tlen)
{
   register ichar_t * cp;               /* Pointer into end of ucword */

   icharcpy(tword, ucword);
   cp = tword + tlen;
   if (flent->stripl) {
      icharcpy(cp, flent->strip);
      tlen += flent->stripl;
   }
   else
      *cp = '\0';
   return tlen;
}

/*---------------------------------------------------------------------------*/

static void suf_list_chk(
   ichar_t *       word,             /* Word to be checked */
   ichar_t *       ucword,           /* Upper-case-only word */
   int             len,              /* The length of ucword */
   struct flagptr *ind,              /* Flag index table */
   int             crossonly,        /* NZ to do only cross-products */
   struct flagent *pfxent,           /* Prefix flag entry if crossonly */
   int             ignoreflagbits,   /* Ignore whether affix is legal */
   int             allhits,          /* Keep going after first hit */
   int             add_poss,
   int             reconly)          /* See only recursive (+) flags */
{
   int                cond;             /* Condition number */
//   struct dent *      dent;             /* Dictionary entry we found */
   register struct flagent *flent;      /* Current table entry */
   int                entcount;         /* Number of entries to process */
//   int                preadd;           /* Length added to tword2 as prefix */
   register int       tlen;             /* Length of tword */
   ichar_t            tword[INPUTWORDLEN + 4 * MAXAFFIXLEN + 4]; /* Tmp cpy */
//   ichar_t            tword2[sizeof tword]; /* 2nd copy for ins_root_cap */
   register ichar_t * cp;               /* Pointer into end of ucword */

   icharcpy(tword, ucword);
   for (flent = ind->pu.ent, entcount = ind->numents;
        entcount > 0;  flent++, entcount--) {
      if (crossonly  &&  (flent->flagflags & FF_CROSSPRODUCT) == 0)
          continue;
      if (reconly  &&  (flent->flagflags & FF_REC) == 0)  /* if we're doing a recursive call and this flag is not recursive try the next one */
          continue;
      if (!reconly  &&  (flent->flagflags & FF_REC) == 1)  /* if we're not doing a recursive call and this flag is recursive try the next one */
          continue;
      /*
       * See if the suffix matches.
       */
      tlen = len - flent->affl;
      if (tlen > 0
          && (flent->affl == 0 || icharcmp(flent->affix, ucword + tlen) == 0)
          && tlen + flent->stripl >= flent->numconds) { /* The suffix matches*/

         /* Remove it, replace it by the "strip" string (if any) */
         tlen = creat_root_word(tword, ucword, flent, tlen);
         cp = tword + tlen;

         /* check the original conditions */
         for (cond = flent->numconds;  --cond >= 0;  ) {
            if ((flent->conds[*--cp] & (1 << cond)) == 0)
               break;
         }
         if (cond < 0) {
            if (reconly && rnumhits < MAX_HITS) {  /* success */
               rhits[rnumhits] = flent;   /* includes class */
               rnumhits++;
            }
            else
            /* The conditions match.  See if the word is in the dictionary. */
            see2_word_in_dict(flent, pfxent, tword, word, ucword,
                         tlen, crossonly, ignoreflagbits, allhits, add_poss);
         }
      }  /* if tlen */
   }   /* for */
}

/*---------------------------------------------------------------------------*/
/* Check possible suffixes */
/* it will put results on hits[] and numhits */
static void chk_suf(
   ichar_t *       word,             /* Word to be checked */
   ichar_t *       ucword,           /* Upper-case-only word */
   int             len,              /* The length of ucword */
   int             crossonly,        /* NZ to do only cross-products */
   struct flagent *pfxent,           /* Prefix flag entry if crossonly */
   int             ignoreflagbits,   /* Ignore whether affix is legal */
   int             allhits,          /* Keep going after first hit */
   int             add_poss,
   int             reconly)          /* See only recursive (+) flags */
{
   register ichar_t * cp;               /* Pointer to char to index on */
   struct flagptr *   ind;              /* Flag index table to test */

   suf_list_chk(word, ucword, len, &sflagindex[0], crossonly, pfxent,
                ignoreflagbits, allhits, add_poss, reconly);
   cp = ucword + len - 1;     /* cp now points to the last char of the word */
   ind = &sflagindex[*cp];    /* get the first element of the list in the array position told by *cp */
   while (ind->numents == 0  &&  ind->pu.fp != NULL) {  /* while there are flag entries in the list */
      if (cp == ucword)
         return;
      if (ind->pu.fp[0].numents) {
         suf_list_chk(word, ucword, len, &ind->pu.fp[0], crossonly, pfxent,
                      ignoreflagbits, allhits, add_poss, reconly);
         if (numhits != 0  &&  !allhits  &&  !cflag  &&  !ignoreflagbits)
            return;
      }
      ind = &ind->pu.fp[*--cp];
   }
   suf_list_chk(word, ucword, len, ind, crossonly, pfxent,
                ignoreflagbits, allhits, add_poss, reconly);
}


static void see_if_word_is_in_dictionary(
    register struct flagent *flent,   /* Current table entry */
    register int tlen,                /* Length of tword */
    ichar_t *tword,                   /* Tmp cpy */
    register ichar_t *cp,             /* Pointer into end of ucword */
    ichar_t *word,                    /* Word to be checked */
    int      ignoreflagbits,          /* Ignore whether affix is legal */
    int      allhits,                 /* Keep going after first hit */
    int      add_poss,
    int      reconly)                 /* See only recursive (+) flags */
/* the result will be in the array hits (a word may have several possible bases) */
{
    int    preadd;                    /* Length added to tword2 as prefix */
    struct dent *dent;                /* Dictionary entry we found */
    ichar_t tword2[INPUTWORDLEN + 4 * MAXAFFIXLEN + 4];  /* 2nd copy for ins_root_cap */

    tlen += flent->stripl;
    if (cflag) {
        flagpr(tword, BITTOCHAR(flent->flagbit), flent->stripl,
               flent->affl, flent->jclass, -1, 0, 0);
    }
    else if (ignoreflagbits) {   /* ignore if affix is legal */
        if ((dent = lookup(tword, 1)) != NULL) {
            if (add_poss)
                add_my_poss(word, dent, flent, NULL, NULL);
            cp = tword2;
            if (flent->affl) {
                icharcpy(cp, flent->affix);
                cp += flent->affl;
                *cp++ = '+';     /* the word was found throug affix removal */
            }
            preadd = cp - tword2;
            icharcpy(cp, tword);
            cp += tlen;
            if (flent->stripl) {
                *cp++ = '-';
                icharcpy(cp, flent->strip);
            }
            ins_root_cap(tword2, word, flent->stripl, preadd,
                         0, (cp - tword2) - tlen - preadd,
                         dent, flent, (struct flagent *) NULL);
        }
    }
    else {
        saw_mode = 1;
        while ((dent = lookup(tword, 1)) && (allhits || (numhits == 0))) {
            if (TSTMASKBIT(dent->mask, flent->flagbit)  &&
                (act_rec == -1 || TSTMASKBIT(dent->mask, rhits[act_rec]->flagbit)) &&
                numhits < MAX_HITS) {
                if (add_poss)
                    add_my_poss(tword, dent, flent, NULL, NULL);
                if (numhits < MAX_HITS) {
                    hits[numhits].dictent = dent;
                    hits[numhits].prefix = flent;   /* includes class */
                    hits[numhits].suffix = hits[numhits].suffix2 = NULL;
                    numhits++;
                }
                else fprintf(stderr, MAX_HITS_REACHED, 7);
            }
        }
        put_saws_off(tword, 1);
        saw_mode = 0;
        if (!allhits)
            return;
    }

    /* Handle cross-products (with prefixes and sufixes) */
    if (flent->flagflags & FF_CROSSPRODUCT)
        chk_suf(word, tword, tlen, 1, flent, ignoreflagbits, allhits, add_poss, reconly);
}

/*---------------------------------------------------------------------------*/

/* Check some prefix flags */
/* the result will be in the array hits (a word may have several possible bases) */
static void pfx_list_chk(
    ichar_t *       word,             /* Word to be checked */
    ichar_t *       ucword,           /* Upper-case-only word */
    int             len,              /* The length of ucword */
    struct flagptr *ind,              /* Flag index table */
    int             ignoreflagbits,   /* Ignore whether affix is legal */
    int             allhits,          /* Keep going after first hit */
    int             add_poss,
    int             reconly)          /* See only recursive (+) flags */
{
    int     cond;                     /* Condition number */
    register ichar_t *cp;             /* Pointer into end of ucword */
    int     entcount;                 /* Number of entries to process */
    register struct flagent *flent;   /* Current table entry */
    register int tlen;                /* Length of tword */
    ichar_t tword[INPUTWORDLEN + 4 * MAXAFFIXLEN + 4]; /* Tmp cpy */
    /* tword is a test word, we have to use the rules "reversed" to get the
       base word of the word we are testing, then we will check that word
       in the dictionary */
    
    /* for each entrie of prefixes ... */
    for (flent = ind->pu.ent, entcount = ind->numents;  entcount > 0;
         flent++, entcount--) {
        /* See if the prefix matches. */
        tlen = len - flent->affl;
        if (tlen > 0  /* the prefix must be smaller than the word */
            && (flent->affl == 0
                || icharncmp(flent->affix, ucword, flent->affl) == 0)  /* the left characters of the word must be equal to the prefix */
            && tlen + flent->stripl >= flent->numconds) {
            /*
             * The prefix matches.  Remove it, replace it by the "strip"
             * string (if any), and check the original conditions.
             */
            if (flent->stripl)   /* if the rules tell that the base word is stripped, put the stipped string of the base word */
                icharcpy(tword, flent->strip);
            
            icharcpy(tword + flent->stripl, ucword + flent->affl);

            /* check conditions with the constructed word */
            cp = tword;
            for (cond = 0;  cond < flent->numconds;  cond++) {
                if ((flent->conds[*cp++] & (1 << cond)) == 0)
                    break;
            }
            if (cond >= flent->numconds)  /* all conditions satisfied */
                /* The conditions match.  See if the word is in the dictionary */
                see_if_word_is_in_dictionary(flent, tlen, tword, cp, word,
                                             ignoreflagbits, allhits, add_poss, reconly);
        }
    }
}

/*---------------------------------------------------------------------------*/

/* Check possible affixes */
void chk_aff(
      ichar_t *word,             /* Word to be checked */
      ichar_t *ucword,           /* Upper-case-only copy of word */
      int      len,              /* The length of word/ucword */
      int      ignoreflagbits,   /* Ignore whether affix is legal */
      int      allhits,          /* Keep going after first hit */
      int      add_poss,
      int      reconly)          /* See only recursive (+) flags */
{
   register ichar_t * cp;               /* Pointer to char to index on */
   struct flagptr *   ind;              /* Flag index table to test */

   pfx_list_chk(word, ucword, len, &pflagindex[0], ignoreflagbits,
               allhits, add_poss, reconly);
   cp = ucword;
   ind = &pflagindex[*cp++];
   while (ind->numents == 0  &&  ind->pu.fp != NULL) {
      if (*cp == 0)
         return;
      if (ind->pu.fp[0].numents) {
         pfx_list_chk(word, ucword, len, &ind->pu.fp[0],
                      ignoreflagbits, allhits, add_poss, reconly);
         if (numhits  &&  !allhits  &&  !cflag  &&  !ignoreflagbits)
            return;
      }
      ind = &ind->pu.fp[*cp++];
   }
   pfx_list_chk(word, ucword, len, ind, ignoreflagbits, allhits, add_poss, reconly);
   if (numhits  &&  !allhits  &&  !cflag  &&  !ignoreflagbits)
       return;
   chk_suf(word, ucword, len, 0, (struct flagent *) NULL,
           ignoreflagbits, allhits, add_poss, reconly);
   sol_out2[i_word_created][0] = '\0';
   is_in_dic[i_word_created] = '\0';
}

/*---------------------------------------------------------------------------*/
/*---------------------------------------------------------------------------*/
/* called by expand_pre and expand_suf                                                               */
/*---------------------------------------------------------------------------*/

static void print_expansion(char *croot, ichar_t *tword, char *extra,
                            char *root_class, char *pre_class, char *suf_class)
{
   char word[MAXWLEN], root[MAXWLEN], strg_out[MAXSOLLEN];
   int i;

   strcpy(root, croot);
   i = strlen(root) - 1;
   while (i > 0 && root[i] != '/')
      i--;
   root[i] = '\0';
   sprintf(word, "%s%s", ichartosstr(tword, 1), extra);
   compound_info(strg_out, word, root, root_class, pre_class, suf_class, "");
   printf("%s",strg_out);
}

/*---------------------------------------------------------------------------*/
/* expand_pre                                                                */
/*---------------------------------------------------------------------------*/

static void creat_new_word_pre(ichar_t *tword, struct flagent *flent,
                               ichar_t *rootword, ichar_t *nextc, int tlen)
{
    /*  Copy the word, add the prefix, and make it
    * the proper case.   This code is carefully written to match that ins_cap
    * and cap_ok.  Note that the affix, as inserted, is uppercase.
    *
    * There is a tricky bit here:  if the root is capitalized, we want a
    * capitalized result.  If the root is followcase, however, we want to
    * duplicate the case of the first remaining letter of the root.  In other
    * words, "Loved/U" should generate "Unloved", but "LOved/U" should generate
    * "UNLOved" and "lOved/U" should produce "unlOved".
    */
   if (flent->affl) {
      icharcpy(tword, flent->affix);
      nextc = tword + flent->affl;
   }
   icharcpy(nextc, rootword + flent->stripl);
   if (myupper(rootword[0])) {
      /* We must distinguish followcase from capitalized and all-upper */
      for (nextc = rootword + 1;  *nextc;  nextc++) {
         if (!myupper(*nextc))
            break;
      }
      if (*nextc) {
         /* It's a followcase or capitalized word.  Figure out which. */
         for (  ;  *nextc;  nextc++) {
            if (myupper(*nextc))
               break;
         }
         if (*nextc) {
            /* It's followcase. */
            if (!myupper(tword[flent->affl]))
               forcelc(tword, flent->affl);
         }
         else {
            /* It's capitalized */
            forcelc(tword + 1, tlen - 1);
         }
      }
   }
   else {
      /* Followcase or all-lower, we don't care which */
      if (!myupper(*nextc))
         forcelc(tword, flent->affl);
   }
}

/*---------------------------------------------------------------------------*/
/* Print a prefix expansion */
static int pr_pre_expansion(
   char *                    croot,           /* Char version of rootword */
   register ichar_t *        rootword,        /* Root word to expand */
   register struct flagent * flent,           /* Current table entry */
   MASKTYPE                  mask[],          /* Mask bits to expand on */
   int                       option,          /* Option, see  expandmode */
   char *                    extra,           /* Extra info to add to line */
   char *                    put_sep)
{
   int     cond;                      /* Current condition number */
   register ichar_t *nextc;           /* Next case choice */
   int     tlen;                      /* Length of tword */
   ichar_t tword[MAXWLEN];            /* Temp */
   char    root_info[MAXCLASS], class_aux[MAXCLASS];

   tlen = icharlen(rootword);
   if (flent->numconds > tlen)
      return 0;
   tlen -= flent->stripl;
   if (tlen <= 0)
      return 0;
   tlen += flent->affl;
   for (cond = 0, nextc = rootword;  cond < flent->numconds;  cond++) {
      if ((flent->conds[mytoupper(*nextc++)] & (1 << cond)) == 0)
         return 0;
   }
   /* The conditions are now satisfied.  */

   creat_new_word_pre(tword, flent, rootword, nextc, tlen);

   if (*put_sep)
      printf(SEP1);
   if (option == 3)
      printf("%s%s", croot, SEP1);
   strcpy(class_aux, ichartosstr(flent->jclass, 1));
   if (option != 4) {
      strcpy(root_info, ichartosstr(gentable[flent->flagbit].jclass, 0));
      print_expansion(croot, tword, extra, root_info, class_aux, "");
   }
   *put_sep = 1;
   if (flent->flagflags & FF_CROSSPRODUCT)
      return tlen + expand_suf(croot, tword, mask, 1, option, extra, class_aux);
   else
      return tlen;
}

/*---------------------------------------------------------------------------*/
/*
 * Expand a dictionary prefix entry
 */
int expand_pre(
   char *            croot,           /* Char version of rootword */
   ichar_t *         rootword,        /* Root word to expand */
   register MASKTYPE mask[],          /* Mask bits to expand on */
   int               option,          /* Option, see expandmode */
   char *            extra)           /* Extra info to add to line */
{
   int entcount;                      /* No. of entries to process */
   int explength;                     /* Length of expansions */
   register struct flagent *flent;    /* Current table entry */
   char put_sep;

   put_sep = 0;
   for (flent = pflaglist, entcount = numpflags, explength = 0;
        entcount > 0;  flent++, entcount--) {
      if (TSTMASKBIT(mask, flent->flagbit))
         explength += pr_pre_expansion(croot, rootword, flent, mask, option,
                                       extra, &put_sep);
   }
   return explength;
}


/*---------------------------------------------------------------------------*/
/* expand_suf                                                                */
/*---------------------------------------------------------------------------*/

static void creat_new_word_suf(ichar_t *tword, struct flagent *flent,
                               ichar_t *rootword, ichar_t *nextc, int tlen)
{
   /* Copy the word, add the suffix,
    * and make it match the case of the last remaining character of the
    * root.  Again, this code carefully matches ins_cap and cap_ok.
    */
   icharcpy(tword, rootword);
   nextc = tword + tlen - flent->stripl;
   if (flent->affl) {
      icharcpy(nextc, flent->affix);
      if (!myupper(nextc[-1]))
         forcelc(nextc, flent->affl);
   }
   else
      *nextc = 0;
}

/*---------------------------------------------------------------------------*/
/* Print a suffix expansion */
static int pr_suf_expansion(
   char *                    croot,        /* Char version of rootword */
   register ichar_t *        rootword,     /* Root word to expand */
   register struct flagent * flent,        /* Current table entry */
   int                       option,       /* Option, see expandmode */
   char *                    extra,        /* Extra info to add to line */
   char                    * pre_class,    /* prefix classification */
   char *                    put_sep)
{
   int     cond;                   /* Current condition number */
   register ichar_t *nextc;        /* Next case choice */
   int     tlen;                   /* Length of tword */
   ichar_t tword[MAXWLEN];   /* Temp */
   char    root_info[MAXCLASS], class_aux[MAXCLASS]; //, strg_out[MAXSOLLEN];

   tlen = icharlen(rootword);
   cond = flent->numconds;
   if (cond > tlen)
      return 0;
   if (tlen - flent->stripl <= 0)
      return 0;
   for (nextc = rootword + tlen;  --cond >= 0;  ) {
      if ((flent->conds[mytoupper(*--nextc)] & (1 << cond)) == 0)
         return 0;
   }
   /* The conditions are satisfied.  */

   creat_new_word_suf(tword, flent, rootword, nextc, tlen);

   if (*put_sep)
      printf(SEP1);
   if (option == 3)
      printf("%s%s", croot, SEP1);
   if (option != 4) {
      strcpy(class_aux, ichartosstr(flent->jclass, 1));
      strcpy(root_info, ichartosstr(gentable[flent->flagbit].jclass, 0));
      print_expansion(croot, tword, extra, root_info, pre_class, class_aux);
   }
   *put_sep = 1;
   return tlen + flent->affl - flent->stripl;
}

/*---------------------------------------------------------------------------*/
/*
 * Expand a dictionary suffix entry
 */
int expand_suf(
   char *             croot,           /* Char version of rootword */
   ichar_t *          rootword,        /* Root word to expand */
   register MASKTYPE  mask[],          /* Mask bits to expand on */
   int                crossonly,       /* NZ if cross-products only */
   int                option,          /* Option, see expandmode */
   char *             extra,           /* Extra info to add to line */
   char             * pre_class)       /* prefix classification */
{
   int entcount;                        /* No. of entries to process */
   int explength;                       /* Length of expansions */
   register struct flagent * flent;     /* Current table entry */
   char put_sep;

   put_sep = 0;
   for (flent = sflaglist, entcount = numsflags, explength = 0;
        entcount > 0;  flent++, entcount--) {
      if (TSTMASKBIT(mask, flent->flagbit)) {
         if (!crossonly  ||  (flent->flagflags & FF_CROSSPRODUCT))
            explength +=
                 pr_suf_expansion(croot, rootword, flent, option, extra,
                                  pre_class, &put_sep);
       }
   }
   return explength;
}
