/* A Bison parser, made by GNU Bison 3.0.4.  */

/* Bison implementation for Yacc-like parsers in C

   Copyright (C) 1984, 1989-1990, 2000-2015 Free Software Foundation, Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

/* C LALR(1) parser skeleton written by Richard Stallman, by
   simplifying the original so-called "semantic" parser.  */

/* All symbols defined below should begin with yy or YY, to avoid
   infringing on user name space.  This should be done even for local
   variables, as they might otherwise be expanded by user macros.
   There are some unavoidable exceptions within include files to
   define necessary library symbols; they are noted "INFRINGES ON
   USER NAME SPACE" below.  */

/* Identify Bison output.  */
#define YYBISON 1

/* Bison version.  */
#define YYBISON_VERSION "3.0.4"

/* Skeleton name.  */
#define YYSKELETON_NAME "yacc.c"

/* Pure parsers.  */
#define YYPURE 0

/* Push parsers.  */
#define YYPUSH 0

/* Pull parsers.  */
#define YYPULL 1




/* Copy the first part of user declarations.  */
#line 1 "src/parse.y" /* yacc.c:339  */


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


#line 83 "src/y.tab.c" /* yacc.c:339  */

# ifndef YY_NULLPTR
#  if defined __cplusplus && 201103L <= __cplusplus
#   define YY_NULLPTR nullptr
#  else
#   define YY_NULLPTR 0
#  endif
# endif

/* Enabling verbose error messages.  */
#ifdef YYERROR_VERBOSE
# undef YYERROR_VERBOSE
# define YYERROR_VERBOSE 1
#else
# define YYERROR_VERBOSE 0
#endif


/* Debug traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif
#if YYDEBUG
extern int yydebug;
#endif

/* Token type.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
  enum yytokentype
  {
    ALLAFFIXES = 258,
    ALTSTRINGCHAR = 259,
    ALTSTRINGTYPE = 260,
    BOUNDARYCHARS = 261,
    COMPOUNDMIN = 262,
    COMPOUNDWORDS = 263,
    DEFSTRINGTYPE = 264,
    FLAG = 265,
    FLAGMARKER = 266,
    NROFFCHARS = 267,
    OFF = 268,
    ON = 269,
    PREFIXES = 270,
    RANGE = 271,
    SUFFIXES = 272,
    STRING = 273,
    STRINGCHAR = 274,
    TEXCHARS = 275,
    WORDCHARS = 276
  };
#endif
/* Tokens.  */
#define ALLAFFIXES 258
#define ALTSTRINGCHAR 259
#define ALTSTRINGTYPE 260
#define BOUNDARYCHARS 261
#define COMPOUNDMIN 262
#define COMPOUNDWORDS 263
#define DEFSTRINGTYPE 264
#define FLAG 265
#define FLAGMARKER 266
#define NROFFCHARS 267
#define OFF 268
#define ON 269
#define PREFIXES 270
#define RANGE 271
#define SUFFIXES 272
#define STRING 273
#define STRINGCHAR 274
#define TEXCHARS 275
#define WORDCHARS 276

/* Value type.  */
#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED

union YYSTYPE
{
#line 19 "src/parse.y" /* yacc.c:355  */

   int simple;                /* Simple char or lval from yylex */
   struct {
      char *set;             /* Character set */
      int complement;        /* NZ if it is a complement set: [^...] */
   } charset;
   unsigned char * string;              /* String */
   ichar_t *       istr;                /* Internal string */
   struct flagent *entry;               /* Flag entry */

#line 173 "src/y.tab.c" /* yacc.c:355  */
};

typedef union YYSTYPE YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define YYSTYPE_IS_DECLARED 1
#endif


extern YYSTYPE yylval;

int yyparse (void);



/* Copy the second part of user declarations.  */
#line 30 "src/parse.y" /* yacc.c:358  */


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

   if (cond->numconds == 0 && cond->stripl < 8) {
     int mask;
     bzero(cond->conds, SET_SIZE + MAXSTRINGCHARS);
     
     for (int pos = 0; pos < cond->stripl; ++pos) {
       mask = 1 << cond->numconds;
       cond->numconds++;

       cond->conds[cond->strip[pos]] |= mask;
       cond->conds[mytoupper((ichar_t) cond->strip[pos])] |= mask;
     }
   }
   
}


#line 316 "src/y.tab.c" /* yacc.c:358  */

#ifdef short
# undef short
#endif

#ifdef YYTYPE_UINT8
typedef YYTYPE_UINT8 yytype_uint8;
#else
typedef unsigned char yytype_uint8;
#endif

#ifdef YYTYPE_INT8
typedef YYTYPE_INT8 yytype_int8;
#else
typedef signed char yytype_int8;
#endif

#ifdef YYTYPE_UINT16
typedef YYTYPE_UINT16 yytype_uint16;
#else
typedef unsigned short int yytype_uint16;
#endif

#ifdef YYTYPE_INT16
typedef YYTYPE_INT16 yytype_int16;
#else
typedef short int yytype_int16;
#endif

#ifndef YYSIZE_T
# ifdef __SIZE_TYPE__
#  define YYSIZE_T __SIZE_TYPE__
# elif defined size_t
#  define YYSIZE_T size_t
# elif ! defined YYSIZE_T
#  include <stddef.h> /* INFRINGES ON USER NAME SPACE */
#  define YYSIZE_T size_t
# else
#  define YYSIZE_T unsigned int
# endif
#endif

#define YYSIZE_MAXIMUM ((YYSIZE_T) -1)

#ifndef YY_
# if defined YYENABLE_NLS && YYENABLE_NLS
#  if ENABLE_NLS
#   include <libintl.h> /* INFRINGES ON USER NAME SPACE */
#   define YY_(Msgid) dgettext ("bison-runtime", Msgid)
#  endif
# endif
# ifndef YY_
#  define YY_(Msgid) Msgid
# endif
#endif

#ifndef YY_ATTRIBUTE
# if (defined __GNUC__                                               \
      && (2 < __GNUC__ || (__GNUC__ == 2 && 96 <= __GNUC_MINOR__)))  \
     || defined __SUNPRO_C && 0x5110 <= __SUNPRO_C
#  define YY_ATTRIBUTE(Spec) __attribute__(Spec)
# else
#  define YY_ATTRIBUTE(Spec) /* empty */
# endif
#endif

#ifndef YY_ATTRIBUTE_PURE
# define YY_ATTRIBUTE_PURE   YY_ATTRIBUTE ((__pure__))
#endif

#ifndef YY_ATTRIBUTE_UNUSED
# define YY_ATTRIBUTE_UNUSED YY_ATTRIBUTE ((__unused__))
#endif

#if !defined _Noreturn \
     && (!defined __STDC_VERSION__ || __STDC_VERSION__ < 201112)
# if defined _MSC_VER && 1200 <= _MSC_VER
#  define _Noreturn __declspec (noreturn)
# else
#  define _Noreturn YY_ATTRIBUTE ((__noreturn__))
# endif
#endif

/* Suppress unused-variable warnings by "using" E.  */
#if ! defined lint || defined __GNUC__
# define YYUSE(E) ((void) (E))
#else
# define YYUSE(E) /* empty */
#endif

#if defined __GNUC__ && 407 <= __GNUC__ * 100 + __GNUC_MINOR__
/* Suppress an incorrect diagnostic about yylval being uninitialized.  */
# define YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN \
    _Pragma ("GCC diagnostic push") \
    _Pragma ("GCC diagnostic ignored \"-Wuninitialized\"")\
    _Pragma ("GCC diagnostic ignored \"-Wmaybe-uninitialized\"")
# define YY_IGNORE_MAYBE_UNINITIALIZED_END \
    _Pragma ("GCC diagnostic pop")
#else
# define YY_INITIAL_VALUE(Value) Value
#endif
#ifndef YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
# define YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
# define YY_IGNORE_MAYBE_UNINITIALIZED_END
#endif
#ifndef YY_INITIAL_VALUE
# define YY_INITIAL_VALUE(Value) /* Nothing. */
#endif


#if ! defined yyoverflow || YYERROR_VERBOSE

/* The parser invokes alloca or malloc; define the necessary symbols.  */

# ifdef YYSTACK_USE_ALLOCA
#  if YYSTACK_USE_ALLOCA
#   ifdef __GNUC__
#    define YYSTACK_ALLOC __builtin_alloca
#   elif defined __BUILTIN_VA_ARG_INCR
#    include <alloca.h> /* INFRINGES ON USER NAME SPACE */
#   elif defined _AIX
#    define YYSTACK_ALLOC __alloca
#   elif defined _MSC_VER
#    include <malloc.h> /* INFRINGES ON USER NAME SPACE */
#    define alloca _alloca
#   else
#    define YYSTACK_ALLOC alloca
#    if ! defined _ALLOCA_H && ! defined EXIT_SUCCESS
#     include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
      /* Use EXIT_SUCCESS as a witness for stdlib.h.  */
#     ifndef EXIT_SUCCESS
#      define EXIT_SUCCESS 0
#     endif
#    endif
#   endif
#  endif
# endif

# ifdef YYSTACK_ALLOC
   /* Pacify GCC's 'empty if-body' warning.  */
#  define YYSTACK_FREE(Ptr) do { /* empty */; } while (0)
#  ifndef YYSTACK_ALLOC_MAXIMUM
    /* The OS might guarantee only one guard page at the bottom of the stack,
       and a page size can be as small as 4096 bytes.  So we cannot safely
       invoke alloca (N) if N exceeds 4096.  Use a slightly smaller number
       to allow for a few compiler-allocated temporary stack slots.  */
