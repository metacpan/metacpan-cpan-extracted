/*
 * $Id: jspell.h 2636 2006-05-18 14:44:56Z ambs $
 */

/*
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

#ifndef __JSPELL_H__
#define __JSPELL_H__

#include <stdio.h>

#include "jsconfig.h"
#include "jslib.h"

#ifdef __STDC__
#define VOID        void
#else /* __STDC__ */
#define VOID        char
#define const
#endif /* __STDC__ */

#ifdef NO8BIT
#define SET_SIZE        128
#else
#define SET_SIZE        256
#endif

#define MASKSIZE        (MASKBITS / MASKTYPE_WIDTH)

#define MAXWLEN INPUTWORDLEN+MAXAFFIXLEN

/* The following is really testing for MASKSIZE <= 1, but cpp can't do that */
#if MASKBITS <= MASKTYPE_WIDTH
#define SETMASKBIT(mask, bit) ((mask)[0] |= 1 << (bit))
#define CLRMASKBIT(mask, bit) ((mask)[0] &= ~(1 << (bit)))
#define TSTMASKBIT(mask, bit) ((mask)[0] & (1 << (bit)))
#else
#define SETMASKBIT(mask, bit) \
                    ((mask)[(bit) / MASKTYPE_WIDTH] |= \
                      1 << ((bit) & (MASKTYPE_WIDTH - 1)))
#define CLRMASKBIT(mask, bit) \
                    ((mask)[(bit) / MASKTYPE_WIDTH] &= \
                      ~(1 << ((bit) & (MASKTYPE_WIDTH - 1))))
#define TSTMASKBIT(mask, bit) \
                    ((mask)[(bit) / MASKTYPE_WIDTH] & \
                      (1 << ((bit) & (MASKTYPE_WIDTH - 1))))
#endif

#if MASKBITS > 64
#define FULLMASKSET
#endif

#if MASKBITS <= 32

#define BITTOCHAR(bit)   ((bit) + 'A')
#define CHARTOBIT(ch)    ((ch) - 'A')

#define LARGESTFLAG      26        /* 5 are needed for flagfield below */
#define FLAGBASE         26
#else
# if MASKBITS <= 64

#define BITTOCHAR(bit)   ((bit) + 'A')
#define CHARTOBIT(ch)    ((ch) - 'A')

#define LARGESTFLAG      (64 - 6) /* 5 are needed for flagfield below */
#define FLAGBASE         26
# else

#define BITTOCHAR(bit)   (bit)
#define CHARTOBIT(ch)    (ch)

#define LARGESTFLAG      MASKBITS /* flagfield is a separate field */
#define FLAGBASE         0
# endif
#endif

/*
** Data type for internal word storage.  If necessary, we use shorts rather
** than chars so that string characters can be encoded as a single unit.
*/
#if (SET_SIZE + MAXSTRINGCHARS) <= 256

#define ICHAR_IS_CHAR

#endif

#ifdef ICHAR_IS_CHAR
typedef unsigned char   ichar_t;        /* Internal character */
#define icharlen        strlen
#define icharcpy        strcpy
#define icharcmp        strcmp
#define icharncmp       strncmp
#define chartoichar(x)  ((ichar_t) (x))
#else
typedef unsigned short  ichar_t;        /* Internal character */
#define chartoichar(x)  ((ichar_t) (unsigned char) (x))
#endif

/* this should be modified if number of words >= 65535 */
/* era.. unsigned short.. mas como o jslib tem unsigned int :-| */
/* typedef unsigned int ID_TYPE;      --  NEW */  

char *advance_beg(char *buf);
int my_main(int argc, char *argv[], char lib);
void printhelp(register FILE *helpout);
void dofile(char * filename);
void jjflags(char *w );
void copyout(char **cc, int cnt);
void ins_repl_all(char *word, char *st_repl);
void put_saws_off(register ichar_t *s, int dotree);
void tree_saw_off(register ichar_t *word);

struct dent {   /* dictionary entry */
   struct dent *next;
   char *   word;
   char *   jclass;  /*CHANGE NEW*/
   char *   comm;   /* comments*/  /*CHANGE NEW*/
   MASKTYPE mask[MASKSIZE];
#ifdef FULLMASKSET
   char     flags;  /*CHANGE NEW*/
#endif
   char     saw;   /* flag - tells if this entry was already saw */
};

