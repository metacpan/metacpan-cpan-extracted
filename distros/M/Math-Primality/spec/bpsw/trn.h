/* trn.h                 Thomas R. Nicely          2007.02.09.2300
 *                    http://www.trnicely.net
 * GCC 3.04                 DJGPP 2.03                    GMP 4.01
 *
 * Freeware copyright (c) 2007 Thomas R. Nicely
 * <http://www.trnicely.net>. No warranties expressed or implied.
 * Distributed under the terms of the GNU GPL, GNU FDL, and DJGPP
 * licenses; see <http://www.gnu.org/licenses/licenses.html> and
 * <http://www.delorie.com/djgpp>. Source, binaries, and license
 * terms available upon request.
 *
 * Revised for compatibility with GCC 4.02 and GMP 4.14
 * (-std=gnu99) running under GNU/Linux (kernel release
 * 2.6.13-15-default, SUSE Linux 10.0 i386) as root.
 *
 * Header for custom library routines written by Thomas R. Nicely.
 * The source code is in trn.c.
 *
 * If it desired to equate old identifiers (such as _iSignum)
 * with newer ones (such as iSignum), define _OLD_IDENTIFIERS_TRN
 * BEFORE inclusion of this header.
 *
 */

#ifndef _TRN_H_
#define _TRN_H_ 1

#ifndef _GNU_SOURCE
  #define _GNU_SOURCE 1
#endif
#ifndef __USE_GNU
  #define __USE_GNU 1
#endif

#if defined(__WIN32__) || defined(__DJGPP__)
  #ifndef __MSDOS__
    #define __MSDOS__ 1
  #endif
#endif

#if !defined(__dj_include_math_h_) && !defined(_MATH_H)
  #include <math.h>
#endif
#include <stdio.h>
#include <string.h>
#include <limits.h>
#include <gmp.h>

#undef __OBSL__  /* Output blank screen line (usually at program exit) */
#ifdef __MSDOS__
  #define __OBSL__ {printf("\n");}
  #include <conio.h>
#else
  #define __OBSL__ {printf("\n\n");}
#endif

/**********************************************************************/
/******************** MANIFEST CONSTANTS CORRECTED ********************/
/**********************************************************************/

/* Redefine the manifest constants in math.h to properly implement
   long double precision. This fixes an oversight (or a misguided
   commitment to 53-bit double precision) in many versions of math.h. */

/* From GNU C 3.04 */

#undef M_E             /*  e           */
#undef M_LOG2E         /*  log_2(e)    */
#undef M_LOG10E        /*  log_10(e)   */
#undef M_LN2           /*  ln(2)       */
#undef M_LN10          /*  ln(10)      */
#undef M_PI            /*  pi          */
#undef M_PI_2          /*  pi/2        */
#undef M_PI_4          /*  pi/4        */
#undef M_1_PI          /*  1/pi        */
#undef M_2_PI          /*  2/pi        */
#undef M_2_SQRTPI      /*  2/sqrt(pi)  */
#undef M_SQRT2         /*  sqrt(2)     */
#undef M_SQRT1_2       /*  sqrt(1/2)   */
#undef PI              /*  in accordance with C99 */
#undef PI2             /*  in accordance with C99 */

/* Corrected values are given to 50 decimal places (at least 165-bit
   precision). */

#define M_E             2.71828182845904523536028747135266249775724709369996L
#define M_LOG2E	        1.44269504088896340735992468100189213742664595415299L
#define M_LOG10E        0.43429448190325182765112891891660508229439700580367L
#define M_LN2           0.69314718055994530941723212145817656807550013436026L
#define M_LN10          2.30258509299404568401799145468436420760110148862877L
#define M_PI            3.14159265358979323846264338327950288419716939937511L
#define M_PI_2          1.57079632679489661923132169163975144209858469968755L
#define M_PI_4          0.78539816339744830961566084581987572104929234984378L
#define M_1_PI          0.31830988618379067153776752674502872406891929148091L
#define M_2_PI          0.63661977236758134307553505349005744813783858296183L
#define M_2_SQRTPI      1.12837916709551257389615890312154517168810125865800L
#define M_SQRT2         1.41421356237309504880168872420969807856967187537695L
#define M_SQRT1_2       0.70710678118654752440084436210484903928483593768847L

/* From B*rland C++ 4.52 */

#undef M_1_SQRTPI      /*  1/sqrt(pi)  */
#undef M_SQRT_2        /*  sqrt(1/2)   */