#   define YYSTACK_ALLOC_MAXIMUM 4032 /* reasonable circa 2006 */
#  endif
# else
#  define YYSTACK_ALLOC YYMALLOC
#  define YYSTACK_FREE YYFREE
#  ifndef YYSTACK_ALLOC_MAXIMUM
#   define YYSTACK_ALLOC_MAXIMUM YYSIZE_MAXIMUM
#  endif
#  if (defined __cplusplus && ! defined EXIT_SUCCESS \
       && ! ((defined YYMALLOC || defined malloc) \
             && (defined YYFREE || defined free)))
#   include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
#   ifndef EXIT_SUCCESS
#    define EXIT_SUCCESS 0
#   endif
#  endif
#  ifndef YYMALLOC
#   define YYMALLOC malloc
#   if ! defined malloc && ! defined EXIT_SUCCESS
void *malloc (YYSIZE_T); /* INFRINGES ON USER NAME SPACE */
#   endif
#  endif
#  ifndef YYFREE
#   define YYFREE free
#   if ! defined free && ! defined EXIT_SUCCESS
void free (void *); /* INFRINGES ON USER NAME SPACE */
#   endif
#  endif
# endif
#endif /* ! defined yyoverflow || YYERROR_VERBOSE */


#if (! defined yyoverflow \
     && (! defined __cplusplus \
         || (defined YYSTYPE_IS_TRIVIAL && YYSTYPE_IS_TRIVIAL)))

/* A type that is properly aligned for any stack member.  */
union yyalloc
{
  yytype_int16 yyss_alloc;
  YYSTYPE yyvs_alloc;
};

/* The size of the maximum gap between one aligned stack and the next.  */
# define YYSTACK_GAP_MAXIMUM (sizeof (union yyalloc) - 1)

/* The size of an array large to enough to hold all stacks, each with
   N elements.  */
# define YYSTACK_BYTES(N) \
     ((N) * (sizeof (yytype_int16) + sizeof (YYSTYPE)) \
      + YYSTACK_GAP_MAXIMUM)

# define YYCOPY_NEEDED 1

/* Relocate STACK from its old location to the new one.  The
   local variables YYSIZE and YYSTACKSIZE give the old and new number of
   elements in the stack, and YYPTR gives the new location of the
   stack.  Advance YYPTR to a properly aligned location for the next
   stack.  */
# define YYSTACK_RELOCATE(Stack_alloc, Stack)                           \
    do                                                                  \
      {                                                                 \
        YYSIZE_T yynewbytes;                                            \
        YYCOPY (&yyptr->Stack_alloc, Stack, yysize);                    \
        Stack = &yyptr->Stack_alloc;                                    \
        yynewbytes = yystacksize * sizeof (*Stack) + YYSTACK_GAP_MAXIMUM; \
        yyptr += yynewbytes / sizeof (*yyptr);                          \
      }                                                                 \
    while (0)

#endif

#if defined YYCOPY_NEEDED && YYCOPY_NEEDED
/* Copy COUNT objects from SRC to DST.  The source and destination do
   not overlap.  */
# ifndef YYCOPY
#  if defined __GNUC__ && 1 < __GNUC__
#   define YYCOPY(Dst, Src, Count) \
      __builtin_memcpy (Dst, Src, (Count) * sizeof (*(Src)))
#  else
#   define YYCOPY(Dst, Src, Count)              \
      do                                        \
        {                                       \
          YYSIZE_T yyi;                         \
          for (yyi = 0; yyi < (Count); yyi++)   \
            (Dst)[yyi] = (Src)[yyi];            \
        }                                       \
      while (0)
#  endif
# endif
#endif /* !YYCOPY_NEEDED */

/* YYFINAL -- State number of the termination state.  */
#define YYFINAL  44
/* YYLAST -- Last index in YYTABLE.  */
#define YYLAST   119

/* YYNTOKENS -- Number of terminals.  */
#define YYNTOKENS  30
/* YYNNTS -- Number of nonterminals.  */
#define YYNNTS  28
/* YYNRULES -- Number of rules.  */
#define YYNRULES  65
/* YYNSTATES -- Number of states.  */
#define YYNSTATES  106

/* YYTRANSLATE[YYX] -- Symbol number corresponding to YYX as returned
   by yylex, with out-of-bounds checking.  */
#define YYUNDEFTOK  2
#define YYMAXUTOK   276

#define YYTRANSLATE(YYX)                                                \
  ((unsigned int) (YYX) <= YYMAXUTOK ? yytranslate[YYX] : YYUNDEFTOK)

/* YYTRANSLATE[TOKEN-NUM] -- Symbol number corresponding to TOKEN-NUM
   as returned by yylex, without out-of-bounds checking.  */
static const yytype_uint8 yytranslate[] =
{
       0,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     8,     9,     5,     3,     7,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     6,    10,
       2,     2,     4,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     1,     2,    11,    12,
      13,    14,    15,    16,    17,    18,    19,    20,    21,    22,
      23,    24,    25,    26,    27,    28,    29
};

#if YYDEBUG
  /* YYRLINE[YYN] -- Source line where rule number YYN was defined.  */
static const yytype_uint16 yyrline[] =
{
       0,   214,   214,   215,   218,   219,   220,   221,   224,   225,
     228,   229,   230,   233,   236,   237,   240,   289,   307,   355,
     374,   389,   424,   425,   428,   452,   480,   507,   511,   512,
     515,   550,   559,   568,   580,   584,   588,   598,   613,   636,
     639,   643,   649,   650,   651,   652,   655,   674,   691,   717,
     737,   739,   741,   743,   747,   763,   781,   785,   789,   796,
     808,   811,   843,   872,   889,   893
};
#endif

#if YYDEBUG || YYERROR_VERBOSE || 0
/* YYTNAME[SYMBOL-NUM] -- String name of the symbol SYMBOL-NUM.
   First, the terminals, then, starting at YYNTOKENS, nonterminals.  */
static const char *const yytname[] =
{
  "$end", "error", "$undefined", "'-'", "'>'", "','", "':'", "'.'", "'*'",
  "'+'", "';'", "ALLAFFIXES", "ALTSTRINGCHAR", "ALTSTRINGTYPE",
  "BOUNDARYCHARS", "COMPOUNDMIN", "COMPOUNDWORDS", "DEFSTRINGTYPE", "FLAG",
  "FLAGMARKER", "NROFFCHARS", "OFF", "ON", "PREFIXES", "RANGE", "SUFFIXES",
  "STRING", "STRINGCHAR", "TEXCHARS", "WORDCHARS", "$accept", "file",
  "headers", "option_group", "charset_group", "deftype_stmt",
  "altchar_group", "charset_stmt", "altchar_stmt", "stringtype_info",
  "filesuf_list", "filesuf", "altchar_spec_group", "altchar_spec",
  "option_stmt", "char_set", "on_or_off", "tables", "prefix_table",
  "suffix_table", "table", "flagdef", "rules", "affix_rule",
  "cond_or_null", "conditions", "ichar_string", "classif", YY_NULLPTR
};
#endif

# ifdef YYPRINT
/* YYTOKNUM[NUM] -- (External) token number corresponding to the
   (internal) symbol number NUM (which must be that of a token).  */
static const yytype_uint16 yytoknum[] =
{
       0,   256,   257,    45,    62,    44,    58,    46,    42,    43,
      59,   258,   259,   260,   261,   262,   263,   264,   265,   266,
     267,   268,   269,   270,   271,   272,   273,   274,   275,   276
};
# endif

#define YYPACT_NINF -86

#define yypact_value_is_default(Yystate) \
  (!!((Yystate) == (-86)))

#define YYTABLE_NINF -60

#define yytable_value_is_error(Yytable_value) \
  0

  /* YYPACT[STATE-NUM] -- Index in YYTABLE of the portion describing
     STATE-NUM.  */
static const yytype_int8 yypact[] =
{
      31,    -3,    14,   -19,    -3,    18,    23,    36,    54,    54,
      37,    42,    14,    34,    -1,    50,    61,    57,   -86,   -86,
     -86,    48,    66,   -86,   -86,   -86,   -86,   -86,   -86,    14,
     -86,   -86,    65,   -86,   -86,   -86,   -86,     6,     8,   -86,
       5,    67,   -86,    14,   -86,   -86,    61,   -86,    18,    79,
     -86,   -86,   -86,   -86,   -86,   -86,    68,    69,    70,    74,
     -86,   -86,   -86,    79,    85,   -86,   -86,    68,   -86,    92,
      93,    90,    75,    85,   -86,   -86,    90,    90,    76,    14,
      77,   -86,    14,    14,   -86,   -86,    13,   -86,   100,    14,
     -86,    13,    13,   -86,     9,   -86,    80,   -86,    90,   102,
     -86,    10,    90,    90,   -86,   -86
};

  /* YYDEFACT[STATE-NUM] -- Default reduction number in state STATE-NUM.
     Performed when YYTABLE does not specify something else to do.  Zero
     means the default is an error.  */