typedef struct hash_info {
   int cantexpand;    /* NZ if an expansion fails */
   struct dent *htab;   /* Aux hash table for personal dict */
   int hsize;         /* Space available in aux hash table */
   int hcount;        /* Number of items in hash table */
} hash_info;

extern hash_info pers,   /* personal dictionary */
    repl;   /* replacement "dic", can't be static */

/*
** Flags in the directory entry.  If FULLMASKSET is undefined, these are
** stored in the highest bits of the last longword of the mask field.  If
** FULLMASKSET is defined, they are stored in the extra "flags" field.
#ifndef NO_CAPITALIZATION_SUPPORT
**
** If a word has only one capitalization form, and that form is not
** FOLLOWCASE, it will have exactly one entry in the dictionary.  The
** legal capitalizations will be indicated by the 2-bit capitalization
** field, as follows:
**
**        ALLCAPS                The word must appear in all capitals.
**        CAPITALIZED        The word must be capitalized (e.g., London).
**                        It will also be accepted in all capitals.
**        ANYCASE                The word may appear in lowercase, capitalized,
**                        or all-capitals.
**
** Regardless of the capitalization flags, the "word" field of the entry
** will point to an all-uppercase copy of the word.  This is to simplify
** the large portion of the code that doesn't care about capitalization.
** Jspell will generate the correct version when needed.
**
** If a word has more than one capitalization, there will be multiple
** entries for it, linked together by the "next" field.  The initial
** entry for such words will be a dummy entry, primarily for use by code
** that ignores capitalization.  The "word" field of this entry will
** again point to an all-uppercase copy of the word.  The "mask" field
** will contain the logical OR of the mask fields of all variants.
** A header entry is indicated by a capitalization type of ALLCAPS,
** with the MOREVARIANTS bit set.
**
** The following entries will define the individual variants.  Each
** entry except the last has the MOREVARIANTS flag set, and each
** contains one of the following capitalization options:
**
**        ALLCAPS                The word must appear in all capitals.
**        CAPITALIZED        The word must be capitalized (e.g., London).
**                        It will also be accepted in all capitals.
**        FOLLOWCASE        The word must be capitalized exactly like the
**                        sample in the entry.  Prefix (suffix) characters
**                        must be rendered in the case of the first (last)
**                        "alphabetic" character.  It will also be accepted
**                        in all capitals.  ("Alphabetic" means "mentioned
**                        in a 'casechars' statement".)
**        ANYCASE                The word may appear in lowercase, capitalized,
**                        or all-capitals.
**
** The "mask" field for the entry contains only the affix flag bits that
** are legal for that capitalization.  The "word" field will be null
** except for FOLLOWCASE entries, where it will point to the
** correctly-capitalized spelling of the root word.
**
** It is worth discussing why the ALLCAPS option is used in
** the header entry.  The header entry accepts an all-capitals
** version of the root plus every affix (this is always legal, since
** words get capitalized in headers and so forth).  Further, all of
** the following variant entries will reject any all-capitals form
** that is illegal due to an affix.
**
** Finally, note that variations in the KEEP flag can cause a multiple-variant
** entry as well.  For example, if the personal dictionary contains "ALPHA",
** (KEEP flag set) and the user adds "alpha" with the KEEP flag clear, a
** multiple-variant entry will be created so that "alpha" will be accepted
** but only "ALPHA" will actually be kept.
#endif
*/
#ifdef FULLMASKSET
#define flagfield       flags
#else
#define flagfield       mask[MASKSIZE - 1]
#endif
#define USED            (1 << (FLAGBASE + 0))
#define KEEP            (1 << (FLAGBASE + 1))
#ifdef NO_CAPITALIZATION_SUPPORT
#define ALLFLAGS        (USED | KEEP)
#else /* NO_CAPITALIZATION_SUPPORT */
#define ANYCASE         (0 << (FLAGBASE + 2))
#define ALLCAPS         (1 << (FLAGBASE + 2))
#define CAPITALIZED     (2 << (FLAGBASE + 2))
#define FOLLOWCASE      (3 << (FLAGBASE + 2))
#define CAPTYPEMASK     (3 << (FLAGBASE + 2))
#define MOREVARIANTS    (1 << (FLAGBASE + 4))
#define ALLFLAGS        (USED | KEEP | CAPTYPEMASK | MOREVARIANTS)
#define captype(x)      ((x) & CAPTYPEMASK)
#endif /* NO_CAPITALIZATION_SUPPORT */

