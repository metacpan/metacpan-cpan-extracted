/* A Bison parser, made by GNU Bison 1.875a.  */

/* Skeleton parser for Yacc-like parsing with Bison,
   Copyright (C) 1984, 1989, 1990, 2000, 2001, 2002, 2003 Free Software Foundation, Inc.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2, or (at your option)
   any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place - Suite 330,
   Boston, MA 02111-1307, USA.  */

/* As a special exception, when this file is copied by Bison into a
   Bison output file, you may use that output file without restriction.
   This special exception was added by the Free Software Foundation
   in version 1.24 of Bison.  */

/* Written by Richard Stallman by simplifying the original so called
   ``semantic'' parser.  */

/* All symbols defined below should begin with yy or YY, to avoid
   infringing on user name space.  This should be done even for local
   variables, as they might otherwise be expanded by user macros.
   There are some unavoidable exceptions within include files to
   define necessary library symbols; they are noted "INFRINGES ON
   USER NAME SPACE" below.  */

/* Identify Bison output.  */
#define YYBISON 1

/* Skeleton name.  */
#define YYSKELETON_NAME "yacc.c"

/* Pure parsers.  */
#define YYPURE 0

/* Using locations.  */
#define YYLSP_NEEDED 0



/* Tokens.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
   /* Put the tokens into the symbol table, so that GDB and other debuggers
      know about them.  */
   enum yytokentype {
     EXPR = 258,
     CTXT = 259,
     SCRIPT = 260,
     CASEXP = 261,
     OF = 262,
     DATA = 263,
     TYPE = 264,
     IF = 265,
     THEN = 266,
     ELSE = 267,
     WHERE = 268,
     LET = 269,
     IN = 270,
     INFIXN = 271,
     INFIXL = 272,
     INFIXR = 273,
     PRIMITIVE = 274,
     TNEWTYPE = 275,
     DEFAULT = 276,
     DERIVING = 277,
     DO = 278,
     TCLASS = 279,
     TINSTANCE = 280,
     MDO = 281,
     REPEAT = 282,
     ALL = 283,
     NUMLIT = 284,
     CHARLIT = 285,
     STRINGLIT = 286,
     VAROP = 287,
     VARID = 288,
     CONOP = 289,
     CONID = 290,
     QVAROP = 291,
     QVARID = 292,
     QCONOP = 293,
     QCONID = 294,
     RECSELID = 295,
     IPVARID = 296,
     COCO = 297,
     UPTO = 298,
     FROM = 299,
     ARROW = 300,
     IMPLIES = 301,
     TMODULE = 302,
     IMPORT = 303,
     HIDING = 304,
     QUALIFIED = 305,
     ASMOD = 306,
     NEEDPRIMS = 307,
     FOREIGN = 308
   };
#endif
#define EXPR 258
#define CTXT 259
#define SCRIPT 260
#define CASEXP 261
#define OF 262
#define DATA 263
#define TYPE 264
#define IF 265
#define THEN 266
#define ELSE 267
#define WHERE 268
#define LET 269
#define IN 270
#define INFIXN 271
#define INFIXL 272
#define INFIXR 273
#define PRIMITIVE 274
#define TNEWTYPE 275
#define DEFAULT 276
#define DERIVING 277
#define DO 278
#define TCLASS 279
#define TINSTANCE 280
#define MDO 281
#define REPEAT 282
#define ALL 283
#define NUMLIT 284
#define CHARLIT 285
#define STRINGLIT 286
#define VAROP 287
#define VARID 288
#define CONOP 289
#define CONID 290
#define QVAROP 291
#define QVARID 292
#define QCONOP 293
#define QCONID 294
#define RECSELID 295
#define IPVARID 296
#define COCO 297
#define UPTO 298
#define FROM 299
#define ARROW 300
#define IMPLIES 301
#define TMODULE 302
#define IMPORT 303
#define HIDING 304
#define QUALIFIED 305
#define ASMOD 306
#define NEEDPRIMS 307
#define FOREIGN 308




/* Copy the first part of user declarations.  */
#line 17 "parser.y"

#ifndef lint
#define lint
#endif
#define defTycon(n,l,lhs,rhs,w)	 tyconDefn(intOf(l),lhs,rhs,w); sp-=n
#define sigdecl(l,vs,t)		 ap(SIGDECL,triple(l,vs,t))
#define fixdecl(l,ops,a,p)	 ap(FIXDECL,\
				    triple(l,ops,mkInt(mkSyntax(a,intOf(p)))))
#define grded(gs)		 ap(GUARDED,gs)
#define bang(t)			 ap(BANG,t)
#define only(t)			 ap(ONLY,t)
#define letrec(bs,e)		 (nonNull(bs) ? ap(LETREC,pair(bs,e)) : e)
#define qualify(ps,t)		 (nonNull(ps) ? ap(QUAL,pair(ps,t)) : t)
#define exportSelf()		 singleton(ap(MODULEENT,mkCon(module(currentModule).text)))
#define yyerror(s)		 /* errors handled elsewhere */
#define YYSTYPE			 Cell

#ifdef YYBISON
# if !defined(__GNUC__) || __GNUC__ <= 1
static void __yy_memcpy Args((char*,char*, unsigned int));
# endif
#endif

#ifdef _MANAGED
static void yymemcpy (char *yyto, const char *yyfrom, size_t yycount);
#endif

static Cell   local gcShadow	 Args((Int,Cell));
static Void   local syntaxError	 Args((String));
static String local unexpected	 Args((Void));
static Cell   local checkPrec	 Args((Cell));
static Cell   local buildTuple	 Args((List));
static List   local checkCtxt	 Args((List));
static Cell   local checkPred	 Args((Cell));
static Pair   local checkDo	 Args((List));
static Cell   local checkTyLhs	 Args((Cell));

#if MUDO
static Pair   local checkMDo	 Args((List));
#endif

#if !TREX
static Void   local noTREX	 Args((String));
#endif
#if !IPARAM
static Void   local noIP	 Args((String));
#endif
#if !MUDO
static Void   local noMDo	 Args((String));
#endif

/* For the purposes of reasonably portable garbage collection, it is
 * necessary to simulate the YACC stack on the Hugs stack to keep
 * track of all intermediate constructs.  The lexical analyser
 * pushes a token onto the stack for each token that is found, with
 * these elements being removed as reduce actions are performed,
 * taking account of look-ahead tokens as described by gcShadow()
 * below.
 *
 * Of the non-terminals used below, only start, topDecl & begin
 * do not leave any values on the Hugs stack.  The same is true for the
 * terminals EXPR and SCRIPT.  At the end of a successful parse, there
 * should only be one element left on the stack, containing the result
 * of the parse.
 */

#define gc0(e)			gcShadow(0,e)
#define gc1(e)			gcShadow(1,e)
#define gc2(e)			gcShadow(2,e)
#define gc3(e)			gcShadow(3,e)
#define gc4(e)			gcShadow(4,e)
#define gc5(e)			gcShadow(5,e)
#define gc6(e)			gcShadow(6,e)
#define gc7(e)			gcShadow(7,e)



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

#if ! defined (YYSTYPE) && ! defined (YYSTYPE_IS_DECLARED)
typedef int YYSTYPE;
# define yystype YYSTYPE /* obsolescent; will be withdrawn */
# define YYSTYPE_IS_DECLARED 1
# define YYSTYPE_IS_TRIVIAL 1
#endif



/* Copy the second part of user declarations.  */


/* Line 214 of yacc.c.  */
#line 270 "y.tab.c"

#if ! defined (yyoverflow) || YYERROR_VERBOSE

/* The parser invokes alloca or malloc; define the necessary symbols.  */

# if YYSTACK_USE_ALLOCA
#  define YYSTACK_ALLOC alloca
# else
#  ifndef YYSTACK_USE_ALLOCA
#   if defined (alloca) || defined (_ALLOCA_H)
#    define YYSTACK_ALLOC alloca
#   else
#    ifdef __GNUC__
#     define YYSTACK_ALLOC __builtin_alloca
#    endif
#   endif
#  endif
# endif

# ifdef YYSTACK_ALLOC
   /* Pacify GCC's `empty if-body' warning. */
#  define YYSTACK_FREE(Ptr) do { /* empty */; } while (0)
# else
#  if defined (__STDC__) || defined (__cplusplus)
#   include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
#   define YYSIZE_T size_t
#  endif
#  define YYSTACK_ALLOC malloc
#  define YYSTACK_FREE free
# endif
#endif /* ! defined (yyoverflow) || YYERROR_VERBOSE */


#if (! defined (yyoverflow) \
     && (! defined (__cplusplus) \
	 || (YYSTYPE_IS_TRIVIAL)))

/* A type that is properly aligned for any stack member.  */
union yyalloc
{
  short yyss;
  YYSTYPE yyvs;
  };

/* The size of the maximum gap between one aligned stack and the next.  */
# define YYSTACK_GAP_MAXIMUM (sizeof (union yyalloc) - 1)

/* The size of an array large to enough to hold all stacks, each with
   N elements.  */
# define YYSTACK_BYTES(N) \
     ((N) * (sizeof (short) + sizeof (YYSTYPE))				\
      + YYSTACK_GAP_MAXIMUM)

/* Copy COUNT objects from FROM to TO.  The source and destination do
   not overlap.  */
# ifndef YYCOPY
#  if 1 < __GNUC__
#   define YYCOPY(To, From, Count) \
      __builtin_memcpy (To, From, (Count) * sizeof (*(From)))
#  else
#   define YYCOPY(To, From, Count)		\
      do					\
	{					\
	  register YYSIZE_T yyi;		\
	  for (yyi = 0; yyi < (Count); yyi++)	\
	    (To)[yyi] = (From)[yyi];		\
	}					\
      while (0)
#  endif
# endif

/* Relocate STACK from its old location to the new one.  The
   local variables YYSIZE and YYSTACKSIZE give the old and new number of
   elements in the stack, and YYPTR gives the new location of the
   stack.  Advance YYPTR to a properly aligned location for the next
   stack.  */
# define YYSTACK_RELOCATE(Stack)					\
    do									\
      {									\
	YYSIZE_T yynewbytes;						\
	YYCOPY (&yyptr->Stack, Stack, yysize);				\
	Stack = &yyptr->Stack;						\
	yynewbytes = yystacksize * sizeof (*Stack) + YYSTACK_GAP_MAXIMUM; \
	yyptr += yynewbytes / sizeof (*yyptr);				\
      }									\
    while (0)

#endif

#if defined (__STDC__) || defined (__cplusplus)
   typedef signed char yysigned_char;
#else
   typedef short yysigned_char;
#endif

/* YYFINAL -- State number of the termination state. */
#define YYFINAL  60
/* YYLAST -- Last index in YYTABLE.  */
#define YYLAST   4117

/* YYNTOKENS -- Number of terminals. */
#define YYNTOKENS  73
/* YYNNTS -- Number of nonterminals. */
#define YYNNTS  164
/* YYNRULES -- Number of rules. */
#define YYNRULES  499
/* YYNRULES -- Number of states. */
#define YYNSTATES  885

/* YYTRANSLATE(YYLEX) -- Bison symbol number corresponding to YYLEX.  */
#define YYUNDEFTOK  2
#define YYMAXUTOK   308

#define YYTRANSLATE(YYX) 						\
  ((unsigned int) (YYX) <= YYMAXUTOK ? yytranslate[YYX] : YYUNDEFTOK)

/* YYTRANSLATE[YYLEX] -- Bison symbol number corresponding to YYLEX.  */
static const unsigned char yytranslate[] =
{
       0,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,    52,     2,     2,     2,     2,     2,     2,
      53,    56,     2,    72,    55,    48,    61,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,    58,
       2,    42,     2,     2,    44,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,    57,    46,    59,     2,    71,    60,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,    69,    47,    70,    50,     2,     2,     2,
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
      25,    26,    27,    28,    29,    30,    31,    32,    33,    34,
      35,    36,    37,    38,    39,    40,    41,    43,    45,    49,
      51,    54,    62,    63,    64,    65,    66,    67,    68
};

#if YYDEBUG
/* YYPRHS[YYN] -- Index of the first RHS symbol of rule number YYN in
   YYRHS.  */
static const unsigned short yyprhs[] =
{
       0,     0,     3,     7,    10,    13,    15,    20,    25,    33,
      36,    37,    39,    41,    43,    44,    47,    49,    52,    57,
      58,    61,    65,    69,    74,    78,    80,    82,    84,    89,
      94,    97,    98,   100,   102,   105,   109,   111,   113,   115,
     119,   122,   124,   125,   129,   135,   142,   147,   150,   151,
     156,   160,   161,   163,   165,   168,   172,   174,   176,   178,
     183,   188,   189,   191,   193,   196,   200,   202,   204,   206,
     209,   213,   217,   219,   221,   226,   233,   236,   242,   250,
     253,   258,   261,   267,   275,   278,   281,   284,   287,   289,
     291,   295,   297,   301,   303,   307,   309,   314,   316,   320,
     322,   327,   331,   335,   339,   341,   343,   345,   350,   354,
     356,   360,   364,   367,   370,   373,   376,   379,   383,   386,
     388,   390,   392,   396,   398,   402,   406,   411,   412,   415,
     420,   421,   423,   427,   429,   434,   438,   440,   442,   445,
     447,   455,   462,   471,   479,   487,   492,   496,   501,   504,
     507,   510,   514,   516,   520,   522,   523,   525,   529,   531,
     532,   535,   539,   541,   545,   547,   548,   551,   556,   558,
     562,   564,   568,   572,   576,   578,   583,   585,   589,   595,
     598,   600,   604,   606,   609,   611,   615,   619,   621,   625,
     627,   631,   635,   639,   643,   647,   651,   655,   657,   659,
     661,   663,   667,   671,   675,   677,   679,   681,   684,   686,
     689,   691,   693,   695,   697,   700,   704,   708,   712,   716,
     720,   724,   728,   734,   738,   741,   743,   747,   751,   755,
     759,   763,   767,   771,   773,   777,   781,   784,   788,   791,
     795,   798,   802,   806,   808,   809,   813,   815,   819,   821,
     825,   829,   830,   833,   836,   839,   841,   844,   849,   852,
     854,   856,   858,   862,   866,   870,   874,   878,   883,   888,
     893,   896,   899,   902,   904,   907,   909,   912,   914,   919,
     920,   923,   924,   927,   931,   935,   936,   939,   942,   945,
     949,   952,   954,   956,   958,   962,   964,   968,   970,   972,
     974,   976,   978,   980,   982,   985,   988,   992,   997,  1001,
    1006,  1010,  1015,  1019,  1024,  1026,  1028,  1030,  1032,  1035,
    1038,  1040,  1042,  1044,  1048,  1050,  1055,  1057,  1059,  1061,
    1065,  1069,  1073,  1077,  1080,  1084,  1090,  1094,  1098,  1102,
    1104,  1105,  1107,  1111,  1113,  1117,  1119,  1123,  1125,  1129,
    1131,  1133,  1137,  1139,  1141,  1143,  1145,  1147,  1149,  1151,
    1156,  1160,  1163,  1168,  1172,  1177,  1181,  1184,  1189,  1193,
    1200,  1205,  1210,  1212,  1217,  1222,  1229,  1232,  1234,  1237,
    1239,  1241,  1245,  1248,  1250,  1252,  1254,  1259,  1264,  1266,
    1268,  1270,  1272,  1276,  1280,  1284,  1290,  1292,  1296,  1301,
    1306,  1311,  1315,  1319,  1323,  1325,  1329,  1331,  1334,  1338,
    1341,  1343,  1347,  1349,  1352,  1354,  1357,  1359,  1364,  1366,
    1369,  1373,  1376,  1378,  1382,  1385,  1387,  1388,  1390,  1394,
    1396,  1398,  1402,  1404,  1406,  1409,  1413,  1418,  1421,  1427,
    1431,  1434,  1438,  1440,  1444,  1446,  1449,  1451,  1454,  1457,
    1461,  1464,  1466,  1468,  1470,  1472,  1474,  1476,  1478,  1480,
    1484,  1488,  1492,  1496,  1500,  1502,  1506,  1508,  1510,  1514,
    1516,  1520,  1522,  1524,  1526,  1528,  1530,  1532,  1534,  1536,
    1538,  1542,  1544,  1546,  1548,  1550,  1552,  1556,  1558,  1560,
    1564,  1566,  1570,  1572,  1574,  1576,  1578,  1580,  1581,  1583
};

/* YYRHS -- A `-1'-separated list of the rules' RHS. */
static const short yyrhs[] =
{
      74,     0,    -1,     3,   186,   162,    -1,     4,   131,    -1,
       5,    75,    -1,     1,    -1,    76,   235,    79,   236,    -1,
      76,    69,    79,    70,    -1,    62,    77,    80,    13,    69,
      79,   236,    -1,    62,     1,    -1,    -1,   220,    -1,   220,
      -1,    31,    -1,    -1,    58,    79,    -1,    96,    -1,    86,
      87,    -1,    86,    58,    87,    96,    -1,    -1,    53,    56,
      -1,    53,    55,    56,    -1,    53,    81,    56,    -1,    53,
      81,    55,    56,    -1,    81,    55,    82,    -1,    82,    -1,
     222,    -1,   224,    -1,   220,    53,    45,    56,    -1,   220,
      53,    83,    56,    -1,    62,    78,    -1,    -1,    55,    -1,
      84,    -1,    84,    55,    -1,    84,    55,    85,    -1,    85,
      -1,   222,    -1,   224,    -1,    86,    58,    88,    -1,    86,
      58,    -1,    88,    -1,    -1,    63,    78,    89,    -1,    63,
      78,    66,    78,    89,    -1,    63,    65,    78,    66,    78,
      89,    -1,    63,    65,    78,    89,    -1,    63,     1,    -1,
      -1,    64,    53,    90,    56,    -1,    53,    90,    56,    -1,
      -1,    55,    -1,    91,    -1,    91,    55,    -1,    91,    55,
      92,    -1,    92,    -1,   221,    -1,    35,    -1,    35,    53,
      45,    56,    -1,    35,    53,    93,    56,    -1,    -1,    55,
      -1,    94,    -1,    94,    55,    -1,    94,    55,    95,    -1,
      95,    -1,   221,    -1,   223,    -1,    96,    58,    -1,    96,
      58,    97,    -1,    96,    58,   153,    -1,    97,    -1,   153,
      -1,     9,    98,    42,   135,    -1,     9,    98,    42,   135,
      15,    99,    -1,     9,     1,    -1,     8,   139,    42,   101,
     111,    -1,     8,   131,    54,    98,    42,   101,   111,    -1,
       8,   139,    -1,     8,   131,    54,    98,    -1,     8,     1,
      -1,    20,   139,    42,   108,   111,    -1,    20,   131,    54,
      98,    42,   108,   111,    -1,    20,     1,    -1,    67,    29,
      -1,    67,     1,    -1,    98,   219,    -1,    35,    -1,     1,
      -1,    99,    55,   100,    -1,   100,    -1,   221,    43,   124,
      -1,   221,    -1,   101,    47,   102,    -1,   102,    -1,    28,
     129,    61,   103,    -1,   104,    -1,   131,    54,   104,    -1,
     104,    -1,    52,   137,   231,   107,    -1,   138,   231,   107,
      -1,   139,   231,   107,    -1,   128,   231,   107,    -1,   139,
      -1,   105,    -1,   106,    -1,   223,    69,   109,    70,    -1,
     223,    69,    70,    -1,     1,    -1,   139,    52,   140,    -1,
     105,    52,   140,    -1,   105,   140,    -1,   139,   128,    -1,
     105,   128,    -1,   106,   128,    -1,   106,   140,    -1,   106,
      52,   140,    -1,    52,   137,    -1,   137,    -1,   128,    -1,
     102,    -1,   109,    55,   110,    -1,   110,    -1,   149,    43,
     127,    -1,   149,    43,   135,    -1,   149,    43,    52,   135,
      -1,    -1,    22,   220,    -1,    22,    53,   112,    56,    -1,
      -1,   113,    -1,   113,    55,   220,    -1,   220,    -1,    19,
     114,    43,   124,    -1,   114,    55,   115,    -1,   115,    -1,
       1,    -1,   221,    31,    -1,   221,    -1,    68,    63,   221,
      31,   221,    43,   124,    -1,    68,    63,   221,   221,    43,
     124,    -1,    68,    63,   221,   221,    31,   221,    43,   124,
      -1,    68,    63,   221,   221,   221,    43,   124,    -1,    68,
     221,   221,    31,   221,    43,   124,    -1,    24,   116,   120,
     161,    -1,    25,   117,   161,    -1,    21,    53,   118,    56,
      -1,    24,     1,    -1,    25,     1,    -1,    21,     1,    -1,
     131,    54,   139,    -1,   139,    -1,   131,    54,   139,    -1,
     139,    -1,    -1,   119,    -1,   119,    55,   135,    -1,   135,
      -1,    -1,    47,   121,    -1,   121,    55,   122,    -1,   122,
      -1,   123,    51,   123,    -1,     1,    -1,    -1,   123,   219,
      -1,    28,   129,    61,   125,    -1,   125,    -1,   131,    54,
     126,    -1,   126,    -1,   128,    51,   126,    -1,   138,    51,
     126,    -1,   139,    51,   126,    -1,   137,    -1,    28,   129,
      61,   130,    -1,   128,    -1,    53,   127,    56,    -1,    53,
     132,    54,   135,    56,    -1,   129,   219,    -1,   219,    -1,
     131,    54,   135,    -1,   135,    -1,    53,    56,    -1,   139,
      -1,    53,   139,    56,    -1,    53,   142,    56,    -1,   133,
      -1,    53,   134,    56,    -1,   133,    -1,    53,   134,    56,
      -1,   219,    46,   219,    -1,    41,    43,   135,    -1,   142,
      55,   133,    -1,   134,    55,   139,    -1,   134,    55,   133,
      -1,   139,    55,   133,    -1,   133,    -1,   136,    -1,   139,
      -1,   138,    -1,   128,    51,   135,    -1,   138,    51,   135,
      -1,   139,    51,   135,    -1,     1,    -1,   138,    -1,   139,
      -1,   138,   140,    -1,   141,    -1,   139,   140,    -1,   220,
      -1,   141,    -1,   220,    -1,   219,    -1,    53,    56,    -1,
      53,    51,    56,    -1,    53,   136,    56,    -1,    53,   139,
      56,    -1,    53,   218,    56,    -1,    53,   142,    56,    -1,
      53,   143,    56,    -1,    53,   144,    56,    -1,    53,   144,
      47,   135,    56,    -1,    57,   135,    59,    -1,    57,    59,
      -1,    71,    -1,   142,    55,   139,    -1,   139,    55,   139,
      -1,   136,    55,   135,    -1,   139,    55,   136,    -1,   142,
      55,   136,    -1,   143,    55,   135,    -1,   144,    55,   145,
      -1,   145,    -1,   219,    43,   135,    -1,    16,   147,   148,
      -1,    16,     1,    -1,    17,   147,   148,    -1,    17,     1,
      -1,    18,   147,   148,    -1,    18,     1,    -1,   149,    43,
     124,    -1,   149,    43,     1,    -1,    29,    -1,    -1,   148,
      55,   233,    -1,   233,    -1,   149,    55,   221,    -1,   221,
      -1,    69,   151,   236,    -1,    69,   152,   236,    -1,    -1,
     151,    58,    -1,   152,    58,    -1,   151,   153,    -1,   146,
      -1,   154,   157,    -1,   154,    43,   135,   157,    -1,   170,
     157,    -1,   155,    -1,   156,    -1,   169,    -1,   175,   225,
     170,    -1,   173,   225,   170,    -1,    29,   225,   170,    -1,
     221,   227,   170,    -1,   221,    72,   171,    -1,    53,   155,
      56,   177,    -1,    53,   156,    56,   177,    -1,    53,   169,
      56,   177,    -1,   221,   177,    -1,   156,   177,    -1,   158,
     161,    -1,     1,    -1,    42,   186,    -1,   159,    -1,   159,
     160,    -1,   160,    -1,    47,   188,    42,   186,    -1,    -1,
      13,   150,    -1,    -1,    13,   163,    -1,    69,   164,   236,
      -1,    69,   165,   236,    -1,    -1,   164,    58,    -1,   165,
      58,    -1,   164,   166,    -1,    41,    42,   186,    -1,    41,
       1,    -1,   153,    -1,   169,    -1,   168,    -1,   170,    43,
     135,    -1,   170,    -1,   221,    72,    29,    -1,   221,    -1,
      29,    -1,   172,    -1,   221,    -1,   172,    -1,   175,    -1,
     173,    -1,    48,   174,    -1,    48,     1,    -1,   221,   232,
     174,    -1,   221,   232,    48,   174,    -1,    29,   232,   174,
      -1,    29,   232,    48,   174,    -1,   175,   232,   174,    -1,
     175,   232,    48,   174,    -1,   173,   232,   174,    -1,   173,
     232,    48,   174,    -1,   176,    -1,   177,    -1,   176,    -1,
     178,    -1,   176,   177,    -1,   217,   177,    -1,    29,    -1,
     221,    -1,   178,    -1,   221,    44,   177,    -1,   217,    -1,
     224,    69,   181,    70,    -1,    30,    -1,    31,    -1,    71,
      -1,    53,   168,    56,    -1,    53,   169,    56,    -1,    53,
     179,    56,    -1,    57,   180,    59,    -1,    50,   177,    -1,
      53,   184,    56,    -1,    53,   184,    47,   167,    56,    -1,
     179,    55,   167,    -1,   167,    55,   167,    -1,   180,    55,
     167,    -1,   167,    -1,    -1,   182,    -1,   182,    55,   183,
      -1,   183,    -1,   222,    42,   167,    -1,   221,    -1,   184,
      55,   185,    -1,   185,    -1,   219,    42,   167,    -1,   187,
      -1,     1,    -1,   189,    43,   130,    -1,   188,    -1,   189,
      -1,   190,    -1,   191,    -1,   193,    -1,   192,    -1,   194,
      -1,   191,   234,    48,   193,    -1,   191,   234,   193,    -1,
      48,   193,    -1,   193,   234,    48,   193,    -1,   193,   234,
     193,    -1,   191,   234,    48,   194,    -1,   191,   234,   194,
      -1,    48,   194,    -1,   193,   234,    48,   194,    -1,   193,
     234,   194,    -1,     6,   186,     7,    69,   201,   236,    -1,
      23,    69,   207,   236,    -1,    26,    69,   207,   236,    -1,
     196,    -1,    46,   195,    51,   186,    -1,    14,   163,    15,
     186,    -1,    10,   186,    11,   186,    12,   186,    -1,   195,
     177,    -1,   177,    -1,   196,   197,    -1,   197,    -1,   222,
      -1,   222,    44,   197,    -1,    50,   197,    -1,    41,    -1,
      71,    -1,   217,    -1,   224,    69,   210,    70,    -1,   197,
      69,   210,    70,    -1,    29,    -1,    30,    -1,    31,    -1,
      27,    -1,    53,   186,    56,    -1,    53,   198,    56,    -1,
      53,   199,    56,    -1,    53,   199,    47,   186,    56,    -1,
      40,    -1,    57,   213,    59,    -1,    53,   193,   234,    56,
      -1,    53,   230,   188,    56,    -1,    53,   232,   188,    56,
      -1,   198,    55,   186,    -1,   186,    55,   186,    -1,   199,
      55,   200,    -1,   200,    -1,   219,    42,   186,    -1,   202,
      -1,    58,   201,    -1,   202,    58,   203,    -1,   202,    58,
      -1,   203,    -1,   167,   204,   161,    -1,   205,    -1,    51,
     186,    -1,     1,    -1,   205,   206,    -1,   206,    -1,    47,
     188,    51,   186,    -1,   208,    -1,    58,   207,    -1,   208,
      58,   209,    -1,   208,    58,    -1,   209,    -1,   187,    49,
     186,    -1,    14,   163,    -1,   187,    -1,    -1,   211,    -1,
     211,    55,   212,    -1,   212,    -1,   221,    -1,   222,    42,
     186,    -1,   186,    -1,   198,    -1,   186,   214,    -1,   186,
      45,   186,    -1,   186,    55,   186,    45,    -1,   186,    45,
      -1,   186,    55,   186,    45,   186,    -1,   214,    47,   215,
      -1,    47,   215,    -1,   215,    55,   216,    -1,   216,    -1,
     186,    49,   186,    -1,   186,    -1,    14,   163,    -1,   224,
      -1,    53,    56,    -1,    57,    59,    -1,    53,   218,    56,
      -1,   218,    55,    -1,    55,    -1,    33,    -1,    64,    -1,
      65,    -1,    66,    -1,    39,    -1,    35,    -1,   219,    -1,
      53,    32,    56,    -1,    53,    72,    56,    -1,    53,    48,
      56,    -1,    53,    52,    56,    -1,    53,    61,    56,    -1,
      37,    -1,    53,    36,    56,    -1,   221,    -1,    35,    -1,
      53,    34,    56,    -1,    39,    -1,    53,    38,    56,    -1,
     223,    -1,    72,    -1,    48,    -1,   228,    -1,    72,    -1,
     228,    -1,    48,    -1,   228,    -1,    32,    -1,    60,   219,
      60,    -1,    52,    -1,    61,    -1,    48,    -1,   230,    -1,
      36,    -1,    60,    37,    60,    -1,   226,    -1,    34,    -1,
      60,    35,    60,    -1,    38,    -1,    60,    39,    60,    -1,
     231,    -1,   225,    -1,   231,    -1,   229,    -1,   232,    -1,
      -1,    70,    -1,     1,    -1
};