static const yytype_uint8 yydefact[] =
{
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     6,     0,    11,     8,
       3,    44,    45,    41,    40,    35,    37,    39,    38,    19,
      33,    34,     0,    13,    36,    31,    53,     0,     0,    48,
       0,    20,    32,    17,     1,     2,     4,     9,     0,     7,
      12,    14,    10,    42,    43,    18,     0,     0,     0,     0,
      49,    21,    16,     5,    22,    15,    27,    24,    25,     0,
       0,    64,     0,    23,    28,    26,    64,    64,     0,    59,
       0,    29,    59,    59,    65,    61,    50,    54,     0,    60,
      30,    51,    52,    55,     0,    62,     0,    63,    64,     0,
      56,     0,    64,    64,    58,    57
};

  /* YYPGOTO[NTERM-NUM].  */
static const yytype_int8 yypgoto[] =
{
     -86,   -86,   -86,   -86,    94,   -86,    59,   -15,    -6,    60,
     -86,    43,   -86,    38,    97,    -2,   109,   101,    95,    98,
     105,    45,   -30,   -10,   -86,   -86,   -85,   -73
};

  /* YYDEFGOTO[NTERM-NUM].  */
static const yytype_int8 yydefgoto[] =
{
      -1,    13,    14,    15,    16,    17,    49,    18,    51,    33,
      67,    68,    73,    74,    19,    85,    25,    20,    21,    22,
      38,    39,    86,    87,    88,    89,    98,    79
};

  /* YYTABLE[YYPACT[STATE-NUM]] -- What to do in state STATE-NUM.  If
     positive, shift that token.  If negative, reduce the rule whose
     number is the opposite.  If YYTABLE_NINF, syntax error.  */
static const yytype_int8 yytable[] =
{
      29,    50,    52,    82,    83,   -47,    36,    30,   -46,    36,
      43,    99,    96,   102,    57,    58,   103,   -59,    23,    24,
      26,    26,     8,    37,     9,   100,    37,    55,   -47,   104,
     105,    50,    59,   -46,    44,    97,    97,    27,    27,    28,
      28,    62,     1,    65,    32,     2,     3,     4,     5,    34,
       6,     7,    91,    92,     8,    36,     9,    65,    10,    11,
      12,     1,    35,    41,     2,     3,     4,     5,    42,     6,
       7,     2,    37,     9,    48,     2,    93,    10,    11,    12,
      71,    93,    93,    60,    10,    60,    12,    95,    10,     8,
      12,    56,    48,    61,    66,    69,    70,    72,    76,    77,
      78,    80,    84,    90,    94,    63,    97,   101,    64,    46,
      75,    81,    47,    31,    40,    45,     0,    54,     0,    53
};

static const yytype_int8 yycheck[] =
{
       2,    16,    17,    76,    77,     0,     1,    26,     0,     1,
      12,    96,     3,     3,     8,     9,   101,     4,    21,    22,
       7,     7,    23,    18,    25,    98,    18,    29,    23,   102,
     103,    46,    26,    25,     0,    26,    26,    24,    24,    26,
      26,    43,    11,    49,    26,    14,    15,    16,    17,    26,
      19,    20,    82,    83,    23,     1,    25,    63,    27,    28,
      29,    11,    26,    26,    14,    15,    16,    17,    26,    19,
      20,    14,    18,    25,    13,    14,    86,    27,    28,    29,
       6,    91,    92,    38,    27,    40,    29,    89,    27,    23,
      29,    26,    13,    26,    26,    26,    26,    12,     6,     6,
      10,    26,    26,    26,     4,    46,    26,     5,    48,    15,
      67,    73,    15,     4,     9,    14,    -1,    22,    -1,    21
};

  /* YYSTOS[STATE-NUM] -- The (internal number of the) accessing
     symbol of state STATE-NUM.  */
static const yytype_uint8 yystos[] =
{
       0,    11,    14,    15,    16,    17,    19,    20,    23,    25,
      27,    28,    29,    31,    32,    33,    34,    35,    37,    44,
      47,    48,    49,    21,    22,    46,     7,    24,    26,    45,
      26,    46,    26,    39,    26,    26,     1,    18,    50,    51,
      50,    26,    26,    45,     0,    47,    34,    44,    13,    36,
      37,    38,    37,    49,    48,    45,    26,     8,     9,    26,
      51,    26,    45,    36,    39,    38,    26,    40,    41,    26,
      26,     6,    12,    42,    43,    41,     6,     6,    10,    57,
      26,    43,    57,    57,    26,    45,    52,    53,    54,    55,
      26,    52,    52,    53,     4,    45,     3,    26,    56,    56,
      57,     5,     3,    56,    57,    57
};

  /* YYR1[YYN] -- Symbol number of symbol that rule YYN derives.  */
static const yytype_uint8 yyr1[] =
{
       0,    30,    31,    31,    32,    32,    32,    32,    33,    33,
      34,    34,    34,    35,    36,    36,    37,    37,    37,    37,
      37,    37,    38,    38,    39,    40,    40,    41,    42,    42,
      43,    44,    44,    44,    44,    44,    44,    45,    45,    45,
      46,    46,    47,    47,    47,    47,    48,    49,    50,    50,
      51,    51,    51,    51,    52,    52,    53,    53,    53,    54,
      54,    55,    55,    56,    57,    57
};

  /* YYR2[YYN] -- Number of symbols on the right hand side of rule YYN.  */
static const yytype_uint8 yyr2[] =
{
       0,     2,     2,     1,     2,     3,     1,     2,     1,     2,
       2,     1,     2,     2,     1,     2,     3,     2,     3,     2,
       2,     3,     2,     3,     3,     1,     2,     1,     1,     2,
       3,     2,     2,     2,     2,     2,     2,     1,     1,     1,
       1,     1,     2,     2,     1,     1,     2,     2,     1,     2,
       5,     6,     6,     1,     1,     2,     4,     7,     7,     0,
       1,     1,     2,     1,     0,     2
};


#define yyerrok         (yyerrstatus = 0)
#define yyclearin       (yychar = YYEMPTY)
#define YYEMPTY         (-2)
#define YYEOF           0

#define YYACCEPT        goto yyacceptlab
#define YYABORT         goto yyabortlab
#define YYERROR         goto yyerrorlab


#define YYRECOVERING()  (!!yyerrstatus)

#define YYBACKUP(Token, Value)                                  \
do                                                              \
  if (yychar == YYEMPTY)                                        \
    {                                                           \
      yychar = (Token);                                         \
      yylval = (Value);                                         \
      YYPOPSTACK (yylen);                                       \
      yystate = *yyssp;                                         \
      goto yybackup;                                            \
    }                                                           \
  else                                                          \
    {                                                           \
      yyerror (YY_("syntax error: cannot back up")); \
      YYERROR;                                                  \
    }                                                           \
while (0)

/* Error token number */
#define YYTERROR        1
#define YYERRCODE       256



/* Enable debugging if requested.  */
#if YYDEBUG

# ifndef YYFPRINTF
#  include <stdio.h> /* INFRINGES ON USER NAME SPACE */
#  define YYFPRINTF fprintf
# endif

# define YYDPRINTF(Args)                        \
do {                                            \
  if (yydebug)                                  \
    YYFPRINTF Args;                             \
} while (0)

/* This macro is provided for backward compatibility. */
#ifndef YY_LOCATION_PRINT
# define YY_LOCATION_PRINT(File, Loc) ((void) 0)
#endif


# define YY_SYMBOL_PRINT(Title, Type, Value, Location)                    \
do {                                                                      \
  if (yydebug)                                                            \
    {                                                                     \
      YYFPRINTF (stderr, "%s ", Title);                                   \
      yy_symbol_print (stderr,                                            \
                  Type, Value); \
      YYFPRINTF (stderr, "\n");                                           \
    }                                                                     \
} while (0)


/*----------------------------------------.
| Print this symbol's value on YYOUTPUT.  |
`----------------------------------------*/

static void
yy_symbol_value_print (FILE *yyoutput, int yytype, YYSTYPE const * const yyvaluep)
{
  FILE *yyo = yyoutput;
  YYUSE (yyo);
  if (!yyvaluep)
    return;
# ifdef YYPRINT
  if (yytype < YYNTOKENS)
    YYPRINT (yyoutput, yytoknum[yytype], *yyvaluep);
# endif
  YYUSE (yytype);
}


/*--------------------------------.
| Print this symbol on YYOUTPUT.  |
`--------------------------------*/

static void
yy_symbol_print (FILE *yyoutput, int yytype, YYSTYPE const * const yyvaluep)
{
  YYFPRINTF (yyoutput, "%s %s (",
             yytype < YYNTOKENS ? "token" : "nterm", yytname[yytype]);

  yy_symbol_value_print (yyoutput, yytype, yyvaluep);
  YYFPRINTF (yyoutput, ")");
}

/*------------------------------------------------------------------.
| yy_stack_print -- Print the state stack from its BOTTOM up to its |
| TOP (included).                                                   |
`------------------------------------------------------------------*/

static void
yy_stack_print (yytype_int16 *yybottom, yytype_int16 *yytop)
{
  YYFPRINTF (stderr, "Stack now");
  for (; yybottom <= yytop; yybottom++)
    {
      int yybot = *yybottom;
      YYFPRINTF (stderr, " %d", yybot);
    }
  YYFPRINTF (stderr, "\n");
}

# define YY_STACK_PRINT(Bottom, Top)                            \
do {                                                            \
  if (yydebug)                                                  \
    yy_stack_print ((Bottom), (Top));                           \
} while (0)


/*------------------------------------------------.
| Report that the YYRULE is going to be reduced.  |
`------------------------------------------------*/

