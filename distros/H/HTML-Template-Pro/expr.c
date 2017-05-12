
/* A Bison parser, made by GNU Bison 2.4.1.  */

/* Skeleton implementation for Bison's Yacc-like parsers in C
   
      Copyright (C) 1984, 1989, 1990, 2000, 2001, 2002, 2003, 2004, 2005, 2006
   Free Software Foundation, Inc.
   
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
#define YYBISON_VERSION "2.4.1"

/* Skeleton name.  */
#define YYSKELETON_NAME "yacc.c"

/* Pure parsers.  */
#define YYPURE 1

/* Push parsers.  */
#define YYPUSH 0

/* Pull parsers.  */
#define YYPULL 1

/* Using locations.  */
#define YYLSP_NEEDED 0



/* Copy the first part of user declarations.  */

/* Line 189 of yacc.c  */
#line 7 "expr.y"

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
  

/* Line 189 of yacc.c  */
#line 95 "y.tab.c"

/* Enabling traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif

/* Enabling verbose error messages.  */
#ifdef YYERROR_VERBOSE
# undef YYERROR_VERBOSE
# define YYERROR_VERBOSE 1
#else
# define YYERROR_VERBOSE 0
#endif

/* Enabling the token table.  */
#ifndef YYTOKEN_TABLE
# define YYTOKEN_TABLE 0
#endif


/* Tokens.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
   /* Put the tokens into the symbol table, so that GDB and other debuggers
      know about them.  */
   enum yytokentype {
     NUM = 258,
     EXTFUNC = 259,
     BUILTIN_VAR = 260,
     BUILTIN_FNC_DD = 261,
     BUILTIN_FNC_DDD = 262,
     BUILTIN_FNC_EE = 263,
     VAR = 264,
     OR = 265,
     AND = 266,
     strCMP = 267,
     strNE = 268,
     strEQ = 269,
     strLE = 270,
     strLT = 271,
     strGE = 272,
     strGT = 273,
     numNE = 274,
     numEQ = 275,
     numLE = 276,
     numLT = 277,
     numGE = 278,
     numGT = 279,
     reNOTLIKE = 280,
     reLIKE = 281,
     NEG = 282,
     NOT = 283
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
#define strCMP 267
#define strNE 268
#define strEQ 269
#define strLE 270
#define strLT 271
#define strGE 272
#define strGT 273
#define numNE 274
#define numEQ 275
#define numLE 276
#define numLT 277
#define numGE 278
#define numGT 279
#define reNOTLIKE 280
#define reLIKE 281
#define NEG 282
#define NOT 283




#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
typedef union YYSTYPE
{

/* Line 214 of yacc.c  */
#line 27 "expr.y"

  struct exprval numval;   /* For returning numbers.  */
  const symrec_const  *tptr;   /* For returning symbol-table pointers.  */
  struct user_func_call extfunc;  /* for user-defined function name */
  PSTRING uservar;



/* Line 214 of yacc.c  */
#line 196 "y.tab.c"
} YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define yystype YYSTYPE /* obsolescent; will be withdrawn */
# define YYSTYPE_IS_DECLARED 1
#endif


/* Copy the second part of user declarations.  */

/* Line 264 of yacc.c  */
#line 33 "expr.y"

  /* the second section is required as we use YYSTYPE here */
  static void yyerror (struct tmplpro_state* state, struct expr_parser* exprobj, PSTRING* expr_retval_ptr, char const *);
  static int yylex (YYSTYPE *lvalp, struct tmplpro_state* state, struct expr_parser* exprobj);


/* Line 264 of yacc.c  */
#line 215 "y.tab.c"

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
#elif (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
typedef signed char yytype_int8;
#else
typedef short int yytype_int8;
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
# elif ! defined YYSIZE_T && (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
#  include <stddef.h> /* INFRINGES ON USER NAME SPACE */
#  define YYSIZE_T size_t
# else
#  define YYSIZE_T unsigned int
# endif
#endif

#define YYSIZE_MAXIMUM ((YYSIZE_T) -1)

#ifndef YY_
# if YYENABLE_NLS
#  if ENABLE_NLS
#   include <libintl.h> /* INFRINGES ON USER NAME SPACE */
#   define YY_(msgid) dgettext ("bison-runtime", msgid)
#  endif
# endif
# ifndef YY_
#  define YY_(msgid) msgid
# endif
#endif

/* Suppress unused-variable warnings by "using" E.  */
#if ! defined lint || defined __GNUC__
# define YYUSE(e) ((void) (e))
#else
# define YYUSE(e) /* empty */
#endif

/* Identity function, used to suppress warnings about constant conditions.  */
#ifndef lint
# define YYID(n) (n)
#else
#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static int
YYID (int yyi)
#else
static int
YYID (yyi)
    int yyi;
#endif
{
  return yyi;
}
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
#    if ! defined _ALLOCA_H && ! defined _STDLIB_H && (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
#     include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
#     ifndef _STDLIB_H
#      define _STDLIB_H 1
#     endif
#    endif
#   endif
#  endif
# endif

# ifdef YYSTACK_ALLOC
   /* Pacify GCC's `empty if-body' warning.  */
#  define YYSTACK_FREE(Ptr) do { /* empty */; } while (YYID (0))
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
#  if (defined __cplusplus && ! defined _STDLIB_H \
       && ! ((defined YYMALLOC || defined malloc) \
	     && (defined YYFREE || defined free)))
#   include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
#   ifndef _STDLIB_H
#    define _STDLIB_H 1
#   endif
#  endif
#  ifndef YYMALLOC
#   define YYMALLOC malloc
#   if ! defined malloc && ! defined _STDLIB_H && (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
void *malloc (YYSIZE_T); /* INFRINGES ON USER NAME SPACE */
#   endif
#  endif
#  ifndef YYFREE
#   define YYFREE free
#   if ! defined free && ! defined _STDLIB_H && (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
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

/* Copy COUNT objects from FROM to TO.  The source and destination do
   not overlap.  */
# ifndef YYCOPY
#  if defined __GNUC__ && 1 < __GNUC__
#   define YYCOPY(To, From, Count) \
      __builtin_memcpy (To, From, (Count) * sizeof (*(From)))
#  else
#   define YYCOPY(To, From, Count)		\
      do					\
	{					\
	  YYSIZE_T yyi;				\
	  for (yyi = 0; yyi < (Count); yyi++)	\
	    (To)[yyi] = (From)[yyi];		\
	}					\
      while (YYID (0))
#  endif
# endif

/* Relocate STACK from its old location to the new one.  The
   local variables YYSIZE and YYSTACKSIZE give the old and new number of
   elements in the stack, and YYPTR gives the new location of the
   stack.  Advance YYPTR to a properly aligned location for the next
   stack.  */
# define YYSTACK_RELOCATE(Stack_alloc, Stack)				\
    do									\
      {									\
	YYSIZE_T yynewbytes;						\
	YYCOPY (&yyptr->Stack_alloc, Stack, yysize);			\
	Stack = &yyptr->Stack_alloc;					\
	yynewbytes = yystacksize * sizeof (*Stack) + YYSTACK_GAP_MAXIMUM; \
	yyptr += yynewbytes / sizeof (*yyptr);				\
      }									\
    while (YYID (0))