/* YYRLINE[YYN] -- source line where rule number YYN was defined.  */
static const unsigned short yyrline[] =
{
       0,   119,   119,   120,   121,   122,   135,   139,   143,   145,
     151,   154,   156,   157,   165,   166,   167,   168,   169,   174,
     175,   176,   177,   178,   180,   181,   186,   187,   188,   189,
     190,   192,   193,   194,   195,   197,   198,   200,   201,   206,
     207,   208,   210,   221,   223,   226,   229,   232,   234,   235,
     236,   238,   239,   240,   241,   243,   244,   246,   247,   248,
     249,   251,   252,   253,   254,   256,   257,   259,   260,   265,
     266,   267,   268,   269,   274,   275,   278,   279,   282,   286,
     288,   291,   292,   295,   299,   300,   306,   308,   309,   310,
     312,   313,   315,   317,   319,   320,   322,   324,   326,   327,
     329,   330,   331,   332,   333,   334,   335,   336,   337,   338,
     340,   341,   342,   344,   345,   346,   347,   348,   350,   351,
     352,   354,   356,   357,   359,   360,   361,   363,   364,   365,
     367,   368,   370,   371,   376,   378,   379,   380,   382,   383,
     388,   390,   392,   394,   396,   402,   403,   404,   405,   406,
     407,   409,   410,   412,   413,   415,   416,   418,   419,   421,
     422,   425,   426,   428,   429,   431,   432,   437,   439,   441,
     442,   444,   445,   446,   447,   449,   451,   453,   454,   456,
     457,   459,   460,   462,   463,   464,   465,   466,   467,   469,
     470,   472,   479,   487,   488,   489,   490,   491,   494,   495,
     497,   498,   499,   500,   501,   503,   504,   506,   507,   509,
     510,   512,   513,   515,   516,   517,   518,   519,   520,   521,
     522,   523,   530,   537,   538,   539,   542,   543,   545,   546,
     547,   548,   551,   552,   554,   561,   562,   563,   564,   565,
     566,   567,   568,   570,   571,   573,   574,   576,   577,   579,
     580,   582,   583,   584,   586,   588,   589,   590,   593,   595,
     596,   597,   599,   600,   601,   602,   603,   605,   606,   607,
     608,   609,   611,   612,   614,   615,   617,   618,   620,   622,
     623,   628,   629,   632,   633,   636,   637,   638,   641,   643,
     650,   651,   656,   657,   659,   660,   662,   664,   665,   666,
     668,   669,   671,   672,   674,   675,   676,   677,   678,   679,
     680,   681,   682,   683,   685,   686,   688,   689,   691,   692,
     694,   695,   696,   698,   699,   700,   701,   702,   703,   704,
     705,   706,   707,   708,   710,   717,   720,   721,   723,   724,
     726,   727,   729,   730,   732,   733,   736,   737,   739,   751,
     752,   754,   755,   757,   758,   760,   761,   763,   764,   766,
     767,   768,   769,   771,   773,   774,   775,   776,   778,   780,
     781,   782,   789,   791,   794,   795,   797,   798,   800,   801,
     803,   804,   805,   806,   807,   808,   809,   810,   812,   813,
     814,   815,   816,   817,   819,   826,   827,   829,   830,   831,
     832,   834,   835,   838,   839,   841,   850,   851,   853,   854,
     855,   857,   859,   860,   861,   863,   864,   866,   869,   870,
     872,   873,   874,   877,   878,   880,   882,   883,   885,   886,
     888,   889,   894,   895,   896,   912,   913,   914,   915,   918,
     919,   921,   922,   924,   925,   926,   931,   932,   933,   934,
     936,   937,   939,   940,   941,   942,   944,   945,   947,   948,
     949,   950,   951,   952,   954,   955,   956,   958,   959,   961,
     962,   963,   965,   966,   967,   969,   970,   972,   973,   975,
     976,   977,   978,   980,   981,   983,   984,   985,   988,   989,
     991,   992,   993,   995,   996,   998,   999,  1004,  1007,  1008
};
#endif

#if YYDEBUG || YYERROR_VERBOSE
/* YYTNME[SYMBOL-NUM] -- String name of the symbol SYMBOL-NUM.
   First, the terminals, then, starting at YYNTOKENS, nonterminals. */
static const char *const yytname[] =
{
  "$end", "error", "$undefined", "EXPR", "CTXT", "SCRIPT", "CASEXP", "OF", 
  "DATA", "TYPE", "IF", "THEN", "ELSE", "WHERE", "LET", "IN", "INFIXN", 
  "INFIXL", "INFIXR", "PRIMITIVE", "TNEWTYPE", "DEFAULT", "DERIVING", 
  "DO", "TCLASS", "TINSTANCE", "MDO", "REPEAT", "ALL", "NUMLIT", 
  "CHARLIT", "STRINGLIT", "VAROP", "VARID", "CONOP", "CONID", "QVAROP", 
  "QVARID", "QCONOP", "QCONID", "RECSELID", "IPVARID", "'='", "COCO", 
  "'@'", "UPTO", "'\\\\'", "'|'", "'-'", "FROM", "'~'", "ARROW", "'!'", 
  "'('", "IMPLIES", "','", "')'", "'['", "';'", "']'", "'`'", "'.'", 
  "TMODULE", "IMPORT", "HIDING", "QUALIFIED", "ASMOD", "NEEDPRIMS", 
  "FOREIGN", "'{'", "'}'", "'_'", "'+'", "$accept", "start", "topModule", 
  "startMain", "modname", "modid", "modBody", "expspec", "exports", 
  "export", "qnames", "qnames1", "qname", "impDecls", "chase", "impDecl", 
  "impspec", "imports", "imports1", "import", "names", "names1", "name", 
  "topDecls", "topDecl", "tyLhs", "invars", "invar", "constrs", "pconstr", 
  "qconstr", "constr", "btype3", "btype4", "bbtype", "nconstr", 
  "fieldspecs", "fieldspec", "deriving", "derivs0", "derivs", "prims", 
  "prim", "crule", "irule", "dtypes", "dtypes1", "fds", "fds1", "fd", 
  "varids0", "topType", "topType0", "topType1", "polyType", "bpolyType", 
  "varids", "sigType", "context", "lcontext", "lacks", "lacks1", "type", 
  "type1", "btype", "btype1", "btype2", "atype", "atype1", "btypes2", 
  "typeTuple", "tfields", "tfield", "gendecl", "optDigit", "ops", "vars", 
  "decls", "decls0", "decls1", "decl", "funlhs", "funlhs0", "funlhs1", 
  "rhs", "rhs1", "gdrhs", "gddef", "wherePart", "lwherePart", "ldecls", 
  "ldecls0", "ldecls1", "ldecl", "pat", "pat_npk", "npk", "pat0", 
  "pat0_INT", "pat0_vI", "infixPat", "pat10", "pat10_vI", "fpat", "apat", 
  "apat_vI", "pats2", "pats1", "patbinds", "patbinds1", "patbind", 
  "patfields", "patfield", "exp", "exp_err", "exp0", "exp0a", "exp0b", 
  "infixExpa", "infixExpb", "exp10a", "exp10b", "pats", "appExp", "aexp", 
  "exps2", "vfields", "vfield", "alts", "alts1", "alt", "altRhs", 
  "guardAlts", "guardAlt", "stmts", "stmts1", "stmt", "fbinds", "fbinds1", 
  "fbind", "list", "zipquals", "quals", "qual", "gcon", "tupCommas", 
  "varid", "qconid", "var", "qvar", "con", "qcon", "varop", "varop_mi", 
  "varop_pl", "varop_mipl", "qvarop", "qvarop_mi", "conop", "qconop", 
  "op", "qop", "begin", "end", 0
};
#endif

# ifdef YYPRINT
/* YYTOKNUM[YYLEX-NUM] -- Internal token number corresponding to
   token YYLEX-NUM.  */
static const unsigned short yytoknum[] =
{
       0,   256,   257,   258,   259,   260,   261,   262,   263,   264,
     265,   266,   267,   268,   269,   270,   271,   272,   273,   274,
     275,   276,   277,   278,   279,   280,   281,   282,   283,   284,
     285,   286,   287,   288,   289,   290,   291,   292,   293,   294,
     295,   296,    61,   297,    64,   298,    92,   124,    45,   299,
     126,   300,    33,    40,   301,    44,    41,    91,    59,    93,
      96,    46,   302,   303,   304,   305,   306,   307,   308,   123,
     125,    95,    43
};
# endif

/* YYR1[YYN] -- Symbol number of symbol that rule YYN derives.  */
static const unsigned char yyr1[] =
{
       0,    73,    74,    74,    74,    74,    75,    75,    75,    75,
      76,    77,    78,    78,    79,    79,    79,    79,    79,    80,
      80,    80,    80,    80,    81,    81,    82,    82,    82,    82,
      82,    83,    83,    83,    83,    84,    84,    85,    85,    86,
      86,    86,    87,    88,    88,    88,    88,    88,    89,    89,
      89,    90,    90,    90,    90,    91,    91,    92,    92,    92,
      92,    93,    93,    93,    93,    94,    94,    95,    95,    96,
      96,    96,    96,    96,    97,    97,    97,    97,    97,    97,
      97,    97,    97,    97,    97,    97,    97,    98,    98,    98,
      99,    99,   100,   100,   101,   101,   102,   102,   103,   103,
     104,   104,   104,   104,   104,   104,   104,   104,   104,   104,
     105,   105,   105,   106,   106,   106,   106,   106,   107,   107,
     107,   108,   109,   109,   110,   110,   110,   111,   111,   111,
     112,   112,   113,   113,    97,   114,   114,   114,   115,   115,
      97,    97,    97,    97,    97,    97,    97,    97,    97,    97,
      97,   116,   116,   117,   117,   118,   118,   119,   119,   120,
     120,   121,   121,   122,   122,   123,   123,   124,   124,   125,
     125,   126,   126,   126,   126,   127,   127,   128,   128,   129,
     129,   130,   130,   131,   131,   131,   131,   131,   131,   132,
     132,   133,   133,   134,   134,   134,   134,   134,   135,   135,
     136,   136,   136,   136,   136,   137,   137,   138,   138,   139,
     139,   140,   140,   141,   141,   141,   141,   141,   141,   141,
     141,   141,   141,   141,   141,   141,   142,   142,   143,   143,
     143,   143,   144,   144,   145,   146,   146,   146,   146,   146,
     146,   146,   146,   147,   147,   148,   148,   149,   149,   150,
     150,   151,   151,   151,   152,   153,   153,   153,   153,   154,
     154,   154,   155,   155,   155,   155,   155,   156,   156,   156,
     156,   156,   157,   157,   158,   158,   159,   159,   160,   161,
     161,   162,   162,   163,   163,   164,   164,   164,   165,   166,
     166,   166,   167,   167,   168,   168,   169,   170,   170,   170,
     171,   171,   172,   172,   173,   173,   173,   173,   173,   173,
     173,   173,   173,   173,   174,   174,   175,   175,   176,   176,
     177,   177,   177,   178,   178,   178,   178,   178,   178,   178,
     178,   178,   178,   178,   178,   178,   179,   179,   180,   180,
     181,   181,   182,   182,   183,   183,   184,   184,   185,   186,
     186,   187,   187,   188,   188,   189,   189,   190,   190,   191,
     191,   191,   191,   191,   192,   192,   192,   192,   192,   193,
     193,   193,   193,   194,   194,   194,   195,   195,   196,   196,
     197,   197,   197,   197,   197,   197,   197,   197,   197,   197,
     197,   197,   197,   197,   197,   197,   197,   197,   197,   197,
     197,   198,   198,   199,   199,   200,   201,   201,   202,   202,
     202,   203,   204,   204,   204,   205,   205,   206,   207,   207,
     208,   208,   208,   209,   209,   209,   210,   210,   211,   211,
     212,   212,   213,   213,   213,   213,   213,   213,   213,   214,
     214,   215,   215,   216,   216,   216,   217,   217,   217,   217,
     218,   218,   219,   219,   219,   219,   220,   220,   221,   221,
     221,   221,   221,   221,   222,   222,   222,   223,   223,   224,
     224,   224,   225,   225,   225,   226,   226,   227,   227,   228,
     228,   228,   228,   229,   229,   230,   230,   230,   231,   231,
     232,   232,   232,   233,   233,   234,   234,   235,   236,   236
};

/* YYR2[YYN] -- Number of symbols composing right hand side of rule YYN.  */
static const unsigned char yyr2[] =
{
       0,     2,     3,     2,     2,     1,     4,     4,     7,     2,
       0,     1,     1,     1,     0,     2,     1,     2,     4,     0,
       2,     3,     3,     4,     3,     1,     1,     1,     4,     4,
       2,     0,     1,     1,     2,     3,     1,     1,     1,     3,
       2,     1,     0,     3,     5,     6,     4,     2,     0,     4,
       3,     0,     1,     1,     2,     3,     1,     1,     1,     4,
       4,     0,     1,     1,     2,     3,     1,     1,     1,     2,
       3,     3,     1,     1,     4,     6,     2,     5,     7,     2,
       4,     2,     5,     7,     2,     2,     2,     2,     1,     1,
       3,     1,     3,     1,     3,     1,     4,     1,     3,     1,
       4,     3,     3,     3,     1,     1,     1,     4,     3,     1,
       3,     3,     2,     2,     2,     2,     2,     3,     2,     1,
       1,     1,     3,     1,     3,     3,     4,     0,     2,     4,
       0,     1,     3,     1,     4,     3,     1,     1,     2,     1,
       7,     6,     8,     7,     7,     4,     3,     4,     2,     2,
       2,     3,     1,     3,     1,     0,     1,     3,     1,     0,
       2,     3,     1,     3,     1,     0,     2,     4,     1,     3,
       1,     3,     3,     3,     1,     4,     1,     3,     5,     2,
       1,     3,     1,     2,     1,     3,     3,     1,     3,     1,
       3,     3,     3,     3,     3,     3,     3,     1,     1,     1,
       1,     3,     3,     3,     1,     1,     1,     2,     1,     2,
       1,     1,     1,     1,     2,     3,     3,     3,     3,     3,
       3,     3,     5,     3,     2,     1,     3,     3,     3,     3,
       3,     3,     3,     1,     3,     3,     2,     3,     2,     3,
       2,     3,     3,     1,     0,     3,     1,     3,     1,     3,
       3,     0,     2,     2,     2,     1,     2,     4,     2,     1,
       1,     1,     3,     3,     3,     3,     3,     4,     4,     4,
       2,     2,     2,     1,     2,     1,     2,     1,     4,     0,
       2,     0,     2,     3,     3,     0,     2,     2,     2,     3,
       2,     1,     1,     1,     3,     1,     3,     1,     1,     1,
       1,     1,     1,     1,     2,     2,     3,     4,     3,     4,
       3,     4,     3,     4,     1,     1,     1,     1,     2,     2,
       1,     1,     1,     3,     1,     4,     1,     1,     1,     3,
       3,     3,     3,     2,     3,     5,     3,     3,     3,     1,
       0,     1,     3,     1,     3,     1,     3,     1,     3,     1,
       1,     3,     1,     1,     1,     1,     1,     1,     1,     4,
       3,     2,     4,     3,     4,     3,     2,     4,     3,     6,
       4,     4,     1,     4,     4,     6,     2,     1,     2,     1,
       1,     3,     2,     1,     1,     1,     4,     4,     1,     1,
       1,     1,     3,     3,     3,     5,     1,     3,     4,     4,
       4,     3,     3,     3,     1,     3,     1,     2,     3,     2,
       1,     3,     1,     2,     1,     2,     1,     4,     1,     2,
       3,     2,     1,     3,     2,     1,     0,     1,     3,     1,
       1,     3,     1,     1,     2,     3,     4,     2,     5,     3,
       2,     3,     1,     3,     1,     2,     1,     2,     2,     3,
       2,     1,     1,     1,     1,     1,     1,     1,     1,     3,
       3,     3,     3,     3,     1,     3,     1,     1,     3,     1,
       3,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       3,     1,     1,     1,     1,     1,     3,     1,     1,     3,
       1,     3,     1,     1,     1,     1,     1,     0,     1,     1
};

/* YYDEFACT[STATE-NAME] -- Default rule to reduce with in state
   STATE-NUM when YYTABLE doesn't specify something else to do.  Zero
   means the default is an error.  */
static const unsigned short yydefact[] =
{
       0,     5,     0,     0,    10,     0,   350,     0,     0,     0,
       0,     0,   391,   388,   389,   390,   452,   467,   464,   469,
     396,   383,     0,     0,     0,     0,     0,   453,   454,   455,
     384,   281,   349,   352,   353,   354,   355,   357,   356,   358,
     372,   379,   385,   458,   466,   380,   471,   446,   457,   456,
       0,     0,     3,   187,   184,     0,   210,     0,     4,   497,
       1,     0,     0,   285,     0,     0,     0,   320,   326,   327,
       0,     0,     0,   328,   377,   322,     0,   324,   321,   446,
     361,   366,   382,   479,   488,   485,   490,     0,   481,   451,
     447,     0,   482,   475,     0,   356,     0,     0,   404,     0,
     458,   487,   476,     0,   492,     0,   448,   432,   433,     0,
       0,     2,     0,   479,   488,   485,   490,   483,   481,   482,
     475,   495,   484,   496,     0,     0,   378,   426,     0,   426,
       0,   183,   197,     0,     0,     0,     0,     0,   225,   209,
     211,   213,   212,     0,     9,    19,    11,    14,    14,     0,
       0,     0,     0,     0,     0,     0,   425,     0,   418,   422,
       0,   333,   298,     0,     0,     0,     0,     0,     0,     0,
       0,   293,   292,   295,   299,   303,   302,   316,   317,     0,
       0,   347,   324,   458,   297,     0,   339,   293,   292,     0,
       0,   376,     0,   340,   459,   468,   465,   470,   461,   462,
       0,     0,     0,     0,   463,   460,     0,   392,     0,     0,
     393,     0,     0,   394,   450,   449,     0,     0,   353,     0,
       0,     0,     0,   434,   397,   282,   204,     0,     0,   351,
       0,   182,   198,   200,   199,   208,   213,     0,   360,   365,
       0,   363,   368,     0,     0,   427,   429,   430,     0,   381,
       0,     0,   192,   199,     0,   188,     0,   185,     0,   186,
       0,   214,     0,     0,     0,     0,     0,   233,     0,   213,
     224,     0,   191,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,   298,     0,    14,     0,     0,
       0,     0,    42,    41,    16,    72,   255,     0,    73,     0,
     259,   260,   261,     0,   303,   302,   297,     0,     0,     0,
     499,     0,   286,   498,   291,   288,   283,   287,   284,   374,
     424,   419,     0,   370,   421,   371,     0,     0,   305,   304,
     314,   315,     0,   329,   330,     0,     0,     0,   318,     0,
     331,     0,     0,   334,   319,     0,     0,     0,     0,   332,
     373,   323,     0,   341,   343,   345,     0,   489,   486,   491,
     480,   402,   398,   401,     0,   403,     0,   405,   399,   400,
     435,     0,   444,   440,   442,   402,     0,     0,     0,   214,
       0,   176,     0,   197,     0,     0,   213,     0,     0,     0,
     207,     0,   359,   364,   362,   367,     0,     0,   387,     0,
       0,   386,   189,   195,   194,   196,   227,   193,   226,   215,
       0,   216,     0,   217,     0,   219,     0,   220,     0,     0,
     221,   218,     0,   223,   457,   469,     0,     0,    20,     0,
       0,    25,     0,    26,    27,     0,    81,     0,    79,    89,
      88,     0,   236,   243,     0,   238,     0,   240,     0,   137,
       0,     0,   136,   139,    84,     0,   184,   150,     0,   148,
     159,     0,   152,   149,   279,     0,   154,   473,     0,   472,
       0,   474,     0,     0,   292,   297,    15,    47,    13,     0,
      48,    12,    86,    85,     0,     0,     7,    42,    17,    69,
       0,     0,   273,     0,     0,     0,   256,   279,   275,   277,
     271,   258,     0,     0,   477,     0,   270,     0,   478,     6,
       0,     0,     0,   406,   410,     0,   290,     0,   423,   420,
       0,   308,   337,   294,     0,   312,     0,   310,   336,     0,
     346,     0,   348,   296,     0,   306,   338,   325,     0,     0,
     395,   445,     0,     0,     0,   439,     0,   180,     0,     0,
       0,   177,     0,     0,   217,     0,   219,   201,   181,   202,
     203,   428,   431,   228,   229,   227,   230,   226,   231,     0,
     232,     0,   234,    21,    30,     0,    22,    31,    14,     0,
       0,     0,    87,     0,   235,   493,   494,   246,   237,   239,
       0,     0,   138,     0,     0,     0,   156,   158,     0,   279,
       0,     0,   146,     0,   264,   297,     0,     0,   330,    48,
      51,     0,     0,    43,     0,     0,     0,    39,    70,    71,
     242,     0,   241,   168,   170,     0,     0,   174,   205,   206,
     247,   274,     0,     0,   272,   276,   263,   262,   296,   266,
     301,   300,   265,   407,   414,     0,     0,   279,   412,   416,
     369,   409,   375,   289,   309,   313,   311,   335,   307,   342,
     344,   443,   441,   438,     0,   179,   190,     0,   222,    23,
      24,     0,    32,     0,    33,    36,    37,    38,     0,    89,
      80,   109,     0,     0,     0,   127,    95,    97,   105,   106,
       0,     0,   104,     0,    74,     0,   134,   135,     0,   121,
     127,   147,     0,   164,   160,   162,     0,   145,   151,   251,
     280,   153,   267,   268,   269,     0,    46,    58,    52,     0,
      53,    56,    57,    51,    48,     0,     0,     0,    18,     0,
       0,     0,     0,     0,   257,     0,     0,   413,   411,   415,
     408,   175,   178,    28,    29,    34,     8,     0,     0,     0,
     205,   206,     0,     0,    77,     0,   114,   112,     0,   115,
     116,     0,     0,     0,     0,   113,     0,     0,     0,   245,
       0,    82,   157,     0,   165,   166,     0,     0,    48,    61,
      50,    54,     0,    44,     0,     0,     0,     0,     0,     0,
     171,   206,   169,   172,   173,   278,     0,    35,   127,     0,
       0,   130,   128,    94,   111,   117,     0,   103,   120,   119,
     101,   110,   102,   108,     0,   123,     0,   248,    75,    91,
      93,   127,   161,   163,   252,   254,   249,   253,   250,    45,
       0,     0,    62,     0,    63,    66,    67,    68,    55,    49,
       0,     0,   141,     0,     0,   167,   417,    78,     0,    96,
      99,     0,   104,   100,     0,   131,   133,   118,     0,   107,
       0,     0,     0,    83,    59,    60,    64,   140,     0,   143,
     144,     0,   129,     0,   122,     0,   124,   125,    90,    92,
      65,   142,    98,   132,   126
};

/* YYDEFGOTO[NTERM-NUM]. */
static const short yydefgoto[] =
{
      -1,     5,    58,    59,   145,   480,   291,   274,   430,   431,
     673,   674,   675,   292,   488,   293,   613,   719,   720,   721,
     833,   834,   835,   294,   295,   441,   818,   819,   685,   686,
     849,   687,   688,   689,   807,   700,   814,   815,   754,   854,
     855,   451,   452,   460,   464,   595,   596,   599,   704,   705,
     706,   622,   623,   624,   380,   228,   546,   229,   626,   382,
      53,   133,   231,   232,   627,   233,   253,   139,   235,   264,
     265,   266,   267,   296,   444,   584,   297,   710,   776,   777,
     298,   299,   300,   301,   496,   497,   498,   499,   602,   111,
      64,   151,   152,   315,   511,   187,   188,   173,   639,   174,
     175,   329,   176,   177,   331,   178,   179,   189,   352,   353,
     354,   180,   181,   372,    32,    33,    34,    35,    36,    37,
      38,    39,    76,    40,    41,    96,    97,    98,   512,   513,
     514,   647,   648,   649,   157,   158,   159,   244,   245,   246,
     109,   223,   373,   374,    42,   268,    43,    56,    44,    45,
      46,    79,   585,   101,   507,   471,   121,   122,   104,   347,
     587,   124,   148,   316
};

/* YYPACT[STATE-NUM] -- Index in YYTABLE of the portion describing
   STATE-NUM.  */