static void
yy_reduce_print (yytype_int16 *yyssp, YYSTYPE *yyvsp, int yyrule)
{
  unsigned long int yylno = yyrline[yyrule];
  int yynrhs = yyr2[yyrule];
  int yyi;
  YYFPRINTF (stderr, "Reducing stack by rule %d (line %lu):\n",
             yyrule - 1, yylno);
  /* The symbols being reduced.  */
  for (yyi = 0; yyi < yynrhs; yyi++)
    {
      YYFPRINTF (stderr, "   $%d = ", yyi + 1);
      yy_symbol_print (stderr,
                       yystos[yyssp[yyi + 1 - yynrhs]],
                       &(yyvsp[(yyi + 1) - (yynrhs)])
                                              );
      YYFPRINTF (stderr, "\n");
    }
}

# define YY_REDUCE_PRINT(Rule)          \
do {                                    \
  if (yydebug)                          \
    yy_reduce_print (yyssp, yyvsp, Rule); \
} while (0)

/* Nonzero means print parse trace.  It is left uninitialized so that
   multiple parsers can coexist.  */
int yydebug;
#else /* !YYDEBUG */
# define YYDPRINTF(Args)
# define YY_SYMBOL_PRINT(Title, Type, Value, Location)
# define YY_STACK_PRINT(Bottom, Top)
# define YY_REDUCE_PRINT(Rule)
#endif /* !YYDEBUG */


/* YYINITDEPTH -- initial size of the parser's stacks.  */
#ifndef YYINITDEPTH
# define YYINITDEPTH 200
#endif

/* YYMAXDEPTH -- maximum size the stacks can grow to (effective only
   if the built-in stack extension method is used).

   Do not make this value too large; the results are undefined if
   YYSTACK_ALLOC_MAXIMUM < YYSTACK_BYTES (YYMAXDEPTH)
   evaluated with infinite-precision integer arithmetic.  */

#ifndef YYMAXDEPTH
# define YYMAXDEPTH 10000
#endif


#if YYERROR_VERBOSE

# ifndef yystrlen
#  if defined __GLIBC__ && defined _STRING_H
#   define yystrlen strlen
#  else
/* Return the length of YYSTR.  */
static YYSIZE_T
yystrlen (const char *yystr)
{
  YYSIZE_T yylen;
  for (yylen = 0; yystr[yylen]; yylen++)
    continue;
  return yylen;
}
#  endif
# endif

# ifndef yystpcpy
#  if defined __GLIBC__ && defined _STRING_H && defined _GNU_SOURCE
#   define yystpcpy stpcpy
#  else
/* Copy YYSRC to YYDEST, returning the address of the terminating '\0' in
   YYDEST.  */
static char *
yystpcpy (char *yydest, const char *yysrc)
{
  char *yyd = yydest;
  const char *yys = yysrc;

  while ((*yyd++ = *yys++) != '\0')
    continue;

  return yyd - 1;
}
#  endif
# endif

# ifndef yytnamerr
/* Copy to YYRES the contents of YYSTR after stripping away unnecessary
   quotes and backslashes, so that it's suitable for yyerror.  The
   heuristic is that double-quoting is unnecessary unless the string
   contains an apostrophe, a comma, or backslash (other than
   backslash-backslash).  YYSTR is taken from yytname.  If YYRES is
   null, do not copy; instead, return the length of what the result
   would have been.  */
static YYSIZE_T
yytnamerr (char *yyres, const char *yystr)
{
  if (*yystr == '"')
    {
      YYSIZE_T yyn = 0;
      char const *yyp = yystr;

      for (;;)
        switch (*++yyp)
          {
          case '\'':
          case ',':
            goto do_not_strip_quotes;

          case '\\':
            if (*++yyp != '\\')
              goto do_not_strip_quotes;
            /* Fall through.  */
          default:
            if (yyres)
              yyres[yyn] = *yyp;
            yyn++;
            break;

          case '"':
            if (yyres)
              yyres[yyn] = '\0';
            return yyn;
          }
    do_not_strip_quotes: ;
    }

  if (! yyres)
    return yystrlen (yystr);

  return yystpcpy (yyres, yystr) - yyres;
}
# endif

/* Copy into *YYMSG, which is of size *YYMSG_ALLOC, an error message
   about the unexpected token YYTOKEN for the state stack whose top is
   YYSSP.

   Return 0 if *YYMSG was successfully written.  Return 1 if *YYMSG is
   not large enough to hold the message.  In that case, also set
   *YYMSG_ALLOC to the required number of bytes.  Return 2 if the
   required number of bytes is too large to store.  */
static int
yysyntax_error (YYSIZE_T *yymsg_alloc, char **yymsg,
                yytype_int16 *yyssp, int yytoken)
{
  YYSIZE_T yysize0 = yytnamerr (YY_NULLPTR, yytname[yytoken]);
  YYSIZE_T yysize = yysize0;
  enum { YYERROR_VERBOSE_ARGS_MAXIMUM = 5 };
  /* Internationalized format string. */
  const char *yyformat = YY_NULLPTR;
  /* Arguments of yyformat. */
  char const *yyarg[YYERROR_VERBOSE_ARGS_MAXIMUM];
  /* Number of reported tokens (one for the "unexpected", one per
     "expected"). */
  int yycount = 0;

  /* There are many possibilities here to consider:
     - If this state is a consistent state with a default action, then
       the only way this function was invoked is if the default action
       is an error action.  In that case, don't check for expected
       tokens because there are none.
     - The only way there can be no lookahead present (in yychar) is if
       this state is a consistent state with a default action.  Thus,
       detecting the absence of a lookahead is sufficient to determine
       that there is no unexpected or expected token to report.  In that
       case, just report a simple "syntax error".
     - Don't assume there isn't a lookahead just because this state is a
       consistent state with a default action.  There might have been a
       previous inconsistent state, consistent state with a non-default
       action, or user semantic action that manipulated yychar.
     - Of course, the expected token list depends on states to have
       correct lookahead information, and it depends on the parser not
       to perform extra reductions after fetching a lookahead from the
       scanner and before detecting a syntax error.  Thus, state merging
       (from LALR or IELR) and default reductions corrupt the expected
       token list.  However, the list is correct for canonical LR with
       one exception: it will still contain any token that will not be
       accepted due to an error action in a later state.
  */
  if (yytoken != YYEMPTY)
    {
      int yyn = yypact[*yyssp];
      yyarg[yycount++] = yytname[yytoken];
      if (!yypact_value_is_default (yyn))
        {
          /* Start YYX at -YYN if negative to avoid negative indexes in
             YYCHECK.  In other words, skip the first -YYN actions for
             this state because they are default actions.  */
          int yyxbegin = yyn < 0 ? -yyn : 0;
          /* Stay within bounds of both yycheck and yytname.  */
          int yychecklim = YYLAST - yyn + 1;
          int yyxend = yychecklim < YYNTOKENS ? yychecklim : YYNTOKENS;
          int yyx;

          for (yyx = yyxbegin; yyx < yyxend; ++yyx)
            if (yycheck[yyx + yyn] == yyx && yyx != YYTERROR
                && !yytable_value_is_error (yytable[yyx + yyn]))
              {
                if (yycount == YYERROR_VERBOSE_ARGS_MAXIMUM)
                  {
                    yycount = 1;
                    yysize = yysize0;
                    break;
                  }
                yyarg[yycount++] = yytname[yyx];
                {
                  YYSIZE_T yysize1 = yysize + yytnamerr (YY_NULLPTR, yytname[yyx]);
                  if (! (yysize <= yysize1
                         && yysize1 <= YYSTACK_ALLOC_MAXIMUM))
                    return 2;
                  yysize = yysize1;
                }
              }
        }
    }

  switch (yycount)
    {
# define YYCASE_(N, S)                      \
      case N:                               \
        yyformat = S;                       \
      break
      YYCASE_(0, YY_("syntax error"));
      YYCASE_(1, YY_("syntax error, unexpected %s"));
      YYCASE_(2, YY_("syntax error, unexpected %s, expecting %s"));
      YYCASE_(3, YY_("syntax error, unexpected %s, expecting %s or %s"));
      YYCASE_(4, YY_("syntax error, unexpected %s, expecting %s or %s or %s"));
      YYCASE_(5, YY_("syntax error, unexpected %s, expecting %s or %s or %s or %s"));
# undef YYCASE_
    }

  {
    YYSIZE_T yysize1 = yysize + yystrlen (yyformat);
    if (! (yysize <= yysize1 && yysize1 <= YYSTACK_ALLOC_MAXIMUM))
      return 2;
    yysize = yysize1;
  }

  if (*yymsg_alloc < yysize)
    {
      *yymsg_alloc = 2 * yysize;
      if (! (yysize <= *yymsg_alloc
             && *yymsg_alloc <= YYSTACK_ALLOC_MAXIMUM))
        *yymsg_alloc = YYSTACK_ALLOC_MAXIMUM;
      return 1;
    }

  /* Avoid sprintf, as that infringes on the user's name space.
     Don't have undefined behavior even if the translation
     produced a string with the wrong number of "%s"s.  */
  {
    char *yyp = *yymsg;
    int yyi = 0;
    while ((*yyp = *yyformat) != '\0')
      if (*yyp == '%' && yyformat[1] == 's' && yyi < yycount)
        {
          yyp += yytnamerr (yyp, yyarg[yyi++]);
          yyformat += 2;
        }
      else
        {
          yyp++;
          yyformat++;
        }
  }
  return 0;
}
#endif /* YYERROR_VERBOSE */

/*-----------------------------------------------.
| Release the memory associated to this symbol.  |
`-----------------------------------------------*/