#define DEF_OUT "lex(%s, [%s], [%s], [%s], [%s])"

/*
 * Language tables used to encode prefix and suffix information.
 */
struct genflagent { /*CHANGE*/ /* NEW structure */
   ichar_t * jclass;                  /* Class of flag */
   short     classl;                 /* Length of class */
};

extern struct genflagent gentable[MASKBITS];    /* CHANGE NEW */

struct flagent
{
   ichar_t * strip;                  /* String to strip off */
   ichar_t * affix;                  /* Affix to append */
   ichar_t * jclass;                 /* Class of affix */ /*CHANGE*/
   short     flagbit;                /* Flag bit this ent matches */
   short     stripl;                 /* Length of strip */
   short     affl;                   /* Length of affix */
   short     classl;                 /* Length of class */  /*CHANGE*/
   short     numconds;               /* Number of char conditions */
   short     flagflags;              /* Modifiers on this flag */
   char      conds[SET_SIZE + MAXSTRINGCHARS]; /* Adj. char conds */
};

int creat_root_word(ichar_t *tword, ichar_t *ucword,
                    struct flagent *flent,   /* Current table entry */
                    int tlen);


/*
 * Bits in flagflags
 */
#define FF_CROSSPRODUCT    (1 << 0)   /* Affix does cross-products */
#define FF_REC             (2 << 0)   /* Affix for recursive calls  only */

union ptr_union                       /* Aid for building flg ptrs */
{
   struct flagptr *fp;              /* Pointer to more indexing */
   struct flagent *ent;             /* First of a list of ents */
};

struct flagptr
{
   union ptr_union pu;              /* Ent list or more indexes */
   int             numents;         /* If zero, pu.fp is valid */
};

/*
 * Description of a single string character type.
 */
struct strchartype
{
   char *name;                    /* Name of the type */
   char *deformatter;             /* Deformatter to use */
   char *suffixes;                /* File suffixes, null seps */
};

/*
 * Header placed at the beginning of the hash file.
 */
struct hashheader
{
    unsigned short magic;                       /* Magic number for ID */
    unsigned short compileoptions;              /* How we were compiled */
    short maxstringchars;                       /* Max # strchrs we support */
    short maxstringcharlen;                     /* Max strchr len supported */
    short compoundmin;                          /* Min lth of compound parts */
    int stringsize;                             /* Size of string table (all strings: prefixes, sufixes, typetables, words, classes) */
    unsigned int thashsize;      /*NEW*/        /* Size of hash table (in bytes) */
    long int lstringsize;                       /* Size of lang. str tbl (size of ) */
    int tblsize;                                /* No. entries in hash tbl */
    int stblsize;                               /* No. entries in sfx tbl */
    int ptblsize;                               /* No. entries in pfx tbl */
    int sortval;                                /* Largest sort ID assigned */
    int nstrchars;                              /* No. strchars defined */
    int nstrchartype;                           /* No. strchar types */
    int strtypestart;                           /* Start of strtype table */
    char nrchars[5];                            /* Nroff special characters */
    char texchars[13];                          /* TeX special characters */
    char defspaceflag;                          /* Default missingspace flag */
    char defhardflag;                           /* Default tryveryhard flag */
    char flagmarker;                            /* "Start-of-flags" char */
    unsigned short sortorder[SET_SIZE + MAXSTRINGCHARS]; /* Sort ordering */
    ichar_t lowerconv[SET_SIZE + MAXSTRINGCHARS]; /* Lower-conversion table */
    ichar_t upperconv[SET_SIZE + MAXSTRINGCHARS]; /* Upper-conversion table */
    char wordchars[SET_SIZE + MAXSTRINGCHARS]; /* NZ for chars found in wrds */
    char upperchars[SET_SIZE + MAXSTRINGCHARS]; /* NZ for uppercase chars */
    char lowerchars[SET_SIZE + MAXSTRINGCHARS]; /* NZ for lowercase chars */
    char boundarychars[SET_SIZE + MAXSTRINGCHARS]; /* NZ for boundary chars */
    char stringstarts[SET_SIZE];                /* NZ if char can start str */
    char stringchars[MAXSTRINGCHARS][MAXSTRINGCHARLEN + 1]; /* String chars */
    char stringdups[MAXSTRINGCHARS];            /* No. of "base" char */
    char dupnos[MAXSTRINGCHARS];                /* Dup char ID # */
    unsigned short magic2;                      /* Second magic for dbl chk */
};