#endif

/* YYFINAL -- State number of the termination state.  */
#define YYFINAL  23
/* YYLAST -- Last index in YYTABLE.  */
#define YYLAST   377

/* YYNTOKENS -- Number of terminals.  */
#define YYNTOKENS  41
/* YYNNTS -- Number of nonterminals.  */
#define YYNNTS  4
/* YYNRULES -- Number of rules.  */
#define YYNRULES  40
/* YYNRULES -- Number of states.  */
#define YYNSTATES  85

/* YYTRANSLATE(YYLEX) -- Bison symbol number corresponding to YYLEX.  */
#define YYUNDEFTOK  2
#define YYMAXUTOK   283

#define YYTRANSLATE(YYX)						\
  ((unsigned int) (YYX) <= YYMAXUTOK ? yytranslate[YYX] : YYUNDEFTOK)

/* YYTRANSLATE[YYLEX] -- Bison symbol number corresponding to YYLEX.  */
static const yytype_uint8 yytranslate[] =
{
       0,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,    34,     2,     2,     2,    33,     2,     2,
      39,    38,    31,    30,    40,    29,     2,    32,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
      19,     2,    20,     2,     2,     2,     2,     2,     2,     2,
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
      15,    16,    17,    18,    21,    22,    23,    24,    25,    26,
      27,    28,    35,    36
};

#if YYDEBUG
/* YYPRHS[YYN] -- Index of the first RHS symbol of rule number YYN in
   YYRHS.  */
static const yytype_uint8 yyprhs[] =
{
       0,     0,     3,     5,     7,     9,    11,    14,    18,    22,
      27,    34,    39,    43,    47,    51,    55,    59,    62,    66,
      70,    74,    78,    82,    86,    90,    94,    98,   101,   104,
     108,   112,   116,   120,   124,   128,   132,   136,   140,   144,
     148
};

/* YYRHS -- A `-1'-separated list of the rules' RHS.  */
static const yytype_int8 yyrhs[] =
{
      42,     0,    -1,    43,    -1,     3,    -1,     5,    -1,     9,
      -1,    44,    38,    -1,     4,    39,    38,    -1,     8,    39,
      38,    -1,     6,    39,    43,    38,    -1,     7,    39,    43,
      40,    43,    38,    -1,     8,    39,    43,    38,    -1,    43,
      30,    43,    -1,    43,    29,    43,    -1,    43,    31,    43,
      -1,    43,    33,    43,    -1,    43,    32,    43,    -1,    29,
      43,    -1,    43,    37,    43,    -1,    43,    10,    43,    -1,
      43,    11,    43,    -1,    43,    25,    43,    -1,    43,    23,
      43,    -1,    43,    21,    43,    -1,    43,    22,    43,    -1,
      43,    20,    43,    -1,    43,    19,    43,    -1,    34,    43,
      -1,    36,    43,    -1,    39,    43,    38,    -1,    43,    12,
      43,    -1,    43,    17,    43,    -1,    43,    15,    43,    -1,
      43,    13,    43,    -1,    43,    14,    43,    -1,    43,    18,
      43,    -1,    43,    16,    43,    -1,    43,    28,    43,    -1,
      43,    27,    43,    -1,     4,    39,    43,    -1,    44,    40,
      43,    -1
};

/* YYRLINE[YYN] -- source line where rule number YYN was defined.  */
static const yytype_uint8 yyrline[] =
{
       0,    61,    61,    69,    70,    72,    81,    85,    90,    97,
     103,   109,   113,   114,   115,   116,   147,   159,   170,   176,
     188,   200,   201,   202,   203,   204,   205,   206,   207,   208,
     209,   213,   214,   215,   216,   217,   218,   219,   220,   223,
     228
};
#endif

#if YYDEBUG || YYERROR_VERBOSE || YYTOKEN_TABLE
/* YYTNAME[SYMBOL-NUM] -- String name of the symbol SYMBOL-NUM.
   First, the terminals, then, starting at YYNTOKENS, nonterminals.  */
static const char *const yytname[] =
{
  "$end", "error", "$undefined", "NUM", "EXTFUNC", "BUILTIN_VAR",
  "BUILTIN_FNC_DD", "BUILTIN_FNC_DDD", "BUILTIN_FNC_EE", "VAR", "OR",
  "AND", "strCMP", "strNE", "strEQ", "strLE", "strLT", "strGE", "strGT",
  "'<'", "'>'", "numNE", "numEQ", "numLE", "numLT", "numGE", "numGT",
  "reNOTLIKE", "reLIKE", "'-'", "'+'", "'*'", "'/'", "'%'", "'!'", "NEG",
  "NOT", "'^'", "')'", "'('", "','", "$accept", "line", "numEXP",
  "arglist", 0
};
#endif

# ifdef YYPRINT
/* YYTOKNUM[YYLEX-NUM] -- Internal token number corresponding to
   token YYLEX-NUM.  */
static const yytype_uint16 yytoknum[] =
{
       0,   256,   257,   258,   259,   260,   261,   262,   263,   264,
     265,   266,   267,   268,   269,   270,   271,   272,   273,    60,
      62,   274,   275,   276,   277,   278,   279,   280,   281,    45,
      43,    42,    47,    37,    33,   282,   283,    94,    41,    40,
      44
};
# endif

/* YYR1[YYN] -- Symbol number of symbol that rule YYN derives.  */
static const yytype_uint8 yyr1[] =
{
       0,    41,    42,    43,    43,    43,    43,    43,    43,    43,
      43,    43,    43,    43,    43,    43,    43,    43,    43,    43,
      43,    43,    43,    43,    43,    43,    43,    43,    43,    43,
      43,    43,    43,    43,    43,    43,    43,    43,    43,    44,
      44
};

/* YYR2[YYN] -- Number of symbols composing right hand side of rule YYN.  */
static const yytype_uint8 yyr2[] =
{
       0,     2,     1,     1,     1,     1,     2,     3,     3,     4,
       6,     4,     3,     3,     3,     3,     3,     2,     3,     3,
       3,     3,     3,     3,     3,     3,     3,     2,     2,     3,
       3,     3,     3,     3,     3,     3,     3,     3,     3,     3,
       3
};

/* YYDEFACT[STATE-NAME] -- Default rule to reduce with in state
   STATE-NUM when YYTABLE doesn't specify something else to do.  Zero
   means the default is an error.  */
static const yytype_uint8 yydefact[] =
{
       0,     3,     0,     4,     0,     0,     0,     5,     0,     0,
       0,     0,     0,     2,     0,     0,     0,     0,     0,    17,
      27,    28,     0,     1,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     6,     0,     7,
      39,     0,     0,     8,     0,    29,    19,    20,    30,    33,
      34,    32,    36,    31,    35,    26,    25,    23,    24,    22,
      21,    38,    37,    13,    12,    14,    16,    15,    18,    40,
       9,     0,    11,     0,    10
};

/* YYDEFGOTO[NTERM-NUM].  */
static const yytype_int8 yydefgoto[] =
{
      -1,    12,    13,    14
};

/* YYPACT[STATE-NUM] -- Index in YYTABLE of the portion describing
   STATE-NUM.  */