static void
yydestruct (const char *yymsg, int yytype, YYSTYPE *yyvaluep)
{
  YYUSE (yyvaluep);
  if (!yymsg)
    yymsg = "Deleting";
  YY_SYMBOL_PRINT (yymsg, yytype, yyvaluep, yylocationp);

  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  YYUSE (yytype);
  YY_IGNORE_MAYBE_UNINITIALIZED_END
}




/* The lookahead symbol.  */
int yychar;

/* The semantic value of the lookahead symbol.  */
YYSTYPE yylval;
/* Number of syntax errors so far.  */
int yynerrs;


/*----------.
| yyparse.  |
`----------*/

int
yyparse (void)
{
    int yystate;
    /* Number of tokens to shift before error messages enabled.  */
    int yyerrstatus;

    /* The stacks and their tools:
       'yyss': related to states.
       'yyvs': related to semantic values.

       Refer to the stacks through separate pointers, to allow yyoverflow
       to reallocate them elsewhere.  */

    /* The state stack.  */
    yytype_int16 yyssa[YYINITDEPTH];
    yytype_int16 *yyss;
    yytype_int16 *yyssp;

    /* The semantic value stack.  */
    YYSTYPE yyvsa[YYINITDEPTH];
    YYSTYPE *yyvs;
    YYSTYPE *yyvsp;

    YYSIZE_T yystacksize;

  int yyn;
  int yyresult;
  /* Lookahead token as an internal (translated) token number.  */
  int yytoken = 0;
  /* The variables used to return semantic value and location from the
     action routines.  */
  YYSTYPE yyval;

#if YYERROR_VERBOSE
  /* Buffer for error messages, and its allocated size.  */
  char yymsgbuf[128];
  char *yymsg = yymsgbuf;
  YYSIZE_T yymsg_alloc = sizeof yymsgbuf;
#endif

#define YYPOPSTACK(N)   (yyvsp -= (N), yyssp -= (N))

  /* The number of symbols on the RHS of the reduced rule.
     Keep to zero when no symbol should be popped.  */
  int yylen = 0;

  yyssp = yyss = yyssa;
  yyvsp = yyvs = yyvsa;
  yystacksize = YYINITDEPTH;

  YYDPRINTF ((stderr, "Starting parse\n"));

  yystate = 0;
  yyerrstatus = 0;
  yynerrs = 0;
  yychar = YYEMPTY; /* Cause a token to be read.  */
  goto yysetstate;

/*------------------------------------------------------------.
| yynewstate -- Push a new state, which is found in yystate.  |
`------------------------------------------------------------*/
 yynewstate:
  /* In all cases, when you get here, the value and location stacks
     have just been pushed.  So pushing a state here evens the stacks.  */
  yyssp++;

 yysetstate:
  *yyssp = yystate;

  if (yyss + yystacksize - 1 <= yyssp)
    {
      /* Get the current used size of the three stacks, in elements.  */
      YYSIZE_T yysize = yyssp - yyss + 1;

#ifdef yyoverflow
      {
        /* Give user a chance to reallocate the stack.  Use copies of
           these so that the &'s don't force the real ones into
           memory.  */
        YYSTYPE *yyvs1 = yyvs;
        yytype_int16 *yyss1 = yyss;

        /* Each stack pointer address is followed by the size of the
           data in use in that stack, in bytes.  This used to be a
           conditional around just the two extra args, but that might
           be undefined if yyoverflow is a macro.  */
        yyoverflow (YY_("memory exhausted"),
                    &yyss1, yysize * sizeof (*yyssp),
                    &yyvs1, yysize * sizeof (*yyvsp),
                    &yystacksize);

        yyss = yyss1;
        yyvs = yyvs1;
      }
#else /* no yyoverflow */
# ifndef YYSTACK_RELOCATE
      goto yyexhaustedlab;
# else
      /* Extend the stack our own way.  */
      if (YYMAXDEPTH <= yystacksize)
        goto yyexhaustedlab;
      yystacksize *= 2;
      if (YYMAXDEPTH < yystacksize)
        yystacksize = YYMAXDEPTH;

      {
        yytype_int16 *yyss1 = yyss;
        union yyalloc *yyptr =
          (union yyalloc *) YYSTACK_ALLOC (YYSTACK_BYTES (yystacksize));
        if (! yyptr)
          goto yyexhaustedlab;
        YYSTACK_RELOCATE (yyss_alloc, yyss);
        YYSTACK_RELOCATE (yyvs_alloc, yyvs);
#  undef YYSTACK_RELOCATE
        if (yyss1 != yyssa)
          YYSTACK_FREE (yyss1);
      }
# endif
#endif /* no yyoverflow */

      yyssp = yyss + yysize - 1;
      yyvsp = yyvs + yysize - 1;

      YYDPRINTF ((stderr, "Stack size increased to %lu\n",
                  (unsigned long int) yystacksize));

      if (yyss + yystacksize - 1 <= yyssp)
        YYABORT;
    }

  YYDPRINTF ((stderr, "Entering state %d\n", yystate));

  if (yystate == YYFINAL)
    YYACCEPT;

  goto yybackup;

/*-----------.
| yybackup.  |
`-----------*/
yybackup:

  /* Do appropriate processing given the current state.  Read a
     lookahead token if we need one and don't already have one.  */

  /* First try to decide what to do without reference to lookahead token.  */
  yyn = yypact[yystate];
  if (yypact_value_is_default (yyn))
    goto yydefault;

  /* Not known => get a lookahead token if don't already have one.  */

  /* YYCHAR is either YYEMPTY or YYEOF or a valid lookahead symbol.  */
  if (yychar == YYEMPTY)
    {
      YYDPRINTF ((stderr, "Reading a token: "));
      yychar = yylex ();
    }

  if (yychar <= YYEOF)
    {
      yychar = yytoken = YYEOF;
      YYDPRINTF ((stderr, "Now at end of input.\n"));
    }
  else
    {
      yytoken = YYTRANSLATE (yychar);
      YY_SYMBOL_PRINT ("Next token is", yytoken, &yylval, &yylloc);
    }

  /* If the proper action on seeing token YYTOKEN is to reduce or to
     detect an error, take that action.  */
  yyn += yytoken;
  if (yyn < 0 || YYLAST < yyn || yycheck[yyn] != yytoken)
    goto yydefault;
  yyn = yytable[yyn];
  if (yyn <= 0)
    {
      if (yytable_value_is_error (yyn))
        goto yyerrlab;
      yyn = -yyn;
      goto yyreduce;
    }

  /* Count tokens shifted since error; after three, turn off error
     status.  */
  if (yyerrstatus)
    yyerrstatus--;

  /* Shift the lookahead token.  */
  YY_SYMBOL_PRINT ("Shifting", yytoken, &yylval, &yylloc);

  /* Discard the shifted token.  */
  yychar = YYEMPTY;

  yystate = yyn;
  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  *++yyvsp = yylval;
  YY_IGNORE_MAYBE_UNINITIALIZED_END

  goto yynewstate;


/*-----------------------------------------------------------.
| yydefault -- do the default action for the current state.  |
`-----------------------------------------------------------*/
yydefault:
  yyn = yydefact[yystate];
  if (yyn == 0)
    goto yyerrlab;
  goto yyreduce;


/*-----------------------------.
| yyreduce -- Do a reduction.  |
`-----------------------------*/
yyreduce:
  /* yyn is the number of a rule to reduce with.  */
  yylen = yyr2[yyn];

  /* If YYLEN is nonzero, implement the default value of the action:
     '$$ = $1'.

     Otherwise, the following line sets YYVAL to garbage.
     This behavior is undocumented and Bison
     users should not rely upon it.  Assigning to YYVAL
     unconditionally makes the parser a bit smaller, and it avoids a
     GCC warning that YYVAL may be used uninitialized.  */
  yyval = yyvsp[1-yylen];


  YY_REDUCE_PRINT (yyn);
  switch (yyn)
    {
        case 16:
#line 241 "src/parse.y" /* yacc.c:1646  */
    {
                     int nextlower;
                     int nextupper;

                     for (nextlower = SET_SIZE + hashheader.nstrchars;
                             --nextlower > SET_SIZE; ) {
                        if ((yyvsp[-1].charset).set[nextlower] != 0 || (yyvsp[0].charset).set[nextlower] != 0) {
                           yyerror(PARSE_Y_NO_WORD_STRINGS);
                           break;
                        }
                     }
                     for (nextlower = 0; nextlower < SET_SIZE; nextlower++) {
                        hashheader.wordchars[nextlower]
                           |= (yyvsp[-1].charset).set[nextlower] | (yyvsp[0].charset).set[nextlower];
                        hashheader.lowerchars[nextlower]
                           |= (yyvsp[-1].charset).set[nextlower];
                        hashheader.upperchars[nextlower]
                           |= (yyvsp[0].charset).set[nextlower];
                     }
                     for (nextlower = nextupper = 0; nextlower < SET_SIZE;
                          nextlower++) {
                        if ((yyvsp[-1].charset).set[nextlower]) {
                           for (  ; nextupper < SET_SIZE && !(yyvsp[0].charset).set[nextupper];
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
                        if ((yyvsp[0].charset).set[nextupper])
                           yyerror(PARSE_Y_UNMATCHED);
                     }
                     free((yyvsp[-1].charset).set);
                     free((yyvsp[0].charset).set);
                  }
#line 1515 "src/y.tab.c" /* yacc.c:1646  */
    break;

  case 17:
#line 290 "src/parse.y" /* yacc.c:1646  */
    {
                     int i;

                     for (i = SET_SIZE + hashheader.nstrchars;
                          --i > SET_SIZE; ) {
                        if ((yyvsp[0].charset).set[i] != 0) {
                           yyerror(PARSE_Y_NO_WORD_STRINGS);
                           break;
                        }
                     }
                     for (i = 0;  i < SET_SIZE;  i++)
                        if ((yyvsp[0].charset).set[i]) {
                           hashheader.wordchars[i] = 1;
                           hashheader.sortorder[i] = hashheader.sortval++;
                        }
                     free ((yyvsp[0].charset).set);
                  }
#line 1537 "src/y.tab.c" /* yacc.c:1646  */
    break;

  case 18:
#line 308 "src/parse.y" /* yacc.c:1646  */
    {
                     int nextlower;
                     int nextupper;

                     for (nextlower = SET_SIZE + hashheader.nstrchars;
                          --nextlower > SET_SIZE;  ) {
                        if ((yyvsp[-1].charset).set[nextlower] != 0 || (yyvsp[0].charset).set[nextlower] != 0) {
                           yyerror(PARSE_Y_NO_BOUNDARY_STRINGS);
                           break;
                        }
                     }
                     for (nextlower = 0; nextlower < SET_SIZE; nextlower++) {
                        hashheader.boundarychars[nextlower]
                           |= (yyvsp[-1].charset).set[nextlower] | (yyvsp[0].charset).set[nextlower];
                        hashheader.lowerchars[nextlower]
                           |= (yyvsp[-1].charset).set[nextlower];
                        hashheader.upperchars[nextlower]
                           |= (yyvsp[0].charset).set[nextlower];
                     }
                     for (nextlower = nextupper = 0; nextlower < SET_SIZE;
                          nextlower++) {
                        if ((yyvsp[-1].charset).set[nextlower]) {
                           for (  ; nextupper < SET_SIZE && !(yyvsp[0].charset).set[nextupper];
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
                        if ((yyvsp[0].charset).set[nextupper])
                           yyerror(PARSE_Y_UNMATCHED);
                     }
                     free((yyvsp[-1].charset).set);
                     free((yyvsp[0].charset).set);
                  }
#line 1589 "src/y.tab.c" /* yacc.c:1646  */
    break;

  case 19:
#line 356 "src/parse.y" /* yacc.c:1646  */
    {
                     int i;

                     for (i = SET_SIZE + hashheader.nstrchars; --i > SET_SIZE;)
                     {
                        if ((yyvsp[0].charset).set[i] != 0) {
                           yyerror(PARSE_Y_NO_BOUNDARY_STRINGS);
                           break;
                        }
                     }
                     for (i = 0;  i < SET_SIZE;  i++) {
                        if ((yyvsp[0].charset).set[i]) {
                           hashheader.boundarychars[i] = 1;
                           hashheader.sortorder[i] = hashheader.sortval++;
                        }
                     }
                     free((yyvsp[0].charset).set);
                   }
#line 1612 "src/y.tab.c" /* yacc.c:1646  */
    break;

  case 20:
#line 375 "src/parse.y" /* yacc.c:1646  */
    {
                     int len;

                     len = strlen((char *) (yyvsp[0].string));
                     if (len > MAXSTRINGCHARLEN)
                        yyerror(PARSE_Y_LONG_STRING);
                     else if (len == 0)
                        yyerror(PARSE_Y_NULL_STRING);
                     else if (hashheader.nstrchars >= MAXSTRINGCHARS)
                        yyerror(PARSE_Y_MANY_STRINGS);
                     else
                        (void) addstringchar((yyvsp[0].string), 0, 0);
                     free((char *) (yyvsp[0].string));
                     }
#line 1631 "src/y.tab.c" /* yacc.c:1646  */
    break;

  case 21:
#line 390 "src/parse.y" /* yacc.c:1646  */
    {
                     int lcslot;
                     int len;
                     int ucslot;

                     len = strlen((char *) (yyvsp[-1].string));
                     if (strlen((char *) (yyvsp[0].string)) != len)
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
                        lcslot = ucslot = addstringchar((yyvsp[0].string), 0, 1);
                        if (ucslot >= 0)
                           lcslot = addstringchar((yyvsp[-1].string), 1, 0);
                        if (ucslot >= 0  &&  lcslot >= 0) {
                           if (ucslot >= lcslot)
                              ucslot++;
                           hashheader.lowerconv[ucslot] = (ichar_t) lcslot;
                           hashheader.upperconv[lcslot] = (ichar_t) ucslot;
                        }
                     }
                     free((char *) (yyvsp[-1].string));
                     free((char *) (yyvsp[0].string));
                  }
#line 1668 "src/y.tab.c" /* yacc.c:1646  */
    break;

  case 24:
#line 429 "src/parse.y" /* yacc.c:1646  */
    {
                     chartypes[ctypenum].name = (char *) (yyvsp[-2].string);
                     chartypes[ctypenum].deformatter = (char *) (yyvsp[-1].string);
                     /*
                      * Implement a few common synonyms.  This should
                      * be generalized.
                      */
                     if (strcmp((char *) (yyvsp[-1].string), "TeX") == 0)
                        strcpy((char *) (yyvsp[-1].string), "tex");
                     else if (strcmp((char *) (yyvsp[-1].string), "troff") == 0)
                        strcpy((char *) (yyvsp[-1].string), "nroff");
                     /*
                      * Someday, we'll accept generalized deformatters.
                      * Then we can get rid of this test.
                      */
                     if (strcmp((char *) (yyvsp[-1].string), "nroff") != 0
                         &&  strcmp((char *) (yyvsp[-1].string), "tex") != 0)
                        yyerror(PARSE_Y_BAD_DEFORMATTER);
                     ctypenum++;
                     hashheader.nstrchartype = ctypenum;
                     }
#line 1694 "src/y.tab.c" /* yacc.c:1646  */
    break;

  case 25:
#line 453 "src/parse.y" /* yacc.c:1646  */
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
                     ctypechars = TBLINC * (strlen((char *) (yyvsp[0].string)) + 1) + 1;
                     chartypes[ctypenum].suffixes =
                                             malloc((unsigned int) ctypechars);
                     if (chartypes[ctypenum].suffixes == NULL) {
                        yyerror(PARSE_Y_NO_SPACE);
                        exit(1);
                     }
                     strcpy(chartypes[ctypenum].suffixes, (char *) (yyvsp[0].string));
                     chartypes[ctypenum].suffixes[strlen ((char *) (yyvsp[0].string)) + 1]
                         = '\0';
                     free((char *) (yyvsp[0].string));
                  }
#line 1726 "src/y.tab.c" /* yacc.c:1646  */
    break;

  case 26:
#line 481 "src/parse.y" /* yacc.c:1646  */
    {
                     char *nexttype;
                     int offset;

                     for (nexttype = chartypes[ctypenum].suffixes;
                          *nexttype != '\0'; nexttype += strlen(nexttype) + 1)
                        ;
                     offset = nexttype - chartypes[ctypenum].suffixes;
                     if ((int) (offset + strlen((char *) (yyvsp[0].string)) + 1)
                         >= ctypechars) {
                        ctypechars += TBLINC * (strlen((char *) (yyvsp[0].string)) + 1);
                        chartypes[ctypenum].suffixes =
                            realloc(chartypes[ctypenum].suffixes,
                             (unsigned int) ctypechars);
                        if (chartypes[ctypenum].suffixes == NULL) {
                           yyerror(PARSE_Y_NO_SPACE);
                           exit(1);
                        }
                        nexttype = chartypes[ctypenum].suffixes + offset;
                     }
                     strcpy(nexttype, (char *) (yyvsp[0].string));
                     nexttype[strlen((char *) (yyvsp[0].string)) + 1] = '\0';
                     free((char *) (yyvsp[0].string));
                  }
#line 1755 "src/y.tab.c" /* yacc.c:1646  */
    break;

  case 30:
#line 516 "src/parse.y" /* yacc.c:1646  */
    {
                     int i, len, slot;

                     len = strlen((char *) (yyvsp[-1].string));
                     if (len > MAXSTRINGCHARLEN)
                        yyerror(PARSE_Y_LONG_STRING);
                     else if (len == 0)
                        yyerror(PARSE_Y_NULL_STRING);
                     else if (hashheader.nstrchars >= MAXSTRINGCHARS)
                        yyerror(PARSE_Y_MANY_STRINGS);
                     else if (!isstringch ((char *) (yyvsp[0].string), 1))
                        yyerror(PARSE_Y_NO_SUCH_STRING);
                     else {
                        slot = addstringchar((yyvsp[-1].string), 0, 0) - SET_SIZE;
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
                     free((char *) (yyvsp[-1].string));
                     free((char *) (yyvsp[0].string));
                     }
#line 1792 "src/y.tab.c" /* yacc.c:1646  */
    break;

  case 31:
#line 551 "src/parse.y" /* yacc.c:1646  */
    {
                     if (strlen((char *) (yyvsp[0].string)) == sizeof(hashheader.nrchars))
                        bcopy((char *) (yyvsp[0].string), hashheader.nrchars,
                                     sizeof(hashheader.nrchars));
                     else
                        yyerror(PARSE_Y_WRONG_NROFF);
                     free((char *) (yyvsp[0].string));
                     }
#line 1805 "src/y.tab.c" /* yacc.c:1646  */
    break;

  case 32:
#line 560 "src/parse.y" /* yacc.c:1646  */
    {
                     if (strlen((char *) (yyvsp[0].string)) == sizeof(hashheader.texchars))
                        bcopy((char *) (yyvsp[0].string), hashheader.texchars,
                                     sizeof(hashheader.texchars));
                     else
                        yyerror(PARSE_Y_WRONG_TEX);
                     free((char *) (yyvsp[0].string));
                     }
#line 1818 "src/y.tab.c" /* yacc.c:1646  */
    break;

  case 33:
#line 569 "src/parse.y" /* yacc.c:1646  */
    {
                     unsigned char * digitp; /* Pointer to next digit */

                     for (digitp = (yyvsp[0].string);  *digitp != '\0';  digitp++) {
                        if (*digitp <= '0'  ||  *digitp >= '9') {
                           yyerror(PARSE_Y_BAD_NUMBER);
                           break;
                        }
                     }
                     hashheader.compoundmin = atoi ((const char *)(yyvsp[0].string));
                     }
#line 1834 "src/y.tab.c" /* yacc.c:1646  */
    break;

  case 34:
#line 581 "src/parse.y" /* yacc.c:1646  */
    {
                     hashheader.defspaceflag = !(yyvsp[0].simple);
                     }
#line 1842 "src/y.tab.c" /* yacc.c:1646  */
    break;

  case 35:
#line 585 "src/parse.y" /* yacc.c:1646  */
    {
                     hashheader.defhardflag = (yyvsp[0].simple);
                     }
#line 1850 "src/y.tab.c" /* yacc.c:1646  */
    break;

  case 36:
#line 589 "src/parse.y" /* yacc.c:1646  */
    {
                     if (strlen((char *) (yyvsp[0].string)) != 1)
                        yyerror(PARSE_Y_LONG_FLAG);
                     else
                        hashheader.flagmarker = (yyvsp[0].string)[0];
                     free((char *) (yyvsp[0].string));
                     }
#line 1862 "src/y.tab.c" /* yacc.c:1646  */
    break;

  case 37:
#line 599 "src/parse.y" /* yacc.c:1646  */
    {
                     int i;
                     char *set;

                     set = malloc(SET_SIZE + MAXSTRINGCHARS);
                     if (set == NULL) {
                        yyerror(PARSE_Y_NO_SPACE);
                        exit(1);
                     }
                     (yyval.charset).set = set;
                     for (i = SET_SIZE + MAXSTRINGCHARS;  --i >= 0;  )
                        *set++ = 1;
                     (yyval.charset).complement = 0;
                     }
#line 1881 "src/y.tab.c" /* yacc.c:1646  */
    break;

  case 38:
#line 614 "src/parse.y" /* yacc.c:1646  */
    {
                     int setlen;

                     (yyval.charset).set = malloc(SET_SIZE + MAXSTRINGCHARS);
                     if ((yyval.charset).set == NULL) {
                        yyerror(PARSE_Y_NO_SPACE);
                        exit(1);
                     }
                     bzero((yyval.charset).set, SET_SIZE + MAXSTRINGCHARS);
                     if (l1_isstringch ((char *) (yyvsp[0].string), setlen, 1)) {
                        if (setlen != strlen((char *) (yyvsp[0].string)))
                           yyerror(PARSE_Y_NEED_BLANK);
                        (yyval.charset).set[SET_SIZE + laststringch] = 1;
                     }
                     else {
                        if (strlen((char *) (yyvsp[0].string)) != 1)
                           yyerror(PARSE_Y_NEED_BLANK);
                        (yyval.charset).set[*(yyvsp[0].string)] = 1;
                     }
                     free((char *) (yyvsp[0].string));
                     (yyval.charset).complement = 0;
                     }
#line 1908 "src/y.tab.c" /* yacc.c:1646  */
    break;

  case 40:
#line 640 "src/parse.y" /* yacc.c:1646  */
    {
                     (yyval.simple) = 1;
                     }
#line 1916 "src/y.tab.c" /* yacc.c:1646  */
    break;

  case 41:
#line 644 "src/parse.y" /* yacc.c:1646  */
    {
                     (yyval.simple) = 0;
                     }
#line 1924 "src/y.tab.c" /* yacc.c:1646  */
    break;

  case 46:
#line 656 "src/parse.y" /* yacc.c:1646  */
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
#line 1945 "src/y.tab.c" /* yacc.c:1646  */
    break;

  case 47:
#line 675 "src/parse.y" /* yacc.c:1646  */
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
#line 1964 "src/y.tab.c" /* yacc.c:1646  */
    break;

  case 48:
#line 692 "src/parse.y" /* yacc.c:1646  */
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
#line 1994 "src/y.tab.c" /* yacc.c:1646  */
    break;

  case 49:
#line 718 "src/parse.y" /* yacc.c:1646  */
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
#line 2016 "src/y.tab.c" /* yacc.c:1646  */
    break;

  case 50:
#line 738 "src/parse.y" /* yacc.c:1646  */
    { treat_flag_def((char *)(yyvsp[-3].string), (yyvsp[-1].istr), 0); }
#line 2022 "src/y.tab.c" /* yacc.c:1646  */
    break;

  case 51:
#line 740 "src/parse.y" /* yacc.c:1646  */
    { treat_flag_def((char *)(yyvsp[-3].string), (yyvsp[-1].istr), FF_CROSSPRODUCT); }
#line 2028 "src/y.tab.c" /* yacc.c:1646  */
    break;

  case 52:
#line 742 "src/parse.y" /* yacc.c:1646  */
    { treat_flag_def((char *)(yyvsp[-3].string), (yyvsp[-1].istr), FF_REC); }
#line 2034 "src/y.tab.c" /* yacc.c:1646  */
    break;

  case 53:
#line 744 "src/parse.y" /* yacc.c:1646  */
    { (yyval.simple) = 0; }
#line 2040 "src/y.tab.c" /* yacc.c:1646  */
    break;

  case 54:
#line 748 "src/parse.y" /* yacc.c:1646  */
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
                     curents[0] = *(yyvsp[0].entry);
                     centnum = 1;
                     free((char *) (yyvsp[0].entry));
                     (yyval.simple) = 0;
                     }
#line 2060 "src/y.tab.c" /* yacc.c:1646  */
    break;

  case 55:
#line 764 "src/parse.y" /* yacc.c:1646  */
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
                     curents[centnum] = *(yyvsp[0].entry);
                     centnum++;
                     free((char *) (yyvsp[0].entry));
                     }
#line 2080 "src/y.tab.c" /* yacc.c:1646  */
    break;

  case 56:
#line 782 "src/parse.y" /* yacc.c:1646  */
    {  treat_affix_rule((yyvsp[-3].entry), strtosichar("", 1), (yyvsp[-1].istr), (yyvsp[0].istr));
                        (yyval.entry) = (yyvsp[-3].entry);
                     }
#line 2088 "src/y.tab.c" /* yacc.c:1646  */
    break;

  case 57:
#line 786 "src/parse.y" /* yacc.c:1646  */
    {  treat_affix_rule((yyvsp[-6].entry), (yyvsp[-3].istr), (yyvsp[-1].istr), (yyvsp[0].istr));
                        (yyval.entry) = (yyvsp[-6].entry);
                      }
#line 2096 "src/y.tab.c" /* yacc.c:1646  */
    break;

  case 58:
#line 790 "src/parse.y" /* yacc.c:1646  */
    {  treat_affix_rule((yyvsp[-6].entry), (yyvsp[-3].istr), strtosichar("", 1), (yyvsp[0].istr));
                        (yyval.entry) = (yyvsp[-6].entry);
                      }
#line 2104 "src/y.tab.c" /* yacc.c:1646  */
    break;

  case 59:
#line 796 "src/parse.y" /* yacc.c:1646  */
    {
                     struct flagent *ent;

                     ent = (struct flagent *) malloc(sizeof(struct flagent));
                     if (ent == NULL) {
                        yyerror(PARSE_Y_NO_SPACE);
                        exit(1);
                     }
                     ent->numconds = 0;
                     bzero(ent->conds, SET_SIZE + MAXSTRINGCHARS);
                     (yyval.entry) = ent;
                     }
#line 2121 "src/y.tab.c" /* yacc.c:1646  */
    break;

  case 61:
#line 812 "src/parse.y" /* yacc.c:1646  */
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
                        if ((yyvsp[0].charset).set[i]) {
                           ent->conds[i] = 1;
                           if (!(yyvsp[0].charset).complement)
                              ent->conds[mytoupper((ichar_t) i)] = 1;
                        }
                     }
                     if ((yyvsp[0].charset).complement) {
                        for (i = SET_SIZE + MAXSTRINGCHARS; --i >= 0; ) {
                           if ((yyvsp[0].charset).set[i] == 0)
                              ent->conds[mytoupper((ichar_t) i)] = 0;
                        }
                     }
                     free((yyvsp[0].charset).set);
                     (yyval.entry) = ent;
                     }
#line 2157 "src/y.tab.c" /* yacc.c:1646  */
    break;

  case 62:
#line 844 "src/parse.y" /* yacc.c:1646  */
    {
                     int i;
                     int mask;

                     if ((yyvsp[-1].entry)->numconds >= 8) {
                        yyerror(PARSE_Y_MANY_CONDS);
                        (yyvsp[-1].entry)->numconds = 7;
                     }
                     mask = 1 << (yyvsp[-1].entry)->numconds;
                     (yyvsp[-1].entry)->numconds++;
                     for (i = SET_SIZE + MAXSTRINGCHARS; --i >= 0; ) {
                        if ((yyvsp[0].charset).set[i]) {
                           (yyvsp[-1].entry)->conds[i] |= mask;
                           if (!(yyvsp[0].charset).complement)
                              (yyvsp[-1].entry)->conds[mytoupper((ichar_t) i)]  |= mask;
                        }
                     }
                     if ((yyvsp[0].charset).complement) {
                        mask = ~mask;
                        for (i = SET_SIZE + MAXSTRINGCHARS; --i >= 0; ) {
                           if ((yyvsp[0].charset).set[i] == 0)
                              (yyvsp[-1].entry)->conds[mytoupper ((ichar_t) i)] &= mask;
                        }
                     }
                     free((yyvsp[0].charset).set);
                     }
#line 2188 "src/y.tab.c" /* yacc.c:1646  */
    break;

  case 63:
#line 873 "src/parse.y" /* yacc.c:1646  */
    {
                     ichar_t *tichar;

                     tichar = strtosichar((char *) (yyvsp[0].string), 1);
                     (yyval.istr) = (ichar_t *) malloc(sizeof(ichar_t)
                                             * (icharlen(tichar) + 1));
                     if ((yyval.istr) == NULL) {
                        yyerror(PARSE_Y_NO_SPACE);
                        exit(1);
                     }
                     icharcpy((yyval.istr), tichar);
                     free((char *) (yyvsp[0].string));
                     }
#line 2206 "src/y.tab.c" /* yacc.c:1646  */
    break;

  case 64:
#line 889 "src/parse.y" /* yacc.c:1646  */
    {
                     (yyval.istr) = (ichar_t *) malloc(sizeof(ichar_t));
                     icharcpy((yyval.istr), strtosichar("", 1));
                   }
#line 2215 "src/y.tab.c" /* yacc.c:1646  */
    break;

  case 65:
#line 894 "src/parse.y" /* yacc.c:1646  */
    {
                     ichar_t *tichar;

                     tichar = strtosichar((char *) (yyvsp[0].string), 1);
                     (yyval.istr) = (ichar_t *) malloc(sizeof(ichar_t)
                                             * (icharlen(tichar) + 1));
                     if ((yyval.istr) == NULL) {
                        yyerror(PARSE_Y_NO_SPACE);
                        exit(1);
                     }
                     icharcpy((yyval.istr), tichar);
                     free((char *) (yyvsp[0].string));   /* ??? */
                   }
#line 2233 "src/y.tab.c" /* yacc.c:1646  */
    break;


#line 2237 "src/y.tab.c" /* yacc.c:1646  */
      default: break;
    }
  /* User semantic actions sometimes alter yychar, and that requires
     that yytoken be updated with the new translation.  We take the
     approach of translating immediately before every use of yytoken.
     One alternative is translating here after every semantic action,
     but that translation would be missed if the semantic action invokes
     YYABORT, YYACCEPT, or YYERROR immediately after altering yychar or
     if it invokes YYBACKUP.  In the case of YYABORT or YYACCEPT, an
     incorrect destructor might then be invoked immediately.  In the
     case of YYERROR or YYBACKUP, subsequent parser actions might lead
     to an incorrect destructor call or verbose syntax error message
     before the lookahead is translated.  */
  YY_SYMBOL_PRINT ("-> $$ =", yyr1[yyn], &yyval, &yyloc);

  YYPOPSTACK (yylen);
  yylen = 0;
  YY_STACK_PRINT (yyss, yyssp);

  *++yyvsp = yyval;

  /* Now 'shift' the result of the reduction.  Determine what state
     that goes to, based on the state we popped back to and the rule
     number reduced by.  */

  yyn = yyr1[yyn];

  yystate = yypgoto[yyn - YYNTOKENS] + *yyssp;
  if (0 <= yystate && yystate <= YYLAST && yycheck[yystate] == *yyssp)
    yystate = yytable[yystate];
  else
    yystate = yydefgoto[yyn - YYNTOKENS];

  goto yynewstate;


