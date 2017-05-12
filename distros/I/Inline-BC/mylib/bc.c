#ifndef lint
static char const 
yyrcsid[] = "$FreeBSD: src/usr.bin/yacc/skeleton.c,v 1.28 2000/01/17 02:04:06 bde Exp $";
#endif
#include <stdlib.h>
#define YYBYACC 1
#define YYMAJOR 1
#define YYMINOR 9
#define YYLEX yylex()
#define YYEMPTY -1
#define yyclearin (yychar=(YYEMPTY))
#define yyerrok (yyerrflag=0)
#define YYRECOVERING() (yyerrflag!=0)
static int yygrowstack();
#define YYPREFIX "yy"
#line 2 "bc.y"
/* bc.y: The grammar for a POSIX compatable bc processor with some
         extensions to the language. */

/*  This file is part of GNU bc.
    Copyright (C) 1991, 1992, 1993, 1994, 1997 Free Software Foundation, Inc.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License , or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; see the file COPYING.  If not, write to:
      The Free Software Foundation, Inc.
      59 Temple Place, Suite 330
      Boston, MA 02111 USA

    You may contact the author by:
       e-mail:  philnelson@acm.org
      us-mail:  Philip A. Nelson
                Computer Science Department, 9062
                Western Washington University
                Bellingham, WA 98226-9062
       
*************************************************************************/

#include "bcdefs.h"
#include "global.h"
#include "proto.h"
#line 40 "bc.y"
typedef union {
	char	 *s_value;
	char	  c_value;
	int	  i_value;
	arg_list *a_value;
       } YYSTYPE;