#define YYPACT_NINF -35
static const yytype_int16 yypact[] =
{
      54,   -35,   -28,   -35,   -27,   -26,   -25,   -35,    54,    54,
      54,    54,     5,   231,   -34,    38,    54,    54,    46,   -22,
     -22,   -22,   115,   -35,    54,    54,    54,    54,    54,    54,
      54,    54,    54,    54,    54,    54,    54,    54,    54,    54,
      54,    54,    54,    54,    54,    54,    54,   -35,    54,   -35,
     231,   144,    84,   -35,   173,   -35,   258,   284,   310,   310,
     310,   310,   310,   310,   310,   329,   329,   329,   329,   329,
     329,   340,   340,    33,    33,   -22,   -22,   -22,   -22,   231,
     -35,    54,   -35,   202,   -35
};

/* YYPGOTO[NTERM-NUM].  */
static const yytype_int8 yypgoto[] =
{
     -35,   -35,    -8,   -35
};

/* YYTABLE[YYPACT[STATE-NUM]].  What to do in state STATE-NUM.  If
   positive, shift that token.  If negative, reduce the rule which
   number is the opposite.  If zero, do what YYDEFACT says.
   If YYTABLE_NINF, syntax error.  */
#define YYTABLE_NINF -1
static const yytype_int8 yytable[] =
{
      19,    20,    21,    22,    47,    23,    48,    50,    51,    52,
      54,    15,    16,    17,    18,    46,    56,    57,    58,    59,
      60,    61,    62,    63,    64,    65,    66,    67,    68,    69,
      70,    71,    72,    73,    74,    75,    76,    77,    78,     0,
      79,     1,     2,     3,     4,     5,     6,     7,     0,     1,
       2,     3,     4,     5,     6,     7,     0,     1,     2,     3,
       4,     5,     6,     7,    43,    44,    45,     8,     0,     0,
      46,     0,     9,    83,    10,     8,    49,    11,     0,     0,
       9,     0,    10,     8,    53,    11,     0,     0,     9,     0,
      10,     0,     0,    11,    24,    25,    26,    27,    28,    29,
      30,    31,    32,    33,    34,    35,    36,    37,     0,    38,
       0,    39,    40,    41,    42,    43,    44,    45,     0,     0,
       0,    46,     0,     0,    81,    24,    25,    26,    27,    28,
      29,    30,    31,    32,    33,    34,    35,    36,    37,     0,
      38,     0,    39,    40,    41,    42,    43,    44,    45,     0,
       0,     0,    46,    55,    24,    25,    26,    27,    28,    29,
      30,    31,    32,    33,    34,    35,    36,    37,     0,    38,
       0,    39,    40,    41,    42,    43,    44,    45,     0,     0,
       0,    46,    80,    24,    25,    26,    27,    28,    29,    30,
      31,    32,    33,    34,    35,    36,    37,     0,    38,     0,
      39,    40,    41,    42,    43,    44,    45,     0,     0,     0,
      46,    82,    24,    25,    26,    27,    28,    29,    30,    31,
      32,    33,    34,    35,    36,    37,     0,    38,     0,    39,
      40,    41,    42,    43,    44,    45,     0,     0,     0,    46,
      84,    24,    25,    26,    27,    28,    29,    30,    31,    32,
      33,    34,    35,    36,    37,     0,    38,     0,    39,    40,
      41,    42,    43,    44,    45,     0,     0,     0,    46,    25,
      26,    27,    28,    29,    30,    31,    32,    33,    34,    35,
      36,    37,     0,    38,     0,    39,    40,    41,    42,    43,
      44,    45,     0,     0,     0,    46,    26,    27,    28,    29,
      30,    31,    32,    33,    34,    35,    36,    37,     0,    38,
       0,    39,    40,    41,    42,    43,    44,    45,     0,     0,
       0,    46,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    33,
      34,    35,    36,    37,     0,    38,     0,    39,    40,    41,
      42,    43,    44,    45,     0,     0,     0,    46,    -1,    -1,
      -1,    -1,    -1,     0,    -1,     0,    39,    40,    41,    42,
      43,    44,    45,     0,     0,     0,    46,    -1,    -1,    41,
      42,    43,    44,    45,     0,     0,     0,    46
};

static const yytype_int8 yycheck[] =
{
       8,     9,    10,    11,    38,     0,    40,    15,    16,    17,
      18,    39,    39,    39,    39,    37,    24,    25,    26,    27,
      28,    29,    30,    31,    32,    33,    34,    35,    36,    37,
      38,    39,    40,    41,    42,    43,    44,    45,    46,    -1,
      48,     3,     4,     5,     6,     7,     8,     9,    -1,     3,
       4,     5,     6,     7,     8,     9,    -1,     3,     4,     5,
       6,     7,     8,     9,    31,    32,    33,    29,    -1,    -1,
      37,    -1,    34,    81,    36,    29,    38,    39,    -1,    -1,
      34,    -1,    36,    29,    38,    39,    -1,    -1,    34,    -1,
      36,    -1,    -1,    39,    10,    11,    12,    13,    14,    15,
      16,    17,    18,    19,    20,    21,    22,    23,    -1,    25,
      -1,    27,    28,    29,    30,    31,    32,    33,    -1,    -1,
      -1,    37,    -1,    -1,    40,    10,    11,    12,    13,    14,
      15,    16,    17,    18,    19,    20,    21,    22,    23,    -1,
      25,    -1,    27,    28,    29,    30,    31,    32,    33,    -1,
      -1,    -1,    37,    38,    10,    11,    12,    13,    14,    15,
      16,    17,    18,    19,    20,    21,    22,    23,    -1,    25,
      -1,    27,    28,    29,    30,    31,    32,    33,    -1,    -1,
      -1,    37,    38,    10,    11,    12,    13,    14,    15,    16,
      17,    18,    19,    20,    21,    22,    23,    -1,    25,    -1,
      27,    28,    29,    30,    31,    32,    33,    -1,    -1,    -1,
      37,    38,    10,    11,    12,    13,    14,    15,    16,    17,
      18,    19,    20,    21,    22,    23,    -1,    25,    -1,    27,
      28,    29,    30,    31,    32,    33,    -1,    -1,    -1,    37,
      38,    10,    11,    12,    13,    14,    15,    16,    17,    18,
      19,    20,    21,    22,    23,    -1,    25,    -1,    27,    28,
      29,    30,    31,    32,    33,    -1,    -1,    -1,    37,    11,
      12,    13,    14,    15,    16,    17,    18,    19,    20,    21,
      22,    23,    -1,    25,    -1,    27,    28,    29,    30,    31,
      32,    33,    -1,    -1,    -1,    37,    12,    13,    14,    15,
      16,    17,    18,    19,    20,    21,    22,    23,    -1,    25,
      -1,    27,    28,    29,    30,    31,    32,    33,    -1,    -1,
      -1,    37,    12,    13,    14,    15,    16,    17,    18,    19,
      20,    21,    22,    23,    -1,    25,    -1,    27,    28,    29,
      30,    31,    32,    33,    -1,    -1,    -1,    37,    19,    20,
      21,    22,    23,    -1,    25,    -1,    27,    28,    29,    30,
      31,    32,    33,    -1,    -1,    -1,    37,    27,    28,    29,
      30,    31,    32,    33,    -1,    -1,    -1,    37
};