#define YYPACT_NINF -766
static const short yypact[] =
{
     873,  -766,  2239,  1138,    -8,   173,  -766,  2239,  2239,   113,
     149,   159,  -766,  -766,  -766,  -766,  -766,  -766,  -766,  -766,
    -766,  -766,  3564,  2831,  2994,  2027,  2080,  -766,  -766,  -766,
    -766,   199,  -766,  -766,   161,  -766,   705,  -766,   705,  -766,
    2994,   178,  -766,  -766,  -766,   205,  -766,   202,  -766,  -766,
     230,  2370,  -766,  -766,  3990,   233,  -766,   112,  -766,   218,
    -766,   287,   294,  -766,   292,  2503,  2503,  -766,  -766,  -766,
    3564,  3081,  1433,  -766,  -766,  -766,  3252,  -766,   266,   249,
    -766,  -766,   178,   269,   278,   280,   306,  2598,   315,  -766,
    -766,  1790,   322,   334,   272,   705,   374,   405,  -766,   381,
     357,  -766,  -766,  2647,  -766,  2647,  -766,   264,   347,   345,
     113,  -766,  1936,  -766,  -766,  -766,  -766,  -766,  -766,  -766,
    -766,  -766,  -766,  -766,  2693,  2739,   178,   931,  2994,   931,
    2457,  -766,  -766,   384,  3698,   412,  1326,  2101,  -766,  -766,
    -766,  -766,  -766,    17,  -766,   353,  -766,  2890,  2890,   351,
    2239,  1751,    15,  2239,   113,  2503,   373,    58,   368,  -766,
      58,  -766,   331,   269,   278,   306,  1008,   315,   322,   334,
     378,   388,   394,   411,  -766,   331,   331,  3564,  -766,   423,
     433,  -766,  3564,   414,   125,  1239,  -766,  -766,  -766,   209,
    2239,  -766,  3564,   931,  -766,  -766,  -766,  -766,  -766,  -766,
     416,   422,   430,   441,  -766,  -766,  2239,  -766,  2549,  2239,
    -766,  2239,    17,  -766,  -766,  -766,  2239,   437,  -766,   448,
    2147,  2285,  2239,   461,  -766,  -766,  -766,  1852,   463,  -766,
     465,  -766,  -766,  3805,  3717,  -766,   233,  2831,  -766,  -766,
    2831,  -766,  -766,   522,   451,   469,  -766,   486,   495,   178,
     478,  2367,  -766,  3808,  1708,  -766,  1708,  -766,  1708,  -766,
     501,  -766,   442,  3608,   512,   520,   475,  -766,   574,   508,
    -766,   500,  -766,  4027,   550,   657,    57,   484,   552,   810,
     174,  1692,    48,  1897,  2852,   730,  3125,  2890,   171,   131,
     654,   499,   515,  -766,   521,  -766,  -766,   143,  -766,    27,
    -766,  3564,  -766,    78,   730,   730,  3037,    58,  3213,   570,
    -766,    60,  -766,  -766,  -766,  -766,  -766,  -766,  -766,  -766,
     292,  -766,  2239,  -766,  2785,  -766,   344,  3291,  -766,  -766,
    3564,  -766,  3330,  -766,  -766,  2457,  3369,  3408,  -766,  3330,
    -766,  3330,    17,  -766,  -766,  3330,   561,  3447,  3330,  -766,
    -766,  -766,   525,   543,  -766,   486,   564,  -766,  -766,  -766,
    -766,  -766,  -766,  -766,   555,  -766,   357,  -766,  -766,  -766,
    -766,   113,   565,   566,  -766,   571,  2285,    17,  2367,   569,
     579,   463,   584,   596,  3627,   589,   215,  2457,  2457,  2457,
    -766,  2457,  -766,  -766,  -766,  -766,   280,   598,  -766,   931,
    2239,  -766,  -766,  -766,  3990,  -766,  3990,  -766,  3990,  -766,
    2457,  -766,  2457,  -766,  2457,  -766,  2457,  -766,  2457,    17,
    -766,  -766,  2457,  -766,   362,   610,   567,   620,  -766,   313,
     592,  -766,   613,  -766,  -766,   625,  -766,   643,  3745,    66,
    -766,   782,  -766,  -766,   862,  -766,   862,  -766,   862,  -766,
     305,   191,  -766,   669,  -766,   647,  3842,  -766,  2386,  -766,
     659,   650,  3857,  -766,   698,   658,  3857,  -766,  1374,  -766,
    3330,  -766,   668,  3486,   677,  3169,  -766,  -766,  -766,   313,
     127,  -766,  -766,  -766,  1119,  1119,  -766,    94,  -766,  2951,
    1473,  1119,  -766,  2239,  2457,  2647,  -766,   698,   666,  -766,
    -766,  -766,  3330,  3330,  -766,  3525,  -766,  3330,  -766,  -766,
    3213,   111,    58,   656,  -766,  2239,  -766,  2239,  -766,  -766,
    3564,  -766,  -766,  -766,  3564,  -766,  3564,  -766,  -766,   684,
    -766,   414,  -766,  -766,  3564,  -766,  -766,  -766,   931,  3330,
    -766,   292,  2239,  2285,  2193,   566,   604,  -766,   619,  3655,
     628,  -766,  2457,  2414,   671,  2414,   688,  -766,  -766,  -766,
    -766,  -766,  -766,  -766,  -766,  3808,  -766,  3808,  -766,   690,
    -766,   508,  -766,  -766,  -766,  4051,  -766,  1981,  2890,   136,
    1527,  2457,  -766,  1172,   694,  -766,  -766,  -766,   694,   694,
    1587,  1119,  -766,   136,  1527,   700,   703,  -766,   359,   698,
     361,   701,  -766,   361,  -766,   329,  3564,  3564,  3564,   150,
     980,   718,   313,  -766,   914,   742,  2951,  -766,  -766,  -766,
    -766,    17,  -766,  -766,  -766,   724,   722,  -766,  3885,  3761,
    -766,  -766,    78,   737,  -766,  -766,  -766,  -766,   331,  -766,
    -766,   329,  -766,  -766,  -766,  2647,  2239,   698,   733,  -766,
    -766,  3330,  -766,  -766,  -766,  -766,  -766,  -766,  -766,  -766,
    -766,  -766,  -766,  -766,  1936,  -766,  -766,   725,  -766,  -766,
    -766,   728,  -766,   729,   732,  -766,  -766,  -766,    58,  -766,
     788,  -766,    17,  3990,  1160,    42,  -766,  -766,  3900,  3928,
     114,  3789,  3670,   720,   777,   862,  -766,  -766,   990,  -766,
     773,  -766,  2457,  -766,   749,  -766,   897,  -766,  3990,  -766,
    -766,  3990,  -766,  -766,  -766,   313,  -766,   753,  -766,   754,
     757,  -766,  -766,   980,   188,  1119,   878,  1119,   521,  1055,
    4006,  4006,  4006,  4006,  -766,  2239,   765,  -766,  -766,  -766,
    -766,  -766,  -766,  -766,  -766,  1536,  -766,  1527,  1064,   114,
    3990,  3990,   184,  1527,  -766,  3990,  -766,  -766,  3990,  -766,
    -766,   783,  3943,  3943,  3990,  -766,  3943,   135,  1119,  -766,
    1527,  -766,  -766,   359,  -766,  -766,  2328,    97,   188,   587,
    -766,  1078,   769,  -766,   789,  1119,  1587,   790,   793,  3971,
    -766,  3987,  -766,  -766,  -766,  -766,  2239,  -766,    42,   834,
    3943,   361,  -766,  -766,  -766,  -766,  3990,  -766,  -766,  -766,
    -766,  -766,  -766,  -766,   106,  -766,   201,  -766,   771,  -766,
     795,   773,  -766,    17,  -766,  -766,  -766,  -766,  -766,  -766,
     787,   630,  -766,   794,   796,  -766,  -766,  -766,  -766,  -766,
    1587,   812,  -766,  1587,  1587,  -766,  -766,  -766,  1806,  -766,
    -766,   802,  3585,  -766,   804,   806,  -766,  -766,  1119,  -766,
    1633,  1119,  1587,  -766,  -766,  -766,  1100,  -766,  1587,  -766,
    -766,  2429,  -766,   361,  -766,  2457,  -766,  -766,  -766,  -766,
    -766,  -766,  -766,  -766,  -766
};

/* YYPGOTO[NTERM-NUM].  */
static const short yypgoto[] =
{
    -766,  -766,  -766,  -766,  -766,  -416,  -144,  -766,  -766,   288,
    -766,  -766,   119,  -766,   379,   397,  -586,   166,  -766,   109,
    -766,  -766,    26,   277,   408,  -449,  -766,    45,   154,  -583,
    -766,  -765,  -766,  -766,  -546,   134,  -766,    49,  -679,  -766,
    -766,  -766,   317,  -766,  -766,  -766,  -766,  -766,  -766,   139,
     141,  -302,   128,   319,    59,   338,  -602,   256,     9,  -766,
     -43,   547,   -46,  -112,  -617,  1181,   219,  -162,    43,   -48,
    -766,  -766,   507,  -766,   261,  -386,  -747,  -766,  -766,  -766,
    -149,  -766,   641,   649,  -294,  -766,  -766,   435,  -491,  -766,
     -38,  -766,  -766,  -766,   -19,   -54,   -61,  -109,  -766,   432,
    -133,  -291,  -121,   -62,   747,  1318,  -766,  -766,  -766,  -766,
     402,  -766,   599,    92,   -33,   -98,   -74,  -766,  -766,  -766,
     234,   409,  -766,  -766,     1,   920,  -766,   741,   444,  -766,
     304,  -766,  -766,   310,   -29,  -766,   635,   836,  -766,   572,
    -766,  -766,   593,   427,  1376,   -24,    -3,   859,   809,   -52,
    -484,  1221,    12,  -766,  -766,    40,  -766,   948,  -341,    19,
     279,    55,  -766,  -117
};

/* YYTABLE[YYPACT[STATE-NUM]].  What to do in state STATE-NUM.  If
   positive, shift that token.  If negative, reduce the rule which
   number is the opposite.  If zero, do what YYDEFACT says.
   If YYTABLE_NINF, syntax error.  */
#define YYTABLE_NINF -468
static const short yytable[] =
{
      55,    99,   314,   135,   307,   217,   634,   219,   132,   501,
     172,   699,    52,   574,   304,   304,   310,   171,   304,   729,
     816,   771,   100,   716,   262,    82,   305,   305,   492,   218,
     305,   218,   156,   156,   850,   318,   521,   160,   303,   303,
     323,   126,   303,   325,   105,   525,   527,    99,    55,   457,
      16,   141,   170,   186,    57,   123,   535,   123,   439,   310,
     588,   516,   589,   609,   752,   102,   749,   -76,   183,   493,
     494,   390,   225,   317,   495,   248,   102,   248,   102,   492,
     748,    27,    28,    29,   252,   313,   302,   302,   203,   753,
     302,   271,   440,   125,    31,   -40,   693,   140,   310,    61,
      62,   458,   517,   586,   330,   586,   882,   586,   707,   236,
     693,   816,   644,   144,   123,   262,   320,    94,   107,   847,
     493,   230,   156,   330,   -76,   495,   321,   141,   313,   249,
     680,   141,   482,   269,   141,   102,   -76,   679,   783,   262,
     272,   356,   863,   476,   698,   809,   809,    48,   114,   809,
     208,    49,   -40,   304,   304,   827,   738,   288,   645,   114,
     483,   858,   646,   116,   -40,   305,   305,   313,    16,   192,
     803,   440,   477,    60,   761,   449,   859,   140,   303,   385,
     610,   327,    63,   809,   383,   326,   490,   699,   450,   857,
     509,   611,   829,   612,   336,   337,   724,   346,   491,    27,
      28,    29,   478,   610,   112,   813,    48,    16,   402,   366,
      49,   403,   110,   405,   611,   407,   715,   810,    65,    48,
     812,   433,    54,    49,   386,   474,   302,   450,    66,   654,
     141,   141,   171,   655,   590,   656,   479,   801,    27,    28,
      29,   610,   309,   658,   860,   319,   591,   127,   386,   128,
     141,    55,   611,    55,   853,    55,   491,    80,   422,    95,
     141,   143,    99,   693,   348,   330,   262,   170,   349,   693,
     134,   129,    55,   130,   330,   330,   140,   140,    55,   143,
      55,    55,   350,   183,   437,   330,   693,   147,   696,   523,
     455,   156,   461,   465,   149,   837,   140,   470,   361,   778,
     564,   363,   566,   364,   327,   150,   140,   153,   367,   220,
     192,   221,   370,   522,   375,   693,   502,   503,   193,   222,
     528,    80,   529,   336,   337,   194,   532,   206,   207,   536,
     550,   234,   141,   541,   195,   383,   196,   163,   734,   531,
     619,   557,   558,   559,   478,   560,   508,   248,    48,   762,
     763,   766,    49,   397,   586,   263,   304,   167,   238,   241,
     703,   604,   197,   114,   563,   114,   168,   116,   305,   116,
     568,   199,   569,   192,   547,   386,   572,   169,   204,   200,
     303,   141,   837,   202,   141,   141,   141,   693,   141,   326,
     205,   326,  -165,   636,   637,   650,    48,   633,   642,   216,
      49,   141,   209,   141,   224,   141,   273,   141,   800,   141,
    -165,   141,   597,   141,   518,   141,   571,  -467,  -467,   141,
     308,   218,   322,  -165,  -165,  -165,   324,   140,   302,   209,
     210,  -467,    81,   332,   678,   141,   214,   215,   582,   254,
     255,   564,   241,   566,   333,   304,   384,   140,   632,   140,
     334,   140,   211,   141,   335,   141,   345,   305,   330,   141,
     212,   213,   330,   141,   330,   203,   390,   258,   259,   303,
     263,   392,   330,   404,   394,   406,   357,   408,   339,   340,
     341,   140,   358,   304,   842,   442,   356,   236,   342,   343,
     359,   141,   562,   368,   438,   305,    81,   410,   411,   140,
     456,   360,   462,   466,   369,   140,   667,   303,   376,   140,
     405,   766,   407,   443,   387,   508,  -244,   302,  -244,   388,
     660,   398,   418,   433,   399,   676,   757,   760,  -466,   390,
     419,   420,  -244,   239,   242,   694,  -244,   400,   867,   446,
     448,   869,   870,   665,  -244,  -244,   141,   736,   401,   141,
     236,   422,   236,   445,   163,   302,  -244,   409,   396,   423,
     879,   746,   141,   435,   141,   381,   881,   414,   415,   486,
     397,   218,   262,   487,   167,   416,   417,   141,   141,   489,
     203,   443,   515,   168,  -244,   631,  -244,   236,   390,   381,
     533,   141,   140,   804,   169,   537,   805,   549,   538,   163,
    -244,   164,   811,   396,  -244,   165,   539,   652,   140,   653,
     140,   540,  -244,  -244,   542,   397,   544,   242,   547,   167,
      16,   543,    17,  -183,  -244,   141,   141,   825,   168,   214,
     421,   565,   830,   567,   661,   551,   663,    16,   552,   169,
     831,   402,   832,   304,   555,   556,   393,   575,   576,   395,
    -189,    27,    28,    29,   198,   305,   772,   327,   436,   826,
     828,   236,   163,  -456,   164,   664,   577,   303,    27,    28,
      29,   140,   140,   230,   254,   666,   573,   582,   397,   547,
     141,   386,   167,   555,   415,   141,   141,    16,   141,   141,
      16,   168,    48,   676,   578,   582,    49,   579,    50,   141,
     592,   593,   169,   775,   600,   141,   598,   450,   141,   629,
      51,   601,   603,   495,   651,   302,   381,   484,    27,    28,
      29,    27,    28,    29,   606,  -185,   665,   141,   141,   141,
     141,   140,   140,   608,   140,   140,   262,   113,   737,   114,
     657,   115,  -186,   116,   141,   665,   668,   141,   141,   695,
     141,   140,   141,   117,   140,   141,   701,   118,   702,   141,
     141,   141,   113,   141,   114,    91,   119,   141,   116,    74,
     709,   723,   565,   727,   567,   730,   731,   120,   467,   735,
     645,   742,   118,   236,   743,   744,   236,   745,   141,   767,
     468,   119,   768,   140,   140,   752,   236,   141,   140,   692,
     385,   140,   469,   141,   773,   383,   779,   140,   851,   629,
     780,   447,   781,   692,   877,    16,   796,   161,   200,   708,
     775,    16,   711,   191,   581,   839,   861,   795,   625,   884,
     747,    78,   840,   843,   140,   681,   844,   236,   862,   443,
     236,   236,  -244,   864,  -244,   386,    27,    28,    29,   141,
     865,   866,    27,    28,    29,   868,   871,   141,  -244,   236,
     872,   873,  -244,   670,   797,   236,   616,    16,   141,   424,
    -244,  -244,   141,    49,     1,    50,     2,     3,     4,    78,
     184,   184,  -244,   234,   617,    78,   683,   848,   846,   782,
     838,   137,   880,   728,   113,   140,   114,   618,    27,    28,
      29,   798,   751,   263,   821,   138,   878,   874,   697,   785,
     467,    16,   822,   142,   118,   823,   146,   845,   690,   876,
     741,   786,   583,   119,   338,   548,   570,   472,   625,   344,
      16,   450,   690,   635,   469,   473,   247,   640,   247,   351,
     659,   530,    27,    28,    29,   725,   108,    16,   774,   791,
     791,   791,   791,   365,   643,   740,   306,   306,   739,   519,
     306,    27,    28,    29,    16,   250,   692,   450,    18,   545,
     662,   561,   692,   103,   769,    78,     0,     0,    27,    28,
      29,   751,   751,     0,   243,   751,    78,     0,     0,   692,
       0,    78,     0,   142,    78,    27,    28,    29,     0,     0,
       0,    78,   355,     0,     0,   629,     0,     0,   629,   328,
       0,     0,     0,    16,     0,   717,     0,     0,   852,   751,
       0,     0,   381,    16,     0,   751,   756,   759,     0,     0,
     765,     0,   770,   450,     0,   718,     0,    67,    68,    69,
       0,    16,     0,    17,    27,    28,    29,    19,   500,   790,
     792,   793,   794,   506,    27,    28,    29,     0,    70,   629,
       0,    71,   629,   629,   198,    72,     0,   384,   625,   625,
     625,   625,    27,    28,    29,     0,     0,   338,     0,    73,
       0,   629,     0,     0,     0,   690,     0,   629,    16,   453,
     692,   690,   142,   142,     0,   475,   306,    16,     0,   485,
     808,   808,     0,     0,   808,     0,     0,     0,   690,     0,
      78,    16,   142,   717,     0,    78,   789,   184,     0,    27,
      28,    29,   142,     0,   625,   799,     0,   625,    27,    28,
      29,   450,   432,    16,     0,    17,    78,   690,   808,    78,
       0,   184,    27,    28,    29,    78,    78,   481,   184,     0,
     184,     0,    16,   831,   184,     0,    78,   184,     0,     0,
       0,   226,     0,     0,    27,    28,    29,     0,     0,     0,
       0,    16,   450,    48,     0,     0,     0,    49,   625,    50,
       0,   625,   625,    27,    28,    29,   381,     0,   377,     0,
     765,    51,     0,    16,   164,    48,     0,     0,   381,    49,
     625,    50,    27,    28,    29,    16,   625,   200,   247,   690,
       0,   260,     0,   378,     0,    89,   261,   137,     0,     0,
     500,     0,   506,    47,    27,    28,    29,     0,    47,    47,
       0,   138,     0,     0,     0,     0,    27,    28,    29,     0,
     328,     0,     0,   142,    47,    47,    47,    47,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,    47,     0,   142,     0,   142,     0,   142,    67,    68,
      69,     0,    16,     0,    17,     0,     0,     0,    19,   605,
       0,     0,    78,     0,    78,     0,    47,    47,   481,    70,
       0,     0,    71,   614,   615,     0,    72,   142,   306,     0,
     630,     0,     0,    27,    28,    29,     0,     0,    47,     0,
      73,   605,   605,     0,   641,   142,   605,     0,     0,   184,
       0,   142,     0,     0,    47,   142,    47,   226,     0,    78,
       0,     0,     0,    78,     0,    78,     0,     0,   481,     0,
      75,     0,     0,    78,     0,    47,    47,   355,   184,    47,
       0,     0,     0,   712,   713,   714,     0,     0,     0,    16,
       0,    48,     0,     0,     0,    49,     0,     0,     0,     0,
       0,    47,     0,     0,    47,     0,    47,   260,     0,   251,
       0,    89,   261,   137,     0,     0,     0,   306,    75,     0,
      27,    28,    29,     0,    75,     0,     0,   138,    77,     0,
     453,     0,     0,     0,     0,     0,     0,    16,   142,   200,
       0,    47,     0,   202,     0,    78,    78,    78,     0,   722,
       0,     0,     0,   726,   142,   306,   142,    47,     0,    47,
      47,     0,    47,     0,   432,     0,     0,    47,    27,    28,
      29,    47,    47,    47,     0,     0,    77,   182,   182,     0,
       0,     0,    77,     0,     0,     0,     0,     0,    47,     0,
     184,    47,   162,    68,    69,     0,    16,     0,    17,     0,
       0,   481,    19,     0,   620,     0,     0,     0,     0,     0,
       0,   185,     0,    70,    75,     0,    71,   142,   142,     0,
      72,     0,   106,     0,   434,    75,     0,    27,    28,    29,
      75,   621,     0,    75,    73,     0,    16,     0,    48,     0,
      75,     0,    49,     0,    50,     0,     0,     0,     0,     0,
       0,     0,     0,   182,   182,     0,   227,   182,   681,     0,
     137,     0,   722,     0,   784,   787,   788,    27,    28,    29,
       0,     0,   182,    47,   138,    47,     0,   142,   142,     0,
     142,   142,     0,    77,     0,   682,     0,     0,    77,     0,
      16,   182,   424,     0,     0,     0,    49,   142,    77,    16,
     142,    17,     0,    18,   481,    19,   817,   820,     0,   683,
     684,     0,     0,     0,   137,   306,     0,     0,   836,   426,
     722,    27,    28,    29,   841,     0,     0,    47,   138,     0,
      27,    28,    29,     0,     0,     0,     0,     0,     0,   142,
     142,   802,     0,     0,   142,   621,     0,   142,     0,    75,
      16,    47,    48,   142,    75,     0,    49,     0,    50,     0,
       0,     0,     0,     0,   226,     0,     0,     0,     0,     0,
     227,     0,     0,     0,   137,    75,     0,     0,    75,     0,
     142,    27,    28,    29,    75,    75,     0,     0,   138,     0,
     856,   377,   182,   182,     0,    75,    16,   817,    48,     0,
     820,   628,    49,     0,     0,   836,     0,    77,     0,     0,
       0,     0,    77,     0,   182,   875,   251,     0,     0,     0,
     137,     0,     0,   454,     0,     0,     0,    27,    28,    29,
       0,     0,     0,   182,   138,     0,    77,     0,   182,     0,
       0,   142,   182,   182,    47,   182,    47,   182,     0,     0,
       0,   182,     0,   182,   182,    16,     0,    48,     0,     0,
       0,    49,   883,    50,     0,     0,    47,     0,    47,     0,
       0,    16,     0,    48,     0,    51,     0,    49,     0,    50,
       0,     0,   310,     0,     0,     0,    27,    28,    29,     0,
       0,   691,     0,    47,    47,    47,     0,   277,   278,   279,
       0,   628,    27,    28,    29,   691,     0,     0,     0,     0,
     285,    68,    69,     0,    16,     0,    17,     0,     0,     0,
      19,    75,   311,    75,     0,     0,   434,     0,   677,   185,
       0,    70,     0,     0,   286,     0,     0,   226,    72,   312,
       0,     0,     0,     0,     0,    27,    28,    29,     0,     0,
       0,   313,    73,    16,     0,   200,     0,   201,     0,   202,
       0,     0,     0,     0,   377,     0,     0,     0,    75,    16,
     164,    48,    75,     0,    75,    49,   182,    50,     0,    77,
       0,    77,    75,   226,    27,    28,    29,   260,     0,   378,
       0,    89,   379,   137,   750,   182,    47,    47,     0,     0,
      27,    28,    29,     0,     0,     0,     0,   138,   182,   182,
     377,   182,     0,   182,     0,    16,   182,    48,     0,     0,
       0,    49,     0,    50,     0,     0,   182,     0,   459,     0,
     182,     0,   182,   260,     0,   378,     0,    89,   379,   137,
     182,   628,   628,   628,   628,   182,    27,    28,    29,     0,
       0,     0,     0,   138,    75,    75,    75,     0,   691,     0,
      16,     0,    48,     0,   691,     0,    49,   226,    50,     0,
       0,     0,     0,   750,   750,     0,     0,   750,     0,     0,
      51,   691,     0,     0,   182,     0,    47,     0,     0,     0,
       0,    27,    28,    29,     0,     0,   677,   628,     0,    16,
     628,    48,     0,     0,     0,    49,     0,    50,     0,     0,
     691,   750,    77,    77,    77,     0,     0,   750,     0,   227,
       0,     0,   182,   137,     0,     0,     0,     0,     0,     0,
      27,    28,    29,     0,     0,     0,     0,   138,     0,     0,
       0,     0,     0,     0,    16,     0,    17,    47,    18,     0,
      19,   628,     0,     0,   628,   628,   671,   182,     6,     0,
       0,     0,     0,     7,   426,     0,   672,     8,     0,     0,
       0,     9,     0,   628,     0,    27,    28,    29,     0,   628,
      10,     0,   691,    11,    12,     0,    13,    14,    15,    83,
      16,    84,    17,    85,    18,    86,    19,    20,    21,     0,
       0,     0,     0,    22,     0,    87,     0,    24,     0,    88,
      25,     6,    89,    90,    26,     0,     7,    91,    92,     0,
       8,    27,    28,    29,     9,     0,     0,     0,    30,    93,
       0,     0,   226,    10,     0,     0,    11,    12,     0,    13,
      14,    15,     0,    16,     0,    17,     0,    18,     0,    19,
      20,    21,     0,     0,     0,     0,    22,     0,    23,     0,
      24,     0,     0,    25,    16,     0,    48,    26,     0,   106,
      49,     0,     0,     0,    27,    28,    29,     0,     6,     0,
       0,    30,   182,     7,   251,     0,     0,     8,   137,     0,
     270,     9,     0,     0,     0,    27,    28,    29,     0,     0,
      10,     0,   138,    11,    12,     0,    13,    14,    15,     0,
      16,     0,    17,     0,    18,     0,    19,    20,    21,     0,
       0,     0,     0,    22,     6,    23,     0,    24,     0,     7,
      25,     0,     0,     8,    26,     0,  -437,     9,     0,     0,
       0,    27,    28,    29,     0,     0,    10,     0,    30,    11,
      12,     0,    13,    14,    15,     0,    16,     0,    17,     0,
      18,     0,    19,    20,    21,     0,     0,     0,     0,    22,
       6,    23,     0,    24,     0,     7,    25,     0,     0,     8,
      26,     0,  -436,     9,     0,     0,     0,    27,    28,    29,
       0,     0,    10,     0,    30,    11,    12,     0,    13,    14,
      15,     0,    16,     0,    17,     0,    18,     0,    19,    20,
      21,     0,     0,     0,     0,    22,     6,    23,     0,    24,
       0,     7,    25,     0,     0,     8,    26,     0,     0,   371,
       0,     0,     0,    27,    28,    29,     0,     0,    10,     0,
      30,    11,    12,     0,    13,    14,    15,     0,    16,     0,
      17,     0,    18,     0,    19,    20,    21,     0,     0,   310,
       0,    22,     0,    23,     0,    24,     0,     0,    25,     0,
       0,     0,    26,     0,   277,   278,   279,     0,     0,    27,
      28,    29,     0,     0,     0,     0,    30,   285,    68,    69,
       0,    16,     0,    17,     0,     0,     0,    19,   226,     0,
       0,     0,     0,     0,     0,     0,   185,     0,    70,     0,
       0,   286,     0,     0,     0,    72,   824,   226,     0,     0,
       0,     0,    27,    28,    29,   377,     0,     0,   313,    73,
      16,     0,    48,    16,     0,    48,    49,     0,    50,    49,
       0,    50,     0,     0,     0,   226,     0,     0,   260,    16,
     378,    48,    89,   261,   137,    49,   131,     0,     0,     0,
     681,    27,    28,    29,    27,    28,    29,     0,   138,   251,
       0,     0,  -155,   137,     0,     0,     0,    16,     0,    48,
      27,    28,    29,    49,     0,    50,     0,   138,   226,     0,
       0,     0,    16,     0,   424,     0,     0,   251,    49,     0,
       0,   137,     0,     0,     0,     0,     0,     0,    27,    28,
      29,   683,   684,     0,     0,   138,   137,     0,     0,     0,
      16,     0,    48,    27,    28,    29,    49,     0,     0,     0,
     138,     0,     0,     0,     0,     0,     0,     0,     0,     7,
     251,     0,     0,     8,   137,     0,     0,   154,     0,     0,
       0,    27,    28,    29,     0,     0,    10,     0,   138,    11,
      12,     0,    13,    14,    15,     0,    16,     0,    17,     0,
      18,     0,    19,    20,    21,     0,     0,     0,     0,    22,
       0,    23,     0,    24,     0,     7,    25,     0,     0,     8,
      26,   155,     0,     9,     0,     0,     0,    27,    28,    29,
       0,     0,    10,     0,    30,    11,    12,     0,    13,    14,
      15,     0,    16,     0,    17,     0,    18,     0,    19,    20,
      21,     0,     0,     0,     0,    22,     0,   240,     0,    24,
       0,     0,    25,     0,     7,   362,    26,     0,     8,     0,
       0,     0,     9,    27,    28,    29,     0,     0,     0,     0,
      30,    10,     0,     0,    11,    12,     0,    13,    14,    15,
       0,    16,     0,    17,     0,    18,     0,    19,    20,    21,
       0,     0,     0,     0,    22,     0,     0,     0,    24,     0,
       0,    25,     0,     7,   198,    26,     0,     8,     0,     0,
       0,     9,    27,    28,    29,     0,     0,     0,     0,    30,
      10,     0,     0,    11,    12,     0,    13,    14,    15,     0,
      16,     0,    17,     0,    18,     0,    19,    20,    21,     0,
       0,     0,     0,    22,     0,    23,     0,    24,     0,     7,
      25,     0,     0,     8,    26,     0,     0,     9,     0,     0,
       0,    27,    28,    29,     0,     0,    10,     0,    30,    11,
      12,     0,    13,    14,    15,     0,    16,     0,    17,     0,
      18,     0,    19,    20,    21,     0,     0,     0,     0,    22,
       0,   237,     0,    24,     0,     7,    25,     0,     0,     8,
      26,     0,     0,     9,     0,     0,     0,    27,    28,    29,
       0,     0,    10,     0,    30,    11,    12,     0,    13,    14,
      15,     0,    16,     0,    17,     0,    18,     0,    19,    20,
      21,     0,     0,     0,     0,    22,     0,   240,     0,    24,
       0,     7,    25,     0,     0,     8,    26,     0,     0,   154,
       0,     0,     0,    27,    28,    29,     0,     0,    10,     0,
      30,    11,    12,     0,    13,    14,    15,     0,    16,     0,
      17,     0,    18,     0,    19,    20,    21,     0,     0,     0,
       0,    22,     0,    23,     0,    24,     0,     7,    25,     0,
       0,     8,    26,     0,     0,     9,     0,     0,     0,    27,
      28,    29,     0,   463,    10,     0,    30,    11,    12,     0,
      13,    14,    15,     0,    16,     0,    17,     0,    18,     0,
      19,    20,    21,     0,     0,     0,     0,    22,     0,     0,
       0,    24,     0,     0,    25,    16,     0,    48,    26,     0,
       0,    49,     0,    50,     0,    27,    28,    29,   275,   276,
       0,     0,    30,     0,     0,    51,   277,   278,   279,   280,
     281,   282,     0,     0,   283,   284,    27,    28,    29,   285,
      68,    69,     0,    16,     0,    17,     0,     0,     0,    19,
       0,     0,     0,     0,     0,     0,     0,     0,   185,     0,
      70,     0,     0,   286,     0,     0,     0,    72,   287,     0,
       0,     0,     0,   288,    27,    28,    29,   289,   290,   275,
     276,    73,     0,     0,     0,     0,     0,   277,   278,   279,
     280,   281,   282,     0,     0,   283,   284,     0,     0,     0,
     285,    68,    69,     0,    16,     0,    17,     0,     0,     0,
      19,     0,     0,     0,     0,     0,     0,     0,     0,   185,
       0,    70,     0,     0,   286,     0,     0,     0,    72,     0,
       0,     0,     0,     0,     0,    27,    28,    29,   289,   290,
       0,    12,    73,    13,    14,    15,     0,    16,     0,    17,
       0,    18,     0,    19,    20,    21,     0,     0,     0,     0,
       0,     0,     0,     0,    24,     0,     0,    25,     0,     0,
       0,    26,     0,     0,     0,     0,     0,     0,    27,    28,
      29,     0,     0,     0,     0,    30,    67,    68,    69,   113,
      16,   114,    17,     0,     0,   116,    19,     0,     0,     0,
    -248,   192,     0,     0,     0,   504,     0,    70,     0,   118,
      71,     0,  -248,     0,    72,     0,     0,   468,   119,     0,
       0,    27,    28,    29,     0,     0,     0,     0,    73,   505,
     162,    68,    69,   163,    16,   164,    17,     0,     0,   165,
      19,     0,     0,     0,     0,     0,     0,     0,     0,   166,
       0,    70,     0,   167,    71,     0,    89,    90,    72,     0,
       0,     0,   168,     0,     0,    27,    28,    29,     0,     0,
       0,     0,    73,   169,   285,    68,    69,   163,    16,   164,
      17,     0,     0,   165,    19,     0,     0,     0,     0,     0,
       0,     0,     0,   166,     0,    70,     0,   167,   286,     0,
      89,    90,    72,     0,     0,     0,   168,     0,     0,    27,
      28,    29,     0,     0,     0,     0,    73,   169,    67,    68,
      69,   113,    16,   114,    17,     0,     0,   116,    19,     0,
       0,     0,     0,   192,     0,     0,     0,   504,     0,    70,
       0,   118,    71,     0,     0,     0,    72,     0,     0,   468,
     119,     0,     0,    27,    28,    29,     0,     0,     0,     0,
      73,   505,   162,    68,    69,     0,    16,     0,    17,     0,
       0,     0,    19,     0,     0,     0,     0,     0,     0,     0,
       0,   185,     0,    70,     0,     0,    71,     0,     0,     0,
      72,   510,     0,     0,     0,     0,     0,    27,    28,    29,
       0,    67,    68,    69,    73,    16,     0,    17,     0,     0,
       0,    19,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,    70,   190,     0,    71,     0,     0,     0,    72,
       0,     0,     0,     0,     0,     0,    27,    28,    29,     0,
      67,    68,    69,    73,    16,     0,    17,     0,     0,     0,
      19,     0,     0,     0,     0,     0,     0,     0,     0,   520,
       0,    70,     0,     0,    71,     0,     0,     0,    72,     0,
       0,     0,     0,     0,     0,    27,    28,    29,     0,   162,
      68,    69,    73,    16,     0,    17,     0,     0,     0,    19,
       0,     0,     0,     0,     0,     0,     0,     0,   185,     0,
      70,     0,     0,    71,     0,     0,     0,    72,     0,     0,
       0,     0,     0,     0,    27,    28,    29,     0,    67,    68,
      69,    73,    16,     0,    17,     0,     0,     0,    19,     0,
       0,     0,     0,     0,     0,     0,     0,   524,     0,    70,
       0,     0,    71,     0,     0,     0,    72,     0,     0,     0,
       0,     0,     0,    27,    28,    29,     0,    67,    68,    69,
      73,    16,     0,    17,     0,     0,     0,    19,     0,     0,
       0,     0,     0,     0,     0,     0,   526,     0,    70,     0,
       0,    71,     0,     0,     0,    72,     0,     0,     0,     0,
       0,     0,    27,    28,    29,     0,    67,    68,    69,    73,
      16,     0,    17,     0,     0,     0,    19,     0,     0,     0,
       0,     0,     0,     0,     0,   534,     0,    70,     0,     0,
      71,     0,     0,     0,    72,     0,     0,     0,     0,     0,
       0,    27,    28,    29,     0,    67,    68,    69,    73,    16,
       0,    17,     0,     0,     0,    19,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,    70,     0,     0,    71,
       0,     0,   607,    72,     0,     0,     0,     0,     0,     0,
      27,    28,    29,     0,   638,    68,    69,    73,    16,     0,
      17,     0,     0,     0,    19,     0,     0,     0,     0,     0,
       0,     0,     0,   185,     0,    70,     0,     0,    71,     0,
       0,     0,    72,     0,     0,     0,     0,     0,     0,    27,
      28,    29,     0,    67,    68,    69,    73,    16,     0,    17,
       0,     0,     0,    19,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,    70,     0,     0,    71,    16,   114,
      48,    72,     0,     0,    49,     0,     0,     0,    27,    28,
      29,     0,     0,     0,     0,    73,     0,   764,   251,  -184,
       0,    16,   137,    48,     0,   761,     0,    49,     0,    27,
      28,    29,     0,     0,     0,     0,   138,     0,     0,   391,
      16,   136,    48,   412,   413,   137,    49,     0,     0,     0,
       0,     0,    27,    28,    29,     0,     0,     0,   391,   138,
     136,     0,   553,   554,   137,     0,     0,     0,    16,     0,
      48,    27,    28,    29,    49,     0,     0,     0,   138,     0,
       0,     0,     0,    16,   114,    48,   391,     0,   136,    49,
     553,   413,   137,     0,     0,     0,     0,     0,     0,    27,
      28,    29,   764,   251,     0,     0,   138,   137,     0,     0,
     761,    16,     0,    48,    27,    28,    29,    49,     0,     0,
       0,   138,     0,     0,     0,     0,     0,     0,     0,     0,
      16,   136,    48,   256,   257,   137,    49,     0,     0,     0,
       0,     0,    27,    28,    29,     0,     0,     0,   391,   138,
     136,  -184,     0,     0,   137,     0,     0,     0,    16,     0,
      48,    27,    28,    29,    49,     0,     0,   580,   138,     0,
       0,     0,     0,     0,    16,     0,    48,     0,   136,  -184,
      49,     0,   137,     0,     0,     0,     0,     0,     0,    27,
      28,    29,   733,     0,   136,  -184,   138,     0,   137,     0,
       0,     0,    16,   114,    48,    27,    28,    29,    49,     0,
       0,     0,   138,     0,     0,     0,     0,     0,    16,     0,
      48,    16,   136,    48,    49,     0,   137,    49,     0,   761,
       0,     0,     0,    27,    28,    29,   389,     0,   136,   391,
     138,   136,   137,     0,     0,   137,     0,     0,     0,    27,
      28,    29,    27,    28,    29,    16,   138,    48,     0,   138,
       0,    49,     0,     0,   594,     0,     0,     0,     0,     0,
      16,     0,    48,     0,     0,   136,    49,     0,     0,   137,
       0,     0,     0,     0,     0,     0,    27,    28,    29,     0,
     136,  -184,     0,   138,   137,     0,     0,     0,    16,     0,
      48,    27,    28,    29,    49,     0,     0,     0,   138,     0,
       0,     0,     0,    16,     0,    48,   732,     0,   136,    49,
       0,     0,   137,     0,     0,     0,     0,     0,     0,    27,
      28,    29,   755,   251,     0,     0,   138,   137,     0,     0,
       0,    16,     0,    48,    27,    28,    29,    49,     0,     0,
       0,   138,     0,     0,     0,     0,    16,     0,    48,     0,
     758,   251,    49,     0,     0,   137,     0,     0,     0,     0,
       0,     0,    27,    28,    29,   806,   251,     0,     0,   138,
     137,     0,     0,     0,    16,     0,    48,    27,    28,    29,
      49,     0,    50,     0,   138,     0,     0,     0,     0,     0,
      16,     0,    48,    16,   227,    48,    49,     0,   137,    49,
       0,     0,     0,     0,     0,    27,    28,    29,   733,    16,
     136,    48,   138,   136,   137,    49,     0,   137,     0,     0,
       0,    27,    28,    29,    27,    28,    29,     0,   138,   251,
      16,   138,   424,   137,    18,     0,   425,     0,     0,     0,
      27,    28,    29,     0,     0,     0,     0,   138,     0,     0,
     426,     0,   427,   428,    16,     0,   424,     0,    18,   429,
     425,    27,    28,    29,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,   426,     0,     0,   669,     0,     0,
       0,     0,     0,   429,     0,    27,    28,    29
};