/*--------------------------------------.
| yyerrlab -- here on detecting error.  |
`--------------------------------------*/
yyerrlab:
  /* Make sure we have latest lookahead translation.  See comments at
     user semantic actions for why this is necessary.  */
  yytoken = yychar == YYEMPTY ? YYEMPTY : YYTRANSLATE (yychar);

  /* If not already recovering from an error, report this error.  */
  if (!yyerrstatus)
    {
      ++yynerrs;
#if ! YYERROR_VERBOSE
      yyerror (YY_("syntax error"));
#else
# define YYSYNTAX_ERROR yysyntax_error (&yymsg_alloc, &yymsg, \
                                        yyssp, yytoken)
      {
        char const *yymsgp = YY_("syntax error");
        int yysyntax_error_status;
        yysyntax_error_status = YYSYNTAX_ERROR;
        if (yysyntax_error_status == 0)
          yymsgp = yymsg;
        else if (yysyntax_error_status == 1)
          {
            if (yymsg != yymsgbuf)
              YYSTACK_FREE (yymsg);
            yymsg = (char *) YYSTACK_ALLOC (yymsg_alloc);
            if (!yymsg)
              {
                yymsg = yymsgbuf;
                yymsg_alloc = sizeof yymsgbuf;
                yysyntax_error_status = 2;
              }
            else
              {
                yysyntax_error_status = YYSYNTAX_ERROR;
                yymsgp = yymsg;
              }
          }
        yyerror (yymsgp);
        if (yysyntax_error_status == 2)
          goto yyexhaustedlab;
      }
