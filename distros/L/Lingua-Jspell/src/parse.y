%{

/*
 * Copyright 1992, 1993, Geoff Kuenning, Granada Hills, CA
 * All rights reserved.
 */

#include <string.h>
#include <ctype.h>
#include <stdlib.h>
#include "jsconfig.h"
#include "jspell.h"
#include "proto.h"
#include "msgs.h"

%}

%union
{
   int simple;                /* Simple char or lval from yylex */
   struct {
      char *set;             /* Character set */
      int complement;        /* NZ if it is a complement set: [^...] */
   } charset;
   unsigned char * string;              /* String */
   ichar_t *       istr;                /* Internal string */
   struct flagent *entry;               /* Flag entry */
}

%{

static int   yylex(void);                                       /* Trivial lexical analyzer */
static int   kwanalyze(int backslashed, unsigned char * str); /* Analyze a possible keyword */
static void  getqstring(void);                                /* Get (double-)quoted string */
static void  getrange(void);                               /* Get a lexical character range */
static int   backch(void);                               /* Process a backslashed character */
static void  yyerror(char * msg);                             /* Print out an error message */
int          yyopen(char * file);                                      /* Open a table file */
void         yyinit(void);                                        /* Initialize for parsing */
static int   grabchar(void);                       /* Get a character and track line number */
static void  ungrabchar(int ch);                /* Unget a character, tracking line numbers */
static int   sufcmp(struct flagent * flag1, struct flagent * flag2);
                                                          /* Compare suffix flags for qsort */
static int   precmp(struct flagent * flag1, struct flagent * flag2);
                                                          /* Compare prefix flags for qsort */
static int   addstringchar(unsigned char * str, int lower, int upper);
                                                     /* Add a string character to the table */
static int   stringcharcmp(char * a, char * b);         /* Strcmp() done right, for Sun 4's */

#ifdef TBLDEBUG
static void  tbldump(struct flagent * flagp, int numflags);            /* Dump a flag table */
static void  entdump(struct flagent * flagp);                        /* Dump one flag entry */
static void  setdump(char * setp, int mask);                    /* Dump a set specification */
static void  subsetdump(char * setp, int mask, int dumpval);     /* Dump part of a set spec */
#endif

struct kwtab
{
   char *kw;               /* Syntactic keyword */
   int val;                /* Lexical value */
};

#define TBLINC 10                /* Size to allocate table by */

static FILE *aff_file = NULL;      /* Input file pointer */
static int   centnum;              /* Number of entries in curents */
static int   centsize = 0;         /* Size of alloc'ed space in curents */
static int   ctypechars;           /* Size of string in current strtype */
static int   ctypenum = 0;         /* Number of entries in chartypes */
static int   ctypesize = 0;        /* Size of alloc'ed spc in chartypes */
static struct flagent * curents;   /* Current flag entry collection */
static char *fname = "(stdin)";    /* Current file name */
static char  lexungrab[MAXSTRINGCHARLEN * 2]; /* Spc for ungrabch */
static int   lineno = 1;           /* Current line number in file */
static struct flagent * table;     /* Current table being built */
static int   tblnum;               /* Numer of entries in table */
static int   tblsize = 0;          /* Size of the flag table */
static int   ungrablen;            /* Size of ungrab area */

/*---------------------------------------------------------------------------*/

void treat_flag_def(char *string, ichar_t *class, short flags)
{
   int i;

   if (strlen((char *) string) != 1)
      yyerror(PARSE_Y_LONG_FLAG);
   for (i = 0;  i < centnum;  i++) {  /* each flag has several lines of rules */
      curents[i].flagbit = CHARTOBIT(string[0]);
      curents[i].flagflags = flags;
   }
   /* NEW */
   i = CHARTOBIT(string[0]);
   gentable[i].jclass = (ichar_t *) malloc(
                       sizeof(ichar_t) * (icharlen(class) + 1));
   icharcpy(gentable[i].jclass, class);
   gentable[i].classl = icharlen(class);

   free((char *) string);
}

/*---------------------------------------------------------------------------*/

void treat_affix_rule(struct flagent *cond, ichar_t *strip, 
                      ichar_t *put, ichar_t *class)
{
   int i;

   cond->stripl = icharlen(strip);
   if (cond->stripl) {
      cond->strip = strip;
      upcase(strip);
   }
   else
      cond->strip = NULL;
   cond->affl = icharlen(put);
   if (cond->affl) {
      cond->affix = put;
      upcase(put);
   }
   else
      cond->affix = NULL;
   cond->jclass = class;
   cond->classl = icharlen(class);
   /*
   * As a special optimization (and a concession to those who the syntax that
   * way), convert any single condition that accepts all characters into no
   * condition at all.
   * (Convert the syntax ". > -xxx,yyy" into  " > -xxx,yyy"
   */
   if (cond->numconds == 1) {
      for (i = SET_SIZE + hashheader.nstrchars; --i >= 0; ) {
         if ((cond->conds[i] & 1) == 0)
            break;
      }
      if (i < 0)
         cond->numconds = 0;
   }
}

%}

%token <simple> '-'
%token <simple> '>'
%token <simple> ','
%token <simple> ':'
%token <simple> '.'
%token <simple> '*'
%token <simple> '+'
%token <simple> ';'
%token <simple> ALLAFFIXES
%token <simple> ALTSTRINGCHAR
%token <simple> ALTSTRINGTYPE
%token <simple> BOUNDARYCHARS
%token <simple> COMPOUNDMIN
%token <simple> COMPOUNDWORDS
%token <simple> DEFSTRINGTYPE
%token <simple> FLAG
%token <simple> FLAGMARKER
%token <simple> NROFFCHARS
%token <simple> OFF
%token <simple> ON
%token <simple> PREFIXES
%token <charset> RANGE
%token <simple> SUFFIXES
%token <string> STRING
%token <simple> STRINGCHAR
%token <simple> TEXCHARS
%token <simple> WORDCHARS

%type <simple> file
%type <simple> headers
%type <simple> option_group
%type <simple> charset_group
%type <simple> altchar_group
%type <simple> charset_stmt
%type <simple> option_stmt
%type <simple> altchar_stmt
%type <simple> altchar_spec_group
%type <simple> altchar_spec
%type <simple> deftype_stmt
%type <string> stringtype_info
%type <simple> filesuf_list
%type <string> filesuf
%type <charset> char_set
%type <simple> tables
%type <simple> prefix_table
%type <simple> suffix_table
%type <simple> table
%type <simple> flagdef
%type <simple> error
%type <simple> on_or_off
%type <simple> rules
%type <entry> affix_rule
%type <entry> cond_or_null
%type <entry> conditions
%type <istr> ichar_string
%type <istr> classif
%%
file            : headers tables
                | tables
                ;

headers         : option_group charset_group
                | option_group charset_group altchar_group
                | charset_group
                | charset_group altchar_group
                ;