static const short yycheck[] =
{
       3,    25,   151,    51,   148,   103,   497,   105,    51,   303,
      71,   594,     3,   429,   147,   148,     1,    71,   151,   621,
     767,   700,    25,   609,   136,    24,   147,   148,     1,   103,
     151,   105,    65,    66,   799,   152,   327,    66,   147,   148,
     157,    40,   151,   160,    25,   336,   337,    71,    51,     1,
      33,    54,    71,    72,    62,    36,   347,    38,     1,     1,
     446,     1,   448,   479,    22,    25,   683,     1,    71,    42,
      43,   233,   110,    58,    47,   127,    36,   129,    38,     1,
     682,    64,    65,    66,   130,    70,   147,   148,    91,    47,
     151,   137,    35,    38,     2,     1,   580,    54,     1,     7,
       8,    53,    42,   444,   166,   446,   871,   448,   599,   112,
     594,   858,     1,     1,    95,   227,   154,    25,    26,   798,
      42,   112,   155,   185,    58,    47,   155,   130,    70,   128,
     579,   134,     1,   136,   137,    95,    70,     1,   724,   251,
     143,   193,   821,   287,   593,   762,   763,    35,    34,   766,
      95,    39,    58,   286,   287,    58,   647,    63,    47,    34,
      29,    55,    51,    38,    70,   286,   287,    70,    33,    44,
     753,    35,     1,     0,    60,     1,    70,   134,   287,   227,
      53,   162,    69,   800,   227,    60,    43,   770,    53,   806,
     307,    64,   778,    66,   175,   176,   612,    72,    55,    64,
      65,    66,    31,    53,    43,    70,    35,    33,   251,   212,
      39,   254,    13,   256,    64,   258,    66,   763,    69,    35,
     766,   273,     3,    39,   227,   286,   287,    53,    69,   520,
     233,   234,   286,   524,    43,   526,    65,    53,    64,    65,
      66,    53,   150,   534,    43,   153,    55,    69,   251,    44,
     253,   254,    64,   256,   800,   258,    55,    23,    43,    25,
     263,    46,   286,   747,    55,   327,   378,   286,    59,   753,
      51,    69,   275,    43,   336,   337,   233,   234,   281,    46,
     283,   284,   190,   286,   275,   347,   770,    69,   590,   335,
     281,   324,   283,   284,     7,   779,   253,   285,   206,   715,
     412,   209,   414,   211,   285,    11,   263,    15,   216,    45,
      44,    47,   220,   332,   222,   799,   304,   305,    69,    55,
     339,    87,   341,   304,   305,    56,   345,    55,    56,   348,
     378,   112,   335,   371,    56,   378,    56,    32,   632,   342,
     489,   387,   388,   389,    31,   391,   306,   399,    35,   690,
     691,   692,    39,    48,   695,   136,   489,    52,   124,   125,
       1,   470,    56,    34,   410,    34,    61,    38,   489,    38,
     416,    56,   418,    44,   377,   378,   422,    72,    56,    35,
     489,   384,   866,    39,   387,   388,   389,   871,   391,    60,
      56,    60,    33,   502,   503,   512,    35,   495,   507,    42,
      39,   404,    55,   406,    59,   408,    53,   410,   749,   412,
      51,   414,   458,   416,   322,   418,   419,    55,    56,   422,
      69,   495,    49,    64,    65,    66,    58,   384,   489,    55,
      56,    69,    23,    55,   578,   438,    55,    56,   441,    55,
      56,   553,   208,   555,    56,   578,   227,   404,   494,   406,
      56,   408,    47,   456,    43,   458,    42,   578,   520,   462,
      55,    56,   524,   466,   526,   468,   628,    55,    56,   578,
     251,   237,   534,   254,   240,   256,    60,   258,    55,    56,
      47,   438,    60,   616,   786,     1,   538,   490,    55,    56,
      60,   494,   400,    56,   275,   616,    87,    55,    56,   456,
     281,    60,   283,   284,    56,   462,   552,   616,    47,   466,
     553,   852,   555,    29,    51,   475,    32,   578,    34,    54,
     539,    70,    47,   575,    55,   577,   688,   689,    42,   691,
      55,    56,    48,   124,   125,   581,    52,    42,   840,   278,
     279,   843,   844,   546,    60,    61,   549,   645,    70,   552,
     553,    43,   555,     1,    32,   616,    72,    56,    36,    59,
     862,   678,   565,    13,   567,   227,   868,    55,    56,    70,
      48,   645,   684,    58,    52,    55,    56,   580,   581,    58,
     583,    29,    12,    61,    32,   493,    34,   590,   750,   251,
      29,   594,   549,   755,    72,    70,   758,   378,    55,    32,
      48,    34,   764,    36,    52,    38,    42,   515,   565,   517,
     567,    56,    60,    61,    49,    48,    45,   208,   621,    52,
      33,    55,    35,    54,    72,   628,   629,   776,    61,    55,
      56,   412,    45,   414,   542,    56,   544,    33,    54,    72,
      53,   684,    55,   776,    55,    56,   237,    55,    56,   240,
      54,    64,    65,    66,    56,   776,   702,   638,     1,   776,
     777,   664,    32,    53,    34,    61,    53,   776,    64,    65,
      66,   628,   629,   664,    55,    56,    56,   680,    48,   682,
     683,   684,    52,    55,    56,   688,   689,    33,   691,   692,
      33,    61,    35,   745,    69,   698,    39,    54,    41,   702,
      31,    54,    72,   706,    54,   708,    47,    53,   711,   490,
      53,    13,    54,    47,    58,   776,   378,    63,    64,    65,
      66,    64,    65,    66,    56,    54,   729,   730,   731,   732,
     733,   688,   689,    56,   691,   692,   848,    32,   646,    34,
      56,    36,    54,    38,   747,   748,    56,   750,   751,    55,
     753,   708,   755,    48,   711,   758,    56,    52,    55,   762,
     763,   764,    32,   766,    34,    60,    61,   770,    38,    22,
      69,    53,   553,    31,   555,    51,    54,    72,    48,    42,
      47,    56,    52,   786,    56,    56,   789,    55,   791,    69,
      60,    61,    15,   750,   751,    22,   799,   800,   755,   580,
     848,   758,    72,   806,    55,   848,    53,   764,   799,   590,
      56,     1,    55,   594,   860,    33,    51,    70,    35,   600,
     823,    33,   603,    76,    42,    56,    55,   735,   490,   875,
      42,    22,    43,    43,   791,     1,    43,   840,    43,    29,
     843,   844,    32,    56,    34,   848,    64,    65,    66,   852,
      56,    55,    64,    65,    66,    43,    54,   860,    48,   862,
      56,    55,    52,   575,   745,   868,   487,    33,   871,    35,
      60,    61,   875,    39,     1,    41,     3,     4,     5,    70,
      71,    72,    72,   664,   487,    76,    52,    53,   796,   723,
     781,    57,   866,   616,    32,   852,    34,   489,    64,    65,
      66,   747,   683,   684,   770,    71,   861,   858,   591,    31,
      48,    33,   773,    54,    52,   774,    57,   789,   580,   860,
     664,    43,    60,    61,   177,   378,   419,   286,   590,   182,
      33,    53,   594,   498,    72,   286,   127,   505,   129,   192,
     538,   342,    64,    65,    66,    31,    26,    33,    51,   730,
     731,   732,   733,   212,   510,   651,   147,   148,   648,   324,
     151,    64,    65,    66,    33,   129,   747,    53,    37,   376,
     543,   399,   753,    25,   695,   166,    -1,    -1,    64,    65,
      66,   762,   763,    -1,    53,   766,   177,    -1,    -1,   770,
      -1,   182,    -1,   134,   185,    64,    65,    66,    -1,    -1,
      -1,   192,   193,    -1,    -1,   786,    -1,    -1,   789,     1,
      -1,    -1,    -1,    33,    -1,    35,    -1,    -1,   799,   800,
      -1,    -1,   684,    33,    -1,   806,   688,   689,    -1,    -1,
     692,    -1,    42,    53,    -1,    55,    -1,    29,    30,    31,
      -1,    33,    -1,    35,    64,    65,    66,    39,   301,   730,
     731,   732,   733,   306,    64,    65,    66,    -1,    50,   840,
      -1,    53,   843,   844,    56,    57,    -1,   848,   730,   731,
     732,   733,    64,    65,    66,    -1,    -1,   330,    -1,    71,
      -1,   862,    -1,    -1,    -1,   747,    -1,   868,    33,   280,
     871,   753,   233,   234,    -1,   286,   287,    33,    -1,   290,
     762,   763,    -1,    -1,   766,    -1,    -1,    -1,   770,    -1,
     301,    33,   253,    35,    -1,   306,    61,   308,    -1,    64,
      65,    66,   263,    -1,   786,    61,    -1,   789,    64,    65,
      66,    53,   273,    33,    -1,    35,   327,   799,   800,   330,
      -1,   332,    64,    65,    66,   336,   337,   288,   339,    -1,
     341,    -1,    33,    53,   345,    -1,   347,   348,    -1,    -1,
      -1,     1,    -1,    -1,    64,    65,    66,    -1,    -1,    -1,
      -1,    33,    53,    35,    -1,    -1,    -1,    39,   840,    41,
      -1,   843,   844,    64,    65,    66,   848,    -1,    28,    -1,
     852,    53,    -1,    33,    34,    35,    -1,    -1,   860,    39,
     862,    41,    64,    65,    66,    33,   868,    35,   399,   871,
      -1,    51,    -1,    53,    -1,    55,    56,    57,    -1,    -1,
     473,    -1,   475,     2,    64,    65,    66,    -1,     7,     8,
      -1,    71,    -1,    -1,    -1,    -1,    64,    65,    66,    -1,
       1,    -1,    -1,   384,    23,    24,    25,    26,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    40,    -1,   404,    -1,   406,    -1,   408,    29,    30,
      31,    -1,    33,    -1,    35,    -1,    -1,    -1,    39,   470,
      -1,    -1,   473,    -1,   475,    -1,    65,    66,   429,    50,
      -1,    -1,    53,   484,   485,    -1,    57,   438,   489,    -1,
     491,    -1,    -1,    64,    65,    66,    -1,    -1,    87,    -1,
      71,   502,   503,    -1,   505,   456,   507,    -1,    -1,   510,
      -1,   462,    -1,    -1,   103,   466,   105,     1,    -1,   520,
      -1,    -1,    -1,   524,    -1,   526,    -1,    -1,   479,    -1,
      22,    -1,    -1,   534,    -1,   124,   125,   538,   539,   128,
      -1,    -1,    -1,   606,   607,   608,    -1,    -1,    -1,    33,
      -1,    35,    -1,    -1,    -1,    39,    -1,    -1,    -1,    -1,
      -1,   150,    -1,    -1,   153,    -1,   155,    51,    -1,    53,
      -1,    55,    56,    57,    -1,    -1,    -1,   578,    70,    -1,
      64,    65,    66,    -1,    76,    -1,    -1,    71,    22,    -1,
     591,    -1,    -1,    -1,    -1,    -1,    -1,    33,   549,    35,
      -1,   190,    -1,    39,    -1,   606,   607,   608,    -1,   610,
      -1,    -1,    -1,   614,   565,   616,   567,   206,    -1,   208,
     209,    -1,   211,    -1,   575,    -1,    -1,   216,    64,    65,
      66,   220,   221,   222,    -1,    -1,    70,    71,    72,    -1,
      -1,    -1,    76,    -1,    -1,    -1,    -1,    -1,   237,    -1,
     651,   240,    29,    30,    31,    -1,    33,    -1,    35,    -1,
      -1,   612,    39,    -1,     1,    -1,    -1,    -1,    -1,    -1,
      -1,    48,    -1,    50,   166,    -1,    53,   628,   629,    -1,
      57,    -1,    59,    -1,   273,   177,    -1,    64,    65,    66,
     182,    28,    -1,   185,    71,    -1,    33,    -1,    35,    -1,
     192,    -1,    39,    -1,    41,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,   147,   148,    -1,    53,   151,     1,    -1,
      57,    -1,   723,    -1,   725,   726,   727,    64,    65,    66,
      -1,    -1,   166,   322,    71,   324,    -1,   688,   689,    -1,
     691,   692,    -1,   177,    -1,    28,    -1,    -1,   182,    -1,
      33,   185,    35,    -1,    -1,    -1,    39,   708,   192,    33,
     711,    35,    -1,    37,   715,    39,   767,   768,    -1,    52,
      53,    -1,    -1,    -1,    57,   776,    -1,    -1,   779,    53,
     781,    64,    65,    66,   785,    -1,    -1,   376,    71,    -1,
      64,    65,    66,    -1,    -1,    -1,    -1,    -1,    -1,   750,
     751,   752,    -1,    -1,   755,    28,    -1,   758,    -1,   301,
      33,   400,    35,   764,   306,    -1,    39,    -1,    41,    -1,
      -1,    -1,    -1,    -1,     1,    -1,    -1,    -1,    -1,    -1,
      53,    -1,    -1,    -1,    57,   327,    -1,    -1,   330,    -1,
     791,    64,    65,    66,   336,   337,    -1,    -1,    71,    -1,
     801,    28,   286,   287,    -1,   347,    33,   858,    35,    -1,
     861,   490,    39,    -1,    -1,   866,    -1,   301,    -1,    -1,
      -1,    -1,   306,    -1,   308,    52,    53,    -1,    -1,    -1,
      57,    -1,    -1,     1,    -1,    -1,    -1,    64,    65,    66,
      -1,    -1,    -1,   327,    71,    -1,   330,    -1,   332,    -1,
      -1,   852,   336,   337,   493,   339,   495,   341,    -1,    -1,
      -1,   345,    -1,   347,   348,    33,    -1,    35,    -1,    -1,
      -1,    39,   873,    41,    -1,    -1,   515,    -1,   517,    -1,
      -1,    33,    -1,    35,    -1,    53,    -1,    39,    -1,    41,
      -1,    -1,     1,    -1,    -1,    -1,    64,    65,    66,    -1,
      -1,   580,    -1,   542,   543,   544,    -1,    16,    17,    18,
      -1,   590,    64,    65,    66,   594,    -1,    -1,    -1,    -1,
      29,    30,    31,    -1,    33,    -1,    35,    -1,    -1,    -1,
      39,   473,    41,   475,    -1,    -1,   575,    -1,   577,    48,
      -1,    50,    -1,    -1,    53,    -1,    -1,     1,    57,    58,
      -1,    -1,    -1,    -1,    -1,    64,    65,    66,    -1,    -1,
      -1,    70,    71,    33,    -1,    35,    -1,    37,    -1,    39,
      -1,    -1,    -1,    -1,    28,    -1,    -1,    -1,   520,    33,
      34,    35,   524,    -1,   526,    39,   470,    41,    -1,   473,
      -1,   475,   534,     1,    64,    65,    66,    51,    -1,    53,
      -1,    55,    56,    57,   683,   489,   645,   646,    -1,    -1,
      64,    65,    66,    -1,    -1,    -1,    -1,    71,   502,   503,
      28,   505,    -1,   507,    -1,    33,   510,    35,    -1,    -1,
      -1,    39,    -1,    41,    -1,    -1,   520,    -1,     1,    -1,
     524,    -1,   526,    51,    -1,    53,    -1,    55,    56,    57,
     534,   730,   731,   732,   733,   539,    64,    65,    66,    -1,
      -1,    -1,    -1,    71,   606,   607,   608,    -1,   747,    -1,
      33,    -1,    35,    -1,   753,    -1,    39,     1,    41,    -1,
      -1,    -1,    -1,   762,   763,    -1,    -1,   766,    -1,    -1,
      53,   770,    -1,    -1,   578,    -1,   735,    -1,    -1,    -1,
      -1,    64,    65,    66,    -1,    -1,   745,   786,    -1,    33,
     789,    35,    -1,    -1,    -1,    39,    -1,    41,    -1,    -1,
     799,   800,   606,   607,   608,    -1,    -1,   806,    -1,    53,
      -1,    -1,   616,    57,    -1,    -1,    -1,    -1,    -1,    -1,
      64,    65,    66,    -1,    -1,    -1,    -1,    71,    -1,    -1,
      -1,    -1,    -1,    -1,    33,    -1,    35,   796,    37,    -1,
      39,   840,    -1,    -1,   843,   844,    45,   651,     1,    -1,
      -1,    -1,    -1,     6,    53,    -1,    55,    10,    -1,    -1,
      -1,    14,    -1,   862,    -1,    64,    65,    66,    -1,   868,
      23,    -1,   871,    26,    27,    -1,    29,    30,    31,    32,
      33,    34,    35,    36,    37,    38,    39,    40,    41,    -1,
      -1,    -1,    -1,    46,    -1,    48,    -1,    50,    -1,    52,
      53,     1,    55,    56,    57,    -1,     6,    60,    61,    -1,
      10,    64,    65,    66,    14,    -1,    -1,    -1,    71,    72,
      -1,    -1,     1,    23,    -1,    -1,    26,    27,    -1,    29,
      30,    31,    -1,    33,    -1,    35,    -1,    37,    -1,    39,
      40,    41,    -1,    -1,    -1,    -1,    46,    -1,    48,    -1,
      50,    -1,    -1,    53,    33,    -1,    35,    57,    -1,    59,
      39,    -1,    -1,    -1,    64,    65,    66,    -1,     1,    -1,
      -1,    71,   776,     6,    53,    -1,    -1,    10,    57,    -1,
      59,    14,    -1,    -1,    -1,    64,    65,    66,    -1,    -1,
      23,    -1,    71,    26,    27,    -1,    29,    30,    31,    -1,
      33,    -1,    35,    -1,    37,    -1,    39,    40,    41,    -1,
      -1,    -1,    -1,    46,     1,    48,    -1,    50,    -1,     6,
      53,    -1,    -1,    10,    57,    -1,    59,    14,    -1,    -1,
      -1,    64,    65,    66,    -1,    -1,    23,    -1,    71,    26,
      27,    -1,    29,    30,    31,    -1,    33,    -1,    35,    -1,
      37,    -1,    39,    40,    41,    -1,    -1,    -1,    -1,    46,
       1,    48,    -1,    50,    -1,     6,    53,    -1,    -1,    10,
      57,    -1,    59,    14,    -1,    -1,    -1,    64,    65,    66,
      -1,    -1,    23,    -1,    71,    26,    27,    -1,    29,    30,
      31,    -1,    33,    -1,    35,    -1,    37,    -1,    39,    40,
      41,    -1,    -1,    -1,    -1,    46,     1,    48,    -1,    50,
      -1,     6,    53,    -1,    -1,    10,    57,    -1,    -1,    14,
      -1,    -1,    -1,    64,    65,    66,    -1,    -1,    23,    -1,
      71,    26,    27,    -1,    29,    30,    31,    -1,    33,    -1,
      35,    -1,    37,    -1,    39,    40,    41,    -1,    -1,     1,
      -1,    46,    -1,    48,    -1,    50,    -1,    -1,    53,    -1,
      -1,    -1,    57,    -1,    16,    17,    18,    -1,    -1,    64,
      65,    66,    -1,    -1,    -1,    -1,    71,    29,    30,    31,
      -1,    33,    -1,    35,    -1,    -1,    -1,    39,     1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    48,    -1,    50,    -1,
      -1,    53,    -1,    -1,    -1,    57,    58,     1,    -1,    -1,
      -1,    -1,    64,    65,    66,    28,    -1,    -1,    70,    71,
      33,    -1,    35,    33,    -1,    35,    39,    -1,    41,    39,
      -1,    41,    -1,    -1,    -1,     1,    -1,    -1,    51,    33,
      53,    35,    55,    56,    57,    39,    56,    -1,    -1,    -1,
       1,    64,    65,    66,    64,    65,    66,    -1,    71,    53,
      -1,    -1,    56,    57,    -1,    -1,    -1,    33,    -1,    35,
      64,    65,    66,    39,    -1,    41,    -1,    71,     1,    -1,
      -1,    -1,    33,    -1,    35,    -1,    -1,    53,    39,    -1,
      -1,    57,    -1,    -1,    -1,    -1,    -1,    -1,    64,    65,
      66,    52,    53,    -1,    -1,    71,    57,    -1,    -1,    -1,
      33,    -1,    35,    64,    65,    66,    39,    -1,    -1,    -1,
      71,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,     6,
      53,    -1,    -1,    10,    57,    -1,    -1,    14,    -1,    -1,
      -1,    64,    65,    66,    -1,    -1,    23,    -1,    71,    26,
      27,    -1,    29,    30,    31,    -1,    33,    -1,    35,    -1,
      37,    -1,    39,    40,    41,    -1,    -1,    -1,    -1,    46,
      -1,    48,    -1,    50,    -1,     6,    53,    -1,    -1,    10,
      57,    58,    -1,    14,    -1,    -1,    -1,    64,    65,    66,
      -1,    -1,    23,    -1,    71,    26,    27,    -1,    29,    30,
      31,    -1,    33,    -1,    35,    -1,    37,    -1,    39,    40,
      41,    -1,    -1,    -1,    -1,    46,    -1,    48,    -1,    50,
      -1,    -1,    53,    -1,     6,    56,    57,    -1,    10,    -1,
      -1,    -1,    14,    64,    65,    66,    -1,    -1,    -1,    -1,
      71,    23,    -1,    -1,    26,    27,    -1,    29,    30,    31,
      -1,    33,    -1,    35,    -1,    37,    -1,    39,    40,    41,
      -1,    -1,    -1,    -1,    46,    -1,    -1,    -1,    50,    -1,
      -1,    53,    -1,     6,    56,    57,    -1,    10,    -1,    -1,
      -1,    14,    64,    65,    66,    -1,    -1,    -1,    -1,    71,
      23,    -1,    -1,    26,    27,    -1,    29,    30,    31,    -1,
      33,    -1,    35,    -1,    37,    -1,    39,    40,    41,    -1,
      -1,    -1,    -1,    46,    -1,    48,    -1,    50,    -1,     6,
      53,    -1,    -1,    10,    57,    -1,    -1,    14,    -1,    -1,
      -1,    64,    65,    66,    -1,    -1,    23,    -1,    71,    26,
      27,    -1,    29,    30,    31,    -1,    33,    -1,    35,    -1,
      37,    -1,    39,    40,    41,    -1,    -1,    -1,    -1,    46,
      -1,    48,    -1,    50,    -1,     6,    53,    -1,    -1,    10,
      57,    -1,    -1,    14,    -1,    -1,    -1,    64,    65,    66,
      -1,    -1,    23,    -1,    71,    26,    27,    -1,    29,    30,
      31,    -1,    33,    -1,    35,    -1,    37,    -1,    39,    40,
      41,    -1,    -1,    -1,    -1,    46,    -1,    48,    -1,    50,
      -1,     6,    53,    -1,    -1,    10,    57,    -1,    -1,    14,
      -1,    -1,    -1,    64,    65,    66,    -1,    -1,    23,    -1,
      71,    26,    27,    -1,    29,    30,    31,    -1,    33,    -1,
      35,    -1,    37,    -1,    39,    40,    41,    -1,    -1,    -1,
      -1,    46,    -1,    48,    -1,    50,    -1,     6,    53,    -1,
      -1,    10,    57,    -1,    -1,    14,    -1,    -1,    -1,    64,
      65,    66,    -1,     1,    23,    -1,    71,    26,    27,    -1,
      29,    30,    31,    -1,    33,    -1,    35,    -1,    37,    -1,
      39,    40,    41,    -1,    -1,    -1,    -1,    46,    -1,    -1,
      -1,    50,    -1,    -1,    53,    33,    -1,    35,    57,    -1,
      -1,    39,    -1,    41,    -1,    64,    65,    66,     8,     9,
      -1,    -1,    71,    -1,    -1,    53,    16,    17,    18,    19,
      20,    21,    -1,    -1,    24,    25,    64,    65,    66,    29,
      30,    31,    -1,    33,    -1,    35,    -1,    -1,    -1,    39,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    48,    -1,
      50,    -1,    -1,    53,    -1,    -1,    -1,    57,    58,    -1,
      -1,    -1,    -1,    63,    64,    65,    66,    67,    68,     8,
       9,    71,    -1,    -1,    -1,    -1,    -1,    16,    17,    18,
      19,    20,    21,    -1,    -1,    24,    25,    -1,    -1,    -1,
      29,    30,    31,    -1,    33,    -1,    35,    -1,    -1,    -1,
      39,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    48,
      -1,    50,    -1,    -1,    53,    -1,    -1,    -1,    57,    -1,
      -1,    -1,    -1,    -1,    -1,    64,    65,    66,    67,    68,
      -1,    27,    71,    29,    30,    31,    -1,    33,    -1,    35,
      -1,    37,    -1,    39,    40,    41,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    50,    -1,    -1,    53,    -1,    -1,
      -1,    57,    -1,    -1,    -1,    -1,    -1,    -1,    64,    65,
      66,    -1,    -1,    -1,    -1,    71,    29,    30,    31,    32,
      33,    34,    35,    -1,    -1,    38,    39,    -1,    -1,    -1,
      43,    44,    -1,    -1,    -1,    48,    -1,    50,    -1,    52,
      53,    -1,    55,    -1,    57,    -1,    -1,    60,    61,    -1,
      -1,    64,    65,    66,    -1,    -1,    -1,    -1,    71,    72,
      29,    30,    31,    32,    33,    34,    35,    -1,    -1,    38,
      39,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    48,
      -1,    50,    -1,    52,    53,    -1,    55,    56,    57,    -1,
      -1,    -1,    61,    -1,    -1,    64,    65,    66,    -1,    -1,
      -1,    -1,    71,    72,    29,    30,    31,    32,    33,    34,
      35,    -1,    -1,    38,    39,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    48,    -1,    50,    -1,    52,    53,    -1,
      55,    56,    57,    -1,    -1,    -1,    61,    -1,    -1,    64,
      65,    66,    -1,    -1,    -1,    -1,    71,    72,    29,    30,
      31,    32,    33,    34,    35,    -1,    -1,    38,    39,    -1,
      -1,    -1,    -1,    44,    -1,    -1,    -1,    48,    -1,    50,
      -1,    52,    53,    -1,    -1,    -1,    57,    -1,    -1,    60,
      61,    -1,    -1,    64,    65,    66,    -1,    -1,    -1,    -1,
      71,    72,    29,    30,    31,    -1,    33,    -1,    35,    -1,
      -1,    -1,    39,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    48,    -1,    50,    -1,    -1,    53,    -1,    -1,    -1,
      57,    58,    -1,    -1,    -1,    -1,    -1,    64,    65,    66,
      -1,    29,    30,    31,    71,    33,    -1,    35,    -1,    -1,
      -1,    39,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    50,    51,    -1,    53,    -1,    -1,    -1,    57,
      -1,    -1,    -1,    -1,    -1,    -1,    64,    65,    66,    -1,
      29,    30,    31,    71,    33,    -1,    35,    -1,    -1,    -1,
      39,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    48,
      -1,    50,    -1,    -1,    53,    -1,    -1,    -1,    57,    -1,
      -1,    -1,    -1,    -1,    -1,    64,    65,    66,    -1,    29,
      30,    31,    71,    33,    -1,    35,    -1,    -1,    -1,    39,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    48,    -1,
      50,    -1,    -1,    53,    -1,    -1,    -1,    57,    -1,    -1,
      -1,    -1,    -1,    -1,    64,    65,    66,    -1,    29,    30,
      31,    71,    33,    -1,    35,    -1,    -1,    -1,    39,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    48,    -1,    50,
      -1,    -1,    53,    -1,    -1,    -1,    57,    -1,    -1,    -1,
      -1,    -1,    -1,    64,    65,    66,    -1,    29,    30,    31,
      71,    33,    -1,    35,    -1,    -1,    -1,    39,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    48,    -1,    50,    -1,
      -1,    53,    -1,    -1,    -1,    57,    -1,    -1,    -1,    -1,
      -1,    -1,    64,    65,    66,    -1,    29,    30,    31,    71,
      33,    -1,    35,    -1,    -1,    -1,    39,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    48,    -1,    50,    -1,    -1,
      53,    -1,    -1,    -1,    57,    -1,    -1,    -1,    -1,    -1,
      -1,    64,    65,    66,    -1,    29,    30,    31,    71,    33,
      -1,    35,    -1,    -1,    -1,    39,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    50,    -1,    -1,    53,
      -1,    -1,    56,    57,    -1,    -1,    -1,    -1,    -1,    -1,
      64,    65,    66,    -1,    29,    30,    31,    71,    33,    -1,
      35,    -1,    -1,    -1,    39,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    48,    -1,    50,    -1,    -1,    53,    -1,
      -1,    -1,    57,    -1,    -1,    -1,    -1,    -1,    -1,    64,
      65,    66,    -1,    29,    30,    31,    71,    33,    -1,    35,
      -1,    -1,    -1,    39,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    50,    -1,    -1,    53,    33,    34,
      35,    57,    -1,    -1,    39,    -1,    -1,    -1,    64,    65,
      66,    -1,    -1,    -1,    -1,    71,    -1,    52,    53,    54,
      -1,    33,    57,    35,    -1,    60,    -1,    39,    -1,    64,
      65,    66,    -1,    -1,    -1,    -1,    71,    -1,    -1,    51,
      33,    53,    35,    55,    56,    57,    39,    -1,    -1,    -1,
      -1,    -1,    64,    65,    66,    -1,    -1,    -1,    51,    71,
      53,    -1,    55,    56,    57,    -1,    -1,    -1,    33,    -1,
      35,    64,    65,    66,    39,    -1,    -1,    -1,    71,    -1,
      -1,    -1,    -1,    33,    34,    35,    51,    -1,    53,    39,
      55,    56,    57,    -1,    -1,    -1,    -1,    -1,    -1,    64,
      65,    66,    52,    53,    -1,    -1,    71,    57,    -1,    -1,
      60,    33,    -1,    35,    64,    65,    66,    39,    -1,    -1,
      -1,    71,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      33,    53,    35,    55,    56,    57,    39,    -1,    -1,    -1,
      -1,    -1,    64,    65,    66,    -1,    -1,    -1,    51,    71,
      53,    54,    -1,    -1,    57,    -1,    -1,    -1,    33,    -1,
      35,    64,    65,    66,    39,    -1,    -1,    42,    71,    -1,
      -1,    -1,    -1,    -1,    33,    -1,    35,    -1,    53,    54,
      39,    -1,    57,    -1,    -1,    -1,    -1,    -1,    -1,    64,
      65,    66,    51,    -1,    53,    54,    71,    -1,    57,    -1,
      -1,    -1,    33,    34,    35,    64,    65,    66,    39,    -1,
      -1,    -1,    71,    -1,    -1,    -1,    -1,    -1,    33,    -1,
      35,    33,    53,    35,    39,    -1,    57,    39,    -1,    60,
      -1,    -1,    -1,    64,    65,    66,    51,    -1,    53,    51,
      71,    53,    57,    -1,    -1,    57,    -1,    -1,    -1,    64,
      65,    66,    64,    65,    66,    33,    71,    35,    -1,    71,
      -1,    39,    -1,    -1,    42,    -1,    -1,    -1,    -1,    -1,
      33,    -1,    35,    -1,    -1,    53,    39,    -1,    -1,    57,
      -1,    -1,    -1,    -1,    -1,    -1,    64,    65,    66,    -1,
      53,    54,    -1,    71,    57,    -1,    -1,    -1,    33,    -1,
      35,    64,    65,    66,    39,    -1,    -1,    -1,    71,    -1,
      -1,    -1,    -1,    33,    -1,    35,    51,    -1,    53,    39,
      -1,    -1,    57,    -1,    -1,    -1,    -1,    -1,    -1,    64,
      65,    66,    52,    53,    -1,    -1,    71,    57,    -1,    -1,
      -1,    33,    -1,    35,    64,    65,    66,    39,    -1,    -1,
      -1,    71,    -1,    -1,    -1,    -1,    33,    -1,    35,    -1,
      52,    53,    39,    -1,    -1,    57,    -1,    -1,    -1,    -1,
      -1,    -1,    64,    65,    66,    52,    53,    -1,    -1,    71,
      57,    -1,    -1,    -1,    33,    -1,    35,    64,    65,    66,
      39,    -1,    41,    -1,    71,    -1,    -1,    -1,    -1,    -1,
      33,    -1,    35,    33,    53,    35,    39,    -1,    57,    39,
      -1,    -1,    -1,    -1,    -1,    64,    65,    66,    51,    33,
      53,    35,    71,    53,    57,    39,    -1,    57,    -1,    -1,
      -1,    64,    65,    66,    64,    65,    66,    -1,    71,    53,
      33,    71,    35,    57,    37,    -1,    39,    -1,    -1,    -1,
      64,    65,    66,    -1,    -1,    -1,    -1,    71,    -1,    -1,
      53,    -1,    55,    56,    33,    -1,    35,    -1,    37,    62,
      39,    64,    65,    66,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    53,    -1,    -1,    56,    -1,    -1,
      -1,    -1,    -1,    62,    -1,    64,    65,    66
};