# undef YYSYNTAX_ERROR
#endif
    }



  if (yyerrstatus == 3)
    {
      /* If just tried and failed to reuse lookahead token after an
         error, discard it.  */

      if (yychar <= YYEOF)
        {
          /* Return failure if at end of input.  */
          if (yychar == YYEOF)
            YYABORT;
        }
      else
        {
          yydestruct ("Error: discarding",
                      yytoken, &yylval);
          yychar = YYEMPTY;
        }
    }

  /* Else will try to reuse lookahead token after shifting the error
     token.  */
  goto yyerrlab1;


/*---------------------------------------------------.
| yyerrorlab -- error raised explicitly by YYERROR.  |
`---------------------------------------------------*/
yyerrorlab:

  /* Pacify compilers like GCC when the user code never invokes
     YYERROR and the label yyerrorlab therefore never appears in user
     code.  */
  if (/*CONSTCOND*/ 0)
     goto yyerrorlab;

  /* Do not reclaim the symbols of the rule whose action triggered
     this YYERROR.  */
  YYPOPSTACK (yylen);
  yylen = 0;
  YY_STACK_PRINT (yyss, yyssp);
  yystate = *yyssp;
  goto yyerrlab1;


/*-------------------------------------------------------------.
| yyerrlab1 -- common code for both syntax error and YYERROR.  |
`-------------------------------------------------------------*/
yyerrlab1:
  yyerrstatus = 3;      /* Each real token shifted decrements this.  */

  for (;;)
    {
      yyn = yypact[yystate];
      if (!yypact_value_is_default (yyn))
        {
          yyn += YYTERROR;
          if (0 <= yyn && yyn <= YYLAST && yycheck[yyn] == YYTERROR)
            {
              yyn = yytable[yyn];
              if (0 < yyn)
                break;
            }
        }

      /* Pop the current state because it cannot handle the error token.  */
      if (yyssp == yyss)
        YYABORT;


      yydestruct ("Error: popping",
                  yystos[yystate], yyvsp);
      YYPOPSTACK (1);
      yystate = *yyssp;
      YY_STACK_PRINT (yyss, yyssp);
    }

  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  *++yyvsp = yylval;
  YY_IGNORE_MAYBE_UNINITIALIZED_END


  /* Shift the error token.  */
  YY_SYMBOL_PRINT ("Shifting", yystos[yyn], yyvsp, yylsp);

  yystate = yyn;
  goto yynewstate;