#define M_1_SQRTPI      0.56418958354775628694807945156077258584405062932900L
#define M_SQRT_2        M_SQRT1_2

/* From ... M*cr*s*ft C ? */

#undef M_SQRT3         /*  sqrt(3)     */
#undef M_TWOPI         /*  2*pi        */
#undef M_3PI_4         /*  3*pi/4      */
#undef M_SQRTPI        /*  sqrt(pi)    */
#undef M_LOGE          /*  log_10(e)   */
#undef M_IVLN10        /*  1/ln(10)    */
#undef M_LOG2_E        /*  ln(2)       */
#undef M_INVLN2        /*  1/ln(2)     */
#undef M_LOG2          /*  log_10(2)   */

#define	M_SQRT3         1.73205080756887729352744634150587236694280525381038L
#define	M_TWOPI         6.28318530717958647692528676655900576839433879875021L
#define	M_3PI_4         2.35619449019234492884698253745962716314787704953133L
#define	M_SQRTPI        1.77245385090551602729816748334114518279754945612239L
#define M_LOGE          M_LOG10E
#define	M_IVLN10        M_LOG10E
#define	M_LOG2_E        M_LN2
#define	M_INVLN2        M_LOG2E
#define M_LOG2          0.30102999566398119521373889472449302676818988146211L

/* Nicely constants */

#undef M_LOG_2_BASE10
#undef M_LOG_E_BASE2
#undef M_LOG_E_BASE10
#undef M_LI2
#undef M_C2
#undef M_C3
#undef M_C4
#undef M_HL2
#undef M_HL3
#undef M_HL4
#undef M_ACC2
#undef M_ACC3
#undef M_ACC4
#undef M_LN2_SQUARED
#undef M_LN2_CUBED

/* The constants M_LI2, M_C2, M_C3, M_C4, M_HL2, M_HL3, M_HL4, M_ACC2,
   M_ACC3, and M_ACC4 appear in calculations involving the
   Hardy-Littlewood integrals, twin primes, prime triplets, and
   prime quadruplets. */

#define M_LOG_2_BASE10  M_LOG2
#define M_LOG_E_BASE2   M_LOG2E
#define M_LOG_E_BASE10  M_LOG10E
#define M_LI2  1.045163780117492784844588889194613136522615578L /* Li(2) */
#define M_C2   0.660161815846869573927812110014555778432623360L /* twins */
#define M_C3   0.635166354604271207206696591272522417342065687L /* trplts */
#define M_C4   0.307494878758327093123354486071076853022178520L /* quads */
#define M_HL2  1.320323631693739147855624220029111556865246721L
#define M_HL3  2.858248595719220432430134660726350878039295593L
#define M_HL4  4.151180863237415757165285561959537515799410019L
#define M_ACC2 2.640647263387478295711248440058223113730493441L
#define M_ACC3 4.287372893578830648645201991089526317058943389L
#define M_ACC4 5.534907817649887676220380749279383354399213359L
#define M_LN2_SQUARED 0.48045301391820142466710252632666497173055295159455L
#define M_LN2_CUBED   0.33302465198892947971885358261173054415612648534861L

/* Long double constants such as, and including those defined in
   GNU extensions. */

#undef  M_El
#undef  M_LOG2El
#undef  M_LOG10El
#undef  M_LN2l
#undef  M_LN10l
#undef  M_PIl
#undef  M_PI_2l
#undef  M_PI_4l
#undef  M_1_PIl
#undef  M_2_PIl
#undef  M_2_SQRTPIl
#undef  M_SQRT2l
#undef  M_SQRT1_2l
#undef  M_1_SQRTPIl
#undef  M_SQRT_2l
#undef 	M_SQRT3l
#undef 	M_TWOPIl
#undef 	M_3PI_4l
#undef 	M_SQRTPIl
#undef  M_LOGEl
#undef 	M_IVLN10l
#undef 	M_LOG2_El
#undef 	M_INVLN2l
#undef  M_LOG2l
#undef  M_LOG_2_BASE10l
#undef  M_LOG_E_BASE2l
#undef  M_LOG_E_BASE10l
#undef  M_LN2_SQUAREDl
#undef  M_LN2_CUBEDl