/* YYSTOS[STATE-NUM] -- The (internal number of the) accessing
   symbol of state STATE-NUM.  */
static const unsigned char yystos[] =
{
       0,     1,     3,     4,     5,    74,     1,     6,    10,    14,
      23,    26,    27,    29,    30,    31,    33,    35,    37,    39,
      40,    41,    46,    48,    50,    53,    57,    64,    65,    66,
      71,   186,   187,   188,   189,   190,   191,   192,   193,   194,
     196,   197,   217,   219,   221,   222,   223,   224,    35,    39,
      41,    53,   131,   133,   139,   219,   220,    62,    75,    76,
       0,   186,   186,    69,   163,    69,    69,    29,    30,    31,
      50,    53,    57,    71,   177,   178,   195,   217,   221,   224,
     193,   194,   197,    32,    34,    36,    38,    48,    52,    55,
      56,    60,    61,    72,   186,   193,   198,   199,   200,   218,
     219,   226,   228,   230,   231,   232,    59,   186,   198,   213,
      13,   162,    43,    32,    34,    36,    38,    48,    52,    61,
      72,   229,   230,   232,   234,   234,   197,    69,    44,    69,
      43,    56,   133,   134,   139,   142,    53,    57,    71,   140,
     141,   219,   220,    46,     1,    77,   220,    69,   235,     7,
      11,   164,   165,    15,    14,    58,   187,   207,   208,   209,
     207,   177,    29,    32,    34,    38,    48,    52,    61,    72,
     167,   168,   169,   170,   172,   173,   175,   176,   178,   179,
     184,   185,   217,   219,   221,    48,   167,   168,   169,   180,
      51,   177,    44,    69,    56,    56,    56,    56,    56,    56,
      35,    37,    39,   219,    56,    56,    55,    56,   234,    55,
      56,    47,    55,    56,    55,    56,    42,   188,   189,   188,
      45,    47,    55,   214,    59,   163,     1,    53,   128,   130,
     131,   135,   136,   138,   139,   141,   219,    48,   193,   194,
      48,   193,   194,    53,   210,   211,   212,   221,   222,   197,
     210,    53,   135,   139,    55,    56,    55,    56,    55,    56,
      51,    56,   136,   139,   142,   143,   144,   145,   218,   219,
      59,   135,   219,    53,    80,     8,     9,    16,    17,    18,
      19,    20,    21,    24,    25,    29,    53,    58,    63,    67,
      68,    79,    86,    88,    96,    97,   146,   149,   153,   154,
     155,   156,   169,   170,   173,   175,   221,    79,    69,   186,
       1,    41,    58,    70,   153,   166,   236,    58,   236,   186,
     163,   207,    49,   236,    58,   236,    60,   232,     1,   174,
     176,   177,    55,    56,    56,    43,   232,   232,   177,    55,
      56,    47,    55,    56,   177,    42,    72,   232,    55,    59,
     186,   177,   181,   182,   183,   221,   222,    60,    60,    60,
      60,   186,    56,   186,   186,   200,   219,   186,    56,    56,
     186,    14,   186,   215,   216,   186,    47,    28,    53,    56,
     127,   128,   132,   133,   139,   142,   219,    51,    54,    51,
     140,    51,   193,   194,   193,   194,    36,    48,    70,    55,
      42,    70,   133,   133,   139,   133,   139,   133,   139,    56,
      55,    56,    55,    56,    55,    56,    55,    56,    47,    55,
      56,    56,    43,    59,    35,    39,    53,    55,    56,    62,
      81,    82,   220,   222,   224,    13,     1,   131,   139,     1,
      35,    98,     1,    29,   147,     1,   147,     1,   147,     1,
      53,   114,   115,   221,     1,   131,   139,     1,    53,     1,
     116,   131,   139,     1,   117,   131,   139,    48,    60,    72,
     225,   228,   155,   156,   169,   221,    79,     1,    31,    65,
      78,   220,     1,    29,    63,   221,    70,    58,    87,    58,
      43,    55,     1,    42,    43,    47,   157,   158,   159,   160,
     177,   157,   225,   225,    48,    72,   177,   227,   228,   236,
      58,   167,   201,   202,   203,    12,     1,    42,   186,   209,
      48,   174,   167,   135,    48,   174,    48,   174,   167,   167,
     185,   219,   167,    29,    48,   174,   167,    70,    55,    42,
      56,   163,    49,    55,    45,   215,   129,   219,   134,   139,
     142,    56,    54,    55,    56,    55,    56,   135,   135,   135,
     135,   212,   186,   135,   136,   139,   136,   139,   135,   135,
     145,   219,   135,    56,    78,    55,    56,    53,    69,    54,
      42,    42,   219,    60,   148,   225,   231,   233,   148,   148,
      43,    55,    31,    54,    42,   118,   119,   135,    47,   120,
      54,    13,   161,    54,   170,   221,    56,    56,    56,    78,
      53,    64,    66,    89,   221,   221,    87,    88,    97,   153,
       1,    28,   124,   125,   126,   128,   131,   137,   138,   139,
     221,   186,   135,   188,   161,   160,   170,   170,    29,   171,
     172,   221,   170,   201,     1,    47,    51,   204,   205,   206,
     236,    58,   186,   186,   174,   174,   174,    56,   174,   183,
     167,   186,   216,   186,    61,   219,    56,   135,    56,    56,
      82,    45,    55,    83,    84,    85,   222,   224,    79,     1,
      98,     1,    28,    52,    53,   101,   102,   104,   105,   106,
     128,   138,   139,   223,   135,    55,   124,   115,    98,   102,
     108,    56,    55,     1,   121,   122,   123,   161,   139,    69,
     150,   139,   177,   177,   177,    66,    89,    35,    55,    90,
      91,    92,   221,    53,    78,    31,   221,    31,    96,   129,
      51,    54,    51,    51,   157,    42,   188,   186,   161,   206,
     203,   130,    56,    56,    56,    55,   236,    42,   129,   137,
     138,   139,    22,    47,   111,    52,   128,   140,    52,   128,
     140,    60,   231,   231,    52,   128,   231,    69,    15,   233,
      42,   111,   135,    55,    51,   219,   151,   152,    78,    53,
      56,    55,    90,    89,   221,    31,    43,   221,   221,    61,
     126,   139,   126,   126,   126,   186,    51,    85,   101,    61,
     231,    53,   220,   102,   140,   140,    52,   107,   128,   137,
     107,   140,   107,    70,   109,   110,   149,   221,    99,   100,
     221,   108,   122,   123,    58,   153,   236,    58,   236,    89,
      45,    53,    55,    93,    94,    95,   221,   223,    92,    56,
      43,   221,   124,    43,    43,   125,   186,   111,    53,   103,
     104,   131,   139,   107,   112,   113,   220,   137,    55,    70,
      43,    55,    43,   111,    56,    56,    55,   124,    43,   124,
     124,    54,    56,    55,   110,    52,   127,   135,   100,   124,
      95,   124,   104,   220,   135
};