option_group    : option_stmt
                | option_group option_stmt
                ;

charset_group   : deftype_stmt charset_stmt
                | charset_stmt
                | charset_group charset_stmt
                ;

deftype_stmt    : DEFSTRINGTYPE stringtype_info
                ;

altchar_group   : altchar_stmt
                | altchar_group altchar_stmt
                ;

charset_stmt    : WORDCHARS char_set char_set
                     {
                     int nextlower;
                     int nextupper;

                     for (nextlower = SET_SIZE + hashheader.nstrchars;
                             --nextlower > SET_SIZE; ) {
                        if ($2.set[nextlower] != 0 || $3.set[nextlower] != 0) {
                           yyerror(PARSE_Y_NO_WORD_STRINGS);
                           break;
                        }
                     }
                     for (nextlower = 0; nextlower < SET_SIZE; nextlower++) {
                        hashheader.wordchars[nextlower]
                           |= $2.set[nextlower] | $3.set[nextlower];
                        hashheader.lowerchars[nextlower]
                           |= $2.set[nextlower];
                        hashheader.upperchars[nextlower]
                           |= $3.set[nextlower];
                     }
                     for (nextlower = nextupper = 0; nextlower < SET_SIZE;
                          nextlower++) {
                        if ($2.set[nextlower]) {
                           for (  ; nextupper < SET_SIZE && !$3.set[nextupper];
                                nextupper++)
                                ;
                           if (nextupper == SET_SIZE) {
                              yyerror(PARSE_Y_UNMATCHED);
                           }
                           else {
                              hashheader.lowerconv[nextupper]
                                   = (ichar_t) nextlower;
                              hashheader.upperconv[nextlower]
                                   = (ichar_t) nextupper;
                              hashheader.sortorder[nextupper]
                                   = hashheader.sortval++;
                              hashheader.sortorder[nextlower]
                                   = hashheader.sortval++;
                              nextupper++;
                           }
                        }
                     }
                     for (  ;  nextupper < SET_SIZE;  nextupper++) {
                        if ($3.set[nextupper])
                           yyerror(PARSE_Y_UNMATCHED);
                     }
                     free($2.set);
                     free($3.set);
                  }
                | WORDCHARS char_set
                     {
                     int i;

                     for (i = SET_SIZE + hashheader.nstrchars;
                          --i > SET_SIZE; ) {
                        if ($2.set[i] != 0) {
                           yyerror(PARSE_Y_NO_WORD_STRINGS);
                           break;
                        }
                     }
                     for (i = 0;  i < SET_SIZE;  i++)
                        if ($2.set[i]) {
                           hashheader.wordchars[i] = 1;
                           hashheader.sortorder[i] = hashheader.sortval++;
                        }
                     free ($2.set);
                  }
                | BOUNDARYCHARS char_set char_set
                     {
                     int nextlower;
                     int nextupper;

                     for (nextlower = SET_SIZE + hashheader.nstrchars;
                          --nextlower > SET_SIZE;  ) {
                        if ($2.set[nextlower] != 0 || $3.set[nextlower] != 0) {
                           yyerror(PARSE_Y_NO_BOUNDARY_STRINGS);
                           break;
                        }
                     }
                     for (nextlower = 0; nextlower < SET_SIZE; nextlower++) {
                        hashheader.boundarychars[nextlower]
                           |= $2.set[nextlower] | $3.set[nextlower];
                        hashheader.lowerchars[nextlower]
                           |= $2.set[nextlower];
                        hashheader.upperchars[nextlower]
                           |= $3.set[nextlower];
                     }
                     for (nextlower = nextupper = 0; nextlower < SET_SIZE;
                          nextlower++) {
                        if ($2.set[nextlower]) {
                           for (  ; nextupper < SET_SIZE && !$3.set[nextupper];
                                nextupper++)
                              ;
                           if (nextupper == SET_SIZE)
                              yyerror (PARSE_Y_UNMATCHED);
                           else {
                               hashheader.lowerconv[nextupper]
                                   = (ichar_t) nextlower;
                               hashheader.upperconv[nextlower]
                                   = (ichar_t) nextupper;
                               hashheader.sortorder[nextupper]
                                   = hashheader.sortval++;
                               hashheader.sortorder[nextlower]
                                   = hashheader.sortval++;
                               nextupper++;
                            }
                         }
                      }
                     for (  ;  nextupper < SET_SIZE;  nextupper++) {
                        if ($3.set[nextupper])
                           yyerror(PARSE_Y_UNMATCHED);
                     }
                     free($2.set);
                     free($3.set);
                  }
                | BOUNDARYCHARS char_set
                     {
                     int i;

                     for (i = SET_SIZE + hashheader.nstrchars; --i > SET_SIZE;)
                     {
                        if ($2.set[i] != 0) {
                           yyerror(PARSE_Y_NO_BOUNDARY_STRINGS);
                           break;
                        }
                     }
                     for (i = 0;  i < SET_SIZE;  i++) {
                        if ($2.set[i]) {
                           hashheader.boundarychars[i] = 1;
                           hashheader.sortorder[i] = hashheader.sortval++;
                        }
                     }
                     free($2.set);
                   }
                | STRINGCHAR STRING
                     {
                     int len;

                     len = strlen((char *) $2);
                     if (len > MAXSTRINGCHARLEN)
                        yyerror(PARSE_Y_LONG_STRING);
                     else if (len == 0)
                        yyerror(PARSE_Y_NULL_STRING);
                     else if (hashheader.nstrchars >= MAXSTRINGCHARS)
                        yyerror(PARSE_Y_MANY_STRINGS);
                     else
                        (void) addstringchar($2, 0, 0);
                     free((char *) $2);
                     }
                | STRINGCHAR STRING STRING
                     {
                     int lcslot;
                     int len;
                     int ucslot;

                     len = strlen((char *) $2);
                     if (strlen((char *) $3) != len)
                        yyerror(PARSE_Y_LENGTH_MISMATCH);
                     else if (len > MAXSTRINGCHARLEN)
                        yyerror(PARSE_Y_LONG_STRING);
                     else if (len == 0)
                        yyerror(PARSE_Y_NULL_STRING);
                     else if (hashheader.nstrchars >= MAXSTRINGCHARS)
                        yyerror(PARSE_Y_MANY_STRINGS);
                     else {
                        /*
                         * Add the uppercase character first, so that
                         * it will sort first.
                         */
                        lcslot = ucslot = addstringchar($3, 0, 1);
                        if (ucslot >= 0)
                           lcslot = addstringchar($2, 1, 0);
                        if (ucslot >= 0  &&  lcslot >= 0) {
                           if (ucslot >= lcslot)
                              ucslot++;
                           hashheader.lowerconv[ucslot] = (ichar_t) lcslot;
                           hashheader.upperconv[lcslot] = (ichar_t) ucslot;
                        }
                     }
                     free((char *) $2);
                     free((char *) $3);
                  }
                ;

