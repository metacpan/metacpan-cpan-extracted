
/*
 * good.c - see if a word or its root word is in the dictionary.
 *
 * Pace Willisson, 1983
 *
 * Copyright 1992, 1993, Geoff Kuenning, Granada Hills, CA
 * All rights reserved.
 *
 * Copyright 1994 by Ulisses Pinto & Jose' Joa~o Almeida, Universidade do Minho
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. All modifications to the source code must be clearly marked as
 *    such.  Binary redistributions based on modified source code
 *    must be clearly marked as modified versions in the documentation
 *    and/or other materials provided with the distribution.
 * 4. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgment:
 *      This product includes software developed by Geoff Kuenning and
 *      other unpaid contributors.
 * 5. The name of Geoff Kuenning may not be used to endorse or promote
 *    products derived from this software without specific prior
 *    written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY GEOFF KUENNING AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL GEOFF KUENNING OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#include <string.h>
#include <ctype.h>
#include "jsconfig.h"
#include "jspell.h"
#include "proto.h"
#include "good.h"

static ichar_t *orig_word;
char *macro(char *strg);

/*---------------------------------------------------------------------------*/

int mk_upper(ichar_t *w, ichar_t *nword)
{
   register ichar_t *p, *q;

   /* Make an uppercase copy of the word we are checking. */
   for (p = w, q = nword;  *p; )
      *q++ = mytoupper(*p++);
   *q = 0;          /* put end of string */
   return q - nword;   /* word length */
}

/*---------------------------------------------------------------------------*/
/*---------------------------------------------------------------------------*/

#ifndef NO_CAPITALIZATION_SUPPORT

/*---------------------------------------------------------------------------*/
/*
** See if this particular capitalization (dent) is legal with these
** particular affixes.
*/
static int entryhasaffixes(register struct dent *dent,
                           register struct success *hit)
{
   if (hit->prefix  &&  !TSTMASKBIT (dent->mask, hit->prefix->flagbit))
      return 0;
   if (hit->suffix  &&  !TSTMASKBIT (dent->mask, hit->suffix->flagbit))
      return 0;
   return 1;                        /* Yes, these affixes are legal */
}

/*---------------------------------------------------------------------------*/

static int cap_ok(register ichar_t *word, register struct success *hit, int len)
{
   register ichar_t *dword;
   register ichar_t *w;
   register struct dent *dent;
   ichar_t  dentword[MAXWLEN];
   int      preadd, prestrip, sufadd;
   ichar_t *limit;
   long     thiscap, dentcap;

   thiscap = whatcap(word);
   /*
   ** All caps is always legal, regardless of affixes.
   */
   preadd = prestrip = sufadd = 0;
   if (thiscap == ALLCAPS)
      return 1;
   else if (thiscap == FOLLOWCASE) {
      /* Set up some constants for the while(1) loop below */
      if (hit->prefix) {
         preadd = hit->prefix->affl;
         prestrip = hit->prefix->stripl;
      }
      else
         preadd = prestrip = 0;
      sufadd = hit->suffix ? hit->suffix->affl : 0;
   }
   /*
   ** Search the variants for one that matches what we have.  Note
   ** that thiscap can't be ALLCAPS, since we already returned for that case.
   */
   dent = hit->dictent;
   for (  ;  ;  ) {
      dentcap = captype(dent->flagfield);
      if (dentcap != thiscap) {
         if (dentcap == ANYCASE  &&  thiscap == CAPITALIZED
             &&  entryhasaffixes(dent, hit))
            return 1;
      }
      else {                               /* captypes match */
         if (thiscap != FOLLOWCASE) {
            if (entryhasaffixes(dent, hit))
               return 1;
         }
         else {
            /*
            ** Make sure followcase matches exactly.
            ** Life is made more difficult by the possibility of affixes.
            ** Start with the prefix.
            */
            strtoichar(dentword, dent->word, INPUTWORDLEN, 1);
            dword = dentword;
            limit = word + preadd;
            if (myupper (dword[prestrip])) {
               for (w = word;  w < limit;  w++) {
                  if (mylower(*w))
                     goto doublecontinue;
               }
            }
            else {
               for (w = word;  w < limit;  w++) {
                  if (myupper(*w))
                     goto doublecontinue;
               }
            }
            dword += prestrip;
            /* Do root part of word */
            limit = dword + len - preadd - sufadd;
            while (dword < limit) {
               if (*dword++ != *w++)
                  goto doublecontinue;
            }
            /* Do suffix */
            dword = limit - 1;
            if (myupper (*dword)) {
               for (  ;  *w;  w++) {
                  if (mylower (*w))
                     goto doublecontinue;
               }
            }
            else {
               for (  ;  *w;  w++) {
                  if (myupper(*w))
                     goto doublecontinue;
               }
            }
            /*
            ** All failure paths go to "doublecontinue,"
            ** so if we get here it must match.
            */
            if (entryhasaffixes (dent, hit))
                return 1;
doublecontinue:        ;
         }
      }
      if ((dent->flagfield & MOREVARIANTS) == 0)
         break;
      dent = dent->next;
   }

   /* No matches found */
   return 0;
}