/* YYSTOS[STATE-NUM] -- The (internal number of the) accessing
   symbol of state STATE-NUM.  */
static const yytype_uint8 yystos[] =
{
       0,     3,     4,     5,     6,     7,     8,     9,    29,    34,
      36,    39,    42,    43,    44,    39,    39,    39,    39,    43,
      43,    43,    43,     0,    10,    11,    12,    13,    14,    15,
      16,    17,    18,    19,    20,    21,    22,    23,    25,    27,
      28,    29,    30,    31,    32,    33,    37,    38,    40,    38,
      43,    43,    43,    38,    43,    38,    43,    43,    43,    43,
      43,    43,    43,    43,    43,    43,    43,    43,    43,    43,
      43,    43,    43,    43,    43,    43,    43,    43,    43,    43,
      38,    40,    38,    43,    38
};

#define yyerrok		(yyerrstatus = 0)
#define yyclearin	(yychar = YYEMPTY)
#define YYEMPTY		(-2)
#define YYEOF		0

#define YYACCEPT	goto yyacceptlab
#define YYABORT		goto yyabortlab
#define YYERROR		goto yyerrorlab


/* Like YYERROR except do call yyerror.  This remains here temporarily
   to ease the transition to the new meaning of YYERROR, for GCC.
   Once GCC version 2 has supplanted version 1, this can go.  */

#define YYFAIL		goto yyerrlab

#define YYRECOVERING()  (!!yyerrstatus)

#define YYBACKUP(Token, Value)					\
do								\
  if (yychar == YYEMPTY && yylen == 1)				\
    {								\
      yychar = (Token);						\
      yylval = (Value);						\
      yytoken = YYTRANSLATE (yychar);				\
      YYPOPSTACK (1);						\
      goto yybackup;						\
    }								\
  else								\
    {								\
      yyerror (state, exprobj, expr_retval_ptr, YY_("syntax error: cannot back up")); \
      YYERROR;							\
    }								\
while (YYID (0))


#define YYTERROR	1
#define YYERRCODE	256


/* YYLLOC_DEFAULT -- Set CURRENT to span from RHS[1] to RHS[N].
   If N is 0, then set CURRENT to the empty location which ends
   the previous symbol: RHS[0] (always defined).  */

#define YYRHSLOC(Rhs, K) ((Rhs)[K])
#ifndef YYLLOC_DEFAULT
# define YYLLOC_DEFAULT(Current, Rhs, N)				\
    do									\
      if (YYID (N))                                                    \
	{								\
	  (Current).first_line   = YYRHSLOC (Rhs, 1).first_line;	\
	  (Current).first_column = YYRHSLOC (Rhs, 1).first_column;	\
	  (Current).last_line    = YYRHSLOC (Rhs, N).last_line;		\
	  (Current).last_column  = YYRHSLOC (Rhs, N).last_column;	\
	}								\
      else								\
	{								\
	  (Current).first_line   = (Current).last_line   =		\
	    YYRHSLOC (Rhs, 0).last_line;				\
	  (Current).first_column = (Current).last_column =		\
	    YYRHSLOC (Rhs, 0).last_column;				\
	}								\
    while (YYID (0))
#endif


/* YY_LOCATION_PRINT -- Print the location on the stream.
   This macro was not mandated originally: define only if we know
   we won't break user code: when these are the locations we know.  */

#ifndef YY_LOCATION_PRINT
# if YYLTYPE_IS_TRIVIAL
#  define YY_LOCATION_PRINT(File, Loc)			\
     fprintf (File, "%d.%d-%d.%d",			\
	      (Loc).first_line, (Loc).first_column,	\
	      (Loc).last_line,  (Loc).last_column)
# else
#  define YY_LOCATION_PRINT(File, Loc) ((void) 0)
# endif
#endif


/* YYLEX -- calling `yylex' with the right arguments.  */

#ifdef YYLEX_PARAM
# define YYLEX yylex (&yylval, YYLEX_PARAM)
#else
# define YYLEX yylex (&yylval, state, exprobj)
#endif

/* Enable debugging if requested.  */
#if YYDEBUG

# ifndef YYFPRINTF
#  include <stdio.h> /* INFRINGES ON USER NAME SPACE */
#  define YYFPRINTF fprintf
# endif

# define YYDPRINTF(Args)			\
do {						\
  if (yydebug)					\
    YYFPRINTF Args;				\
} while (YYID (0))

# define YY_SYMBOL_PRINT(Title, Type, Value, Location)			  \
do {									  \
  if (yydebug)								  \
    {									  \
      YYFPRINTF (stderr, "%s ", Title);					  \
      yy_symbol_print (stderr,						  \
		  Type, Value, state, exprobj, expr_retval_ptr); \
      YYFPRINTF (stderr, "\n");						  \
    }									  \
} while (YYID (0))


/*--------------------------------.
| Print this symbol on YYOUTPUT.  |
`--------------------------------*/

/*ARGSUSED*/
#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static void
yy_symbol_value_print (FILE *yyoutput, int yytype, YYSTYPE const * const yyvaluep, struct tmplpro_state* state, struct expr_parser* exprobj, PSTRING* expr_retval_ptr)
#else
static void
yy_symbol_value_print (yyoutput, yytype, yyvaluep, state, exprobj, expr_retval_ptr)
    FILE *yyoutput;
    int yytype;
    YYSTYPE const * const yyvaluep;
    struct tmplpro_state* state;
    struct expr_parser* exprobj;
    PSTRING* expr_retval_ptr;
#endif
{
  if (!yyvaluep)
    return;
  YYUSE (state);
  YYUSE (exprobj);
  YYUSE (expr_retval_ptr);
# ifdef YYPRINT
  if (yytype < YYNTOKENS)
    YYPRINT (yyoutput, yytoknum[yytype], *yyvaluep);
# else
  YYUSE (yyoutput);
# endif
  switch (yytype)
    {
      default:
	break;
    }
}


/*--------------------------------.
| Print this symbol on YYOUTPUT.  |
`--------------------------------*/

#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static void
yy_symbol_print (FILE *yyoutput, int yytype, YYSTYPE const * const yyvaluep, struct tmplpro_state* state, struct expr_parser* exprobj, PSTRING* expr_retval_ptr)
#else
static void
yy_symbol_print (yyoutput, yytype, yyvaluep, state, exprobj, expr_retval_ptr)
    FILE *yyoutput;
    int yytype;
    YYSTYPE const * const yyvaluep;
    struct tmplpro_state* state;
    struct expr_parser* exprobj;
    PSTRING* expr_retval_ptr;
#endif
{
  if (yytype < YYNTOKENS)
    YYFPRINTF (yyoutput, "token %s (", yytname[yytype]);
  else
    YYFPRINTF (yyoutput, "nterm %s (", yytname[yytype]);

  yy_symbol_value_print (yyoutput, yytype, yyvaluep, state, exprobj, expr_retval_ptr);
  YYFPRINTF (yyoutput, ")");
}

/*------------------------------------------------------------------.
| yy_stack_print -- Print the state stack from its BOTTOM up to its |
| TOP (included).                                                   |
`------------------------------------------------------------------*/