#line 59 "y.tab.c"
#define YYERRCODE 256
#define ENDOFLINE 257
#define AND 258
#define OR 259
#define NOT 260
#define STRING 261
#define NAME 262
#define NUMBER 263
#define ASSIGN_OP 264
#define REL_OP 265
#define INCR_DECR 266
#define Define 267
#define Break 268
#define Quit 269
#define Length 270
#define Return 271
#define For 272
#define If 273
#define While 274
#define Sqrt 275
#define Else 276
#define Scale 277
#define Ibase 278
#define Obase 279
#define Auto 280
#define Read 281
#define Warranty 282
#define Halt 283
#define Last 284
#define Continue 285
#define Print 286
#define Limits 287
#define UNARY_MINUS 288
#define HistoryVar 289
const short yylhs[] = {                                        -1,
    0,    0,   10,   10,   10,   17,   17,   11,   11,   11,
   11,   12,   12,   12,   12,   12,   12,   15,   15,   13,
   13,   13,   13,   13,   13,   13,   13,   13,   18,   19,
   20,   21,   13,   22,   13,   24,   25,   13,   13,   27,
   13,   26,   26,   28,   28,   23,   29,   23,   30,   14,
    5,    5,    6,    6,    6,    7,    7,    7,    7,    7,
    7,    8,    8,    9,    9,    9,    9,    4,    4,    2,
    2,   31,    1,   32,    1,   33,    1,    1,    1,    1,
    1,    1,    1,    1,    1,    1,    1,    1,    1,    1,
    1,    1,    1,    1,    1,    1,    3,    3,    3,    3,
    3,    3,    3,   16,   16,   16,
};
const short yylen[] = {                                         2,
    0,    2,    2,    1,    2,    0,    1,    0,    1,    3,
    2,    0,    1,    2,    3,    2,    3,    1,    2,    1,
    1,    1,    1,    1,    1,    1,    1,    2,    0,    0,
    0,    0,   14,    0,    8,    0,    0,    8,    3,    0,
    3,    1,    3,    1,    1,    0,    0,    4,    0,   12,
    0,    1,    0,    3,    3,    1,    3,    4,    3,    5,
    6,    0,    1,    1,    3,    3,    5,    0,    1,    0,
    1,    0,    4,    0,    4,    0,    4,    2,    3,    3,
    3,    3,    3,    3,    3,    2,    1,    1,    3,    4,
    2,    2,    4,    4,    4,    3,    1,    4,    1,    1,
    1,    1,    1,    0,    1,    2,
};
const short yydefred[] = {                                      1,
    0,    0,    0,   23,    0,   88,    0,    0,   24,   26,
    0,    0,   29,    0,   36,    0,    0,   99,  100,    0,
   20,   27,  103,   25,   40,   21,  102,    0,    0,    0,
    0,    0,    2,    0,   18,    4,    9,    5,   19,    0,
    0,    0,    0,  101,   91,    0,    0,    0,   28,    0,
    0,    0,    0,    0,    0,    0,   86,    0,    0,    0,
   13,   74,   76,    0,    0,    0,    0,    0,    0,    0,
   72,   92,    3,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,   96,   44,    0,   41,
    0,   89,    0,    0,   39,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,   10,    0,   90,    0,   98,
    0,    0,    0,    0,   93,    0,    0,   34,    0,   94,
   95,    0,   15,   17,    0,    0,    0,   65,    0,    0,
    0,    0,    0,    0,   30,    0,    0,   43,    0,   57,
    0,    7,    0,    0,    0,    0,    0,    0,   67,   58,
    0,    0,    0,    0,    0,    0,  105,    0,   60,    0,
   31,   47,   35,   38,  106,    0,   49,   61,    0,    0,
    0,    0,    0,    0,   54,   55,    0,   32,   48,   50,
    0,    0,   33,
};
const short yydgoto[] = {                                       1,
   31,   49,   32,  117,  113,  167,  114,   77,   78,   33,
   34,   60,   35,   36,   61,  158,  143,   50,  146,  169,
  181,  136,  163,   52,  137,   90,   56,   91,  170,  172,
  105,   96,   97,
};
const short yysindex[] = {                                      0,
   24,   55,  243,    0,  -25,    0, -170, -222,    0,    0,
    1,  243,    0,    9,    0,   13,   16,    0,    0,   19,
    0,    0,    0,    0,    0,    0,    0,  243,  243,   87,
  899, -214,    0,  -56,    0,    0,    0,    0,    0,  -29,
  306,  243,  -47,    0,    0,   22,  243,  899,    0,   23,
  243,   27,  243,  243,   34,  211,    0,  796,  127,  -49,
    0,    0,    0,  243,  243,  243,  243,  243,  243,  243,
    0,    0,    0,   87,  -19,  899,   37,   40,  833,  -38,
  846,  243,  908,  243,  920,  931,    0,    0,  899,    0,
   44,    0,   87,  127,    0,  243,  243,  -14,  -12,  -12,
  -13,  -13,  -13,  -13,  243,    0,  274,    0,  378,    0,
   -4, -173,   49,   50,    0,  899,   38,    0,  899,    0,
    0,  211,    0,    0,  -29,  556,  -14,    0,  -18,  899,
    3,    8, -156,  -35,    0, -156,   62,    0,  346,    0,
   12,    0,  -11,   20, -158,  243,  127, -156,    0,    0,
 -147,   25,   29,   54, -160,  127,    0, -233,    0,   28,
    0,    0,    0,    0,    0,  -38,    0,    0,  243, -156,
   11,   87,   82,  127,    0,    0,  -48,    0,    0,    0,
 -156,  127,    0,
};
const short yyrindex[] = {                                      0,
  -42,    0,    0,    0,  417,    0,    0,    0,    0,    0,
    0,  -57,    0,    0,    0,    0,  643,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,  -39,
  376,  663,    0,    0,    0,    0,    0,    0,    0,  533,
   83,    0,  672,    0,    0,    0,    0,  390,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,   47,  119,   -2,    0,   84,    0,   85,
    0,   69,    0,    0,    0,    0,    0,    0,   78,    0,
  392,    0,   15,   32,    0,    0,    0,  482,  570,  772,
  701,  730,  739,  759,    0,    0,    0,    0,    0,    0,
  -32,    0,    0,   88,    0,   -5,    0,    0,   89,    0,
    0,    0,    0,    0,  610,  781,  601,    0,  119,    4,
    0,    0,   10,    0,    0,  159,    0,    0,    0,    0,
    0,    0,    0,    2,    0,   69,    0,  159,    0,    0,
  -40,    0,    0,    0,   43,    0,    0,   -8,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,   90,  159,
    0,  -39,    0,    0,    0,    0,    0,    0,    0,    0,
  159,    0,    0,
};
const short yygindex[] = {                                      0,
 1065,    0,  128, -112,    0,    0,  -30,    0,    0,    0,
    0,  -34,   -1,    0,    5,    0, -110,    0,    0,    0,
    0,    0,    0,    0,    0,   17,    0,    0,    0,    0,
    0,    0,    0,
};
#define YYTABLESIZE 1234
const short yytable[] = {                                     104,
   39,   70,   74,  112,  104,   37,  145,   69,   56,   94,
   94,   56,   67,   65,   41,   66,    8,   68,  104,   12,
   41,   41,   69,  165,   69,  147,   56,   67,   65,   67,
   66,   53,   68,  154,   68,   69,   53,  156,   64,   46,
   47,   64,   59,   42,   66,   59,  166,   66,   51,   71,
   53,   72,   53,   69,  134,   54,  173,   39,   55,  174,
   59,   80,   82,   29,   70,   42,   84,   70,   28,  176,
  182,  107,  139,   14,   87,   95,  180,  108,  106,   70,
   70,   70,  104,  109,  104,   12,  131,  122,  132,  133,
   16,   43,  124,  134,   29,  140,  135,  123,  141,   28,
  142,   46,  148,  153,  150,   11,   44,   18,   19,  157,
  152,  151,  161,   23,   53,  162,   53,  159,   27,  160,
  168,   45,  178,   62,   63,   51,   29,   68,   52,   37,
   68,   28,    6,    0,   45,  171,   45,  177,  138,   14,
    0,    0,    0,    0,    0,  155,   30,    0,    0,    0,
    0,    0,    0,    0,  164,   97,   16,    0,    0,   97,
   97,   97,   97,   97,    0,   97,   29,   46,    0,    0,
    0,   28,  179,    0,    0,    0,    0,   30,    0,    0,
  183,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    6,   70,
   73,    0,   45,    6,    0,    0,    0,   93,   93,   30,
    0,    0,   97,    0,    8,  104,    0,   12,   70,  104,
  104,  104,  104,  111,   56,  104,  144,  104,  104,  104,
  104,  104,  104,  104,  104,   64,  104,  104,  104,  104,
  104,  104,  104,  104,  104,  104,  104,   53,  104,   30,
   29,   53,   53,   53,   53,   28,    0,   53,   59,   53,
   53,   53,   53,   53,   53,   53,   53,  175,   53,   53,
   53,   14,   53,   53,   53,   53,   53,   53,   53,    2,
   53,    6,   29,    3,    4,    5,    6,   28,   16,    7,
    8,    9,   10,   11,   12,   13,   14,   15,   16,   46,
   17,   18,   19,   11,   20,   21,   22,   23,   24,   25,
   26,   38,   27,   29,    3,    4,    5,    6,   28,    0,
    7,    0,    9,   10,   11,   12,   13,   14,   15,   16,
    0,   17,   18,   19,   45,   20,   21,   22,   23,   24,
   25,   26,   59,   27,    0,   29,    3,    4,    5,    6,
   28,    0,    7,   45,    9,   10,   11,   12,   13,   14,
   15,   16,    0,   17,   18,   19,  128,   20,   21,   22,
   23,   24,   25,   26,    0,   27,   97,   97,    0,    0,
    0,    0,   97,   97,   97,   29,    3,    4,    5,    6,
   28,    0,    7,    0,    9,   10,   11,   12,   13,   14,
   15,   16,    0,   17,   18,   19,    0,   20,   21,   22,
   23,   24,   25,   26,    0,   27,    0,   29,    6,    6,
    6,    6,   28,    0,    6,    0,    6,    6,    6,    6,
    6,    6,    6,    6,   22,    6,    6,    6,  149,    6,
    6,    6,    6,    6,    6,    6,    0,    6,   71,    0,
   42,    0,    0,   97,    0,    0,    0,   97,   97,   97,
   97,   97,    0,   97,    0,    0,    0,    0,    0,    0,
    3,   88,    5,    6,    0,   97,    7,    0,    0,    0,
   11,    0,    0,    0,    0,   16,    0,   17,   18,   19,
    0,   20,    0,    0,   23,    0,    0,    0,    0,   27,
   22,    0,    3,    0,    5,    6,    0,    0,    7,   97,
   97,    0,   11,    0,   71,    0,   42,   16,    0,   17,
   18,   19,   79,   20,    0,   79,   23,    0,    0,    0,
    0,   27,    0,    3,    0,    5,    6,    0,    0,    7,
   79,   97,    0,   11,    0,    0,    0,    0,   16,    0,
   17,   18,   19,    0,   20,    0,    0,   23,    0,    0,
    0,    0,   27,    0,    0,    3,    0,   75,    6,    0,
    0,    7,    0,   78,   79,   11,   78,    0,    0,    0,
   16,    0,   17,   18,   19,    0,   20,    0,    0,   23,
    0,   78,   69,    0,   27,    0,    0,   67,   65,    0,
   66,    0,   68,    0,    0,    3,   79,    5,    6,    0,
   80,    7,   80,   80,   80,   11,    0,    0,    0,    0,
   16,    0,   17,   18,   19,   78,   20,    0,   80,   23,
    0,    0,   22,    0,   27,    0,    0,    3,    0,  129,
    6,   73,    0,    7,   73,    0,   71,   11,   42,   70,
   75,   22,   16,   75,   17,   18,   19,   78,   20,   73,
    0,   23,   80,    0,    0,   71,   27,   42,   75,    0,
    0,    0,    0,   97,   97,   97,    0,    0,    0,  101,
   97,   97,   97,  101,  101,  101,  101,  101,    0,  101,
    0,    0,   97,   73,   80,    0,    0,    0,    0,   87,
    0,  101,   75,   87,   87,   87,   87,   87,   97,   87,
    0,    0,   97,   97,   97,   97,   97,    0,   97,    0,
    0,   87,    0,    0,    0,   73,    0,    0,    0,    0,
   97,    0,    0,    0,   75,  101,  101,   82,   79,   79,
   79,   82,   82,   82,   82,   82,   79,   82,    0,    0,
    0,    0,    0,    0,    0,   87,   87,   79,    0,   82,
    0,    0,    0,    0,   97,   97,   83,  101,    0,    0,
   83,   83,   83,   83,   83,   84,   83,    0,    0,   84,
   84,   84,   84,   84,    0,   84,    0,   87,   83,   78,
   78,   78,    0,   82,    0,   85,   97,   84,    0,   85,
   85,   85,   85,   85,    0,   85,    0,    0,   78,    0,
    0,    0,   81,   62,   81,   81,   81,   85,    0,    0,
   64,   77,   83,    0,   77,   82,   80,   80,   80,    0,
   81,   84,   69,    0,   80,    0,   92,   67,   65,   77,
   66,    0,   68,    0,    0,   80,    0,    0,    0,    0,
    0,   85,    0,    0,   83,    0,    0,   73,   73,   73,
    0,    0,    0,   84,   81,   73,   75,   75,   75,   69,
    0,    0,    0,   77,   67,   65,   73,   66,    0,   68,
    0,    0,   69,   85,    0,   75,  115,   67,   65,   70,
   66,    0,   68,    0,    0,    0,   81,    0,    0,  101,
  101,  101,    0,    0,    0,   77,  101,  101,  101,    0,
    0,    0,    0,    0,    0,    0,    0,    0,  101,   87,
   87,   87,    0,    0,    0,  110,   70,   87,   97,   97,
   97,    0,    0,    0,    0,   69,   97,    0,   87,   70,
   67,   65,    0,   66,   69,   68,    0,   97,  118,   67,
   65,    0,   66,    0,   68,    0,   69,   82,   82,   82,
  120,   67,   65,    0,   66,   82,   68,   69,    0,    0,
    0,  121,   67,   65,    0,   66,   82,   68,    0,    0,
    0,    0,    0,    0,    0,    0,   83,   83,   83,    0,
    0,    0,   70,    0,   83,   84,   84,   84,    0,    0,
    0,   70,    0,   84,    0,   83,    0,    0,    0,    0,
    0,    0,    0,   70,   84,   85,   85,   85,    0,    0,
    0,    0,    0,   85,   70,    0,    0,    0,   81,   81,
   81,    0,    0,    0,   85,    0,   81,   77,    0,   77,
    0,    0,    0,    0,    0,    0,    0,   81,    0,    0,
    0,    0,    0,   62,   63,    0,   77,    0,    0,    0,
   64,    0,    0,    0,    0,    0,    0,   40,    0,    0,
    0,    0,    0,    0,    0,    0,   48,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
   62,   63,   57,   58,    0,    0,    0,   64,    0,    0,
    0,    0,    0,   62,   63,   76,   79,    0,    0,    0,
   64,   81,    0,    0,    0,   83,    0,   85,   86,    0,
   89,    0,    0,    0,    0,    0,    0,    0,   98,   99,
  100,  101,  102,  103,  104,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,  116,    0,  119,    0,
    0,    0,    0,    0,    0,    0,   62,   63,    0,    0,
  125,  126,    0,   64,    0,   62,   63,    0,    0,  127,
    0,   79,   64,  130,    0,    0,    0,   62,   63,    0,
    0,    0,    0,    0,   64,    0,   89,    0,   62,   63,
    0,    0,    0,    0,    0,   64,    0,    0,    0,    0,
    0,    0,    0,   79,    0,    0,    0,    0,    0,    0,
  116,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,    0,    0,    0,    0,    0,    0,    0,
    0,    0,    0,  116,
};
const short yycheck[] = {                                      40,
    2,   59,   59,   42,   45,    1,   42,   37,   41,   59,
   59,   44,   42,   43,   40,   45,   59,   47,   59,   59,
   40,   40,   37,  257,   37,  136,   59,   42,   43,   42,
   45,   40,   47,  146,   47,   41,   45,  148,   41,  262,
   40,   44,   41,   91,   41,   44,  280,   44,   40,  264,
   59,  266,   40,   59,   44,   40,  169,   59,   40,  170,
   59,   40,   40,   40,   94,   91,   40,  125,   45,   59,
  181,   91,   91,   59,   41,  125,  125,   41,   74,   94,
   94,   94,  123,   44,  125,  125,   91,   44,  262,   41,
   59,  262,   94,   44,   40,   93,   59,   93,   91,   45,
  257,   59,   41,  262,   93,   59,  277,  278,  279,  257,
   91,  123,   59,  284,  123,  276,  125,   93,  289,   91,
   93,   44,   41,   41,   41,   41,   40,   59,   41,   41,
   41,   45,  123,   -1,    7,  166,   59,  172,  122,  125,
   -1,   -1,   -1,   -1,   -1,  147,  123,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,  156,   37,  125,   -1,   -1,   41,
   42,   43,   44,   45,   -1,   47,   40,  125,   -1,   -1,
   -1,   45,  174,   -1,   -1,   -1,   -1,  123,   -1,   -1,
  182,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   40,  257,
  257,   -1,  125,   45,   -1,   -1,   -1,  257,  257,  123,
   -1,   -1,   94,   -1,  257,  256,   -1,  257,  276,  260,
  261,  262,  263,  262,  257,  266,  262,  268,  269,  270,
  271,  272,  273,  274,  275,  265,  277,  278,  279,  280,
  281,  282,  283,  284,  285,  286,  287,  256,  289,  123,
   40,  260,  261,  262,  263,   45,   -1,  266,  257,  268,
  269,  270,  271,  272,  273,  274,  275,  257,  277,  278,
  279,  257,  281,  282,  283,  284,  285,  286,  287,  256,
  289,  123,   40,  260,  261,  262,  263,   45,  257,  266,
  267,  268,  269,  270,  271,  272,  273,  274,  275,  257,
  277,  278,  279,  257,  281,  282,  283,  284,  285,  286,
  287,  257,  289,   40,  260,  261,  262,  263,   45,   -1,
  266,   -1,  268,  269,  270,  271,  272,  273,  274,  275,
   -1,  277,  278,  279,  257,  281,  282,  283,  284,  285,
  286,  287,  256,  289,   -1,   40,  260,  261,  262,  263,
   45,   -1,  266,  276,  268,  269,  270,  271,  272,  273,
  274,  275,   -1,  277,  278,  279,   93,  281,  282,  283,
  284,  285,  286,  287,   -1,  289,  258,  259,   -1,   -1,
   -1,   -1,  264,  265,  266,   40,  260,  261,  262,  263,
   45,   -1,  266,   -1,  268,  269,  270,  271,  272,  273,
  274,  275,   -1,  277,  278,  279,   -1,  281,  282,  283,
  284,  285,  286,  287,   -1,  289,   -1,   40,  260,  261,
  262,  263,   45,   -1,  266,   -1,  268,  269,  270,  271,
  272,  273,  274,  275,   59,  277,  278,  279,   93,  281,
  282,  283,  284,  285,  286,  287,   -1,  289,   59,   -1,
   59,   -1,   -1,   37,   -1,   -1,   -1,   41,   42,   43,
   44,   45,   -1,   47,   -1,   -1,   -1,   -1,   -1,   -1,
  260,  261,  262,  263,   -1,   59,  266,   -1,   -1,   -1,
  270,   -1,   -1,   -1,   -1,  275,   -1,  277,  278,  279,
   -1,  281,   -1,   -1,  284,   -1,   -1,   -1,   -1,  289,
  125,   -1,  260,   -1,  262,  263,   -1,   -1,  266,   93,
   94,   -1,  270,   -1,  125,   -1,  125,  275,   -1,  277,
  278,  279,   41,  281,   -1,   44,  284,   -1,   -1,   -1,
   -1,  289,   -1,  260,   -1,  262,  263,   -1,   -1,  266,
   59,  125,   -1,  270,   -1,   -1,   -1,   -1,  275,   -1,
  277,  278,  279,   -1,  281,   -1,   -1,  284,   -1,   -1,
   -1,   -1,  289,   -1,   -1,  260,   -1,  262,  263,   -1,
   -1,  266,   -1,   41,   93,  270,   44,   -1,   -1,   -1,
  275,   -1,  277,  278,  279,   -1,  281,   -1,   -1,  284,
   -1,   59,   37,   -1,  289,   -1,   -1,   42,   43,   -1,
   45,   -1,   47,   -1,   -1,  260,  125,  262,  263,   -1,
   41,  266,   43,   44,   45,  270,   -1,   -1,   -1,   -1,
  275,   -1,  277,  278,  279,   93,  281,   -1,   59,  284,
   -1,   -1,  257,   -1,  289,   -1,   -1,  260,   -1,  262,
  263,   41,   -1,  266,   44,   -1,  257,  270,  257,   94,
   41,  276,  275,   44,  277,  278,  279,  125,  281,   59,
   -1,  284,   93,   -1,   -1,  276,  289,  276,   59,   -1,
   -1,   -1,   -1,  257,  258,  259,   -1,   -1,   -1,   37,
  264,  265,  266,   41,   42,   43,   44,   45,   -1,   47,
   -1,   -1,  276,   93,  125,   -1,   -1,   -1,   -1,   37,
   -1,   59,   93,   41,   42,   43,   44,   45,   37,   47,
   -1,   -1,   41,   42,   43,   44,   45,   -1,   47,   -1,
   -1,   59,   -1,   -1,   -1,  125,   -1,   -1,   -1,   -1,
   59,   -1,   -1,   -1,  125,   93,   94,   37,  257,  258,
  259,   41,   42,   43,   44,   45,  265,   47,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   93,   94,  276,   -1,   59,
   -1,   -1,   -1,   -1,   93,   94,   37,  125,   -1,   -1,
   41,   42,   43,   44,   45,   37,   47,   -1,   -1,   41,
   42,   43,   44,   45,   -1,   47,   -1,  125,   59,  257,
  258,  259,   -1,   93,   -1,   37,  125,   59,   -1,   41,
   42,   43,   44,   45,   -1,   47,   -1,   -1,  276,   -1,
   -1,   -1,   41,  258,   43,   44,   45,   59,   -1,   -1,
  265,   41,   93,   -1,   44,  125,  257,  258,  259,   -1,
   59,   93,   37,   -1,  265,   -1,   41,   42,   43,   59,
   45,   -1,   47,   -1,   -1,  276,   -1,   -1,   -1,   -1,
   -1,   93,   -1,   -1,  125,   -1,   -1,  257,  258,  259,
   -1,   -1,   -1,  125,   93,  265,  257,  258,  259,   37,
   -1,   -1,   -1,   93,   42,   43,  276,   45,   -1,   47,
   -1,   -1,   37,  125,   -1,  276,   41,   42,   43,   94,
   45,   -1,   47,   -1,   -1,   -1,  125,   -1,   -1,  257,
  258,  259,   -1,   -1,   -1,  125,  264,  265,  266,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,  276,  257,
  258,  259,   -1,   -1,   -1,   93,   94,  265,  257,  258,
  259,   -1,   -1,   -1,   -1,   37,  265,   -1,  276,   94,
   42,   43,   -1,   45,   37,   47,   -1,  276,   41,   42,
   43,   -1,   45,   -1,   47,   -1,   37,  257,  258,  259,
   41,   42,   43,   -1,   45,  265,   47,   37,   -1,   -1,
   -1,   41,   42,   43,   -1,   45,  276,   47,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,  257,  258,  259,   -1,
   -1,   -1,   94,   -1,  265,  257,  258,  259,   -1,   -1,
   -1,   94,   -1,  265,   -1,  276,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   94,  276,  257,  258,  259,   -1,   -1,
   -1,   -1,   -1,  265,   94,   -1,   -1,   -1,  257,  258,
  259,   -1,   -1,   -1,  276,   -1,  265,  257,   -1,  259,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,  276,   -1,   -1,
   -1,   -1,   -1,  258,  259,   -1,  276,   -1,   -1,   -1,
  265,   -1,   -1,   -1,   -1,   -1,   -1,    3,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   12,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
  258,  259,   28,   29,   -1,   -1,   -1,  265,   -1,   -1,
   -1,   -1,   -1,  258,  259,   41,   42,   -1,   -1,   -1,
  265,   47,   -1,   -1,   -1,   51,   -1,   53,   54,   -1,
   56,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   64,   65,
   66,   67,   68,   69,   70,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   82,   -1,   84,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,  258,  259,   -1,   -1,
   96,   97,   -1,  265,   -1,  258,  259,   -1,   -1,  105,
   -1,  107,  265,  109,   -1,   -1,   -1,  258,  259,   -1,
   -1,   -1,   -1,   -1,  265,   -1,  122,   -1,  258,  259,
   -1,   -1,   -1,   -1,   -1,  265,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,  139,   -1,   -1,   -1,   -1,   -1,   -1,
  146,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1,
   -1,   -1,   -1,  169,
};
#define YYFINAL 1
#ifndef YYDEBUG
#define YYDEBUG 0
#endif
#define YYMAXTOKEN 289
#if YYDEBUG
const char * const yyname[] = {
"end-of-file",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,"'%'",0,0,"'('","')'","'*'","'+'","','","'-'",0,"'/'",0,0,0,0,0,0,0,0,0,0,
0,"';'",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,"'['",0,
"']'","'^'",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,"'{'",0,
"'}'",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,"ENDOFLINE","AND","OR","NOT","STRING","NAME",
"NUMBER","ASSIGN_OP","REL_OP","INCR_DECR","Define","Break","Quit","Length",
"Return","For","If","While","Sqrt","Else","Scale","Ibase","Obase","Auto","Read",
"Warranty","Halt","Last","Continue","Print","Limits","UNARY_MINUS","HistoryVar",
};
const char * const yyrule[] = {
"$accept : program",
"program :",
"program : program input_item",
"input_item : semicolon_list ENDOFLINE",
"input_item : function",
"input_item : error ENDOFLINE",
"opt_newline :",
"opt_newline : ENDOFLINE",
"semicolon_list :",
"semicolon_list : statement_or_error",
"semicolon_list : semicolon_list ';' statement_or_error",
"semicolon_list : semicolon_list ';'",
"statement_list :",
"statement_list : statement_or_error",
"statement_list : statement_list ENDOFLINE",
"statement_list : statement_list ENDOFLINE statement_or_error",
"statement_list : statement_list ';'",
"statement_list : statement_list ';' statement",
"statement_or_error : statement",
"statement_or_error : error statement",
"statement : Warranty",
"statement : Limits",
"statement : expression",
"statement : STRING",
"statement : Break",
"statement : Continue",
"statement : Quit",
"statement : Halt",
"statement : Return return_expression",
"$$1 :",
"$$2 :",
"$$3 :",
"$$4 :",
"statement : For $$1 '(' opt_expression ';' $$2 opt_expression ';' $$3 opt_expression ')' $$4 opt_newline statement",
"$$5 :",
"statement : If '(' expression ')' $$5 opt_newline statement opt_else",
"$$6 :",
"$$7 :",
"statement : While $$6 '(' expression $$7 ')' opt_newline statement",
"statement : '{' statement_list '}'",
"$$8 :",
"statement : Print $$8 print_list",
"print_list : print_element",
"print_list : print_element ',' print_list",
"print_element : STRING",
"print_element : expression",
"opt_else :",
"$$9 :",
"opt_else : Else $$9 opt_newline statement",
"$$10 :",
"function : Define NAME '(' opt_parameter_list ')' opt_newline '{' required_eol opt_auto_define_list $$10 statement_list '}'",
"opt_parameter_list :",
"opt_parameter_list : define_list",
"opt_auto_define_list :",
"opt_auto_define_list : Auto define_list ENDOFLINE",
"opt_auto_define_list : Auto define_list ';'",
"define_list : NAME",
"define_list : NAME '[' ']'",
"define_list : '*' NAME '[' ']'",
"define_list : define_list ',' NAME",
"define_list : define_list ',' NAME '[' ']'",
"define_list : define_list ',' '*' NAME '[' ']'",
"opt_argument_list :",
"opt_argument_list : argument_list",
"argument_list : expression",
"argument_list : NAME '[' ']'",
"argument_list : argument_list ',' expression",
"argument_list : argument_list ',' NAME '[' ']'",
"opt_expression :",
"opt_expression : expression",
"return_expression :",
"return_expression : expression",
"$$11 :",
"expression : named_expression ASSIGN_OP $$11 expression",
"$$12 :",
"expression : expression AND $$12 expression",
"$$13 :",
"expression : expression OR $$13 expression",
"expression : NOT expression",
"expression : expression REL_OP expression",
"expression : expression '+' expression",
"expression : expression '-' expression",
"expression : expression '*' expression",
"expression : expression '/' expression",
"expression : expression '%' expression",
"expression : expression '^' expression",
"expression : '-' expression",
"expression : named_expression",
"expression : NUMBER",
"expression : '(' expression ')'",
"expression : NAME '(' opt_argument_list ')'",
"expression : INCR_DECR named_expression",
"expression : named_expression INCR_DECR",
"expression : Length '(' expression ')'",
"expression : Sqrt '(' expression ')'",
"expression : Scale '(' expression ')'",
"expression : Read '(' ')'",
"named_expression : NAME",
"named_expression : NAME '[' expression ']'",
"named_expression : Ibase",
"named_expression : Obase",
"named_expression : Scale",
"named_expression : HistoryVar",
"named_expression : Last",
"required_eol :",
"required_eol : ENDOFLINE",
"required_eol : required_eol ENDOFLINE",
};
#endif
#if YYDEBUG
#include <stdio.h>
#endif
#ifdef YYSTACKSIZE
#undef YYMAXDEPTH
#define YYMAXDEPTH YYSTACKSIZE
#else
#ifdef YYMAXDEPTH
#define YYSTACKSIZE YYMAXDEPTH
#else
#define YYSTACKSIZE 10000
#define YYMAXDEPTH 10000
#endif
#endif
#define YYINITSTACKSIZE 200
int yydebug;
int yynerrs;
int yyerrflag;
int yychar;
short *yyssp;
YYSTYPE *yyvsp;
YYSTYPE yyval;
YYSTYPE yylval;
short *yyss;
short *yysslim;
YYSTYPE *yyvs;
int yystacksize;
#line 654 "bc.y"

