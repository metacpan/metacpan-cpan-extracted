#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include "jsconfig.h"
#include "jspell.h"
#include "proto.h"
#include "msgs.h"

int linit(void);
struct dent *lookup(ichar_t * word, int dotree);


static int inited = 0;

/*---------------------------------------------------------------------------*/

static int verify_hash()
/* verifica se esta tudo bem com o hashheader */
{
   if (hashsize < sizeof(hashheader)) {
      if (hashsize < 0)
         fprintf(stderr, LOOKUP_C_CANT_READ, hashname);
      else if (hashsize == 0)
         fprintf(stderr, LOOKUP_C_NULL_HASH, hashname);
      else
         fprintf(stderr, LOOKUP_C_SHORT_HASH(hashname, hashsize,
                        (int) sizeof hashheader));
      return -1;
   }
   else if (hashheader.magic != MAGIC) {
           fprintf(stderr, LOOKUP_C_BAD_MAGIC(hashname, (unsigned int) MAGIC,
                                             (unsigned int) hashheader.magic));
      return -1;
   }
   else if (hashheader.magic2 != MAGIC) {
           fprintf(stderr, LOOKUP_C_BAD_MAGIC2(hashname, (unsigned int) MAGIC,
                                            (unsigned int) hashheader.magic2));
      return -1;
   }
   else if (hashheader.compileoptions != COMPILEOPTIONS
            ||  hashheader.maxstringchars != MAXSTRINGCHARS
            ||  hashheader.maxstringcharlen != MAXSTRINGCHARLEN) {
           fprintf(stderr,
             LOOKUP_C_BAD_OPTIONS((unsigned int) hashheader.compileoptions,
              hashheader.maxstringchars, hashheader.maxstringcharlen,
             (unsigned int) COMPILEOPTIONS, MAXSTRINGCHARS, MAXSTRINGCHARLEN));
      return -1;
   }
   return 1;
}

/*---------------------------------------------------------------------------*/

static int creat_empty_table()
{
   /*
    * Dictionary is not needed - create an empty dummy table. We actually
    * have to have one entry since the hash algorithm involves a divide by
    * the table size (actually modulo, but zero is still unacceptable).
    * So we create an empty entry.
   */
   hashsize = 1;             /* This prevents divides by zero */
   hashtbl = (struct dent *) calloc(1, sizeof(struct dent));
   if (hashtbl == NULL) {
      fprintf(stderr, LOOKUP_C_NO_HASH_SPACE);
      return -1;
   }
   hashtbl[0].word = NULL;
   hashtbl[0].next = NULL;
   hashtbl[0].flagfield &= ~(USED | KEEP);
   /* The flag bits don't matter, but calloc cleared them. */
   hashstrings = (char *) malloc((unsigned) hashheader.lstringsize);
   return 1;   /* OK */
}

/*---------------------------------------------------------------------------*/
/*---------------------------------------------------------------------------*/

static int read_hash_header(int hashfd)
{
   /* 20080322 - WAS: hashsize = read(hashfd, (char *) &hashheader, sizeof(hashheader)); */
   hashsize = read(hashfd, (void*) &hashheader, sizeof(hashheader));
   if (verify_hash() == -1) return -1;

   if (nodictflag) {  /* don't remove these {} */
      if (creat_empty_table() == -1) return -1;
   }
   else {
      hashtbl = (struct dent *)
                malloc((unsigned) hashheader.tblsize * sizeof(struct dent));
      hashsize = hashheader.tblsize;
      hashstrings = (char *) malloc((unsigned) hashheader.stringsize);
   }
   numsflags = hashheader.stblsize;
   numpflags = hashheader.ptblsize;
   sflaglist = (struct flagent *)
                malloc((numsflags + numpflags) * sizeof(struct flagent));
   if (hashtbl == NULL  ||  hashstrings == NULL  ||  sflaglist == NULL) {
      fprintf(stderr, LOOKUP_C_NO_HASH_SPACE);
      return -1;
   }
   pflaglist = sflaglist + numsflags;
   return 1;
}

/*---------------------------------------------------------------------------*/

static int read_lang_strings(int hashfd)
{
   /* Read just the strings for the language table, and skip over the rest
    * of the strings and all of the hash table.
   */
   if (read(hashfd, hashstrings, (unsigned) hashheader.lstringsize)
       != hashheader.lstringsize) {
       fprintf(stderr, LOOKUP_C_BAD_FORMAT);
       return -1;
   } else
       return 1;
}

/*---------------------------------------------------------------------------*/

static int read_all_strings(int hashfd)
{   /* read strings: words, class, */
    if (read(hashfd, hashstrings, (unsigned) hashheader.stringsize)
	!= hashheader.stringsize) {
	fprintf(stderr, LOOKUP_C_BAD_FORMAT);
	return -1;
    } else {
	return 1;
    }
}