/* hash table magic number */
#define MAGIC                  0x9602

/* compile options, put in the hash header for consistency checking */
#ifdef NO8BIT
# define MAGIC8BIT             0x01
#else
# define MAGIC8BIT             0x00
#endif
#ifdef NO_CAPITALIZATION_SUPPORT
# define MAGICCAPITALIZATION   0x00
#else
# define MAGICCAPITALIZATION   0x02
#endif
#if MASKBITS <= 32
# define MAGICMASKSET          0x00
#else
# if MASKBITS <= 64
#  define MAGICMASKSET         0x04
# else
#  if MASKBITS <= 128
#   define MAGICMASKSET        0x08
#  else
#   define MAGICMASKSET        0x0C
#  endif
# endif
#endif

#define COMPILEOPTIONS        (MAGIC8BIT | MAGICCAPITALIZATION | MAGICMASKSET)

/*
 * Structure used to record data about successful lookups; these values
 * are used in the ins_root_cap routine to produce correct capitalizations.
 */
struct success
{
   struct dent *   dictent;         /* Header of dict entry chain for wd */
   struct flagent *prefix;          /* Prefix flag used, or NULL */
   struct flagent *suffix;          /* Suffix flag used, or NULL */
   struct flagent *suffix2;         /* Suffix flag used rec NULL */
};

/*
** Offsets into the nroff special-character array
*/
#define NRLEFTPAREN        hashheader.nrchars[0]
#define NRRIGHTPAREN       hashheader.nrchars[1]
#define NRDOT              hashheader.nrchars[2]
#define NRBACKSLASH        hashheader.nrchars[3]
#define NRSTAR             hashheader.nrchars[4]

/*
** Offsets into the TeX special-character array
*/
#define TEXLEFTPAREN     hashheader.texchars[0]
#define TEXRIGHTPAREN    hashheader.texchars[1]
#define TEXLEFTSQUARE    hashheader.texchars[2]
#define TEXRIGHTSQUARE   hashheader.texchars[3]
#define TEXLEFTCURLY     hashheader.texchars[4]
#define TEXRIGHTCURLY    hashheader.texchars[5]
#define TEXLEFTANGLE     hashheader.texchars[6]
#define TEXRIGHTANGLE    hashheader.texchars[7]
#define TEXBACKSLASH     hashheader.texchars[8]
#define TEXDOLLAR        hashheader.texchars[9]
#define TEXSTAR          hashheader.texchars[10]
#define TEXDOT           hashheader.texchars[11]
#define TEXPERCENT       hashheader.texchars[12]

/*
** The isXXXX macros normally only check ASCII range, and don't support
** the character sets of other languages.  These private versions handle
** whatever character sets have been defined in the affix files.
*/
#define myupper(X)       (hashheader.upperchars[X])
#define mylower(X)       (hashheader.lowerchars[X])
#define myspace(X)       (((X) > 0)  &&  ((X) < 0x80) \
                          &&  isspace((unsigned char) (X)))
#define iswordch(X)      (hashheader.wordchars[X])
#define isboundarych(X)  (hashheader.boundarychars[X])
#define isstringstart(X) (hashheader.stringstarts[(unsigned char) (X)])
#define mytolower(X)     (hashheader.lowerconv[X])
#define mytoupper(X)     (hashheader.upperconv[X])

/*
** These macros are similar to the ones above, but they take into account
** the possibility of string characters.  Note well that they take a POINTER,
** not a character.
**
** The "l_" versions set "len" to the length of the string character as a
** handy side effect.  (Note that the global "laststringch" is also set,
** and sometimes used, by these macros.)
**
** The "l1_" versions go one step further and guarantee that the "len"
** field is valid for *all* characters, being set to 1 even if the macro
** returns false.  This macro is a great example of how NOT to write
** readable C.
*/
#define isstringch(ptr, canon)  (isstringstart (*ptr) \
                                  &&  stringcharlen (ptr, canon) > 0)