#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static void
yy_stack_print (yytype_int16 *yybottom, yytype_int16 *yytop)
#else
static void
yy_stack_print (yybottom, yytop)
    yytype_int16 *yybottom;
    yytype_int16 *yytop;
#endif
{
  YYFPRINTF (stderr, "Stack now");
  for (; yybottom <= yytop; yybottom++)
    {
      int yybot = *yybottom;
      YYFPRINTF (stderr, " %d", yybot);
    }
  YYFPRINTF (stderr, "\n");
}

# define YY_STACK_PRINT(Bottom, Top)				\
do {								\
  if (yydebug)							\
    yy_stack_print ((Bottom), (Top));				\
} while (YYID (0))


/*------------------------------------------------.
| Report that the YYRULE is going to be reduced.  |
`------------------------------------------------*/

#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static void
yy_reduce_print (YYSTYPE *yyvsp, int yyrule, struct tmplpro_state* state, struct expr_parser* exprobj, PSTRING* expr_retval_ptr)
#else
static void
yy_reduce_print (yyvsp, yyrule, state, exprobj, expr_retval_ptr)
    YYSTYPE *yyvsp;
    int yyrule;
    struct tmplpro_state* state;
    struct expr_parser* exprobj;
    PSTRING* expr_retval_ptr;
#endif
{
  int yynrhs = yyr2[yyrule];
  int yyi;
  unsigned long int yylno = yyrline[yyrule];
  YYFPRINTF (stderr, "Reducing stack by rule %d (line %lu):\n",
	     yyrule - 1, yylno);
  /* The symbols being reduced.  */
  for (yyi = 0; yyi < yynrhs; yyi++)
    {
      YYFPRINTF (stderr, "   $%d = ", yyi + 1);
      yy_symbol_print (stderr, yyrhs[yyprhs[yyrule] + yyi],
		       &(yyvsp[(yyi + 1) - (yynrhs)])
		       		       , state, exprobj, expr_retval_ptr);
      YYFPRINTF (stderr, "\n");
    }
}

# define YY_REDUCE_PRINT(Rule)		\
do {					\
  if (yydebug)				\
    yy_reduce_print (yyvsp, Rule, state, exprobj, expr_retval_ptr); \
} while (YYID (0))

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
#ifndef	YYINITDEPTH
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
#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static YYSIZE_T
yystrlen (const char *yystr)
#else
static YYSIZE_T
yystrlen (yystr)
    const char *yystr;
#endif
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
#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static char *
yystpcpy (char *yydest, const char *yysrc)
#else
static char *
yystpcpy (yydest, yysrc)
    char *yydest;
    const char *yysrc;
#endif
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

/* Copy into YYRESULT an error message about the unexpected token
   YYCHAR while in state YYSTATE.  Return the number of bytes copied,
   including the terminating null byte.  If YYRESULT is null, do not
   copy anything; just return the number of bytes that would be
   copied.  As a special case, return 0 if an ordinary "syntax error"
   message will do.  Return YYSIZE_MAXIMUM if overflow occurs during
   size calculation.  */
static YYSIZE_T
yysyntax_error (char *yyresult, int yystate, int yychar)
{
  int yyn = yypact[yystate];

  if (! (YYPACT_NINF < yyn && yyn <= YYLAST))
    return 0;
  else
    {
      int yytype = YYTRANSLATE (yychar);
      YYSIZE_T yysize0 = yytnamerr (0, yytname[yytype]);
      YYSIZE_T yysize = yysize0;
      YYSIZE_T yysize1;
      int yysize_overflow = 0;
      enum { YYERROR_VERBOSE_ARGS_MAXIMUM = 5 };
      char const *yyarg[YYERROR_VERBOSE_ARGS_MAXIMUM];
      int yyx;

# if 0
      /* This is so xgettext sees the translatable formats that are
	 constructed on the fly.  */
      YY_("syntax error, unexpected %s");
      YY_("syntax error, unexpected %s, expecting %s");
      YY_("syntax error, unexpected %s, expecting %s or %s");
      YY_("syntax error, unexpected %s, expecting %s or %s or %s");
      YY_("syntax error, unexpected %s, expecting %s or %s or %s or %s");
# endif
      char *yyfmt;
      char const *yyf;
      static char const yyunexpected[] = "syntax error, unexpected %s";
      static char const yyexpecting[] = ", expecting %s";
      static char const yyor[] = " or %s";
      char yyformat[sizeof yyunexpected
		    + sizeof yyexpecting - 1
		    + ((YYERROR_VERBOSE_ARGS_MAXIMUM - 2)
		       * (sizeof yyor - 1))];
      char const *yyprefix = yyexpecting;

      /* Start YYX at -YYN if negative to avoid negative indexes in
	 YYCHECK.  */
      int yyxbegin = yyn < 0 ? -yyn : 0;

      /* Stay within bounds of both yycheck and yytname.  */
      int yychecklim = YYLAST - yyn + 1;
      int yyxend = yychecklim < YYNTOKENS ? yychecklim : YYNTOKENS;
      int yycount = 1;

      yyarg[0] = yytname[yytype];
      yyfmt = yystpcpy (yyformat, yyunexpected);

      for (yyx = yyxbegin; yyx < yyxend; ++yyx)
	if (yycheck[yyx + yyn] == yyx && yyx != YYTERROR)
	  {
	    if (yycount == YYERROR_VERBOSE_ARGS_MAXIMUM)
	      {
		yycount = 1;
		yysize = yysize0;
		yyformat[sizeof yyunexpected - 1] = '\0';
		break;
	      }
	    yyarg[yycount++] = yytname[yyx];
	    yysize1 = yysize + yytnamerr (0, yytname[yyx]);
	    yysize_overflow |= (yysize1 < yysize);
	    yysize = yysize1;
	    yyfmt = yystpcpy (yyfmt, yyprefix);
	    yyprefix = yyor;
	  }

      yyf = YY_(yyformat);
      yysize1 = yysize + yystrlen (yyf);
      yysize_overflow |= (yysize1 < yysize);
      yysize = yysize1;

      if (yysize_overflow)
	return YYSIZE_MAXIMUM;

      if (yyresult)
	{
	  /* Avoid sprintf, as that infringes on the user's name space.
	     Don't have undefined behavior even if the translation
	     produced a string with the wrong number of "%s"s.  */
	  char *yyp = yyresult;
	  int yyi = 0;
	  while ((*yyp = *yyf) != '\0')
	    {
	      if (*yyp == '%' && yyf[1] == 's' && yyi < yycount)
		{
		  yyp += yytnamerr (yyp, yyarg[yyi++]);
		  yyf += 2;
		}
	      else
		{
		  yyp++;
		  yyf++;
		}
	    }
	}
      return yysize;
    }
}
#endif /* YYERROR_VERBOSE */


/*-----------------------------------------------.
| Release the memory associated to this symbol.  |
`-----------------------------------------------*/