#endif

/*---------------------------------------------------------------------------*/
/*---------------------------------------------------------------------------*/

void try_direct_match_in_dic(ichar_t *w, ichar_t *nword,
                             int allhits, int add_poss, int n)
{
    register struct dent *dp;

    saw_mode = 1;
    numhits = 0;
    do {
      if ((dp = lookup(nword, 1)) != NULL) {
         if (numhits < MAX_HITS) {
            hits[numhits].dictent = dp;
            hits[numhits].prefix = hits[numhits].suffix = hits[numhits].suffix2 = NULL;
            if (add_poss)
               add_my_poss(nword, dp, NULL, NULL, NULL);
#ifndef NO_CAPITALIZATION_SUPPORT
            if (allhits  ||  cap_ok(w, &hits[numhits], n))
               numhits++;
#else
            numhits++;
#endif
         }
         else fprintf(stderr, "%c MAX_HITS reached\n", 7);
      }
   } while (dp);
   put_saws_off(nword, 1);
   saw_mode = 0;
}
/*---------------------------------------------------------------------------*/

#ifndef NO_CAPITALIZATION_SUPPORT
int good(ichar_t *w,           /* Word to look up */
   int ignoreflagbits, int allhits, int add_poss, int reconly)
#else
/* ARGSUSED */
int good(ichar_t *w;                /* Word to look up */
   int ignoreflagbits, int dummy, int add_poss, int reconly)
#define allhits      1
#endif
/* ignoreflagbits - NZ to ignore affix flags in dict
                    (is used when trying to find errors)
   allhits         - NZ to ignore case, get every hit  */
{
   ichar_t nword[MAXWLEN];
   register int n;

#ifndef NO_CAPITALIZATION_SUPPORT
   allhits = 1;
#endif
   n = mk_upper(w, nword);

   numhits = 0;

   if (cflag) {
      if (!islib)  printf("%s", ichartosstr(w, 0));
      orig_word = w;
   }
   else
      try_direct_match_in_dic(w, nword, allhits, add_poss, n);
   if (numhits  &&  !allhits)
      return 1;

   /* try stripping off affixes */
#if 0
   numchars = icharlen(nword);
   if (numchars < 4) {
      if (cflag && !islib)
         putchar('\n');
      return numhits  ||  (numchars == 1);
   }
#endif

   chk_aff(w, nword, n, ignoreflagbits, allhits, add_poss, reconly);

   if (cflag && !islib)
      putchar('\n');

#ifndef NO_CAPITALIZATION_SUPPORT
   if (numhits)
      return allhits  ||  cap_ok(w, &hits[0], n);
   else
      return 0;
#else
   return numhits;
#endif
}

/*---------------------------------------------------------------------------*/

