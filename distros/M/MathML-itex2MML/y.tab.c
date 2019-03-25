/* A Bison parser, made by GNU Bison 3.3.1.  */

/* Bison implementation for Yacc-like parsers in C

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

/* C LALR(1) parser skeleton written by Richard Stallman, by
   simplifying the original so-called "semantic" parser.  */

/* All symbols defined below should begin with yy or YY, to avoid
   infringing on user name space.  This should be done even for local
   variables, as they might otherwise be expanded by user macros.
   There are some unavoidable exceptions within include files to
   define necessary library symbols; they are noted "INFRINGES ON
   USER NAME SPACE" below.  */

/* Undocumented macros, especially those whose name start with YY_,
   are private implementation details.  Do not rely on them.  */

/* Identify Bison output.  */
#define YYBISON 1

/* Bison version.  */
#define YYBISON_VERSION "3.3.1"

/* Skeleton name.  */
#define YYSKELETON_NAME "yacc.c"

/* Pure parsers.  */
#define YYPURE 0

/* Push parsers.  */
#define YYPUSH 0

/* Pull parsers.  */
#define YYPULL 1


/* Substitute the variable and function names.  */
#define yyparse         itex2MML_yyparse
#define yylex           itex2MML_yylex
#define yyerror         itex2MML_yyerror
#define yydebug         itex2MML_yydebug
#define yynerrs         itex2MML_yynerrs

#define yylval          itex2MML_yylval
#define yychar          itex2MML_yychar

/* First part of user prologue.  */
#line 7 "itex2MML.y" /* yacc.c:337  */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "itex2MML.h"

#define YYSTYPE char *
#define YYPARSE_PARAM_TYPE char **
#define YYPARSE_PARAM ret_str

#define yytext itex2MML_yytext

 extern int yylex ();
 int itex2MML_do_html_filter (const char * buffer, size_t length, const int forbid_markup);

 extern char * yytext;

 static void itex2MML_default_error (const char * msg)
   {
     if (msg)
       fprintf(stderr, "Line: %d Error: %s\n", itex2MML_lineno, msg);
   }

 void (*itex2MML_error) (const char * msg) = itex2MML_default_error;

 static void yyerror (char **ret_str, char * s)
   {
     char * msg = itex2MML_copy3 (s, " at token ", yytext);
     if (itex2MML_error)
       (*itex2MML_error) (msg);
     itex2MML_free_string (msg);
   }

 /* Note: If length is 0, then buffer is treated like a string; otherwise only length bytes are written.
  */
 static void itex2MML_default_write (const char * buffer, size_t length)
   {
     if (buffer)
       {
	 if (length)
	   fwrite (buffer, 1, length, stdout);
	 else
	   fputs (buffer, stdout);
       }
   }

 static void itex2MML_default_write_mathml (const char * mathml)
   {
     if (itex2MML_write)
       (*itex2MML_write) (mathml, 0);
   }

#ifdef itex2MML_CAPTURE
    static char * itex2MML_output_string = "" ;

    const char * itex2MML_output ()
    {
        char * copy = (char *) malloc((itex2MML_output_string ? strlen(itex2MML_output_string) : 0) + 1);
        if (copy)
          {
           if (itex2MML_output_string)
             {
               strcpy(copy, itex2MML_output_string);
               if (*itex2MML_output_string != '\0')
                   free(itex2MML_output_string);
             }
           else
             copy[0] = 0;
           itex2MML_output_string = "";
          }
        return copy;
    }

 static void itex2MML_capture (const char * buffer, size_t length)
    {
     if (buffer)
       {
         if (length)
           {
              size_t first_length = itex2MML_output_string ? strlen(itex2MML_output_string) : 0;
              char * copy  = (char *) malloc(first_length + length + 1);
              if (copy)
                {
                  if (itex2MML_output_string)
                    {
                       strcpy(copy, itex2MML_output_string);
                       if (*itex2MML_output_string != '\0')
                          free(itex2MML_output_string);
                    }
                  else
                     copy[0] = 0;
                  strncat(copy, buffer, length);
                  itex2MML_output_string = copy;
                 }
            }
         else
            {
              char * copy = itex2MML_copy2(itex2MML_output_string, buffer);
              if (*itex2MML_output_string != '\0')
                 free(itex2MML_output_string);
              itex2MML_output_string = copy;
            }
        }
    }

    static void itex2MML_capture_mathml (const char * buffer)
    {
       char * temp = itex2MML_copy2(itex2MML_output_string, buffer);
       if (*itex2MML_output_string != '\0')
         free(itex2MML_output_string);
       itex2MML_output_string = temp;
    }
    void (*itex2MML_write) (const char * buffer, size_t length) = itex2MML_capture;
    void (*itex2MML_write_mathml) (const char * mathml) = itex2MML_capture_mathml;
#else
    void (*itex2MML_write) (const char * buffer, size_t length) = itex2MML_default_write;
    void (*itex2MML_write_mathml) (const char * mathml) = itex2MML_default_write_mathml;
#endif 

 char * itex2MML_empty_string = "";

 /* Create a copy of a string, adding space for extra chars
  */
 char * itex2MML_copy_string_extra (const char * str, unsigned extra)
   {
     char * copy = (char *) malloc(extra + (str ? strlen (str) : 0) + 1);
     if (copy)
       {
	 if (str)
	   strcpy(copy, str);
	 else
	   copy[0] = 0;
       }
     return copy ? copy : itex2MML_empty_string;
   }

 /* Create a copy of a string, appending two strings
  */
 char * itex2MML_copy3 (const char * first, const char * second, const char * third)
   {
     size_t first_length =  first ? strlen( first) : 0;
     size_t second_length = second ? strlen(second) : 0;
     size_t third_length =  third ? strlen( third) : 0;

     char * copy = (char *) malloc(first_length + second_length + third_length + 1);

     if (copy)
       {
	 if (first)
	   strcpy(copy, first);
	 else
	   copy[0] = 0;

	 if (second) strcat(copy, second);
	 if ( third) strcat(copy,  third);
       }
     return copy ? copy : itex2MML_empty_string;
   }

 /* Create a copy of a string, appending a second string
  */
 char * itex2MML_copy2 (const char * first, const char * second)
   {
     return itex2MML_copy3(first, second, 0);
   }

 /* Create a copy of a string
  */
 char * itex2MML_copy_string (const char * str)
   {
     return itex2MML_copy3(str, 0, 0);
   }

 /* Create a copy of a string, escaping unsafe characters for XML
  */
 char * itex2MML_copy_escaped (const char * str)
   {
     size_t length = 0;

     const char * ptr1 = str;

     char * ptr2 = 0;
     char * copy = 0;

     if ( str == 0) return itex2MML_empty_string;
     if (*str == 0) return itex2MML_empty_string;

     while (*ptr1)
       {
	 switch (*ptr1)
	   {
	   case '<':  /* &lt;   */
	   case '>':  /* &gt;   */
	     length += 4;
	     break;
	   case '&':  /* &amp;  */
	     length += 5;
	     break;
	   case '\'': /* &apos; */
	   case '"':  /* &quot; */
	   case '-':  /* &#x2d; */
	     length += 6;
	     break;
	   default:
	     length += 1;
	     break;
	   }
	 ++ptr1;
       }

     copy = (char *) malloc (length + 1);

     if (copy)
       {
	 ptr1 = str;
	 ptr2 = copy;

	 while (*ptr1)
	   {
	     switch (*ptr1)
	       {
	       case '<':
		 strcpy (ptr2, "&lt;");
		 ptr2 += 4;
		 break;
	       case '>':
		 strcpy (ptr2, "&gt;");
		 ptr2 += 4;
		 break;
	       case '&':  /* &amp;  */
		 strcpy (ptr2, "&amp;");
		 ptr2 += 5;
		 break;
	       case '\'': /* &apos; */
		 strcpy (ptr2, "&apos;");
		 ptr2 += 6;
		 break;
	       case '"':  /* &quot; */
		 strcpy (ptr2, "&quot;");
		 ptr2 += 6;
		 break;
	       case '-':  /* &#x2d; */
		 strcpy (ptr2, "&#x2d;");
		 ptr2 += 6;
		 break;
	       default:
		 *ptr2++ = *ptr1;
		 break;
	       }
	     ++ptr1;
	   }
	 *ptr2 = 0;
       }
     return copy ? copy : itex2MML_empty_string;
   }

 /* Create a hex character reference string corresponding to code
  */
 char * itex2MML_character_reference (unsigned long int code)
   {
#define ENTITY_LENGTH 10
     char * entity = (char *) malloc(ENTITY_LENGTH);
     sprintf(entity, "&#x%05lx;", code);
     return entity;
   }

 void itex2MML_free_string (char * str)
   {
     if (str && str != itex2MML_empty_string)
       free(str);
   }


#line 353 "y.tab.c" /* yacc.c:337  */
# ifndef YY_NULLPTR
#  if defined __cplusplus
#   if 201103L <= __cplusplus
#    define YY_NULLPTR nullptr
#   else
#    define YY_NULLPTR 0
#   endif
#  else
#   define YY_NULLPTR ((void*)0)
#  endif
# endif

/* Enabling verbose error messages.  */
#ifdef YYERROR_VERBOSE
# undef YYERROR_VERBOSE
# define YYERROR_VERBOSE 1
#else
# define YYERROR_VERBOSE 0
#endif

/* In a future release of Bison, this section will be replaced
   by #include "y.tab.h".  */
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
typedef unsigned short yytype_uint16;
#endif

#ifdef YYTYPE_INT16
typedef YYTYPE_INT16 yytype_int16;
#else
typedef short yytype_int16;
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
#  define YYSIZE_T unsigned
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

/* Suppress unused-variable warnings by "using" E.  */
#if ! defined lint || defined __GNUC__
# define YYUSE(E) ((void) (E))
#else
# define YYUSE(E) /* empty */
#endif

#if defined __GNUC__ && ! defined __ICC && 407 <= __GNUC__ * 100 + __GNUC_MINOR__
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
#define YYFINAL  211
/* YYLAST -- Last index in YYTABLE.  */
#define YYLAST   5195

/* YYNTOKENS -- Number of terminals.  */
#define YYNTOKENS  175
/* YYNNTS -- Number of nonterminals.  */
#define YYNNTS  123
/* YYNRULES -- Number of rules.  */
#define YYNRULES  335
/* YYNSTATES -- Number of states.  */
#define YYNSTATES  594

#define YYUNDEFTOK  2
#define YYMAXUTOK   429

/* YYTRANSLATE(TOKEN-NUM) -- Symbol number corresponding to TOKEN-NUM
   as returned by yylex, with out-of-bounds checking.  */
#define YYTRANSLATE(YYX)                                                \
  ((unsigned) (YYX) <= YYMAXUTOK ? yytranslate[YYX] : YYUNDEFTOK)

/* YYTRANSLATE[TOKEN-NUM] -- Symbol number corresponding to TOKEN-NUM
   as returned by yylex.  */
static const yytype_uint8 yytranslate[] =
{
       0,     2,     2,     2,     2,     2,     2,     2,     2,     2,
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
      35,    36,    37,    38,    39,    40,    41,    42,    43,    44,
      45,    46,    47,    48,    49,    50,    51,    52,    53,    54,
      55,    56,    57,    58,    59,    60,    61,    62,    63,    64,
      65,    66,    67,    68,    69,    70,    71,    72,    73,    74,
      75,    76,    77,    78,    79,    80,    81,    82,    83,    84,
      85,    86,    87,    88,    89,    90,    91,    92,    93,    94,
      95,    96,    97,    98,    99,   100,   101,   102,   103,   104,
     105,   106,   107,   108,   109,   110,   111,   112,   113,   114,
     115,   116,   117,   118,   119,   120,   121,   122,   123,   124,
     125,   126,   127,   128,   129,   130,   131,   132,   133,   134,
     135,   136,   137,   138,   139,   140,   141,   142,   143,   144,
     145,   146,   147,   148,   149,   150,   151,   152,   153,   154,
     155,   156,   157,   158,   159,   160,   161,   162,   163,   164,
     165,   166,   167,   168,   169,   170,   171,   172,   173,   174
};

#if YYDEBUG
  /* YYRLINE[YYN] -- Source line where rule number YYN was defined.  */
static const yytype_uint16 yyrline[] =
{
       0,   287,   287,   290,   291,   292,   293,   294,   296,   298,
     299,   300,   316,   333,   337,   343,   362,   376,   395,   409,
     428,   442,   461,   475,   485,   495,   502,   509,   513,   517,
     522,   523,   524,   525,   526,   530,   534,   535,   536,   537,
     538,   539,   540,   541,   542,   543,   544,   545,   546,   547,
     548,   549,   550,   551,   552,   553,   554,   555,   556,   557,
     558,   559,   560,   561,   562,   563,   564,   565,   566,   567,
     568,   569,   570,   571,   572,   573,   574,   575,   576,   577,
     578,   579,   580,   581,   582,   583,   584,   585,   586,   587,
     588,   589,   590,   591,   592,   593,   594,   595,   596,   597,
     598,   599,   600,   601,   602,   603,   607,   611,   619,   620,
     621,   622,   624,   629,   634,   640,   644,   648,   653,   658,
     662,   666,   671,   675,   679,   684,   688,   692,   697,   701,
     705,   710,   715,   720,   725,   730,   735,   740,   746,   750,
     754,   758,   760,   766,   767,   773,   779,   780,   781,   786,
     791,   796,   800,   805,   809,   813,   817,   822,   827,   832,
     837,   842,   847,   853,   864,   872,   880,   887,   892,   900,
     908,   915,   923,   928,   933,   938,   943,   948,   953,   958,
     963,   968,   973,   978,   983,   988,   993,   998,  1003,  1007,
    1013,  1018,  1022,  1028,  1032,  1036,  1044,  1049,  1053,  1059,
    1064,  1069,  1074,  1078,  1084,  1089,  1093,  1097,  1101,  1105,
    1109,  1113,  1117,  1121,  1126,  1136,  1143,  1151,  1161,  1170,
    1178,  1182,  1188,  1193,  1197,  1201,  1206,  1213,  1221,  1226,
    1233,  1247,  1254,  1268,  1275,  1283,  1288,  1293,  1298,  1302,
    1307,  1311,  1316,  1320,  1324,  1328,  1332,  1337,  1342,  1347,
    1352,  1357,  1361,  1366,  1370,  1375,  1379,  1384,  1389,  1396,
    1404,  1417,  1430,  1440,  1452,  1461,  1471,  1478,  1486,  1493,
    1501,  1511,  1520,  1524,  1528,  1532,  1536,  1540,  1544,  1548,
    1552,  1556,  1560,  1564,  1574,  1581,  1585,  1589,  1594,  1599,
    1604,  1608,  1616,  1620,  1626,  1630,  1634,  1638,  1642,  1646,
    1650,  1654,  1658,  1662,  1667,  1672,  1677,  1682,  1687,  1692,
    1697,  1702,  1707,  1712,  1719,  1723,  1729,  1733,  1738,  1742,
    1748,  1756,  1760,  1766,  1770,  1775,  1778,  1782,  1790,  1794,
    1800,  1804,  1808,  1812,  1817,  1822
};
#endif

#if YYDEBUG || YYERROR_VERBOSE || 0
/* YYTNAME[SYMBOL-NUM] -- String name of the symbol SYMBOL-NUM.
   First, the terminals, then, starting at YYNTOKENS, nonterminals.  */
static const char *const yytname[] =
{
  "$end", "error", "$undefined", "TEXOVER", "TEXATOP", "CHAR",
  "STARTMATH", "STARTDMATH", "ENDMATH", "MI", "MIB", "MN", "MO", "SUP",
  "SUB", "MROWOPEN", "MROWCLOSE", "LEFT", "RIGHT", "BIG", "BBIG", "BIGG",
  "BBIGG", "BIGL", "BBIGL", "BIGGL", "BBIGGL", "FRAC", "TFRAC",
  "OPERATORNAME", "MATHOP", "MATHBIN", "MATHREL", "MOP", "MOL", "MOLL",
  "MOF", "MOR", "PERIODDELIM", "OTHERDELIM", "LEFTDELIM", "RIGHTDELIM",
  "MOS", "MOB", "SQRT", "ROOT", "BINOM", "TBINOM", "UNDER", "OVER",
  "OVERBRACE", "UNDERLINE", "UNDERBRACE", "UNDEROVER", "TENSOR", "MULTI",
  "ARRAYALIGN", "COLUMNALIGN", "ARRAY", "COLSEP", "ROWSEP", "ARRAYOPTS",
  "COLLAYOUT", "COLALIGN", "ROWALIGN", "ALIGN", "EQROWS", "EQCOLS",
  "ROWLINES", "COLLINES", "FRAME", "PADDING", "ATTRLIST", "ITALICS",
  "SANS", "TT", "BOLD", "BOXED", "SLASHED", "RM", "BB", "ST", "END",
  "BBLOWERCHAR", "BBUPPERCHAR", "BBDIGIT", "CALCHAR", "FRAKCHAR", "CAL",
  "SCR", "FRAK", "CLAP", "LLAP", "RLAP", "ROWOPTS", "TEXTSIZE", "SCSIZE",
  "SCSCSIZE", "DISPLAY", "TEXTSTY", "TEXTBOX", "TEXTSTRING", "XMLSTRING",
  "CELLOPTS", "ROWSPAN", "COLSPAN", "THINSPACE", "MEDSPACE", "THICKSPACE",
  "QUAD", "QQUAD", "NEGSPACE", "NEGMEDSPACE", "NEGTHICKSPACE", "PHANTOM",
  "HREF", "UNKNOWNCHAR", "EMPTYMROW", "STATLINE", "TOOLTIP", "TOGGLE",
  "TOGGLESTART", "TOGGLEEND", "FGHIGHLIGHT", "BGHIGHLIGHT", "SPACE",
  "INTONE", "INTTWO", "INTTHREE", "BAR", "WIDEBAR", "VEC", "WIDEVEC",
  "WIDELVEC", "WIDELRVEC", "WIDEUVEC", "WIDEULVEC", "WIDEULRVEC", "HAT",
  "WIDEHAT", "CHECK", "WIDECHECK", "TILDE", "WIDETILDE", "DOT", "DDOT",
  "DDDOT", "DDDDOT", "UNARYMINUS", "UNARYPLUS", "BEGINENV", "ENDENV",
  "MATRIX", "PMATRIX", "BMATRIX", "BBMATRIX", "VMATRIX", "VVMATRIX", "SVG",
  "ENDSVG", "SMALLMATRIX", "CASES", "ALIGNED", "GATHERED", "SUBSTACK",
  "PMOD", "RMCHAR", "COLOR", "BGCOLOR", "XARROW", "OPTARGOPEN",
  "OPTARGCLOSE", "ITEXNUM", "RAISEBOX", "NEG", "$accept", "doc",
  "xmlmmlTermList", "char", "expression", "compoundTermList",
  "compoundTerm", "closedTerm", "left", "right", "bigdelim",
  "unrecognized", "unaryminus", "unaryplus", "mi", "mib", "mn", "mob",
  "mo", "space", "statusline", "tooltip", "toggle", "fghighlight",
  "bghighlight", "color", "mathrlap", "mathllap", "mathclap", "textstring",
  "displaystyle", "textstyle", "textsize", "scriptsize",
  "scriptscriptsize", "italics", "sans", "mono", "slashed", "boxed",
  "bold", "roman", "rmchars", "bbold", "bbchars", "bbchar", "frak",
  "frakletters", "frakletter", "cal", "scr", "calletters", "calletter",
  "thinspace", "medspace", "thickspace", "quad", "qquad", "negspace",
  "negmedspace", "negthickspace", "phantom", "href", "tensor", "multi",
  "subsupList", "subsupTerm", "mfrac", "pmod", "texover", "texatop",
  "binom", "munderbrace", "munderline", "moverbrace", "bar", "vec", "lvec",
  "lrvec", "uvec", "ulvec", "ulrvec", "dot", "ddot", "dddot", "ddddot",
  "tilde", "check", "hat", "msqrt", "mroot", "raisebox", "munder", "mover",
  "munderover", "emptymrow", "mathenv", "columnAlignList", "substack",
  "array", "arrayopts", "anarrayopt", "collayout", "colalign", "rowalign",
  "align", "eqrows", "eqcols", "rowlines", "collines", "frame", "padding",
  "tableRowList", "tableRow", "simpleTableRow", "optsTableRow", "rowopts",
  "arowopt", "tableCell", "cellopts", "acellopt", "rowspan", "colspan", YY_NULLPTR
};
#endif

# ifdef YYPRINT
/* YYTOKNUM[NUM] -- (External) token number corresponding to the
   (internal) symbol number NUM (which must be that of a token).  */
static const yytype_uint16 yytoknum[] =
{
       0,   256,   257,   258,   259,   260,   261,   262,   263,   264,
     265,   266,   267,   268,   269,   270,   271,   272,   273,   274,
     275,   276,   277,   278,   279,   280,   281,   282,   283,   284,
     285,   286,   287,   288,   289,   290,   291,   292,   293,   294,
     295,   296,   297,   298,   299,   300,   301,   302,   303,   304,
     305,   306,   307,   308,   309,   310,   311,   312,   313,   314,
     315,   316,   317,   318,   319,   320,   321,   322,   323,   324,
     325,   326,   327,   328,   329,   330,   331,   332,   333,   334,
     335,   336,   337,   338,   339,   340,   341,   342,   343,   344,
     345,   346,   347,   348,   349,   350,   351,   352,   353,   354,
     355,   356,   357,   358,   359,   360,   361,   362,   363,   364,
     365,   366,   367,   368,   369,   370,   371,   372,   373,   374,
     375,   376,   377,   378,   379,   380,   381,   382,   383,   384,
     385,   386,   387,   388,   389,   390,   391,   392,   393,   394,
     395,   396,   397,   398,   399,   400,   401,   402,   403,   404,
     405,   406,   407,   408,   409,   410,   411,   412,   413,   414,
     415,   416,   417,   418,   419,   420,   421,   422,   423,   424,
     425,   426,   427,   428,   429
};
# endif

#define YYPACT_NINF -387

#define yypact_value_is_default(Yystate) \
  (!!((Yystate) == (-387)))

#define YYTABLE_NINF -1

#define yytable_value_is_error(Yytable_value) \
  0

  /* YYPACT[STATE-NUM] -- Index in YYTABLE of the portion describing
     STATE-NUM.  */