#line 606 "y.tab.c"
/* allocate initial stack or double stack size, up to YYMAXDEPTH */
static int yygrowstack()
{
    int newsize, i;
    short *newss;
    YYSTYPE *newvs;

    if ((newsize = yystacksize) == 0)
        newsize = YYINITSTACKSIZE;
    else if (newsize >= YYMAXDEPTH)
        return -1;
    else if ((newsize *= 2) > YYMAXDEPTH)
        newsize = YYMAXDEPTH;
    i = yyssp - yyss;
    newss = yyss ? (short *)realloc(yyss, newsize * sizeof *newss) :
      (short *)malloc(newsize * sizeof *newss);
    if (newss == NULL)
        return -1;
    yyss = newss;
    yyssp = newss + i;
    newvs = yyvs ? (YYSTYPE *)realloc(yyvs, newsize * sizeof *newvs) :
      (YYSTYPE *)malloc(newsize * sizeof *newvs);
    if (newvs == NULL)
        return -1;
    yyvs = newvs;
    yyvsp = newvs + i;
    yystacksize = newsize;
    yysslim = yyss + newsize - 1;
    return 0;
}

#define YYABORT goto yyabort
#define YYREJECT goto yyabort
#define YYACCEPT goto yyaccept
#define YYERROR goto yyerrlab