/*ARGSUSED*/
#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static void
yydestruct (const char *yymsg, int yytype, YYSTYPE *yyvaluep, struct tmplpro_state* state, struct expr_parser* exprobj, PSTRING* expr_retval_ptr)
#else
static void
yydestruct (yymsg, yytype, yyvaluep, state, exprobj, expr_retval_ptr)
    const char *yymsg;
    int yytype;
    YYSTYPE *yyvaluep;
    struct tmplpro_state* state;
    struct expr_parser* exprobj;
    PSTRING* expr_retval_ptr;
#endif
{
  YYUSE (yyvaluep);
  YYUSE (state);
  YYUSE (exprobj);
  YYUSE (expr_retval_ptr);

  if (!yymsg)
    yymsg = "Deleting";
  YY_SYMBOL_PRINT (yymsg, yytype, yyvaluep, yylocationp);

  switch (yytype)
    {

      default:
	break;
    }
}

/* Prevent warnings from -Wmissing-prototypes.  */
#ifdef YYPARSE_PARAM
#if defined __STDC__ || defined __cplusplus
int yyparse (void *YYPARSE_PARAM);
#else
int yyparse ();
#endif
#else /* ! YYPARSE_PARAM */
#if defined __STDC__ || defined __cplusplus
int yyparse (struct tmplpro_state* state, struct expr_parser* exprobj, PSTRING* expr_retval_ptr);
#else
int yyparse ();
#endif
#endif /* ! YYPARSE_PARAM */





/*-------------------------.
| yyparse or yypush_parse.  |
`-------------------------*/

#ifdef YYPARSE_PARAM
#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
int
yyparse (void *YYPARSE_PARAM)
#else
int
yyparse (YYPARSE_PARAM)
    void *YYPARSE_PARAM;
#endif
#else /* ! YYPARSE_PARAM */
#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
int
yyparse (struct tmplpro_state* state, struct expr_parser* exprobj, PSTRING* expr_retval_ptr)
#else
int
yyparse (state, exprobj, expr_retval_ptr)
    struct tmplpro_state* state;
    struct expr_parser* exprobj;
    PSTRING* expr_retval_ptr;