static const yytype_int16 yypact[] =
{
     142,  -387,  1389,  1555,    37,   142,  -387,  -387,  -387,  -387,
    -387,  -387,  -387,  4857,  4857,  3537,   129,   160,   166,   170,
     173,    50,   163,   186,   188,  4857,  4857,   -56,   -41,   -29,
     -20,  -387,  -387,  -387,  -387,  -387,  -387,  -387,  -387,  -387,
    -387,  -387,  3702,  4857,  4857,  4857,  4857,  4857,  4857,  4857,
    4857,  4857,  4857,   -10,    41,  4857,  4857,  4857,  4857,  4857,
    4857,    46,    48,    77,    84,    93,  4857,  4857,  4857,  3537,
    3537,  3537,  3537,  3537,    79,  -387,  -387,  -387,  -387,  -387,
    -387,  -387,  -387,  4857,    81,  -387,  -387,    97,   114,  4857,
    3537,    25,    32,    95,  4857,  4857,  4857,  4857,  4857,  4857,
    4857,  4857,  4857,  4857,  4857,  4857,  4857,  4857,  4857,  4857,
    4857,  4857,  4857,  -387,  -387,    -1,   103,  4857,  -387,   148,
     174,  3867,   147,   -91,  1721,  -387,   216,  3537,  -387,  -387,
    -387,  -387,  -387,   218,  -387,   220,  -387,  -387,  -387,  -387,
    -387,  -387,  -387,  -387,  -387,  -387,  -387,  -387,  -387,  -387,
    -387,  -387,  -387,  -387,  -387,  -387,  -387,  -387,  -387,  -387,
      83,  -387,  -387,  -387,  -387,  -387,  -387,  -387,  -387,  -387,
    -387,  -387,  -387,  -387,  -387,  -387,  -387,  -387,  -387,  -387,
    -387,  -387,  -387,  -387,  -387,  -387,  -387,  -387,  -387,  -387,
    -387,  -387,  -387,  -387,  -387,  -387,  -387,  -387,  -387,  -387,
    -387,  -387,  -387,  -387,  -387,  -387,  -387,  -387,  -387,  -387,
    1887,  -387,  -387,  -387,  -387,  -387,  -387,  -387,  1056,   110,
    -387,  -387,  -387,  -387,  -387,  -387,  -387,  -387,  -387,  -387,
    -387,  -387,  -387,  -387,  -387,  -387,  -387,  -387,  -387,  -387,
    -387,  -387,  -387,  4857,  4857,  -387,  -387,  -387,  -387,  3537,
    -387,  4857,  4857,  4857,  4857,  4857,  -387,  -387,  -387,  4857,
     204,   222,  4857,  2052,  -387,  -387,  -387,  -387,  -387,  -387,
      85,   139,   164,   164,   167,  -387,  -387,  -387,  3537,  3537,
    3537,  3537,  3537,  -387,  -387,  4857,  4857,  4857,  4857,  2382,
    4857,  4857,   126,  -387,  -387,  -387,  -387,  -387,  -387,  -387,
    -387,  -387,  -387,  -387,  -387,  -387,  -387,  -387,  -387,  -387,
    -387,  -387,   -26,  2217,  2217,  2217,  2217,  2217,  2217,   -86,
    2217,  2217,  2217,  2217,  2217,  -387,  3537,  3537,  3537,  -387,
    -387,  4032,   152,  -387,  -387,  4857,  4857,  1223,  4857,  4857,
    4857,  4857,  -387,  -387,  3537,  3537,  -387,  -387,  -387,  -387,
    2547,  -387,  -387,  -387,  -387,  -387,  4857,  4857,  4197,   222,
     222,  -387,   119,   241,   242,   244,   245,  3537,     3,  -387,
     203,  -387,  -387,   -47,  -387,  -387,  -387,     2,  -387,  -387,
     -24,  -387,    -4,  -387,   -55,  -387,  -387,  -387,  -387,  -387,
    -387,  -387,  -387,   187,   182,   213,   -53,   -52,   -51,   -49,
     -48,   -46,   112,  -387,   -45,   -42,   -40,   -39,     6,  3537,
    3537,  2712,  4362,  -387,  4527,   259,   261,  3537,  3537,   125,
    -387,   267,   269,   270,   272,  2877,  3042,  4857,  -387,  -387,
    4857,   273,   159,  -387,  4857,   222,   122,   179,    16,  -387,
    2217,  3207,  -387,  -387,  -387,  -387,  -387,  -387,  -387,  -387,
     202,   213,  -387,   -23,   136,   137,   135,   143,   138,   134,
    -387,   140,   144,   141,   145,  -387,  5022,  4857,  -387,  4692,
    -387,  4857,  4857,  3372,  3372,  -387,  -387,  -387,  4857,  4857,
    4857,  4857,  -387,  -387,  -387,  -387,  4857,  -387,    -9,   165,
     225,   227,   229,   232,   234,   235,   237,   238,   255,   256,
      75,  -387,  -387,  -387,  -387,  -387,  -387,  -387,  -387,  -387,
    -387,  -387,  -387,  -387,     1,  -387,   257,   258,  -387,  -387,
      12,  -387,  -387,  -387,  -387,  -387,   190,   -21,  -387,  2217,
    -387,  -387,  -387,  -387,  -387,  -387,  -387,  -387,  -387,  -387,
    -387,  -387,  -387,  4857,  -387,  -387,  -387,  -387,  -387,  -387,
    -387,  -387,  -387,  -387,   222,  -387,  -387,  -387,  -387,  -387,
    -387,  -387,  -387,  -387,  -387,  -387,  -387,  2217,  -387,  3207,
    -387,  -387,  -387,  3537,  -387,   249,  2217,   -37,  -387,   181,
      17,   203,  3537,   251,   -36,   275,  -387,  -387,   206,   279,
    -387,   262,  -387,  -387
};

  /* YYDEFACT[STATE-NUM] -- Default reduction number in state STATE-NUM.
     Performed when YYTABLE does not specify something else to do.  Zero
     means the default is an error.  */
static const yytype_uint16 yydefact[] =
{
       3,     8,     0,     0,     0,     2,     4,     5,     9,   141,
     142,   143,   148,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,   157,   149,   150,   154,   158,   155,   153,   152,   151,
     156,   145,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,   205,   206,   207,   208,   209,
     210,   211,   212,     0,     0,   138,   272,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,   139,   140,     0,     0,     0,   188,     0,
       0,     0,     0,     0,     0,    13,    29,     0,   147,   111,
      31,    32,    34,    33,    35,   146,    36,    85,    97,    98,
      99,   100,   101,   102,    67,    66,    65,    86,    68,    69,
      70,    71,    72,    73,    74,    75,    81,    82,    76,    77,
      78,    79,    80,    83,    84,    87,    88,    89,    90,    91,
      92,    93,    94,    95,    96,    37,    38,    39,   110,   103,
     104,    40,    61,    62,    60,    46,    47,    48,    49,    50,
      51,    52,    54,    55,    56,    57,    59,    58,    53,    41,
      42,    43,    44,    45,    63,    64,   108,   109,    30,    10,
       0,     1,     6,     7,    28,    33,   146,    27,     0,    29,
     114,   113,   112,   120,   118,   119,   123,   121,   122,   126,
     124,   125,   129,   127,   128,   131,   130,   133,   132,   135,
     134,   137,   136,     0,     0,   159,   160,   161,   162,     0,
     257,     0,     0,     0,     0,     0,   237,   236,   235,     0,
       0,     0,     0,   325,   181,   182,   183,   186,   185,   184,
       0,     0,     0,     0,     0,   174,   173,   172,   178,   179,
     180,   176,   177,   175,   213,     0,     0,     0,     0,     0,
       0,     0,     0,   238,   239,   240,   241,   242,   243,   244,
     245,   246,   255,   256,   253,   254,   251,   252,   247,   248,
     249,   250,     0,   325,   325,   325,   325,   325,   325,     0,
     325,   325,   325,   325,   325,   228,     0,     0,     0,   268,
     144,     0,     0,    11,    14,     0,     0,     0,     0,     0,
       0,     0,   189,    12,     0,     0,   106,   105,   226,   227,
       0,   259,   233,   234,   267,   269,     0,     0,     0,     0,
     216,   220,     0,     0,     0,     0,     0,   326,     0,   314,
     316,   317,   318,     0,   193,   194,   195,     0,   191,   204,
       0,   202,     0,   199,     0,   197,   214,   164,   165,   166,
     167,   168,   169,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,   286,     0,     0,     0,     0,     0,   170,
     171,     0,     0,   264,     0,    26,    25,     0,     0,     0,
     107,    22,    20,    18,    16,     0,     0,     0,   271,   224,
       0,   223,     0,   221,     0,     0,     0,     0,     0,   290,
     325,   325,   187,   190,   192,   200,   203,   201,   196,   198,
       0,     0,   288,     0,     0,     0,     0,     0,     0,     0,
     285,     0,     0,     0,     0,   289,     0,     0,   262,     0,
     265,     0,     0,     0,     0,   117,   116,   115,     0,     0,
       0,     0,   229,   231,   258,   225,     0,   215,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,   292,   294,   295,   296,   297,   298,   299,   300,   301,
     302,   303,   323,   324,     0,   321,     0,     0,   330,   331,
       0,   328,   332,   333,   315,   319,     0,     0,   287,   325,
     273,   275,   276,   278,   277,   279,   280,   281,   282,   274,
     266,   270,   260,     0,   263,    24,    23,   230,   232,    21,
      19,    17,    15,   222,     0,   218,   219,   304,   305,   306,
     307,   308,   309,   310,   311,   312,   313,   325,   293,   325,
     322,   334,   335,     0,   329,     0,   325,     0,   261,     0,
       0,   320,   327,     0,     0,     0,   217,   291,     0,     0,
     284,     0,   283,   163
};

  /* YYPGOTO[NTERM-NUM].  */
static const yytype_int16 yypgoto[] =
{
    -387,  -387,  -387,   333,   334,    23,   -14,   577,  -387,  -229,
    -387,  -387,  -387,  -387,  -387,    -2,  -387,   168,  -387,  -387,
    -387,  -387,  -387,  -387,  -387,  -387,  -387,  -387,  -387,  -387,
    -387,  -387,  -387,  -387,  -387,  -387,  -387,  -387,  -387,  -387,
    -387,  -387,    70,  -387,  -387,   -32,  -387,  -387,   -43,  -387,
    -387,    73,  -351,  -387,  -387,  -387,  -387,  -387,  -387,  -387,
    -387,  -387,  -387,  -387,  -387,  -258,  -358,  -387,  -387,  -387,
    -387,  -387,  -387,  -387,  -387,  -387,  -387,  -387,  -387,  -387,
    -387,  -387,  -387,  -387,  -387,  -387,  -387,  -387,  -387,  -387,
    -387,  -387,  -387,  -387,  -387,  -387,  -387,  -104,  -387,  -387,
    -387,  -148,  -387,  -386,  -384,  -387,  -387,  -387,  -387,  -387,
    -387,  -387,  -274,   -85,  -215,  -387,  -387,  -158,   -84,  -387,
    -162,  -387,  -387
};

  /* YYDEFGOTO[NTERM-NUM].  */
static const yytype_int16 yydefgoto[] =
{
      -1,     4,     5,     6,     7,   367,   125,   126,   127,   420,
     128,   129,   130,   131,   132,   215,   134,   216,   136,   137,
     138,   139,   140,   141,   142,   143,   144,   145,   146,   147,
     148,   149,   150,   151,   152,   153,   154,   155,   156,   157,
     158,   159,   160,   161,   377,   378,   162,   384,   385,   163,
     164,   380,   381,   165,   166,   167,   168,   169,   170,   171,
     172,   173,   174,   175,   176,   360,   361,   177,   178,   179,
     180,   181,   182,   183,   184,   185,   186,   187,   188,   189,
     190,   191,   192,   193,   194,   195,   196,   197,   198,   199,
     200,   201,   202,   203,   204,   205,   206,   453,   207,   208,
     500,   501,   502,   503,   504,   505,   506,   507,   508,   509,
     510,   511,   368,   369,   370,   371,   514,   515,   372,   520,
     521,   522,   523
};

  /* YYTABLE[YYPACT[STATE-NUM]] -- What to do in state STATE-NUM.  If
     positive, shift that token.  If negative, reduce the rule whose
     number is the opposite.  If YYTABLE_NINF, syntax error.  */