altchar_stmt    : ALTSTRINGTYPE stringtype_info
                | ALTSTRINGTYPE stringtype_info altchar_spec_group
                ;

stringtype_info : STRING STRING filesuf_list
                     {
                     chartypes[ctypenum].name = (char *) $1;
                     chartypes[ctypenum].deformatter = (char *) $2;
                     /*
                      * Implement a few common synonyms.  This should
                      * be generalized.
                      */
                     if (strcmp((char *) $2, "TeX") == 0)
                        strcpy((char *) $2, "tex");
                     else if (strcmp((char *) $2, "troff") == 0)
                        strcpy((char *) $2, "nroff");
                     /*
                      * Someday, we'll accept generalized deformatters.
                      * Then we can get rid of this test.
                      */
                     if (strcmp((char *) $2, "nroff") != 0
                         &&  strcmp((char *) $2, "tex") != 0)
                        yyerror(PARSE_Y_BAD_DEFORMATTER);
                     ctypenum++;
                     hashheader.nstrchartype = ctypenum;
                     }
                ;

filesuf_list    : filesuf
                     {
                     if (ctypenum >= ctypesize) {
                        if (ctypesize == 0)
                           chartypes = (struct strchartype *)
                               malloc(TBLINC * sizeof(struct strchartype));
                        else
                           chartypes = (struct strchartype *)
                            realloc((char *) chartypes,
                            (ctypesize + TBLINC) * sizeof(struct strchartype));
                        if (chartypes == NULL) {
                           yyerror(PARSE_Y_NO_SPACE);
                           exit(1);
                        }
                        ctypesize += TBLINC;
                     }
                     ctypechars = TBLINC * (strlen((char *) $1) + 1) + 1;
                     chartypes[ctypenum].suffixes =
                                             malloc((unsigned int) ctypechars);
                     if (chartypes[ctypenum].suffixes == NULL) {
                        yyerror(PARSE_Y_NO_SPACE);
                        exit(1);
                     }
                     strcpy(chartypes[ctypenum].suffixes, (char *) $1);
                     chartypes[ctypenum].suffixes[strlen ((char *) $1) + 1]
                         = '\0';
                     free((char *) $1);
                  }
                | filesuf_list filesuf
                     {
                     char *nexttype;
                     int offset;

                     for (nexttype = chartypes[ctypenum].suffixes;
                          *nexttype != '\0'; nexttype += strlen(nexttype) + 1)
                        ;
                     offset = nexttype - chartypes[ctypenum].suffixes;
                     if ((int) (offset + strlen((char *) $2) + 1)
                         >= ctypechars) {
                        ctypechars += TBLINC * (strlen((char *) $2) + 1);
                        chartypes[ctypenum].suffixes =
                            realloc(chartypes[ctypenum].suffixes,
                             (unsigned int) ctypechars);
                        if (chartypes[ctypenum].suffixes == NULL) {
                           yyerror(PARSE_Y_NO_SPACE);
                           exit(1);
                        }
                        nexttype = chartypes[ctypenum].suffixes + offset;
                     }
                     strcpy(nexttype, (char *) $2);
                     nexttype[strlen((char *) $2) + 1] = '\0';
                     free((char *) $2);
                  }
                ;

filesuf         : STRING
                ;

altchar_spec_group
                : altchar_spec
                | altchar_spec_group altchar_spec
                ;

altchar_spec    : ALTSTRINGCHAR STRING STRING
                     {
                     int i, len, slot;

                     len = strlen((char *) $2);
                     if (len > MAXSTRINGCHARLEN)
                        yyerror(PARSE_Y_LONG_STRING);
                     else if (len == 0)
                        yyerror(PARSE_Y_NULL_STRING);
                     else if (hashheader.nstrchars >= MAXSTRINGCHARS)
                        yyerror(PARSE_Y_MANY_STRINGS);
                     else if (!isstringch ((char *) $3, 1))
                        yyerror(PARSE_Y_NO_SUCH_STRING);
                     else {
                        slot = addstringchar($2, 0, 0) - SET_SIZE;
                        if (laststringch >= slot)
                           laststringch++;
                        hashheader.stringdups[slot] = (char) laststringch;
                        for (i = hashheader.nstrchars;  --i >= 0;  ) {
                           if (hashheader.stringdups[i] == laststringch)
                              hashheader.dupnos[slot]++;
                        }
                        /*
                         * The above code sets dupnos one too high,
                         * because it counts the character itself.
                         */
                        if (hashheader.dupnos[slot] != hashheader.nstrchartype)
                            yyerror(PARSE_Y_MULTIPLE_STRINGS);
                        hashheader.dupnos[slot]--;
                     }
                     free((char *) $2);
                     free((char *) $3);
                     }
                ;

option_stmt     : NROFFCHARS STRING
                     {
                     if (strlen((char *) $2) == sizeof(hashheader.nrchars))
                        bcopy((char *) $2, hashheader.nrchars,
                                     sizeof(hashheader.nrchars));
                     else
                        yyerror(PARSE_Y_WRONG_NROFF);
                     free((char *) $2);
                     }
                | TEXCHARS STRING
                     {
                     if (strlen((char *) $2) == sizeof(hashheader.texchars))
                        bcopy((char *) $2, hashheader.texchars,
                                     sizeof(hashheader.texchars));
                     else
                        yyerror(PARSE_Y_WRONG_TEX);
                     free((char *) $2);
                     }
                | COMPOUNDMIN STRING
                     {
                     unsigned char * digitp; /* Pointer to next digit */

                     for (digitp = $2;  *digitp != '\0';  digitp++) {
                        if (*digitp <= '0'  ||  *digitp >= '9') {
                           yyerror(PARSE_Y_BAD_NUMBER);
                           break;
                        }
                     }
                     hashheader.compoundmin = atoi ((const char *)$2);
                     }
                | COMPOUNDWORDS on_or_off
                     {
                     hashheader.defspaceflag = !$2;
                     }
                | ALLAFFIXES on_or_off
                     {
                     hashheader.defhardflag = $2;
                     }
                | FLAGMARKER STRING
                     {
                     if (strlen((char *) $2) != 1)
                        yyerror(PARSE_Y_LONG_FLAG);
                     else
                        hashheader.flagmarker = $2[0];
                     free((char *) $2);
                     }
                ;