/*-------------------------------------.
| yyacceptlab -- YYACCEPT comes here.  |
`-------------------------------------*/
yyacceptlab:
  yyresult = 0;
  goto yyreturn;

/*-----------------------------------.
| yyabortlab -- YYABORT comes here.  |
`-----------------------------------*/
yyabortlab:
  yyresult = 1;
  goto yyreturn;

#if !defined yyoverflow || YYERROR_VERBOSE
/*-------------------------------------------------.
| yyexhaustedlab -- memory exhaustion comes here.  |
`-------------------------------------------------*/
yyexhaustedlab:
  yyerror (YY_("memory exhausted"));
  yyresult = 2;
  /* Fall through.  */
#endif

yyreturn:
  if (yychar != YYEMPTY)
    {
      /* Make sure we have latest lookahead translation.  See comments at
         user semantic actions for why this is necessary.  */
      yytoken = YYTRANSLATE (yychar);
      yydestruct ("Cleanup: discarding lookahead",
                  yytoken, &yylval);
    }
  /* Do not reclaim the symbols of the rule whose action triggered
     this YYABORT or YYACCEPT.  */
  YYPOPSTACK (yylen);
  YY_STACK_PRINT (yyss, yyssp);
  while (yyssp != yyss)
    {
      yydestruct ("Cleanup: popping",
                  yystos[*yyssp], yyvsp);
      YYPOPSTACK (1);
    }
#ifndef yyoverflow
  if (yyss != yyssa)
    YYSTACK_FREE (yyss);
#endif
#if YYERROR_VERBOSE
  if (yymsg != yymsgbuf)
    YYSTACK_FREE (yymsg);
#endif
  return yyresult;
}
#line 909 "src/parse.y" /* yacc.c:1906  */

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