static const yytype_uint16 yytable[] =
{
     133,   133,   433,   362,   433,   261,   554,   440,   440,   440,
     331,   440,   440,   133,   440,   440,   402,   569,   440,   439,
     440,   440,   465,   440,   440,   124,   210,   448,   573,   446,
     394,   446,   383,   587,   528,   442,   528,   211,   218,   396,
     397,   398,   399,   400,   401,   245,   404,   405,   406,   407,
     408,   512,   518,   513,   519,   395,   263,   312,   445,   529,
     246,   576,   379,   440,   491,   492,   440,   133,   133,   133,
     133,   133,   247,   403,   433,   491,   492,   440,   447,   491,
     492,   248,   379,   332,   443,   374,   375,   376,   133,   235,
     236,   567,   278,   279,   280,   281,   282,   290,   454,   455,
     456,   432,   457,   458,   291,   459,   461,   262,   555,   462,
     334,   463,   464,   289,   585,   589,   516,   517,   324,   342,
     516,   517,   133,   335,   336,   133,   347,   270,   512,   271,
     513,   433,   357,   358,   518,   434,   519,   490,   491,   492,
     493,   494,   495,   496,   497,   498,   499,     1,     2,     3,
     337,   313,   314,   315,   316,   317,   318,   319,   272,   320,
     321,   322,   323,   475,   476,   273,   477,   220,   221,   222,
     135,   135,   357,   358,   274,   487,   292,   489,   357,   358,
     283,   556,   285,   135,   490,   491,   492,   493,   494,   495,
     496,   497,   498,   499,   357,   358,   334,   586,   286,   223,
     224,   225,   237,   238,   334,   226,   227,   228,   133,   229,
     230,   231,   232,   233,   234,   287,   133,   357,   358,   359,
     326,   433,   374,   375,   376,   239,   240,   241,   242,   335,
     336,   338,   339,   340,   341,   357,   358,   135,   135,   135,
     135,   135,   491,   492,   547,   548,   327,   133,   330,   342,
     379,   118,   393,   414,   383,   577,   435,   436,   135,   437,
     438,   133,   441,   451,   334,   334,   334,   334,   334,   450,
     452,   460,   350,   471,   472,   334,   133,   133,   133,   133,
     133,   478,   479,   526,   480,   481,   486,   133,   530,   532,
     531,   535,   135,   580,   534,   135,   579,   557,   533,   558,
     536,   559,   584,   538,   560,   537,   561,   562,   539,   563,
     564,   133,   133,   133,   133,   133,   133,   575,   133,   133,
     133,   133,   133,   334,   133,   133,   133,   565,   566,   571,
     572,   583,   588,   590,   591,   133,   334,   592,   212,   213,
     373,   449,   133,   133,   593,   444,   382,   527,   133,   409,
     410,   411,   568,   334,   581,   524,   570,   525,   574,     0,
       0,     0,     0,     0,     0,   133,     0,   425,   426,     0,
       0,     0,     0,     0,     0,     0,     0,     0,   135,     0,
       0,     0,     0,     0,     0,     0,   135,     0,     0,     0,
       0,     0,     0,     0,     0,   334,   334,   334,     0,     0,
       0,     0,     0,     0,     0,     0,     0,   133,   133,   133,
       0,   334,   334,     0,     0,   133,   133,   135,     0,     0,
       0,     0,     0,   133,   133,     0,     0,     0,     0,     0,
       0,   135,     0,     0,     0,     0,     0,     0,   133,   133,
     473,   474,     0,     0,     0,     0,   135,   135,   135,   135,
     135,     0,     0,     0,     0,     0,     0,   135,     0,   334,
     334,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,   133,   133,     0,     0,     0,     0,     0,     0,     0,
       0,   135,   135,   135,   135,   135,   135,     0,   135,   135,
     135,   135,   135,     0,   135,   135,   135,     0,     0,     0,
       0,     0,     0,     0,     0,   135,     0,     0,     0,     0,
       0,     0,   135,   135,     0,     0,     0,     0,   135,     0,
       0,     0,     0,     0,     0,     0,     0,   133,     0,     0,
       0,     0,     0,     0,     0,   135,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,   133,     0,   133,   334,     0,
       0,   133,     0,     0,   133,     0,     0,   135,   135,   135,
     133,     0,     0,     0,     0,   135,   135,     0,     0,     0,
     214,   217,   219,   135,   135,     0,   582,     0,     0,     0,
       0,     0,   243,   244,     0,     0,     0,     0,   135,   135,
       0,     0,     0,     0,     0,     0,     0,     0,     0,   250,
     251,   252,   253,   254,   255,   256,   257,   258,   259,   260,
       0,     0,   264,   265,   266,   267,   268,   269,     0,     0,
       0,   135,   135,   275,   276,   277,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     284,     0,     0,     0,     0,     0,   288,     0,     0,     0,
       0,   293,   294,   295,   296,   297,   298,   299,   300,   301,
     302,   303,   304,   305,   306,   307,   308,   309,   310,   311,
       0,     0,     0,     0,   325,     0,     0,   135,   329,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,   135,     0,   135,     0,     0,
       0,   135,     0,     0,   135,     0,     0,     0,     0,     0,
     135,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     348,   349,     0,     0,     0,     0,     0,     0,   351,   352,
     353,   354,   355,     0,     0,     0,   356,     0,     0,   363,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,   386,   387,   388,   389,     0,   391,   392,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,   413,     0,
       0,     0,   415,   416,     0,   421,   422,   423,   424,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,   428,   429,   431,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,   468,
       0,   470,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,   484,     0,     0,   485,     0,     0,
       0,   488,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,   541,   542,     0,   544,     0,   545,   546,
       0,     0,     0,     0,     0,   549,   550,   551,   552,   344,
     345,     0,     0,   553,     0,     9,    10,    11,    12,    13,
      14,    15,   346,    16,     0,    17,    18,    19,    20,    21,
      22,    23,    24,    25,    26,    27,    28,    29,    30,    31,
      32,    33,    34,    35,    36,    37,    38,    39,    40,    41,
      42,    43,    44,    45,    46,    47,    48,    49,    50,    51,
      52,    53,     0,     0,    54,     0,     0,     0,     0,     0,
     578,     0,     0,     0,     0,     0,     0,     0,     0,    55,
      56,    57,    58,    59,    60,    61,    62,     0,     0,     0,
       0,     0,     0,     0,    63,    64,    65,    66,    67,    68,
       0,    69,    70,    71,    72,    73,    74,     0,     0,     0,
       0,     0,    75,    76,    77,    78,    79,    80,    81,    82,
      83,    84,    85,    86,    87,    88,    89,    90,     0,    91,
      92,    93,     0,     0,     0,    94,    95,    96,    97,    98,
      99,   100,   101,   102,   103,   104,   105,   106,   107,   108,
     109,   110,   111,   112,   113,   114,   115,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
     116,   117,   118,   119,   120,   121,   417,   418,   122,   123,
       0,     0,     9,    10,    11,    12,    13,    14,    15,     0,
      16,   419,    17,    18,    19,    20,    21,    22,    23,    24,
      25,    26,    27,    28,    29,    30,    31,    32,    33,    34,
      35,    36,    37,    38,    39,    40,    41,    42,    43,    44,
      45,    46,    47,    48,    49,    50,    51,    52,    53,     0,
       0,    54,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,    55,    56,    57,    58,
      59,    60,    61,    62,     0,     0,     0,     0,     0,     0,
       0,    63,    64,    65,    66,    67,    68,     0,    69,    70,
      71,    72,    73,    74,     0,     0,     0,     0,     0,    75,
      76,    77,    78,    79,    80,    81,    82,    83,    84,    85,
      86,    87,    88,    89,    90,     0,    91,    92,    93,     0,
       0,     0,    94,    95,    96,    97,    98,    99,   100,   101,
     102,   103,   104,   105,   106,   107,   108,   109,   110,   111,
     112,   113,   114,   115,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,   116,   117,   118,
     119,   120,   121,     0,     0,   122,   123,     8,     9,    10,
      11,    12,    13,    14,    15,     0,    16,     0,    17,    18,
      19,    20,    21,    22,    23,    24,    25,    26,    27,    28,
      29,    30,    31,    32,    33,    34,    35,    36,    37,    38,
      39,    40,    41,    42,    43,    44,    45,    46,    47,    48,
      49,    50,    51,    52,    53,     0,     0,    54,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,    55,    56,    57,    58,    59,    60,    61,    62,
       0,     0,     0,     0,     0,     0,     0,    63,    64,    65,
      66,    67,    68,     0,    69,    70,    71,    72,    73,    74,
       0,     0,     0,     0,     0,    75,    76,    77,    78,    79,
      80,    81,    82,    83,    84,    85,    86,    87,    88,    89,
      90,     0,    91,    92,    93,     0,     0,     0,    94,    95,
      96,    97,    98,    99,   100,   101,   102,   103,   104,   105,
     106,   107,   108,   109,   110,   111,   112,   113,   114,   115,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,   116,   117,   118,   119,   120,   121,     0,
       0,   122,   123,   209,     9,    10,    11,    12,    13,    14,
      15,     0,    16,     0,    17,    18,    19,    20,    21,    22,
      23,    24,    25,    26,    27,    28,    29,    30,    31,    32,
      33,    34,    35,    36,    37,    38,    39,    40,    41,    42,
      43,    44,    45,    46,    47,    48,    49,    50,    51,    52,
      53,     0,     0,    54,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,    55,    56,
      57,    58,    59,    60,    61,    62,     0,     0,     0,     0,
       0,     0,     0,    63,    64,    65,    66,    67,    68,     0,
      69,    70,    71,    72,    73,    74,     0,     0,     0,     0,
       0,    75,    76,    77,    78,    79,    80,    81,    82,    83,
      84,    85,    86,    87,    88,    89,    90,     0,    91,    92,
      93,     0,     0,     0,    94,    95,    96,    97,    98,    99,
     100,   101,   102,   103,   104,   105,   106,   107,   108,   109,
     110,   111,   112,   113,   114,   115,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,   116,
     117,   118,   119,   120,   121,     0,     0,   122,   123,   333,
       9,    10,    11,    12,    13,    14,    15,     0,    16,     0,
      17,    18,    19,    20,    21,    22,    23,    24,    25,    26,
      27,    28,    29,    30,    31,    32,    33,    34,    35,    36,
      37,    38,    39,    40,    41,    42,    43,    44,    45,    46,
      47,    48,    49,    50,    51,    52,    53,     0,     0,    54,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,    55,    56,    57,    58,    59,    60,
      61,    62,     0,     0,     0,     0,     0,     0,     0,    63,
      64,    65,    66,    67,    68,     0,    69,    70,    71,    72,
      73,    74,     0,     0,     0,     0,     0,    75,    76,    77,
      78,    79,    80,    81,    82,    83,    84,    85,    86,    87,
      88,    89,    90,     0,    91,    92,    93,     0,     0,     0,
      94,    95,    96,    97,    98,    99,   100,   101,   102,   103,
     104,   105,   106,   107,   108,   109,   110,   111,   112,   113,
     114,   115,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,   116,   117,   118,   119,   120,
     121,     0,     0,   122,   123,   343,     9,    10,    11,    12,
      13,    14,    15,     0,    16,     0,    17,    18,    19,    20,
      21,    22,    23,    24,    25,    26,    27,    28,    29,    30,
      31,    32,    33,    34,    35,    36,    37,    38,    39,    40,
      41,    42,    43,    44,    45,    46,    47,    48,    49,    50,
      51,    52,    53,     0,     0,    54,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
      55,    56,    57,    58,    59,    60,    61,    62,     0,     0,
       0,     0,     0,     0,     0,    63,    64,    65,    66,    67,
      68,     0,    69,    70,    71,    72,    73,    74,     0,     0,
       0,     0,     0,    75,    76,    77,    78,    79,    80,    81,
      82,    83,    84,    85,    86,    87,    88,    89,    90,     0,
      91,    92,    93,     0,     0,     0,    94,    95,    96,    97,
      98,    99,   100,   101,   102,   103,   104,   105,   106,   107,
     108,   109,   110,   111,   112,   113,   114,   115,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,   116,   117,   118,   119,   120,   121,     0,     0,   122,
     123,     9,    10,    11,    12,    13,    14,    15,     0,    16,
       0,    17,    18,    19,    20,    21,    22,    23,    24,    25,
      26,    27,    28,    29,    30,    31,    32,    33,    34,    35,
      36,    37,    38,    39,    40,    41,    42,    43,    44,    45,
      46,    47,    48,    49,    50,    51,    52,    53,     0,     0,
      54,     0,     0,   364,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,    55,    56,    57,    58,    59,
      60,    61,    62,     0,     0,     0,     0,     0,     0,     0,
      63,    64,    65,    66,    67,    68,   365,    69,    70,    71,
      72,    73,    74,     0,     0,   366,     0,     0,    75,    76,
      77,    78,    79,    80,    81,    82,    83,    84,    85,    86,
      87,    88,    89,    90,     0,    91,    92,    93,     0,     0,
       0,    94,    95,    96,    97,    98,    99,   100,   101,   102,
     103,   104,   105,   106,   107,   108,   109,   110,   111,   112,
     113,   114,   115,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,   116,   117,   118,   119,
     120,   121,     0,     0,   122,   123,     9,    10,    11,    12,
      13,    14,    15,     0,    16,     0,    17,    18,    19,    20,
      21,    22,    23,    24,    25,    26,    27,    28,    29,    30,
      31,    32,    33,    34,    35,    36,    37,    38,    39,    40,
      41,    42,    43,    44,    45,    46,    47,    48,    49,    50,
      51,    52,    53,     0,     0,    54,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
      55,    56,    57,    58,    59,    60,    61,    62,     0,     0,
       0,     0,     0,     0,     0,    63,    64,    65,    66,    67,
      68,   365,    69,    70,    71,    72,    73,    74,     0,     0,
     366,     0,     0,    75,    76,    77,    78,    79,    80,    81,
      82,    83,    84,    85,    86,    87,    88,    89,    90,     0,
      91,    92,    93,     0,     0,     0,    94,    95,    96,    97,
      98,    99,   100,   101,   102,   103,   104,   105,   106,   107,
     108,   109,   110,   111,   112,   113,   114,   115,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,   116,   117,   118,   119,   120,   121,     0,     0,   122,
     123,     9,    10,    11,    12,    13,    14,    15,     0,    16,
       0,    17,    18,    19,    20,    21,    22,    23,    24,    25,
      26,    27,    28,    29,    30,    31,    32,    33,    34,    35,
      36,    37,    38,    39,    40,    41,    42,    43,    44,    45,
      46,    47,    48,    49,    50,    51,    52,    53,     0,     0,
      54,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,    55,    56,    57,    58,    59,
      60,    61,    62,     0,     0,     0,     0,     0,     0,     0,
      63,    64,    65,    66,    67,    68,     0,    69,    70,    71,
      72,    73,    74,     0,     0,     0,     0,     0,    75,    76,
      77,    78,    79,    80,    81,    82,    83,    84,    85,    86,
      87,    88,    89,    90,   390,    91,    92,    93,     0,     0,
       0,    94,    95,    96,    97,    98,    99,   100,   101,   102,
     103,   104,   105,   106,   107,   108,   109,   110,   111,   112,
     113,   114,   115,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,   116,   117,   118,   119,
     120,   121,     0,     0,   122,   123,     9,    10,    11,    12,
      13,    14,    15,     0,    16,     0,    17,    18,    19,    20,
      21,    22,    23,    24,    25,    26,    27,    28,    29,    30,
      31,    32,    33,    34,    35,    36,    37,    38,    39,    40,
      41,    42,    43,    44,    45,    46,    47,    48,    49,    50,
      51,    52,    53,     0,     0,    54,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
      55,    56,    57,    58,    59,    60,    61,    62,     0,     0,
       0,     0,     0,     0,     0,    63,    64,    65,    66,    67,
      68,     0,    69,    70,    71,    72,    73,    74,     0,     0,
       0,     0,     0,    75,    76,    77,    78,    79,    80,    81,
      82,    83,    84,    85,    86,    87,    88,    89,    90,     0,
      91,    92,    93,     0,     0,     0,    94,    95,    96,    97,
      98,    99,   100,   101,   102,   103,   104,   105,   106,   107,
     108,   109,   110,   111,   112,   113,   114,   115,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,   116,   117,   118,   119,   120,   121,     0,   427,   122,
     123,     9,    10,    11,    12,    13,    14,    15,     0,    16,
       0,    17,    18,    19,    20,    21,    22,    23,    24,    25,
      26,    27,    28,    29,    30,    31,    32,    33,    34,    35,
      36,    37,    38,    39,    40,    41,    42,    43,    44,    45,
      46,    47,    48,    49,    50,    51,    52,    53,     0,     0,
      54,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,    55,    56,    57,    58,    59,
      60,    61,    62,     0,     0,     0,     0,     0,     0,     0,
      63,    64,    65,    66,    67,    68,     0,    69,    70,    71,
      72,    73,    74,     0,     0,     0,     0,     0,    75,    76,
      77,    78,    79,    80,    81,    82,    83,    84,    85,    86,
      87,    88,    89,    90,     0,    91,    92,    93,     0,     0,
       0,    94,    95,    96,    97,    98,    99,   100,   101,   102,
     103,   104,   105,   106,   107,   108,   109,   110,   111,   112,
     113,   114,   115,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,   116,   117,   118,   119,
     120,   121,     0,   466,   122,   123,     9,    10,    11,    12,
      13,    14,    15,   482,    16,     0,    17,    18,    19,    20,
      21,    22,    23,    24,    25,    26,    27,    28,    29,    30,
      31,    32,    33,    34,    35,    36,    37,    38,    39,    40,
      41,    42,    43,    44,    45,    46,    47,    48,    49,    50,
      51,    52,    53,     0,     0,    54,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
      55,    56,    57,    58,    59,    60,    61,    62,     0,     0,
       0,     0,     0,     0,     0,    63,    64,    65,    66,    67,
      68,     0,    69,    70,    71,    72,    73,    74,     0,     0,
       0,     0,     0,    75,    76,    77,    78,    79,    80,    81,
      82,    83,    84,    85,    86,    87,    88,    89,    90,     0,
      91,    92,    93,     0,     0,     0,    94,    95,    96,    97,
      98,    99,   100,   101,   102,   103,   104,   105,   106,   107,
     108,   109,   110,   111,   112,   113,   114,   115,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,   116,   117,   118,   119,   120,   121,     0,     0,   122,
     123,     9,    10,    11,    12,    13,    14,    15,   483,    16,
       0,    17,    18,    19,    20,    21,    22,    23,    24,    25,
      26,    27,    28,    29,    30,    31,    32,    33,    34,    35,
      36,    37,    38,    39,    40,    41,    42,    43,    44,    45,
      46,    47,    48,    49,    50,    51,    52,    53,     0,     0,
      54,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,    55,    56,    57,    58,    59,
      60,    61,    62,     0,     0,     0,     0,     0,     0,     0,
      63,    64,    65,    66,    67,    68,     0,    69,    70,    71,
      72,    73,    74,     0,     0,     0,     0,     0,    75,    76,
      77,    78,    79,    80,    81,    82,    83,    84,    85,    86,
      87,    88,    89,    90,     0,    91,    92,    93,     0,     0,
       0,    94,    95,    96,    97,    98,    99,   100,   101,   102,
     103,   104,   105,   106,   107,   108,   109,   110,   111,   112,
     113,   114,   115,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,   116,   117,   118,   119,
     120,   121,     0,     0,   122,   123,     9,    10,    11,    12,
      13,    14,    15,     0,    16,     0,    17,    18,    19,    20,
      21,    22,    23,    24,    25,    26,    27,    28,    29,    30,
      31,    32,    33,    34,    35,    36,    37,    38,    39,    40,
      41,    42,    43,    44,    45,    46,    47,    48,    49,    50,
      51,    52,    53,     0,     0,    54,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
      55,    56,    57,    58,    59,    60,    61,    62,     0,     0,
       0,     0,     0,     0,     0,    63,    64,    65,    66,    67,
      68,     0,    69,    70,    71,    72,    73,    74,     0,     0,
     366,     0,     0,    75,    76,    77,    78,    79,    80,    81,
      82,    83,    84,    85,    86,    87,    88,    89,    90,     0,
      91,    92,    93,     0,     0,     0,    94,    95,    96,    97,
      98,    99,   100,   101,   102,   103,   104,   105,   106,   107,
     108,   109,   110,   111,   112,   113,   114,   115,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,   116,   117,   118,   119,   120,   121,     0,     0,   122,
     123,     9,    10,    11,    12,    13,    14,    15,     0,    16,
     419,    17,    18,    19,    20,    21,    22,    23,    24,    25,
      26,    27,    28,    29,    30,    31,    32,    33,    34,    35,
      36,    37,    38,    39,    40,    41,    42,    43,    44,    45,
      46,    47,    48,    49,    50,    51,    52,    53,     0,     0,
      54,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,    55,    56,    57,    58,    59,
      60,    61,    62,     0,     0,     0,     0,     0,     0,     0,
      63,    64,    65,    66,    67,    68,     0,    69,    70,    71,
      72,    73,    74,     0,     0,     0,     0,     0,    75,    76,
      77,    78,    79,    80,    81,    82,    83,    84,    85,    86,
      87,    88,    89,    90,     0,    91,    92,    93,     0,     0,
       0,    94,    95,    96,    97,    98,    99,   100,   101,   102,
     103,   104,   105,   106,   107,   108,   109,   110,   111,   112,
     113,   114,   115,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,   116,   117,   118,   119,
     120,   121,     0,     0,   122,   123,     9,    10,    11,    12,
      13,    14,    15,     0,    16,     0,    17,    18,    19,    20,
      21,    22,    23,    24,    25,    26,    27,    28,    29,    30,
      31,    32,    33,    34,    35,    36,    37,    38,    39,    40,
      41,    42,    43,    44,    45,    46,    47,    48,    49,    50,
      51,    52,    53,     0,     0,    54,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
      55,    56,    57,    58,    59,    60,    61,    62,     0,     0,
       0,     0,     0,     0,     0,    63,    64,    65,    66,    67,
      68,     0,    69,    70,    71,    72,    73,    74,     0,     0,
       0,     0,     0,    75,    76,    77,    78,    79,    80,    81,
      82,    83,    84,    85,    86,    87,    88,    89,    90,     0,
      91,    92,    93,     0,     0,     0,    94,    95,    96,    97,
      98,    99,   100,   101,   102,   103,   104,   105,   106,   107,
     108,   109,   110,   111,   112,   113,   114,   115,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,   116,   117,   118,   119,   120,   121,     0,     0,   122,
     123,     9,    10,    11,    12,     0,     0,    15,     0,    16,
       0,    17,    18,    19,    20,    21,    22,    23,    24,    25,
      26,    27,    28,    29,    30,    31,    32,    33,    34,    35,
      36,    37,    38,    39,    40,    41,    42,    43,    44,    45,
      46,    47,    48,    49,    50,    51,    52,    53,     0,     0,
      54,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,    55,    56,    57,    58,    59,
      60,    61,    62,     0,     0,     0,     0,     0,     0,     0,
      63,    64,    65,    66,    67,    68,     0,    69,    70,    71,
      72,    73,    74,     0,     0,     0,     0,     0,    75,    76,
      77,    78,    79,    80,    81,    82,    83,    84,    85,    86,
      87,    88,    89,    90,     0,    91,    92,    93,     0,     0,
       0,    94,    95,    96,    97,    98,    99,   100,   101,   102,
     103,   104,   105,   106,   107,   108,   109,   110,   111,   112,
     113,   114,   115,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,   116,   117,   118,   119,
     120,   121,   249,     0,   122,   123,     9,    10,    11,    12,
       0,     0,    15,     0,    16,     0,    17,    18,    19,    20,
      21,    22,    23,    24,    25,    26,    27,    28,    29,    30,
      31,    32,    33,    34,    35,    36,    37,    38,    39,    40,
      41,    42,    43,    44,    45,    46,    47,    48,    49,    50,
      51,    52,    53,     0,     0,    54,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
      55,    56,    57,    58,    59,    60,    61,    62,     0,     0,
       0,     0,     0,     0,     0,    63,    64,    65,    66,    67,
      68,     0,    69,    70,    71,    72,    73,    74,     0,     0,
       0,     0,     0,    75,    76,    77,    78,    79,    80,    81,
      82,    83,    84,    85,    86,    87,    88,    89,    90,     0,
      91,    92,    93,     0,     0,     0,    94,    95,    96,    97,
      98,    99,   100,   101,   102,   103,   104,   105,   106,   107,
     108,   109,   110,   111,   112,   113,   114,   115,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,   116,   117,   118,   119,   120,   121,   328,     0,   122,
     123,     9,    10,    11,    12,     0,     0,    15,     0,    16,
       0,    17,    18,    19,    20,    21,    22,    23,    24,    25,
      26,    27,    28,    29,    30,    31,    32,    33,    34,    35,
      36,    37,    38,    39,    40,    41,    42,    43,    44,    45,
      46,    47,    48,    49,    50,    51,    52,    53,     0,     0,
      54,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,    55,    56,    57,    58,    59,
      60,    61,    62,     0,     0,     0,     0,     0,     0,     0,
      63,    64,    65,    66,    67,    68,     0,    69,    70,    71,
      72,    73,    74,   412,     0,     0,     0,     0,    75,    76,
      77,    78,    79,    80,    81,    82,    83,    84,    85,    86,
      87,    88,    89,    90,     0,    91,    92,    93,     0,     0,
       0,    94,    95,    96,    97,    98,    99,   100,   101,   102,
     103,   104,   105,   106,   107,   108,   109,   110,   111,   112,
     113,   114,   115,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,   116,   117,   118,   119,
     120,   121,     0,     0,   122,   123,     9,    10,    11,    12,
     430,     0,    15,     0,    16,     0,    17,    18,    19,    20,
      21,    22,    23,    24,    25,    26,    27,    28,    29,    30,
      31,    32,    33,    34,    35,    36,    37,    38,    39,    40,
      41,    42,    43,    44,    45,    46,    47,    48,    49,    50,
      51,    52,    53,     0,     0,    54,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
      55,    56,    57,    58,    59,    60,    61,    62,     0,     0,
       0,     0,     0,     0,     0,    63,    64,    65,    66,    67,
      68,     0,    69,    70,    71,    72,    73,    74,     0,     0,
       0,     0,     0,    75,    76,    77,    78,    79,    80,    81,
      82,    83,    84,    85,    86,    87,    88,    89,    90,     0,
      91,    92,    93,     0,     0,     0,    94,    95,    96,    97,
      98,    99,   100,   101,   102,   103,   104,   105,   106,   107,
     108,   109,   110,   111,   112,   113,   114,   115,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,   116,   117,   118,   119,   120,   121,     0,     0,   122,
     123,     9,    10,    11,    12,     0,     0,    15,     0,    16,
       0,    17,    18,    19,    20,    21,    22,    23,    24,    25,
      26,    27,    28,    29,    30,    31,    32,    33,    34,    35,
      36,    37,    38,    39,    40,    41,    42,    43,    44,    45,
      46,    47,    48,    49,    50,    51,    52,    53,     0,     0,
      54,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,    55,    56,    57,    58,    59,
      60,    61,    62,     0,     0,     0,     0,     0,     0,     0,
      63,    64,    65,    66,    67,    68,     0,    69,    70,    71,
      72,    73,    74,   467,     0,     0,     0,     0,    75,    76,
      77,    78,    79,    80,    81,    82,    83,    84,    85,    86,
      87,    88,    89,    90,     0,    91,    92,    93,     0,     0,
       0,    94,    95,    96,    97,    98,    99,   100,   101,   102,
     103,   104,   105,   106,   107,   108,   109,   110,   111,   112,
     113,   114,   115,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,   116,   117,   118,   119,
     120,   121,     0,     0,   122,   123,     9,    10,    11,    12,
       0,     0,    15,     0,    16,     0,    17,    18,    19,    20,
      21,    22,    23,    24,    25,    26,    27,    28,    29,    30,
      31,    32,    33,    34,    35,    36,    37,    38,    39,    40,
      41,    42,    43,    44,    45,    46,    47,    48,    49,    50,
      51,    52,    53,     0,     0,    54,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
      55,    56,    57,    58,    59,    60,    61,    62,     0,     0,
       0,     0,     0,     0,     0,    63,    64,    65,    66,    67,
      68,     0,    69,    70,    71,    72,    73,    74,   469,     0,
       0,     0,     0,    75,    76,    77,    78,    79,    80,    81,
      82,    83,    84,    85,    86,    87,    88,    89,    90,     0,
      91,    92,    93,     0,     0,     0,    94,    95,    96,    97,
      98,    99,   100,   101,   102,   103,   104,   105,   106,   107,
     108,   109,   110,   111,   112,   113,   114,   115,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,   116,   117,   118,   119,   120,   121,     0,     0,   122,
     123,     9,    10,    11,    12,     0,     0,    15,     0,    16,
       0,    17,    18,    19,    20,    21,    22,    23,    24,    25,
      26,    27,    28,    29,    30,    31,    32,    33,    34,    35,
      36,    37,    38,    39,    40,    41,    42,    43,    44,    45,
      46,    47,    48,    49,    50,    51,    52,    53,     0,     0,
      54,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,    55,    56,    57,    58,    59,
      60,    61,    62,     0,     0,     0,     0,     0,     0,     0,
      63,    64,    65,    66,    67,    68,     0,    69,    70,    71,
      72,    73,    74,   543,     0,     0,     0,     0,    75,    76,
      77,    78,    79,    80,    81,    82,    83,    84,    85,    86,
      87,    88,    89,    90,     0,    91,    92,    93,     0,     0,
       0,    94,    95,    96,    97,    98,    99,   100,   101,   102,
     103,   104,   105,   106,   107,   108,   109,   110,   111,   112,
     113,   114,   115,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,   116,   117,   118,   119,
     120,   121,     0,     0,   122,   123,     9,    10,    11,    12,
       0,     0,    15,     0,    16,     0,    17,    18,    19,    20,
      21,    22,    23,    24,    25,    26,    27,    28,    29,    30,
      31,    32,    33,    34,    35,    36,    37,    38,    39,    40,
      41,    42,    43,    44,    45,    46,    47,    48,    49,    50,
      51,    52,    53,     0,     0,    54,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
      55,    56,    57,    58,    59,    60,    61,    62,     0,     0,
       0,     0,     0,     0,     0,    63,    64,    65,    66,    67,
      68,     0,    69,    70,    71,    72,    73,    74,     0,     0,
       0,     0,     0,    75,    76,    77,    78,    79,    80,    81,
      82,    83,    84,    85,    86,    87,    88,    89,    90,     0,
      91,    92,    93,     0,     0,     0,    94,    95,    96,    97,
      98,    99,   100,   101,   102,   103,   104,   105,   106,   107,
     108,   109,   110,   111,   112,   113,   114,   115,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,   116,   117,   118,   119,   120,   121,     0,     0,   122,
     123,     9,    10,    11,    12,     0,     0,    15,     0,    16,
       0,    17,    18,    19,    20,    21,    22,    23,    24,    25,
      26,    27,    28,    29,    30,    31,    32,    33,    34,    35,
      36,    37,    38,    39,    40,    41,    42,    43,    44,    45,
      46,    47,    48,    49,    50,    51,    52,    53,     0,     0,
      54,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,    55,    56,    57,    58,    59,
      60,    61,    62,     0,     0,     0,     0,     0,     0,     0,
      63,    64,    65,    66,    67,    68,     0,    69,    70,    71,
      72,    73,    74,     0,     0,     0,     0,     0,    75,    76,
      77,    78,    79,    80,    81,    82,    83,    84,    85,   540,
      87,    88,    89,    90,     0,    91,    92,    93,     0,     0,
       0,    94,    95,    96,    97,    98,    99,   100,   101,   102,
     103,   104,   105,   106,   107,   108,   109,   110,   111,   112,
     113,   114,   115,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,   116,   117,   118,   119,
     120,   121,     0,     0,   122,   123
};