char_set        : '.'
                     {
                     int i;
                     char *set;

                     set = malloc(SET_SIZE + MAXSTRINGCHARS);
                     if (set == NULL) {
                        yyerror(PARSE_Y_NO_SPACE);
                        exit(1);
                     }
                     $$.set = set;
                     for (i = SET_SIZE + MAXSTRINGCHARS;  --i >= 0;  )
                        *set++ = 1;
                     $$.complement = 0;
                     }
                | STRING
                     {
                     int setlen;

                     $$.set = malloc(SET_SIZE + MAXSTRINGCHARS);
                     if ($$.set == NULL) {
                        yyerror(PARSE_Y_NO_SPACE);
                        exit(1);
                     }
                     bzero($$.set, SET_SIZE + MAXSTRINGCHARS);
                     if (l1_isstringch ((char *) $1, setlen, 1)) {
                        if (setlen != strlen((char *) $1))
                           yyerror(PARSE_Y_NEED_BLANK);
                        $$.set[SET_SIZE + laststringch] = 1;
                     }
                     else {
                        if (strlen((char *) $1) != 1)
                           yyerror(PARSE_Y_NEED_BLANK);
                        $$.set[*$1] = 1;
                     }
                     free((char *) $1);
                     $$.complement = 0;
                     }
                | RANGE
                ;

on_or_off       : ON
                     {
                     $$ = 1;
                     }
                | OFF
                     {
                     $$ = 0;
                     }
                ;

tables          : prefix_table suffix_table
                | suffix_table prefix_table
                | prefix_table
                | suffix_table
                ;

prefix_table    : PREFIXES table
                     {
                     pflaglist = table;
                     numpflags = tblnum;
                     /*
                      * Sort the flag table.  This is critical so that jspell
                      * can build a correct index table.  The idea is to put
                      * similar affixes together.
                      */
                     qsort((char *) table, (unsigned) tblnum, sizeof(*table),
			   (int (*) (const void *, const void *)) precmp);
#ifdef TBLDEBUG
                     fprintf(stderr, "prefixes\n");
                     tbldump(table, tblnum);
#endif
                     tblsize = 0;
                     }
                ;

suffix_table    : SUFFIXES table
                     {
                     sflaglist = table;
                     numsflags = tblnum;
                     /*
                      * See comments on the prefix sort.
                      */
                     qsort((char *) table, (unsigned) tblnum, sizeof(*table),
                           (int (*) (const void *, const void *)) sufcmp);
#ifdef TBLDEBUG
                     fprintf(stderr, "suffixes\n");
                     tbldump(table, tblnum);
#endif
                     tblsize = 0;
                     }
                ;

table           : flagdef
                     {
                     if (tblsize == 0) {
                        tblsize = centnum + TBLINC;
                        tblnum = 0;
                        table = (struct flagent *)
                           malloc(tblsize * (sizeof(struct flagent)));
                        if (table == NULL) {
                           yyerror(PARSE_Y_NO_SPACE);
                           exit(1);
                        }
                     }
                     else if (tblnum + centnum >= tblsize) {
                        tblsize = tblnum + centnum + TBLINC;
                        table = (struct flagent *)
                           realloc((char *) table,
                             tblsize * (sizeof(struct flagent)));
                        if (table == NULL) {
                           yyerror(PARSE_Y_NO_SPACE);
                           exit(1);
                        }
                     }
                     for (tblnum = 0;  tblnum < centnum;  tblnum++)
                        table[tblnum] = curents[tblnum];
                     centnum = 0;
                  }
                | table flagdef
                     {
                     int i;

                     if (tblnum + centnum >= tblsize) {
                        tblsize = tblnum + centnum + TBLINC;
                        table = (struct flagent *) realloc((char *) table,
                                           tblsize * (sizeof(struct flagent)));
                        if (table == NULL) {
                           yyerror(PARSE_Y_NO_SPACE);
                           exit(1);
                        }
                     }
                     for (i = 0;  i < centnum;  i++)
                        table[tblnum + i] = curents[i];
                     tblnum += centnum;
                     centnum = 0;
                  }
                ;

flagdef         : FLAG STRING ':' classif rules
                     { treat_flag_def((char *)$2, $4, 0); }
                | FLAG '*' STRING ':' classif rules
                     { treat_flag_def((char *)$3, $5, FF_CROSSPRODUCT); }
                | FLAG '+' STRING ':' classif rules
                     { treat_flag_def((char *)$3, $5, FF_REC); }
                | error
                     { $$ = 0; }
                ;

rules           : affix_rule
                     {
                     if (centsize == 0) {
                         curents = (struct flagent *)
                           malloc(TBLINC * (sizeof(struct flagent)));
                         if (curents == NULL) {
                             yyerror(PARSE_Y_NO_SPACE);
                             exit(1);
                         }
                         centsize = TBLINC;
                     }
                     curents[0] = *$1;
                     centnum = 1;
                     free((char *) $1);
                     $$ = 0;
                     }
                | rules affix_rule
                     {
                     if (centnum >= centsize) {
                         centsize += TBLINC;
                         curents = (struct flagent *)
                           realloc((char *) curents,
                             centsize * (sizeof(struct flagent)));
                         if (curents == NULL) {
                             yyerror(PARSE_Y_NO_SPACE);
                             exit(1);
                         }
                     }
                     curents[centnum] = *$2;
                     centnum++;
                     free((char *) $2);
                     }
                ;

affix_rule      : cond_or_null '>' ichar_string classif
                     {  treat_affix_rule($1, strtosichar("", 1), $3, $4);
                        $$ = $1;
                     }
                | cond_or_null '>' '-' ichar_string ',' ichar_string classif
                     {  treat_affix_rule($1, $4, $6, $7);
                        $$ = $1;
                      }
                | cond_or_null '>' '-' ichar_string ',' '-' classif
                     {  treat_affix_rule($1, $4, strtosichar("", 1), $7);
                        $$ = $1;
                      }
                ;

cond_or_null    : /* Empty */
                     {
                     struct flagent *ent;

                     ent = (struct flagent *) malloc(sizeof(struct flagent));
                     if (ent == NULL) {
                        yyerror(PARSE_Y_NO_SPACE);
                        exit(1);
                     }
                     ent->numconds = 0;
                     bzero(ent->conds, SET_SIZE + MAXSTRINGCHARS);
                     $$ = ent;
                     }
                | conditions
                ;