#if ! defined (YYSIZE_T) && defined (__SIZE_TYPE__)
# define YYSIZE_T __SIZE_TYPE__
#endif
#if ! defined (YYSIZE_T) && defined (size_t)
# define YYSIZE_T size_t
#endif
#if ! defined (YYSIZE_T)
# if defined (__STDC__) || defined (__cplusplus)
#  include <stddef.h> /* INFRINGES ON USER NAME SPACE */
#  define YYSIZE_T size_t
# endif
#endif
#if ! defined (YYSIZE_T)
# define YYSIZE_T unsigned int
#endif

#define yyerrok		(yyerrstatus = 0)
#define yyclearin	(yychar = YYEMPTY)
#define YYEMPTY		(-2)
#define YYEOF		0

#define YYACCEPT	goto yyacceptlab
#define YYABORT		goto yyabortlab
#define YYERROR		goto yyerrlab1


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
      YYPOPSTACK;						\
      goto yybackup;						\
    }								\
  else								\
    { 								\
      yyerror ("syntax error: cannot back up");\
      YYERROR;							\
    }								\
while (0)

#define YYTERROR	1
#define YYERRCODE	256

/* YYLLOC_DEFAULT -- Compute the default location (before the actions
   are run).  */

#ifndef YYLLOC_DEFAULT
# define YYLLOC_DEFAULT(Current, Rhs, N)         \
  Current.first_line   = Rhs[1].first_line;      \
  Current.first_column = Rhs[1].first_column;    \
  Current.last_line    = Rhs[N].last_line;       \
  Current.last_column  = Rhs[N].last_column;
#endif

/* YYLEX -- calling `yylex' with the right arguments.  */

#ifdef YYLEX_PARAM
# define YYLEX yylex (YYLEX_PARAM)
#else
# define YYLEX yylex ()
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
} while (0)

# define YYDSYMPRINT(Args)			\
do {						\
  if (yydebug)					\
    yysymprint Args;				\
} while (0)

# define YYDSYMPRINTF(Title, Token, Value, Location)		\
do {								\
  if (yydebug)							\
    {								\
      YYFPRINTF (stderr, "%s ", Title);				\
      yysymprint (stderr, 					\
                  Token, Value);	\
      YYFPRINTF (stderr, "\n");					\
    }								\
} while (0)

/*------------------------------------------------------------------.
| yy_stack_print -- Print the state stack from its BOTTOM up to its |
| TOP (cinluded).                                                   |
`------------------------------------------------------------------*/

#if defined (__STDC__) || defined (__cplusplus)
static void
yy_stack_print (short *bottom, short *top)
#else
static void
yy_stack_print (bottom, top)
    short *bottom;
    short *top;
#endif
{
  YYFPRINTF (stderr, "Stack now");
  for (/* Nothing. */; bottom <= top; ++bottom)
    YYFPRINTF (stderr, " %d", *bottom);
  YYFPRINTF (stderr, "\n");
}

# define YY_STACK_PRINT(Bottom, Top)				\
do {								\
  if (yydebug)							\
    yy_stack_print ((Bottom), (Top));				\
} while (0)


/*------------------------------------------------.
| Report that the YYRULE is going to be reduced.  |
`------------------------------------------------*/

#if defined (__STDC__) || defined (__cplusplus)
static void
yy_reduce_print (int yyrule)
#else
static void
yy_reduce_print (yyrule)
    int yyrule;
#endif
{
  int yyi;
  unsigned int yylineno = yyrline[yyrule];
  YYFPRINTF (stderr, "Reducing stack by rule %d (line %u), ",
             yyrule - 1, yylineno);
  /* Print the symbols being reduced, and their result.  */
  for (yyi = yyprhs[yyrule]; 0 <= yyrhs[yyi]; yyi++)
    YYFPRINTF (stderr, "%s ", yytname [yyrhs[yyi]]);
  YYFPRINTF (stderr, "-> %s\n", yytname [yyr1[yyrule]]);
}

# define YY_REDUCE_PRINT(Rule)		\
do {					\
  if (yydebug)				\
    yy_reduce_print (Rule);		\
} while (0)

/* Nonzero means print parse trace.  It is left uninitialized so that
   multiple parsers can coexist.  */
int yydebug;
#else /* !YYDEBUG */
# define YYDPRINTF(Args)
# define YYDSYMPRINT(Args)
# define YYDSYMPRINTF(Title, Token, Value, Location)
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
   SIZE_MAX < YYSTACK_BYTES (YYMAXDEPTH)
   evaluated with infinite-precision integer arithmetic.  */

#if YYMAXDEPTH == 0
# undef YYMAXDEPTH
#endif

#ifndef YYMAXDEPTH
# define YYMAXDEPTH 10000
#endif



#if YYERROR_VERBOSE

# ifndef yystrlen
#  if defined (__GLIBC__) && defined (_STRING_H)
#   define yystrlen strlen
#  else
/* Return the length of YYSTR.  */
static YYSIZE_T
#   if defined (__STDC__) || defined (__cplusplus)
yystrlen (const char *yystr)
#   else
yystrlen (yystr)
     const char *yystr;
#   endif
{
  register const char *yys = yystr;

  while (*yys++ != '\0')
    continue;

  return yys - yystr - 1;
}
#  endif
# endif

# ifndef yystpcpy
#  if defined (__GLIBC__) && defined (_STRING_H) && defined (_GNU_SOURCE)
#   define yystpcpy stpcpy
#  else
/* Copy YYSRC to YYDEST, returning the address of the terminating '\0' in
   YYDEST.  */
static char *
#   if defined (__STDC__) || defined (__cplusplus)
yystpcpy (char *yydest, const char *yysrc)
#   else
yystpcpy (yydest, yysrc)
     char *yydest;
     const char *yysrc;
#   endif
{
  register char *yyd = yydest;
  register const char *yys = yysrc;

  while ((*yyd++ = *yys++) != '\0')
    continue;

  return yyd - 1;
}
#  endif
# endif

#endif /* !YYERROR_VERBOSE */



#if YYDEBUG
/*--------------------------------.
| Print this symbol on YYOUTPUT.  |
`--------------------------------*/

#if defined (__STDC__) || defined (__cplusplus)
static void
yysymprint (FILE *yyoutput, int yytype, YYSTYPE *yyvaluep)
#else
static void
yysymprint (yyoutput, yytype, yyvaluep)
    FILE *yyoutput;
    int yytype;
    YYSTYPE *yyvaluep;
#endif
{
  /* Pacify ``unused variable'' warnings.  */
  (void) yyvaluep;

  if (yytype < YYNTOKENS)
    {
      YYFPRINTF (yyoutput, "token %s (", yytname[yytype]);
# ifdef YYPRINT
      YYPRINT (yyoutput, yytoknum[yytype], *yyvaluep);
# endif
    }
  else
    YYFPRINTF (yyoutput, "nterm %s (", yytname[yytype]);

  switch (yytype)
    {
      default:
        break;
    }
  YYFPRINTF (yyoutput, ")");
}

#endif /* ! YYDEBUG */
/*-----------------------------------------------.
| Release the memory associated to this symbol.  |
`-----------------------------------------------*/

#if defined (__STDC__) || defined (__cplusplus)
static void
yydestruct (int yytype, YYSTYPE *yyvaluep)
#else
static void
yydestruct (yytype, yyvaluep)
    int yytype;
    YYSTYPE *yyvaluep;
#endif
{
  /* Pacify ``unused variable'' warnings.  */
  (void) yyvaluep;

  switch (yytype)
    {

      default:
        break;
    }
}


/* Prevent warnings from -Wmissing-prototypes.  */

#ifdef YYPARSE_PARAM
# if defined (__STDC__) || defined (__cplusplus)
int yyparse (void *YYPARSE_PARAM);
# else
int yyparse ();
# endif
#else /* ! YYPARSE_PARAM */
#if defined (__STDC__) || defined (__cplusplus)
int yyparse (void);
#else
int yyparse ();
#endif
#endif /* ! YYPARSE_PARAM */



/* The lookahead symbol.  */
int yychar;

/* The semantic value of the lookahead symbol.  */
YYSTYPE yylval;

/* Number of syntax errors so far.  */
int yynerrs;



/*----------.
| yyparse.  |
`----------*/

#ifdef YYPARSE_PARAM
# if defined (__STDC__) || defined (__cplusplus)
int yyparse (void *YYPARSE_PARAM)
# else
int yyparse (YYPARSE_PARAM)
  void *YYPARSE_PARAM;
# endif
#else /* ! YYPARSE_PARAM */
#if defined (__STDC__) || defined (__cplusplus)
int
yyparse (void)
#else
int
yyparse ()

