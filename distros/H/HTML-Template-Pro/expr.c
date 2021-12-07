/* A Bison parser, made by GNU Bison 3.0.5.  */

/* Bison implementation for Yacc-like parsers in C

   Copyright (C) 1984, 1989-1990, 2000-2015, 2018 Free Software Foundation, Inc.

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
#define YYBISON_VERSION "3.0.5"

/* Skeleton name.  */
#define YYSKELETON_NAME "yacc.c"

/* Pure parsers.  */
#define YYPURE 1

/* Push parsers.  */
#define YYPUSH 0

/* Pull parsers.  */
#define YYPULL 1




/* Copy the first part of user declarations.  */
#line 7 "expr.y" /* yacc.c:339  */

#include <math.h>  /* For math functions, cos(), sin(), etc.  */
#include <stdio.h> /* for printf */
#include <stdlib.h> /* for malloc */
#include <ctype.h> /* for yylex alnum */
#include "calc.h"  /* Contains definition of `symrec'.  */
#include "tmpllog.h"
#include "pabstract.h"
#include "prostate.h"
#include "provalue.h"
#include "pparam.h"
#include "pmiscdef.h"
/* for expr-specific only */
#include "exprtool.h"
#include "exprpstr.h"
#include "parse_expr.h"
  /* Remember unsigned char assert on win32
Debug Assertion Failed! f:\dd\vctools\crt_bld\self_x86\crt\src \isctype.c Expression:(unsigned)(c + 1) <= 256 
   */
  

#line 88 "y.tab.c" /* yacc.c:339  */

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
    NUM = 258,
    EXTFUNC = 259,
    BUILTIN_VAR = 260,
    BUILTIN_FNC_DD = 261,
    BUILTIN_FNC_DDD = 262,
    BUILTIN_FNC_EE = 263,
    VAR = 264,
    OR = 265,
    AND = 266,
    strGT = 267,
    strGE = 268,
    strLT = 269,
    strLE = 270,
    strEQ = 271,
    strNE = 272,
    strCMP = 273,
    numGT = 274,
    numGE = 275,
    numLT = 276,
    numLE = 277,
    numEQ = 278,
    numNE = 279,
    reLIKE = 280,
    reNOTLIKE = 281,
    NOT = 282,
    NEG = 283
  };
#endif
/* Tokens.  */
#define NUM 258
#define EXTFUNC 259
#define BUILTIN_VAR 260
#define BUILTIN_FNC_DD 261
#define BUILTIN_FNC_DDD 262
#define BUILTIN_FNC_EE 263
#define VAR 264
#define OR 265
#define AND 266
#define strGT 267
#define strGE 268
#define strLT 269
#define strLE 270
#define strEQ 271
#define strNE 272
#define strCMP 273
#define numGT 274
#define numGE 275
#define numLT 276
#define numLE 277
#define numEQ 278
#define numNE 279
#define reLIKE 280
#define reNOTLIKE 281
#define NOT 282
#define NEG 283

/* Value type.  */
#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED

union YYSTYPE
{
#line 27 "expr.y" /* yacc.c:355  */

  struct exprval numval;   /* For returning numbers.  */
  const symrec_const  *tptr;   /* For returning symbol-table pointers.  */
  struct user_func_call extfunc;  /* for user-defined function name */
  PSTRING uservar;

#line 188 "y.tab.c" /* yacc.c:355  */
};

typedef union YYSTYPE YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define YYSTYPE_IS_DECLARED 1
#endif



int yyparse (struct tmplpro_state* state, struct expr_parser* exprobj, PSTRING* expr_retval_ptr);



/* Copy the second part of user declarations.  */
#line 33 "expr.y" /* yacc.c:358  */

  /* the second section is required as we use YYSTYPE here */
  static void yyerror (struct tmplpro_state* state, struct expr_parser* exprobj, PSTRING* expr_retval_ptr, char const *);
  static int yylex (YYSTYPE *lvalp, struct tmplpro_state* state, struct expr_parser* exprobj);

#line 209 "y.tab.c" /* yacc.c:358  */

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
#define YYFINAL  23
/* YYLAST -- Last index in YYTABLE.  */
#define YYLAST   374

/* YYNTOKENS -- Number of terminals.  */
#define YYNTOKENS  41
/* YYNNTS -- Number of nonterminals.  */
#define YYNNTS  4
/* YYNRULES -- Number of rules.  */
#define YYNRULES  40
/* YYNSTATES -- Number of states.  */
#define YYNSTATES  85

/* YYTRANSLATE[YYX] -- Symbol number corresponding to YYX as returned
   by yylex, with out-of-bounds checking.  */
#define YYUNDEFTOK  2
#define YYMAXUTOK   283

#define YYTRANSLATE(YYX)                                                \
  ((unsigned int) (YYX) <= YYMAXUTOK ? yytranslate[YYX] : YYUNDEFTOK)

/* YYTRANSLATE[TOKEN-NUM] -- Symbol number corresponding to TOKEN-NUM
   as returned by yylex, without out-of-bounds checking.  */
static const yytype_uint8 yytranslate[] =
{
       0,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,    34,     2,     2,     2,    33,     2,     2,
      39,    38,    31,    30,    40,    29,     2,    32,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
      25,     2,    26,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,    37,     2,     2,     2,     2,     2,
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
       2,     2,     2,     2,     2,     2,     1,     2,     3,     4,
       5,     6,     7,     8,     9,    10,    11,    12,    13,    14,
      15,    16,    17,    18,    19,    20,    21,    22,    23,    24,
      27,    28,    35,    36
};

#if YYDEBUG
  /* YYRLINE[YYN] -- Source line where rule number YYN was defined.  */
static const yytype_uint8 yyrline[] =
{
       0,    61,    61,    69,    70,    72,    81,    85,    90,    97,
     103,   109,   113,   114,   115,   116,   147,   159,   170,   176,
     188,   200,   201,   202,   203,   204,   205,   206,   207,   208,
     209,   213,   214,   215,   216,   217,   218,   219,   220,   223,
     228
};
#endif

#if YYDEBUG || YYERROR_VERBOSE || 0
/* YYTNAME[SYMBOL-NUM] -- String name of the symbol SYMBOL-NUM.
   First, the terminals, then, starting at YYNTOKENS, nonterminals.  */