conditions      : char_set
                     {
                     struct flagent *ent;
                     int i;

                     ent = (struct flagent *) malloc(sizeof(struct flagent));
                     if (ent == NULL) {
                        yyerror(PARSE_Y_NO_SPACE);
                        exit(1);
                     }
                     ent->numconds = 1;
                     bzero(ent->conds, SET_SIZE + MAXSTRINGCHARS);
                     /*
                      * Copy conditions to the new entry, making sure that
                      * uppercase versions are generated for lowercase input.
                      */
                     for (i = SET_SIZE + MAXSTRINGCHARS;  --i >= 0; ) {
                        if ($1.set[i]) {
                           ent->conds[i] = 1;
                           if (!$1.complement)
                              ent->conds[mytoupper((ichar_t) i)] = 1;
                        }
                     }
                     if ($1.complement) {
                        for (i = SET_SIZE + MAXSTRINGCHARS; --i >= 0; ) {
                           if ($1.set[i] == 0)
                              ent->conds[mytoupper((ichar_t) i)] = 0;
                        }
                     }
                     free($1.set);
                     $$ = ent;
                     }
                | conditions char_set
                     {
                     int i;
                     int mask;

                     if ($1->numconds >= 8) {
                        yyerror(PARSE_Y_MANY_CONDS);
                        $1->numconds = 7;
                     }
                     mask = 1 << $1->numconds;
                     $1->numconds++;
                     for (i = SET_SIZE + MAXSTRINGCHARS; --i >= 0; ) {
                        if ($2.set[i]) {
                           $1->conds[i] |= mask;
                           if (!$2.complement)
                              $1->conds[mytoupper((ichar_t) i)]  |= mask;
                        }
                     }
                     if ($2.complement) {
                        mask = ~mask;
                        for (i = SET_SIZE + MAXSTRINGCHARS; --i >= 0; ) {
                           if ($2.set[i] == 0)
                              $1->conds[mytoupper ((ichar_t) i)] &= mask;
                        }
                     }
                     free($2.set);
                     }
                ;

ichar_string    : STRING
                     {
                     ichar_t *tichar;

                     tichar = strtosichar((char *) $1, 1);
                     $$ = (ichar_t *) malloc(sizeof(ichar_t)
                                             * (icharlen(tichar) + 1));
                     if ($$ == NULL) {
                        yyerror(PARSE_Y_NO_SPACE);
                        exit(1);
                     }
                     icharcpy($$, tichar);
                     free((char *) $1);
                     }
                ;

classif         : /* empty */
                   {
                     $$ = (ichar_t *) malloc(sizeof(ichar_t));
                     icharcpy($$, strtosichar("", 1));
                   }
                | ';' STRING
                   {
                     ichar_t *tichar;

                     tichar = strtosichar((char *) $2, 1);
                     $$ = (ichar_t *) malloc(sizeof(ichar_t)
                                             * (icharlen(tichar) + 1));
                     if ($$ == NULL) {
                        yyerror(PARSE_Y_NO_SPACE);
                        exit(1);
                     }
                     icharcpy($$, tichar);
                     free((char *) $2);   /* ??? */
                   }
                ;

%%
static struct kwtab                        /* Table of built-in keywords */
    keywords[] =
    {
    {"allaffixes", ALLAFFIXES},
    {"altstringchar", ALTSTRINGCHAR},
    {"altstringtype", ALTSTRINGTYPE},
    {"boundarychars", BOUNDARYCHARS},
    {"compoundmin", COMPOUNDMIN},
    {"compoundwords", COMPOUNDWORDS},
    {"defstringtype", DEFSTRINGTYPE},
    {"flag", FLAG},
    {"flagmarker", FLAGMARKER},
    {"nroffchars", NROFFCHARS},
    {"troffchars", NROFFCHARS},
    {"on", ON},
    {"off", OFF},
    {"prefixes", PREFIXES},
    {"stringchar", STRINGCHAR},
    {"suffixes", SUFFIXES},
    {"TeXchars", TEXCHARS},
    {"texchars", TEXCHARS},
    {"wordchars", WORDCHARS},
    {NULL, 0}
    };

/*----------------------------------------------------------------------------*/
/*
 * Trivial lexical analyzer.
 */
static int yylex()
{
   int backslashed;                /* NZ if backslash appeared */
   register int  ch;               /* Next character seen */
   register unsigned char *lexp;   /* Pointer into lexstring */
   unsigned char lexstring[256];   /* Space for collecting strings */

   while ((ch = grabchar()) != EOF  &&  (isspace(ch)  ||  ch == '#'))
   {                        /* Skip whitespace and comments */
      if (ch == '#') {
         while ((ch = grabchar()) != EOF  &&  ch != '\n')
             ;
      }
   }
   switch (ch) {
       case EOF:
           return EOF;
       case '"':
           getqstring();
           return STRING;
       case '-':
       case '>':
       case ',':
       case ':':
       case '.':
       case '*':
       case '+':
       case ';':
           yylval.simple = ch;
           return ch;
       case '[':                /* Beginning of a range set ] */
           getrange();        /* Get the range */
           return RANGE;
   }
   /*
    * We get here if the character is an ordinary one;  note that
    * this includes backslashes.
    */
   backslashed = 0;
   lexp = lexstring;
   for (  ;  ;  ) {
      switch (ch) {
          case EOF:
              *lexp = '\0';
              return kwanalyze(backslashed, lexstring);
          case '\\':
              backslashed = 1;
              ch = backch();
              *lexp++ = (char) ch;
              break;
          case ' ':
          case '\t':
          case '\n':
          case '\f':
          case '\r':
              *lexp = '\0';
              return kwanalyze(backslashed, lexstring);
          case '#':
          case '>':
          case ':':
          case '-':
          case ',':
          case ';':
          case '[':                        /* ] */
              ungrabchar(ch);
              *lexp = '\0';
              return kwanalyze(backslashed, lexstring);
          default:
              *lexp++ = (char) ch;
#ifdef NO8BIT
              if (ch & 0x80)
                 yyerror(PARSE_Y_8_BIT);
#endif /* NO8BIT */
              break;
      }
      ch = grabchar();
   }
}

/*----------------------------------------------------------------------------*/

static int kwanalyze(int backslashed,        /* NZ if string had a backslash */
                     register unsigned char *str)   /* String to analyze */
{
   register struct kwtab *kwptr;               /* Pointer into keyword table */

   yylval.simple = 0;
   if (!backslashed)                        /* Backslash means not keyword */
   {
      for (kwptr = keywords;  kwptr->kw != NULL;  kwptr++) {
         if (strcmp(kwptr->kw, (char *) str) == 0)
            return(yylval.simple = kwptr->val);
      }
   }
   yylval.string =
     (unsigned char *) malloc((unsigned) strlen((char *) str) + 1);
   if (yylval.string == NULL) {
      yyerror(PARSE_Y_NO_SPACE);
      exit(1);
   }
   (void) strcpy((char *) yylval.string, (char *) str);
#ifdef NO8BIT
   while (*str != '\0') {
      if (*str++ & 0x80)
         yyerror(PARSE_Y_8_BIT);
   }
#endif /* NO8BIT */
   return STRING;
}

/*----------------------------------------------------------------------------*/
/*
 * Analyze a string in double quotes.  The leading quote has already
 * been processed.
 */