#endif
#endif
{
  
  register int yystate;
  register int yyn;
  int yyresult;
  /* Number of tokens to shift before error messages enabled.  */
  int yyerrstatus;
  /* Lookahead token as an internal (translated) token number.  */
  int yytoken = 0;

  /* Three stacks and their tools:
     `yyss': related to states,
     `yyvs': related to semantic values,
     `yyls': related to locations.

     Refer to the stacks thru separate pointers, to allow yyoverflow
     to reallocate them elsewhere.  */

  /* The state stack.  */
  short	yyssa[YYINITDEPTH];
  short *yyss = yyssa;
  register short *yyssp;

  /* The semantic value stack.  */
  YYSTYPE yyvsa[YYINITDEPTH];
  YYSTYPE *yyvs = yyvsa;
  register YYSTYPE *yyvsp;



#define YYPOPSTACK   (yyvsp--, yyssp--)

  YYSIZE_T yystacksize = YYINITDEPTH;

  /* The variables used to return semantic value and location from the
     action routines.  */
  YYSTYPE yyval;


  /* When reducing, the number of symbols on the RHS of the reduced
     rule.  */
  int yylen;

  YYDPRINTF ((stderr, "Starting parse\n"));

  yystate = 0;
  yyerrstatus = 0;
  yynerrs = 0;
  yychar = YYEMPTY;		/* Cause a token to be read.  */

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
     have just been pushed. so pushing a state here evens the stacks.
     */
  yyssp++;

 yysetstate:
  *yyssp = yystate;

  if (yyss + yystacksize - 1 <= yyssp)
    {
      /* Get the current used size of the three stacks, in elements.  */
      YYSIZE_T yysize = yyssp - yyss + 1;

#ifdef yyoverflow
      {
	/* Give user a chance to reallocate the stack. Use copies of
	   these so that the &'s don't force the real ones into
	   memory.  */
	YYSTYPE *yyvs1 = yyvs;
	short *yyss1 = yyss;


	/* Each stack pointer address is followed by the size of the
	   data in use in that stack, in bytes.  This used to be a
	   conditional around just the two extra args, but that might
	   be undefined if yyoverflow is a macro.  */
	yyoverflow ("parser stack overflow",
		    &yyss1, yysize * sizeof (*yyssp),
		    &yyvs1, yysize * sizeof (*yyvsp),

		    &yystacksize);

	yyss = yyss1;
	yyvs = yyvs1;
      }
#else /* no yyoverflow */
# ifndef YYSTACK_RELOCATE
      goto yyoverflowlab;
# else
      /* Extend the stack our own way.  */
      if (YYMAXDEPTH <= yystacksize)
	goto yyoverflowlab;
      yystacksize *= 2;
      if (YYMAXDEPTH < yystacksize)
	yystacksize = YYMAXDEPTH;

      {
	short *yyss1 = yyss;
	union yyalloc *yyptr =
	  (union yyalloc *) YYSTACK_ALLOC (YYSTACK_BYTES (yystacksize));
	if (! yyptr)
	  goto yyoverflowlab;
	YYSTACK_RELOCATE (yyss);
	YYSTACK_RELOCATE (yyvs);

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

  goto yybackup;

/*-----------.
| yybackup.  |
`-----------*/
yybackup:

/* Do appropriate processing given the current state.  */
/* Read a lookahead token if we need one and don't already have one.  */
/* yyresume: */

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
      YYDSYMPRINTF ("Next token is", yytoken, &yylval, &yylloc);
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

  if (yyn == YYFINAL)
    YYACCEPT;

  /* Shift the lookahead token.  */
  YYDPRINTF ((stderr, "Shifting token %s, ", yytname[yytoken]));

  /* Discard the token being shifted unless it is eof.  */
  if (yychar != YYEOF)
    yychar = YYEMPTY;

  *++yyvsp = yylval;


  /* Count tokens shifted since error; after three, turn off error
     status.  */
  if (yyerrstatus)
    yyerrstatus--;

  yystate = yyn;
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
#line 119 "parser.y"
    {inputExpr = letrec(yyvsp[0],yyvsp[-1]); sp-=2;}
    break;

  case 3:
#line 120 "parser.y"
    {inputContext = yyvsp[0];	    sp-=1;}
    break;

  case 4:
#line 121 "parser.y"
    {valDefns  = yyvsp[0];	    sp-=1;}
    break;

  case 5:
#line 122 "parser.y"
    {syntaxError("input");}
    break;

  case 6:
#line 135 "parser.y"
    {
					 setExportList(singleton(ap(MODULEENT,mkCon(module(currentModule).text))));
					 yyval = gc3(yyvsp[-1]);
					}
    break;

  case 7:
#line 139 "parser.y"
    {
					 setExportList(singleton(ap(MODULEENT,mkCon(module(currentModule).text))));
					 yyval = gc4(yyvsp[-1]);
					}
    break;

  case 8:
#line 144 "parser.y"
    {setExportList(yyvsp[-4]);   yyval = gc7(yyvsp[-1]);}
    break;

  case 9:
#line 145 "parser.y"
    {syntaxError("module definition");}
    break;

  case 10:
#line 151 "parser.y"
    {startModule(conMain); 
					 yyval = gc0(NIL);}
    break;

  case 11:
#line 154 "parser.y"
    {startModule(mkCon(mkNestedQual(yyvsp[0]))); yyval = gc1(NIL);}
    break;

  case 12:
#line 156 "parser.y"
    {yyval = mkCon(mkNestedQual(yyvsp[0]));}
    break;

  case 13:
#line 157 "parser.y"
    { String modName = findPathname(textToStr(textOf(yyvsp[0])));
					  if (modName) { /* fillin pathname if known */
					      yyval = mkStr(findText(modName));
					  } else {
					      yyval = yyvsp[0];
					  }
					}
    break;

  case 14:
#line 165 "parser.y"
    {yyval = gc0(NIL); }
    break;

  case 15:
#line 166 "parser.y"
    {yyval = gc2(yyvsp[0]);}
    break;

  case 16:
#line 167 "parser.y"
    {yyval = gc1(yyvsp[0]);}
    break;

  case 17:
#line 168 "parser.y"
    {yyval = gc2(NIL);}
    break;

  case 18:
#line 169 "parser.y"
    {yyval = gc4(yyvsp[0]);}
    break;

  case 19:
#line 174 "parser.y"
    {yyval = gc0(exportSelf());}
    break;

  case 20:
#line 175 "parser.y"
    {yyval = gc2(NIL);}
    break;

  case 21:
#line 176 "parser.y"
    {yyval = gc3(NIL);}
    break;

  case 22:
#line 177 "parser.y"
    {yyval = gc3(yyvsp[-1]);}
    break;

  case 23:
#line 178 "parser.y"
    {yyval = gc4(yyvsp[-2]);}
    break;

  case 24:
#line 180 "parser.y"
    {yyval = gc3(cons(yyvsp[0],yyvsp[-2]));}
    break;

  case 25:
#line 181 "parser.y"
    {yyval = gc1(singleton(yyvsp[0]));}
    break;

  case 26:
#line 186 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 27:
#line 187 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 28:
#line 188 "parser.y"
    {yyval = gc4(pair(yyvsp[-3],DOTDOT));}
    break;

  case 29:
#line 189 "parser.y"
    {yyval = gc4(pair(yyvsp[-3],yyvsp[-1]));}
    break;

  case 30:
#line 190 "parser.y"
    {yyval = gc2(ap(MODULEENT,yyvsp[0]));}
    break;

  case 31:
#line 192 "parser.y"
    {yyval = gc0(NIL);}
    break;

  case 32:
#line 193 "parser.y"
    {yyval = gc1(NIL);}
    break;

  case 33:
#line 194 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 34:
#line 195 "parser.y"
    {yyval = gc2(yyvsp[-1]);}
    break;

  case 35:
#line 197 "parser.y"
    {yyval = gc3(cons(yyvsp[0],yyvsp[-2]));}
    break;

  case 36:
#line 198 "parser.y"
    {yyval = gc1(singleton(yyvsp[0]));}
    break;

  case 37:
#line 200 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 38:
#line 201 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 39:
#line 206 "parser.y"
    {imps = cons(yyvsp[0],imps); yyval=gc3(NIL);}
    break;

  case 40:
#line 207 "parser.y"
    {yyval   = gc2(NIL); }
    break;

  case 41:
#line 208 "parser.y"
    {imps = singleton(yyvsp[0]); yyval=gc1(NIL);}
    break;

  case 42:
#line 210 "parser.y"
    {if (chase(imps)) {
					     clearStack();
					     onto(imps);
					     done();
					     closeAnyInput();
					     return 0;
					 }
					 yyval = gc0(NIL);
					}
    break;

  case 43:
#line 221 "parser.y"
    {addUnqualImport(yyvsp[-1],NIL,yyvsp[0]);
					 yyval = gc3(yyvsp[-1]);}
    break;

  case 44:
#line 224 "parser.y"
    {addUnqualImport(yyvsp[-3],yyvsp[-1],yyvsp[0]);
					 yyval = gc5(yyvsp[-3]);}
    break;

  case 45:
#line 227 "parser.y"
    {addQualImport(yyvsp[-3],yyvsp[-1],yyvsp[0]);
					 yyval = gc6(yyvsp[-3]);}
    break;

  case 46:
#line 230 "parser.y"
    {addQualImport(yyvsp[-1],yyvsp[-1],yyvsp[0]);
					 yyval = gc4(yyvsp[-1]);}
    break;

  case 47:
#line 232 "parser.y"
    {syntaxError("import declaration");}
    break;

  case 48:
#line 234 "parser.y"
    {yyval = gc0(DOTDOT);}
    break;

  case 49:
#line 235 "parser.y"
    {yyval = gc4(ap(HIDDEN,yyvsp[-1]));}
    break;

  case 50:
#line 236 "parser.y"
    {yyval = gc3(yyvsp[-1]);}
    break;

  case 51:
#line 238 "parser.y"
    {yyval = gc0(NIL);}
    break;

  case 52:
#line 239 "parser.y"
    {yyval = gc1(NIL);}
    break;

  case 53:
#line 240 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 54:
#line 241 "parser.y"
    {yyval = gc2(yyvsp[-1]);}
    break;

  case 55:
#line 243 "parser.y"
    {yyval = gc3(cons(yyvsp[0],yyvsp[-2]));}
    break;

  case 56:
#line 244 "parser.y"
    {yyval = gc1(singleton(yyvsp[0]));}
    break;

  case 57:
#line 246 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 58:
#line 247 "parser.y"
    {yyval = gc1(pair(yyvsp[0],NONE));}
    break;

  case 59:
#line 248 "parser.y"
    {yyval = gc4(pair(yyvsp[-3],DOTDOT));}
    break;

  case 60:
#line 249 "parser.y"
    {yyval = gc4(pair(yyvsp[-3],yyvsp[-1]));}
    break;

  case 61:
#line 251 "parser.y"
    {yyval = gc0(NIL);}
    break;

  case 62:
#line 252 "parser.y"
    {yyval = gc1(NIL);}
    break;

  case 63:
#line 253 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 64:
#line 254 "parser.y"
    {yyval = gc2(yyvsp[-1]);}
    break;

  case 65:
#line 256 "parser.y"
    {yyval = gc3(cons(yyvsp[0],yyvsp[-2]));}
    break;

  case 66:
#line 257 "parser.y"
    {yyval = gc1(singleton(yyvsp[0]));}
    break;

  case 67:
#line 259 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 68:
#line 260 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 69:
#line 265 "parser.y"
    {yyval = gc2(yyvsp[-1]);}
    break;

  case 70:
#line 266 "parser.y"
    {yyval = gc2(yyvsp[-2]);}
    break;

  case 71:
#line 267 "parser.y"
    {yyval = gc3(cons(yyvsp[0],yyvsp[-2]));}
    break;

  case 72:
#line 268 "parser.y"
    {yyval = gc0(NIL);}
    break;

  case 73:
#line 269 "parser.y"
    {yyval = gc1(cons(yyvsp[0],NIL));}
    break;

  case 74:
#line 274 "parser.y"
    {defTycon(4,yyvsp[-1],yyvsp[-2],yyvsp[0],SYNONYM);}
    break;

  case 75:
#line 276 "parser.y"
    {defTycon(6,yyvsp[-3],yyvsp[-4],
						    ap(yyvsp[-2],yyvsp[0]),RESTRICTSYN);}
    break;

  case 76:
#line 278 "parser.y"
    {syntaxError("type definition");}
    break;

  case 77:
#line 280 "parser.y"
    {defTycon(5,yyvsp[-2],checkTyLhs(yyvsp[-3]),
						    ap(rev(yyvsp[-1]),yyvsp[0]),DATATYPE);}
    break;

  case 78:
#line 283 "parser.y"
    {defTycon(7,yyvsp[-2],yyvsp[-3],
						  ap(qualify(yyvsp[-5],rev(yyvsp[-1])),
						     yyvsp[0]),DATATYPE);}
    break;

  case 79:
#line 286 "parser.y"
    {defTycon(2,yyvsp[-1],checkTyLhs(yyvsp[0]),
						    ap(NIL,NIL),DATATYPE);}
    break;

  case 80:
#line 288 "parser.y"
    {defTycon(4,yyvsp[-3],yyvsp[0],
						  ap(qualify(yyvsp[-2],NIL),
						     NIL),DATATYPE);}
    break;

  case 81:
#line 291 "parser.y"
    {syntaxError("data definition");}
    break;

  case 82:
#line 293 "parser.y"
    {defTycon(5,yyvsp[-2],checkTyLhs(yyvsp[-3]),
						    ap(yyvsp[-1],yyvsp[0]),NEWTYPE);}
    break;

  case 83:
#line 296 "parser.y"
    {defTycon(7,yyvsp[-2],yyvsp[-3],
						  ap(qualify(yyvsp[-5],yyvsp[-1]),
						     yyvsp[0]),NEWTYPE);}
    break;

  case 84:
#line 299 "parser.y"
    {syntaxError("newtype definition");}
    break;

  case 85:
#line 300 "parser.y"
    {if (isInt(yyvsp[0])) {
					     needPrims(intOf(yyvsp[0]));
					 } else {
					     syntaxError("needprims decl");
					 }
					 sp-=2;}
    break;

  case 86:
#line 306 "parser.y"
    {syntaxError("needprims decl");}
    break;

  case 87:
#line 308 "parser.y"
    {yyval = gc2(ap(yyvsp[-1],yyvsp[0]));}
    break;

  case 88:
#line 309 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 89:
#line 310 "parser.y"
    {syntaxError("type defn lhs");}
    break;

  case 90:
#line 312 "parser.y"
    {yyval = gc3(cons(yyvsp[0],yyvsp[-2]));}
    break;

  case 91:
#line 313 "parser.y"
    {yyval = gc1(cons(yyvsp[0],NIL));}
    break;

  case 92:
#line 315 "parser.y"
    {yyval = gc3(sigdecl(yyvsp[-1],singleton(yyvsp[-2]),
									yyvsp[0]));}
    break;

  case 93:
#line 317 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 94:
#line 319 "parser.y"
    {yyval = gc3(cons(yyvsp[0],yyvsp[-2]));}
    break;

  case 95:
#line 320 "parser.y"
    {yyval = gc1(cons(yyvsp[0],NIL));}
    break;

  case 96:
#line 322 "parser.y"
    {yyval = gc4(ap(POLYTYPE,
						     pair(rev(yyvsp[-2]),yyvsp[0])));}
    break;

  case 97:
#line 324 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 98:
#line 326 "parser.y"
    {yyval = gc3(qualify(yyvsp[-2],yyvsp[0]));}
    break;

  case 99:
#line 327 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 100:
#line 329 "parser.y"
    {yyval = gc4(ap(ap(yyvsp[-1],bang(yyvsp[-2])),yyvsp[0]));}
    break;

  case 101:
#line 330 "parser.y"
    {yyval = gc3(ap(ap(yyvsp[-1],yyvsp[-2]),yyvsp[0]));}
    break;

  case 102:
#line 331 "parser.y"
    {yyval = gc3(ap(ap(yyvsp[-1],yyvsp[-2]),yyvsp[0]));}
    break;

  case 103:
#line 332 "parser.y"
    {yyval = gc3(ap(ap(yyvsp[-1],yyvsp[-2]),yyvsp[0]));}
    break;

  case 104:
#line 333 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 105:
#line 334 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 106:
#line 335 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 107:
#line 336 "parser.y"
    {yyval = gc4(ap(LABC,pair(yyvsp[-3],rev(yyvsp[-1]))));}
    break;

  case 108:
#line 337 "parser.y"
    {yyval = gc3(ap(LABC,pair(yyvsp[-2],NIL)));}
    break;

  case 109:
#line 338 "parser.y"
    {syntaxError("data type definition");}
    break;

  case 110:
#line 340 "parser.y"
    {yyval = gc3(ap(yyvsp[-2],bang(yyvsp[0])));}
    break;

  case 111:
#line 341 "parser.y"
    {yyval = gc3(ap(yyvsp[-2],bang(yyvsp[0])));}
    break;

  case 112:
#line 342 "parser.y"
    {yyval = gc2(ap(yyvsp[-1],yyvsp[0]));}
    break;

  case 113:
#line 344 "parser.y"
    {yyval = gc2(ap(yyvsp[-1],yyvsp[0]));}
    break;

  case 114:
#line 345 "parser.y"
    {yyval = gc2(ap(yyvsp[-1],yyvsp[0]));}
    break;

  case 115:
#line 346 "parser.y"
    {yyval = gc2(ap(yyvsp[-1],yyvsp[0]));}
    break;

  case 116:
#line 347 "parser.y"
    {yyval = gc2(ap(yyvsp[-1],yyvsp[0]));}
    break;

  case 117:
#line 348 "parser.y"
    {yyval = gc3(ap(yyvsp[-2],bang(yyvsp[0])));}
    break;

  case 118:
#line 350 "parser.y"
    {yyval = gc2(bang(yyvsp[0]));}
    break;

  case 119:
#line 351 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 120:
#line 352 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 121:
#line 354 "parser.y"
    {yyval = gc1(singleton(yyvsp[0]));}
    break;

  case 122:
#line 356 "parser.y"
    {yyval = gc3(cons(yyvsp[0],yyvsp[-2]));}
    break;

  case 123:
#line 357 "parser.y"
    {yyval = gc1(cons(yyvsp[0],NIL));}
    break;

  case 124:
#line 359 "parser.y"
    {yyval = gc3(pair(rev(yyvsp[-2]),yyvsp[0]));}
    break;

  case 125:
#line 360 "parser.y"
    {yyval = gc3(pair(rev(yyvsp[-2]),yyvsp[0]));}
    break;

  case 126:
#line 361 "parser.y"
    {yyval = gc4(pair(rev(yyvsp[-3]),bang(yyvsp[0])));}
    break;

  case 127:
#line 363 "parser.y"
    {yyval = gc0(NIL);}
    break;

  case 128:
#line 364 "parser.y"
    {yyval = gc2(singleton(yyvsp[0]));}
    break;

  case 129:
#line 365 "parser.y"
    {yyval = gc4(yyvsp[-1]);}
    break;

  case 130:
#line 367 "parser.y"
    {yyval = gc0(NIL);}
    break;

  case 131:
#line 368 "parser.y"
    {yyval = gc1(rev(yyvsp[0]));}
    break;

  case 132:
#line 370 "parser.y"
    {yyval = gc3(cons(yyvsp[0],yyvsp[-2]));}
    break;

  case 133:
#line 371 "parser.y"
    {yyval = gc1(singleton(yyvsp[0]));}
    break;

  case 134:
#line 376 "parser.y"
    {primDefn(yyvsp[-3],yyvsp[-2],yyvsp[0]); sp-=4;}
    break;

  case 135:
#line 378 "parser.y"
    {yyval = gc3(cons(yyvsp[0],yyvsp[-2]));}
    break;

  case 136:
#line 379 "parser.y"
    {yyval = gc1(cons(yyvsp[0],NIL));}
    break;

  case 137:
#line 380 "parser.y"
    {syntaxError("primitive defn");}
    break;

  case 138:
#line 382 "parser.y"
    {yyval = gc2(pair(yyvsp[-1],yyvsp[0]));}
    break;

  case 139:
#line 383 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 140:
#line 389 "parser.y"
    {foreignImport(yyvsp[-6],yyvsp[-4],NIL,yyvsp[-3],yyvsp[-2],yyvsp[0]); sp-=7;}
    break;

  case 141:
#line 391 "parser.y"
    {foreignImport(yyvsp[-5],yyvsp[-3],NIL,yyvsp[-2],yyvsp[-2],yyvsp[0]); sp-=6;}
    break;

  case 142:
#line 393 "parser.y"
    {foreignImport(yyvsp[-7],yyvsp[-5],yyvsp[-4],yyvsp[-3],yyvsp[-2],yyvsp[0]); sp-=8;}
    break;

  case 143:
#line 395 "parser.y"
    {foreignImport(yyvsp[-6],yyvsp[-4],yyvsp[-3],yyvsp[-2],yyvsp[-2],yyvsp[0]); sp-=7;}
    break;

  case 144:
#line 397 "parser.y"
    {foreignExport(yyvsp[-6],yyvsp[-5],yyvsp[-4],yyvsp[-3],yyvsp[-2],yyvsp[0]); sp-=7;}
    break;

  case 145:
#line 402 "parser.y"
    {classDefn(intOf(yyvsp[-3]),yyvsp[-2],yyvsp[0],yyvsp[-1]); sp-=4;}
    break;

  case 146:
#line 403 "parser.y"
    {instDefn(intOf(yyvsp[-2]),yyvsp[-1],yyvsp[0]);  sp-=3;}
    break;

  case 147:
#line 404 "parser.y"
    {defaultDefn(intOf(yyvsp[-3]),yyvsp[-1]);  sp-=4;}
    break;

  case 148:
#line 405 "parser.y"
    {syntaxError("class declaration");}
    break;

  case 149:
#line 406 "parser.y"
    {syntaxError("instance declaration");}
    break;

  case 150:
#line 407 "parser.y"
    {syntaxError("default declaration");}
    break;

  case 151:
#line 409 "parser.y"
    {yyval = gc3(pair(yyvsp[-2],checkPred(yyvsp[0])));}
    break;

  case 152:
#line 410 "parser.y"
    {yyval = gc1(pair(NIL,checkPred(yyvsp[0])));}
    break;

  case 153:
#line 412 "parser.y"
    {yyval = gc3(pair(yyvsp[-2],checkPred(yyvsp[0])));}
    break;

  case 154:
#line 413 "parser.y"
    {yyval = gc1(pair(NIL,checkPred(yyvsp[0])));}
    break;

  case 155:
#line 415 "parser.y"
    {yyval = gc0(NIL);}
    break;

  case 156:
#line 416 "parser.y"
    {yyval = gc1(rev(yyvsp[0]));}
    break;

  case 157:
#line 418 "parser.y"
    {yyval = gc3(cons(yyvsp[0],yyvsp[-2]));}
    break;

  case 158:
#line 419 "parser.y"
    {yyval = gc1(cons(yyvsp[0],NIL));}
    break;

  case 159:
#line 421 "parser.y"
    {yyval = gc0(NIL);}
    break;

  case 160:
#line 422 "parser.y"
    {h98DoesntSupport(row,"dependent parameters");
					 yyval = gc2(rev(yyvsp[0]));}
    break;

  case 161:
#line 425 "parser.y"
    {yyval = gc3(cons(yyvsp[0],yyvsp[-2]));}
    break;

  case 162:
#line 426 "parser.y"
    {yyval = gc1(cons(yyvsp[0],NIL));}
    break;

  case 163:
#line 428 "parser.y"
    {yyval = gc3(pair(rev(yyvsp[-2]),rev(yyvsp[0])));}
    break;

  case 164:
#line 429 "parser.y"
    {syntaxError("functional dependency");}
    break;

  case 165:
#line 431 "parser.y"
    {yyval = gc0(NIL);}
    break;

  case 166:
#line 432 "parser.y"
    {yyval = gc2(cons(yyvsp[0],yyvsp[-1]));}
    break;

  case 167:
#line 437 "parser.y"
    {yyval = gc4(ap(POLYTYPE,
						     pair(rev(yyvsp[-2]),yyvsp[0])));}
    break;

  case 168:
#line 439 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 169:
#line 441 "parser.y"
    {yyval = gc3(qualify(yyvsp[-2],yyvsp[0]));}
    break;

  case 170:
#line 442 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 171:
#line 444 "parser.y"
    {yyval = gc3(fn(yyvsp[-2],yyvsp[0]));}
    break;

  case 172:
#line 445 "parser.y"
    {yyval = gc3(fn(yyvsp[-2],yyvsp[0]));}
    break;

  case 173:
#line 446 "parser.y"
    {yyval = gc3(fn(yyvsp[-2],yyvsp[0]));}
    break;

  case 174:
#line 447 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 175:
#line 449 "parser.y"
    {yyval = gc4(ap(POLYTYPE,
						     pair(rev(yyvsp[-2]),yyvsp[0])));}
    break;

  case 176:
#line 451 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 177:
#line 453 "parser.y"
    {yyval = gc3(yyvsp[-1]);}
    break;

  case 178:
#line 454 "parser.y"
    {yyval = gc5(qualify(yyvsp[-3],yyvsp[-1]));}
    break;

  case 179:
#line 456 "parser.y"
    {yyval = gc2(cons(yyvsp[0],yyvsp[-1]));}
    break;

  case 180:
#line 457 "parser.y"
    {yyval = gc1(singleton(yyvsp[0]));}
    break;

  case 181:
#line 459 "parser.y"
    {yyval = gc3(qualify(yyvsp[-2],yyvsp[0]));}
    break;

  case 182:
#line 460 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 183:
#line 462 "parser.y"
    {yyval = gc2(NIL);}
    break;

  case 184:
#line 463 "parser.y"
    {yyval = gc1(singleton(checkPred(yyvsp[0])));}
    break;

  case 185:
#line 464 "parser.y"
    {yyval = gc3(singleton(checkPred(yyvsp[-1])));}
    break;

  case 186:
#line 465 "parser.y"
    {yyval = gc3(checkCtxt(rev(yyvsp[-1])));}
    break;

  case 187:
#line 466 "parser.y"
    {yyval = gc1(singleton(yyvsp[0]));}
    break;

  case 188:
#line 467 "parser.y"
    {yyval = gc3(checkCtxt(rev(yyvsp[-1])));}
    break;

  case 189:
#line 469 "parser.y"
    {yyval = gc1(singleton(yyvsp[0]));}
    break;

  case 190:
#line 470 "parser.y"
    {yyval = gc3(checkCtxt(rev(yyvsp[-1])));}
    break;

  case 191:
#line 472 "parser.y"
    {
#if TREX
					 yyval = gc3(ap(mkExt(textOf(yyvsp[0])),yyvsp[-2]));
#else
					 noTREX("a type context");
#endif
					}
    break;

  case 192:
#line 479 "parser.y"
    {
#if IPARAM
					 yyval = gc3(pair(mkIParam(yyvsp[-2]),yyvsp[0]));
#else
					 noIP("a type context");
#endif
					}
    break;

  case 193:
#line 487 "parser.y"
    {yyval = gc3(cons(yyvsp[0],yyvsp[-2]));}
    break;

  case 194:
#line 488 "parser.y"
    {yyval = gc3(cons(yyvsp[0],yyvsp[-2]));}
    break;

  case 195:
#line 489 "parser.y"
    {yyval = gc3(cons(yyvsp[0],yyvsp[-2]));}
    break;

  case 196:
#line 490 "parser.y"
    {yyval = gc3(cons(yyvsp[0],cons(yyvsp[-2],NIL)));}
    break;

  case 197:
#line 491 "parser.y"
    {yyval = gc1(singleton(yyvsp[0]));}
    break;

  case 198:
#line 494 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 199:
#line 495 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 200:
#line 497 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 201:
#line 498 "parser.y"
    {yyval = gc3(fn(yyvsp[-2],yyvsp[0]));}
    break;

  case 202:
#line 499 "parser.y"
    {yyval = gc3(fn(yyvsp[-2],yyvsp[0]));}
    break;

  case 203:
#line 500 "parser.y"
    {yyval = gc3(fn(yyvsp[-2],yyvsp[0]));}
    break;

  case 204:
#line 501 "parser.y"
    {syntaxError("type expression");}
    break;

  case 205:
#line 503 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 206:
#line 504 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 207:
#line 506 "parser.y"
    {yyval = gc2(ap(yyvsp[-1],yyvsp[0]));}
    break;

  case 208:
#line 507 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 209:
#line 509 "parser.y"
    {yyval = gc2(ap(yyvsp[-1],yyvsp[0]));}
    break;

  case 210:
#line 510 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 211:
#line 512 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 212:
#line 513 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 213:
#line 515 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 214:
#line 516 "parser.y"
    {yyval = gc2(typeUnit);}
    break;

  case 215:
#line 517 "parser.y"
    {yyval = gc3(typeArrow);}
    break;

  case 216:
#line 518 "parser.y"
    {yyval = gc3(yyvsp[-1]);}
    break;

  case 217:
#line 519 "parser.y"
    {yyval = gc3(yyvsp[-1]);}
    break;

  case 218:
#line 520 "parser.y"
    {yyval = gc3(yyvsp[-1]);}
    break;

  case 219:
#line 521 "parser.y"
    {yyval = gc3(buildTuple(yyvsp[-1]));}
    break;

  case 220:
#line 522 "parser.y"
    {yyval = gc3(buildTuple(yyvsp[-1]));}
    break;

  case 221:
#line 523 "parser.y"
    {
#if TREX
					 yyval = gc3(revOnto(yyvsp[-1],typeNoRow));
#else
					 noTREX("a type");
#endif
					}
    break;

  case 222:
#line 530 "parser.y"
    {
#if TREX
					 yyval = gc5(revOnto(yyvsp[-3],yyvsp[-1]));
#else
					 noTREX("a type");
#endif
					}
    break;

  case 223:
#line 537 "parser.y"
    {yyval = gc3(ap(typeList,yyvsp[-1]));}
    break;

  case 224:
#line 538 "parser.y"
    {yyval = gc2(typeList);}
    break;

  case 225:
#line 539 "parser.y"
    {h98DoesntSupport(row,"anonymous type variables");
					 yyval = gc1(inventVar());}
    break;

  case 226:
#line 542 "parser.y"
    {yyval = gc3(cons(yyvsp[0],yyvsp[-2]));}
    break;

  case 227:
#line 543 "parser.y"
    {yyval = gc3(cons(yyvsp[0],cons(yyvsp[-2],NIL)));}
    break;

  case 228:
#line 545 "parser.y"
    {yyval = gc3(cons(yyvsp[0],cons(yyvsp[-2],NIL)));}
    break;

  case 229:
#line 546 "parser.y"
    {yyval = gc3(cons(yyvsp[0],cons(yyvsp[-2],NIL)));}
    break;

  case 230:
#line 547 "parser.y"
    {yyval = gc3(cons(yyvsp[0],yyvsp[-2]));}
    break;

  case 231:
#line 548 "parser.y"
    {yyval = gc3(cons(yyvsp[0],yyvsp[-2]));}
    break;

  case 232:
#line 551 "parser.y"
    {yyval = gc3(cons(yyvsp[0],yyvsp[-2]));}
    break;

  case 233:
#line 552 "parser.y"
    {yyval = gc1(singleton(yyvsp[0]));}
    break;

  case 234:
#line 554 "parser.y"
    {h98DoesntSupport(row,"extensible records");
					 yyval = gc3(ap(mkExt(textOf(yyvsp[-2])),yyvsp[0]));}
    break;

  case 235:
#line 561 "parser.y"
    {yyval = gc3(fixdecl(yyvsp[-2],yyvsp[0],NON_ASS,yyvsp[-1]));}
    break;

  case 236:
#line 562 "parser.y"
    {syntaxError("fixity decl");}
    break;

  case 237:
#line 563 "parser.y"
    {yyval = gc3(fixdecl(yyvsp[-2],yyvsp[0],LEFT_ASS,yyvsp[-1]));}
    break;

  case 238:
#line 564 "parser.y"
    {syntaxError("fixity decl");}
    break;

  case 239:
#line 565 "parser.y"
    {yyval = gc3(fixdecl(yyvsp[-2],yyvsp[0],RIGHT_ASS,yyvsp[-1]));}
    break;

  case 240:
#line 566 "parser.y"
    {syntaxError("fixity decl");}
    break;

  case 241:
#line 567 "parser.y"
    {yyval = gc3(sigdecl(yyvsp[-1],yyvsp[-2],yyvsp[0]));}
    break;

  case 242:
#line 568 "parser.y"
    {syntaxError("type signature");}
    break;

  case 243:
#line 570 "parser.y"
    {yyval = gc1(checkPrec(yyvsp[0]));}
    break;

  case 244:
#line 571 "parser.y"
    {yyval = gc0(mkInt(DEF_PREC));}
    break;

  case 245:
#line 573 "parser.y"
    {yyval = gc3(cons(yyvsp[0],yyvsp[-2]));}
    break;

  case 246:
#line 574 "parser.y"
    {yyval = gc1(singleton(yyvsp[0]));}
    break;

  case 247:
#line 576 "parser.y"
    {yyval = gc3(cons(yyvsp[0],yyvsp[-2]));}
    break;

  case 248:
#line 577 "parser.y"
    {yyval = gc1(singleton(yyvsp[0]));}
    break;

  case 249:
#line 579 "parser.y"
    {yyval = gc3(yyvsp[-1]);}
    break;

  case 250:
#line 580 "parser.y"
    {yyval = gc3(yyvsp[-1]);}
    break;

  case 251:
#line 582 "parser.y"
    {yyval = gc0(NIL);}
    break;

  case 252:
#line 583 "parser.y"
    {yyval = gc2(yyvsp[-1]);}
    break;

  case 253:
#line 584 "parser.y"
    {yyval = gc2(yyvsp[-1]);}
    break;

  case 254:
#line 586 "parser.y"
    {yyval = gc2(cons(yyvsp[0],yyvsp[-1]));}
    break;

  case 255:
#line 588 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 256:
#line 589 "parser.y"
    {yyval = gc2(ap(FUNBIND,pair(yyvsp[-1],yyvsp[0])));}
    break;

  case 257:
#line 590 "parser.y"
    {yyval = gc4(ap(FUNBIND,
						     pair(yyvsp[-3],ap(RSIGN,
								ap(yyvsp[0],yyvsp[-1])))));}
    break;

  case 258:
#line 593 "parser.y"
    {yyval = gc2(ap(PATBIND,pair(yyvsp[-1],yyvsp[0])));}
    break;

  case 259:
#line 595 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 260:
#line 596 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 261:
#line 597 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 262:
#line 599 "parser.y"
    {yyval = gc3(ap2(yyvsp[-1],yyvsp[-2],yyvsp[0]));}
    break;

  case 263:
#line 600 "parser.y"
    {yyval = gc3(ap2(yyvsp[-1],yyvsp[-2],yyvsp[0]));}
    break;

  case 264:
#line 601 "parser.y"
    {yyval = gc3(ap2(yyvsp[-1],yyvsp[-2],yyvsp[0]));}
    break;

  case 265:
#line 602 "parser.y"
    {yyval = gc3(ap2(yyvsp[-1],yyvsp[-2],yyvsp[0]));}
    break;

  case 266:
#line 603 "parser.y"
    {yyval = gc3(ap2(varPlus,yyvsp[-2],yyvsp[0]));}
    break;

  case 267:
#line 605 "parser.y"
    {yyval = gc4(ap(yyvsp[-2],yyvsp[0]));}
    break;

  case 268:
#line 606 "parser.y"
    {yyval = gc4(ap(yyvsp[-2],yyvsp[0]));}
    break;

  case 269:
#line 607 "parser.y"
    {yyval = gc4(ap(yyvsp[-2],yyvsp[0]));}
    break;

  case 270:
#line 608 "parser.y"
    {yyval = gc2(ap(yyvsp[-1],yyvsp[0]));}
    break;

  case 271:
#line 609 "parser.y"
    {yyval = gc2(ap(yyvsp[-1],yyvsp[0]));}
    break;

  case 272:
#line 611 "parser.y"
    {yyval = gc2(letrec(yyvsp[0],yyvsp[-1]));}
    break;

  case 273:
#line 612 "parser.y"
    {syntaxError("declaration");}
    break;

  case 274:
#line 614 "parser.y"
    {yyval = gc2(pair(yyvsp[-1],yyvsp[0]));}
    break;

  case 275:
#line 615 "parser.y"
    {yyval = gc1(grded(rev(yyvsp[0])));}
    break;

  case 276:
#line 617 "parser.y"
    {yyval = gc2(cons(yyvsp[0],yyvsp[-1]));}
    break;

  case 277:
#line 618 "parser.y"
    {yyval = gc1(singleton(yyvsp[0]));}
    break;

  case 278:
#line 620 "parser.y"
    {yyval = gc4(pair(yyvsp[-1],pair(yyvsp[-2],yyvsp[0])));}
    break;

  case 279:
#line 622 "parser.y"
    {yyval = gc0(NIL);}
    break;

  case 280:
#line 623 "parser.y"
    {yyval = gc2(yyvsp[0]);}
    break;

  case 281:
#line 628 "parser.y"
    {yyval = gc0(NIL);}
    break;

  case 282:
#line 629 "parser.y"
    {yyval = gc2(yyvsp[0]);}
    break;

  case 283:
#line 632 "parser.y"
    {yyval = gc3(yyvsp[-1]);}
    break;

  case 284:
#line 633 "parser.y"
    {yyval = gc3(yyvsp[-1]);}
    break;

  case 285:
#line 636 "parser.y"
    {yyval = gc0(NIL);}
    break;

  case 286:
#line 637 "parser.y"
    {yyval = gc2(yyvsp[-1]);}
    break;

  case 287:
#line 638 "parser.y"
    {yyval = gc2(yyvsp[-1]);}
    break;

  case 288:
#line 641 "parser.y"
    {yyval = gc2(cons(yyvsp[0],yyvsp[-1]));}
    break;

  case 289:
#line 643 "parser.y"
    {
#if IPARAM
				         yyval = gc3(pair(yyvsp[-2],yyvsp[0]));
#else
					 noIP("a binding");
#endif
					}
    break;

  case 290:
#line 650 "parser.y"
    {syntaxError("a binding");}
    break;

  case 291:
#line 651 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 292:
#line 656 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 293:
#line 657 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 294:
#line 659 "parser.y"
    {yyval = gc3(ap(ESIGN,pair(yyvsp[-2],yyvsp[0])));}
    break;

  case 295:
#line 660 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 296:
#line 662 "parser.y"
    {yyval = gc3(ap2(varPlus,yyvsp[-2],yyvsp[0]));}
    break;

  case 297:
#line 664 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 298:
#line 665 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 299:
#line 666 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 300:
#line 668 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 301:
#line 669 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 302:
#line 671 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 303:
#line 672 "parser.y"
    {yyval = gc1(ap(INFIX,yyvsp[0]));}
    break;

  case 304:
#line 674 "parser.y"
    {yyval = gc2(ap(NEG,only(yyvsp[0])));}
    break;

  case 305:
#line 675 "parser.y"
    {syntaxError("pattern");}
    break;

  case 306:
#line 676 "parser.y"
    {yyval = gc3(ap(ap(yyvsp[-1],only(yyvsp[-2])),yyvsp[0]));}
    break;

  case 307:
#line 677 "parser.y"
    {yyval = gc4(ap(NEG,ap2(yyvsp[-2],only(yyvsp[-3]),yyvsp[0])));}
    break;

  case 308:
#line 678 "parser.y"
    {yyval = gc3(ap(ap(yyvsp[-1],only(yyvsp[-2])),yyvsp[0]));}
    break;

  case 309:
#line 679 "parser.y"
    {yyval = gc4(ap(NEG,ap2(yyvsp[-2],only(yyvsp[-3]),yyvsp[0])));}
    break;

  case 310:
#line 680 "parser.y"
    {yyval = gc3(ap(ap(yyvsp[-1],only(yyvsp[-2])),yyvsp[0]));}
    break;

  case 311:
#line 681 "parser.y"
    {yyval = gc4(ap(NEG,ap2(yyvsp[-2],only(yyvsp[-3]),yyvsp[0])));}
    break;

  case 312:
#line 682 "parser.y"
    {yyval = gc3(ap(ap(yyvsp[-1],yyvsp[-2]),yyvsp[0]));}
    break;

  case 313:
#line 683 "parser.y"
    {yyval = gc4(ap(NEG,ap(ap(yyvsp[-2],yyvsp[-3]),yyvsp[0])));}
    break;

  case 314:
#line 685 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 315:
#line 686 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 316:
#line 688 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 317:
#line 689 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 318:
#line 691 "parser.y"
    {yyval = gc2(ap(yyvsp[-1],yyvsp[0]));}
    break;

  case 319:
#line 692 "parser.y"
    {yyval = gc2(ap(yyvsp[-1],yyvsp[0]));}
    break;

  case 320:
#line 694 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 321:
#line 695 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 322:
#line 696 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 323:
#line 698 "parser.y"
    {yyval = gc3(ap(ASPAT,pair(yyvsp[-2],yyvsp[0])));}
    break;

  case 324:
#line 699 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 325:
#line 700 "parser.y"
    {yyval = gc4(ap(CONFLDS,pair(yyvsp[-3],yyvsp[-1])));}
    break;

  case 326:
#line 701 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 327:
#line 702 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 328:
#line 703 "parser.y"
    {yyval = gc1(WILDCARD);}
    break;

  case 329:
#line 704 "parser.y"
    {yyval = gc3(yyvsp[-1]);}
    break;

  case 330:
#line 705 "parser.y"
    {yyval = gc3(yyvsp[-1]);}
    break;

  case 331:
#line 706 "parser.y"
    {yyval = gc3(buildTuple(yyvsp[-1]));}
    break;

  case 332:
#line 707 "parser.y"
    {yyval = gc3(ap(FINLIST,rev(yyvsp[-1])));}
    break;

  case 333:
#line 708 "parser.y"
    {yyval = gc2(ap(LAZYPAT,yyvsp[0]));}
    break;

  case 334:
#line 710 "parser.y"
    {
#if TREX
					 yyval = gc3(revOnto(yyvsp[-1],nameNoRec));
#else
					 yyval = gc3(NIL);
#endif
					}
    break;

  case 335:
#line 717 "parser.y"
    {yyval = gc5(revOnto(yyvsp[-3],yyvsp[-1]));}
    break;

  case 336:
#line 720 "parser.y"
    {yyval = gc3(cons(yyvsp[0],yyvsp[-2]));}
    break;

  case 337:
#line 721 "parser.y"
    {yyval = gc3(cons(yyvsp[0],singleton(yyvsp[-2])));}
    break;

  case 338:
#line 723 "parser.y"
    {yyval = gc3(cons(yyvsp[0],yyvsp[-2]));}
    break;

  case 339:
#line 724 "parser.y"
    {yyval = gc1(singleton(yyvsp[0]));}
    break;

  case 340:
#line 726 "parser.y"
    {yyval = gc0(NIL);}
    break;

  case 341:
#line 727 "parser.y"
    {yyval = gc1(rev(yyvsp[0]));}
    break;

  case 342:
#line 729 "parser.y"
    {yyval = gc3(cons(yyvsp[0],yyvsp[-2]));}
    break;

  case 343:
#line 730 "parser.y"
    {yyval = gc1(singleton(yyvsp[0]));}
    break;

  case 344:
#line 732 "parser.y"
    {yyval = gc3(pair(yyvsp[-2],yyvsp[0]));}
    break;

  case 345:
#line 733 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 346:
#line 736 "parser.y"
    {yyval = gc3(cons(yyvsp[0],yyvsp[-2]));}
    break;

  case 347:
#line 737 "parser.y"
    {yyval = gc1(singleton(yyvsp[0]));}
    break;

  case 348:
#line 739 "parser.y"
    {
#if TREX
					 yyval = gc3(ap(mkExt(textOf(yyvsp[-2])),yyvsp[0]));
#else
					 noTREX("a pattern");
#endif
					}
    break;

  case 349:
#line 751 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 350:
#line 752 "parser.y"
    {syntaxError("expression");}
    break;

  case 351:
#line 754 "parser.y"
    {yyval = gc3(ap(ESIGN,pair(yyvsp[-2],yyvsp[0])));}
    break;

  case 352:
#line 755 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 353:
#line 757 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 354:
#line 758 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 355:
#line 760 "parser.y"
    {yyval = gc1(ap(INFIX,yyvsp[0]));}
    break;

  case 356:
#line 761 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 357:
#line 763 "parser.y"
    {yyval = gc1(ap(INFIX,yyvsp[0]));}
    break;

  case 358:
#line 764 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 359:
#line 766 "parser.y"
    {yyval = gc4(ap(NEG,ap(ap(yyvsp[-2],yyvsp[-3]),yyvsp[0])));}
    break;

  case 360:
#line 767 "parser.y"
    {yyval = gc3(ap(ap(yyvsp[-1],yyvsp[-2]),yyvsp[0]));}
    break;

  case 361:
#line 768 "parser.y"
    {yyval = gc2(ap(NEG,only(yyvsp[0])));}
    break;

  case 362:
#line 769 "parser.y"
    {yyval = gc4(ap(NEG,
						     ap(ap(yyvsp[-2],only(yyvsp[-3])),yyvsp[0])));}
    break;

  case 363:
#line 771 "parser.y"
    {yyval = gc3(ap(ap(yyvsp[-1],only(yyvsp[-2])),yyvsp[0]));}
    break;

  case 364:
#line 773 "parser.y"
    {yyval = gc4(ap(NEG,ap(ap(yyvsp[-2],yyvsp[-3]),yyvsp[0])));}
    break;

  case 365:
#line 774 "parser.y"
    {yyval = gc3(ap(ap(yyvsp[-1],yyvsp[-2]),yyvsp[0]));}
    break;

  case 366:
#line 775 "parser.y"
    {yyval = gc2(ap(NEG,only(yyvsp[0])));}
    break;

  case 367:
#line 776 "parser.y"
    {yyval = gc4(ap(NEG,
						     ap(ap(yyvsp[-2],only(yyvsp[-3])),yyvsp[0])));}
    break;

  case 368:
#line 778 "parser.y"
    {yyval = gc3(ap(ap(yyvsp[-1],only(yyvsp[-2])),yyvsp[0]));}
    break;

  case 369:
#line 780 "parser.y"
    {yyval = gc6(ap(CASE,pair(yyvsp[-4],rev(yyvsp[-1]))));}
    break;

  case 370:
#line 781 "parser.y"
    {yyval = gc4(ap(DOCOMP,checkDo(yyvsp[-1])));}
    break;

  case 371:
#line 782 "parser.y"
    {
#if MUDO
					 yyval = gc4(ap(MDOCOMP, checkMDo(yyvsp[-1])));
#else
					 noMDo("an expression");
#endif
					}
    break;

  case 372:
#line 789 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 373:
#line 791 "parser.y"
    {yyval = gc4(ap(LAMBDA,      
						     pair(rev(yyvsp[-2]),
							  pair(yyvsp[-1],yyvsp[0]))));}
    break;

  case 374:
#line 794 "parser.y"
    {yyval = gc4(letrec(yyvsp[-2],yyvsp[0]));}
    break;

  case 375:
#line 795 "parser.y"
    {yyval = gc6(ap(COND,triple(yyvsp[-4],yyvsp[-2],yyvsp[0])));}
    break;

  case 376:
#line 797 "parser.y"
    {yyval = gc2(cons(yyvsp[0],yyvsp[-1]));}
    break;

  case 377:
#line 798 "parser.y"
    {yyval = gc1(cons(yyvsp[0],NIL));}
    break;

  case 378:
#line 800 "parser.y"
    {yyval = gc2(ap(yyvsp[-1],yyvsp[0]));}
    break;

  case 379:
#line 801 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 380:
#line 803 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 381:
#line 804 "parser.y"
    {yyval = gc3(ap(ASPAT,pair(yyvsp[-2],yyvsp[0])));}
    break;

  case 382:
#line 805 "parser.y"
    {yyval = gc2(ap(LAZYPAT,yyvsp[0]));}
    break;

  case 383:
#line 806 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 384:
#line 807 "parser.y"
    {yyval = gc1(WILDCARD);}
    break;

  case 385:
#line 808 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 386:
#line 809 "parser.y"
    {yyval = gc4(ap(CONFLDS,pair(yyvsp[-3],yyvsp[-1])));}
    break;

  case 387:
#line 810 "parser.y"
    {yyval = gc4(ap(UPDFLDS,
						     triple(yyvsp[-3],NIL,yyvsp[-1])));}
    break;

  case 388:
#line 812 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 389:
#line 813 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 390:
#line 814 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 391:
#line 815 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 392:
#line 816 "parser.y"
    {yyval = gc3(yyvsp[-1]);}
    break;

  case 393:
#line 817 "parser.y"
    {yyval = gc3(buildTuple(yyvsp[-1]));}
    break;

  case 394:
#line 819 "parser.y"
    {
#if TREX
					 yyval = gc3(revOnto(yyvsp[-1],nameNoRec));
#else
					 yyval = gc3(NIL);
#endif
					}
    break;

  case 395:
#line 826 "parser.y"
    {yyval = gc5(revOnto(yyvsp[-3],yyvsp[-1]));}
    break;

  case 396:
#line 827 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 397:
#line 829 "parser.y"
    {yyval = gc3(yyvsp[-1]);}
    break;

  case 398:
#line 830 "parser.y"
    {yyval = gc4(ap(yyvsp[-1],yyvsp[-2]));}
    break;

  case 399:
#line 831 "parser.y"
    {yyval = gc4(ap(ap(nameFlip,yyvsp[-2]),yyvsp[-1]));}
    break;

  case 400:
#line 832 "parser.y"
    {yyval = gc4(ap(ap(nameFlip,yyvsp[-2]),yyvsp[-1]));}
    break;

  case 401:
#line 834 "parser.y"
    {yyval = gc3(cons(yyvsp[0],yyvsp[-2]));}
    break;

  case 402:
#line 835 "parser.y"
    {yyval = gc3(cons(yyvsp[0],cons(yyvsp[-2],NIL)));}
    break;

  case 403:
#line 838 "parser.y"
    {yyval = gc3(cons(yyvsp[0],yyvsp[-2]));}
    break;

  case 404:
#line 839 "parser.y"
    {yyval = gc1(singleton(yyvsp[0]));}
    break;

  case 405:
#line 841 "parser.y"
    {
#if TREX
					 yyval = gc3(ap(mkExt(textOf(yyvsp[-2])),yyvsp[0]));
#else
					 noTREX("an expression");
#endif
					}
    break;

  case 406:
#line 850 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 407:
#line 851 "parser.y"
    {yyval = gc2(yyvsp[0]);}
    break;

  case 408:
#line 853 "parser.y"
    {yyval = gc3(cons(yyvsp[0],yyvsp[-2]));}
    break;

  case 409:
#line 854 "parser.y"
    {yyval = gc2(yyvsp[-1]);}
    break;

  case 410:
#line 855 "parser.y"
    {yyval = gc1(cons(yyvsp[0],NIL));}
    break;

  case 411:
#line 857 "parser.y"
    {yyval = gc3(pair(yyvsp[-2],letrec(yyvsp[0],yyvsp[-1])));}
    break;

  case 412:
#line 859 "parser.y"
    {yyval = gc1(grded(rev(yyvsp[0])));}
    break;

  case 413:
#line 860 "parser.y"
    {yyval = gc2(pair(yyvsp[-1],yyvsp[0]));}
    break;

  case 414:
#line 861 "parser.y"
    {syntaxError("case expression");}
    break;

  case 415:
#line 863 "parser.y"
    {yyval = gc2(cons(yyvsp[0],yyvsp[-1]));}
    break;

  case 416:
#line 864 "parser.y"
    {yyval = gc1(cons(yyvsp[0],NIL));}
    break;

  case 417:
#line 866 "parser.y"
    {yyval = gc4(pair(yyvsp[-1],pair(yyvsp[-2],yyvsp[0])));}
    break;

  case 418:
#line 869 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 419:
#line 870 "parser.y"
    {yyval = gc2(yyvsp[0]);}
    break;

  case 420:
#line 872 "parser.y"
    {yyval = gc3(cons(yyvsp[0],yyvsp[-2]));}
    break;

  case 421:
#line 873 "parser.y"
    {yyval = gc2(yyvsp[-1]);}
    break;

  case 422:
#line 874 "parser.y"
    {yyval = gc1(cons(yyvsp[0],NIL));}
    break;

  case 423:
#line 877 "parser.y"
    {yyval = gc3(ap(FROMQUAL,pair(yyvsp[-2],yyvsp[0])));}
    break;

  case 424:
#line 878 "parser.y"
    {yyval = gc2(ap(QWHERE,yyvsp[0]));}
    break;

  case 425:
#line 880 "parser.y"
    {yyval = gc1(ap(DOQUAL,yyvsp[0]));}
    break;

  case 426:
#line 882 "parser.y"
    {yyval = gc0(NIL);}
    break;

  case 427:
#line 883 "parser.y"
    {yyval = gc1(rev(yyvsp[0]));}
    break;

  case 428:
#line 885 "parser.y"
    {yyval = gc3(cons(yyvsp[0],yyvsp[-2]));}
    break;

  case 429:
#line 886 "parser.y"
    {yyval = gc1(singleton(yyvsp[0]));}
    break;

  case 430:
#line 888 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 431:
#line 889 "parser.y"
    {yyval = gc3(pair(yyvsp[-2],yyvsp[0]));}
    break;

  case 432:
#line 894 "parser.y"
    {yyval = gc1(ap(FINLIST,cons(yyvsp[0],NIL)));}
    break;

  case 433:
#line 895 "parser.y"
    {yyval = gc1(ap(FINLIST,rev(yyvsp[0])));}
    break;

  case 434:
#line 896 "parser.y"
    {
#if ZIP_COMP
					 if (length(yyvsp[0])==1) {
					     yyval = gc2(ap(COMP,pair(yyvsp[-1],hd(yyvsp[0]))));
					 } else {
					     if (haskell98)
						 syntaxError("list comprehension");
					     yyval = gc2(ap(ZCOMP,pair(yyvsp[-1],rev(yyvsp[0]))));
					 }
#else
					 if (length(yyvsp[0])!=1) {
					     syntaxError("list comprehension");
					 }
					 yyval = gc2(ap(COMP,pair(yyvsp[-1],hd(yyvsp[0]))));
#endif
					}
    break;

  case 435:
#line 912 "parser.y"
    {yyval = gc3(ap(ap(nameFromTo,yyvsp[-2]),yyvsp[0]));}
    break;

  case 436:
#line 913 "parser.y"
    {yyval = gc4(ap(ap(nameFromThen,yyvsp[-3]),yyvsp[-1]));}
    break;

  case 437:
#line 914 "parser.y"
    {yyval = gc2(ap(nameFrom,yyvsp[-1]));}
    break;

  case 438:
#line 915 "parser.y"
    {yyval = gc5(ap(ap(ap(nameFromThenTo,
								yyvsp[-4]),yyvsp[-2]),yyvsp[0]));}
    break;

  case 439:
#line 918 "parser.y"
    {yyval = gc3(cons(rev(yyvsp[0]),yyvsp[-2]));}
    break;

  case 440:
#line 919 "parser.y"
    {yyval = gc2(cons(rev(yyvsp[0]),NIL));}
    break;

  case 441:
#line 921 "parser.y"
    {yyval = gc3(cons(yyvsp[0],yyvsp[-2]));}
    break;

  case 442:
#line 922 "parser.y"
    {yyval = gc1(cons(yyvsp[0],NIL));}
    break;

  case 443:
#line 924 "parser.y"
    {yyval = gc3(ap(FROMQUAL,pair(yyvsp[-2],yyvsp[0])));}
    break;

  case 444:
#line 925 "parser.y"
    {yyval = gc1(ap(BOOLQUAL,yyvsp[0]));}
    break;

  case 445:
#line 926 "parser.y"
    {yyval = gc2(ap(QWHERE,yyvsp[0]));}
    break;

  case 446:
#line 931 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 447:
#line 932 "parser.y"
    {yyval = gc2(nameUnit);}
    break;

  case 448:
#line 933 "parser.y"
    {yyval = gc2(nameNil);}
    break;

  case 449:
#line 934 "parser.y"
    {yyval = gc3(yyvsp[-1]);}
    break;

  case 450:
#line 936 "parser.y"
    {yyval = gc2(mkTuple(tupleOf(yyvsp[-1])+1));}
    break;

  case 451:
#line 937 "parser.y"
    {yyval = gc1(mkTuple(2));}
    break;

  case 452:
#line 939 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 453:
#line 940 "parser.y"
    {yyval = gc1(varHiding);}
    break;

  case 454:
#line 941 "parser.y"
    {yyval = gc1(varQualified);}
    break;

  case 455:
#line 942 "parser.y"
    {yyval = gc1(varAsMod);}
    break;

  case 456:
#line 944 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 457:
#line 945 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 458:
#line 947 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 459:
#line 948 "parser.y"
    {yyval = gc3(yyvsp[-1]);}
    break;

  case 460:
#line 949 "parser.y"
    {yyval = gc3(varPlus);}
    break;

  case 461:
#line 950 "parser.y"
    {yyval = gc3(varMinus);}
    break;

  case 462:
#line 951 "parser.y"
    {yyval = gc3(varBang);}
    break;

  case 463:
#line 952 "parser.y"
    {yyval = gc3(varDot);}
    break;

  case 464:
#line 954 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 465:
#line 955 "parser.y"
    {yyval = gc3(yyvsp[-1]);}
    break;

  case 466:
#line 956 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 467:
#line 958 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 468:
#line 959 "parser.y"
    {yyval = gc3(yyvsp[-1]);}
    break;

  case 469:
#line 961 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 470:
#line 962 "parser.y"
    {yyval = gc3(yyvsp[-1]);}
    break;

  case 471:
#line 963 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 472:
#line 965 "parser.y"
    {yyval = gc1(varPlus);}
    break;

  case 473:
#line 966 "parser.y"
    {yyval = gc1(varMinus);}
    break;

  case 474:
#line 967 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 475:
#line 969 "parser.y"
    {yyval = gc1(varPlus);}
    break;

  case 476:
#line 970 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 477:
#line 972 "parser.y"
    {yyval = gc1(varMinus);}
    break;

  case 478:
#line 973 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 479:
#line 975 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 480:
#line 976 "parser.y"
    {yyval = gc3(yyvsp[-1]);}
    break;

  case 481:
#line 977 "parser.y"
    {yyval = gc1(varBang);}
    break;

  case 482:
#line 978 "parser.y"
    {yyval = gc1(varDot);}
    break;

  case 483:
#line 980 "parser.y"
    {yyval = gc1(varMinus);}
    break;

  case 484:
#line 981 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 485:
#line 983 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 486:
#line 984 "parser.y"
    {yyval = gc3(yyvsp[-1]);}
    break;

  case 487:
#line 985 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 488:
#line 988 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 489:
#line 989 "parser.y"
    {yyval = gc3(yyvsp[-1]);}
    break;

  case 490:
#line 991 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 491:
#line 992 "parser.y"
    {yyval = gc3(yyvsp[-1]);}
    break;

  case 492:
#line 993 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 493:
#line 995 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 494:
#line 996 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 495:
#line 998 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 496:
#line 999 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 497:
#line 1004 "parser.y"
    {goOffside(startColumn);}
    break;

  case 498:
#line 1007 "parser.y"
    {yyval = yyvsp[0];}
    break;

  case 499:
#line 1008 "parser.y"
    {yyerrok; 
					 if (canUnOffside()) {
					     unOffside();
					     /* insert extra token on stack*/
					     push(NIL);
					     pushed(0) = pushed(1);
					     pushed(1) = mkInt(column);
					 }
					 else
					     syntaxError("definition");
					}
    break;


    }

/* Line 999 of yacc.c.  */
#line 5277 "y.tab.c"

  yyvsp -= yylen;
  yyssp -= yylen;


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
#if YYERROR_VERBOSE
      yyn = yypact[yystate];

      if (YYPACT_NINF < yyn && yyn < YYLAST)
	{
	  YYSIZE_T yysize = 0;
	  int yytype = YYTRANSLATE (yychar);
	  char *yymsg;
	  int yyx, yycount;

	  yycount = 0;
	  /* Start YYX at -YYN if negative to avoid negative indexes in
	     YYCHECK.  */
	  for (yyx = yyn < 0 ? -yyn : 0;
	       yyx < (int) (sizeof (yytname) / sizeof (char *)); yyx++)
	    if (yycheck[yyx + yyn] == yyx && yyx != YYTERROR)
	      yysize += yystrlen (yytname[yyx]) + 15, yycount++;
	  yysize += yystrlen ("syntax error, unexpected ") + 1;
	  yysize += yystrlen (yytname[yytype]);
	  yymsg = (char *) YYSTACK_ALLOC (yysize);
	  if (yymsg != 0)
	    {
	      char *yyp = yystpcpy (yymsg, "syntax error, unexpected ");
	      yyp = yystpcpy (yyp, yytname[yytype]);

	      if (yycount < 5)
		{
		  yycount = 0;
		  for (yyx = yyn < 0 ? -yyn : 0;
		       yyx < (int) (sizeof (yytname) / sizeof (char *));
		       yyx++)
		    if (yycheck[yyx + yyn] == yyx && yyx != YYTERROR)
		      {
			const char *yyq = ! yycount ? ", expecting " : " or ";
			yyp = yystpcpy (yyp, yyq);
			yyp = yystpcpy (yyp, yytname[yyx]);
			yycount++;
		      }
		}
	      yyerror (yymsg);
	      YYSTACK_FREE (yymsg);
	    }
	  else
	    yyerror ("syntax error; also virtual memory exhausted");
	}
      else
#endif /* YYERROR_VERBOSE */
	yyerror ("syntax error");
    }



  if (yyerrstatus == 3)
    {
      /* If just tried and failed to reuse lookahead token after an
	 error, discard it.  */

      /* Return failure if at end of input.  */
      if (yychar == YYEOF)
        {
	  /* Pop the error token.  */
          YYPOPSTACK;
	  /* Pop the rest of the stack.  */
	  while (yyss < yyssp)
	    {
	      YYDSYMPRINTF ("Error: popping", yystos[*yyssp], yyvsp, yylsp);
	      yydestruct (yystos[*yyssp], yyvsp);
	      YYPOPSTACK;
	    }
	  YYABORT;
        }

      YYDSYMPRINTF ("Error: discarding", yytoken, &yylval, &yylloc);
      yydestruct (yytoken, &yylval);
      yychar = YYEMPTY;

    }

  /* Else will try to reuse lookahead token after shifting the error
     token.  */
  goto yyerrlab1;


/*----------------------------------------------------.
| yyerrlab1 -- error raised explicitly by an action.  |
`----------------------------------------------------*/
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

      YYDSYMPRINTF ("Error: popping", yystos[*yyssp], yyvsp, yylsp);
      yydestruct (yystos[yystate], yyvsp);
      yyvsp--;
      yystate = *--yyssp;

      YY_STACK_PRINT (yyss, yyssp);
    }

  if (yyn == YYFINAL)
    YYACCEPT;

  YYDPRINTF ((stderr, "Shifting error token, "));

  *++yyvsp = yylval;


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