static int in_suf_rec(ichar_t *w, int allhits, int add_poss)
/* tries to match recursive "afixes" i.e. flags marked with "+" */
{
   ichar_t nword[MAXWLEN], w2[MAXWLEN];
   int n, tlen, good_hits;

   n = mk_upper(w, nword);

   rnumhits = 0;
   good_hits = numhits;   /* hits found with good() function */
/*   chk_aff(w, nword, n, 0, allhits, add_poss, 1);*/   /* sera' que add_poss deve ter isto ? (old) */
   chk_aff(w, nword, n, 0, 0, 0, 1);     /* sera' que add_poss deve ter isto ? */
   numhits = good_hits;   /* put numhits right */
   if (rnumhits) { /* there were matches */
      for (act_rec = 0; act_rec < rnumhits; act_rec++) {
         tlen = icharlen(w) - rhits[act_rec]->affl;   /* radical length */
         creat_root_word(w2, w, rhits[act_rec], tlen);
         if (cflag)
            orig_word = w2;   /* necessary on flagpr routine */
         n = mk_upper(w2, nword);
         chk_aff(w2, nword, n, 0, 1, add_poss, 0);  /* hits should increase if words found */
/*         chk_aff(w2, nword, n, 0, allhits, add_poss, 0);*/  /* hits should increase if words found (old) */
      }
      act_rec = -1;
   }
   return numhits;
}

/*---------------------------------------------------------------------------*/

int bgood(ichar_t *w,           /* Word to look up */
          int ignoreflagbits, int allhits, int add_poss)
{
   int g, g1;

   g = good(w, ignoreflagbits, allhits, add_poss, 0);
   g1 = in_suf_rec(w, allhits, add_poss);
   return (g || g1);
}

/*---------------------------------------------------------------------------*/
/*---------------------------------------------------------------------------*/

char *suppercase(char *w)
{
   static char r[255];
   char *q;

   q = r;
   while (*w)
       *q++ = mytoupper((int)*w++);
   *q = 0;          /* put end of string */
   return r;
}

/*---------------------------------------------------------------------------*/
/* flagpr                                                                    */
/*---------------------------------------------------------------------------*/

static int case_verify(int preflag, int preadd, int sufflag, int sufadd,
                       int orig_len)
{
   register ichar_t *origp;   /* Pointer into orig_word */

   /*
    * We refuse to print if the cases outside the modification points don't
    * match those just inside.  This prevents things like "OEM's" from being
    * turned into "OEM/S" which expands only to "OEM'S".
    */
   if (preflag > 0) {
      origp = orig_word + preadd;
      if (myupper(*origp)) {
         for (origp = orig_word;  origp < orig_word + preadd;  origp++) {
            if (mylower(*origp))
               return 0;
         }
      }
      else {
         for (origp = orig_word;  origp < orig_word + preadd;  origp++) {
           if (myupper(*origp))
              return 0;
         }
      }
   }
   if (sufflag > 0) {
      origp = orig_word + orig_len - sufadd;
      if (myupper(origp[-1])) {
         for (  ;  *origp != 0;  origp++) {
            if (mylower(*origp))
               return 0;
         }
      }
      else {
         origp = orig_word + orig_len - sufadd;
         for (  ;  *origp != 0;  origp++) {
            if (myupper(*origp))
               return 0;
         }
      }
   }
   return 1;
}

/*---------------------------------------------------------------------------*/

static void create_root(char *root, ichar_t* word,
                        int prestrip, int preadd, int sufadd, int orig_len)
{
   register ichar_t *origp;   /* Pointer into orig_word */

   origp = orig_word + preadd;
   root[0] = '\0';
   if (myupper(*origp)) {
      while (--prestrip >= 0)
         strcat(root, printichar((int) *word++));
   }
   else {
      while (--prestrip >= 0)
         strcat(root, printichar((int) mytolower(*word++)));
   }

   for (prestrip = orig_len - preadd - sufadd;  --prestrip >= 0;  word++)
      strcat(root, printichar((int) *origp++));
/*   printf("DEB 2-root=%s", root); */

   if (origp > orig_word)
      origp--;

   if (myupper(*origp))
      strcat(root, ichartosstr(word, 0));
   else {
      while (*word)
         strcat(root, printichar((int) mytolower(*word++)));
   }

   /* an important conversion for convinente output in Latin1 and
     similar fonts: */
}

/*---------------------------------------------------------------------------*/

static char *get_class_info(int preflag, int sufflag)
{
   static char class_info[MAXCLASS];

   if (preflag > 0)
      strcpy(class_info, ichartosstr(gentable[CHARTOBIT(preflag)].jclass, 0));
   else class_info[0] = '\0';
   if (sufflag > 0) {
      if (class_info[0] != '\0') strcat(class_info, "+");
      strcat(class_info, ichartosstr(gentable[CHARTOBIT(sufflag)].jclass, 0));
   }
   return class_info;
}