static void getqstring()
{
   register int ch;                /* Next character read */
   char lexstring[256];        /* Room to collect the string */
   register char *lexp;                /* Pointer into lexstring */

   for (lexp = lexstring;
        (ch = grabchar()) != EOF  &&  ch != '"'
         &&  lexp < &lexstring[sizeof lexstring - 1];  ) {
      if (ch == '\\')
         ch = backch();
      *lexp++ = (char) ch;
   }
   *lexp++ = '\0';
   if (ch == EOF)
      yyerror(PARSE_Y_EOF);
   else if (ch != '"') {
      yyerror(PARSE_Y_LONG_QUOTE);
      while ((ch = grabchar()) != EOF  &&  ch != '"') {
         if (ch == '\\')
            ch = backch();
      }
   }
   yylval.string = (unsigned char *) malloc((unsigned) (lexp - lexstring));
   if (yylval.string == NULL) {
      yyerror(PARSE_Y_NO_SPACE);
      exit(1);
   }
   (void) strcpy((char *) yylval.string, lexstring);
#ifdef NO8BIT
   for (lexp = lexstring;  *lexp != '\0';  ) {
      if (*lexp++ & 0x80)
         yyerror(PARSE_Y_8_BIT);
   }
#endif /* NO8BIT */
}

/*----------------------------------------------------------------------------*/
/*
 * Analyze a range (e.g., [A-Za-z]).  The left square bracket
 * has already been processed.
 */
static void getrange()                        /* Parse a range set */
{
   register int ch;                /* Next character read */
   register int lastch;                /* Previous char, for ranges */
   char stringch[MAXSTRINGCHARLEN];
   int stringchlen;

   yylval.charset.set = malloc(SET_SIZE + MAXSTRINGCHARS);
   if (yylval.charset.set == NULL) {
      yyerror(PARSE_Y_NO_SPACE);
      exit(1);
   }

   /* Start with a null set */
   (void) bzero(yylval.charset.set, SET_SIZE + MAXSTRINGCHARS);
   yylval.charset.complement = 0;

   lastch = -1;
   ch = grabchar();
   if (ch == '^') {
      yylval.charset.complement = 1;
      ch = grabchar();
   }
   /* [ */
   if (ch == ']') {
      /* [[ */
      lastch = ']';
      yylval.charset.set[']'] = 1;
   }
   else
      ungrabchar(ch);
   /* [ */
   while ((ch = grabchar()) != EOF  &&  ch != ']') {
      if (isstringstart(ch)) {               /* Handle a possible string character */
          stringch[0] = (char) ch;
          for (stringchlen = 1;
            stringchlen < MAXSTRINGCHARLEN;
            stringchlen++) {
              stringch[stringchlen] = '\0';
              if (isstringch(stringch, 1)) {
                  yylval.charset.set[SET_SIZE + laststringch] = 1;
                  stringchlen = 0;
                  break;
              }
              ch = grabchar();
              if (ch == EOF)
                  break;
              else
                  stringch[stringchlen] = (char) ch;
          }
          if (stringchlen == 0) {
              lastch = -1;                /* String characters can't be ranges */
              continue;                /* We found a string character */
          }
          /*
           * Not a string character - put it back
           */
          while (--stringchlen > 0)
              ungrabchar(stringch[stringchlen] & 0xFF);
          ch = stringch[0] & 0xFF;
      }
      if (ch == '\\') {
          lastch = ch = backch();
          yylval.charset.set[ch] = 1;
          continue;
      }
#ifdef NO8BIT
      if (ch & 0x80) {
         yyerror(PARSE_Y_8_BIT);
         ch &= 0x7F;
      }
#endif /* NO8BIT */
      if (ch == '-') {                       /* Handle a range */
          if (lastch == -1) {
              lastch = ch = '-';        /* Not really a range */
              yylval.charset.set['-'] = 1;
          }
          else {
              ch = grabchar();
              /* [ */
              if (ch == EOF  ||  ch == ']') {
                  lastch = ch = '-';        /* Not really range */
                  yylval.charset.set['-'] = 1;
                  if (ch != EOF)
                      ungrabchar(ch);
              }
              else {
#ifdef NO8BIT
                  if (ch & 0x80) {
                     yyerror(PARSE_Y_8_BIT);
                     ch &= 0x7F;
                  }
#endif /* NO8BIT */
                 if (ch == '\\')
                    ch = backch();
                 while (lastch <= ch)
                    yylval.charset.set[lastch++] = 1;
                 lastch = -1;
              }
          }
      }
      else {
         lastch = ch;
         yylval.charset.set[ch] = 1;
      }
   }
   if (yylval.charset.complement) {
      for (ch = 0;  ch < SET_SIZE + MAXSTRINGCHARS;  ch++)
         yylval.charset.set[ch] = !yylval.charset.set[ch];
   }
}

/*----------------------------------------------------------------------------*/

static int backch()                 /* Process post-backslash characters */
{
   register int ch;                /* Next character read */
   register int octval;                /* Budding octal value */

   ch = grabchar();
   if (ch == EOF)
      return '\\';
   else if (ch >= '0'  &&  ch <= '7') {
       octval = ch - '0';
       ch = grabchar();
       if (ch >= '0'  &&  ch <= '7') {
          octval = (octval << 3) + ch - '0';
          ch = grabchar();
          if (ch >= '0'  &&  ch <= '7')
             octval = (octval << 3) + ch - '0';
          else
             ungrabchar(ch);
       }
       else if (ch != EOF)
           ungrabchar(ch);
       ch = octval;
   }
   else if (ch == 'x') {
       ch = grabchar();
       octval = 0;
       if ((ch >= '0'  &&  ch <= '9')
         ||  (ch >= 'a'  &&  ch <= 'f')
         ||  (ch >= 'A'  &&  ch <= 'F')) {
           if (ch >= '0'  &&  ch <= '9')
              octval = ch - '0';
           else if (ch >= 'a'  &&  ch <= 'f')
              octval = ch - 'a' + 0xA;
           else if (ch >= 'A'  &&  ch <= 'F')
              octval = ch - 'A' + 0xA;
           ch = grabchar();
           octval <<= 4;
           if (ch >= '0'  &&  ch <= '9')
              octval |= ch -'0';
           else if (ch >= 'a'  &&  ch <= 'f')
              octval |= ch - 'a' + 0xA;
           else if (ch >= 'A'  &&  ch <= 'F')
              octval |= ch - 'A' + 0xA;
           else if (ch != EOF) {
              octval >>= 4;
              ungrabchar(ch);
           }
       }
       else if (ch != EOF)
          ungrabchar(ch);
       ch = octval;
   }
   else {
      switch (ch) {
         case 'n': ch = '\n'; break;
         case 'f': ch = '\f'; break;
         case 'r': ch = '\r'; break;
         case 'b': ch = '\b'; break;
         case 't': ch = '\t'; break;
         case 'v': ch = '\v'; break;
      }
   }
#ifdef NO8BIT
   if (ch & 0x80) {
      yyerror(PARSE_Y_8_BIT);
      ch &= 0x7F;
   }
#endif /* NO8BIT */
   return ch;
}

/*----------------------------------------------------------------------------*/

static void yyerror(char *str  /* Error string */)
{
   fflush(stdout);
   fprintf(stderr, PARSE_Y_ERROR_FORMAT(fname, lineno, str));
   fflush(stderr);
}