#endif
#endif
{
/* The lookahead symbol.  */
int yychar;

/* The semantic value of the lookahead symbol.  */
YYSTYPE yylval;

    /* Number of syntax errors so far.  */
    int yynerrs;

    int yystate;
    /* Number of tokens to shift before error messages enabled.  */
    int yyerrstatus;

    /* The stacks and their tools:
       `yyss': related to states.
       `yyvs': related to semantic values.

       Refer to the stacks thru separate pointers, to allow yyoverflow
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
  int yytoken;
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

  yytoken = 0;
  yyss = yyssa;
  yyvs = yyvsa;
  yystacksize = YYINITDEPTH;

  YYDPRINTF ((stderr, "Starting parse\n"));

  yystate = 0;
  yyerrstatus = 0;
  yynerrs = 0;
  yychar = YYEMPTY; /* Cause a token to be read.  */

  /* Initialize stack pointers.
     Waste one element of value and location stack
     so that they stay on the same level as the state stack.
     The wasted elements are never initialized.  */
  yyssp = yyss;
  yyvsp = yyvs;

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
  if (yyn == YYPACT_NINF)
    goto yydefault;

  /* Not known => get a lookahead token if don't already have one.  */

  /* YYCHAR is either YYEMPTY or YYEOF or a valid lookahead symbol.  */
  if (yychar == YYEMPTY)
    {
      YYDPRINTF ((stderr, "Reading a token: "));
      yychar = YYLEX;
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
      if (yyn == 0 || yyn == YYTABLE_NINF)
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
  *++yyvsp = yylval;

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
     `$$ = $1'.

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

/* Line 1455 of yacc.c  */
#line 62 "expr.y"
    { 
		   expr_to_str1(state, &(yyvsp[(1) - (1)].numval));
		   *expr_retval_ptr=(yyvsp[(1) - (1)].numval).val.strval;
		 }
    break;

  case 3:

/* Line 1455 of yacc.c  */
#line 69 "expr.y"
    { (yyval.numval) = (yyvsp[(1) - (1)].numval);			}
    break;

  case 4:

/* Line 1455 of yacc.c  */
#line 70 "expr.y"
    { (yyval.numval).type=EXPR_TYPE_DBL; (yyval.numval).val.dblval = (yyvsp[(1) - (1)].tptr)->var; }
    break;

  case 5:

/* Line 1455 of yacc.c  */
#line 72 "expr.y"
    {
		  PSTRING varvalue=_get_variable_value(state->param, (yyvsp[(1) - (1)].uservar));
		  if (varvalue.begin==NULL) {
		    int loglevel = state->param->warn_unused ? TMPL_LOG_ERROR : TMPL_LOG_INFO;
		    log_expr(exprobj,loglevel, "non-initialized variable %.*s\n",(int)((yyvsp[(1) - (1)].uservar).endnext-(yyvsp[(1) - (1)].uservar).begin),(yyvsp[(1) - (1)].uservar).begin);
		  }
		  (yyval.numval).type=EXPR_TYPE_PSTR;
		  (yyval.numval).val.strval=varvalue;
  }
    break;

  case 6:

/* Line 1455 of yacc.c  */
#line 82 "expr.y"
    {
		   (yyval.numval) = call_expr_userfunc(exprobj, state->param, (yyvsp[(1) - (2)].extfunc));
		 }
    break;

  case 7:

/* Line 1455 of yacc.c  */
#line 86 "expr.y"
    {
		   (yyvsp[(1) - (3)].extfunc).arglist=state->param->InitExprArglistFuncPtr(state->param->ext_calluserfunc_state);
		   (yyval.numval) = call_expr_userfunc(exprobj, state->param, (yyvsp[(1) - (3)].extfunc));
		 }
    break;

  case 8:

/* Line 1455 of yacc.c  */
#line 91 "expr.y"
    {
		   struct exprval e = NEW_EXPRVAL(EXPR_TYPE_PSTR);
		   e.val.strval.begin = NULL;
		   e.val.strval.endnext = NULL;
		   (yyval.numval) = (*((func_t_ee)(yyvsp[(1) - (3)].tptr)->fnctptr))(exprobj, e);
		 }
    break;

  case 9:

/* Line 1455 of yacc.c  */
#line 98 "expr.y"
    {
		   (yyval.numval).type=EXPR_TYPE_DBL;
		   expr_to_dbl1(exprobj, &(yyvsp[(3) - (4)].numval));
		   (yyval.numval).val.dblval = (*((func_t_dd)(yyvsp[(1) - (4)].tptr)->fnctptr))((yyvsp[(3) - (4)].numval).val.dblval); 
		 }
    break;

  case 10:

/* Line 1455 of yacc.c  */
#line 104 "expr.y"
    {
		   (yyval.numval).type=EXPR_TYPE_DBL;
		   expr_to_dbl(exprobj, &(yyvsp[(3) - (6)].numval), &(yyvsp[(5) - (6)].numval));
		   (yyval.numval).val.dblval = (*((func_t_ddd)(yyvsp[(1) - (6)].tptr)->fnctptr))((yyvsp[(3) - (6)].numval).val.dblval,(yyvsp[(5) - (6)].numval).val.dblval);
		 }
    break;

  case 11:

/* Line 1455 of yacc.c  */
#line 110 "expr.y"
    {
		   (yyval.numval) = (*((func_t_ee)(yyvsp[(1) - (4)].tptr)->fnctptr))(exprobj,(yyvsp[(3) - (4)].numval));
		 }
    break;

  case 12:

/* Line 1455 of yacc.c  */
#line 113 "expr.y"
    { DO_MATHOP(exprobj, (yyval.numval),+,(yyvsp[(1) - (3)].numval),(yyvsp[(3) - (3)].numval));	}
    break;

  case 13:

/* Line 1455 of yacc.c  */
#line 114 "expr.y"
    { DO_MATHOP(exprobj, (yyval.numval),-,(yyvsp[(1) - (3)].numval),(yyvsp[(3) - (3)].numval));	}
    break;

  case 14:

/* Line 1455 of yacc.c  */
#line 115 "expr.y"
    { DO_MATHOP(exprobj, (yyval.numval),*,(yyvsp[(1) - (3)].numval),(yyvsp[(3) - (3)].numval));	}
    break;

  case 15:

/* Line 1455 of yacc.c  */
#line 117 "expr.y"
    { 
		   (yyval.numval).type=EXPR_TYPE_INT;
		   expr_to_int(exprobj, &(yyvsp[(1) - (3)].numval),&(yyvsp[(3) - (3)].numval));
		   (yyval.numval).val.intval = (yyvsp[(1) - (3)].numval).val.intval % (yyvsp[(3) - (3)].numval).val.intval;
		 }
    break;

  case 16:

/* Line 1455 of yacc.c  */
#line 148 "expr.y"
    {
		   (yyval.numval).type=EXPR_TYPE_DBL;
		   expr_to_dbl(exprobj, &(yyvsp[(1) - (3)].numval),&(yyvsp[(3) - (3)].numval));
                   if ((yyvsp[(3) - (3)].numval).val.dblval)
                     (yyval.numval).val.dblval = (yyvsp[(1) - (3)].numval).val.dblval / (yyvsp[(3) - (3)].numval).val.dblval;
                   else
                     {
                       (yyval.numval).val.dblval = 0;
		       log_expr(exprobj, TMPL_LOG_ERROR, "%s\n", "division by zero");
                     }
		 }
    break;

  case 17:

/* Line 1455 of yacc.c  */
#line 160 "expr.y"
    { 
		   switch ((yyval.numval).type=(yyvsp[(2) - (2)].numval).type) {
		   case EXPR_TYPE_INT: 
		     (yyval.numval).val.intval = -(yyvsp[(2) - (2)].numval).val.intval;
		   ;break;
		   case EXPR_TYPE_DBL: 
		     (yyval.numval).val.dblval = -(yyvsp[(2) - (2)].numval).val.dblval;
		   ;break;
		   }
		 }
    break;

  case 18:

/* Line 1455 of yacc.c  */
#line 171 "expr.y"
    { 
		   (yyval.numval).type=EXPR_TYPE_DBL;
		   expr_to_dbl(exprobj, &(yyvsp[(1) - (3)].numval),&(yyvsp[(3) - (3)].numval));
		   (yyval.numval).val.dblval = pow ((yyvsp[(1) - (3)].numval).val.dblval, (yyvsp[(3) - (3)].numval).val.dblval);
                 }
    break;

  case 19:

/* Line 1455 of yacc.c  */
#line 177 "expr.y"
    {
		   if (exprobj->is_tt_like_logical) {
		     (yyval.numval)=(yyvsp[(1) - (3)].numval);
		     switch (expr_to_int_or_dbl_logop1(exprobj, &(yyval.numval))) {
		     case EXPR_TYPE_INT: (yyval.numval)= ((yyvsp[(1) - (3)].numval).val.intval ? (yyvsp[(1) - (3)].numval) : (yyvsp[(3) - (3)].numval)); break;
		     case EXPR_TYPE_DBL: (yyval.numval)= ((yyvsp[(1) - (3)].numval).val.dblval ? (yyvsp[(1) - (3)].numval) : (yyvsp[(3) - (3)].numval)); break;
		     }
		   } else {
		     DO_LOGOP(exprobj, (yyval.numval),||,(yyvsp[(1) - (3)].numval),(yyvsp[(3) - (3)].numval));
		   }
		 }
    break;

  case 20:

/* Line 1455 of yacc.c  */
#line 189 "expr.y"
    {
		   if (exprobj->is_tt_like_logical) {
		     (yyval.numval)=(yyvsp[(1) - (3)].numval);
		     switch (expr_to_int_or_dbl_logop1(exprobj, &(yyval.numval))) {
		     case EXPR_TYPE_INT: (yyval.numval)= ((yyvsp[(1) - (3)].numval).val.intval ? (yyvsp[(3) - (3)].numval) : (yyvsp[(1) - (3)].numval)); break;
		     case EXPR_TYPE_DBL: (yyval.numval)= ((yyvsp[(1) - (3)].numval).val.dblval ? (yyvsp[(3) - (3)].numval) : (yyvsp[(1) - (3)].numval)); break;
		     }
		   } else {
		     DO_LOGOP(exprobj, (yyval.numval),&&,(yyvsp[(1) - (3)].numval),(yyvsp[(3) - (3)].numval));
		   }
		 }
    break;

  case 21:

/* Line 1455 of yacc.c  */
#line 200 "expr.y"
    { DO_CMPOP(exprobj, (yyval.numval),>=,(yyvsp[(1) - (3)].numval),(yyvsp[(3) - (3)].numval));	}
    break;

  case 22:

/* Line 1455 of yacc.c  */
#line 201 "expr.y"
    { DO_CMPOP(exprobj, (yyval.numval),<=,(yyvsp[(1) - (3)].numval),(yyvsp[(3) - (3)].numval));	}
    break;

  case 23:

/* Line 1455 of yacc.c  */
#line 202 "expr.y"
    { DO_CMPOP(exprobj, (yyval.numval),!=,(yyvsp[(1) - (3)].numval),(yyvsp[(3) - (3)].numval));	}
    break;

  case 24:

/* Line 1455 of yacc.c  */
#line 203 "expr.y"
    { DO_CMPOP(exprobj, (yyval.numval),==,(yyvsp[(1) - (3)].numval),(yyvsp[(3) - (3)].numval));	}
    break;

  case 25:

/* Line 1455 of yacc.c  */
#line 204 "expr.y"
    { DO_CMPOP(exprobj, (yyval.numval),>,(yyvsp[(1) - (3)].numval),(yyvsp[(3) - (3)].numval));	}
    break;

  case 26:

/* Line 1455 of yacc.c  */
#line 205 "expr.y"
    { DO_CMPOP(exprobj, (yyval.numval),<,(yyvsp[(1) - (3)].numval),(yyvsp[(3) - (3)].numval));	}
    break;

  case 27:

/* Line 1455 of yacc.c  */
#line 206 "expr.y"
    { DO_LOGOP1(exprobj, (yyval.numval),!,(yyvsp[(2) - (2)].numval));		}
    break;

  case 28:

/* Line 1455 of yacc.c  */
#line 207 "expr.y"
    { DO_LOGOP1(exprobj, (yyval.numval),!,(yyvsp[(2) - (2)].numval));		}
    break;

  case 29:

/* Line 1455 of yacc.c  */
#line 208 "expr.y"
    { (yyval.numval) = (yyvsp[(2) - (3)].numval);			}
    break;

  case 30:

/* Line 1455 of yacc.c  */
#line 209 "expr.y"
    { 
  expr_to_str(state, &(yyvsp[(1) - (3)].numval),&(yyvsp[(3) - (3)].numval)); 
  (yyval.numval).type=EXPR_TYPE_INT; (yyval.numval).val.intval = pstring_ge ((yyvsp[(1) - (3)].numval).val.strval,(yyvsp[(3) - (3)].numval).val.strval)-pstring_le ((yyvsp[(1) - (3)].numval).val.strval,(yyvsp[(3) - (3)].numval).val.strval);
}
    break;

  case 31:

/* Line 1455 of yacc.c  */
#line 213 "expr.y"
    { DO_TXTOP((yyval.numval),pstring_ge,(yyvsp[(1) - (3)].numval),(yyvsp[(3) - (3)].numval),state);}
    break;

  case 32:

/* Line 1455 of yacc.c  */
#line 214 "expr.y"
    { DO_TXTOP((yyval.numval),pstring_le,(yyvsp[(1) - (3)].numval),(yyvsp[(3) - (3)].numval),state);}
    break;

  case 33:

/* Line 1455 of yacc.c  */
#line 215 "expr.y"
    { DO_TXTOP((yyval.numval),pstring_ne,(yyvsp[(1) - (3)].numval),(yyvsp[(3) - (3)].numval),state);}
    break;

  case 34:

/* Line 1455 of yacc.c  */
#line 216 "expr.y"
    { DO_TXTOP((yyval.numval),pstring_eq,(yyvsp[(1) - (3)].numval),(yyvsp[(3) - (3)].numval),state);}
    break;

  case 35:

/* Line 1455 of yacc.c  */
#line 217 "expr.y"
    { DO_TXTOP((yyval.numval),pstring_gt,(yyvsp[(1) - (3)].numval),(yyvsp[(3) - (3)].numval),state);}
    break;

  case 36:

/* Line 1455 of yacc.c  */
#line 218 "expr.y"
    { DO_TXTOP((yyval.numval),pstring_lt,(yyvsp[(1) - (3)].numval),(yyvsp[(3) - (3)].numval),state);}
    break;

  case 37:

/* Line 1455 of yacc.c  */
#line 219 "expr.y"
    { DO_TXTOPLOG((yyval.numval),re_like,(yyvsp[(1) - (3)].numval),(yyvsp[(3) - (3)].numval),exprobj);}
    break;

  case 38:

/* Line 1455 of yacc.c  */
#line 220 "expr.y"
    { DO_TXTOPLOG((yyval.numval),re_notlike,(yyvsp[(1) - (3)].numval),(yyvsp[(3) - (3)].numval),exprobj);}
    break;

  case 39:

/* Line 1455 of yacc.c  */
#line 223 "expr.y"
    {
  (yyvsp[(1) - (3)].extfunc).arglist=state->param->InitExprArglistFuncPtr(state->param->expr_func_map);
  pusharg_expr_userfunc(exprobj,state->param,(yyvsp[(1) - (3)].extfunc),(yyvsp[(3) - (3)].numval));
  (yyval.extfunc) = (yyvsp[(1) - (3)].extfunc);
}
    break;

  case 40:

/* Line 1455 of yacc.c  */
#line 228 "expr.y"
    { pusharg_expr_userfunc(exprobj,state->param,(yyvsp[(1) - (3)].extfunc),(yyvsp[(3) - (3)].numval)); (yyval.extfunc) = (yyvsp[(1) - (3)].extfunc);	}
    break;



/* Line 1455 of yacc.c  */
#line 1910 "y.tab.c"
      default: break;
    }
  YY_SYMBOL_PRINT ("-> $$ =", yyr1[yyn], &yyval, &yyloc);

  YYPOPSTACK (yylen);
  yylen = 0;
  YY_STACK_PRINT (yyss, yyssp);

  *++yyvsp = yyval;

  /* Now `shift' the result of the reduction.  Determine what state
     that goes to, based on the state we popped back to and the rule
     number reduced by.  */

  yyn = yyr1[yyn];

  yystate = yypgoto[yyn - YYNTOKENS] + *yyssp;
  if (0 <= yystate && yystate <= YYLAST && yycheck[yystate] == *yyssp)
    yystate = yytable[yystate];
  else
    yystate = yydefgoto[yyn - YYNTOKENS];

  goto yynewstate;


/*------------------------------------.
| yyerrlab -- here on detecting error |
`------------------------------------*/
yyerrlab:
  /* If not already recovering from an error, report this error.  */
  if (!yyerrstatus)
    {
      ++yynerrs;
#if ! YYERROR_VERBOSE
      yyerror (state, exprobj, expr_retval_ptr, YY_("syntax error"));
#else
      {
	YYSIZE_T yysize = yysyntax_error (0, yystate, yychar);
	if (yymsg_alloc < yysize && yymsg_alloc < YYSTACK_ALLOC_MAXIMUM)
	  {
	    YYSIZE_T yyalloc = 2 * yysize;
	    if (! (yysize <= yyalloc && yyalloc <= YYSTACK_ALLOC_MAXIMUM))
	      yyalloc = YYSTACK_ALLOC_MAXIMUM;
	    if (yymsg != yymsgbuf)
	      YYSTACK_FREE (yymsg);
	    yymsg = (char *) YYSTACK_ALLOC (yyalloc);
	    if (yymsg)
	      yymsg_alloc = yyalloc;
	    else
	      {
		yymsg = yymsgbuf;
		yymsg_alloc = sizeof yymsgbuf;
	      }
	  }

	if (0 < yysize && yysize <= yymsg_alloc)
	  {
	    (void) yysyntax_error (yymsg, yystate, yychar);
	    yyerror (state, exprobj, expr_retval_ptr, yymsg);
	  }
	else
	  {
	    yyerror (state, exprobj, expr_retval_ptr, YY_("syntax error"));
	    if (yysize != 0)
	      goto yyexhaustedlab;
	  }
      }
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

  /* Do not reclaim the symbols of the rule which action triggered
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
  yyerrstatus = 3;	/* Each real token shifted decrements this.  */

  for (;;)
    {
      yyn = yypact[yystate];
      if (yyn != YYPACT_NINF)
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

  *++yyvsp = yylval;


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

#if !defined(yyoverflow) || YYERROR_VERBOSE
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
     yydestruct ("Cleanup: discarding lookahead",
		 yytoken, &yylval, state, exprobj, expr_retval_ptr);
  /* Do not reclaim the symbols of the rule which action triggered
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
  /* Make sure YYID is used.  */
  return YYID (yyresult);
}



/* Line 1675 of yacc.c  */
#line 232 "expr.y"


/* Called by yyparse on error.  */
static void
yyerror (struct tmplpro_state* state, struct expr_parser* exprobj, PSTRING* expr_retval_ptr, char const *s)
{
  log_expr(exprobj, TMPL_LOG_ERROR, "not a valid expression: %s\n", s);
}

#include "calc.inc"

static
const symrec_const
#ifndef __cplusplus
const 
#endif
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
#ifndef __cplusplus
const 
#endif
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