#define l_isstringch(ptr, len, canon)        \
                                (isstringstart (*ptr) \
                                  &&  (len = stringcharlen (ptr, canon)) > 0)
#define l1_isstringch(ptr, len, canon)        \
                                  (len = 1, \
                                  isstringstart (*ptr) \
                                    &&  ((len = stringcharlen (ptr, canon)) \
                                        > 0 \
                                      ? 1 : (len = 1, 0)))

/*
 * Sizes of buffers returned by ichartosstr/strtosichar.
 */
#define ICHARTOSSTR_SIZE MAXSOLLEN
#define STRTOSICHAR_SIZE (MAXSOLLEN * sizeof(ichar_t))

#ifdef MAIN
# define EXTERN /* nothing */
#else
# define EXTERN extern
#endif

/* to simulate LIB behaviour on a exec. version we may change islib temporarily */
EXTERN char islib;
EXTERN char signs[80];       /* CHANGE NEW*/
EXTERN int i_word_created;    /* index to sol_out[] of c option */ /* CHANGE NEW*/
EXTERN int     contextsize;       /* number of lines of context to show */
EXTERN char    contextbufs[MAXCONTEXT][BUFSIZ]; /* Context of current line */
EXTERN char *  currentchar;       /* Location in contextbufs */
EXTERN char    ctoken[MAXWLEN];   /* Current token as char */
EXTERN ichar_t itoken[MAXWLEN];   /* Ctoken as ichar_t str */


/*---------------------------------------------------------------------------*/

EXTERN int    numhits;                 /* number of hits in dictionary lookups */
EXTERN struct success hits[MAX_HITS];  /* table of hits gotten in lookup */
/* tgood puts here various possible prefix of a specific word */
EXTERN int    rnumhits;                /* number of hits in dictionary lookups */
EXTERN struct flagent *rhits[MAX_HITS]; /* table of hits gotten in lookup */

EXTERN char *  hashstrings;           /* Strings in hash table */
EXTERN struct hashheader hashheader;  /* Header of hash table */
EXTERN struct dent *     hashtbl;     /* Main hash table, for dictionary */
EXTERN int    hashsize;               /* Size of main hash table */

EXTERN char    hashname[MAXPATHLEN]; /* Name of hash table file */

EXTERN int     aflag;               /* NZ if -a or -A option specified */
EXTERN int     cflag;               /* NZ if -c (crunch) option */
/* EXTERN int     Jflag;     */          /* NZ if -J option specified JJoao */
/* EXTERN int     showflags;   */        /* NZ if -z option */
EXTERN int     lflag;               /* NZ if -l (list) option */
EXTERN int     incfileflag;         /* whether xgets() acts exactly like gets() */
EXTERN int     nodictflag;          /* NZ if dictionary not needed */

EXTERN int     laststringch;        /* Number of last string character */
EXTERN int     defdupchar;          /* Default duplicate string type */

EXTERN int     numpflags;           /* Number of prefix flags in table */
EXTERN int     numsflags;           /* Number of suffix flags in table */
EXTERN struct flagptr pflagindex[SET_SIZE + MAXSTRINGCHARS];
                                     /* Fast index to pflaglist */
EXTERN struct flagent * pflaglist;   /* Prefix flag control list */
EXTERN struct flagptr sflagindex[SET_SIZE + MAXSTRINGCHARS];
                                     /* Fast index to sflaglist */
EXTERN struct flagent * sflaglist;   /* Suffix flag control list */

EXTERN struct strchartype *       /* String character type collection */
               chartypes;

EXTERN FILE *  infile;              /* File being corrected */
EXTERN FILE *  outfile;             /* Corrected copy of infile */

EXTERN char *  askfilename;         /* File specified in -f option */
EXTERN char    o_form[80];          /* Output format */  /*CHANGE*/

EXTERN int     changes;             /* NZ if changes made to cur. file */
EXTERN int     readonly;            /* NZ if current file is readonly */
EXTERN int     quit;                /* NZ if we're done with this file */


EXTERN char   possibilities[MAXPOSSIBLE][MAXWLEN];
EXTERN char sol_out[MAXPOSSIBLE][MAXSOLLEN];     /*CHANGE NEW */
EXTERN char misses_out[MAXPOSSIBLE][MAXSOLLEN];  /*CHANGE NEW */
EXTERN char sol_out2[MAXPOSSIBLE][MAXSOLLEN];    /*CHANGE NEW */
EXTERN char is_in_dic[MAXPOSSIBLE];              /*CHANGE NEW */