/*----------------------------------------------------------------------------*/

int yyopen(register char *file   /* File name to be opened */)
{
   fname = malloc((unsigned) strlen(file) + 1);
   if (fname == NULL) {
      fprintf(stderr, PARSE_Y_MALLOC_TROUBLE);
      exit(1);
   }
   strcpy(fname, file);
   aff_file = fopen(file, "r");
   if (aff_file == NULL) {
      fprintf(stderr, CANT_OPEN, file);
      perror("");
      return 1;
   }
   lineno = 1;
   return 0;
}

/*----------------------------------------------------------------------------*/

void yyinit()
{
   register int i;        /* Loop counter */

   if (aff_file == NULL)
      aff_file = stdin;        /* Must be dynamically initialized on Amigas */
   for (i = 0;  i < SET_SIZE + MAXSTRINGCHARS;  i++) {
      hashheader.lowerconv[i] = (ichar_t) i;
      hashheader.upperconv[i] = (ichar_t) i;
      hashheader.wordchars[i] = 0;
      hashheader.lowerchars[i] = 0;
      hashheader.upperchars[i] = 0;
      hashheader.boundarychars[i] = 0;
      /*
       * The default sort order is a big value so that there is room
       * to insert "underneath" it.  In this way, special characters
       * will sort last, but in ASCII order.
       */
      hashheader.sortorder[i] = i + 1 + 2 * SET_SIZE;
   }
   for (i = 0;  i < SET_SIZE;  i++)
      hashheader.stringstarts[i] = 0;
   for (i = 0;  i < MAXSTRINGCHARS;  i++) {
      hashheader.stringdups[i] = (char) i;
      hashheader.dupnos[i] = 0;
   }

   hashheader.sortval = 1;        /* This is so 0 can mean uninitialized */
   bcopy(NRSPECIAL, hashheader.nrchars, sizeof hashheader.nrchars);
   bcopy(TEXSPECIAL, hashheader.texchars, sizeof hashheader.texchars);
   hashheader.defspaceflag = 1; /* Default is to report missing blanks */
   hashheader.defhardflag = 0; /* Default is to try hard only if failures */
   hashheader.nstrchars = 0;        /* No string characters to start with */
   hashheader.flagmarker = '/'; /* Default flag marker is slash */
   hashheader.compoundmin = 3;        /* Dflt is at least 3 chars in cmpnd parts */
   /* Set up magic numbers and compile options */
   hashheader.magic = hashheader.magic2 = MAGIC;
   hashheader.compileoptions = COMPILEOPTIONS;
   hashheader.maxstringchars = MAXSTRINGCHARS;
   hashheader.maxstringcharlen = MAXSTRINGCHARLEN;

   init_gentable();
}

/*----------------------------------------------------------------------------*/

static int grabchar()                /* Get a character and count lines */
{
   int ch;        /* Next input character */

   if (ungrablen > 0)
      ch = lexungrab[--ungrablen] & 0xFF;
   else
      ch = getc(aff_file);
   if (ch == '\n')
      lineno++;
   return ch;
}

/*----------------------------------------------------------------------------*/

static void ungrabchar(           /* Unget a character, tracking line numbers */
                       int ch)        /* Character to put back */
{
   if (ch == '\n')
      lineno--;
   if (ch != EOF) {
      if (ungrablen == sizeof(lexungrab))
         yyerror(PARSE_Y_UNGRAB_PROBLEM);
      else
         lexungrab[ungrablen++] = (char) ch;
   }
}

/*----------------------------------------------------------------------------*/

static int sufcmp(                     /* Compare suffix flags for qsort */
              register struct flagent *flag1,        /* Flags to be compared */
              register struct flagent *flag2)        /* ... */
{
   register ichar_t *cp1;        /* Pointer into flag1's suffix */
   register ichar_t *cp2;        /* Pointer into flag2's suffix */

   if (flag1->affl == 0  ||  flag2->affl == 0)
       return flag1->affl - flag2->affl;
   cp1 = flag1->affix + flag1->affl;
   cp2 = flag2->affix + flag2->affl;
   while (*--cp1 == *--cp2  &&  cp1 > flag1->affix  &&  cp2 > flag2->affix)
       ;
   if (*cp1 == *cp2) {
      if (cp1 == flag1->affix) {
         if (cp2 == flag2->affix)
            return 0;
         else
            return -1;
      }
      else
         return 1;
   }
   return *cp1 - *cp2;
}

/*----------------------------------------------------------------------------*/

static int precmp(                     /* Compare prefix flags for qsort */
    register struct flagent *flag1,        /* Flags to be compared */
    register struct flagent *flag2)        /* ... */
{
   if (flag1->affl == 0  ||  flag2->affl == 0)
      return flag1->affl - flag2->affl;
   else
      return icharcmp(flag1->affix, flag2->affix);
}

/*----------------------------------------------------------------------------*/