static const yytype_int16 yycheck[] =
{
       2,     3,   360,   261,   362,    15,    15,    60,    60,    60,
     101,    60,    60,    15,    60,    60,   102,    16,    60,    16,
      60,    60,    16,    60,    60,     2,     3,    82,    16,   380,
      56,   382,    87,    16,    57,    82,    57,     0,    15,   313,
     314,   315,   316,   317,   318,   101,   320,   321,   322,   323,
     324,   437,   438,   437,   438,    81,    15,    58,    82,    82,
     101,    82,    86,    60,    63,    64,    60,    69,    70,    71,
      72,    73,   101,   159,   432,    63,    64,    60,    82,    63,
      64,   101,    86,   174,    82,    83,    84,    85,    90,    39,
      40,    16,    69,    70,    71,    72,    73,    72,   151,   151,
     151,   359,   151,   151,    72,   151,   151,   117,   117,   151,
     124,   151,   151,    90,   151,   151,   104,   105,    15,   166,
     104,   105,   124,    13,    14,   127,    16,    81,   514,    81,
     514,   489,    13,    14,   520,    16,   520,    62,    63,    64,
      65,    66,    67,    68,    69,    70,    71,     5,     6,     7,
     127,   152,   153,   154,   155,   156,   157,   158,    81,   160,
     161,   162,   163,    38,    39,    81,    41,    38,    39,    40,
       2,     3,    13,    14,    81,    16,    81,   435,    13,    14,
     101,    16,   101,    15,    62,    63,    64,    65,    66,    67,
      68,    69,    70,    71,    13,    14,   210,    16,   101,    39,
      40,    41,    39,    40,   218,    39,    40,    41,   210,    39,
      40,    41,    39,    40,    41,   101,   218,    13,    14,    15,
      72,   579,    83,    84,    85,    39,    40,    39,    40,    13,
      14,    13,    14,    13,    14,    13,    14,    69,    70,    71,
      72,    73,    63,    64,   473,   474,    72,   249,   101,   166,
      86,   166,   126,   101,    87,   529,    15,    15,    90,    15,
      15,   263,    59,    81,   278,   279,   280,   281,   282,    82,
      57,   159,   249,    14,    13,   289,   278,   279,   280,   281,
     282,    14,    13,    81,    14,    13,    13,   289,   152,   154,
     153,   157,   124,   567,   156,   127,   554,    72,   155,    72,
     160,    72,   576,   162,    72,   161,    72,    72,   163,    72,
      72,   313,   314,   315,   316,   317,   318,   127,   320,   321,
     322,   323,   324,   337,   326,   327,   328,    72,    72,    72,
      72,    82,    81,    58,   128,   337,   350,    58,     5,     5,
     270,   384,   344,   345,    82,   377,   273,   451,   350,   326,
     327,   328,   500,   367,   569,   440,   514,   441,   520,    -1,
      -1,    -1,    -1,    -1,    -1,   367,    -1,   344,   345,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,   210,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,   218,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,   409,   410,   411,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,   409,   410,   411,
      -1,   425,   426,    -1,    -1,   417,   418,   249,    -1,    -1,
      -1,    -1,    -1,   425,   426,    -1,    -1,    -1,    -1,    -1,
      -1,   263,    -1,    -1,    -1,    -1,    -1,    -1,   440,   441,
     417,   418,    -1,    -1,    -1,    -1,   278,   279,   280,   281,
     282,    -1,    -1,    -1,    -1,    -1,    -1,   289,    -1,   473,
     474,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,   473,   474,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,   313,   314,   315,   316,   317,   318,    -1,   320,   321,
     322,   323,   324,    -1,   326,   327,   328,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,   337,    -1,    -1,    -1,    -1,
      -1,    -1,   344,   345,    -1,    -1,    -1,    -1,   350,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,   529,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,   367,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,   567,    -1,   569,   582,    -1,
      -1,   573,    -1,    -1,   576,    -1,    -1,   409,   410,   411,
     582,    -1,    -1,    -1,    -1,   417,   418,    -1,    -1,    -1,
      13,    14,    15,   425,   426,    -1,   573,    -1,    -1,    -1,
      -1,    -1,    25,    26,    -1,    -1,    -1,    -1,   440,   441,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    42,
      43,    44,    45,    46,    47,    48,    49,    50,    51,    52,
      -1,    -1,    55,    56,    57,    58,    59,    60,    -1,    -1,
      -1,   473,   474,    66,    67,    68,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      83,    -1,    -1,    -1,    -1,    -1,    89,    -1,    -1,    -1,
      -1,    94,    95,    96,    97,    98,    99,   100,   101,   102,
     103,   104,   105,   106,   107,   108,   109,   110,   111,   112,
      -1,    -1,    -1,    -1,   117,    -1,    -1,   529,   121,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,   567,    -1,   569,    -1,    -1,
      -1,   573,    -1,    -1,   576,    -1,    -1,    -1,    -1,    -1,
     582,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
     243,   244,    -1,    -1,    -1,    -1,    -1,    -1,   251,   252,
     253,   254,   255,    -1,    -1,    -1,   259,    -1,    -1,   262,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,   285,   286,   287,   288,    -1,   290,   291,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,   331,    -1,
      -1,    -1,   335,   336,    -1,   338,   339,   340,   341,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,   356,   357,   358,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,   412,
      -1,   414,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,   427,    -1,    -1,   430,    -1,    -1,
      -1,   434,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,   466,   467,    -1,   469,    -1,   471,   472,
      -1,    -1,    -1,    -1,    -1,   478,   479,   480,   481,     3,
       4,    -1,    -1,   486,    -1,     9,    10,    11,    12,    13,
      14,    15,    16,    17,    -1,    19,    20,    21,    22,    23,
      24,    25,    26,    27,    28,    29,    30,    31,    32,    33,
      34,    35,    36,    37,    38,    39,    40,    41,    42,    43,
      44,    45,    46,    47,    48,    49,    50,    51,    52,    53,
      54,    55,    -1,    -1,    58,    -1,    -1,    -1,    -1,    -1,
     543,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    73,
      74,    75,    76,    77,    78,    79,    80,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    88,    89,    90,    91,    92,    93,
      -1,    95,    96,    97,    98,    99,   100,    -1,    -1,    -1,
      -1,    -1,   106,   107,   108,   109,   110,   111,   112,   113,
     114,   115,   116,   117,   118,   119,   120,   121,    -1,   123,
     124,   125,    -1,    -1,    -1,   129,   130,   131,   132,   133,
     134,   135,   136,   137,   138,   139,   140,   141,   142,   143,
     144,   145,   146,   147,   148,   149,   150,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
     164,   165,   166,   167,   168,   169,     3,     4,   172,   173,
      -1,    -1,     9,    10,    11,    12,    13,    14,    15,    -1,
      17,    18,    19,    20,    21,    22,    23,    24,    25,    26,
      27,    28,    29,    30,    31,    32,    33,    34,    35,    36,
      37,    38,    39,    40,    41,    42,    43,    44,    45,    46,
      47,    48,    49,    50,    51,    52,    53,    54,    55,    -1,
      -1,    58,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    73,    74,    75,    76,
      77,    78,    79,    80,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    88,    89,    90,    91,    92,    93,    -1,    95,    96,
      97,    98,    99,   100,    -1,    -1,    -1,    -1,    -1,   106,
     107,   108,   109,   110,   111,   112,   113,   114,   115,   116,
     117,   118,   119,   120,   121,    -1,   123,   124,   125,    -1,
      -1,    -1,   129,   130,   131,   132,   133,   134,   135,   136,
     137,   138,   139,   140,   141,   142,   143,   144,   145,   146,
     147,   148,   149,   150,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,   164,   165,   166,
     167,   168,   169,    -1,    -1,   172,   173,     8,     9,    10,
      11,    12,    13,    14,    15,    -1,    17,    -1,    19,    20,
      21,    22,    23,    24,    25,    26,    27,    28,    29,    30,
      31,    32,    33,    34,    35,    36,    37,    38,    39,    40,
      41,    42,    43,    44,    45,    46,    47,    48,    49,    50,
      51,    52,    53,    54,    55,    -1,    -1,    58,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    73,    74,    75,    76,    77,    78,    79,    80,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    88,    89,    90,
      91,    92,    93,    -1,    95,    96,    97,    98,    99,   100,
      -1,    -1,    -1,    -1,    -1,   106,   107,   108,   109,   110,
     111,   112,   113,   114,   115,   116,   117,   118,   119,   120,
     121,    -1,   123,   124,   125,    -1,    -1,    -1,   129,   130,
     131,   132,   133,   134,   135,   136,   137,   138,   139,   140,
     141,   142,   143,   144,   145,   146,   147,   148,   149,   150,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,   164,   165,   166,   167,   168,   169,    -1,
      -1,   172,   173,     8,     9,    10,    11,    12,    13,    14,
      15,    -1,    17,    -1,    19,    20,    21,    22,    23,    24,
      25,    26,    27,    28,    29,    30,    31,    32,    33,    34,
      35,    36,    37,    38,    39,    40,    41,    42,    43,    44,
      45,    46,    47,    48,    49,    50,    51,    52,    53,    54,
      55,    -1,    -1,    58,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    73,    74,
      75,    76,    77,    78,    79,    80,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    88,    89,    90,    91,    92,    93,    -1,
      95,    96,    97,    98,    99,   100,    -1,    -1,    -1,    -1,
      -1,   106,   107,   108,   109,   110,   111,   112,   113,   114,
     115,   116,   117,   118,   119,   120,   121,    -1,   123,   124,
     125,    -1,    -1,    -1,   129,   130,   131,   132,   133,   134,
     135,   136,   137,   138,   139,   140,   141,   142,   143,   144,
     145,   146,   147,   148,   149,   150,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,   164,
     165,   166,   167,   168,   169,    -1,    -1,   172,   173,     8,
       9,    10,    11,    12,    13,    14,    15,    -1,    17,    -1,
      19,    20,    21,    22,    23,    24,    25,    26,    27,    28,
      29,    30,    31,    32,    33,    34,    35,    36,    37,    38,
      39,    40,    41,    42,    43,    44,    45,    46,    47,    48,
      49,    50,    51,    52,    53,    54,    55,    -1,    -1,    58,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    73,    74,    75,    76,    77,    78,
      79,    80,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    88,
      89,    90,    91,    92,    93,    -1,    95,    96,    97,    98,
      99,   100,    -1,    -1,    -1,    -1,    -1,   106,   107,   108,
     109,   110,   111,   112,   113,   114,   115,   116,   117,   118,
     119,   120,   121,    -1,   123,   124,   125,    -1,    -1,    -1,
     129,   130,   131,   132,   133,   134,   135,   136,   137,   138,
     139,   140,   141,   142,   143,   144,   145,   146,   147,   148,
     149,   150,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,   164,   165,   166,   167,   168,
     169,    -1,    -1,   172,   173,     8,     9,    10,    11,    12,
      13,    14,    15,    -1,    17,    -1,    19,    20,    21,    22,
      23,    24,    25,    26,    27,    28,    29,    30,    31,    32,
      33,    34,    35,    36,    37,    38,    39,    40,    41,    42,
      43,    44,    45,    46,    47,    48,    49,    50,    51,    52,
      53,    54,    55,    -1,    -1,    58,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      73,    74,    75,    76,    77,    78,    79,    80,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    88,    89,    90,    91,    92,
      93,    -1,    95,    96,    97,    98,    99,   100,    -1,    -1,
      -1,    -1,    -1,   106,   107,   108,   109,   110,   111,   112,
     113,   114,   115,   116,   117,   118,   119,   120,   121,    -1,
     123,   124,   125,    -1,    -1,    -1,   129,   130,   131,   132,
     133,   134,   135,   136,   137,   138,   139,   140,   141,   142,
     143,   144,   145,   146,   147,   148,   149,   150,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,   164,   165,   166,   167,   168,   169,    -1,    -1,   172,
     173,     9,    10,    11,    12,    13,    14,    15,    -1,    17,
      -1,    19,    20,    21,    22,    23,    24,    25,    26,    27,
      28,    29,    30,    31,    32,    33,    34,    35,    36,    37,
      38,    39,    40,    41,    42,    43,    44,    45,    46,    47,
      48,    49,    50,    51,    52,    53,    54,    55,    -1,    -1,
      58,    -1,    -1,    61,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    73,    74,    75,    76,    77,
      78,    79,    80,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      88,    89,    90,    91,    92,    93,    94,    95,    96,    97,
      98,    99,   100,    -1,    -1,   103,    -1,    -1,   106,   107,
     108,   109,   110,   111,   112,   113,   114,   115,   116,   117,
     118,   119,   120,   121,    -1,   123,   124,   125,    -1,    -1,
      -1,   129,   130,   131,   132,   133,   134,   135,   136,   137,
     138,   139,   140,   141,   142,   143,   144,   145,   146,   147,
     148,   149,   150,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,   164,   165,   166,   167,
     168,   169,    -1,    -1,   172,   173,     9,    10,    11,    12,
      13,    14,    15,    -1,    17,    -1,    19,    20,    21,    22,
      23,    24,    25,    26,    27,    28,    29,    30,    31,    32,
      33,    34,    35,    36,    37,    38,    39,    40,    41,    42,
      43,    44,    45,    46,    47,    48,    49,    50,    51,    52,
      53,    54,    55,    -1,    -1,    58,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      73,    74,    75,    76,    77,    78,    79,    80,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    88,    89,    90,    91,    92,
      93,    94,    95,    96,    97,    98,    99,   100,    -1,    -1,
     103,    -1,    -1,   106,   107,   108,   109,   110,   111,   112,
     113,   114,   115,   116,   117,   118,   119,   120,   121,    -1,
     123,   124,   125,    -1,    -1,    -1,   129,   130,   131,   132,
     133,   134,   135,   136,   137,   138,   139,   140,   141,   142,
     143,   144,   145,   146,   147,   148,   149,   150,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,   164,   165,   166,   167,   168,   169,    -1,    -1,   172,
     173,     9,    10,    11,    12,    13,    14,    15,    -1,    17,
      -1,    19,    20,    21,    22,    23,    24,    25,    26,    27,
      28,    29,    30,    31,    32,    33,    34,    35,    36,    37,
      38,    39,    40,    41,    42,    43,    44,    45,    46,    47,
      48,    49,    50,    51,    52,    53,    54,    55,    -1,    -1,
      58,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    73,    74,    75,    76,    77,
      78,    79,    80,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      88,    89,    90,    91,    92,    93,    -1,    95,    96,    97,
      98,    99,   100,    -1,    -1,    -1,    -1,    -1,   106,   107,
     108,   109,   110,   111,   112,   113,   114,   115,   116,   117,
     118,   119,   120,   121,   122,   123,   124,   125,    -1,    -1,
      -1,   129,   130,   131,   132,   133,   134,   135,   136,   137,
     138,   139,   140,   141,   142,   143,   144,   145,   146,   147,
     148,   149,   150,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,   164,   165,   166,   167,
     168,   169,    -1,    -1,   172,   173,     9,    10,    11,    12,
      13,    14,    15,    -1,    17,    -1,    19,    20,    21,    22,
      23,    24,    25,    26,    27,    28,    29,    30,    31,    32,
      33,    34,    35,    36,    37,    38,    39,    40,    41,    42,
      43,    44,    45,    46,    47,    48,    49,    50,    51,    52,
      53,    54,    55,    -1,    -1,    58,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      73,    74,    75,    76,    77,    78,    79,    80,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    88,    89,    90,    91,    92,
      93,    -1,    95,    96,    97,    98,    99,   100,    -1,    -1,
      -1,    -1,    -1,   106,   107,   108,   109,   110,   111,   112,
     113,   114,   115,   116,   117,   118,   119,   120,   121,    -1,
     123,   124,   125,    -1,    -1,    -1,   129,   130,   131,   132,
     133,   134,   135,   136,   137,   138,   139,   140,   141,   142,
     143,   144,   145,   146,   147,   148,   149,   150,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,   164,   165,   166,   167,   168,   169,    -1,   171,   172,
     173,     9,    10,    11,    12,    13,    14,    15,    -1,    17,
      -1,    19,    20,    21,    22,    23,    24,    25,    26,    27,
      28,    29,    30,    31,    32,    33,    34,    35,    36,    37,
      38,    39,    40,    41,    42,    43,    44,    45,    46,    47,
      48,    49,    50,    51,    52,    53,    54,    55,    -1,    -1,
      58,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    73,    74,    75,    76,    77,
      78,    79,    80,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      88,    89,    90,    91,    92,    93,    -1,    95,    96,    97,
      98,    99,   100,    -1,    -1,    -1,    -1,    -1,   106,   107,
     108,   109,   110,   111,   112,   113,   114,   115,   116,   117,
     118,   119,   120,   121,    -1,   123,   124,   125,    -1,    -1,
      -1,   129,   130,   131,   132,   133,   134,   135,   136,   137,
     138,   139,   140,   141,   142,   143,   144,   145,   146,   147,
     148,   149,   150,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,   164,   165,   166,   167,
     168,   169,    -1,   171,   172,   173,     9,    10,    11,    12,
      13,    14,    15,    16,    17,    -1,    19,    20,    21,    22,
      23,    24,    25,    26,    27,    28,    29,    30,    31,    32,
      33,    34,    35,    36,    37,    38,    39,    40,    41,    42,
      43,    44,    45,    46,    47,    48,    49,    50,    51,    52,
      53,    54,    55,    -1,    -1,    58,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      73,    74,    75,    76,    77,    78,    79,    80,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    88,    89,    90,    91,    92,
      93,    -1,    95,    96,    97,    98,    99,   100,    -1,    -1,
      -1,    -1,    -1,   106,   107,   108,   109,   110,   111,   112,
     113,   114,   115,   116,   117,   118,   119,   120,   121,    -1,
     123,   124,   125,    -1,    -1,    -1,   129,   130,   131,   132,
     133,   134,   135,   136,   137,   138,   139,   140,   141,   142,
     143,   144,   145,   146,   147,   148,   149,   150,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,   164,   165,   166,   167,   168,   169,    -1,    -1,   172,
     173,     9,    10,    11,    12,    13,    14,    15,    16,    17,
      -1,    19,    20,    21,    22,    23,    24,    25,    26,    27,
      28,    29,    30,    31,    32,    33,    34,    35,    36,    37,
      38,    39,    40,    41,    42,    43,    44,    45,    46,    47,
      48,    49,    50,    51,    52,    53,    54,    55,    -1,    -1,
      58,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    73,    74,    75,    76,    77,
      78,    79,    80,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      88,    89,    90,    91,    92,    93,    -1,    95,    96,    97,
      98,    99,   100,    -1,    -1,    -1,    -1,    -1,   106,   107,
     108,   109,   110,   111,   112,   113,   114,   115,   116,   117,
     118,   119,   120,   121,    -1,   123,   124,   125,    -1,    -1,
      -1,   129,   130,   131,   132,   133,   134,   135,   136,   137,
     138,   139,   140,   141,   142,   143,   144,   145,   146,   147,
     148,   149,   150,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,   164,   165,   166,   167,
     168,   169,    -1,    -1,   172,   173,     9,    10,    11,    12,
      13,    14,    15,    -1,    17,    -1,    19,    20,    21,    22,
      23,    24,    25,    26,    27,    28,    29,    30,    31,    32,
      33,    34,    35,    36,    37,    38,    39,    40,    41,    42,
      43,    44,    45,    46,    47,    48,    49,    50,    51,    52,
      53,    54,    55,    -1,    -1,    58,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      73,    74,    75,    76,    77,    78,    79,    80,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    88,    89,    90,    91,    92,
      93,    -1,    95,    96,    97,    98,    99,   100,    -1,    -1,
     103,    -1,    -1,   106,   107,   108,   109,   110,   111,   112,
     113,   114,   115,   116,   117,   118,   119,   120,   121,    -1,
     123,   124,   125,    -1,    -1,    -1,   129,   130,   131,   132,
     133,   134,   135,   136,   137,   138,   139,   140,   141,   142,
     143,   144,   145,   146,   147,   148,   149,   150,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,   164,   165,   166,   167,   168,   169,    -1,    -1,   172,
     173,     9,    10,    11,    12,    13,    14,    15,    -1,    17,
      18,    19,    20,    21,    22,    23,    24,    25,    26,    27,
      28,    29,    30,    31,    32,    33,    34,    35,    36,    37,
      38,    39,    40,    41,    42,    43,    44,    45,    46,    47,
      48,    49,    50,    51,    52,    53,    54,    55,    -1,    -1,
      58,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    73,    74,    75,    76,    77,
      78,    79,    80,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      88,    89,    90,    91,    92,    93,    -1,    95,    96,    97,
      98,    99,   100,    -1,    -1,    -1,    -1,    -1,   106,   107,
     108,   109,   110,   111,   112,   113,   114,   115,   116,   117,
     118,   119,   120,   121,    -1,   123,   124,   125,    -1,    -1,
      -1,   129,   130,   131,   132,   133,   134,   135,   136,   137,
     138,   139,   140,   141,   142,   143,   144,   145,   146,   147,
     148,   149,   150,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,   164,   165,   166,   167,
     168,   169,    -1,    -1,   172,   173,     9,    10,    11,    12,
      13,    14,    15,    -1,    17,    -1,    19,    20,    21,    22,
      23,    24,    25,    26,    27,    28,    29,    30,    31,    32,
      33,    34,    35,    36,    37,    38,    39,    40,    41,    42,
      43,    44,    45,    46,    47,    48,    49,    50,    51,    52,
      53,    54,    55,    -1,    -1,    58,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      73,    74,    75,    76,    77,    78,    79,    80,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    88,    89,    90,    91,    92,
      93,    -1,    95,    96,    97,    98,    99,   100,    -1,    -1,
      -1,    -1,    -1,   106,   107,   108,   109,   110,   111,   112,
     113,   114,   115,   116,   117,   118,   119,   120,   121,    -1,
     123,   124,   125,    -1,    -1,    -1,   129,   130,   131,   132,
     133,   134,   135,   136,   137,   138,   139,   140,   141,   142,
     143,   144,   145,   146,   147,   148,   149,   150,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,   164,   165,   166,   167,   168,   169,    -1,    -1,   172,
     173,     9,    10,    11,    12,    -1,    -1,    15,    -1,    17,
      -1,    19,    20,    21,    22,    23,    24,    25,    26,    27,
      28,    29,    30,    31,    32,    33,    34,    35,    36,    37,
      38,    39,    40,    41,    42,    43,    44,    45,    46,    47,
      48,    49,    50,    51,    52,    53,    54,    55,    -1,    -1,
      58,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    73,    74,    75,    76,    77,
      78,    79,    80,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      88,    89,    90,    91,    92,    93,    -1,    95,    96,    97,
      98,    99,   100,    -1,    -1,    -1,    -1,    -1,   106,   107,
     108,   109,   110,   111,   112,   113,   114,   115,   116,   117,
     118,   119,   120,   121,    -1,   123,   124,   125,    -1,    -1,
      -1,   129,   130,   131,   132,   133,   134,   135,   136,   137,
     138,   139,   140,   141,   142,   143,   144,   145,   146,   147,
     148,   149,   150,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,   164,   165,   166,   167,
     168,   169,   170,    -1,   172,   173,     9,    10,    11,    12,
      -1,    -1,    15,    -1,    17,    -1,    19,    20,    21,    22,
      23,    24,    25,    26,    27,    28,    29,    30,    31,    32,
      33,    34,    35,    36,    37,    38,    39,    40,    41,    42,
      43,    44,    45,    46,    47,    48,    49,    50,    51,    52,
      53,    54,    55,    -1,    -1,    58,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      73,    74,    75,    76,    77,    78,    79,    80,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    88,    89,    90,    91,    92,
      93,    -1,    95,    96,    97,    98,    99,   100,    -1,    -1,
      -1,    -1,    -1,   106,   107,   108,   109,   110,   111,   112,
     113,   114,   115,   116,   117,   118,   119,   120,   121,    -1,
     123,   124,   125,    -1,    -1,    -1,   129,   130,   131,   132,
     133,   134,   135,   136,   137,   138,   139,   140,   141,   142,
     143,   144,   145,   146,   147,   148,   149,   150,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,   164,   165,   166,   167,   168,   169,   170,    -1,   172,
     173,     9,    10,    11,    12,    -1,    -1,    15,    -1,    17,
      -1,    19,    20,    21,    22,    23,    24,    25,    26,    27,
      28,    29,    30,    31,    32,    33,    34,    35,    36,    37,
      38,    39,    40,    41,    42,    43,    44,    45,    46,    47,
      48,    49,    50,    51,    52,    53,    54,    55,    -1,    -1,
      58,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    73,    74,    75,    76,    77,
      78,    79,    80,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      88,    89,    90,    91,    92,    93,    -1,    95,    96,    97,
      98,    99,   100,   101,    -1,    -1,    -1,    -1,   106,   107,
     108,   109,   110,   111,   112,   113,   114,   115,   116,   117,
     118,   119,   120,   121,    -1,   123,   124,   125,    -1,    -1,
      -1,   129,   130,   131,   132,   133,   134,   135,   136,   137,
     138,   139,   140,   141,   142,   143,   144,   145,   146,   147,
     148,   149,   150,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,   164,   165,   166,   167,
     168,   169,    -1,    -1,   172,   173,     9,    10,    11,    12,
      13,    -1,    15,    -1,    17,    -1,    19,    20,    21,    22,
      23,    24,    25,    26,    27,    28,    29,    30,    31,    32,
      33,    34,    35,    36,    37,    38,    39,    40,    41,    42,
      43,    44,    45,    46,    47,    48,    49,    50,    51,    52,
      53,    54,    55,    -1,    -1,    58,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      73,    74,    75,    76,    77,    78,    79,    80,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    88,    89,    90,    91,    92,
      93,    -1,    95,    96,    97,    98,    99,   100,    -1,    -1,
      -1,    -1,    -1,   106,   107,   108,   109,   110,   111,   112,
     113,   114,   115,   116,   117,   118,   119,   120,   121,    -1,
     123,   124,   125,    -1,    -1,    -1,   129,   130,   131,   132,
     133,   134,   135,   136,   137,   138,   139,   140,   141,   142,
     143,   144,   145,   146,   147,   148,   149,   150,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,   164,   165,   166,   167,   168,   169,    -1,    -1,   172,
     173,     9,    10,    11,    12,    -1,    -1,    15,    -1,    17,
      -1,    19,    20,    21,    22,    23,    24,    25,    26,    27,
      28,    29,    30,    31,    32,    33,    34,    35,    36,    37,
      38,    39,    40,    41,    42,    43,    44,    45,    46,    47,
      48,    49,    50,    51,    52,    53,    54,    55,    -1,    -1,
      58,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    73,    74,    75,    76,    77,
      78,    79,    80,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      88,    89,    90,    91,    92,    93,    -1,    95,    96,    97,
      98,    99,   100,   101,    -1,    -1,    -1,    -1,   106,   107,
     108,   109,   110,   111,   112,   113,   114,   115,   116,   117,
     118,   119,   120,   121,    -1,   123,   124,   125,    -1,    -1,
      -1,   129,   130,   131,   132,   133,   134,   135,   136,   137,
     138,   139,   140,   141,   142,   143,   144,   145,   146,   147,
     148,   149,   150,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,   164,   165,   166,   167,
     168,   169,    -1,    -1,   172,   173,     9,    10,    11,    12,
      -1,    -1,    15,    -1,    17,    -1,    19,    20,    21,    22,
      23,    24,    25,    26,    27,    28,    29,    30,    31,    32,
      33,    34,    35,    36,    37,    38,    39,    40,    41,    42,
      43,    44,    45,    46,    47,    48,    49,    50,    51,    52,
      53,    54,    55,    -1,    -1,    58,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      73,    74,    75,    76,    77,    78,    79,    80,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    88,    89,    90,    91,    92,
      93,    -1,    95,    96,    97,    98,    99,   100,   101,    -1,
      -1,    -1,    -1,   106,   107,   108,   109,   110,   111,   112,
     113,   114,   115,   116,   117,   118,   119,   120,   121,    -1,
     123,   124,   125,    -1,    -1,    -1,   129,   130,   131,   132,
     133,   134,   135,   136,   137,   138,   139,   140,   141,   142,
     143,   144,   145,   146,   147,   148,   149,   150,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,   164,   165,   166,   167,   168,   169,    -1,    -1,   172,
     173,     9,    10,    11,    12,    -1,    -1,    15,    -1,    17,
      -1,    19,    20,    21,    22,    23,    24,    25,    26,    27,
      28,    29,    30,    31,    32,    33,    34,    35,    36,    37,
      38,    39,    40,    41,    42,    43,    44,    45,    46,    47,
      48,    49,    50,    51,    52,    53,    54,    55,    -1,    -1,
      58,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    73,    74,    75,    76,    77,
      78,    79,    80,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      88,    89,    90,    91,    92,    93,    -1,    95,    96,    97,
      98,    99,   100,   101,    -1,    -1,    -1,    -1,   106,   107,
     108,   109,   110,   111,   112,   113,   114,   115,   116,   117,
     118,   119,   120,   121,    -1,   123,   124,   125,    -1,    -1,
      -1,   129,   130,   131,   132,   133,   134,   135,   136,   137,
     138,   139,   140,   141,   142,   143,   144,   145,   146,   147,
     148,   149,   150,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,   164,   165,   166,   167,
     168,   169,    -1,    -1,   172,   173,     9,    10,    11,    12,
      -1,    -1,    15,    -1,    17,    -1,    19,    20,    21,    22,
      23,    24,    25,    26,    27,    28,    29,    30,    31,    32,
      33,    34,    35,    36,    37,    38,    39,    40,    41,    42,
      43,    44,    45,    46,    47,    48,    49,    50,    51,    52,
      53,    54,    55,    -1,    -1,    58,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      73,    74,    75,    76,    77,    78,    79,    80,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    88,    89,    90,    91,    92,
      93,    -1,    95,    96,    97,    98,    99,   100,    -1,    -1,
      -1,    -1,    -1,   106,   107,   108,   109,   110,   111,   112,
     113,   114,   115,   116,   117,   118,   119,   120,   121,    -1,
     123,   124,   125,    -1,    -1,    -1,   129,   130,   131,   132,
     133,   134,   135,   136,   137,   138,   139,   140,   141,   142,
     143,   144,   145,   146,   147,   148,   149,   150,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,   164,   165,   166,   167,   168,   169,    -1,    -1,   172,
     173,     9,    10,    11,    12,    -1,    -1,    15,    -1,    17,
      -1,    19,    20,    21,    22,    23,    24,    25,    26,    27,
      28,    29,    30,    31,    32,    33,    34,    35,    36,    37,
      38,    39,    40,    41,    42,    43,    44,    45,    46,    47,
      48,    49,    50,    51,    52,    53,    54,    55,    -1,    -1,
      58,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    73,    74,    75,    76,    77,
      78,    79,    80,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      88,    89,    90,    91,    92,    93,    -1,    95,    96,    97,
      98,    99,   100,    -1,    -1,    -1,    -1,    -1,   106,   107,
     108,   109,   110,   111,   112,   113,   114,   115,   116,   117,
     118,   119,   120,   121,    -1,   123,   124,   125,    -1,    -1,
      -1,   129,   130,   131,   132,   133,   134,   135,   136,   137,
     138,   139,   140,   141,   142,   143,   144,   145,   146,   147,
     148,   149,   150,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,   164,   165,   166,   167,
     168,   169,    -1,    -1,   172,   173
};

  /* YYSTOS[STATE-NUM] -- The (internal number of the) accessing
     symbol of state STATE-NUM.  */
static const yytype_uint16 yystos[] =
{
       0,     5,     6,     7,   176,   177,   178,   179,     8,     9,
      10,    11,    12,    13,    14,    15,    17,    19,    20,    21,
      22,    23,    24,    25,    26,    27,    28,    29,    30,    31,
      32,    33,    34,    35,    36,    37,    38,    39,    40,    41,
      42,    43,    44,    45,    46,    47,    48,    49,    50,    51,
      52,    53,    54,    55,    58,    73,    74,    75,    76,    77,
      78,    79,    80,    88,    89,    90,    91,    92,    93,    95,
      96,    97,    98,    99,   100,   106,   107,   108,   109,   110,
     111,   112,   113,   114,   115,   116,   117,   118,   119,   120,
     121,   123,   124,   125,   129,   130,   131,   132,   133,   134,
     135,   136,   137,   138,   139,   140,   141,   142,   143,   144,
     145,   146,   147,   148,   149,   150,   164,   165,   166,   167,
     168,   169,   172,   173,   180,   181,   182,   183,   185,   186,
     187,   188,   189,   190,   191,   192,   193,   194,   195,   196,
     197,   198,   199,   200,   201,   202,   203,   204,   205,   206,
     207,   208,   209,   210,   211,   212,   213,   214,   215,   216,
     217,   218,   221,   224,   225,   228,   229,   230,   231,   232,
     233,   234,   235,   236,   237,   238,   239,   242,   243,   244,
     245,   246,   247,   248,   249,   250,   251,   252,   253,   254,
     255,   256,   257,   258,   259,   260,   261,   262,   263,   264,
     265,   266,   267,   268,   269,   270,   271,   273,   274,     8,
     180,     0,   178,   179,   182,   190,   192,   182,   180,   182,
      38,    39,    40,    39,    40,    41,    39,    40,    41,    39,
      40,    41,    39,    40,    41,    39,    40,    39,    40,    39,
      40,    39,    40,   182,   182,   101,   101,   101,   101,   170,
     182,   182,   182,   182,   182,   182,   182,   182,   182,   182,
     182,    15,   117,    15,   182,   182,   182,   182,   182,   182,
      81,    81,    81,    81,    81,   182,   182,   182,   180,   180,
     180,   180,   180,   101,   182,   101,   101,   101,   182,   180,
      72,    72,    81,   182,   182,   182,   182,   182,   182,   182,
     182,   182,   182,   182,   182,   182,   182,   182,   182,   182,
     182,   182,    58,   152,   153,   154,   155,   156,   157,   158,
     160,   161,   162,   163,    15,   182,    72,    72,   170,   182,
     101,   101,   174,     8,   181,    13,    14,   180,    13,    14,
      13,    14,   166,     8,     3,     4,    16,    16,   182,   182,
     180,   182,   182,   182,   182,   182,   182,    13,    14,    15,
     240,   241,   240,   182,    61,    94,   103,   180,   287,   288,
     289,   290,   293,   217,    83,    84,    85,   219,   220,    86,
     226,   227,   226,    87,   222,   223,   182,   182,   182,   182,
     122,   182,   182,   126,    56,    81,   287,   287,   287,   287,
     287,   287,   102,   159,   287,   287,   287,   287,   287,   180,
     180,   180,   101,   182,   101,   182,   182,     3,     4,    18,
     184,   182,   182,   182,   182,   180,   180,   171,   182,   182,
      13,   182,   240,   241,    16,    15,    15,    15,    15,    16,
      60,    59,    82,    82,   220,    82,   227,    82,    82,   223,
      82,    81,    57,   272,   151,   151,   151,   151,   151,   151,
     159,   151,   151,   151,   151,    16,   171,   101,   182,   101,
     182,    14,    13,   180,   180,    38,    39,    41,    14,    13,
      14,    13,    16,    16,   182,   182,    13,    16,   182,   240,
      62,    63,    64,    65,    66,    67,    68,    69,    70,    71,
     275,   276,   277,   278,   279,   280,   281,   282,   283,   284,
     285,   286,   278,   279,   291,   292,   104,   105,   278,   279,
     294,   295,   296,   297,   288,   293,    81,   272,    57,    82,
     152,   153,   154,   155,   156,   157,   160,   161,   162,   163,
     117,   182,   182,   101,   182,   182,   182,   184,   184,   182,
     182,   182,   182,   182,    15,   117,    16,    72,    72,    72,
      72,    72,    72,    72,    72,    72,    72,    16,   276,    16,
     292,    72,    72,    16,   295,   127,    82,   287,   182,   240,
     287,   289,   180,    82,   287,   151,    16,    16,    81,   151,
      58,   128,    58,    82
};

  /* YYR1[YYN] -- Symbol number of symbol that rule YYN derives.  */