/*---------------------------------------------------------------------------*/

static char staux[MAXCLASS];

static char *root_class;
static char root[MAXCLASS], pre_class[MAXCLASS],
            suf_class[MAXCLASS], suf2_class[MAXCLASS];

static void adjust_dollar()
{
   strcpy(suf2_class, suf_class);
   strcpy(staux, root_class+1);  /* advance $ */
   strcpy(root, staux);
   root_class = cut_by_dollar(root);
   strcpy(suf_class, cut_by_dollar(root_class));
}

/*---------------------------------------------------------------------------*/
/*
 * Print a word and its flag, making sure the case of the output matches
 * the case of the original found in "orig_word".
 */
void flagpr(
   register ichar_t *word,   /* (Modified) word to print */
   int preflag,              /* Prefix flag (if any) */
   int prestrip,             /* Lth of pfx stripped off orig_word */
   int preadd,               /* Length of prefix added to w */
   ichar_t *preclass,
   int sufflag,              /* Suffix flag (if any) */
   int sufadd,               /* Length of suffix added to w */
   ichar_t *sufclass)
{
   int orig_len;              /* Length of orig_word */
   int i;
   char strg_out[MAXSOLLEN];
   ichar_t * suf2class;
   int suf2flag;             /* Suffix flag 2 (if any) */

   if (act_rec == -1) {
      suf2class = 0;
      suf2flag = 0;
   }
   else {
      suf2class = rhits[act_rec]->jclass;
      suf2flag = BITTOCHAR(rhits[act_rec]->flagbit);
   }

   orig_len = icharlen(orig_word);
   if (!case_verify(preflag, preadd, sufflag, sufadd, orig_len))
      return;

   /* The cases are ok.  Put out the word, being careful that the
    * prefix/suffix cases match those in the original, and that the
    * unchanged characters from the original actually match it.
    */
   if (!islib)
      printf(SEP1);

   create_root(root, word, prestrip, preadd, sufadd, orig_len);

   root_class = get_class_info(preflag, sufflag);

   pre_class[0] = suf_class[0] = suf2_class[0] ='\0';
   if (preclass)  ichartostr(pre_class, preclass, 100, 1);
   if (sufclass)  ichartostr(suf_class, sufclass, 100, 1);
   if (suf2class) ichartostr(suf2_class, suf2class, 100, 1);

   if (root_class[0] == '$')
      adjust_dollar();

   sprintf(strg_out, o_form, ichartosstr(strtosichar(macro(root), 1), 0),   /* this conversion of root is necessery for adequate output in Latin like fonts */
                   macro(root_class), pre_class, macro(suf_class), suf2_class);
   if (islib) {
      strcpy(sol_out2[i_word_created], strg_out);
/*      printf("DEB - strg_out = %s", strg_out); */
      /* without suppercase lookup wouldn't work */
      if (lookup(strtosichar(suppercase(root), 1), 1))   /* root is in dictionary */
         is_in_dic[i_word_created] = 1;
      else
         is_in_dic[i_word_created] = 0;


      strcpy(sep_sol[i_word_created].root, root);
/*      strcpy(sep_sol[i_word_created].root, ichartosstr(strtosichar(root, 1), 0)); */
      strcpy(sep_sol[i_word_created].root_class, root_class);
      strcpy(sep_sol[i_word_created].pre_class, pre_class);
      strcpy(sep_sol[i_word_created].suf_class, suf_class);
      strcpy(sep_sol[i_word_created].suf2_class, suf2_class);
      i_word_created++;
   }
   else {
      printf("%s", strg_out);
   }
   /*  Now put out the flags */
   if (showflags) {
      i = 0;
      strg_out[i++] = hashheader.flagmarker;
      if (preflag > 0)
         strg_out[i++] = preflag;
      if (sufflag > 0)
         strg_out[i++] = sufflag;
      if (suf2flag > 0)
         strg_out[i++] = suf2flag;
      strg_out[i] = '\0';
      if (islib) {
         strcat(sol_out2[i_word_created-1], strg_out);
         strcpy(sep_sol[i_word_created-1].flag, strg_out+1);  /* +1 to advance flagmarker */
/*         printf("DEB-%s\r\n", strg_out); */
      }
      else
         printf("%s ", strg_out);
   }
}