static const char *const yytname[] =
{
  "$end", "error", "$undefined", "NUM", "EXTFUNC", "BUILTIN_VAR",
  "BUILTIN_FNC_DD", "BUILTIN_FNC_DDD", "BUILTIN_FNC_EE", "VAR", "OR",
  "AND", "strGT", "strGE", "strLT", "strLE", "strEQ", "strNE", "strCMP",
  "numGT", "numGE", "numLT", "numLE", "numEQ", "numNE", "'<'", "'>'",
  "reLIKE", "reNOTLIKE", "'-'", "'+'", "'*'", "'/'", "'%'", "'!'", "NOT",
  "NEG", "'^'", "')'", "'('", "','", "$accept", "line", "numEXP",
  "arglist", YY_NULLPTR
};
#endif

# ifdef YYPRINT
/* YYTOKNUM[NUM] -- (External) token number corresponding to the
   (internal) symbol number NUM (which must be that of a token).  */
static const yytype_uint16 yytoknum[] =
{
       0,   256,   257,   258,   259,   260,   261,   262,   263,   264,
     265,   266,   267,   268,   269,   270,   271,   272,   273,   274,
     275,   276,   277,   278,   279,    60,    62,   280,   281,    45,
      43,    42,    47,    37,    33,   282,   283,    94,    41,    40,
      44
};
# endif

#define YYPACT_NINF -35

#define yypact_value_is_default(Yystate) \
  (!!((Yystate) == (-35)))

#define YYTABLE_NINF -1

#define yytable_value_is_error(Yytable_value) \
  (!!((Yytable_value) == (-1)))

  /* YYPACT[STATE-NUM] -- Index in YYTABLE of the portion describing
     STATE-NUM.  */
static const yytype_int16 yypact[] =
{
      54,   -35,   -28,   -35,   -27,   -26,   -25,   -35,    54,    54,
      54,    54,     5,   231,   -34,    40,    54,    54,    47,   -22,
     -22,   -22,   115,   -35,    54,    54,    54,    54,    54,    54,
      54,    54,    54,    54,    54,    54,    54,    54,    54,    54,
      54,    54,    54,    54,    54,    54,    54,   -35,    54,   -35,
     231,   144,    84,   -35,   173,   -35,   258,   284,   310,   310,
     310,   310,   310,   310,   310,   326,   326,   326,   326,   326,
     326,   337,   337,    33,    33,   -22,   -22,   -22,   -22,   231,
     -35,    54,   -35,   202,   -35
};

  /* YYDEFACT[STATE-NUM] -- Default reduction number in state STATE-NUM.
     Performed when YYTABLE does not specify something else to do.  Zero
     means the default is an error.  */
static const yytype_uint8 yydefact[] =
{
       0,     3,     0,     4,     0,     0,     0,     5,     0,     0,
       0,     0,     0,     2,     0,     0,     0,     0,     0,    17,
      27,    28,     0,     1,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     6,     0,     7,
      39,     0,     0,     8,     0,    29,    19,    20,    35,    31,
      36,    32,    34,    33,    30,    21,    22,    24,    23,    26,
      25,    37,    38,    13,    12,    14,    16,    15,    18,    40,
       9,     0,    11,     0,    10
};

  /* YYPGOTO[NTERM-NUM].  */
static const yytype_int8 yypgoto[] =
{
     -35,   -35,    -8,   -35
};

  /* YYDEFGOTO[NTERM-NUM].  */
static const yytype_int8 yydefgoto[] =
{
      -1,    12,    13,    14
};

  /* YYTABLE[YYPACT[STATE-NUM]] -- What to do in state STATE-NUM.  If
     positive, shift that token.  If negative, reduce the rule whose
     number is the opposite.  If YYTABLE_NINF, syntax error.  */
static const yytype_int8 yytable[] =
{
      19,    20,    21,    22,    47,    23,    48,    50,    51,    52,
      54,    15,    16,    17,    18,    46,    56,    57,    58,    59,
      60,    61,    62,    63,    64,    65,    66,    67,    68,    69,
      70,    71,    72,    73,    74,    75,    76,    77,    78,     0,
      79,     0,     0,     1,     2,     3,     4,     5,     6,     7,
       1,     2,     3,     4,     5,     6,     7,     1,     2,     3,
       4,     5,     6,     7,    43,    44,    45,     0,     0,     8,
      46,     0,     0,    83,     9,    10,     8,     0,    49,    11,
       0,     9,    10,     8,     0,    53,    11,     0,     9,    10,
       0,     0,     0,    11,    24,    25,    26,    27,    28,    29,
      30,    31,    32,     0,    33,     0,    34,    35,    36,    37,
      38,    39,    40,    41,    42,    43,    44,    45,     0,     0,
       0,    46,     0,     0,    81,    24,    25,    26,    27,    28,
      29,    30,    31,    32,     0,    33,     0,    34,    35,    36,
      37,    38,    39,    40,    41,    42,    43,    44,    45,     0,
       0,     0,    46,    55,    24,    25,    26,    27,    28,    29,
      30,    31,    32,     0,    33,     0,    34,    35,    36,    37,
      38,    39,    40,    41,    42,    43,    44,    45,     0,     0,
       0,    46,    80,    24,    25,    26,    27,    28,    29,    30,
      31,    32,     0,    33,     0,    34,    35,    36,    37,    38,
      39,    40,    41,    42,    43,    44,    45,     0,     0,     0,
      46,    82,    24,    25,    26,    27,    28,    29,    30,    31,
      32,     0,    33,     0,    34,    35,    36,    37,    38,    39,
      40,    41,    42,    43,    44,    45,     0,     0,     0,    46,
      84,    24,    25,    26,    27,    28,    29,    30,    31,    32,
       0,    33,     0,    34,    35,    36,    37,    38,    39,    40,
      41,    42,    43,    44,    45,     0,     0,     0,    46,    25,
      26,    27,    28,    29,    30,    31,    32,     0,    33,     0,
      34,    35,    36,    37,    38,    39,    40,    41,    42,    43,
      44,    45,     0,     0,     0,    46,    26,    27,    28,    29,
      30,    31,    32,     0,    33,     0,    34,    35,    36,    37,
      38,    39,    40,    41,    42,    43,    44,    45,     0,     0,
       0,    46,    -1,    -1,    -1,    -1,    -1,    -1,    -1,     0,
      33,     0,    34,    35,    36,    37,    38,    39,    40,    41,
      42,    43,    44,    45,     0,     0,    -1,    46,    -1,    -1,
      -1,    -1,    -1,    39,    40,    41,    42,    43,    44,    45,
       0,     0,     0,    46,    -1,    -1,    41,    42,    43,    44,
      45,     0,     0,     0,    46
};

