/* A Bison parser, made by GNU Bison 3.3.1.  */

/* Bison interface for Yacc-like parsers in C

   Copyright (C) 1984, 1989-1990, 2000-2015, 2018-2019 Free Software Foundation,
   Inc.

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

/* Undocumented macros, especially those whose name start with YY_,
   are private implementation details.  Do not rely on them.  */

#ifndef YY_ITEX2MML_YY_Y_TAB_H_INCLUDED
# define YY_ITEX2MML_YY_Y_TAB_H_INCLUDED
/* Debug traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif
#if YYDEBUG
extern int itex2MML_yydebug;
#endif

/* Token type.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
  enum yytokentype
  {
    TEXOVER = 258,
    TEXATOP = 259,
    CHAR = 260,
    STARTMATH = 261,
    STARTDMATH = 262,
    ENDMATH = 263,
    MI = 264,
    MIB = 265,
    MN = 266,
    MO = 267,
    SUP = 268,
    SUB = 269,
    MROWOPEN = 270,
    MROWCLOSE = 271,
    LEFT = 272,
    RIGHT = 273,
    BIG = 274,
    BBIG = 275,
    BIGG = 276,
    BBIGG = 277,
    BIGL = 278,
    BBIGL = 279,
    BIGGL = 280,
    BBIGGL = 281,
    FRAC = 282,
    TFRAC = 283,
    OPERATORNAME = 284,
    MATHOP = 285,
    MATHBIN = 286,
    MATHREL = 287,
    MOP = 288,
    MOL = 289,
    MOLL = 290,
    MOF = 291,
    MOR = 292,
    PERIODDELIM = 293,
    OTHERDELIM = 294,
    LEFTDELIM = 295,
    RIGHTDELIM = 296,
    MOS = 297,
    MOB = 298,
    SQRT = 299,
    ROOT = 300,
    BINOM = 301,
    TBINOM = 302,
    UNDER = 303,
    OVER = 304,
    OVERBRACE = 305,
    UNDERLINE = 306,
    UNDERBRACE = 307,
    UNDEROVER = 308,
    TENSOR = 309,
    MULTI = 310,
    ARRAYALIGN = 311,
    COLUMNALIGN = 312,
    ARRAY = 313,
    COLSEP = 314,
    ROWSEP = 315,
    ARRAYOPTS = 316,
    COLLAYOUT = 317,
    COLALIGN = 318,
    ROWALIGN = 319,
    ALIGN = 320,
    EQROWS = 321,
    EQCOLS = 322,
    ROWLINES = 323,
    COLLINES = 324,
    FRAME = 325,
    PADDING = 326,
    ATTRLIST = 327,
    ITALICS = 328,
    SANS = 329,
    TT = 330,
    BOLD = 331,
    BOXED = 332,
    SLASHED = 333,
    RM = 334,
    BB = 335,
    ST = 336,
    END = 337,
    BBLOWERCHAR = 338,
    BBUPPERCHAR = 339,
    BBDIGIT = 340,
    CALCHAR = 341,
    FRAKCHAR = 342,
    CAL = 343,
    SCR = 344,
    FRAK = 345,
    CLAP = 346,
    LLAP = 347,
    RLAP = 348,
    ROWOPTS = 349,
    TEXTSIZE = 350,
    SCSIZE = 351,
    SCSCSIZE = 352,
    DISPLAY = 353,
    TEXTSTY = 354,
    TEXTBOX = 355,
    TEXTSTRING = 356,
    XMLSTRING = 357,
    CELLOPTS = 358,
    ROWSPAN = 359,
    COLSPAN = 360,
    THINSPACE = 361,
    MEDSPACE = 362,
    THICKSPACE = 363,
    QUAD = 364,
    QQUAD = 365,
    NEGSPACE = 366,
    NEGMEDSPACE = 367,
    NEGTHICKSPACE = 368,
    PHANTOM = 369,
    HREF = 370,
    UNKNOWNCHAR = 371,
    EMPTYMROW = 372,
    STATLINE = 373,
    TOOLTIP = 374,
    TOGGLE = 375,
    TOGGLESTART = 376,
    TOGGLEEND = 377,
    FGHIGHLIGHT = 378,
    BGHIGHLIGHT = 379,
    SPACE = 380,
    INTONE = 381,
    INTTWO = 382,
    INTTHREE = 383,
    BAR = 384,
    WIDEBAR = 385,
    VEC = 386,
    WIDEVEC = 387,
    WIDELVEC = 388,
    WIDELRVEC = 389,
    WIDEUVEC = 390,
    WIDEULVEC = 391,
    WIDEULRVEC = 392,
    HAT = 393,
    WIDEHAT = 394,
    CHECK = 395,
    WIDECHECK = 396,
    TILDE = 397,
    WIDETILDE = 398,
    DOT = 399,
    DDOT = 400,
    DDDOT = 401,
    DDDDOT = 402,
    UNARYMINUS = 403,
    UNARYPLUS = 404,
    BEGINENV = 405,
    ENDENV = 406,
    MATRIX = 407,
    PMATRIX = 408,
    BMATRIX = 409,
    BBMATRIX = 410,
    VMATRIX = 411,
    VVMATRIX = 412,
    SVG = 413,
    ENDSVG = 414,
    SMALLMATRIX = 415,
    CASES = 416,
    ALIGNED = 417,
    GATHERED = 418,
    SUBSTACK = 419,
    PMOD = 420,
    RMCHAR = 421,
    COLOR = 422,
    BGCOLOR = 423,
    XARROW = 424,
    OPTARGOPEN = 425,
    OPTARGCLOSE = 426,
    ITEXNUM = 427,
    RAISEBOX = 428,
    NEG = 429
  };
#endif
/* Tokens.  */
#define TEXOVER 258
#define TEXATOP 259
#define CHAR 260
#define STARTMATH 261
#define STARTDMATH 262
#define ENDMATH 263
#define MI 264
#define MIB 265
#define MN 266
#define MO 267
#define SUP 268
#define SUB 269
#define MROWOPEN 270
#define MROWCLOSE 271
#define LEFT 272
#define RIGHT 273
#define BIG 274
#define BBIG 275
#define BIGG 276
#define BBIGG 277
#define BIGL 278
#define BBIGL 279
#define BIGGL 280
#define BBIGGL 281
#define FRAC 282
#define TFRAC 283
#define OPERATORNAME 284
#define MATHOP 285
#define MATHBIN 286
#define MATHREL 287
#define MOP 288
#define MOL 289
#define MOLL 290
#define MOF 291
#define MOR 292
#define PERIODDELIM 293
#define OTHERDELIM 294
#define LEFTDELIM 295
#define RIGHTDELIM 296
#define MOS 297
#define MOB 298
#define SQRT 299
#define ROOT 300
#define BINOM 301
#define TBINOM 302
#define UNDER 303
#define OVER 304
#define OVERBRACE 305
#define UNDERLINE 306
#define UNDERBRACE 307
#define UNDEROVER 308
#define TENSOR 309
#define MULTI 310
#define ARRAYALIGN 311
#define COLUMNALIGN 312
#define ARRAY 313
#define COLSEP 314
#define ROWSEP 315
#define ARRAYOPTS 316
#define COLLAYOUT 317
#define COLALIGN 318
#define ROWALIGN 319
#define ALIGN 320
#define EQROWS 321
#define EQCOLS 322
#define ROWLINES 323
#define COLLINES 324
#define FRAME 325
#define PADDING 326
#define ATTRLIST 327
#define ITALICS 328
#define SANS 329
#define TT 330
#define BOLD 331
#define BOXED 332
#define SLASHED 333
#define RM 334
#define BB 335
#define ST 336
#define END 337
#define BBLOWERCHAR 338
#define BBUPPERCHAR 339
#define BBDIGIT 340
#define CALCHAR 341
#define FRAKCHAR 342
#define CAL 343
#define SCR 344
#define FRAK 345
#define CLAP 346
#define LLAP 347
#define RLAP 348
#define ROWOPTS 349
#define TEXTSIZE 350
#define SCSIZE 351
#define SCSCSIZE 352
#define DISPLAY 353
#define TEXTSTY 354
#define TEXTBOX 355
#define TEXTSTRING 356
#define XMLSTRING 357
#define CELLOPTS 358
#define ROWSPAN 359
#define COLSPAN 360
#define THINSPACE 361
#define MEDSPACE 362
#define THICKSPACE 363
#define QUAD 364
#define QQUAD 365
#define NEGSPACE 366
#define NEGMEDSPACE 367
#define NEGTHICKSPACE 368
#define PHANTOM 369
#define HREF 370
#define UNKNOWNCHAR 371
#define EMPTYMROW 372
#define STATLINE 373
#define TOOLTIP 374
#define TOGGLE 375
#define TOGGLESTART 376
#define TOGGLEEND 377
#define FGHIGHLIGHT 378
#define BGHIGHLIGHT 379
#define SPACE 380
#define INTONE 381
#define INTTWO 382
#define INTTHREE 383
#define BAR 384
#define WIDEBAR 385
#define VEC 386
#define WIDEVEC 387
#define WIDELVEC 388
#define WIDELRVEC 389
#define WIDEUVEC 390
#define WIDEULVEC 391
#define WIDEULRVEC 392
#define HAT 393
#define WIDEHAT 394
#define CHECK 395
#define WIDECHECK 396
#define TILDE 397
#define WIDETILDE 398
#define DOT 399
#define DDOT 400
#define DDDOT 401
#define DDDDOT 402
#define UNARYMINUS 403
#define UNARYPLUS 404
#define BEGINENV 405
#define ENDENV 406
#define MATRIX 407
#define PMATRIX 408
#define BMATRIX 409
#define BBMATRIX 410
#define VMATRIX 411
#define VVMATRIX 412
#define SVG 413
#define ENDSVG 414
#define SMALLMATRIX 415
#define CASES 416
#define ALIGNED 417
#define GATHERED 418
#define SUBSTACK 419
#define PMOD 420
#define RMCHAR 421
#define COLOR 422
#define BGCOLOR 423
#define XARROW 424
#define OPTARGOPEN 425
#define OPTARGCLOSE 426
#define ITEXNUM 427
#define RAISEBOX 428
#define NEG 429

/* Value type.  */
#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
typedef int YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define YYSTYPE_IS_DECLARED 1
#endif


extern YYSTYPE itex2MML_yylval;

int itex2MML_yyparse (char **ret_str);

#endif /* !YY_ITEX2MML_YY_Y_TAB_H_INCLUDED  */