#ifndef YYPARSE_PARAM
#if defined(__cplusplus) || __STDC__
#define YYPARSE_PARAM_ARG void
#define YYPARSE_PARAM_DECL
#else	/* ! ANSI-C/C++ */
#define YYPARSE_PARAM_ARG
#define YYPARSE_PARAM_DECL
#endif	/* ANSI-C/C++ */
#else	/* YYPARSE_PARAM */
#ifndef YYPARSE_PARAM_TYPE
#define YYPARSE_PARAM_TYPE void *
#endif
#if defined(__cplusplus) || __STDC__
#define YYPARSE_PARAM_ARG YYPARSE_PARAM_TYPE YYPARSE_PARAM
#define YYPARSE_PARAM_DECL
#else	/* ! ANSI-C/C++ */
#define YYPARSE_PARAM_ARG YYPARSE_PARAM
#define YYPARSE_PARAM_DECL YYPARSE_PARAM_TYPE YYPARSE_PARAM;
#endif	/* ANSI-C/C++ */
#endif	/* ! YYPARSE_PARAM */

int
yyparse (YYPARSE_PARAM_ARG)
    YYPARSE_PARAM_DECL
{
    register int yym, yyn, yystate;
#if YYDEBUG
    register const char *yys;

    if ((yys = getenv("YYDEBUG")))
    {
        yyn = *yys;
        if (yyn >= '0' && yyn <= '9')
            yydebug = yyn - '0';
    }
#endif

    yynerrs = 0;
    yyerrflag = 0;
    yychar = (-1);

    if (yyss == NULL && yygrowstack()) goto yyoverflow;
    yyssp = yyss;
    yyvsp = yyvs;
    *yyssp = yystate = 0;

yyloop:
    if ((yyn = yydefred[yystate])) goto yyreduce;
    if (yychar < 0)
    {
        if ((yychar = yylex()) < 0) yychar = 0;
#if YYDEBUG
        if (yydebug)
        {
            yys = 0;
            if (yychar <= YYMAXTOKEN) yys = yyname[yychar];
            if (!yys) yys = "illegal-symbol";
            printf("%sdebug: state %d, reading %d (%s)\n",
                    YYPREFIX, yystate, yychar, yys);
        }
#endif
    }
    if ((yyn = yysindex[yystate]) && (yyn += yychar) >= 0 &&
            yyn <= YYTABLESIZE && yycheck[yyn] == yychar)
    {
#if YYDEBUG
        if (yydebug)
            printf("%sdebug: state %d, shifting to state %d\n",
                    YYPREFIX, yystate, yytable[yyn]);
#endif
        if (yyssp >= yysslim && yygrowstack())
        {
            goto yyoverflow;
        }
        *++yyssp = yystate = yytable[yyn];
        *++yyvsp = yylval;
        yychar = (-1);
        if (yyerrflag > 0)  --yyerrflag;
        goto yyloop;
    }
    if ((yyn = yyrindex[yystate]) && (yyn += yychar) >= 0 &&
            yyn <= YYTABLESIZE && yycheck[yyn] == yychar)
    {
        yyn = yytable[yyn];
        goto yyreduce;
    }
    if (yyerrflag) goto yyinrecovery;
#if defined(lint) || defined(__GNUC__)
    goto yynewerror;
#endif
yynewerror:
    yyerror("syntax error");
#if defined(lint) || defined(__GNUC__)
    goto yyerrlab;
#endif
yyerrlab:
    ++yynerrs;
yyinrecovery:
    if (yyerrflag < 3)
    {
        yyerrflag = 3;
        for (;;)
        {
            if ((yyn = yysindex[*yyssp]) && (yyn += YYERRCODE) >= 0 &&
                    yyn <= YYTABLESIZE && yycheck[yyn] == YYERRCODE)
            {
#if YYDEBUG
                if (yydebug)
                    printf("%sdebug: state %d, error recovery shifting\
 to state %d\n", YYPREFIX, *yyssp, yytable[yyn]);
#endif
                if (yyssp >= yysslim && yygrowstack())
                {
                    goto yyoverflow;
                }
                *++yyssp = yystate = yytable[yyn];
                *++yyvsp = yylval;
                goto yyloop;
            }
            else
            {
#if YYDEBUG
                if (yydebug)
                    printf("%sdebug: error recovery discarding state %d\n",
                            YYPREFIX, *yyssp);
#endif
                if (yyssp <= yyss) goto yyabort;
                --yyssp;
                --yyvsp;
            }
        }
    }
    else
    {
        if (yychar == 0) goto yyabort;
#if YYDEBUG
        if (yydebug)
        {
            yys = 0;
            if (yychar <= YYMAXTOKEN) yys = yyname[yychar];
            if (!yys) yys = "illegal-symbol";
            printf("%sdebug: state %d, error recovery discards token %d (%s)\n",
                    YYPREFIX, yystate, yychar, yys);
        }
#endif
        yychar = (-1);
        goto yyloop;
    }
yyreduce:
#if YYDEBUG
    if (yydebug)
        printf("%sdebug: state %d, reducing by rule %d (%s)\n",
                YYPREFIX, yystate, yyn, yyrule[yyn]);
#endif
    yym = yylen[yyn];
    yyval = yyvsp[1-yym];
    switch (yyn)
    {
case 1:
#line 108 "bc.y"
{
			      yyval.i_value = 0;
			      if (interactive && !quiet)
				{
				  show_bc_version ();
				  welcome ();
				}
			    }
break;
case 3:
#line 119 "bc.y"
{ run_code (); }
break;
case 4:
#line 121 "bc.y"
{ run_code (); }
break;
case 5:
#line 123 "bc.y"
{
			      yyerrok;
			      init_gen ();
			    }
break;
case 7:
#line 130 "bc.y"
{ my_warn ("newline not allowed"); }
break;
case 8:
#line 133 "bc.y"
{ yyval.i_value = 0; }
break;
case 12:
#line 139 "bc.y"
{ yyval.i_value = 0; }
break;
case 19:
#line 148 "bc.y"
{ yyval.i_value = yyvsp[0].i_value; }
break;
case 20:
#line 151 "bc.y"
{ warranty (""); }
break;
case 21:
#line 153 "bc.y"
{ limits (); }
break;
case 22:
#line 155 "bc.y"
{
			      if (yyvsp[0].i_value & 2)
				my_warn ("comparison in expression");
			      if (yyvsp[0].i_value & 1)
				generate ("W");
			      else 
				generate ("p");
			    }
break;
case 23:
#line 164 "bc.y"
{
			      yyval.i_value = 0;
			      generate ("w");
			      generate (yyvsp[0].s_value);
			      free (yyvsp[0].s_value);
			    }
break;
case 24:
#line 171 "bc.y"
{
			      if (break_label == 0)
				yyerror ("Break outside a for/while");
			      else
				{
				  sprintf (genstr, "J%1d:", break_label);
				  generate (genstr);
				}
			    }
break;
case 25:
#line 181 "bc.y"
{
			      my_warn ("Continue statement");
			      if (continue_label == 0)
				yyerror ("Continue outside a for");
			      else
				{
				  sprintf (genstr, "J%1d:", continue_label);
				  generate (genstr);
				}
			    }
break;
case 26:
#line 192 "bc.y"
{ exit (0); }
break;
case 27:
#line 194 "bc.y"
{ generate ("h"); }
break;
case 28:
#line 196 "bc.y"
{ generate ("R"); }
break;
case 29:
#line 198 "bc.y"
{
			      yyvsp[0].i_value = break_label; 
			      break_label = next_label++;
			    }
break;
case 30:
#line 203 "bc.y"
{
			      if (yyvsp[-1].i_value & 2)
				my_warn ("Comparison in first for expression");
			      if (yyvsp[-1].i_value >= 0)
				generate ("p");
			      yyvsp[-1].i_value = next_label++;
			      sprintf (genstr, "N%1d:", yyvsp[-1].i_value);
			      generate (genstr);
			    }
break;
case 31:
#line 213 "bc.y"
{
			      if (yyvsp[-1].i_value < 0) generate ("1");
			      yyvsp[-1].i_value = next_label++;
			      sprintf (genstr, "B%1d:J%1d:", yyvsp[-1].i_value, break_label);
			      generate (genstr);
			      yyval.i_value = continue_label;
			      continue_label = next_label++;
			      sprintf (genstr, "N%1d:", continue_label);
			      generate (genstr);
			    }
break;
case 32:
#line 224 "bc.y"
{
			      if (yyvsp[-1].i_value & 2 )
				my_warn ("Comparison in third for expression");
			      if (yyvsp[-1].i_value & 16)
				sprintf (genstr, "J%1d:N%1d:", yyvsp[-7].i_value, yyvsp[-4].i_value);
			      else
				sprintf (genstr, "pJ%1d:N%1d:", yyvsp[-7].i_value, yyvsp[-4].i_value);
			      generate (genstr);
			    }
break;
case 33:
#line 234 "bc.y"
{
			      sprintf (genstr, "J%1d:N%1d:",
				       continue_label, break_label);
			      generate (genstr);
			      break_label = yyvsp[-13].i_value;
			      continue_label = yyvsp[-5].i_value;
			    }
break;
case 34:
#line 242 "bc.y"
{
			      yyvsp[-1].i_value = if_label;
			      if_label = next_label++;
			      sprintf (genstr, "Z%1d:", if_label);
			      generate (genstr);
			    }
break;
case 35:
#line 249 "bc.y"
{
			      sprintf (genstr, "N%1d:", if_label); 
			      generate (genstr);
			      if_label = yyvsp[-5].i_value;
			    }
break;
case 36:
#line 255 "bc.y"
{
			      yyvsp[0].i_value = next_label++;
			      sprintf (genstr, "N%1d:", yyvsp[0].i_value);
			      generate (genstr);
			    }
break;
case 37:
#line 261 "bc.y"
{
			      yyvsp[0].i_value = break_label; 
			      break_label = next_label++;
			      sprintf (genstr, "Z%1d:", break_label);
			      generate (genstr);
			    }
break;
case 38:
#line 268 "bc.y"
{
			      sprintf (genstr, "J%1d:N%1d:", yyvsp[-7].i_value, break_label);
			      generate (genstr);
			      break_label = yyvsp[-4].i_value;
			    }
break;
case 39:
#line 274 "bc.y"
{ yyval.i_value = 0; }
break;
case 40:
#line 276 "bc.y"
{  my_warn ("print statement"); }
break;
case 44:
#line 283 "bc.y"
{
			      generate ("O");
			      generate (yyvsp[0].s_value);
			      free (yyvsp[0].s_value);
			    }
break;
case 45:
#line 289 "bc.y"
{ generate ("P"); }
break;
case 47:
#line 293 "bc.y"
{
			      my_warn ("else clause in if statement");
			      yyvsp[0].i_value = next_label++;
			      sprintf (genstr, "J%d:N%1d:", yyvsp[0].i_value, if_label); 
			      generate (genstr);
			      if_label = yyvsp[0].i_value;
			    }
break;
case 49:
#line 303 "bc.y"
{
			      /* Check auto list against parameter list? */
			      check_params (yyvsp[-5].a_value,yyvsp[0].a_value);
			      sprintf (genstr, "F%d,%s.%s[",
				       lookup(yyvsp[-7].s_value,FUNCTDEF), 
				       arg_str (yyvsp[-5].a_value), arg_str (yyvsp[0].a_value));
			      generate (genstr);
			      free_args (yyvsp[-5].a_value);
			      free_args (yyvsp[0].a_value);
			      yyvsp[-8].i_value = next_label;
			      next_label = 1;
			    }
break;
case 50:
#line 316 "bc.y"
{
			      generate ("0R]");
			      next_label = yyvsp[-11].i_value;
			    }
break;
case 51:
#line 322 "bc.y"
{ yyval.a_value = NULL; }
break;
case 53:
#line 326 "bc.y"
{ yyval.a_value = NULL; }
break;
case 54:
#line 328 "bc.y"
{ yyval.a_value = yyvsp[-1].a_value; }
break;
case 55:
#line 330 "bc.y"
{ yyval.a_value = yyvsp[-1].a_value; }
break;
case 56:
#line 333 "bc.y"
{ yyval.a_value = nextarg (NULL, lookup (yyvsp[0].s_value,SIMPLE), FALSE);}
break;
case 57:
#line 335 "bc.y"
{ yyval.a_value = nextarg (NULL, lookup (yyvsp[-2].s_value,ARRAY), FALSE); }
break;
case 58:
#line 337 "bc.y"
{ yyval.a_value = nextarg (NULL, lookup (yyvsp[-2].s_value,ARRAY), TRUE); }
break;
case 59:
#line 339 "bc.y"
{ yyval.a_value = nextarg (yyvsp[-2].a_value, lookup (yyvsp[0].s_value,SIMPLE), FALSE); }
break;
case 60:
#line 341 "bc.y"
{ yyval.a_value = nextarg (yyvsp[-4].a_value, lookup (yyvsp[-2].s_value,ARRAY), FALSE); }
break;
case 61:
#line 343 "bc.y"
{ yyval.a_value = nextarg (yyvsp[-5].a_value, lookup (yyvsp[-2].s_value,ARRAY), TRUE); }
break;
case 62:
#line 346 "bc.y"
{ yyval.a_value = NULL; }
break;
case 64:
#line 350 "bc.y"
{
			      if (yyvsp[0].i_value & 2) my_warn ("comparison in argument");
			      yyval.a_value = nextarg (NULL,0,FALSE);
			    }
break;
case 65:
#line 355 "bc.y"
{
			      sprintf (genstr, "K%d:", -lookup (yyvsp[-2].s_value,ARRAY));
			      generate (genstr);
			      yyval.a_value = nextarg (NULL,1,FALSE);
			    }
break;
case 66:
#line 361 "bc.y"
{
			      if (yyvsp[0].i_value & 2) my_warn ("comparison in argument");
			      yyval.a_value = nextarg (yyvsp[-2].a_value,0,FALSE);
			    }
break;
case 67:
#line 366 "bc.y"
{
			      sprintf (genstr, "K%d:", -lookup (yyvsp[-2].s_value,ARRAY));
			      generate (genstr);
			      yyval.a_value = nextarg (yyvsp[-4].a_value,1,FALSE);
			    }
break;
case 68:
#line 382 "bc.y"
{
			      yyval.i_value = 16;
			      my_warn ("Missing expression in for statement");
			    }
break;
case 70:
#line 389 "bc.y"
{
			      yyval.i_value = 0;
			      generate ("0");
			    }
break;
case 71:
#line 394 "bc.y"
{
			      if (yyvsp[0].i_value & 2)
				my_warn ("comparison in return expresion");
			      if (!(yyvsp[0].i_value & 4))
				my_warn ("return expression requires parenthesis");
			    }
break;
case 72:
#line 402 "bc.y"
{
			      if (yyvsp[0].c_value != '=')
				{
				  if (yyvsp[-1].i_value < 0)
				    sprintf (genstr, "DL%d:", -yyvsp[-1].i_value);
				  else
				    sprintf (genstr, "l%d:", yyvsp[-1].i_value);
				  generate (genstr);
				}
			    }
break;
case 73:
#line 413 "bc.y"
{
			      if (yyvsp[0].i_value & 2) my_warn("comparison in assignment");
			      if (yyvsp[-2].c_value != '=')
				{
				  sprintf (genstr, "%c", yyvsp[-2].c_value);
				  generate (genstr);
				}
			      if (yyvsp[-3].i_value < 0)
				sprintf (genstr, "S%d:", -yyvsp[-3].i_value);
			      else
				sprintf (genstr, "s%d:", yyvsp[-3].i_value);
			      generate (genstr);
			      yyval.i_value = 0;
			    }
break;
case 74:
#line 429 "bc.y"
{
			      my_warn("&& operator");
			      yyvsp[0].i_value = next_label++;
			      sprintf (genstr, "DZ%d:p", yyvsp[0].i_value);
			      generate (genstr);
			    }
break;
case 75:
#line 436 "bc.y"
{
			      sprintf (genstr, "DZ%d:p1N%d:", yyvsp[-2].i_value, yyvsp[-2].i_value);
			      generate (genstr);
			      yyval.i_value = (yyvsp[-3].i_value | yyvsp[0].i_value) & ~4;
			    }
break;
case 76:
#line 442 "bc.y"
{
			      my_warn("|| operator");
			      yyvsp[0].i_value = next_label++;
			      sprintf (genstr, "B%d:", yyvsp[0].i_value);
			      generate (genstr);
			    }
break;
case 77:
#line 449 "bc.y"
{
			      int tmplab;
			      tmplab = next_label++;
			      sprintf (genstr, "B%d:0J%d:N%d:1N%d:",
				       yyvsp[-2].i_value, tmplab, yyvsp[-2].i_value, tmplab);
			      generate (genstr);
			      yyval.i_value = (yyvsp[-3].i_value | yyvsp[0].i_value) & ~4;
			    }
break;
case 78:
#line 458 "bc.y"
{
			      yyval.i_value = yyvsp[0].i_value & ~4;
			      my_warn("! operator");
			      generate ("!");
			    }
break;
case 79:
#line 464 "bc.y"
{
			      yyval.i_value = 3;
			      switch (*(yyvsp[-1].s_value))
				{
				case '=':
				  generate ("=");
				  break;

				case '!':
				  generate ("#");
				  break;

				case '<':
				  if (yyvsp[-1].s_value[1] == '=')
				    generate ("{");
				  else
				    generate ("<");
				  break;

				case '>':
				  if (yyvsp[-1].s_value[1] == '=')
				    generate ("}");
				  else
				    generate (">");
				  break;
				}
			    }
break;
case 80:
#line 492 "bc.y"
{
			      generate ("+");
			      yyval.i_value = (yyvsp[-2].i_value | yyvsp[0].i_value) & ~4;
			    }
break;
case 81:
#line 497 "bc.y"
{
			      generate ("-");
			      yyval.i_value = (yyvsp[-2].i_value | yyvsp[0].i_value) & ~4;
			    }
break;
case 82:
#line 502 "bc.y"
{
			      generate ("*");
			      yyval.i_value = (yyvsp[-2].i_value | yyvsp[0].i_value) & ~4;
			    }
break;
case 83:
#line 507 "bc.y"
{
			      generate ("/");
			      yyval.i_value = (yyvsp[-2].i_value | yyvsp[0].i_value) & ~4;
			    }
break;
case 84:
#line 512 "bc.y"
{
			      generate ("%");
			      yyval.i_value = (yyvsp[-2].i_value | yyvsp[0].i_value) & ~4;
			    }
break;
case 85:
#line 517 "bc.y"
{
			      generate ("^");
			      yyval.i_value = (yyvsp[-2].i_value | yyvsp[0].i_value) & ~4;
			    }
break;
case 86:
#line 522 "bc.y"
{
			      generate ("n");
			      yyval.i_value = yyvsp[0].i_value & ~4;
			    }
break;
case 87:
#line 527 "bc.y"
{
			      yyval.i_value = 1;
			      if (yyvsp[0].i_value < 0)
				sprintf (genstr, "L%d:", -yyvsp[0].i_value);
			      else
				sprintf (genstr, "l%d:", yyvsp[0].i_value);
			      generate (genstr);
			    }
break;
case 88:
#line 536 "bc.y"
{
			      int len = strlen(yyvsp[0].s_value);
			      yyval.i_value = 1;
			      if (len == 1 && *yyvsp[0].s_value == '0')
				generate ("0");
			      else if (len == 1 && *yyvsp[0].s_value == '1')
				generate ("1");
			      else
				{
				  generate ("K");
				  generate (yyvsp[0].s_value);
				  generate (":");
				}
			      free (yyvsp[0].s_value);
			    }
break;
case 89:
#line 552 "bc.y"
{ yyval.i_value = yyvsp[-1].i_value | 5; }
break;
case 90:
#line 554 "bc.y"
{
			      yyval.i_value = 1;
			      if (yyvsp[-1].a_value != NULL)
				{ 
				  sprintf (genstr, "C%d,%s:",
					   lookup (yyvsp[-3].s_value,FUNCT),
					   call_str (yyvsp[-1].a_value));
				  free_args (yyvsp[-1].a_value);
				}
			      else
				{
				  sprintf (genstr, "C%d:", lookup (yyvsp[-3].s_value,FUNCT));
				}
			      generate (genstr);
			    }
break;
case 91:
#line 570 "bc.y"
{
			      yyval.i_value = 1;
			      if (yyvsp[0].i_value < 0)
				{
				  if (yyvsp[-1].c_value == '+')
				    sprintf (genstr, "DA%d:L%d:", -yyvsp[0].i_value, -yyvsp[0].i_value);
				  else
				    sprintf (genstr, "DM%d:L%d:", -yyvsp[0].i_value, -yyvsp[0].i_value);
				}
			      else
				{
				  if (yyvsp[-1].c_value == '+')
				    sprintf (genstr, "i%d:l%d:", yyvsp[0].i_value, yyvsp[0].i_value);
				  else
				    sprintf (genstr, "d%d:l%d:", yyvsp[0].i_value, yyvsp[0].i_value);
				}
			      generate (genstr);
			    }
break;
case 92:
#line 589 "bc.y"
{
			      yyval.i_value = 1;
			      if (yyvsp[-1].i_value < 0)
				{
				  sprintf (genstr, "DL%d:x", -yyvsp[-1].i_value);
				  generate (genstr); 
				  if (yyvsp[0].c_value == '+')
				    sprintf (genstr, "A%d:", -yyvsp[-1].i_value);
				  else
				      sprintf (genstr, "M%d:", -yyvsp[-1].i_value);
				}
			      else
				{
				  sprintf (genstr, "l%d:", yyvsp[-1].i_value);
				  generate (genstr);
				  if (yyvsp[0].c_value == '+')
				    sprintf (genstr, "i%d:", yyvsp[-1].i_value);
				  else
				    sprintf (genstr, "d%d:", yyvsp[-1].i_value);
				}
			      generate (genstr);
			    }
break;
case 93:
#line 612 "bc.y"
{ generate ("cL"); yyval.i_value = 1;}
break;
case 94:
#line 614 "bc.y"
{ generate ("cR"); yyval.i_value = 1;}
break;
case 95:
#line 616 "bc.y"
{ generate ("cS"); yyval.i_value = 1;}
break;
case 96:
#line 618 "bc.y"
{
			      my_warn ("read function");
			      generate ("cI"); yyval.i_value = 1;
			    }
break;
case 97:
#line 624 "bc.y"
{ yyval.i_value = lookup(yyvsp[0].s_value,SIMPLE); }
break;
case 98:
#line 626 "bc.y"
{
			      if (yyvsp[-1].i_value > 1) my_warn("comparison in subscript");
			      yyval.i_value = lookup(yyvsp[-3].s_value,ARRAY);
			    }
break;
case 99:
#line 631 "bc.y"
{ yyval.i_value = 0; }
break;
case 100:
#line 633 "bc.y"
{ yyval.i_value = 1; }
break;
case 101:
#line 635 "bc.y"
{ yyval.i_value = 2; }
break;
case 102:
#line 637 "bc.y"
{ yyval.i_value = 3;
			      my_warn ("History variable");
			    }
break;
case 103:
#line 641 "bc.y"
{ yyval.i_value = 4;
			      my_warn ("Last variable");
			    }
break;
case 104:
#line 647 "bc.y"
{ my_warn ("End of line required"); }
break;
case 106:
#line 650 "bc.y"
{ my_warn ("Too many end of lines"); }
break;
#line 1466 "y.tab.c"
    }
    yyssp -= yym;
    yystate = *yyssp;
    yyvsp -= yym;
    yym = yylhs[yyn];
    if (yystate == 0 && yym == 0)
    {
#if YYDEBUG
        if (yydebug)
            printf("%sdebug: after reduction, shifting from state 0 to\
 state %d\n", YYPREFIX, YYFINAL);
#endif
        yystate = YYFINAL;
        *++yyssp = YYFINAL;
        *++yyvsp = yyval;
        if (yychar < 0)
        {
            if ((yychar = yylex()) < 0) yychar = 0;
#if YYDEBUG
            if (yydebug)
            {
                yys = 0;
                if (yychar <= YYMAXTOKEN) yys = yyname[yychar];
                if (!yys) yys = "illegal-symbol";
                printf("%sdebug: state %d, reading %d (%s)\n",
                        YYPREFIX, YYFINAL, yychar, yys);
            }
#endif
        }
        if (yychar == 0) goto yyaccept;
        goto yyloop;
    }
    if ((yyn = yygindex[yym]) && (yyn += yystate) >= 0 &&
            yyn <= YYTABLESIZE && yycheck[yyn] == yystate)
        yystate = yytable[yyn];
    else
        yystate = yydgoto[yym];
#if YYDEBUG
    if (yydebug)
        printf("%sdebug: after reduction, shifting from state %d \
to state %d\n", YYPREFIX, *yyssp, yystate);
#endif
    if (yyssp >= yysslim && yygrowstack())
    {
        goto yyoverflow;
    }
    *++yyssp = yystate;
    *++yyvsp = yyval;
    goto yyloop;
yyoverflow:
    yyerror("yacc stack overflow");
yyabort:
    return (1);
yyaccept:
    return (0);
}