/*---------------------------------------------------------------------------*/

static void init_words(int hashfd)
{
   int i, n, mask_len;
   long int ind[3];
   register struct dent *dp;
   char n0, *mem, *im;

   if (!nodictflag) {
      mem = (char *) calloc(hashheader.thashsize, 1);
      if (read(hashfd, mem, hashheader.thashsize) != hashheader.thashsize) {
          fprintf(stderr, LOOKUP_C_BAD_FORMAT);
          exit(1);
      }
      im = mem;

      mask_len = MASKSIZE*sizeof(MASKTYPE);
      for (i = hashsize, dp = hashtbl;  --i >= 0;  dp++) {
         n0 = *im++;
         if (n0) {  /* exists entry */
            if (n0 == 4) n = 2;
            else         n = n0;
            memcpy(ind, im, sizeof(long int)*n);
            im += sizeof(long int)*n;

            dp->word = &hashstrings[ind[0]];
/*            printf("DEB- dp->word = %s\n", dp->word); */

            if (n0 == 2 || n0 == 3) dp->jclass = &hashstrings[ind[1]];
/*            else                    dp->class = NULL; */ /* is already null */
            if (n0 == 3)            dp->next = &hashtbl[ind[2]];
            else if (n0 == 4)       dp->next = &hashtbl[ind[1]];
/*                 else dp->next = NULL;*/  /* is already null */

            memcpy(dp->mask, im, mask_len);
            im += mask_len;
#ifdef FULLMASKSET
              dp->flags = *im++;
#endif
         }
/*         else {
            dp->word = dp->class = NULL;
            dp->next = NULL;
         }
         dp->saw = 0; */   /* are already null */
      }
      free(mem);
   }
}

/*---------------------------------------------------------------------------*/

static int read_generic_flag_info(int hashfd)
{
   int i;

   /* read generic flag info */
   for (i = 0; i < MASKBITS; i++) {
      if (read(hashfd, (char *) &(gentable[i].classl), sizeof(short)) ==
                                                       sizeof(short)) {
         gentable[i].jclass = (ichar_t *) malloc(
                              sizeof(ichar_t) * (gentable[i].classl + 1));
         if (read(hashfd, (char *) gentable[i].jclass,
                  ((unsigned) (gentable[i].classl)+1) * sizeof(ichar_t))
             != (gentable[i].classl+1) * sizeof(ichar_t))
         {
            fprintf(stderr, LOOKUP_C_BAD_FORMAT);
            return -1;
         }
      }
   }
   return 1;
}

/*---------------------------------------------------------------------------*/

static int read_lines_of_flags(int hashfd)
{
   /* read "lines" of flags */
   if (read(hashfd, (char *) sflaglist,
            (unsigned) (numsflags + numpflags) * sizeof(struct flagent))
        != (numsflags + numpflags) * sizeof(struct flagent))
   {
      fprintf(stderr, LOOKUP_C_BAD_FORMAT);
      return -1;
   }
   else return 1;
}

/*---------------------------------------------------------------------------*/