static const yytype_uint16 yyr1[] =
{
       0,   175,   176,   177,   177,   177,   177,   177,   178,   179,
     179,   179,   179,   180,   180,   181,   181,   181,   181,   181,
     181,   181,   181,   181,   181,   181,   181,   181,   181,   181,
     182,   182,   182,   182,   182,   182,   182,   182,   182,   182,
     182,   182,   182,   182,   182,   182,   182,   182,   182,   182,
     182,   182,   182,   182,   182,   182,   182,   182,   182,   182,
     182,   182,   182,   182,   182,   182,   182,   182,   182,   182,
     182,   182,   182,   182,   182,   182,   182,   182,   182,   182,
     182,   182,   182,   182,   182,   182,   182,   182,   182,   182,
     182,   182,   182,   182,   182,   182,   182,   182,   182,   182,
     182,   182,   182,   182,   182,   182,   182,   182,   182,   182,
     182,   182,   183,   183,   183,   184,   184,   184,   185,   185,
     185,   185,   185,   185,   185,   185,   185,   185,   185,   185,
     185,   185,   185,   185,   185,   185,   185,   185,   186,   187,
     188,   189,   190,   191,   191,   192,   193,   193,   193,   193,
     193,   193,   193,   193,   193,   193,   193,   193,   193,   193,
     193,   193,   193,   194,   195,   196,   197,   197,   198,   199,
     200,   200,   201,   202,   203,   204,   205,   206,   207,   208,
     209,   210,   211,   212,   213,   214,   215,   216,   217,   217,
     218,   219,   219,   220,   220,   220,   221,   222,   222,   223,
     224,   225,   226,   226,   227,   228,   229,   230,   231,   232,
     233,   234,   235,   236,   237,   238,   238,   239,   239,   239,
     240,   240,   241,   241,   241,   241,   242,   242,   243,   244,
     244,   245,   245,   246,   246,   247,   248,   249,   250,   250,
     251,   251,   252,   253,   254,   255,   256,   257,   258,   259,
     260,   261,   261,   262,   262,   263,   263,   264,   265,   265,
     266,   266,   266,   266,   266,   266,   267,   267,   268,   268,
     269,   269,   270,   271,   271,   271,   271,   271,   271,   271,
     271,   271,   271,   271,   271,   271,   271,   272,   272,   273,
     274,   274,   275,   275,   276,   276,   276,   276,   276,   276,
     276,   276,   276,   276,   277,   278,   279,   280,   281,   282,
     283,   284,   285,   286,   287,   287,   288,   288,   289,   289,
     290,   291,   291,   292,   292,   293,   293,   293,   294,   294,
     295,   295,   295,   295,   296,   297
};

  /* YYR2[YYN] -- Number of symbols on the right hand side of rule YYN.  */
static const yytype_uint8 yyr2[] =
{
       0,     2,     1,     0,     1,     1,     2,     2,     1,     2,
       2,     3,     3,     1,     2,     5,     3,     5,     3,     5,
       3,     5,     3,     5,     5,     3,     3,     2,     2,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     3,     3,     3,     1,     1,
       1,     1,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     1,     1,
       1,     1,     1,     1,     2,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     2,
       2,     2,     2,    10,     3,     3,     3,     3,     3,     3,
       3,     3,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     4,     1,     2,
       4,     1,     2,     1,     1,     1,     4,     1,     2,     1,
       4,     4,     1,     2,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     2,     3,     5,     3,     8,     6,     6,
       1,     2,     4,     2,     2,     3,     3,     3,     2,     5,
       5,     5,     5,     3,     3,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     5,     3,
       5,     6,     4,     5,     3,     4,     5,     3,     2,     3,
       5,     4,     1,     5,     5,     5,     5,     5,     5,     5,
       5,     5,     5,     9,     8,     4,     3,     2,     1,     4,
       4,     8,     1,     2,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     1,     3,     1,     1,     1,     3,
       5,     1,     2,     1,     1,     0,     1,     5,     1,     2,
       1,     1,     1,     1,     2,     2
};


#define yyerrok         (yyerrstatus = 0)
#define yyclearin       (yychar = YYEMPTY)
#define YYEMPTY         (-2)
#define YYEOF           0

#define YYACCEPT        goto yyacceptlab
#define YYABORT         goto yyabortlab
#define YYERROR         goto yyerrorlab


#define YYRECOVERING()  (!!yyerrstatus)

#define YYBACKUP(Token, Value)                                    \
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
        yyerror (ret_str, YY_("syntax error: cannot back up")); \
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
                  Type, Value, ret_str); \
      YYFPRINTF (stderr, "\n");                                           \
    }                                                                     \
} while (0)


/*-----------------------------------.
| Print this symbol's value on YYO.  |
`-----------------------------------*/

static void
yy_symbol_value_print (FILE *yyo, int yytype, YYSTYPE const * const yyvaluep, char **ret_str)
{
  FILE *yyoutput = yyo;
  YYUSE (yyoutput);
  YYUSE (ret_str);
  if (!yyvaluep)
    return;
# ifdef YYPRINT
  if (yytype < YYNTOKENS)
    YYPRINT (yyo, yytoknum[yytype], *yyvaluep);
# endif
  YYUSE (yytype);
}


/*---------------------------.
| Print this symbol on YYO.  |
`---------------------------*/

static void
yy_symbol_print (FILE *yyo, int yytype, YYSTYPE const * const yyvaluep, char **ret_str)
{
  YYFPRINTF (yyo, "%s %s (",
             yytype < YYNTOKENS ? "token" : "nterm", yytname[yytype]);

  yy_symbol_value_print (yyo, yytype, yyvaluep, ret_str);
  YYFPRINTF (yyo, ")");
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
yy_reduce_print (yytype_int16 *yyssp, YYSTYPE *yyvsp, int yyrule, char **ret_str)
{
  unsigned long yylno = yyrline[yyrule];
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
                       &yyvsp[(yyi + 1) - (yynrhs)]
                                              , ret_str);
      YYFPRINTF (stderr, "\n");
    }
}

# define YY_REDUCE_PRINT(Rule)          \
do {                                    \
  if (yydebug)                          \
    yy_reduce_print (yyssp, yyvsp, Rule, ret_str); \
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
            else
              goto append;

          append:
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

  return (YYSIZE_T) (yystpcpy (yyres, yystr) - yyres);
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
                  if (yysize <= yysize1 && yysize1 <= YYSTACK_ALLOC_MAXIMUM)
                    yysize = yysize1;
                  else
                    return 2;
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
    if (yysize <= yysize1 && yysize1 <= YYSTACK_ALLOC_MAXIMUM)
      yysize = yysize1;
    else
      return 2;
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
yydestruct (const char *yymsg, int yytype, YYSTYPE *yyvaluep, char **ret_str)
{
  YYUSE (yyvaluep);
  YYUSE (ret_str);
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
yyparse (char **ret_str)
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
| yynewstate -- push a new state, which is found in yystate.  |
`------------------------------------------------------------*/
yynewstate:
  /* In all cases, when you get here, the value and location stacks
     have just been pushed.  So pushing a state here evens the stacks.  */
  yyssp++;


/*--------------------------------------------------------------------.
| yynewstate -- set current state (the top of the stack) to yystate.  |
`--------------------------------------------------------------------*/
yysetstate:
  *yyssp = (yytype_int16) yystate;

  if (yyss + yystacksize - 1 <= yyssp)
#if !defined yyoverflow && !defined YYSTACK_RELOCATE
    goto yyexhaustedlab;
#else
    {
      /* Get the current used size of the three stacks, in elements.  */
      YYSIZE_T yysize = (YYSIZE_T) (yyssp - yyss + 1);

# if defined yyoverflow
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
# else /* defined YYSTACK_RELOCATE */
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
# undef YYSTACK_RELOCATE
        if (yyss1 != yyssa)
          YYSTACK_FREE (yyss1);
      }
# endif

      yyssp = yyss + yysize - 1;
      yyvsp = yyvs + yysize - 1;

      YYDPRINTF ((stderr, "Stack size increased to %lu\n",
                  (unsigned long) yystacksize));

      if (yyss + yystacksize - 1 <= yyssp)
        YYABORT;
    }
#endif /* !defined yyoverflow && !defined YYSTACK_RELOCATE */

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
| yyreduce -- do a reduction.  |
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
#line 287 "itex2MML.y" /* yacc.c:1652  */
    {/* all processing done in body*/}
#line 3237 "y.tab.c" /* yacc.c:1652  */
    break;

  case 3:
#line 290 "itex2MML.y" /* yacc.c:1652  */
    {/* nothing - do nothing*/}
#line 3243 "y.tab.c" /* yacc.c:1652  */
    break;

  case 4:
#line 291 "itex2MML.y" /* yacc.c:1652  */
    {/* proc done in body*/}
#line 3249 "y.tab.c" /* yacc.c:1652  */
    break;

  case 5:
#line 292 "itex2MML.y" /* yacc.c:1652  */
    {/* all proc. in body*/}
#line 3255 "y.tab.c" /* yacc.c:1652  */
    break;

  case 6:
#line 293 "itex2MML.y" /* yacc.c:1652  */
    {/* all proc. in body*/}
#line 3261 "y.tab.c" /* yacc.c:1652  */
    break;

  case 7:
#line 294 "itex2MML.y" /* yacc.c:1652  */
    {/* all proc. in body*/}
#line 3267 "y.tab.c" /* yacc.c:1652  */
    break;

  case 8:
#line 296 "itex2MML.y" /* yacc.c:1652  */
    {printf("%s", yyvsp[0]);}
#line 3273 "y.tab.c" /* yacc.c:1652  */
    break;

  case 9:
#line 298 "itex2MML.y" /* yacc.c:1652  */
    {/* empty math group - ignore*/}
#line 3279 "y.tab.c" /* yacc.c:1652  */
    break;

  case 10:
#line 299 "itex2MML.y" /* yacc.c:1652  */
    {/* ditto */}
#line 3285 "y.tab.c" /* yacc.c:1652  */
    break;

  case 11:
#line 300 "itex2MML.y" /* yacc.c:1652  */
    {
  char ** r = (char **) ret_str;
  char * p = itex2MML_copy3("<math xmlns='http://www.w3.org/1998/Math/MathML' display='inline'><semantics><mrow>", yyvsp[-1], "</mrow><annotation encoding='application/x-tex'>");
  char * s = itex2MML_copy3(p, yyvsp[0], "</annotation></semantics></math>");
  itex2MML_free_string(p);
  itex2MML_free_string(yyvsp[-1]);  
  itex2MML_free_string(yyvsp[0]);
  if (r) {
    (*r) = (s == itex2MML_empty_string) ? 0 : s;
  }
  else {
    if (itex2MML_write_mathml)
      (*itex2MML_write_mathml) (s);
    itex2MML_free_string(s);
  }
}
#line 3306 "y.tab.c" /* yacc.c:1652  */
    break;

  case 12:
#line 316 "itex2MML.y" /* yacc.c:1652  */
    {
  char ** r = (char **) ret_str;
  char * p = itex2MML_copy3("<math xmlns='http://www.w3.org/1998/Math/MathML' display='block'><semantics><mrow>", yyvsp[-1], "</mrow><annotation encoding='application/x-tex'>");
  char * s = itex2MML_copy3(p, yyvsp[0], "</annotation></semantics></math>");
  itex2MML_free_string(p);
  itex2MML_free_string(yyvsp[-1]);  
  itex2MML_free_string(yyvsp[0]);
  if (r) {
    (*r) = (s == itex2MML_empty_string) ? 0 : s;
  }
  else {
    if (itex2MML_write_mathml)
      (*itex2MML_write_mathml) (s);
    itex2MML_free_string(s);
  }
}
#line 3327 "y.tab.c" /* yacc.c:1652  */
    break;

  case 13:
#line 333 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy_string(yyvsp[0]);
  itex2MML_free_string(yyvsp[0]);
}
#line 3336 "y.tab.c" /* yacc.c:1652  */
    break;

  case 14:
#line 337 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy2(yyvsp[-1], yyvsp[0]);
  itex2MML_free_string(yyvsp[-1]);
  itex2MML_free_string(yyvsp[0]);
}
#line 3346 "y.tab.c" /* yacc.c:1652  */
    break;

  case 15:
#line 343 "itex2MML.y" /* yacc.c:1652  */
    {
  if (itex2MML_displaymode == 1) {
    char * s1 = itex2MML_copy3("<munderover>", yyvsp[-4], " ");
    char * s2 = itex2MML_copy3(yyvsp[-2], " ", yyvsp[0]);
    yyval = itex2MML_copy3(s1, s2, "</munderover>");
    itex2MML_free_string(s1);
    itex2MML_free_string(s2);
  }
  else {
    char * s1 = itex2MML_copy3("<msubsup>", yyvsp[-4], " ");
    char * s2 = itex2MML_copy3(yyvsp[-2], " ", yyvsp[0]);
    yyval = itex2MML_copy3(s1, s2, "</msubsup>");
    itex2MML_free_string(s1);
    itex2MML_free_string(s2);
  }
  itex2MML_free_string(yyvsp[-4]);
  itex2MML_free_string(yyvsp[-2]);
  itex2MML_free_string(yyvsp[0]);
}
#line 3370 "y.tab.c" /* yacc.c:1652  */
    break;

  case 16:
#line 362 "itex2MML.y" /* yacc.c:1652  */
    {
  if (itex2MML_displaymode == 1) {
    char * s1 = itex2MML_copy3("<munder>", yyvsp[-2], " ");
    yyval = itex2MML_copy3(s1, yyvsp[0], "</munder>");
    itex2MML_free_string(s1);
  }
  else {
    char * s1 = itex2MML_copy3("<msub>", yyvsp[-2], " ");
    yyval = itex2MML_copy3(s1, yyvsp[0], "</msub>");
    itex2MML_free_string(s1);
  }
  itex2MML_free_string(yyvsp[-2]);
  itex2MML_free_string(yyvsp[0]);
}
#line 3389 "y.tab.c" /* yacc.c:1652  */
    break;

  case 17:
#line 376 "itex2MML.y" /* yacc.c:1652  */
    {
  if (itex2MML_displaymode == 1) {
    char * s1 = itex2MML_copy3("<munderover>", yyvsp[-4], " ");
    char * s2 = itex2MML_copy3(yyvsp[0], " ", yyvsp[-2]);
    yyval = itex2MML_copy3(s1, s2, "</munderover>");
    itex2MML_free_string(s1);
    itex2MML_free_string(s2);
  }
  else {
    char * s1 = itex2MML_copy3("<msubsup>", yyvsp[-4], " ");
    char * s2 = itex2MML_copy3(yyvsp[0], " ", yyvsp[-2]);
    yyval = itex2MML_copy3(s1, s2, "</msubsup>");
    itex2MML_free_string(s1);
    itex2MML_free_string(s2);
  }
  itex2MML_free_string(yyvsp[-4]);
  itex2MML_free_string(yyvsp[-2]);
  itex2MML_free_string(yyvsp[0]);
}
#line 3413 "y.tab.c" /* yacc.c:1652  */
    break;

  case 18:
#line 395 "itex2MML.y" /* yacc.c:1652  */
    {
  if (itex2MML_displaymode == 1) {
    char * s1 = itex2MML_copy3("<mover>", yyvsp[-2], " ");
    yyval = itex2MML_copy3(s1, yyvsp[0], "</mover>");
    itex2MML_free_string(s1);
  }
  else {
    char * s1 = itex2MML_copy3("<msup>", yyvsp[-2], " ");
    yyval = itex2MML_copy3(s1, yyvsp[0], "</msup>");
    itex2MML_free_string(s1);
  }
  itex2MML_free_string(yyvsp[-2]);
  itex2MML_free_string(yyvsp[0]);
}
#line 3432 "y.tab.c" /* yacc.c:1652  */
    break;

  case 19:
#line 409 "itex2MML.y" /* yacc.c:1652  */
    {
  if (itex2MML_displaymode == 1) {
    char * s1 = itex2MML_copy3("<munderover>", yyvsp[-4], " ");
    char * s2 = itex2MML_copy3(yyvsp[-2], " ", yyvsp[0]);
    yyval = itex2MML_copy3(s1, s2, "</munderover>");
    itex2MML_free_string(s1);
    itex2MML_free_string(s2);
  }
  else {
    char * s1 = itex2MML_copy3("<msubsup>", yyvsp[-4], " ");
    char * s2 = itex2MML_copy3(yyvsp[-2], " ", yyvsp[0]);
    yyval = itex2MML_copy3(s1, s2, "</msubsup>");
    itex2MML_free_string(s1);
    itex2MML_free_string(s2);
  }
  itex2MML_free_string(yyvsp[-4]);
  itex2MML_free_string(yyvsp[-2]);
  itex2MML_free_string(yyvsp[0]);
}
#line 3456 "y.tab.c" /* yacc.c:1652  */
    break;

  case 20:
#line 428 "itex2MML.y" /* yacc.c:1652  */
    {
  if (itex2MML_displaymode == 1) {
    char * s1 = itex2MML_copy3("<munder>", yyvsp[-2], " ");
    yyval = itex2MML_copy3(s1, yyvsp[0], "</munder>");
    itex2MML_free_string(s1);
  }
  else {
    char * s1 = itex2MML_copy3("<msub>", yyvsp[-2], " ");
    yyval = itex2MML_copy3(s1, yyvsp[0], "</msub>");
    itex2MML_free_string(s1);
  }
  itex2MML_free_string(yyvsp[-2]);
  itex2MML_free_string(yyvsp[0]);
}
#line 3475 "y.tab.c" /* yacc.c:1652  */
    break;

  case 21:
#line 442 "itex2MML.y" /* yacc.c:1652  */
    {
  if (itex2MML_displaymode == 1) {
    char * s1 = itex2MML_copy3("<munderover>", yyvsp[-4], " ");
    char * s2 = itex2MML_copy3(yyvsp[0], " ", yyvsp[-2]);
    yyval = itex2MML_copy3(s1, s2, "</munderover>");
    itex2MML_free_string(s1);
    itex2MML_free_string(s2);
  }
  else {
    char * s1 = itex2MML_copy3("<msubsup>", yyvsp[-4], " ");
    char * s2 = itex2MML_copy3(yyvsp[0], " ", yyvsp[-2]);
    yyval = itex2MML_copy3(s1, s2, "</msubsup>");
    itex2MML_free_string(s1);
    itex2MML_free_string(s2);
  }
  itex2MML_free_string(yyvsp[-4]);
  itex2MML_free_string(yyvsp[-2]);
  itex2MML_free_string(yyvsp[0]);
}
#line 3499 "y.tab.c" /* yacc.c:1652  */
    break;

  case 22:
#line 461 "itex2MML.y" /* yacc.c:1652  */
    {
  if (itex2MML_displaymode == 1) {
    char * s1 = itex2MML_copy3("<mover>", yyvsp[-2], " ");
    yyval = itex2MML_copy3(s1, yyvsp[0], "</mover>");
    itex2MML_free_string(s1);
  }
  else {
    char * s1 = itex2MML_copy3("<msup>", yyvsp[-2], " ");
    yyval = itex2MML_copy3(s1, yyvsp[0], "</msup>");
    itex2MML_free_string(s1);
  }
  itex2MML_free_string(yyvsp[-2]);
  itex2MML_free_string(yyvsp[0]);
}
#line 3518 "y.tab.c" /* yacc.c:1652  */
    break;

  case 23:
#line 475 "itex2MML.y" /* yacc.c:1652  */
    {
  char * s1 = itex2MML_copy3("<msubsup>", yyvsp[-4], " ");
  char * s2 = itex2MML_copy3(yyvsp[-2], " ", yyvsp[0]);
  yyval = itex2MML_copy3(s1, s2, "</msubsup>");
  itex2MML_free_string(s1);
  itex2MML_free_string(s2);
  itex2MML_free_string(yyvsp[-4]);
  itex2MML_free_string(yyvsp[-2]);
  itex2MML_free_string(yyvsp[0]);
}
#line 3533 "y.tab.c" /* yacc.c:1652  */
    break;

  case 24:
#line 485 "itex2MML.y" /* yacc.c:1652  */
    {
  char * s1 = itex2MML_copy3("<msubsup>", yyvsp[-4], " ");
  char * s2 = itex2MML_copy3(yyvsp[0], " ", yyvsp[-2]);
  yyval = itex2MML_copy3(s1, s2, "</msubsup>");
  itex2MML_free_string(s1);
  itex2MML_free_string(s2);
  itex2MML_free_string(yyvsp[-4]);
  itex2MML_free_string(yyvsp[-2]);
  itex2MML_free_string(yyvsp[0]);
}
#line 3548 "y.tab.c" /* yacc.c:1652  */
    break;

  case 25:
#line 495 "itex2MML.y" /* yacc.c:1652  */
    {
  char * s1 = itex2MML_copy3("<msub>", yyvsp[-2], " ");
  yyval = itex2MML_copy3(s1, yyvsp[0], "</msub>");
  itex2MML_free_string(s1);
  itex2MML_free_string(yyvsp[-2]);
  itex2MML_free_string(yyvsp[0]);
}
#line 3560 "y.tab.c" /* yacc.c:1652  */
    break;

  case 26:
#line 502 "itex2MML.y" /* yacc.c:1652  */
    {
  char * s1 = itex2MML_copy3("<msup>", yyvsp[-2], " ");
  yyval = itex2MML_copy3(s1, yyvsp[0], "</msup>");
  itex2MML_free_string(s1);
  itex2MML_free_string(yyvsp[-2]);
  itex2MML_free_string(yyvsp[0]);
}
#line 3572 "y.tab.c" /* yacc.c:1652  */
    break;

  case 27:
#line 509 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<msub><mo/>", yyvsp[0], "</msub>");
  itex2MML_free_string(yyvsp[0]);
}
#line 3581 "y.tab.c" /* yacc.c:1652  */
    break;

  case 28:
#line 513 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<msup><mo/>", yyvsp[0], "</msup>");
  itex2MML_free_string(yyvsp[0]);
}
#line 3590 "y.tab.c" /* yacc.c:1652  */
    break;

  case 29:
#line 517 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy_string(yyvsp[0]);
  itex2MML_free_string(yyvsp[0]);
}
#line 3599 "y.tab.c" /* yacc.c:1652  */
    break;

  case 34:
#line 526 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mi>", yyvsp[0], "</mi>");
  itex2MML_free_string(yyvsp[0]);
}
#line 3608 "y.tab.c" /* yacc.c:1652  */
    break;

  case 35:
#line 530 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mn>", yyvsp[0], "</mn>");
  itex2MML_free_string(yyvsp[0]);
}
#line 3617 "y.tab.c" /* yacc.c:1652  */
    break;

  case 105:
#line 603 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy_string(yyvsp[-1]);
  itex2MML_free_string(yyvsp[-1]);
}
#line 3626 "y.tab.c" /* yacc.c:1652  */
    break;

  case 106:
#line 607 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mrow>", yyvsp[-1], "</mrow>");
  itex2MML_free_string(yyvsp[-1]);
}
#line 3635 "y.tab.c" /* yacc.c:1652  */
    break;

  case 107:
#line 611 "itex2MML.y" /* yacc.c:1652  */
    {
  char * s1 = itex2MML_copy3("<mrow>", yyvsp[-2], yyvsp[-1]);
  yyval = itex2MML_copy3(s1, yyvsp[0], "</mrow>");
  itex2MML_free_string(s1);
  itex2MML_free_string(yyvsp[-2]);
  itex2MML_free_string(yyvsp[-1]);
  itex2MML_free_string(yyvsp[0]);
}
#line 3648 "y.tab.c" /* yacc.c:1652  */
    break;

  case 112:
#line 624 "itex2MML.y" /* yacc.c:1652  */
    {
  itex2MML_rowposn = 2;
  yyval = itex2MML_copy3("<mo>", yyvsp[0], "</mo>");
  itex2MML_free_string(yyvsp[0]);
}
#line 3658 "y.tab.c" /* yacc.c:1652  */
    break;

  case 113:
#line 629 "itex2MML.y" /* yacc.c:1652  */
    {
  itex2MML_rowposn = 2;
  yyval = itex2MML_copy3("<mo>", yyvsp[0], "</mo>");
  itex2MML_free_string(yyvsp[0]);
}
#line 3668 "y.tab.c" /* yacc.c:1652  */
    break;

  case 114:
#line 634 "itex2MML.y" /* yacc.c:1652  */
    {
  itex2MML_rowposn = 2;
  yyval = itex2MML_copy_string("");
  itex2MML_free_string(yyvsp[0]);
}
#line 3678 "y.tab.c" /* yacc.c:1652  */
    break;

  case 115:
#line 640 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mo>", yyvsp[0], "</mo>");
  itex2MML_free_string(yyvsp[0]);
}
#line 3687 "y.tab.c" /* yacc.c:1652  */
    break;

  case 116:
#line 644 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mo>", yyvsp[0], "</mo>");
  itex2MML_free_string(yyvsp[0]);
}
#line 3696 "y.tab.c" /* yacc.c:1652  */
    break;

  case 117:
#line 648 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy_string("");
  itex2MML_free_string(yyvsp[0]);
}
#line 3705 "y.tab.c" /* yacc.c:1652  */
    break;

  case 118:
#line 653 "itex2MML.y" /* yacc.c:1652  */
    {
  itex2MML_rowposn = 2;
  yyval = itex2MML_copy3("<mo maxsize=\"1.2em\" minsize=\"1.2em\">", yyvsp[0], "</mo>");
  itex2MML_free_string(yyvsp[0]);
}
#line 3715 "y.tab.c" /* yacc.c:1652  */
    break;

  case 119:
#line 658 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mo maxsize=\"1.2em\" minsize=\"1.2em\">", yyvsp[0], "</mo>");
  itex2MML_free_string(yyvsp[0]);
}
#line 3724 "y.tab.c" /* yacc.c:1652  */
    break;

  case 120:
#line 662 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mo maxsize=\"1.2em\" minsize=\"1.2em\">", yyvsp[0], "</mo>");
  itex2MML_free_string(yyvsp[0]);
}
#line 3733 "y.tab.c" /* yacc.c:1652  */
    break;

  case 121:
#line 666 "itex2MML.y" /* yacc.c:1652  */
    {
  itex2MML_rowposn = 2;
  yyval = itex2MML_copy3("<mo maxsize=\"1.8em\" minsize=\"1.8em\">", yyvsp[0], "</mo>");
  itex2MML_free_string(yyvsp[0]);
}
#line 3743 "y.tab.c" /* yacc.c:1652  */
    break;

  case 122:
#line 671 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mo maxsize=\"1.8em\" minsize=\"1.8em\">", yyvsp[0], "</mo>");
  itex2MML_free_string(yyvsp[0]);
}
#line 3752 "y.tab.c" /* yacc.c:1652  */
    break;

  case 123:
#line 675 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mo maxsize=\"1.8em\" minsize=\"1.8em\">", yyvsp[0], "</mo>");
  itex2MML_free_string(yyvsp[0]);
}
#line 3761 "y.tab.c" /* yacc.c:1652  */
    break;

  case 124:
#line 679 "itex2MML.y" /* yacc.c:1652  */
    {
  itex2MML_rowposn = 2;
  yyval = itex2MML_copy3("<mo maxsize=\"2.4em\" minsize=\"2.4em\">", yyvsp[0], "</mo>");
  itex2MML_free_string(yyvsp[0]);
}
#line 3771 "y.tab.c" /* yacc.c:1652  */
    break;

  case 125:
#line 684 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mo maxsize=\"2.4em\" minsize=\"2.4em\">", yyvsp[0], "</mo>");
  itex2MML_free_string(yyvsp[0]);
}
#line 3780 "y.tab.c" /* yacc.c:1652  */
    break;

  case 126:
#line 688 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mo maxsize=\"2.4em\" minsize=\"2.4em\">", yyvsp[0], "</mo>");
  itex2MML_free_string(yyvsp[0]);
}
#line 3789 "y.tab.c" /* yacc.c:1652  */
    break;

  case 127:
#line 692 "itex2MML.y" /* yacc.c:1652  */
    {
  itex2MML_rowposn = 2;
  yyval = itex2MML_copy3("<mo maxsize=\"3em\" minsize=\"3em\">", yyvsp[0], "</mo>");
  itex2MML_free_string(yyvsp[0]);
}
#line 3799 "y.tab.c" /* yacc.c:1652  */
    break;

  case 128:
#line 697 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mo maxsize=\"3em\" minsize=\"3em\">", yyvsp[0], "</mo>");
  itex2MML_free_string(yyvsp[0]);
}
#line 3808 "y.tab.c" /* yacc.c:1652  */
    break;

  case 129:
#line 701 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mo maxsize=\"3em\" minsize=\"3em\">", yyvsp[0], "</mo>");
  itex2MML_free_string(yyvsp[0]);
}
#line 3817 "y.tab.c" /* yacc.c:1652  */
    break;

  case 130:
#line 705 "itex2MML.y" /* yacc.c:1652  */
    {
  itex2MML_rowposn = 2;
  yyval = itex2MML_copy3("<mo maxsize=\"1.2em\" minsize=\"1.2em\">", yyvsp[0], "</mo>");
  itex2MML_free_string(yyvsp[0]);
}
#line 3827 "y.tab.c" /* yacc.c:1652  */
    break;

  case 131:
#line 710 "itex2MML.y" /* yacc.c:1652  */
    {
  itex2MML_rowposn = 2;
  yyval = itex2MML_copy3("<mo maxsize=\"1.2em\" minsize=\"1.2em\">", yyvsp[0], "</mo>");
  itex2MML_free_string(yyvsp[0]);
}
#line 3837 "y.tab.c" /* yacc.c:1652  */
    break;

  case 132:
#line 715 "itex2MML.y" /* yacc.c:1652  */
    {
  itex2MML_rowposn = 2;
  yyval = itex2MML_copy3("<mo maxsize=\"1.8em\" minsize=\"1.8em\">", yyvsp[0], "</mo>");
  itex2MML_free_string(yyvsp[0]);
}
#line 3847 "y.tab.c" /* yacc.c:1652  */
    break;

  case 133:
#line 720 "itex2MML.y" /* yacc.c:1652  */
    {
  itex2MML_rowposn = 2;
  yyval = itex2MML_copy3("<mo maxsize=\"1.8em\" minsize=\"1.8em\">", yyvsp[0], "</mo>");
  itex2MML_free_string(yyvsp[0]);
}
#line 3857 "y.tab.c" /* yacc.c:1652  */
    break;

  case 134:
#line 725 "itex2MML.y" /* yacc.c:1652  */
    {
  itex2MML_rowposn = 2;
  yyval = itex2MML_copy3("<mo maxsize=\"2.4em\" minsize=\"2.4em\">", yyvsp[0], "</mo>");
  itex2MML_free_string(yyvsp[0]);
}
#line 3867 "y.tab.c" /* yacc.c:1652  */
    break;

  case 135:
#line 730 "itex2MML.y" /* yacc.c:1652  */
    {
  itex2MML_rowposn = 2;
  yyval = itex2MML_copy3("<mo maxsize=\"2.4em\" minsize=\"2.4em\">", yyvsp[0], "</mo>");
  itex2MML_free_string(yyvsp[0]);
}
#line 3877 "y.tab.c" /* yacc.c:1652  */
    break;

  case 136:
#line 735 "itex2MML.y" /* yacc.c:1652  */
    {
  itex2MML_rowposn = 2;
  yyval = itex2MML_copy3("<mo maxsize=\"3em\" minsize=\"3em\">", yyvsp[0], "</mo>");
  itex2MML_free_string(yyvsp[0]);
}
#line 3887 "y.tab.c" /* yacc.c:1652  */
    break;

  case 137:
#line 740 "itex2MML.y" /* yacc.c:1652  */
    {
  itex2MML_rowposn = 2;
  yyval = itex2MML_copy3("<mo maxsize=\"3em\" minsize=\"3em\">", yyvsp[0], "</mo>");
  itex2MML_free_string(yyvsp[0]);
}
#line 3897 "y.tab.c" /* yacc.c:1652  */
    break;

  case 138:
#line 746 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy_string("<merror><mtext>Unknown character</mtext></merror>");
}
#line 3905 "y.tab.c" /* yacc.c:1652  */
    break;

  case 139:
#line 750 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy_string("<mo lspace=\"0.11111em\" rspace=\"0em\">&minus;</mo>");
}
#line 3913 "y.tab.c" /* yacc.c:1652  */
    break;

  case 140:
#line 754 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy_string("<mo lspace=\"0.11111em\" rspace=\"0em\">+</mo>");
}
#line 3921 "y.tab.c" /* yacc.c:1652  */
    break;

  case 142:
#line 760 "itex2MML.y" /* yacc.c:1652  */
    {
  itex2MML_rowposn=2;
  yyval = itex2MML_copy3("<mi>", yyvsp[0], "</mi>");
  itex2MML_free_string(yyvsp[0]);
}
#line 3931 "y.tab.c" /* yacc.c:1652  */
    break;

  case 144:
#line 767 "itex2MML.y" /* yacc.c:1652  */
    {
  itex2MML_rowposn = 2;
  yyval = itex2MML_copy_string(yyvsp[0]);
  itex2MML_free_string(yyvsp[0]);
}
#line 3941 "y.tab.c" /* yacc.c:1652  */
    break;

  case 145:
#line 773 "itex2MML.y" /* yacc.c:1652  */
    {
  itex2MML_rowposn = 2;
  yyval = itex2MML_copy3("<mo lspace=\"0.16667em\" rspace=\"0.16667em\">", yyvsp[0], "</mo>");
  itex2MML_free_string(yyvsp[0]);
}
#line 3951 "y.tab.c" /* yacc.c:1652  */
    break;

  case 148:
#line 781 "itex2MML.y" /* yacc.c:1652  */
    {
  itex2MML_rowposn = 2;
  yyval = itex2MML_copy3("<mo>", yyvsp[0], "</mo>");
  itex2MML_free_string(yyvsp[0]);
}
#line 3961 "y.tab.c" /* yacc.c:1652  */
    break;

  case 149:
#line 786 "itex2MML.y" /* yacc.c:1652  */
    {
  itex2MML_rowposn = 2;
  yyval = itex2MML_copy3("<mo>", yyvsp[0], "</mo>");
  itex2MML_free_string(yyvsp[0]);
}
#line 3971 "y.tab.c" /* yacc.c:1652  */
    break;

  case 150:
#line 791 "itex2MML.y" /* yacc.c:1652  */
    {
  itex2MML_rowposn = 2;
  yyval = itex2MML_copy3("<mstyle scriptlevel=\"0\"><mo>", yyvsp[0], "</mo></mstyle>");
  itex2MML_free_string(yyvsp[0]);
}
#line 3981 "y.tab.c" /* yacc.c:1652  */
    break;

  case 151:
#line 796 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mo stretchy=\"false\">", yyvsp[0], "</mo>");
  itex2MML_free_string(yyvsp[0]);
}
#line 3990 "y.tab.c" /* yacc.c:1652  */
    break;

  case 152:
#line 800 "itex2MML.y" /* yacc.c:1652  */
    {
  itex2MML_rowposn = 2;
  yyval = itex2MML_copy3("<mo stretchy=\"false\">", yyvsp[0], "</mo>");
  itex2MML_free_string(yyvsp[0]);
}
#line 4000 "y.tab.c" /* yacc.c:1652  */
    break;

  case 153:
#line 805 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mo stretchy=\"false\">", yyvsp[0], "</mo>");
  itex2MML_free_string(yyvsp[0]);
}
#line 4009 "y.tab.c" /* yacc.c:1652  */
    break;

  case 154:
#line 809 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mo stretchy=\"false\">", yyvsp[0], "</mo>");
  itex2MML_free_string(yyvsp[0]);
}
#line 4018 "y.tab.c" /* yacc.c:1652  */
    break;

  case 155:
#line 813 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mo>", yyvsp[0], "</mo>");
  itex2MML_free_string(yyvsp[0]);
}
#line 4027 "y.tab.c" /* yacc.c:1652  */
    break;

  case 156:
#line 817 "itex2MML.y" /* yacc.c:1652  */
    {
  itex2MML_rowposn=2;
  yyval = itex2MML_copy3("<mo lspace=\"0.22222em\" rspace=\"0.22222em\">", yyvsp[0], "</mo>");
  itex2MML_free_string(yyvsp[0]);
}
#line 4037 "y.tab.c" /* yacc.c:1652  */
    break;

  case 157:
#line 822 "itex2MML.y" /* yacc.c:1652  */
    {
  itex2MML_rowposn = 2;
  yyval = itex2MML_copy3("<mo lspace=\"0em\" rspace=\"0.16667em\">", yyvsp[0], "</mo>");
  itex2MML_free_string(yyvsp[0]);
}
#line 4047 "y.tab.c" /* yacc.c:1652  */
    break;

  case 158:
#line 827 "itex2MML.y" /* yacc.c:1652  */
    {
  itex2MML_rowposn = 2;
  yyval = itex2MML_copy3("<mo lspace=\"0.11111em\">", yyvsp[0], "</mo>");
  itex2MML_free_string(yyvsp[0]);
}
#line 4057 "y.tab.c" /* yacc.c:1652  */
    break;

  case 159:
#line 832 "itex2MML.y" /* yacc.c:1652  */
    {
  itex2MML_rowposn = 2;
  yyval = itex2MML_copy3("<mo lspace=\"0em\" rspace=\"0.16667em\">", yyvsp[0], "</mo>");
  itex2MML_free_string(yyvsp[0]);
}
#line 4067 "y.tab.c" /* yacc.c:1652  */
    break;

  case 160:
#line 837 "itex2MML.y" /* yacc.c:1652  */
    {
  itex2MML_rowposn = 2;
  yyval = itex2MML_copy3("<mo lspace=\"0.16667em\" rspace=\"0.16667em\">", yyvsp[0], "</mo>");
  itex2MML_free_string(yyvsp[0]);
}
#line 4077 "y.tab.c" /* yacc.c:1652  */
    break;

  case 161:
#line 842 "itex2MML.y" /* yacc.c:1652  */
    {
  itex2MML_rowposn = 2;
  yyval = itex2MML_copy3("<mo lspace=\"0.22222em\" rspace=\"0.22222em\">", yyvsp[0], "</mo>");
  itex2MML_free_string(yyvsp[0]);
}
#line 4087 "y.tab.c" /* yacc.c:1652  */
    break;

  case 162:
#line 847 "itex2MML.y" /* yacc.c:1652  */
    {
  itex2MML_rowposn = 2;
  yyval = itex2MML_copy3("<mo lspace=\"0.27778em\" rspace=\"0.27778em\">", yyvsp[0], "</mo>");
  itex2MML_free_string(yyvsp[0]);
}
#line 4097 "y.tab.c" /* yacc.c:1652  */
    break;

  case 163:
#line 853 "itex2MML.y" /* yacc.c:1652  */
    {
  char * s1 = itex2MML_copy3("<mspace height=\"", yyvsp[-7], "ex\" depth=\"");
  char * s2 = itex2MML_copy3(yyvsp[-4], "ex\" width=\"", yyvsp[-1]);
  yyval = itex2MML_copy3(s1, s2, "em\"/>");
  itex2MML_free_string(s1);
  itex2MML_free_string(s2);
  itex2MML_free_string(yyvsp[-7]);
  itex2MML_free_string(yyvsp[-4]);
  itex2MML_free_string(yyvsp[-1]);
}
#line 4112 "y.tab.c" /* yacc.c:1652  */
    break;

  case 164:
#line 864 "itex2MML.y" /* yacc.c:1652  */
    {
  char * s1 = itex2MML_copy3("<maction actiontype=\"statusline\">", yyvsp[0], "<mtext>");
  yyval = itex2MML_copy3(s1, yyvsp[-1], "</mtext></maction>");
  itex2MML_free_string(s1);
  itex2MML_free_string(yyvsp[-1]);
  itex2MML_free_string(yyvsp[0]);
}
#line 4124 "y.tab.c" /* yacc.c:1652  */
    break;

  case 165:
#line 872 "itex2MML.y" /* yacc.c:1652  */
    {
  char * s1 = itex2MML_copy3("<maction actiontype=\"tooltip\">", yyvsp[0], "<mtext>");
  yyval = itex2MML_copy3(s1, yyvsp[-1], "</mtext></maction>");
  itex2MML_free_string(s1);
  itex2MML_free_string(yyvsp[-1]);
  itex2MML_free_string(yyvsp[0]);
}
#line 4136 "y.tab.c" /* yacc.c:1652  */
    break;

  case 166:
#line 880 "itex2MML.y" /* yacc.c:1652  */
    {
  char * s1 = itex2MML_copy3("<maction actiontype=\"toggle\" selection=\"2\">", yyvsp[-1], " ");
  yyval = itex2MML_copy3(s1, yyvsp[0], "</maction>");
  itex2MML_free_string(s1);
  itex2MML_free_string(yyvsp[-1]);
  itex2MML_free_string(yyvsp[0]);
}
#line 4148 "y.tab.c" /* yacc.c:1652  */
    break;

  case 167:
#line 887 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<maction actiontype=\"toggle\">", yyvsp[-1], "</maction>");
  itex2MML_free_string(yyvsp[-1]);
}
#line 4157 "y.tab.c" /* yacc.c:1652  */
    break;

  case 168:
#line 892 "itex2MML.y" /* yacc.c:1652  */
    {
  char * s1 = itex2MML_copy3("<maction actiontype=\"highlight\" other='color=", yyvsp[-1], "'>");
  yyval = itex2MML_copy3(s1, yyvsp[0], "</maction>");
  itex2MML_free_string(s1);
  itex2MML_free_string(yyvsp[-1]);
  itex2MML_free_string(yyvsp[0]);
}
#line 4169 "y.tab.c" /* yacc.c:1652  */
    break;

  case 169:
#line 900 "itex2MML.y" /* yacc.c:1652  */
    {
  char * s1 = itex2MML_copy3("<maction actiontype=\"highlight\" other='background=", yyvsp[-1], "'>");
  yyval = itex2MML_copy3(s1, yyvsp[0], "</maction>");
  itex2MML_free_string(s1);
  itex2MML_free_string(yyvsp[-1]);
  itex2MML_free_string(yyvsp[0]);
}
#line 4181 "y.tab.c" /* yacc.c:1652  */
    break;

  case 170:
#line 908 "itex2MML.y" /* yacc.c:1652  */
    {
  char * s1 = itex2MML_copy3("<mstyle mathcolor=", yyvsp[-1], ">");
  yyval = itex2MML_copy3(s1, yyvsp[0], "</mstyle>");
  itex2MML_free_string(s1);
  itex2MML_free_string(yyvsp[-1]);
  itex2MML_free_string(yyvsp[0]);
}
#line 4193 "y.tab.c" /* yacc.c:1652  */
    break;

  case 171:
#line 915 "itex2MML.y" /* yacc.c:1652  */
    {
  char * s1 = itex2MML_copy3("<mstyle mathbackground=", yyvsp[-1], ">");
  yyval = itex2MML_copy3(s1, yyvsp[0], "</mstyle>");
  itex2MML_free_string(s1);
  itex2MML_free_string(yyvsp[-1]);
  itex2MML_free_string(yyvsp[0]);
}
#line 4205 "y.tab.c" /* yacc.c:1652  */
    break;

  case 172:
#line 923 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mpadded width=\"0px\">", yyvsp[0], "</mpadded>");
  itex2MML_free_string(yyvsp[0]);
}
#line 4214 "y.tab.c" /* yacc.c:1652  */
    break;

  case 173:
#line 928 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mpadded width=\"0px\" lspace=\"-100%width\">", yyvsp[0], "</mpadded>");
  itex2MML_free_string(yyvsp[0]);
}
#line 4223 "y.tab.c" /* yacc.c:1652  */
    break;

  case 174:
#line 933 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mpadded width=\"0px\" lspace=\"-50%width\">", yyvsp[0], "</mpadded>");
  itex2MML_free_string(yyvsp[0]);
}
#line 4232 "y.tab.c" /* yacc.c:1652  */
    break;

  case 175:
#line 938 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mtext>", yyvsp[0], "</mtext>");
  itex2MML_free_string(yyvsp[0]);
}
#line 4241 "y.tab.c" /* yacc.c:1652  */
    break;

  case 176:
#line 943 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mstyle displaystyle=\"true\">", yyvsp[0], "</mstyle>");
  itex2MML_free_string(yyvsp[0]);
}
#line 4250 "y.tab.c" /* yacc.c:1652  */
    break;

  case 177:
#line 948 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mstyle displaystyle=\"false\">", yyvsp[0], "</mstyle>");
  itex2MML_free_string(yyvsp[0]);
}
#line 4259 "y.tab.c" /* yacc.c:1652  */
    break;

  case 178:
#line 953 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mstyle scriptlevel=\"0\">", yyvsp[0], "</mstyle>");
  itex2MML_free_string(yyvsp[0]);
}
#line 4268 "y.tab.c" /* yacc.c:1652  */
    break;

  case 179:
#line 958 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mstyle scriptlevel=\"1\">", yyvsp[0], "</mstyle>");
  itex2MML_free_string(yyvsp[0]);
}
#line 4277 "y.tab.c" /* yacc.c:1652  */
    break;

  case 180:
#line 963 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mstyle scriptlevel=\"2\">", yyvsp[0], "</mstyle>");
  itex2MML_free_string(yyvsp[0]);
}
#line 4286 "y.tab.c" /* yacc.c:1652  */
    break;

  case 181:
#line 968 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mstyle mathvariant=\"italic\">", yyvsp[0], "</mstyle>");
  itex2MML_free_string(yyvsp[0]);
}
#line 4295 "y.tab.c" /* yacc.c:1652  */
    break;

  case 182:
#line 973 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mstyle mathvariant=\"sans-serif\">", yyvsp[0], "</mstyle>");
  itex2MML_free_string(yyvsp[0]);
}
#line 4304 "y.tab.c" /* yacc.c:1652  */
    break;

  case 183:
#line 978 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mstyle mathvariant=\"monospace\">", yyvsp[0], "</mstyle>");
  itex2MML_free_string(yyvsp[0]);
}
#line 4313 "y.tab.c" /* yacc.c:1652  */
    break;

  case 184:
#line 983 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<menclose notation=\"updiagonalstrike\">", yyvsp[0], "</menclose>");
  itex2MML_free_string(yyvsp[0]);
}
#line 4322 "y.tab.c" /* yacc.c:1652  */
    break;

  case 185:
#line 988 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<menclose notation=\"box\">", yyvsp[0], "</menclose>");
  itex2MML_free_string(yyvsp[0]);
}
#line 4331 "y.tab.c" /* yacc.c:1652  */
    break;

  case 186:
#line 993 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mstyle mathvariant=\"bold\">", yyvsp[0], "</mstyle>");
  itex2MML_free_string(yyvsp[0]);
}
#line 4340 "y.tab.c" /* yacc.c:1652  */
    break;

  case 187:
#line 998 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mi mathvariant=\"normal\">", yyvsp[-1], "</mi>");
  itex2MML_free_string(yyvsp[-1]);
}
#line 4349 "y.tab.c" /* yacc.c:1652  */
    break;

  case 188:
#line 1003 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy_string(yyvsp[0]);
  itex2MML_free_string(yyvsp[0]);
}
#line 4358 "y.tab.c" /* yacc.c:1652  */
    break;

  case 189:
#line 1007 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy2(yyvsp[-1], yyvsp[0]);
  itex2MML_free_string(yyvsp[-1]);
  itex2MML_free_string(yyvsp[0]);
}
#line 4368 "y.tab.c" /* yacc.c:1652  */
    break;

  case 190:
#line 1013 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mi>", yyvsp[-1], "</mi>");
  itex2MML_free_string(yyvsp[-1]);
}
#line 4377 "y.tab.c" /* yacc.c:1652  */
    break;

  case 191:
#line 1018 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy_string(yyvsp[0]);
  itex2MML_free_string(yyvsp[0]);
}
#line 4386 "y.tab.c" /* yacc.c:1652  */
    break;

  case 192:
#line 1022 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy2(yyvsp[-1], yyvsp[0]);
  itex2MML_free_string(yyvsp[-1]);
  itex2MML_free_string(yyvsp[0]);
}
#line 4396 "y.tab.c" /* yacc.c:1652  */
    break;

  case 193:
#line 1028 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("&", yyvsp[0], "opf;");
  itex2MML_free_string(yyvsp[0]);
}
#line 4405 "y.tab.c" /* yacc.c:1652  */
    break;

  case 194:
#line 1032 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("&", yyvsp[0], "opf;");
  itex2MML_free_string(yyvsp[0]);
}
#line 4414 "y.tab.c" /* yacc.c:1652  */
    break;

  case 195:
#line 1036 "itex2MML.y" /* yacc.c:1652  */
    {
  /* Blackboard digits 0-9 correspond to Unicode characters 0x1D7D8-0x1D7E1 */
  char * end = yyvsp[0] + 1;
  int code = 0x1D7D8 + strtoul(yyvsp[0], &end, 10);
  yyval = itex2MML_character_reference(code);
  itex2MML_free_string(yyvsp[0]);
}
#line 4426 "y.tab.c" /* yacc.c:1652  */
    break;

  case 196:
#line 1044 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mi>", yyvsp[-1], "</mi>");
  itex2MML_free_string(yyvsp[-1]);
}
#line 4435 "y.tab.c" /* yacc.c:1652  */
    break;

  case 197:
#line 1049 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy_string(yyvsp[0]);
  itex2MML_free_string(yyvsp[0]);
}
#line 4444 "y.tab.c" /* yacc.c:1652  */
    break;

  case 198:
#line 1053 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy2(yyvsp[-1], yyvsp[0]);
  itex2MML_free_string(yyvsp[-1]);
  itex2MML_free_string(yyvsp[0]);
}
#line 4454 "y.tab.c" /* yacc.c:1652  */
    break;

  case 199:
#line 1059 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("&", yyvsp[0], "fr;");
  itex2MML_free_string(yyvsp[0]);
}
#line 4463 "y.tab.c" /* yacc.c:1652  */
    break;

  case 200:
#line 1064 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mi>", yyvsp[-1], "</mi>");
  itex2MML_free_string(yyvsp[-1]);
}
#line 4472 "y.tab.c" /* yacc.c:1652  */
    break;

  case 201:
#line 1069 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mi class='mathscript'>", yyvsp[-1], "</mi>");
  itex2MML_free_string(yyvsp[-1]);
}
#line 4481 "y.tab.c" /* yacc.c:1652  */
    break;

  case 202:
#line 1074 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy_string(yyvsp[0]);
  itex2MML_free_string(yyvsp[0]);
}
#line 4490 "y.tab.c" /* yacc.c:1652  */
    break;

  case 203:
#line 1078 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy2(yyvsp[-1], yyvsp[0]);
  itex2MML_free_string(yyvsp[-1]);
  itex2MML_free_string(yyvsp[0]);
}
#line 4500 "y.tab.c" /* yacc.c:1652  */
    break;

  case 204:
#line 1084 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("&", yyvsp[0], "scr;");
  itex2MML_free_string(yyvsp[0]);
}
#line 4509 "y.tab.c" /* yacc.c:1652  */
    break;

  case 205:
#line 1089 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy_string("<mspace width=\"0.16667em\"/>");
}
#line 4517 "y.tab.c" /* yacc.c:1652  */
    break;

  case 206:
#line 1093 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy_string("<mspace width=\"0.22222em\"/>");
}
#line 4525 "y.tab.c" /* yacc.c:1652  */
    break;

  case 207:
#line 1097 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy_string("<mspace width=\"0.27778em\"/>");
}
#line 4533 "y.tab.c" /* yacc.c:1652  */
    break;

  case 208:
#line 1101 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy_string("<mspace width=\"1em\"/>");
}
#line 4541 "y.tab.c" /* yacc.c:1652  */
    break;

  case 209:
#line 1105 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy_string("<mspace width=\"2em\"/>");
}
#line 4549 "y.tab.c" /* yacc.c:1652  */
    break;

  case 210:
#line 1109 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy_string("<mspace width=\"-0.16667em\"/>");
}
#line 4557 "y.tab.c" /* yacc.c:1652  */
    break;

  case 211:
#line 1113 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy_string("<mspace width=\"-0.22222em\"/>");
}
#line 4565 "y.tab.c" /* yacc.c:1652  */
    break;

  case 212:
#line 1117 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy_string("<mspace width=\"-0.27778em\"/>");
}
#line 4573 "y.tab.c" /* yacc.c:1652  */
    break;

  case 213:
#line 1121 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mphantom>", yyvsp[0], "</mphantom>");
  itex2MML_free_string(yyvsp[0]);
}
#line 4582 "y.tab.c" /* yacc.c:1652  */
    break;

  case 214:
#line 1126 "itex2MML.y" /* yacc.c:1652  */
    {
  char * s1 = itex2MML_copy3("<mrow href=\"", yyvsp[-1], "\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" xlink:type=\"simple\" xlink:href=\"");
  char * s2 = itex2MML_copy3(s1, yyvsp[-1], "\">");
  yyval = itex2MML_copy3(s2, yyvsp[0], "</mrow>");
  itex2MML_free_string(s1);
  itex2MML_free_string(s2);
  itex2MML_free_string(yyvsp[-1]);
  itex2MML_free_string(yyvsp[0]);
}
#line 4596 "y.tab.c" /* yacc.c:1652  */
    break;

  case 215:
#line 1136 "itex2MML.y" /* yacc.c:1652  */
    {
  char * s1 = itex2MML_copy3("<mmultiscripts>", yyvsp[-3], yyvsp[-1]);
  yyval = itex2MML_copy2(s1, "</mmultiscripts>");
  itex2MML_free_string(s1);
  itex2MML_free_string(yyvsp[-3]);
  itex2MML_free_string(yyvsp[-1]);
}
#line 4608 "y.tab.c" /* yacc.c:1652  */
    break;

  case 216:
#line 1143 "itex2MML.y" /* yacc.c:1652  */
    {
  char * s1 = itex2MML_copy3("<mmultiscripts>", yyvsp[-1], yyvsp[0]);
  yyval = itex2MML_copy2(s1, "</mmultiscripts>");
  itex2MML_free_string(s1);
  itex2MML_free_string(yyvsp[-1]);
  itex2MML_free_string(yyvsp[0]);
}
#line 4620 "y.tab.c" /* yacc.c:1652  */
    break;

  case 217:
#line 1151 "itex2MML.y" /* yacc.c:1652  */
    {
  char * s1 = itex2MML_copy3("<mmultiscripts>", yyvsp[-3], yyvsp[-1]);
  char * s2 = itex2MML_copy3("<mprescripts/>", yyvsp[-5], "</mmultiscripts>");
  yyval = itex2MML_copy2(s1, s2);
  itex2MML_free_string(s1);
  itex2MML_free_string(s2);
  itex2MML_free_string(yyvsp[-5]);
  itex2MML_free_string(yyvsp[-3]);
  itex2MML_free_string(yyvsp[-1]);
}
#line 4635 "y.tab.c" /* yacc.c:1652  */
    break;

  case 218:
#line 1161 "itex2MML.y" /* yacc.c:1652  */
    {
  char * s1 = itex2MML_copy2("<mmultiscripts>", yyvsp[-1]);
  char * s2 = itex2MML_copy3("<mprescripts/>", yyvsp[-3], "</mmultiscripts>");
  yyval = itex2MML_copy2(s1, s2);
  itex2MML_free_string(s1);
  itex2MML_free_string(s2);
  itex2MML_free_string(yyvsp[-3]);
  itex2MML_free_string(yyvsp[-1]);
}
#line 4649 "y.tab.c" /* yacc.c:1652  */
    break;

  case 219:
#line 1170 "itex2MML.y" /* yacc.c:1652  */
    {
  char * s1 = itex2MML_copy3("<mmultiscripts>", yyvsp[-3], yyvsp[-1]);
  yyval = itex2MML_copy2(s1, "</mmultiscripts>");
  itex2MML_free_string(s1);
  itex2MML_free_string(yyvsp[-3]);
  itex2MML_free_string(yyvsp[-1]); 
}
#line 4661 "y.tab.c" /* yacc.c:1652  */
    break;

  case 220:
#line 1178 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy_string(yyvsp[0]);
  itex2MML_free_string(yyvsp[0]);
}
#line 4670 "y.tab.c" /* yacc.c:1652  */
    break;

  case 221:
#line 1182 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3(yyvsp[-1], " ", yyvsp[0]);
  itex2MML_free_string(yyvsp[-1]);
  itex2MML_free_string(yyvsp[0]);
}
#line 4680 "y.tab.c" /* yacc.c:1652  */
    break;

  case 222:
#line 1188 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3(yyvsp[-2], " ", yyvsp[0]);
  itex2MML_free_string(yyvsp[-2]);
  itex2MML_free_string(yyvsp[0]);
}
#line 4690 "y.tab.c" /* yacc.c:1652  */
    break;

  case 223:
#line 1193 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy2(yyvsp[0], " <none/>");
  itex2MML_free_string(yyvsp[0]);
}
#line 4699 "y.tab.c" /* yacc.c:1652  */
    break;

  case 224:
#line 1197 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy2("<none/> ", yyvsp[0]);
  itex2MML_free_string(yyvsp[0]);
}
#line 4708 "y.tab.c" /* yacc.c:1652  */
    break;

  case 225:
#line 1201 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy2("<none/> ", yyvsp[0]);
  itex2MML_free_string(yyvsp[0]);
}
#line 4717 "y.tab.c" /* yacc.c:1652  */
    break;

  case 226:
#line 1206 "itex2MML.y" /* yacc.c:1652  */
    {
  char * s1 = itex2MML_copy3("<mfrac>", yyvsp[-1], yyvsp[0]);
  yyval = itex2MML_copy2(s1, "</mfrac>");
  itex2MML_free_string(s1);
  itex2MML_free_string(yyvsp[-1]);
  itex2MML_free_string(yyvsp[0]);
}
#line 4729 "y.tab.c" /* yacc.c:1652  */
    break;

  case 227:
#line 1213 "itex2MML.y" /* yacc.c:1652  */
    {
  char * s1 = itex2MML_copy3("<mstyle displaystyle=\"false\"><mfrac>", yyvsp[-1], yyvsp[0]);
  yyval = itex2MML_copy2(s1, "</mfrac></mstyle>");
  itex2MML_free_string(s1);
  itex2MML_free_string(yyvsp[-1]);
  itex2MML_free_string(yyvsp[0]);
}
#line 4741 "y.tab.c" /* yacc.c:1652  */
    break;

  case 228:
#line 1221 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3( "<mrow><mo lspace=\"0.22222em\">(</mo><mo rspace=\"0.16667em\">mod</mo>", yyvsp[0], "<mo rspace=\"0.22222em\">)</mo></mrow>");
  itex2MML_free_string(yyvsp[0]);
}
#line 4750 "y.tab.c" /* yacc.c:1652  */
    break;

  case 229:
#line 1226 "itex2MML.y" /* yacc.c:1652  */
    {
  char * s1 = itex2MML_copy3("<mfrac><mrow>", yyvsp[-3], "</mrow><mrow>");
  yyval = itex2MML_copy3(s1, yyvsp[-1], "</mrow></mfrac>");
  itex2MML_free_string(s1);
  itex2MML_free_string(yyvsp[-3]);
  itex2MML_free_string(yyvsp[-1]);
}
#line 4762 "y.tab.c" /* yacc.c:1652  */
    break;

  case 230:
#line 1233 "itex2MML.y" /* yacc.c:1652  */
    {
  char * s1 = itex2MML_copy3("<mrow>", yyvsp[-4], "<mfrac><mrow>");
  char * s2 = itex2MML_copy3(yyvsp[-3], "</mrow><mrow>", yyvsp[-1]);
  char * s3 = itex2MML_copy3("</mrow></mfrac>", yyvsp[0], "</mrow>");
  yyval = itex2MML_copy3(s1, s2, s3);
  itex2MML_free_string(s1);
  itex2MML_free_string(s2);
  itex2MML_free_string(s3);
  itex2MML_free_string(yyvsp[-4]);
  itex2MML_free_string(yyvsp[-3]);
  itex2MML_free_string(yyvsp[-1]);
  itex2MML_free_string(yyvsp[0]);
}
#line 4780 "y.tab.c" /* yacc.c:1652  */
    break;

  case 231:
#line 1247 "itex2MML.y" /* yacc.c:1652  */
    {
  char * s1 = itex2MML_copy3("<mfrac linethickness=\"0px\"><mrow>", yyvsp[-3], "</mrow><mrow>");
  yyval = itex2MML_copy3(s1, yyvsp[-1], "</mrow></mfrac>");
  itex2MML_free_string(s1);
  itex2MML_free_string(yyvsp[-3]);
  itex2MML_free_string(yyvsp[-1]);
}
#line 4792 "y.tab.c" /* yacc.c:1652  */
    break;

  case 232:
#line 1254 "itex2MML.y" /* yacc.c:1652  */
    {
  char * s1 = itex2MML_copy3("<mrow>", yyvsp[-4], "<mfrac linethickness=\"0px\"><mrow>");
  char * s2 = itex2MML_copy3(yyvsp[-3], "</mrow><mrow>", yyvsp[-1]);
  char * s3 = itex2MML_copy3("</mrow></mfrac>", yyvsp[0], "</mrow>");
  yyval = itex2MML_copy3(s1, s2, s3);
  itex2MML_free_string(s1);
  itex2MML_free_string(s2);
  itex2MML_free_string(s3);
  itex2MML_free_string(yyvsp[-4]);
  itex2MML_free_string(yyvsp[-3]);
  itex2MML_free_string(yyvsp[-1]);
  itex2MML_free_string(yyvsp[0]);
}
#line 4810 "y.tab.c" /* yacc.c:1652  */
    break;

  case 233:
#line 1268 "itex2MML.y" /* yacc.c:1652  */
    {
  char * s1 = itex2MML_copy3("<mrow><mo>(</mo><mfrac linethickness=\"0px\">", yyvsp[-1], yyvsp[0]);
  yyval = itex2MML_copy2(s1, "</mfrac><mo>)</mo></mrow>");
  itex2MML_free_string(s1);
  itex2MML_free_string(yyvsp[-1]);
  itex2MML_free_string(yyvsp[0]);
}
#line 4822 "y.tab.c" /* yacc.c:1652  */
    break;

  case 234:
#line 1275 "itex2MML.y" /* yacc.c:1652  */
    {
  char * s1 = itex2MML_copy3("<mrow><mo>(</mo><mstyle displaystyle=\"false\"><mfrac linethickness=\"0px\">", yyvsp[-1], yyvsp[0]);
  yyval = itex2MML_copy2(s1, "</mfrac></mstyle><mo>)</mo></mrow>");
  itex2MML_free_string(s1);
  itex2MML_free_string(yyvsp[-1]);
  itex2MML_free_string(yyvsp[0]);
}
#line 4834 "y.tab.c" /* yacc.c:1652  */
    break;

  case 235:
#line 1283 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<munder>", yyvsp[0], "<mo>&UnderBrace;</mo></munder>");
  itex2MML_free_string(yyvsp[0]);
}
#line 4843 "y.tab.c" /* yacc.c:1652  */
    break;

  case 236:
#line 1288 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<munder>", yyvsp[0], "<mo>&#x00332;</mo></munder>");
  itex2MML_free_string(yyvsp[0]);
}
#line 4852 "y.tab.c" /* yacc.c:1652  */
    break;

  case 237:
#line 1293 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mover>", yyvsp[0], "<mo>&OverBrace;</mo></mover>");
  itex2MML_free_string(yyvsp[0]);
}
#line 4861 "y.tab.c" /* yacc.c:1652  */
    break;

  case 238:
#line 1298 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mover>", yyvsp[0], "<mo stretchy=\"false\">&#x000AF;</mo></mover>");
  itex2MML_free_string(yyvsp[0]);
}
#line 4870 "y.tab.c" /* yacc.c:1652  */
    break;

  case 239:
#line 1302 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mover>", yyvsp[0], "<mo>&#x000AF;</mo></mover>");
  itex2MML_free_string(yyvsp[0]);
}
#line 4879 "y.tab.c" /* yacc.c:1652  */
    break;

  case 240:
#line 1307 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mover>", yyvsp[0], "<mo stretchy=\"false\">&rightarrow;</mo></mover>");
  itex2MML_free_string(yyvsp[0]);
}
#line 4888 "y.tab.c" /* yacc.c:1652  */
    break;

  case 241:
#line 1311 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mover>", yyvsp[0], "<mo>&rightarrow;</mo></mover>");
  itex2MML_free_string(yyvsp[0]);
}
#line 4897 "y.tab.c" /* yacc.c:1652  */
    break;

  case 242:
#line 1316 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mover>", yyvsp[0], "<mo>&leftarrow;</mo></mover>");
  itex2MML_free_string(yyvsp[0]);
}
#line 4906 "y.tab.c" /* yacc.c:1652  */
    break;

  case 243:
#line 1320 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mover>", yyvsp[0], "<mo>&leftrightarrow;</mo></mover>");
  itex2MML_free_string(yyvsp[0]);
}
#line 4915 "y.tab.c" /* yacc.c:1652  */
    break;

  case 244:
#line 1324 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<munder>", yyvsp[0], "<mo>&rightarrow;</mo></munder>");
  itex2MML_free_string(yyvsp[0]);
}
#line 4924 "y.tab.c" /* yacc.c:1652  */
    break;

  case 245:
#line 1328 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<munder>", yyvsp[0], "<mo>&leftarrow;</mo></munder>");
  itex2MML_free_string(yyvsp[0]);
}
#line 4933 "y.tab.c" /* yacc.c:1652  */
    break;

  case 246:
#line 1332 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<munder>", yyvsp[0], "<mo>&leftrightarrow;</mo></munder>");
  itex2MML_free_string(yyvsp[0]);
}
#line 4942 "y.tab.c" /* yacc.c:1652  */
    break;

  case 247:
#line 1337 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mover>", yyvsp[0], "<mo>&dot;</mo></mover>");
  itex2MML_free_string(yyvsp[0]);
}
#line 4951 "y.tab.c" /* yacc.c:1652  */
    break;

  case 248:
#line 1342 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mover>", yyvsp[0], "<mo>&Dot;</mo></mover>");
  itex2MML_free_string(yyvsp[0]);
}
#line 4960 "y.tab.c" /* yacc.c:1652  */
    break;

  case 249:
#line 1347 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mover>", yyvsp[0], "<mo>&tdot;</mo></mover>");
  itex2MML_free_string(yyvsp[0]);
}
#line 4969 "y.tab.c" /* yacc.c:1652  */
    break;

  case 250:
#line 1352 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mover>", yyvsp[0], "<mo>&DotDot;</mo></mover>");
  itex2MML_free_string(yyvsp[0]);
}
#line 4978 "y.tab.c" /* yacc.c:1652  */
    break;

  case 251:
#line 1357 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mover>", yyvsp[0], "<mo stretchy=\"false\">&tilde;</mo></mover>");
  itex2MML_free_string(yyvsp[0]);
}
#line 4987 "y.tab.c" /* yacc.c:1652  */
    break;

  case 252:
#line 1361 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mover>", yyvsp[0], "<mo>&tilde;</mo></mover>");
  itex2MML_free_string(yyvsp[0]);
}
#line 4996 "y.tab.c" /* yacc.c:1652  */
    break;

  case 253:
#line 1366 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mover>", yyvsp[0], "<mo stretchy=\"false\">&#x2c7;</mo></mover>");
  itex2MML_free_string(yyvsp[0]);
}
#line 5005 "y.tab.c" /* yacc.c:1652  */
    break;

  case 254:
#line 1370 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mover>", yyvsp[0], "<mo>&#x2c7;</mo></mover>");
  itex2MML_free_string(yyvsp[0]);
}
#line 5014 "y.tab.c" /* yacc.c:1652  */
    break;

  case 255:
#line 1375 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mover>", yyvsp[0], "<mo stretchy=\"false\">&#x5E;</mo></mover>");
  itex2MML_free_string(yyvsp[0]);
}
#line 5023 "y.tab.c" /* yacc.c:1652  */
    break;

  case 256:
#line 1379 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mover>", yyvsp[0], "<mo>&#x5E;</mo></mover>");
  itex2MML_free_string(yyvsp[0]);
}
#line 5032 "y.tab.c" /* yacc.c:1652  */
    break;

  case 257:
#line 1384 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<msqrt>", yyvsp[0], "</msqrt>");
  itex2MML_free_string(yyvsp[0]);
}
#line 5041 "y.tab.c" /* yacc.c:1652  */
    break;

  case 258:
#line 1389 "itex2MML.y" /* yacc.c:1652  */
    {
  char * s1 = itex2MML_copy3("<mroot>", yyvsp[0], yyvsp[-2]);
  yyval = itex2MML_copy2(s1, "</mroot>");
  itex2MML_free_string(s1);
  itex2MML_free_string(yyvsp[-2]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5053 "y.tab.c" /* yacc.c:1652  */
    break;

  case 259:
#line 1396 "itex2MML.y" /* yacc.c:1652  */
    {
  char * s1 = itex2MML_copy3("<mroot>", yyvsp[0], yyvsp[-1]);
  yyval = itex2MML_copy2(s1, "</mroot>");
  itex2MML_free_string(s1);
  itex2MML_free_string(yyvsp[-1]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5065 "y.tab.c" /* yacc.c:1652  */
    break;

  case 260:
#line 1404 "itex2MML.y" /* yacc.c:1652  */
    {
  char * s1 = itex2MML_copy3("<mpadded voffset='", yyvsp[-3], "' height='");
  char * s2 = itex2MML_copy3(s1, yyvsp[-2], "' depth='");
  char * s3 = itex2MML_copy3(s2, yyvsp[-1], "'>");
  yyval = itex2MML_copy3(s3, yyvsp[0], "</mpadded>");
  itex2MML_free_string(s1);
  itex2MML_free_string(s2);
  itex2MML_free_string(s3);
  itex2MML_free_string(yyvsp[-3]);
  itex2MML_free_string(yyvsp[-2]);
  itex2MML_free_string(yyvsp[-1]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5083 "y.tab.c" /* yacc.c:1652  */
    break;

  case 261:
#line 1417 "itex2MML.y" /* yacc.c:1652  */
    {
  char * s1 = itex2MML_copy3("<mpadded voffset='-", yyvsp[-3], "' height='");
  char * s2 = itex2MML_copy3(s1, yyvsp[-2], "' depth='");
  char * s3 = itex2MML_copy3(s2, yyvsp[-1], "'>");
  yyval = itex2MML_copy3(s3, yyvsp[0], "</mpadded>");
  itex2MML_free_string(s1);
  itex2MML_free_string(s2);
  itex2MML_free_string(s3);
  itex2MML_free_string(yyvsp[-3]);
  itex2MML_free_string(yyvsp[-2]);
  itex2MML_free_string(yyvsp[-1]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5101 "y.tab.c" /* yacc.c:1652  */
    break;

  case 262:
#line 1430 "itex2MML.y" /* yacc.c:1652  */
    {
  char * s1 = itex2MML_copy3("<mpadded voffset='", yyvsp[-2], "' height='");
  char * s2 = itex2MML_copy3(s1, yyvsp[-1], "' depth='depth'>");
  yyval = itex2MML_copy3(s2, yyvsp[0], "</mpadded>");
  itex2MML_free_string(s1);
  itex2MML_free_string(s2);
  itex2MML_free_string(yyvsp[-2]);
  itex2MML_free_string(yyvsp[-1]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5116 "y.tab.c" /* yacc.c:1652  */
    break;

  case 263:
#line 1440 "itex2MML.y" /* yacc.c:1652  */
    {
  char * s1 = itex2MML_copy3("<mpadded voffset='-", yyvsp[-2], "' height='");
  char * s2 = itex2MML_copy3(s1, yyvsp[-1], "' depth='+");
  char * s3 = itex2MML_copy3(s2, yyvsp[-2], "'>");
  yyval = itex2MML_copy3(s3, yyvsp[0], "</mpadded>");
  itex2MML_free_string(s1);
  itex2MML_free_string(s2);
  itex2MML_free_string(s3);
  itex2MML_free_string(yyvsp[-2]);
  itex2MML_free_string(yyvsp[-1]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5133 "y.tab.c" /* yacc.c:1652  */
    break;

  case 264:
#line 1452 "itex2MML.y" /* yacc.c:1652  */
    {
  char * s1 = itex2MML_copy3("<mpadded voffset='", yyvsp[-1], "' height='+");
  char * s2 = itex2MML_copy3(s1, yyvsp[-1], "' depth='depth'>");
  yyval = itex2MML_copy3(s2, yyvsp[0], "</mpadded>");
  itex2MML_free_string(s1);
  itex2MML_free_string(s2);
  itex2MML_free_string(yyvsp[-1]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5147 "y.tab.c" /* yacc.c:1652  */
    break;

  case 265:
#line 1461 "itex2MML.y" /* yacc.c:1652  */
    {
  char * s1 = itex2MML_copy3("<mpadded voffset='-", yyvsp[-1], "' height='0pt' depth='+");
  char * s2 = itex2MML_copy3(s1, yyvsp[-1], "'>");
  yyval = itex2MML_copy3(s2, yyvsp[0], "</mpadded>");
  itex2MML_free_string(s1);
  itex2MML_free_string(s2);
  itex2MML_free_string(yyvsp[-1]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5161 "y.tab.c" /* yacc.c:1652  */
    break;

  case 266:
#line 1471 "itex2MML.y" /* yacc.c:1652  */
    {
  char * s1 = itex2MML_copy3("<munder><mo>", yyvsp[-4], "</mo><mrow>");
  yyval = itex2MML_copy3(s1, yyvsp[-2], "</mrow></munder>");
  itex2MML_free_string(s1);
  itex2MML_free_string(yyvsp[-4]);
  itex2MML_free_string(yyvsp[-2]);
}
#line 5173 "y.tab.c" /* yacc.c:1652  */
    break;

  case 267:
#line 1478 "itex2MML.y" /* yacc.c:1652  */
    {
  char * s1 = itex2MML_copy3("<munder>", yyvsp[0], yyvsp[-1]);
  yyval = itex2MML_copy2(s1, "</munder>");
  itex2MML_free_string(s1);
  itex2MML_free_string(yyvsp[-1]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5185 "y.tab.c" /* yacc.c:1652  */
    break;

  case 268:
#line 1486 "itex2MML.y" /* yacc.c:1652  */
    {
  char * s1 = itex2MML_copy3("<mover><mo>", yyvsp[-1], "</mo>");
  yyval =  itex2MML_copy3(s1, yyvsp[0], "</mover>");
  itex2MML_free_string(s1);
  itex2MML_free_string(yyvsp[-1]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5197 "y.tab.c" /* yacc.c:1652  */
    break;

  case 269:
#line 1493 "itex2MML.y" /* yacc.c:1652  */
    {
  char * s1 = itex2MML_copy3("<mover>", yyvsp[0], yyvsp[-1]);
  yyval = itex2MML_copy2(s1, "</mover>");
  itex2MML_free_string(s1);
  itex2MML_free_string(yyvsp[-1]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5209 "y.tab.c" /* yacc.c:1652  */
    break;

  case 270:
#line 1501 "itex2MML.y" /* yacc.c:1652  */
    {
  char * s1 = itex2MML_copy3("<munderover><mo>", yyvsp[-4], "</mo><mrow>");
  char * s2 = itex2MML_copy3(s1, yyvsp[-2], "</mrow>");
  yyval = itex2MML_copy3(s2, yyvsp[0], "</munderover>");
  itex2MML_free_string(s1);
  itex2MML_free_string(s2);
  itex2MML_free_string(yyvsp[-4]);
  itex2MML_free_string(yyvsp[-2]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5224 "y.tab.c" /* yacc.c:1652  */
    break;

  case 271:
#line 1511 "itex2MML.y" /* yacc.c:1652  */
    {
  char * s1 = itex2MML_copy3("<munderover>", yyvsp[0], yyvsp[-2]);
  yyval = itex2MML_copy3(s1, yyvsp[-1], "</munderover>");
  itex2MML_free_string(s1);
  itex2MML_free_string(yyvsp[-2]);
  itex2MML_free_string(yyvsp[-1]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5237 "y.tab.c" /* yacc.c:1652  */
    break;

  case 272:
#line 1520 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy_string("<mrow/>");
}
#line 5245 "y.tab.c" /* yacc.c:1652  */
    break;

  case 273:
#line 1524 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mrow><mtable displaystyle=\"false\" rowspacing=\"0.5ex\">", yyvsp[-2], "</mtable></mrow>");
  itex2MML_free_string(yyvsp[-2]);
}
#line 5254 "y.tab.c" /* yacc.c:1652  */
    break;

  case 274:
#line 1528 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mrow><mtable displaystyle=\"true\" rowspacing=\"1.0ex\">", yyvsp[-2], "</mtable></mrow>");
  itex2MML_free_string(yyvsp[-2]);
}
#line 5263 "y.tab.c" /* yacc.c:1652  */
    break;

  case 275:
#line 1532 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mrow><mo>(</mo><mrow><mtable displaystyle=\"false\" rowspacing=\"0.5ex\">", yyvsp[-2], "</mtable></mrow><mo>)</mo></mrow>");
  itex2MML_free_string(yyvsp[-2]);
}
#line 5272 "y.tab.c" /* yacc.c:1652  */
    break;

  case 276:
#line 1536 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mrow><mo>[</mo><mrow><mtable displaystyle=\"false\" rowspacing=\"0.5ex\">", yyvsp[-2], "</mtable></mrow><mo>]</mo></mrow>");
  itex2MML_free_string(yyvsp[-2]);
}
#line 5281 "y.tab.c" /* yacc.c:1652  */
    break;

  case 277:
#line 1540 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mrow><mo>&VerticalBar;</mo><mrow><mtable displaystyle=\"false\" rowspacing=\"0.5ex\">", yyvsp[-2], "</mtable></mrow><mo>&VerticalBar;</mo></mrow>");
  itex2MML_free_string(yyvsp[-2]);
}
#line 5290 "y.tab.c" /* yacc.c:1652  */
    break;

  case 278:
#line 1544 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mrow><mo>{</mo><mrow><mtable displaystyle=\"false\" rowspacing=\"0.5ex\">", yyvsp[-2], "</mtable></mrow><mo>}</mo></mrow>");
  itex2MML_free_string(yyvsp[-2]);
}
#line 5299 "y.tab.c" /* yacc.c:1652  */
    break;

  case 279:
#line 1548 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mrow><mo>&DoubleVerticalBar;</mo><mrow><mtable displaystyle=\"false\" rowspacing=\"0.5ex\">", yyvsp[-2], "</mtable></mrow><mo>&DoubleVerticalBar;</mo></mrow>");
  itex2MML_free_string(yyvsp[-2]);
}
#line 5308 "y.tab.c" /* yacc.c:1652  */
    break;

  case 280:
#line 1552 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mstyle scriptlevel=\"2\"><mrow><mtable displaystyle=\"false\" rowspacing=\"0.5ex\">", yyvsp[-2], "</mtable></mrow></mstyle>");
  itex2MML_free_string(yyvsp[-2]);
}
#line 5317 "y.tab.c" /* yacc.c:1652  */
    break;

  case 281:
#line 1556 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mrow><mo>{</mo><mrow><mtable displaystyle=\"false\" columnalign=\"left left\">", yyvsp[-2], "</mtable></mrow></mrow>");
  itex2MML_free_string(yyvsp[-2]);
}
#line 5326 "y.tab.c" /* yacc.c:1652  */
    break;

  case 282:
#line 1560 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mrow><mtable displaystyle=\"true\" columnalign=\"right left right left right left right left right left\" columnspacing=\"0em\">", yyvsp[-2], "</mtable></mrow>");
  itex2MML_free_string(yyvsp[-2]);
}
#line 5335 "y.tab.c" /* yacc.c:1652  */
    break;

  case 283:
#line 1564 "itex2MML.y" /* yacc.c:1652  */
    {
  char * s1 = itex2MML_copy3("<mtable displaystyle=\"false\" rowspacing=\"0.5ex\" align=\"", yyvsp[-6], "\" columnalign=\"");
  char * s2 = itex2MML_copy3(s1, yyvsp[-4], "\">");
  yyval = itex2MML_copy3(s2, yyvsp[-2], "</mtable>");
  itex2MML_free_string(s1);
  itex2MML_free_string(s2);
  itex2MML_free_string(yyvsp[-6]);
  itex2MML_free_string(yyvsp[-4]);
  itex2MML_free_string(yyvsp[-2]);
}
#line 5350 "y.tab.c" /* yacc.c:1652  */
    break;

  case 284:
#line 1574 "itex2MML.y" /* yacc.c:1652  */
    {
  char * s1 = itex2MML_copy3("<mtable displaystyle=\"false\" rowspacing=\"0.5ex\" columnalign=\"", yyvsp[-4], "\">");
  yyval = itex2MML_copy3(s1, yyvsp[-2], "</mtable>");
  itex2MML_free_string(s1);
  itex2MML_free_string(yyvsp[-4]);
  itex2MML_free_string(yyvsp[-2]);
}
#line 5362 "y.tab.c" /* yacc.c:1652  */
    break;

  case 285:
#line 1581 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<semantics><annotation-xml encoding=\"SVG1.1\">", yyvsp[-1], "</annotation-xml></semantics>");
  itex2MML_free_string(yyvsp[-1]);
}
#line 5371 "y.tab.c" /* yacc.c:1652  */
    break;

  case 286:
#line 1585 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy_string(" ");
}
#line 5379 "y.tab.c" /* yacc.c:1652  */
    break;

  case 287:
#line 1589 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3(yyvsp[-1], " ", yyvsp[0]);
  itex2MML_free_string(yyvsp[-1]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5389 "y.tab.c" /* yacc.c:1652  */
    break;

  case 288:
#line 1594 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy_string(yyvsp[0]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5398 "y.tab.c" /* yacc.c:1652  */
    break;

  case 289:
#line 1599 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mrow><mtable columnalign=\"center\" rowspacing=\"0.5ex\">", yyvsp[-1], "</mtable></mrow>");
  itex2MML_free_string(yyvsp[-1]);
}
#line 5407 "y.tab.c" /* yacc.c:1652  */
    break;

  case 290:
#line 1604 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mrow><mtable>", yyvsp[-1], "</mtable></mrow>");
  itex2MML_free_string(yyvsp[-1]);
}
#line 5416 "y.tab.c" /* yacc.c:1652  */
    break;

  case 291:
#line 1608 "itex2MML.y" /* yacc.c:1652  */
    {
  char * s1 = itex2MML_copy3("<mrow><mtable ", yyvsp[-3], ">");
  yyval = itex2MML_copy3(s1, yyvsp[-1], "</mtable></mrow>");
  itex2MML_free_string(s1);
  itex2MML_free_string(yyvsp[-3]);
  itex2MML_free_string(yyvsp[-1]);
}
#line 5428 "y.tab.c" /* yacc.c:1652  */
    break;

  case 292:
#line 1616 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy_string(yyvsp[0]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5437 "y.tab.c" /* yacc.c:1652  */
    break;

  case 293:
#line 1620 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3(yyvsp[-1], " ", yyvsp[0]);
  itex2MML_free_string(yyvsp[-1]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5447 "y.tab.c" /* yacc.c:1652  */
    break;

  case 294:
#line 1626 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy_string(yyvsp[0]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5456 "y.tab.c" /* yacc.c:1652  */
    break;

  case 295:
#line 1630 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy_string(yyvsp[0]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5465 "y.tab.c" /* yacc.c:1652  */
    break;

  case 296:
#line 1634 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy_string(yyvsp[0]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5474 "y.tab.c" /* yacc.c:1652  */
    break;

  case 297:
#line 1638 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy_string(yyvsp[0]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5483 "y.tab.c" /* yacc.c:1652  */
    break;

  case 298:
#line 1642 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy_string(yyvsp[0]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5492 "y.tab.c" /* yacc.c:1652  */
    break;

  case 299:
#line 1646 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy_string(yyvsp[0]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5501 "y.tab.c" /* yacc.c:1652  */
    break;

  case 300:
#line 1650 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy_string(yyvsp[0]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5510 "y.tab.c" /* yacc.c:1652  */
    break;

  case 301:
#line 1654 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy_string(yyvsp[0]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5519 "y.tab.c" /* yacc.c:1652  */
    break;

  case 302:
#line 1658 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy_string(yyvsp[0]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5528 "y.tab.c" /* yacc.c:1652  */
    break;

  case 303:
#line 1662 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy_string(yyvsp[0]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5537 "y.tab.c" /* yacc.c:1652  */
    break;

  case 304:
#line 1667 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy2("columnalign=", yyvsp[0]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5546 "y.tab.c" /* yacc.c:1652  */
    break;

  case 305:
#line 1672 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy2("columnalign=", yyvsp[0]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5555 "y.tab.c" /* yacc.c:1652  */
    break;

  case 306:
#line 1677 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy2("rowalign=", yyvsp[0]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5564 "y.tab.c" /* yacc.c:1652  */
    break;

  case 307:
#line 1682 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy2("align=", yyvsp[0]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5573 "y.tab.c" /* yacc.c:1652  */
    break;

  case 308:
#line 1687 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy2("equalrows=", yyvsp[0]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5582 "y.tab.c" /* yacc.c:1652  */
    break;

  case 309:
#line 1692 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy2("equalcolumns=", yyvsp[0]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5591 "y.tab.c" /* yacc.c:1652  */
    break;

  case 310:
#line 1697 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy2("rowlines=", yyvsp[0]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5600 "y.tab.c" /* yacc.c:1652  */
    break;

  case 311:
#line 1702 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy2("columnlines=", yyvsp[0]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5609 "y.tab.c" /* yacc.c:1652  */
    break;

  case 312:
#line 1707 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy2("frame=", yyvsp[0]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5618 "y.tab.c" /* yacc.c:1652  */
    break;

  case 313:
#line 1712 "itex2MML.y" /* yacc.c:1652  */
    {
  char * s1 = itex2MML_copy3("rowspacing=", yyvsp[0], " columnspacing=");
  yyval = itex2MML_copy2(s1, yyvsp[0]);
  itex2MML_free_string(s1);
  itex2MML_free_string(yyvsp[0]);
}
#line 5629 "y.tab.c" /* yacc.c:1652  */
    break;

  case 314:
#line 1719 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy_string(yyvsp[0]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5638 "y.tab.c" /* yacc.c:1652  */
    break;

  case 315:
#line 1723 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3(yyvsp[-2], " ", yyvsp[0]);
  itex2MML_free_string(yyvsp[-2]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5648 "y.tab.c" /* yacc.c:1652  */
    break;

  case 316:
#line 1729 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mtr>", yyvsp[0], "</mtr>");
  itex2MML_free_string(yyvsp[0]);
}
#line 5657 "y.tab.c" /* yacc.c:1652  */
    break;

  case 317:
#line 1733 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy_string(yyvsp[0]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5666 "y.tab.c" /* yacc.c:1652  */
    break;

  case 318:
#line 1738 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy_string(yyvsp[0]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5675 "y.tab.c" /* yacc.c:1652  */
    break;

  case 319:
#line 1742 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3(yyvsp[-2], " ", yyvsp[0]);
  itex2MML_free_string(yyvsp[-2]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5685 "y.tab.c" /* yacc.c:1652  */
    break;

  case 320:
#line 1748 "itex2MML.y" /* yacc.c:1652  */
    {
  char * s1 = itex2MML_copy3("<mtr ", yyvsp[-2], ">");
  yyval = itex2MML_copy3(s1, yyvsp[0], "</mtr>");
  itex2MML_free_string(s1);
  itex2MML_free_string(yyvsp[-2]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5697 "y.tab.c" /* yacc.c:1652  */
    break;

  case 321:
#line 1756 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy_string(yyvsp[0]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5706 "y.tab.c" /* yacc.c:1652  */
    break;

  case 322:
#line 1760 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3(yyvsp[-1], " ", yyvsp[0]);
  itex2MML_free_string(yyvsp[-1]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5716 "y.tab.c" /* yacc.c:1652  */
    break;

  case 323:
#line 1766 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy_string(yyvsp[0]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5725 "y.tab.c" /* yacc.c:1652  */
    break;

  case 324:
#line 1770 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy_string(yyvsp[0]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5734 "y.tab.c" /* yacc.c:1652  */
    break;

  case 325:
#line 1775 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy_string("<mtd/>");
}
#line 5742 "y.tab.c" /* yacc.c:1652  */
    break;

  case 326:
#line 1778 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3("<mtd>", yyvsp[0], "</mtd>");
  itex2MML_free_string(yyvsp[0]);
}
#line 5751 "y.tab.c" /* yacc.c:1652  */
    break;

  case 327:
#line 1782 "itex2MML.y" /* yacc.c:1652  */
    {
  char * s1 = itex2MML_copy3("<mtd ", yyvsp[-2], ">");
  yyval = itex2MML_copy3(s1, yyvsp[0], "</mtd>");
  itex2MML_free_string(s1);
  itex2MML_free_string(yyvsp[-2]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5763 "y.tab.c" /* yacc.c:1652  */
    break;

  case 328:
#line 1790 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy_string(yyvsp[0]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5772 "y.tab.c" /* yacc.c:1652  */
    break;

  case 329:
#line 1794 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy3(yyvsp[-1], " ", yyvsp[0]);
  itex2MML_free_string(yyvsp[-1]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5782 "y.tab.c" /* yacc.c:1652  */
    break;

  case 330:
#line 1800 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy_string(yyvsp[0]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5791 "y.tab.c" /* yacc.c:1652  */
    break;

  case 331:
#line 1804 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy_string(yyvsp[0]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5800 "y.tab.c" /* yacc.c:1652  */
    break;

  case 332:
#line 1808 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy_string(yyvsp[0]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5809 "y.tab.c" /* yacc.c:1652  */
    break;

  case 333:
#line 1812 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy_string(yyvsp[0]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5818 "y.tab.c" /* yacc.c:1652  */
    break;

  case 334:
#line 1817 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy2("rowspan=", yyvsp[0]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5827 "y.tab.c" /* yacc.c:1652  */
    break;

  case 335:
#line 1822 "itex2MML.y" /* yacc.c:1652  */
    {
  yyval = itex2MML_copy2("columnspan=", yyvsp[0]);
  itex2MML_free_string(yyvsp[0]);
}
#line 5836 "y.tab.c" /* yacc.c:1652  */
    break;


#line 5840 "y.tab.c" /* yacc.c:1652  */
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
  {
    const int yylhs = yyr1[yyn] - YYNTOKENS;
    const int yyi = yypgoto[yylhs] + *yyssp;
    yystate = (0 <= yyi && yyi <= YYLAST && yycheck[yyi] == *yyssp
               ? yytable[yyi]
               : yydefgoto[yylhs]);
  }

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
      yyerror (ret_str, YY_("syntax error"));
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
        yyerror (ret_str, yymsgp);
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
                      yytoken, &yylval, ret_str);
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
  /* Pacify compilers when the user code never invokes YYERROR and the
     label yyerrorlab therefore never appears in user code.  */
  if (0)
    YYERROR;

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
                  yystos[yystate], yyvsp, ret_str);
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
  yyerror (ret_str, YY_("memory exhausted"));
  yyresult = 2;
  /* Fall through.  */
#endif


/*-----------------------------------------------------.
| yyreturn -- parsing is finished, return the result.  |
`-----------------------------------------------------*/
yyreturn:
  if (yychar != YYEMPTY)
    {
      /* Make sure we have latest lookahead translation.  See comments at
         user semantic actions for why this is necessary.  */
      yytoken = YYTRANSLATE (yychar);
      yydestruct ("Cleanup: discarding lookahead",
                  yytoken, &yylval, ret_str);
    }
  /* Do not reclaim the symbols of the rule whose action triggered
     this YYABORT or YYACCEPT.  */
  YYPOPSTACK (yylen);
  YY_STACK_PRINT (yyss, yyssp);
  while (yyssp != yyss)
    {
      yydestruct ("Cleanup: popping",
                  yystos[*yyssp], yyvsp, ret_str);
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
#line 1827 "itex2MML.y" /* yacc.c:1918  */


char * itex2MML_parse (const char * buffer, size_t length)
{
  char * mathml = 0;

  int result;

  itex2MML_setup (buffer, length);
  itex2MML_restart ();

  result = itex2MML_yyparse (&mathml);

  if (result && mathml) /* shouldn't happen? */
    {
      itex2MML_free_string (mathml);
      mathml = 0;
    }
  return mathml;
}

int itex2MML_filter (const char * buffer, size_t length)
{
  itex2MML_setup (buffer, length);
  itex2MML_restart ();

  return itex2MML_yyparse (0);
}

#define ITEX_DELIMITER_DOLLAR 0
#define ITEX_DELIMITER_DOUBLE 1
#define ITEX_DELIMITER_SQUARE 2
#define ITEX_DELIMITER_PAREN  3

static char * itex2MML_last_error = 0;

static void itex2MML_keep_error (const char * msg)
{
  if (itex2MML_last_error)
    {
      itex2MML_free_string (itex2MML_last_error);
      itex2MML_last_error = 0;
    }
  itex2MML_last_error = itex2MML_copy_escaped (msg);
}

int itex2MML_html_filter (const char * buffer, size_t length)
{
  return itex2MML_do_html_filter (buffer, length, 0);
}

int itex2MML_strict_html_filter (const char * buffer, size_t length)
{
  return itex2MML_do_html_filter (buffer, length, 1);
}

int itex2MML_do_html_filter (const char * buffer, size_t length, const int forbid_markup)
{
  int result = 0;

  int type = 0;
  int skip = 0;
  int match = 0;

  const char * ptr1 = buffer;
  const char * ptr2 = 0;

  const char * end = buffer + length;

  char * mathml = 0;

  void (*save_error_fn) (const char * msg) = itex2MML_error;

  itex2MML_error = itex2MML_keep_error;

 _until_math:
  ptr2 = ptr1;

  while (ptr2 < end)
    {
      if (*ptr2 == '$') break;
      if ((*ptr2 == '\\') && (ptr2 + 1 < end))
	{
	  if (*(ptr2+1) == '[' || *(ptr2+1) == '(') break;
	}
      ++ptr2;
    }
  if (itex2MML_write && ptr2 > ptr1)
    (*itex2MML_write) (ptr1, ptr2 - ptr1);

  if (ptr2 == end) goto _finish;

 _until_html:
  ptr1 = ptr2;

  if (ptr2 + 1 < end)
    {
      if ((*ptr2 == '\\') && (*(ptr2+1) == '['))
	{
	  type = ITEX_DELIMITER_SQUARE;
	  ptr2 += 2;
	}
      else if ((*ptr2 == '\\') && (*(ptr2+1) == '('))
	{
	  type = ITEX_DELIMITER_PAREN;
	  ptr2 += 2;
	}
      else if ((*ptr2 == '$') && (*(ptr2+1) == '$'))
	{
	  type = ITEX_DELIMITER_DOUBLE;
	  ptr2 += 2;
	}
      else
	{
	  type = ITEX_DELIMITER_DOLLAR;
	  ptr2 += 2;
	}
    }
  else goto _finish;

  skip = 0;
  match = 0;

  while (ptr2 < end)
    {
      switch (*ptr2)
	{
	case '<':
	case '>':
	  if (forbid_markup == 1) skip = 1;
	  break;

	case '\\':
	  if (ptr2 + 1 < end)
	    {
	      if (*(ptr2 + 1) == '[' || *(ptr2 + 1) == '(')
		{
		  skip = 1;
		}
	      else if (*(ptr2 + 1) == ']')
		{
		  if (type == ITEX_DELIMITER_SQUARE)
		    {
		      ptr2 += 2;
		      match = 1;
		    }
		  else
		    {
		      skip = 1;
		    }
		}
	      else if (*(ptr2 + 1) == ')')
		{
		  if (type == ITEX_DELIMITER_PAREN)
		    {
		      ptr2 += 2;
		      match = 1;
		    }
	  else
	    {
	      skip = 1;
	    }
	}

	    }
	  break;

	case '$':
	  if (*(ptr2-1) == '\\')
	    {
	      skip = 0;
	    }
	  else if (type == ITEX_DELIMITER_SQUARE || type == ITEX_DELIMITER_PAREN)
	    {
	      skip = 1;
	    }
	  else if (ptr2 + 1 < end)
	    {
	      if (*(ptr2 + 1) == '$')
		{
		  if (type == ITEX_DELIMITER_DOLLAR)
		    {
		      ptr2++;
		      match = 1;
		    }
		  else
		    {
		      ptr2 += 2;
		      match = 1;
		    }
		}
	      else
		{
		  if (type == ITEX_DELIMITER_DOLLAR)
		    {
		      ptr2++;
		      match = 1;
		    }
		  else
		    {
		      skip = 1;
		    }
		}
	    }
	  else
	    {
	      if (type == ITEX_DELIMITER_DOLLAR)
		{
		  ptr2++;
		  match = 1;
		}
	      else
		{
		  skip = 1;
		}
	    }
	  break;

	default:
	  break;
	}
      if (skip || match) break;

      ++ptr2;
    }
  if (skip)
    {
      if (type == ITEX_DELIMITER_DOLLAR)
	{
	  if (itex2MML_write)
	    (*itex2MML_write) (ptr1, 1);
	  ptr1++;
	}
      else
	{
	  if (itex2MML_write)
	    (*itex2MML_write) (ptr1, 2);
	  ptr1 += 2;
	}
      goto _until_math;
    }
  if (match)
    {
      mathml = itex2MML_parse (ptr1, ptr2 - ptr1);

      if (mathml)
	{
	  if (itex2MML_write_mathml)
	    (*itex2MML_write_mathml) (mathml);
	  itex2MML_free_string (mathml);
	  mathml = 0;
	}
      else
	{
	  ++result;
	  if (itex2MML_write)
	    {
	      if (type == ITEX_DELIMITER_DOLLAR)
		(*itex2MML_write) ("<math xmlns='http://www.w3.org/1998/Math/MathML' display='inline'><merror><mtext>", 0);
	      else
		(*itex2MML_write) ("<math xmlns='http://www.w3.org/1998/Math/MathML' display='block'><merror><mtext>", 0);

	      (*itex2MML_write) (itex2MML_last_error, 0);
	      (*itex2MML_write) ("</mtext></merror></math>", 0);
	    }
	}
      ptr1 = ptr2;

      goto _until_math;
    }
  if (itex2MML_write)
    (*itex2MML_write) (ptr1, ptr2 - ptr1);

 _finish:
  if (itex2MML_last_error)
    {
      itex2MML_free_string (itex2MML_last_error);
      itex2MML_last_error = 0;
    }
  itex2MML_error = save_error_fn;

  return result;
}