struct ssep_sol {  /* CHANGE NEW */
   char root[MAXWLEN];
   char root_class[MAXCLASS];
   char pre_class[MAXCLASS];
   char suf_class[MAXCLASS];
   char suf2_class[MAXCLASS];
   char flag[4];
};

EXTERN struct ssep_sol sep_sol[MAXPOSSIBLE];   /* CHANGE NEW */

struct poss {
   struct success suc;
   char word[INPUTWORDLEN + MAXAFFIXLEN];
};
EXTERN struct poss my_poss[MAXPOSSIBLE];
EXTERN int my_poss_count;
                                    /* Table of possible corrections */
EXTERN int     pcount;              /* Count of possibilities generated */
EXTERN int     maxposslen;          /* Length of longest possibility */
EXTERN int     easypossibilities;   /* Number of "easy" corrections found */
                                /* ..(defined as those using legal affixes) */

/*
 * The following array contains a list of characters that should be tried
 * in "missingletter."  Note that lowercase characters are omitted.
 */
EXTERN int     Trynum;                /* Size of "Try" array */
EXTERN ichar_t Try[SET_SIZE + MAXSTRINGCHARS];

/*
 * Initialized variables.  These are generated using macros so that they
 * may be consistently declared in all programs.  Numerous examples of
 * usage are given below.
 */
#ifdef MAIN
#define INIT(decl, init)       decl = init
#else
#define INIT(decl, init)       extern decl
#endif

#ifdef MINIMENU
INIT (int minimenusize, 2);             /* MUST be either 2 or zero */
#else /* MINIMENU */
INIT (int minimenusize, 0);             /* MUST be either 2 or zero */
#endif /* MINIMENU */

INIT (int eflag, 0);                    /* NZ for expand mode */
INIT (int dumpflag, 0);                 /* NZ to do dump mode */
INIT (int fflag, 0);                    /* NZ if -f specified */
INIT (int vflag, 0);                    /* NZ to display characters as M-xxx */
INIT (int Jflag, 0);                    /* NZ no Gclass by defaut */
INIT (int xflag, DEFNOBACKUPFLAG);      /* NZ to suppress backups */
INIT (int deftflag, DEFTEXFLAG);        /* NZ for TeX mode by default */
INIT (int tflag, DEFTEXFLAG);           /* NZ for TeX mode in current file */
INIT (int oflag, 0);                    /* NZ if -o specified */  /*CHANGE NEW */
INIT (int gflag, 0);                    /* display "good" options only */  /*CHANGE NEW */
INIT (int yflag, 0);                    /* suppress typing erros */  /*CHANGE NEW */
INIT (char signal_is_word, 1);          /* tells if jspell should consider a punctuation sign as a word */
INIT (int prefstringchar, -1);          /* Preferred string character type */

INIT (int terse, 0);                    /* NZ for "terse3" mode */

INIT (char tempfile[MAXPATHLEN], "");   /* Name of file we're spelling into */

INIT (int minword, MINWORD);            /* Longest always-legal word */
INIT (int sortit, 1);                   /* Sort suggestions alphabetically */
INIT (int missingspaceflag, -1);        /* Don't report missing spaces */
INIT (int tryhardflag, -1);             /* Always call tryveryhard */

INIT (char *currentfile, NULL);         /* Name of current input file */
INIT (int  act_rec, -1);
INIT (char saw_mode, 0);
INIT (int showflags, 0);               /* flag z */

/* Odd numbers for math mode in LaTeX; even for LR or paragraph mode */
INIT (int math_mode, 0);
/* P -- paragraph or LR mode
 * b -- parsing a \begin statement
 * e -- parsing an \end statement
 * r -- parsing a \ref type of argument.
 * m -- looking for a \begin{minipage} argument.
 */
INIT (char LaTeX_Mode, 'P');
INIT (int TeX_comment, 0);

/* to the replace all */
extern struct dent *last_found;



void  jcorrect(char *ctok, ichar_t *itok, char **curchar);
int mk_upper(ichar_t *w, ichar_t *nword);
#endif	/* __JSPELL_H__ */