#ifndef yyoverflow
/*----------------------------------------------.
| yyoverflowlab -- parser overflow comes here.  |
`----------------------------------------------*/
yyoverflowlab:
  yyerror ("parser stack overflow");
  yyresult = 2;
  /* Fall through.  */
#endif

yyreturn:
#ifndef yyoverflow
  if (yyss != yyssa)
    YYSTACK_FREE (yyss);
#endif
  return yyresult;
}


#line 1023 "parser.y"


static Cell local gcShadow(n,e)		/* keep parsed fragments on stack  */
Int  n;
Cell e; {
    /* If a look ahead token is held then the required stack transformation
     * is:
     *   pushed: n               1     0          1     0
     *           x1  |  ...  |  xn  |  la   ===>  e  |  la
     *                                top()            top()
     *
     * Othwerwise, the transformation is:
     *   pushed: n-1             0        0
     *           x1  |  ...  |  xn  ===>  e
     *                         top()     top()
     */
    if (yychar>=0) {
	pushed(n-1) = top();
	pushed(n)   = e;
    }
    else
	pushed(n-1) = e;
    sp -= (n-1);
    return e;
}

static Void local syntaxError(s)	/* report on syntax error	   */
String s; {
    ERRMSG(row) "Syntax error in %s (unexpected %s)", s, unexpected()
    EEND;
}

static String local unexpected() {     /* find name for unexpected token   */
    static char buffer[100];
    static char *fmt = "%s \"%s\"";
    static char *kwd = "keyword";

    switch (yychar) {
	case 0         : return "end of input";

#define keyword(kw) sprintf(buffer,fmt,kwd,kw); return buffer;
	case INFIXL    : keyword("infixl");
	case INFIXR    : keyword("infixr");
	case INFIXN    : keyword("infix");
	case TINSTANCE : keyword("instance");
	case TCLASS    : keyword("class");
	case PRIMITIVE : keyword("primitive");
	case CASEXP    : keyword("case");
	case OF        : keyword("of");
	case IF        : keyword("if");
	case THEN      : keyword("then");
	case ELSE      : keyword("else");
	case WHERE     : keyword("where");
	case TYPE      : keyword("type");
	case DATA      : keyword("data");
	case TNEWTYPE  : keyword("newtype");
	case LET       : keyword("let");
	case IN        : keyword("in");
	case DERIVING  : keyword("deriving");
	case DEFAULT   : keyword("default");
	case IMPORT    : keyword("import");
	case TMODULE   : keyword("module");
	case ALL       : keyword("forall");
#undef keyword

	case ARROW     : return "`->'";
	case '='       : return "`='";
	case COCO      : return "`::'";
	case '-'       : return "`-'";
	case '!'       : return "`!'";
	case ','       : return "comma";
	case '@'       : return "`@'";
	case '('       : return "`('";
	case ')'       : return "`)'";
	case '{'       : return "`{', possibly due to bad layout";
	case '}'       : return "`}', possibly due to bad layout";
	case '_'       : return "`_'";
	case '|'       : return "`|'";
	case '.'       : return "`.'";
	case ';'       : return "`;', possibly due to bad layout";
	case UPTO      : return "`..'";
	case '['       : return "`['";
	case ']'       : return "`]'";
	case FROM      : return "`<-'";
	case '\\'      : return "backslash (lambda)";
	case '~'       : return "tilde";
	case '`'       : return "backquote";
#if TREX
	case RECSELID  : sprintf(buffer,"selector \"#%s\"",
				 textToStr(extText(snd(yylval))));
			 return buffer;
#endif
#if IPARAM
	case IPVARID   : sprintf(buffer,"implicit parameter \"?%s\"",
				 textToStr(textOf(yylval)));
			 return buffer;
#endif
	case VAROP     :
	case VARID     :
	case CONOP     :
	case CONID     : sprintf(buffer,"symbol \"%s\"",
				 textToStr(textOf(yylval)));
			 return buffer;
	case QVAROP    :
	case QVARID    :
	case QCONOP    : 
	case QCONID    : sprintf(buffer,"symbol \"%s\"",
				 identToStr(yylval));
			 return buffer;
	case HIDING    : return "symbol \"hiding\"";
	case QUALIFIED : return "symbol \"qualified\"";
	case ASMOD     : return "symbol \"as\"";
	case NUMLIT    : return "numeric literal";
	case CHARLIT   : return "character literal";
	case STRINGLIT : return "string literal";
	case IMPLIES   : return "`=>'";
	default        : return "token";
    }
}

static Cell local checkPrec(p)		/* Check for valid precedence value*/
Cell p; {
    if (!isInt(p) || intOf(p)<MIN_PREC || intOf(p)>MAX_PREC) {
	ERRMSG(row) "Precedence value must be an integer in the range [%d..%d]",
		    MIN_PREC, MAX_PREC
	EEND;
    }
    return p;
}

static Cell local buildTuple(tup)	/* build tuple (x1,...,xn) from	   */
List tup; {				/* list [xn,...,x1]		   */
    Int  n = 0;
    Cell t = tup;
    Cell x;

    do {				/*    .                    .	   */
	x      = fst(t);		/*   / \                  / \	   */
	fst(t) = snd(t);		/*  xn  .                .   xn	   */
	snd(t) = x;			/*       .    ===>      .	   */
	x      = t;			/*        .            .	   */
	t      = fun(x);		/*         .          .		   */
	n++;				/*        / \        / \	   */
    } while (nonNull(t));		/*       x1  NIL   (n)  x1	   */
    fst(x) = mkTuple(n);
    return tup;
}

static List local checkCtxt(con)	/* validate context		   */
Type con; {
    mapOver(checkPred, con);
    return con;
}

static Cell local checkPred(c)		/* check that type expr is a valid */
Cell c; {				/* constraint			   */
    Cell cn = getHead(c);
#if TREX
    if (isExt(cn) && argCount==1)
	return c;
#endif
#if IPARAM
    if (isIP(cn))
	return c;
#endif
    if (!isQCon(cn) /*|| argCount==0*/)
	syntaxError("class expression");
    return c;
}

static Pair local checkDo(dqs)		/* convert reversed list of dquals */
List dqs; {				/* to an (expr,quals) pair         */
    if (isNull(dqs) || whatIs(hd(dqs))!=DOQUAL) {
	ERRMSG(row) "Last generator in do {...} must be an expression"
	EEND;
    }
    fst(dqs) = snd(fst(dqs));		/* put expression in fst of pair   */
    snd(dqs) = rev(snd(dqs));		/* & reversed list of quals in snd */
    return dqs;
}

#if MUDO
static Pair local checkMDo(dqs)		/* convert reversed list of dquals */
List dqs; {				/* to an (expr,quals) pair         */
    if (isNull(dqs) || whatIs(hd(dqs))!=DOQUAL) {
	ERRMSG(row) "Last generator in mdo {...} must be an expression"
	EEND;
    }
    fst(dqs) = snd(fst(dqs));		/* put expression in fst of pair   */
    snd(dqs) = rev(snd(dqs));		/* & reversed list of quals in snd */
    return dqs;
}
#endif

static Cell local checkTyLhs(c)		/* check that lhs is of the form   */
Cell c; {				/* T a1 ... a			   */
    Cell tlhs = c;
    while (isAp(tlhs) && whatIs(arg(tlhs))==VARIDCELL) {
	tlhs = fun(tlhs);
    }
    if (whatIs(tlhs)!=CONIDCELL) {
	ERRMSG(row) "Illegal left hand side in datatype definition"
	EEND;
    }
    return c;
}

#if !TREX
static Void local noTREX(where)
String where; {
    ERRMSG(row) "Attempt to use TREX records while parsing %s.\n", where ETHEN
    ERRTEXT     "(TREX is disabled in this build of Hugs)"
    EEND;
}
#endif
#if !IPARAM
static Void local noIP(where)
String where; {
    ERRMSG(row) "Attempt to use Implicit Parameters while parsing %s.\n", where ETHEN
    ERRTEXT     "(Implicit Parameters are disabled in this build of Hugs)"
    EEND;
}
#endif

#if !MUDO
/***
   Due to the way we implement this stuff, this function will actually
   never be called. When MUDO is not defined, the lexer thinks that mdo
   is just another identifier, and hence the MDO token is never returned
   to the parser: consequently the mdo production is never reduced, making 
   this code unreachable. The alternative is to let the lexer to 
   recognize "mdo" all the time, but that's not Haskell compliant. In any 
   case we keep this function here, even if just for documentation purposes.
***/
static Void local noMDo(where)
String where; {
    ERRMSG(row) "Attempt to use MDO while parsing %s.\n", where ETHEN
    ERRTEXT     "(Recursive monadic bindings are disabled in this build of Hugs)"
    EEND;
}
#endif

/*-------------------------------------------------------------------------*/