#define M_El		M_E
#define M_LOG2El        M_LOG2E
#define M_LOG10El       M_LOG10E
#define M_LN2l		M_LN2
#define M_LN10l         M_LN10l
#define M_PIl		M_PI
#define M_PI_2l	        M_PI_2
#define M_PI_4l         M_PI_4
#define M_1_PIl         M_1_PI
#define M_2_PIl         M_2_PI
#define M_2_SQRTPIl     M_2_SQRTPI
#define M_SQRT2l        M_SQRT2
#define M_SQRT1_2l      M_SQRT1_2
#define M_1_SQRTPIl     M_1_SQRTPI
#define M_SQRT_2l       M_SQRT_2
#define	M_SQRT3l        M_SQRT3
#define	M_TWOPIl        M_TWOPI
#define	M_3PI_4l        M_3PI_4
#define	M_SQRTPIl       M_SQRTPI
#define M_LOGEl         M_LOGE
#define	M_IVLN10l       M_IVLN10
#define	M_LOG2_El       M_LOG2_E
#define	M_INVLN2l       M_INVLN2
#define M_LOG2l         M_LOG2
#define M_LOG_2_BASE10l M_LOG2_BASE10
#define M_LOG_E_BASE2l  M_LOG_E_BASE2
#define M_LOG_E_BASE10l M_LOG_E_BASE10
#define M_LI2l          M_LI2
#define M_LN2_SQUAREDl  M_LN2_SQUARED
#define M_LN2_CUBEDl    M_LN2_CUBED

/**********************************************************************/
/****************** END MANIFEST CONSTANTS CORRECTED ******************/
/**********************************************************************/

/* Parameters that should have been taken care of by <limits.h>. */

#ifndef CHAR_BIT
  #define CHAR_BIT 8
#endif

#if !defined(LLONG_MAX)
#  if defined(LONG_LONG_MAX)
#    define LLONG_MAX LONG_LONG_MAX
#  else
#    define LLONG_MAX 9223372036854775807LL
#  endif
#else
#  if !defined(LONG_LONG_MAX)
#    define LONG_LONG_MAX LLONG_MAX
#  endif
#endif

#if !defined(LLONG_MIN)
#  if defined(LONG_LONG_MIN)
#    define LLONG_MIN LONG_LONG_MIN
#  else
#    define LLONG_MIN -9223372036854775808LL
#  endif
#else
#  if !defined(LONG_LONG_MIN)
#    define LONG_LONG_MIN LLONG_MIN
#  endif
#endif

#if !defined(ULLONG_MAX)
#  if defined(ULONG_LONG_MAX)
#    define ULLONG_MAX ULONG_LONG_MAX
#  else
#    define ULLONG_MAX 18446744073709551615ULL
#  endif
#else
#  if !defined(ULONG_LONG_MAX)
#    define ULONG_LONG_MAX ULLONG_MAX
#  endif
#endif

/* Miscellaneous defines, including the maximum number of decimal digits
   for which mpz_t storage is to be reserved, and the corresponding
   maximum number of bits; __MAX_BITS__=ceil(__MAX_DIGITS__/log_10(2)). */

#undef __MAX_DIGITS__
#undef __MAX_BITS__

#define __MAX_DIGITS__ 1001000UL
#define __MAX_BITS__   (3*__MAX_DIGITS__ + __MAX_DIGITS__/3 + 1)

/* Custom gmp routines */

unsigned long long  _mpz_get_ull(mpz_t mpz);
void                _mpz_set_ull(mpz_t mpz, unsigned long long ull);
long double         _mpz_get_ld(mpz_t mpz);
void                _mpz_set_ld(mpz_t mpz, long double ld);
int                 _mpz_cmp_ld(mpz_t mpz, long double ld);

long double         _mpz_log10l(mpz_t mpz);
long double         _mpz_logl(mpz_t mpz);
void                _mpz_powl(mpz_t mpz, long double ldBase,
                      long double ldExp);
void                _mpz_expl(mpz_t mpz, long double ldExp);

#ifdef __i386__
long double         _mpf_get_ld(mpf_t mpf);
void                _mpf_set_ld(mpf_t mpf, long double ld);
long double         __strtold(char *sz, char **ep);
#else
long double         _mpf_get_ld2(mpf_t mpf);
void                _mpf_set_ld2(mpf_t mpf, long double ld);
#define             _mpf_get_ld _mpf_get_ld2
#define             _mpf_set_ld _mpf_set_ld2
#define             __strtold strtold
#endif

int                 __mpz_set_str(mpz_t mpz, char *sz, int iBase);
int                 __mpf_set_str(mpf_t mpf, char *sz, int iBase);

/* Prime number generation and testing */