static const yytype_int8 yycheck[] =
{
       8,     9,    10,    11,    38,     0,    40,    15,    16,    17,
      18,    39,    39,    39,    39,    37,    24,    25,    26,    27,
      28,    29,    30,    31,    32,    33,    34,    35,    36,    37,
      38,    39,    40,    41,    42,    43,    44,    45,    46,    -1,
      48,    -1,    -1,     3,     4,     5,     6,     7,     8,     9,
       3,     4,     5,     6,     7,     8,     9,     3,     4,     5,
       6,     7,     8,     9,    31,    32,    33,    -1,    -1,    29,
      37,    -1,    -1,    81,    34,    35,    29,    -1,    38,    39,
      -1,    34,    35,    29,    -1,    38,    39,    -1,    34,    35,
      -1,    -1,    -1,    39,    10,    11,    12,    13,    14,    15,
      16,    17,    18,    -1,    20,    -1,    22,    23,    24,    25,
      26,    27,    28,    29,    30,    31,    32,    33,    -1,    -1,
      -1,    37,    -1,    -1,    40,    10,    11,    12,    13,    14,
      15,    16,    17,    18,    -1,    20,    -1,    22,    23,    24,
      25,    26,    27,    28,    29,    30,    31,    32,    33,    -1,
      -1,    -1,    37,    38,    10,    11,    12,    13,    14,    15,
      16,    17,    18,    -1,    20,    -1,    22,    23,    24,    25,
      26,    27,    28,    29,    30,    31,    32,    33,    -1,    -1,
      -1,    37,    38,    10,    11,    12,    13,    14,    15,    16,
      17,    18,    -1,    20,    -1,    22,    23,    24,    25,    26,
      27,    28,    29,    30,    31,    32,    33,    -1,    -1,    -1,
      37,    38,    10,    11,    12,    13,    14,    15,    16,    17,
      18,    -1,    20,    -1,    22,    23,    24,    25,    26,    27,
      28,    29,    30,    31,    32,    33,    -1,    -1,    -1,    37,
      38,    10,    11,    12,    13,    14,    15,    16,    17,    18,
      -1,    20,    -1,    22,    23,    24,    25,    26,    27,    28,
      29,    30,    31,    32,    33,    -1,    -1,    -1,    37,    11,
      12,    13,    14,    15,    16,    17,    18,    -1,    20,    -1,
      22,    23,    24,    25,    26,    27,    28,    29,    30,    31,
      32,    33,    -1,    -1,    -1,    37,    12,    13,    14,    15,
      16,    17,    18,    -1,    20,    -1,    22,    23,    24,    25,
      26,    27,    28,    29,    30,    31,    32,    33,    -1,    -1,
      -1,    37,    12,    13,    14,    15,    16,    17,    18,    -1,
      20,    -1,    22,    23,    24,    25,    26,    27,    28,    29,
      30,    31,    32,    33,    -1,    -1,    20,    37,    22,    23,
      24,    25,    26,    27,    28,    29,    30,    31,    32,    33,
      -1,    -1,    -1,    37,    27,    28,    29,    30,    31,    32,
      33,    -1,    -1,    -1,    37
};

  /* YYSTOS[STATE-NUM] -- The (internal number of the) accessing
     symbol of state STATE-NUM.  */
static const yytype_uint8 yystos[] =
{
       0,     3,     4,     5,     6,     7,     8,     9,    29,    34,
      35,    39,    42,    43,    44,    39,    39,    39,    39,    43,
      43,    43,    43,     0,    10,    11,    12,    13,    14,    15,
      16,    17,    18,    20,    22,    23,    24,    25,    26,    27,
      28,    29,    30,    31,    32,    33,    37,    38,    40,    38,
      43,    43,    43,    38,    43,    38,    43,    43,    43,    43,
      43,    43,    43,    43,    43,    43,    43,    43,    43,    43,
      43,    43,    43,    43,    43,    43,    43,    43,    43,    43,
      38,    40,    38,    43,    38
};

  /* YYR1[YYN] -- Symbol number of symbol that rule YYN derives.  */
static const yytype_uint8 yyr1[] =
{
       0,    41,    42,    43,    43,    43,    43,    43,    43,    43,
      43,    43,    43,    43,    43,    43,    43,    43,    43,    43,
      43,    43,    43,    43,    43,    43,    43,    43,    43,    43,
      43,    43,    43,    43,    43,    43,    43,    43,    43,    44,
      44
};

  /* YYR2[YYN] -- Number of symbols on the right hand side of rule YYN.  */
static const yytype_uint8 yyr2[] =
{
       0,     2,     1,     1,     1,     1,     2,     3,     3,     4,
       6,     4,     3,     3,     3,     3,     3,     2,     3,     3,
       3,     3,     3,     3,     3,     3,     3,     2,     2,     3,
       3,     3,     3,     3,     3,     3,     3,     3,     3,     3,
       3
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
      yyerror (state, exprobj, expr_retval_ptr, YY_("syntax error: cannot back up")); \
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
                  Type, Value, state, exprobj, expr_retval_ptr); \
      YYFPRINTF (stderr, "\n");                                           \
    }                                                                     \
} while (0)


/*----------------------------------------.
| Print this symbol's value on YYOUTPUT.  |
`----------------------------------------*/