static int addstringchar(    /* Add a string character */
   register unsigned char *str,        /* String character to be added */
   int lower,        /* NZ if a lower string */
   int upper)        /* NZ if an upper string */
{
   int len;          /* Length of the string */
   register int mslot;        /* Slot being moved or modified */
   register int slot;        /* Where to put it */

   len = strlen((char *) str);
   if (len > MAXSTRINGCHARLEN) {
      yyerror(PARSE_Y_LONG_STRING);
   }
   else if (len == 0) {
      yyerror(PARSE_Y_NULL_STRING);
      return -1;
   }
   else if (hashheader.nstrchars >= MAXSTRINGCHARS) {
      yyerror(PARSE_Y_MANY_STRINGS);
      return -1;
   }

   /*
    * Find where to put the new character
    */
   for (slot = 0;  slot < hashheader.nstrchars;  slot++) {
      if (stringcharcmp(&hashheader.stringchars[slot][0], (char *) str) > 0)
         break;
   }
   /*
    * Fix all duplicate numbers to reflect the new slot.
    */
   for (mslot = hashheader.nstrchars;  --mslot >= 0;  ) {
      if (hashheader.stringdups[mslot] >= slot)
         hashheader.stringdups[mslot]++;
   }
   /*
    * Fix all characters before it so that their case conversion reflects
    * the new locations of the characters that will follow the new one.
    */
   slot += SET_SIZE;
   for (mslot = SET_SIZE;  mslot < slot;  mslot++) {
      if (hashheader.lowerconv[mslot] >= (ichar_t) slot)
         hashheader.lowerconv[mslot]++;
      if (hashheader.upperconv[mslot] >= (ichar_t) slot)
         hashheader.upperconv[mslot]++;
   }
   /*
    * Slide up all the other characters to make room for the new one, also
    * making the appropriate changes in the case-conversion tables.
    */
   for (mslot = hashheader.nstrchars + SET_SIZE;  --mslot >= slot;  ) {
      strcpy(&hashheader.stringchars[mslot + 1 - SET_SIZE][0],
                    &hashheader.stringchars[mslot - SET_SIZE][0]);
      hashheader.lowerchars[mslot + 1] = hashheader.lowerchars[mslot];
      hashheader.upperchars[mslot + 1] = hashheader.upperchars[mslot];
      hashheader.wordchars[mslot + 1] = hashheader.wordchars[mslot];
      hashheader.boundarychars[mslot + 1] = hashheader.boundarychars[mslot];
      if (hashheader.lowerconv[mslot] >= (ichar_t) slot)
         hashheader.lowerconv[mslot]++;
      if (hashheader.upperconv[mslot] >= (ichar_t) slot)
         hashheader.upperconv[mslot]++;
      hashheader.lowerconv[mslot + 1] = hashheader.lowerconv[mslot];
      hashheader.upperconv[mslot + 1] = hashheader.upperconv[mslot];
      hashheader.sortorder[mslot + 1] = hashheader.sortorder[mslot];
      hashheader.stringdups[mslot + 1 - SET_SIZE] =
                 hashheader.stringdups[mslot - SET_SIZE];
      hashheader.dupnos[mslot + 1 - SET_SIZE] =
                 hashheader.dupnos[mslot - SET_SIZE];
   }
   /*
    * Insert the new string character into the slot we made.  The
    * caller may choose to change the case-conversion field.
    */
   strcpy(&hashheader.stringchars[slot - SET_SIZE][0], (char *) str);
   hashheader.lowerchars[slot] = (char) lower;
   hashheader.upperchars[slot] = (char) upper;
   hashheader.wordchars[slot] = 1;
   hashheader.boundarychars[slot] = 0;
   hashheader.sortorder[slot] = hashheader.sortval++;
   hashheader.lowerconv[slot] = (ichar_t) slot;
   hashheader.upperconv[slot] = (ichar_t) slot;
   hashheader.stringdups[slot - SET_SIZE] = slot - SET_SIZE;
   hashheader.dupnos[slot - SET_SIZE] = 0;
   /*
    * Add the first character of the string to the string-starts table, and
    * bump the count.
    */
   hashheader.stringstarts[str[0]] = 1;
   hashheader.nstrchars++;
   return slot;
}

/*----------------------------------------------------------------------------*/
/*
 * This routine is a reimplemention of strcmp(), needed because the
 * idiots at Sun managed to screw up the implementation of strcmp on
 * Sun 4's (they used unsigned comparisons, even though characters
 * default to signed).  I hate hate HATE putting in this routine just
 * to support the stupidity of one programmer who ought to find a new
 * career digging ditches, but there are a lot of Sun 4's out there,
 * so I don't really have a lot of choice.
 */
static int stringcharcmp(register char *a, register char *b)
{

#ifdef NO8BIT
   while (*a != '\0') {
      if (((*a++ ^ *b++) & NOPARITY) != 0)
         return(*--a & NOPARITY) - (*--b & NOPARITY);
   }
   return(*a & NOPARITY) - (*b & NOPARITY);
#else /* NO8BIT */
   while (*a != '\0') {
      if (*a++ != *b++)
         return *--a - *--b;
   }
   return *a - *b;
#endif /* NO8BIT */
}

/*----------------------------------------------------------------------------*/

#ifdef TBLDEBUG
static void tbldump(                        /* Dump a flag table */
   register struct flagent *flagp,        /* First flag entry to dump */
   register int numflags) /* Number of flags to dump */
{
   while (--numflags >= 0)
      entdump(flagp++);
}

/*----------------------------------------------------------------------------*/

static void entdump(                      /* Dump one flag entry */
   register struct flagent *flagp)        /* Flag entry to dump */
{
   register int cond;        /* Condition number */

   fprintf(stderr, "flag %s%c:\t",
           (flagp->flagflags & FF_CROSSPRODUCT) ? "*" : "", 
           BITTOCHAR(flagp->flagbit));
   for (cond = 0;  cond < flagp->numconds;  cond++) {
      setdump(flagp->conds, 1 << cond);
      if (cond < flagp->numconds - 1)
         putc(' ', stderr);
   }
   if (cond == 0)                        /* No conditions at all? */
      putc('.', stderr);
   fprintf(stderr, "\t> ");
   putc('\t', stderr);
   if (flagp->stripl)
      fprintf(stderr, "-%s,", ichartosstr(flagp->strip, 1));
   fprintf(stderr, "%s\n",
     flagp->affl ? ichartosstr(flagp->affix, 1) : "-");
}

/*----------------------------------------------------------------------------*/

static void setdump(               /* Dump a set specification */
   register char *setp,        /* Set to be dumped */
   register int   mask)        /* Mask for bit to be dumped */
{
   register int   cnum;        /* Next character's number */
   register int   firstnz; /* Number of first NZ character */
   register int   numnz;        /* Number of NZ characters */

   numnz = 0;
   for (cnum = SET_SIZE + hashheader.nstrchars;  --cnum >= 0;  ) {
      if (setp[cnum] & mask) {
         numnz++;
         firstnz = cnum;
      }
   }
   if (numnz == 1) {
      if (cnum < SET_SIZE)
         putc(firstnz, stderr);
      else
         fputs(hashheader.stringchars[cnum - SET_SIZE], stderr);
   }
   else if (numnz == SET_SIZE)
      putc('.', stderr);
   else if (numnz > SET_SIZE / 2) {
      fprintf(stderr, "[^");
      subsetdump(setp, mask, 0);
      putc(']', stderr);
   }
   else {
      putc('[', stderr);
      subsetdump(setp, mask, mask);
      putc(']', stderr);
   }
}

/*----------------------------------------------------------------------------*/

static void subsetdump(    /* Dump part of a set spec */
   register char *setp,       /* Set to be dumped */
   register int mask,         /* Mask for bit to be dumped */
   register int dumpval)      /* Value to be printed */
{
   register int cnum;         /* Next character's number */
   register int rangestart;   /* Value starting a range */

   for (cnum = 0;  cnum < SET_SIZE;  setp++, cnum++) {
      if (((*setp ^ dumpval) & mask) == 0) {
          for (rangestart = cnum;  cnum < SET_SIZE;  setp++, cnum++) {
             if ((*setp ^ dumpval) & mask)
                break;
          }
          if (cnum == rangestart + 1)
             putc(rangestart, stderr);
          else if (cnum <= rangestart + 3) {
             while (rangestart < cnum) {
                putc(rangestart, stderr);
                rangestart++;
             }
          }
          else
             fprintf(stderr, "%c-%c", rangestart, cnum - 1);
      }
   }
   for (  ;  cnum < SET_SIZE + hashheader.nstrchars;  setp++, cnum++) {
      if (((*setp ^ dumpval) & mask) == 0)
         fputs(hashheader.stringchars[cnum - SET_SIZE], stderr);
   }
}
#endif