void    vGenPrimes16(void);
int     iIsPrime32(unsigned long ulN);
int     iIsPrime64(unsigned long long ullN, unsigned long ulMaxDivisor);
int     iPrP(mpz_t mpzN, unsigned long ulNMR, unsigned long ulMaxDivisor);
unsigned long ulPrmDiv(mpz_t mpzN, unsigned long ulMaxDivisor);
int     iMillerRabin(mpz_t mpzN, unsigned long ulB);
int     iLucasSelfridge(mpz_t mpzN);
int     iStrongLucasSelfridge(mpz_t mpzN);
int     iExtraStrongLucas(mpz_t mpzN, long lB);

/* Functions returning (for x >= 2) Li(x); the Hardy-Littlewood integral
   approximations for the counts of twin primes, triplets, and
   quadruplets; Riemann's prime counting function R(x); and Riemann's
   zeta function. */

long double ldLogInt(long double ldx, long double *ldHL2,
  long double *ldHL3, long double *ldHL4);
long double ldLi(long double ldx);
long double ldRPCF(long double ldx);
void vDefineZetaArray(void);
long double ldZeta(long double ldx);

/* String editing */

char *szTrimMWS(char *pch);
char *szTrimTWS(char *pch);
char *szTrimLWS(char *pch);

/* Routines for analyzing prime gap records */

int         iRecordValidExt(char *sz);
int         iGetGapRecExt(char *szGapRec, FILE *fpIn);
void        vGapContExt(char *szContRec, char *szGapRec);
int         iGetGapRec(char *szGapRec, FILE *fpIn);
int         iRecordValid(char *szRec);
void        vGapCont(char *szContRec, char *szGapRec);

/* Miscellaneous routines */

void           vFlush(void);
int            __iLockMemory(void *MemStartAddress, unsigned long ulBytes);
unsigned long  __ulPhysicalMemoryAvailable(void);
int            iSignum(long double ldArg);
int            _isFile(char *szFileName);
int            _isRFile(char *szFileName);
int            _isRWFile(char *szFileName);
double         lfSeconds2(void);
unsigned long  ulSqrt(unsigned long long ull);
void           vAtExit(void);
void           vSigInt(int iSig);
void           _vZeroFile(FILE *fp, char *szName);

/* The GNU munlock function has no direct counterpart in DJGPP;
   DOS/W*ndows memory is unlocked when freed, unless it has
   been explicitly locked by means of Win32 or raw DPMI calls. */

#ifdef __DJGPP__
  #define munlock(pvoid, sizet) 0
#else
  #define stricmp(sz1, sz2) strcasecmp(sz1, sz2)
  #define strnicmp(sz1, sz2, i) strncasecmp(sz1, sz2, i)
  char *strlwr(char *sz);
  char *strupr(char *sz);
#endif

#define strcmpi(sz1, sz2) strcasecmp(sz1, sz2)
#define strncmpi(sz1, sz2, i) strncasecmp(sz1, sz2, i)

#undef  _iSignum
#define _iSignum iSignum

/* Expression parser for mpz bigints. iEvalExpr and iParseMPZ are
   deprecated identifiers. */

int     iEvalExprMPZ(mpz_t mpzResult, char *szExpression);
#define iEvalExpr iEvalExprMPZ
#define iParseMPZ iEvalExprMPZ

/**********************************************************************/
/*********************** LONG DOUBLE FUNCTIONS ************************/
/**********************************************************************/

#if defined(__i386__) && defined(__DJGPP__) && (__DJGPP <= 2) \
  && defined(__DJGPP_MINOR__) && (__DJGPP_MINOR__ <= 4)

/* Custom long double routines, implemented in trn.c with inline assembly
   specific to the x87 coprocessors. The corresponding intrinsic long
   double routines, mandated by C99 and gnu99, appear to be missing
   from versions of DJGPP through 2.04. Presumably they will be
   supported in ports of GNU C, versions 4.00 and beyond. */

#undef ceill
#undef expl
#undef fabsl
#undef floorl
#undef fmodl
#undef iSignum
#undef logl
#undef log10l
#undef powl
#undef sqrtl
#undef __strtold

long double         ceill(long double ldArg);
long double         expl(long double ldArg);
long double         fabsl(long double ldArg);
long double         floorl(long double ldArg);
long double         fmodl(long double ldTop, long double ldBottom);
long double         logl(long double ldArg);
long double         log10l(long double ldArg);
long double         log2l(long double ldArg);
long double         powl(long double ldBase, long double ldExp);
long double         sqrtl(long double ldArg);

#endif

#ifdef __i386__
char *              szLDtoHex(char *sz, long double ld);
#endif