static void
yy_symbol_value_print (FILE *yyoutput, int yytype, YYSTYPE const * const yyvaluep, struct tmplpro_state* state, struct expr_parser* exprobj, PSTRING* expr_retval_ptr)
{
  FILE *yyo = yyoutput;
  YYUSE (yyo);
  YYUSE (state);
  YYUSE (exprobj);
  YYUSE (expr_retval_ptr);
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
yy_symbol_print (FILE *yyoutput, int yytype, YYSTYPE const * const yyvaluep, struct tmplpro_state* state, struct expr_parser* exprobj, PSTRING* expr_retval_ptr)
{
  YYFPRINTF (yyoutput, "%s %s (",
             yytype < YYNTOKENS ? "token" : "nterm", yytname[yytype]);

  yy_symbol_value_print (yyoutput, yytype, yyvaluep, state, exprobj, expr_retval_ptr);
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
yy_reduce_print (yytype_int16 *yyssp, YYSTYPE *yyvsp, int yyrule, struct tmplpro_state* state, struct expr_parser* exprobj, PSTRING* expr_retval_ptr)
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
                                              , state, exprobj, expr_retval_ptr);
      YYFPRINTF (stderr, "\n");
    }
}

# define YY_REDUCE_PRINT(Rule)          \
do {                                    \
  if (yydebug)                          \
    yy_reduce_print (yyssp, yyvsp, Rule, state, exprobj, expr_retval_ptr); \
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
    default: /* Avoid compiler warnings. */
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
yydestruct (const char *yymsg, int yytype, YYSTYPE *yyvaluep, struct tmplpro_state* state, struct expr_parser* exprobj, PSTRING* expr_retval_ptr)
{
  YYUSE (yyvaluep);
  YYUSE (state);
  YYUSE (exprobj);
  YYUSE (expr_retval_ptr);
  if (!yymsg)
    yymsg = "Deleting";
  YY_SYMBOL_PRINT (yymsg, yytype, yyvaluep, yylocationp);

  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  YYUSE (yytype);
  YY_IGNORE_MAYBE_UNINITIALIZED_END
}




/*----------.
| yyparse.  |
`----------*/

int
yyparse (struct tmplpro_state* state, struct expr_parser* exprobj, PSTRING* expr_retval_ptr)
{
/* The lookahead symbol.  */
int yychar;


/* The semantic value of the lookahead symbol.  */
/* Default value used for initialization, for pacifying older GCCs
   or non-GCC compilers.  */
YY_INITIAL_VALUE (static YYSTYPE yyval_default;)
YYSTYPE yylval YY_INITIAL_VALUE (= yyval_default);

    /* Number of syntax errors so far.  */
    int yynerrs;

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
      yychar = yylex (&yylval, state, exprobj);
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
        case 2:
#line 62 "expr.y" /* yacc.c:1648  */
    { 
		   expr_to_str1(state, &(yyvsp[0].numval));
		   *expr_retval_ptr=(yyvsp[0].numval).val.strval;
		 }
#line 1410 "y.tab.c" /* yacc.c:1648  */
    break;

  case 3:
#line 69 "expr.y" /* yacc.c:1648  */
    { (yyval.numval) = (yyvsp[0].numval);			}
#line 1416 "y.tab.c" /* yacc.c:1648  */
    break;

  case 4:
#line 70 "expr.y" /* yacc.c:1648  */
    { (yyval.numval).type=EXPR_TYPE_DBL; (yyval.numval).val.dblval = (yyvsp[0].tptr)->var; }
#line 1422 "y.tab.c" /* yacc.c:1648  */
    break;

  case 5:
#line 72 "expr.y" /* yacc.c:1648  */
    {
		  PSTRING varvalue=_get_variable_value(state->param, (yyvsp[0].uservar));
		  if (varvalue.begin==NULL) {
		    int loglevel = state->param->warn_unused ? TMPL_LOG_ERROR : TMPL_LOG_INFO;
		    log_expr(exprobj,loglevel, "non-initialized variable %.*s\n",(int)((yyvsp[0].uservar).endnext-(yyvsp[0].uservar).begin),(yyvsp[0].uservar).begin);
		  }
		  (yyval.numval).type=EXPR_TYPE_PSTR;
		  (yyval.numval).val.strval=varvalue;
  }
#line 1436 "y.tab.c" /* yacc.c:1648  */
    break;

  case 6:
#line 82 "expr.y" /* yacc.c:1648  */
    {
		   (yyval.numval) = call_expr_userfunc(exprobj, state->param, (yyvsp[-1].extfunc));
		 }
#line 1444 "y.tab.c" /* yacc.c:1648  */
    break;

  case 7:
#line 86 "expr.y" /* yacc.c:1648  */
    {
		   (yyvsp[-2].extfunc).arglist=state->param->InitExprArglistFuncPtr(state->param->ext_calluserfunc_state);
		   (yyval.numval) = call_expr_userfunc(exprobj, state->param, (yyvsp[-2].extfunc));
		 }
#line 1453 "y.tab.c" /* yacc.c:1648  */
    break;

  case 8:
#line 91 "expr.y" /* yacc.c:1648  */
    {
		   struct exprval e = NEW_EXPRVAL(EXPR_TYPE_PSTR);
		   e.val.strval.begin = NULL;
		   e.val.strval.endnext = NULL;
		   (yyval.numval) = (*((func_t_ee)(yyvsp[-2].tptr)->fnctptr))(exprobj, e);
		 }
#line 1464 "y.tab.c" /* yacc.c:1648  */
    break;

  case 9:
#line 98 "expr.y" /* yacc.c:1648  */
    {
		   (yyval.numval).type=EXPR_TYPE_DBL;
		   expr_to_dbl1(exprobj, &(yyvsp[-1].numval));
		   (yyval.numval).val.dblval = (*((func_t_dd)(yyvsp[-3].tptr)->fnctptr))((yyvsp[-1].numval).val.dblval); 
		 }
#line 1474 "y.tab.c" /* yacc.c:1648  */
    break;

  case 10:
#line 104 "expr.y" /* yacc.c:1648  */
    {
		   (yyval.numval).type=EXPR_TYPE_DBL;
		   expr_to_dbl(exprobj, &(yyvsp[-3].numval), &(yyvsp[-1].numval));
		   (yyval.numval).val.dblval = (*((func_t_ddd)(yyvsp[-5].tptr)->fnctptr))((yyvsp[-3].numval).val.dblval,(yyvsp[-1].numval).val.dblval);
		 }
#line 1484 "y.tab.c" /* yacc.c:1648  */
    break;

  case 11:
#line 110 "expr.y" /* yacc.c:1648  */
    {
		   (yyval.numval) = (*((func_t_ee)(yyvsp[-3].tptr)->fnctptr))(exprobj,(yyvsp[-1].numval));
		 }
#line 1492 "y.tab.c" /* yacc.c:1648  */
    break;

  case 12:
#line 113 "expr.y" /* yacc.c:1648  */
    { DO_MATHOP(exprobj, (yyval.numval),+,(yyvsp[-2].numval),(yyvsp[0].numval));	}
#line 1498 "y.tab.c" /* yacc.c:1648  */
    break;

  case 13:
#line 114 "expr.y" /* yacc.c:1648  */
    { DO_MATHOP(exprobj, (yyval.numval),-,(yyvsp[-2].numval),(yyvsp[0].numval));	}
#line 1504 "y.tab.c" /* yacc.c:1648  */
    break;

  case 14:
#line 115 "expr.y" /* yacc.c:1648  */
    { DO_MATHOP(exprobj, (yyval.numval),*,(yyvsp[-2].numval),(yyvsp[0].numval));	}
#line 1510 "y.tab.c" /* yacc.c:1648  */
    break;

  case 15:
#line 117 "expr.y" /* yacc.c:1648  */
    { 
		   (yyval.numval).type=EXPR_TYPE_INT;
		   expr_to_int(exprobj, &(yyvsp[-2].numval),&(yyvsp[0].numval));
		   (yyval.numval).val.intval = (yyvsp[-2].numval).val.intval % (yyvsp[0].numval).val.intval;
		 }
#line 1520 "y.tab.c" /* yacc.c:1648  */
    break;

  case 16:
#line 148 "expr.y" /* yacc.c:1648  */
    {
		   (yyval.numval).type=EXPR_TYPE_DBL;
		   expr_to_dbl(exprobj, &(yyvsp[-2].numval),&(yyvsp[0].numval));
                   if ((yyvsp[0].numval).val.dblval)
                     (yyval.numval).val.dblval = (yyvsp[-2].numval).val.dblval / (yyvsp[0].numval).val.dblval;
                   else
                     {
                       (yyval.numval).val.dblval = 0;
		       log_expr(exprobj, TMPL_LOG_ERROR, "%s\n", "division by zero");
                     }
		 }
#line 1536 "y.tab.c" /* yacc.c:1648  */
    break;

  case 17:
#line 160 "expr.y" /* yacc.c:1648  */
    { 
		   switch ((yyval.numval).type=(yyvsp[0].numval).type) {
		   case EXPR_TYPE_INT: 
		     (yyval.numval).val.intval = -(yyvsp[0].numval).val.intval;
		   ;break;
		   case EXPR_TYPE_DBL: 
		     (yyval.numval).val.dblval = -(yyvsp[0].numval).val.dblval;
		   ;break;
		   }
		 }
#line 1551 "y.tab.c" /* yacc.c:1648  */
    break;

  case 18:
#line 171 "expr.y" /* yacc.c:1648  */
    { 
		   (yyval.numval).type=EXPR_TYPE_DBL;
		   expr_to_dbl(exprobj, &(yyvsp[-2].numval),&(yyvsp[0].numval));
		   (yyval.numval).val.dblval = pow ((yyvsp[-2].numval).val.dblval, (yyvsp[0].numval).val.dblval);
                 }
#line 1561 "y.tab.c" /* yacc.c:1648  */
    break;

  case 19:
#line 177 "expr.y" /* yacc.c:1648  */
    {
		   if (exprobj->is_tt_like_logical) {
		     (yyval.numval)=(yyvsp[-2].numval);
		     switch (expr_to_int_or_dbl_logop1(exprobj, &(yyval.numval))) {
		     case EXPR_TYPE_INT: (yyval.numval)= ((yyvsp[-2].numval).val.intval ? (yyvsp[-2].numval) : (yyvsp[0].numval)); break;
		     case EXPR_TYPE_DBL: (yyval.numval)= ((yyvsp[-2].numval).val.dblval ? (yyvsp[-2].numval) : (yyvsp[0].numval)); break;
		     }
		   } else {
		     DO_LOGOP(exprobj, (yyval.numval),||,(yyvsp[-2].numval),(yyvsp[0].numval));
		   }
		 }
#line 1577 "y.tab.c" /* yacc.c:1648  */
    break;

  case 20:
#line 189 "expr.y" /* yacc.c:1648  */
    {
		   if (exprobj->is_tt_like_logical) {
		     (yyval.numval)=(yyvsp[-2].numval);
		     switch (expr_to_int_or_dbl_logop1(exprobj, &(yyval.numval))) {
		     case EXPR_TYPE_INT: (yyval.numval)= ((yyvsp[-2].numval).val.intval ? (yyvsp[0].numval) : (yyvsp[-2].numval)); break;
		     case EXPR_TYPE_DBL: (yyval.numval)= ((yyvsp[-2].numval).val.dblval ? (yyvsp[0].numval) : (yyvsp[-2].numval)); break;
		     }
		   } else {
		     DO_LOGOP(exprobj, (yyval.numval),&&,(yyvsp[-2].numval),(yyvsp[0].numval));
		   }
		 }
#line 1593 "y.tab.c" /* yacc.c:1648  */
    break;

  case 21:
#line 200 "expr.y" /* yacc.c:1648  */
    { DO_CMPOP(exprobj, (yyval.numval),>=,(yyvsp[-2].numval),(yyvsp[0].numval));	}
#line 1599 "y.tab.c" /* yacc.c:1648  */
    break;

  case 22:
#line 201 "expr.y" /* yacc.c:1648  */
    { DO_CMPOP(exprobj, (yyval.numval),<=,(yyvsp[-2].numval),(yyvsp[0].numval));	}
#line 1605 "y.tab.c" /* yacc.c:1648  */
    break;

  case 23:
#line 202 "expr.y" /* yacc.c:1648  */
    { DO_CMPOP(exprobj, (yyval.numval),!=,(yyvsp[-2].numval),(yyvsp[0].numval));	}
#line 1611 "y.tab.c" /* yacc.c:1648  */
    break;

  case 24:
#line 203 "expr.y" /* yacc.c:1648  */
    { DO_CMPOP(exprobj, (yyval.numval),==,(yyvsp[-2].numval),(yyvsp[0].numval));	}
#line 1617 "y.tab.c" /* yacc.c:1648  */
    break;

  case 25:
#line 204 "expr.y" /* yacc.c:1648  */
    { DO_CMPOP(exprobj, (yyval.numval),>,(yyvsp[-2].numval),(yyvsp[0].numval));	}
#line 1623 "y.tab.c" /* yacc.c:1648  */
    break;

  case 26:
#line 205 "expr.y" /* yacc.c:1648  */
    { DO_CMPOP(exprobj, (yyval.numval),<,(yyvsp[-2].numval),(yyvsp[0].numval));	}
#line 1629 "y.tab.c" /* yacc.c:1648  */
    break;

  case 27:
#line 206 "expr.y" /* yacc.c:1648  */
    { DO_LOGOP1(exprobj, (yyval.numval),!,(yyvsp[0].numval));		}
#line 1635 "y.tab.c" /* yacc.c:1648  */
    break;

  case 28:
#line 207 "expr.y" /* yacc.c:1648  */
    { DO_LOGOP1(exprobj, (yyval.numval),!,(yyvsp[0].numval));		}
#line 1641 "y.tab.c" /* yacc.c:1648  */
    break;

  case 29:
#line 208 "expr.y" /* yacc.c:1648  */
    { (yyval.numval) = (yyvsp[-1].numval);			}
#line 1647 "y.tab.c" /* yacc.c:1648  */
    break;

  case 30:
#line 209 "expr.y" /* yacc.c:1648  */
    { 
  expr_to_str(state, &(yyvsp[-2].numval),&(yyvsp[0].numval)); 
  (yyval.numval).type=EXPR_TYPE_INT; (yyval.numval).val.intval = pstring_ge ((yyvsp[-2].numval).val.strval,(yyvsp[0].numval).val.strval)-pstring_le ((yyvsp[-2].numval).val.strval,(yyvsp[0].numval).val.strval);
}
#line 1656 "y.tab.c" /* yacc.c:1648  */
    break;

  case 31:
#line 213 "expr.y" /* yacc.c:1648  */
    { DO_TXTOP((yyval.numval),pstring_ge,(yyvsp[-2].numval),(yyvsp[0].numval),state);}
#line 1662 "y.tab.c" /* yacc.c:1648  */
    break;

  case 32:
#line 214 "expr.y" /* yacc.c:1648  */
    { DO_TXTOP((yyval.numval),pstring_le,(yyvsp[-2].numval),(yyvsp[0].numval),state);}
#line 1668 "y.tab.c" /* yacc.c:1648  */
    break;

  case 33:
#line 215 "expr.y" /* yacc.c:1648  */
    { DO_TXTOP((yyval.numval),pstring_ne,(yyvsp[-2].numval),(yyvsp[0].numval),state);}
#line 1674 "y.tab.c" /* yacc.c:1648  */
    break;

  case 34:
#line 216 "expr.y" /* yacc.c:1648  */
    { DO_TXTOP((yyval.numval),pstring_eq,(yyvsp[-2].numval),(yyvsp[0].numval),state);}
#line 1680 "y.tab.c" /* yacc.c:1648  */
    break;

  case 35:
#line 217 "expr.y" /* yacc.c:1648  */
    { DO_TXTOP((yyval.numval),pstring_gt,(yyvsp[-2].numval),(yyvsp[0].numval),state);}
#line 1686 "y.tab.c" /* yacc.c:1648  */
    break;

  case 36:
#line 218 "expr.y" /* yacc.c:1648  */
    { DO_TXTOP((yyval.numval),pstring_lt,(yyvsp[-2].numval),(yyvsp[0].numval),state);}
#line 1692 "y.tab.c" /* yacc.c:1648  */
    break;

  case 37:
#line 219 "expr.y" /* yacc.c:1648  */
    { DO_TXTOPLOG((yyval.numval),re_like,(yyvsp[-2].numval),(yyvsp[0].numval),exprobj);}
#line 1698 "y.tab.c" /* yacc.c:1648  */
    break;

  case 38:
#line 220 "expr.y" /* yacc.c:1648  */
    { DO_TXTOPLOG((yyval.numval),re_notlike,(yyvsp[-2].numval),(yyvsp[0].numval),exprobj);}
#line 1704 "y.tab.c" /* yacc.c:1648  */
    break;

  case 39:
#line 223 "expr.y" /* yacc.c:1648  */
    {
  (yyvsp[-2].extfunc).arglist=state->param->InitExprArglistFuncPtr(state->param->expr_func_map);
  pusharg_expr_userfunc(exprobj,state->param,(yyvsp[-2].extfunc),(yyvsp[0].numval));
  (yyval.extfunc) = (yyvsp[-2].extfunc);
}
#line 1714 "y.tab.c" /* yacc.c:1648  */
    break;

  case 40:
#line 228 "expr.y" /* yacc.c:1648  */
    { pusharg_expr_userfunc(exprobj,state->param,(yyvsp[-2].extfunc),(yyvsp[0].numval)); (yyval.extfunc) = (yyvsp[-2].extfunc);	}
#line 1720 "y.tab.c" /* yacc.c:1648  */
    break;


#line 1724 "y.tab.c" /* yacc.c:1648  */
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
      yyerror (state, exprobj, expr_retval_ptr, YY_("syntax error"));
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
        yyerror (state, exprobj, expr_retval_ptr, yymsgp);
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
                      yytoken, &yylval, state, exprobj, expr_retval_ptr);
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
                  yystos[yystate], yyvsp, state, exprobj, expr_retval_ptr);
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
  yyerror (state, exprobj, expr_retval_ptr, YY_("memory exhausted"));
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
                  yytoken, &yylval, state, exprobj, expr_retval_ptr);
    }
  /* Do not reclaim the symbols of the rule whose action triggered
     this YYABORT or YYACCEPT.  */
  YYPOPSTACK (yylen);
  YY_STACK_PRINT (yyss, yyssp);
  while (yyssp != yyss)
    {
      yydestruct ("Cleanup: popping",
                  yystos[*yyssp], yyvsp, state, exprobj, expr_retval_ptr);
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
#line 232 "expr.y" /* yacc.c:1907  */


/* Called by yyparse on error.  */
static void
yyerror (struct tmplpro_state* state, struct expr_parser* exprobj, PSTRING* expr_retval_ptr, char const *s)
{
  log_expr(exprobj, TMPL_LOG_ERROR, "not a valid expression: %s\n", s);
}

#include "calc.inc"

static
const symrec_const
builtin_funcs_symrec[] =
  {
    /* built-in funcs */
    {SYMREC("sin"), BUILTIN_FNC_DD,	0,	  sin},
    {SYMREC("cos"), BUILTIN_FNC_DD,	0,	  cos},
    {SYMREC("atan"), BUILTIN_FNC_DD,	0,	 atan},
    {SYMREC("log"), BUILTIN_FNC_DD,	0,	  log},
    {SYMREC("exp"), BUILTIN_FNC_DD,	0,	  exp},
    {SYMREC("sqrt"), BUILTIN_FNC_DD,	0,	 sqrt},
    {SYMREC("atan2"), BUILTIN_FNC_DDD,	0,	atan2},
    {SYMREC("abs"), BUILTIN_FNC_EE,	0,	builtin_abs},
    {SYMREC("defined"), BUILTIN_FNC_EE,	0,	builtin_defined},
    {SYMREC("int"), BUILTIN_FNC_EE,	0,	builtin_int},
    {SYMREC("hex"), BUILTIN_FNC_EE,	0,	builtin_hex},
    {SYMREC("length"), BUILTIN_FNC_EE,	0,	builtin_length},
    {SYMREC("oct"), BUILTIN_FNC_EE,	0,	builtin_oct},
    {SYMREC("rand"), BUILTIN_FNC_EE,	0,	builtin_rand},
    {SYMREC("srand"), BUILTIN_FNC_EE,	0,	builtin_srand},
    {SYMREC("version"), BUILTIN_FNC_EE,	0,	builtin_version},
    /* end mark */
    {0, 0, 0}
  };

static
const symrec_const
builtin_ops_symrec[] =
  {
    /* built-in ops */
    {SYMREC("eq"),  strEQ,	0,	NULL},
    {SYMREC("ne"),  strNE,	0,	NULL},
    {SYMREC("gt"),  strGT,	0,	NULL},
    {SYMREC("ge"),  strGE,	0,	NULL},
    {SYMREC("lt"),  strLT,	0,	NULL},
    {SYMREC("le"),  strLE,	0,	NULL},
    {SYMREC("cmp"), strCMP,	0,	NULL},
    {SYMREC("or"),  OR,	0,	NULL},
    {SYMREC("and"),AND,	0,	NULL},
    {SYMREC("not"),NOT,	0,	NULL},
    /* end mark */
    {0, 0, 0}
  };

TMPLPRO_LOCAL
PSTRING 
parse_expr(PSTRING expression, struct tmplpro_state* state)
{
  PSTRING expr_retval;
  struct expr_parser exprobj;
  expr_retval.begin=expression.begin;
  expr_retval.endnext=expression.begin;
  exprobj.expr_curpos=expression.begin;
  exprobj.exprarea=expression;
  exprobj.state = state;
  exprobj.is_expect_quote_like=1;
  // TODO!!
  exprobj.is_tt_like_logical=0;
  yyparse (state, &exprobj, &expr_retval);
  if (NULL!=expr_retval.begin && NULL==expr_retval.endnext) log_expr(&exprobj, TMPL_LOG_ERROR, "parse_expr internal warning: %s\n", "endnext is null pointer");
  return expr_retval;
}

static
void 
log_expr(struct expr_parser* exprobj, int loglevel, const char* fmt, ...)
{
  va_list vl;
  va_start(vl, fmt);
  log_state(exprobj->state, loglevel, "in EXPR:at pos " MOD_TD " [" MOD_TD "]: ", 
	   TO_PTRDIFF_T((exprobj->expr_curpos)-(exprobj->state->top)),
	   TO_PTRDIFF_T((exprobj->expr_curpos)-(exprobj->exprarea).begin));
  tmpl_vlog(loglevel, fmt, vl);
  va_end(vl);
}

static
PSTRING 
fill_symbuf (struct expr_parser* exprobj, int is_accepted(unsigned char)) {
  /* skip first char, already tested */
  PSTRING retval = {exprobj->expr_curpos++};
  while (exprobj->expr_curpos < (exprobj->exprarea).endnext && is_accepted(*exprobj->expr_curpos)) exprobj->expr_curpos++;
  retval.endnext= exprobj->expr_curpos;
  return retval;
}

static 
int 
is_alnum_lex (unsigned char c)
{
  return (c == '_' || isalnum (c));
}

static 
int 
is_not_identifier_ext_end (unsigned char c)
{ 
  return (c != '}');
} 

#define TESTOP(c1,c2,z)  if (c1 == c) { char d=*++(exprobj->expr_curpos); if (c2 != d) return c; else (exprobj->expr_curpos)++; return z; }
#define TESTOP3(c1,c2,c3,num2,str3)  if (c1 == c) { char d=*++(exprobj->expr_curpos); if (c2 == d) {(exprobj->expr_curpos)++; return num2;} else if (c3 == d) {(exprobj->expr_curpos)++; exprobj->is_expect_quote_like=1; return str3;} else return c; }

static 
int
yylex (YYSTYPE *lvalp, struct tmplpro_state* state, struct expr_parser* exprobj)
{
  register unsigned char c = 0;
  int is_identifier_ext; 
  /* TODO: newline? */
  /* Ignore white space, get first nonwhite character.  */
  while ((exprobj->expr_curpos)<(exprobj->exprarea).endnext && ((c = *(exprobj->expr_curpos)) == ' ' || c == '\t')) (exprobj->expr_curpos)++;
  if ((exprobj->expr_curpos)>=(exprobj->exprarea).endnext) return 0;

  /* Char starts a quote => read a string */
  if ('\''==c || '"'==c || (exprobj->is_expect_quote_like && '/'==c) ) {
    PSTRING strvalue;
    unsigned char terminal_quote=c;
    int escape_flag = 0;
    c =* ++(exprobj->expr_curpos);
    strvalue.begin = exprobj->expr_curpos;
    strvalue.endnext = exprobj->expr_curpos;

    while ((exprobj->expr_curpos)<(exprobj->exprarea).endnext && c != terminal_quote) {
      /* any escaped char with \ , incl. quote */
      if ('\\' == c) {
	escape_flag = 1;
	exprobj->expr_curpos+=2;
	c =*(exprobj->expr_curpos);
      } else {
	c = * ++(exprobj->expr_curpos);
      }
    }

    strvalue.endnext = exprobj->expr_curpos;
    if ((exprobj->expr_curpos)<(exprobj->exprarea).endnext && ((c = *(exprobj->expr_curpos)) == terminal_quote)) (exprobj->expr_curpos)++;
    if (escape_flag) {
      (*lvalp).numval.type=EXPR_TYPE_UPSTR;
    } else {
      (*lvalp).numval.type=EXPR_TYPE_PSTR;
    }
    (*lvalp).numval.val.strval=strvalue;
    exprobj->is_expect_quote_like=0;
    return NUM;
  }
	
  exprobj->is_expect_quote_like=0;
  /* Char starts a number => parse the number.         */
  if (c == '.' || isdigit (c))
    {
      (*lvalp).numval=exp_read_number (exprobj, &(exprobj->expr_curpos), (exprobj->exprarea).endnext);
      return NUM;
    }

  /* 
   * Emiliano Bruni extension to Expr:
   * original HTML::Template allows almost arbitrary chars in parameter names,
   * but original HTML::Template::Expr (as to 0.04) allows only
   * var to be m![A-Za-z_][A-Za-z0-9_]*!.
   * with this extension, arbitrary chars can be used 
   * if bracketed in ${}, as, for example, EXPR="${foo.bar} eq 'a'".
   * first it was bracketing in {}, but it is changed 
   *
   * COMPATIBILITY WARNING.
   * Currently, this extension is not present in HTML::Template::Expr (as of 0.04).
   */
  /* Let's try to see if this is an identifier between two { } - Emiliano */
  is_identifier_ext = (int) (c == '{' || c == '$');

  /* Char starts an identifier => read the name.       */
  /* variables with _leading_underscore are allowed too */
  if (isalpha (c) || c=='_' || is_identifier_ext) {
    const symrec_const *s;
    PSTRING name;
    if (is_identifier_ext) {
      (exprobj->expr_curpos)++; /* jump over $ or { */
      if ('$' == c && '{' == *(exprobj->expr_curpos)) {
	(exprobj->expr_curpos)++; /* jump over { */
#ifndef ALLOW_OLD_BRACKETING_IN_EXPR
      } else {
      	log_expr(exprobj, TMPL_LOG_ERROR, "{} bracketing is deprecated. Use ${} bracketing.\n");
#endif
      }
      name=fill_symbuf(exprobj, is_not_identifier_ext_end);
      if ((exprobj->expr_curpos)<(exprobj->exprarea).endnext) (exprobj->expr_curpos)++; /* Jump the last } - Emiliano */
    } else {
      name=fill_symbuf(exprobj, is_alnum_lex);
    }
    s = getsym (builtin_ops_symrec, name);
    if (s != 0) {
      (*lvalp).tptr = s;
      return s->type;
    }

    {
      const char* next_char= exprobj->expr_curpos;
      /* optimization: funcs is always followed by ( */
      while ((next_char<(exprobj->exprarea).endnext) && isspace(*next_char)) next_char++;
      if ((*next_char)=='(') {
	/* user-defined functions have precedence over buit-in */
	if (((*lvalp).extfunc.func=(state->param->IsExprUserfncFuncPtr)(state->param->expr_func_map, name))) {
	  return EXTFUNC;
	}
	s = getsym (builtin_funcs_symrec, name);
	if (s != 0) {
	  (*lvalp).tptr = s;
	  return s->type;
	}
      }
      (*lvalp).uservar=name;
      /*log_expr(exprobj,TMPL_LOG_DEBUG2, "yylex: returned variable name %.*s\n",(int)(name.endnext-name.begin),name.begin);*/
      return VAR;
    }
  }

  TESTOP3('=','=','~',numEQ,reLIKE)
  TESTOP3('!','=','~',numNE,reNOTLIKE)
  TESTOP('>','=',numGE)
  TESTOP('<','=',numLE)
  TESTOP('&','&',AND)
  TESTOP('|','|',OR)

  /* Any other character is a token by itself. */
  (exprobj->expr_curpos)++;
  return c;
}

static
struct exprval
call_expr_userfunc(struct expr_parser* exprobj, struct tmplpro_param* param, struct user_func_call USERFUNC) {
  struct exprval emptyval = {EXPR_TYPE_PSTR};
  emptyval.val.strval.begin=NULL;
  emptyval.val.strval.endnext=NULL;
  exprobj->userfunc_call = emptyval;
  param->CallExprUserfncFuncPtr(param->ext_calluserfunc_state, USERFUNC.arglist, USERFUNC.func, &(exprobj->userfunc_call));
  if (param->debug>6) _tmplpro_expnum_debug (exprobj->userfunc_call, "EXPR: function call: returned ");
  param->FreeExprArglistFuncPtr(USERFUNC.arglist);
  USERFUNC.arglist = NULL;
  /* never happen; tmplpro_set_expr_as_* never set EXPR_TYPE_NULL *
   * if (exprobj->userfunc_call.type == EXPR_TYPE_NULL) exprobj->userfunc_call.type = EXPR_TYPE_PSTR;  */
  return exprobj->userfunc_call;
}

static
void
pusharg_expr_userfunc(struct expr_parser* exprobj, struct tmplpro_param* param, struct user_func_call USERFUNC, struct exprval arg) {
  if (arg.type == EXPR_TYPE_UPSTR) {
    arg.val.strval=expr_unescape_pstring_val(&(exprobj->state->expr_left_pbuffer),arg.val.strval);
    arg.type=EXPR_TYPE_PSTR;
  }
  exprobj->userfunc_call = arg;
  param->PushExprArglistFuncPtr(USERFUNC.arglist,&(exprobj->userfunc_call));
  if (param->debug>6) _tmplpro_expnum_debug (arg, "EXPR: arglist: pushed ");
}

#include "exprtool.inc"
#include "exprpstr.inc"