static int read_info_from_disk()
{
   int hashfd;

#ifdef __WIN__ 
   if ((hashfd = open(hashname, O_RDONLY | O_BINARY)) < 0) {
#else
   if ((hashfd = open(hashname, O_RDONLY)) < 0) {
#endif
      fprintf(stderr, CANT_OPEN, hashname);
      return -1;
   }

   if (read_hash_header(hashfd) == -1)
       return -1;

   if (nodictflag) {
      read_lang_strings(hashfd);

      lseek(hashfd, (long)hashheader.stringsize - (long) hashheader.lstringsize
                  + hashheader.thashsize, 1);
   }
   else {
       if (read_all_strings(hashfd) == -1) return -1;
       init_words(hashfd);
   }

   if (read_generic_flag_info(hashfd) == -1) return -1;
   if (read_lines_of_flags(hashfd)    == -1) return -1;

   close(hashfd);
   return 0;
}

/*---------------------------------------------------------------------------*/

static int act_all_entry(void)
{
   int i;
   struct flagent *entry;
   struct flagptr *ind;
   register ichar_t *cp;
   int viazero;

   for (i = numsflags + numpflags, entry = sflaglist; --i >= 0; entry++) {
      if (entry->stripl)
         entry->strip = (ichar_t *) &hashstrings[(long int) entry->strip];
      else
         entry->strip = NULL;
      if (entry->affl)
         entry->affix = (ichar_t *) &hashstrings[(long int) entry->affix];
      else
         entry->affix = NULL;
      if (entry->classl)
         entry->jclass = (ichar_t *) &hashstrings[(long int) entry->jclass];
      else
         entry->jclass = NULL;
   }

   /*
   ** Warning - 'entry' and 'i' are reset in the body of the loop below.
   ** Don't try to optimize it by (e.g.) moving the decrement
   ** of i into the loop condition.
   */
   for (i = numsflags, entry = sflaglist;  i > 0;  i--, entry++) {
      if (entry->affl == 0) {
         cp = NULL;
         ind = &sflagindex[0];
         viazero = 1;
      }
      else {
         cp = entry->affix + entry->affl - 1;
         ind = &sflagindex[*cp];
         viazero = 0;
         while (ind->numents == 0  &&  ind->pu.fp != NULL) {
            if (cp == entry->affix) {
               ind = &ind->pu.fp[0];
               viazero = 1;
            }
            else {
               ind = &ind->pu.fp[*--cp];
               viazero = 0;
            }
         }
      }
      if (ind->numents == 0)
         ind->pu.ent = entry;
      ind->numents++;
      /*
      ** If this index entry has more than MAXSEARCH flags in it, we will split
      ** it into subentries to reduce the searching.  However, the split
      ** doesn't make sense in two cases:  (a) if we are already at the end of
      ** the current affix, or (b) if all the entries in the list have
      ** identical affixes.  Since the list is sorted, (b) is true if the first
      ** and last affixes in the list are identical.
      */
      if (!viazero  &&  ind->numents >= MAXSEARCH
          &&  icharcmp(entry->affix, ind->pu.ent->affix) != 0) {
         /* Sneaky trick:  back up and reprocess */
         entry = ind->pu.ent - 1; /* -1 is for entry++ in loop */
         i = numsflags - (entry - sflaglist);
         ind->pu.fp =
           (struct flagptr *)
             calloc((unsigned) (SET_SIZE + hashheader.nstrchars),
                    sizeof(struct flagptr));
         if (ind->pu.fp == NULL) {
            fprintf(stderr, LOOKUP_C_NO_LANG_SPACE);
            return -1;
         }
         ind->numents = 0;
      }
   }
   /*
   ** Warning - 'entry' and 'i' are reset in the body of the loop below.
   ** Don't try to optimize it by (e.g.) moving the decrement of i into the
   ** loop condition.
   */
   for (i = numpflags, entry = pflaglist;  i > 0;  i--, entry++) {
      if (entry->affl == 0) {
         cp = NULL;
         ind = &pflagindex[0];
         viazero = 1;
      }
      else {
         cp = entry->affix;
         ind = &pflagindex[*cp++];
         viazero = 0;
         while (ind->numents == 0  &&  ind->pu.fp != NULL) {
            if (*cp == 0) {
               ind = &ind->pu.fp[0];
               viazero = 1;
            }
            else {
               ind = &ind->pu.fp[*cp++];
               viazero = 0;
            }
         }
      }
      if (ind->numents == 0)
         ind->pu.ent = entry;
      ind->numents++;
      /*
      * If this index entry has more than MAXSEARCH flags in it, we will split
      * it into subentries to reduce the searching.  However, the split doesn't
      * make sense in two cases:  (a) if we are already at the end of the
      * current affix, or (b) if all the entries in the list have identical
      * affixes.  Since the list is sorted, (b) is true if the first and last
      * affixes in the list are identical.
      */
      if (!viazero  &&  ind->numents >= MAXSEARCH
          &&  icharcmp(entry->affix, ind->pu.ent->affix) != 0)
      {
         /* Sneaky trick:  back up and reprocess */
         entry = ind->pu.ent - 1; /* -1 is for entry++ in loop */
         i = numpflags - (entry - pflaglist);
         ind->pu.fp = (struct flagptr *)calloc(SET_SIZE + hashheader.nstrchars,
                                               sizeof(struct flagptr));
         if (ind->pu.fp == NULL) {
            fprintf(stderr, LOOKUP_C_NO_LANG_SPACE);
            return -1;
         }
         ind->numents = 0;
      }
   }
   return 0;
}


/*---------------------------------------------------------------------------*/

static int act_chartypes(void)
{
   int i, nextchar;

   if (hashheader.nstrchartype == 0)
      chartypes = NULL;
   else {
      chartypes = (struct strchartype *)
                 malloc(hashheader.nstrchartype * sizeof(struct strchartype));
      if (chartypes == NULL) {
         fprintf(stderr, LOOKUP_C_NO_LANG_SPACE);
         return -1;
      }
      for (i = 0, nextchar = hashheader.strtypestart;
           i < hashheader.nstrchartype; i++)  {
         chartypes[i].name = &hashstrings[nextchar];
         nextchar += strlen(chartypes[i].name) + 1;
         chartypes[i].deformatter = &hashstrings[nextchar];
         nextchar += strlen(chartypes[i].deformatter) + 1;
         chartypes[i].suffixes = &hashstrings[nextchar];
         while (hashstrings[nextchar] != '\0')
            nextchar += strlen(&hashstrings[nextchar]) + 1;
         nextchar++;
      }
   }
   return 0;
}


/*---------------------------------------------------------------------------*/

#ifdef INDEXDUMP
static void dumpindex(register struct flagptr *indexp, register int depth)
{
   register int i;
   int j, k;
   char stripbuf[INPUTWORDLEN + 4 * MAXAFFIXLEN + 4];

   for (i = 0;  i < SET_SIZE + hashheader.nstrchars;  i++, indexp++) {
      if (indexp->numents == 0  &&  indexp->pu.fp != NULL) {
         for (j = depth;  --j >= 0;  )
            putc(' ', stderr);
         if (i >= ' '  &&  i <= '~')
            putc(i, stderr);
         else
            fprintf(stderr, "0x%x", i);
         putc('\n', stderr);
         dumpindex(indexp->pu.fp, depth + 1);
      }
      else if (indexp->numents) {
          for (j = depth;  --j >= 0;  )
             putc(' ', stderr);
          if (i >= ' '  &&  i <= '~')
             putc(i, stderr);
          else
             fprintf(stderr, "0x%x", i);
          fprintf(stderr, " -> %d entries\n", indexp->numents);
          for (k = 0;  k < indexp->numents;  k++) {
             for (j = depth;  --j >= 0;  )
                putc(' ', stderr);
             if (indexp->pu.ent[k].stripl) {
                ichartostr(stripbuf, indexp->pu.ent[k].strip, sizeof stripbuf,
                           1);
                fprintf(stderr, "     entry %d (-%s,%s)\n",
                        &indexp->pu.ent[k] - sflaglist, stripbuf,
                        indexp->pu.ent[k].affl
                        ? ichartosstr(indexp->pu.ent[k].affix, 1) : "-");
             }
             else
                fprintf(stderr, "     entry %d (%s)\n",
                        &indexp->pu.ent[k] - sflaglist,
                        ichartosstr(indexp->pu.ent[k].affix, 1));
             }
          }
      }
   }
#endif

/*---------------------------------------------------------------------------*/

void dump_info()
{
#ifdef INDEXDUMP
   fprintf(stderr, "Prefix index table:\n");
   dumpindex(pflagindex, 0);
   fprintf(stderr, "Suffix index table:\n");
   dumpindex(sflagindex, 0);
#endif
}

/*---------------------------------------------------------------------------*/

int linit(void) {
    if (inited) return 0;
    if (read_info_from_disk() == -1) return -1;
    if (act_all_entry() == -1) return -1;
    dump_info();
    if (act_chartypes() == -1) return -1;
    inited = 1;
    return 0;
}

/*---------------------------------------------------------------------------*/

/* n is length of s */
struct dent *lookup(register ichar_t *s, int dotree)
{
   register struct dent *dp;
   register char *s1;
   char schar[MAXWLEN];

   dp = &hashtbl[hash(s, hashsize)];
   if (ichartostr(schar, s, sizeof schar, 1))
      fprintf(stderr, WORD_TOO_LONG(schar));
   for (  ;  dp ;  dp = dp->next) {
      /* quick strcmp, but only for equality */
      s1 = dp->word;
      if (s1  &&  s1[0] == schar[0]  &&  strcmp(s1 + 1, schar + 1) == 0
          && (!(dp->saw) || !saw_mode)) {
         if (saw_mode) dp->saw = 1;
         return dp;
      }
#ifndef NO_CAPITALIZATION_SUPPORT
      while (dp->flagfield & MOREVARIANTS)        /* Skip variations */
         dp = dp->next;
#endif
   }
   if (dotree) {   /* search in personal dictionary */
      return treelookup(s, &pers);
   }
   else
      return NULL;
}

/*---------------------------------------------------------------------------*/

void put_saws_off(register ichar_t *s, int dotree)
{
   register struct dent *dp;
   register char *s1;
   char schar[MAXWLEN];

   dp = &hashtbl[hash(s, hashsize)];
   if (ichartostr(schar, s, sizeof schar, 1))
      fprintf(stderr, WORD_TOO_LONG(schar));
   for (  ;  dp ;  dp = dp->next) {
      /* quick strcmp, but only for equality */
      s1 = dp->word;
      if (s1  &&  s1[0] == schar[0]  &&  strcmp(s1 + 1, schar + 1) == 0)
         dp->saw = 0;
#ifndef NO_CAPITALIZATION_SUPPORT
      while (dp->flagfield & MOREVARIANTS)        /* Skip variations */
         dp = dp->next;
#endif
   }
   if (dotree)   /* put saw off in personal dictionary */
      tree_saw_off(s);
}