#if defined(__DJGPP__) && (__DJGPP <= 2) \
    && defined(__DJGPP_MINOR__) && (__DJGPP_MINOR__ <= 4)
  #define strtold         _strtold
#else
  #define _atold(x)        strtold(x, NULL)
  #define _strtold         strtold
#endif

#undef __nearbyintl
long double __nearbyintl(long double ld);  /* custom implementation */

/**********************************************************************/
/********************* END LONG DOUBLE FUNCTIONS **********************/
/**********************************************************************/

/**********************************************************************/
/****************** CONIO EMULATIONS FOR NON-DOS **********************/
/**********************************************************************/

#ifndef __MSDOS__

/* At this time, only the screenheight and screenwidth fields return
   meaningful values from gettextinfo. */

struct text_info {
    unsigned char winleft;        /* left window coordinate */
    unsigned char wintop;         /* top window coordinate */
    unsigned char winright;       /* right window coordinate */
    unsigned char winbottom;      /* bottom window coordinate */
    unsigned char attribute;      /* text attribute */
    unsigned char normattr;       /* text attribute at progr invoc */
    unsigned char currmode;       /* BW40, BW80, C40, C80, C4350 */
    unsigned char screenheight;   /* lines per screen */
    unsigned char screenwidth;    /* characters per line */
    unsigned char curx;           /* cursor x-coord in current window */
    unsigned char cury;           /* cursor y-coord in current window */
};

enum text_modes { LASTMODE=-1, BW40=0, C40, BW80, C80, MONO=7, C4350=64 };

enum COLORS {
    /*  dark colors  */
    BLACK,
    BLUE,
    GREEN,
    CYAN,
    RED,
    MAGENTA,
    BROWN,
    LIGHTGRAY,
    /*  light colors  */
    DARKGRAY, /* charcoal */
    LIGHTBLUE,
    LIGHTGREEN,
    LIGHTCYAN,
    LIGHTRED,
    LIGHTMAGENTA,
    YELLOW,
    WHITE
};

void clrscr(void);
int  getch(void);
void gettextinfo(struct text_info *ti);
void gotoxy(int x, int y);
void highvideo(void);
void lowvideo(void);
void normvideo(void);

/**********************************************************************/
/**********************************************************************/

/* The functionality of the following CONIO routines is not presently
   supported outside of DOS; the placeholders simply return (in the
   case of kbhit, with a value of zero). */

int kbhit(void);
void textmode(int newmode);
void textattr(int newattr);
void textbackground(int newcolor);
void textcolor(int newcolor);

#endif  /* conio emulations for non-DOS */

/**********************************************************************/
/************************** CONIO EXTENSIONS **************************/
/**********************************************************************/

/* The following function will clear the current line, leave the cursor
   at the left margin, and set the global extern variables __iSW and
   __iSH to the current screen width and screen height. */

void __clearline(void);

#undef __CLEAR_LINE__
#define __CLEAR_LINE__  __clearline()

void __nocursor(void);
void __normalcursor(void);

/**********************************************************************/
/**********************************************************************/
/*                                                                    */
/* Define deprecrated identifiers to be equivalent to current ones.   */
/*                                                                    */
/* To activate this section, place the directive                      */
/* #define _OLD_IDENTIFIERS_TRN just before #include "trn.h".         */
/*                                                                    */
/**********************************************************************/
/**********************************************************************/

#ifdef _OLD_IDENTIFIERS_TRN

#undef _ceill
#undef _expl
#undef _fabsl
#undef _floorl
#undef _fmodl
#undef _logl
#undef _log10l
#undef _powl
#undef _sqrtl

#define _ceill     ceill
#define _expl      expl
#define _fabsl     fabsl
#define _floorl    floorl
#define _fmodl     fmodl
#define _logl      logl
#define _log10l    log10l
#define _powl      powl
#define _sqrtl     sqrtl

#ifndef CLEAR_LINE
  #define CLEAR_LINE __clearline()
#endif
#ifndef fzero
  #define fzero _vZeroFile
#endif
#ifndef MAX_DIGITS
  #define MAX_DIGITS __MAX_DIGITS__
#endif
#ifndef MAX_BITS
  #define MAX_BITS __MAX_BITS__
#endif
#ifndef VSPACE
  #define VSPACE __OBSL__
#endif
#ifndef __PRINT_BLANK_LINE__
  #define __PRINT_BLANK_LINE__ __OBSL__
#endif

#endif  /* _OLD_IDENTIFIERS_TRN */

#endif  /* _TRN_H_ */
