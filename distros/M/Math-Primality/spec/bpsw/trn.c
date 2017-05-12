/* trn.c                 Thomas R. Nicely          2007.02.09.2300
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
 * Common custom routines. Callable from co-compiled or linked codes.
 *
 */

#ifndef _GNU_SOURCE
  #define _GNU_SOURCE 1
#endif
#ifndef __USE_GNU
  #define __USE_GNU 1
#endif

#include "trn.h"
#include <assert.h>
#include <ctype.h>
#include <float.h>
#include <limits.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <sys/mman.h>
#include <sys/time.h>
#include <sys/stat.h>
#include <termios.h>
#include <time.h>
#include <unistd.h>
#include <gmp.h>
#ifdef __MSDOS__
  #include <conio.h>
#else
  #include <sys/ioctl.h>
//  #include <sys/sysinfo.h>
  #include <sys/sysctl.h>
#endif

/* M_EPSILON1 is the convergence tolerance in several calculations. */

#define M_EPSILON1 LDBL_EPSILON

/* The following external variables may be accessed from linked codes
   by declaring them "extern" in those codes. */

int __iSW, __iSH;  /* screen size in columns and rows */
unsigned long ulDmax=0;  /* tracks global max of Lucas-Selfridge |D| */
unsigned long ulPrime16[6545];  /* array of 16-bit primes < 65538 */
long double ldZ[66];  /* Zeta function values zeta(2..65) */

/**********************************************************************/
/************************ CONIO EXTENSIONS ****************************/
/**********************************************************************/
void __clearline(void)
{
/* Clear the entire current line and leave the cursor at the left
   margin. Set the global extern variables __iSW and __iSH to the
   current screen width and screen height. Attempt to minimize execution
   time; some methods of doing this, such as system("tput el"), use up
   nearly a million CPU cycles. */

static char sz[132]="\0";
int iSW=132;
struct text_info ti;

if(__iSW < 2)
  {
  gettextinfo(&ti);
  __iSW=ti.screenwidth;
  __iSH=ti.screenheight;
  if(__iSW < 2)__iSW=80;
  if(__iSH < 2)__iSH=25;
  }

#ifdef __MSDOS__

  fprintf(stderr, "\r");
  clreol();
  fprintf(stderr, "\r");

#else

if(*sz==0)
  {
  if(__iSW < 132)iSW=__iSW;
  memset(sz, ' ', iSW-1);
  sz[iSW-1]=0;
  }
fprintf(stderr, "\r%s\r", sz);

#endif

return;
}
/**********************************************************************/
void __nocursor(void)
{
#ifdef __DJGPP__
_setcursortype(_NOCURSOR);  /* from <conio.h> */
#elif defined(__unix__)
system("tput civis");
#endif
return;
}
/**********************************************************************/
void __normalcursor(void)
{
#ifdef __DJGPP__
_setcursortype(_NORMALCURSOR);
#elif defined(__unix__)
system("tput cnorm");
#endif
return;
}
/**********************************************************************/
/**********************************************************************/

#ifndef __MSDOS__

/**********************************************************************/
/************** NON-DOS CONIO SIMULATION CALLS ************************/
/**********************************************************************/
/* A small subset of emulated conio (screen control) functions for    */
/* non-DOS systems.                                                   */
/**********************************************************************/
/**********************************************************************/

/**********************************************************************/
void clrscr(void)
{
system("clear");
return;
}
/**********************************************************************/
int getch(void)
{
/* Emulates the DJGPP/B*rland C function getch(), which returns the
   first keystroke detected, immediately and without echo. */

char ch;
struct termios attr, attrSaved;

if (!isatty(STDIN_FILENO))
  {
  fprintf(stderr, "\n ERROR in getch: stdin is not a terminal.\n\n");
  exit(EXIT_FAILURE);
  }
tcgetattr(STDIN_FILENO, &attrSaved);
tcgetattr(STDIN_FILENO, &attr);
attr.c_lflag &= ~(ICANON|ECHO); /* Clear ICANON and ECHO */
attr.c_cc[VMIN]=1;  /* one input character */
attr.c_cc[VTIME]=0;  /* wait forever */
tcsetattr(STDIN_FILENO, TCSANOW, &attr);
read(STDIN_FILENO, &ch, 1);
tcsetattr(STDIN_FILENO, TCSAFLUSH, &attr);  /* discard excess input */
tcsetattr(STDIN_FILENO, TCSANOW, &attrSaved);  /* reset terminal */
return(ch);
}
/**********************************************************************/
void gettextinfo(struct text_info *ti)
{
/* Emulates the DOS/DJGPP/B*rland conio function gettextinfo, which
   returns video (terminal) state information. Currently, all values
   are zeroed except the screen width (number of columns, i.e.,
   characters per line) and screen height (number of rows or lines). */

struct winsize ws;

ti->winleft=0;
ti->wintop=0;
ti->winright=0;
ti->winbottom=0;
ti->attribute=0;
ti->normattr=0;
ti->currmode=0;
ti->screenheight=0;
ti->screenwidth=0;
ti->curx=0;
ti->cury=0;
if(!ioctl(STDIN_FILENO, TIOCGWINSZ, &ws))
  {
  ti->screenwidth=ws.ws_col;
  ti->screenheight=ws.ws_row;
  __iSW=ws.ws_col;
  __iSH=ws.ws_row;
  }
return;
}
/**********************************************************************/
void gotoxy(int iCol, int iRow)
{
char sz[18];
int iNumCols, iNumRows;
struct text_info ti;

gettextinfo(&ti);
iNumCols=ti.screenwidth;
iNumRows=ti.screenheight;
iCol--; iRow--;  /* (1,1) DOS is (0,0) Un*x */
if(iCol < 0)iCol=0;
if(iRow < 0)iRow=0;
/* keep it on screen */
if(iCol >= iNumCols)iCol=iCol%iNumCols;
if(iRow >= iNumRows)iRow=iRow%iNumRows;
sprintf(sz, "tput cup %d %d", iRow, iCol);  /* tput expects row first */
system(sz);
return;
}
/**********************************************************************/
void highvideo(void)
{
system("tput bold");
return;
}
/**********************************************************************/
void lowvideo(void)
{
system("tput dim");
return;
}
/**********************************************************************/
void normvideo(void)
{
system("tput sgr0");
return;
}
/**********************************************************************/
/**********************************************************************/
/* Placeholders for conio routines not presently supported outside    */
/* of DOS.                                                            */
/**********************************************************************/
/**********************************************************************/
int kbhit(void)
{
return(0);  /* No keystroke available (detectable) */
}
/**********************************************************************/
void textmode(int newmode)
{
return;
}
/**********************************************************************/
void textattr(int newattr)
{
return;
}
/**********************************************************************/
void textbackground(int newcolor)
{
return;
}
/**********************************************************************/
void textcolor(int newcolor)
{
return;
}
/**********************************************************************/
/**********************************************************************/
#if 0  /* This routine is still under development */
/**********************************************************************/
int __kbhit(void)
{
/* _Attempts_ a non-DOS emulation of the DJGPP/B*rland C function kbhit().
   In DOS, kbhit() will return either 0 or 1 _immediately_, indicating
   if a completed keystroke is available (1) in the keyboard
   buffer (some prefix keys, such as CTRL, are not reported until the
   suffix, such as A, is pressed); this keystroke can then be
   retrieved via getch(). The present emulation, however, requires
   TWO keystrokes, and only returns the second; the extra keystroke
   is demanded, for unknown reasons, by the final tcsetattr call. */

int nBytes=0;
static int iFirstCall=1;
struct termios attr;
static struct termios attrSaved;

if(iFirstCall)
  {
  iFirstCall=0;
  if (!isatty(STDIN_FILENO))
    {
    fprintf(stderr, "\n ERROR in __kbhit: stdin is not a terminal.\n\n");
    exit(EXIT_FAILURE);
    }
  tcgetattr(STDIN_FILENO, &attrSaved);
  tcgetattr(STDIN_FILENO, &attr);
  attr.c_lflag &= ~(ICANON|ECHO); /* Clear ICANON and ECHO */
  attr.c_cc[VMIN]=0;
  attr.c_cc[VTIME]=0;  /* force read to return presto. */
  tcsetattr(STDIN_FILENO, TCSANOW, &attr);
  }
ioctl(STDIN_FILENO, FIONREAD, &nBytes);  /* query keyboard buffer */
if(nBytes)
  {
  /* The following call resets the terminal to canonical mode.
     Unfortunately, it also demands input of another keystroke,
     an undocumented and fatal feature. */
  tcsetattr(STDIN_FILENO, 0, &attrSaved);
  return(1);
  }
return(0);
}
/**********************************************************************/
/**********************************************************************/
#endif  /* unimplemented non-DOS conio routines */
#endif  /* non-DOS conio routines */

/**********************************************************************/
/**********************************************************************/
/* Long double floating point arithmetic routines. If an x87 FPU is   */
/* present, inline assembly is used to retrieve the result from the   */
/* FPU. If not, the default double precision result is returned.      */
/*                                                                    */
/* If the compiler is C99 and gnu99 compliant, the built-ins (fabsl,  */
/* cosl, powl, etc.) can be called instead. However, DJGPP versions   */
/* through 2.04 appear to leave long double floating point function   */
/* calls unimplemented.                                               */
/**********************************************************************/
/**********************************************************************/

#if defined(__i386__) && defined(__DJGPP__) && (__DJGPP <= 2) \
  && defined(__DJGPP_MINOR__) && (__DJGPP_MINOR__ <= 4)

int __iFPU=0;  /* Will indicate presence of x87 hardware FPU */

/**********************************************************************/
long double fabsl(long double ldArg)
{
if(ldArg >= 0)return(ldArg);
return(-ldArg);
}
/**********************************************************************/
long double ceill(long double ldArg)
{
unsigned short uhCWSave, uhCWTemp;
long double ldResult;

if(__iFPU==0)__iFPU=_detect_80387();
if(__iFPU==0)return((long double)ceil(ldArg));
asm("fstcw %0" : "=m" (uhCWSave) :);
uhCWTemp=uhCWSave & 0xFBFF;
uhCWTemp=uhCWTemp | 0x0800;
asm("fldcw %0" : : "m" (uhCWTemp));
asm("frndint" : "=t" (ldResult) : "0" (ldArg));
asm("fldcw %0" : : "m" (uhCWSave));
return(ldResult);
}
/**********************************************************************/
long double expl(long double ldExp)
{
long double ldExp2, ldInt, ldFrac, ldMant, ldResult;

if(__iFPU==0)__iFPU=_detect_80387();
if(__iFPU==0)return((long double)exp(ldExp));
ldExp2=M_LOG_E_BASE2*ldExp;
ldInt=floorl(ldExp2);
ldFrac=ldExp2 - ldInt;
asm("f2xm1" : "=t" (ldMant) : "0" (ldFrac));
ldMant += 1.0L;
asm("fscale" : "=t" (ldResult) : "0" (ldMant), "u" (ldInt));
return(ldResult);
}
/**********************************************************************/
long double floorl(long double ldArg)
{
unsigned short uhCWSave, uhCWTemp;
long double ldResult;

if(__iFPU==0)__iFPU=_detect_80387();
if(__iFPU==0)return((long double)floor(ldArg));
asm("fnstcw %0" : "=m" (uhCWSave) :);
uhCWTemp=uhCWSave & 0xF7FF;
uhCWTemp=uhCWTemp | 0x0400;
asm("fldcw %0" : : "m" (uhCWTemp));
asm("frndint" : "=t" (ldResult) : "0" (ldArg));
asm("fldcw %0" : : "m" (uhCWSave));
return(ldResult);
}
/**********************************************************************/
long double fmodl(long double ldTop, long double ldBottom)
{
long double ldRem, ldNumerator;

if(ldBottom==0)
  {
  fprintf(stderr,
    "\n ERROR: Zero modulus passed to fmodl.\n");
  signal(SIGFPE, SIG_DFL);
  raise(SIGFPE);
  exit(EXIT_FAILURE);
  }

if(__iFPU==0)__iFPU=_detect_80387();
if(__iFPU==0)return((long double)fmod(ldTop,ldBottom));
ldNumerator=ldTop;
while(1)
  {
  asm("fprem" : "=t" (ldRem) : "0" (ldNumerator), "u" (ldBottom));
  if(fabsl(ldRem) <= fabsl(ldBottom))break;
  ldNumerator=ldRem;
  }
return(ldRem);
}
/**********************************************************************/
long double logl(long double ldArg)
{
long double ldResult, ldLn_2=M_LN2;

if(ldArg <= 0)
  {
  fprintf(stderr,
    "\n ERROR: Non-positive argument passed to logl.\n");
  signal(SIGFPE, SIG_DFL);
  raise(SIGFPE);
  exit(EXIT_FAILURE);
  }

if(__iFPU==0)__iFPU=_detect_80387();
if(__iFPU==0)return((long double)log(ldArg));
asm("fyl2x" : "=t" (ldResult) : "0" (ldArg), "u" (ldLn_2) : "st(1)");
return(ldResult);
}
/**********************************************************************/
long double log10l(long double ldArg)
{
long double ldResult, ldLog10_2=M_LOG_2_BASE10;

if(ldArg <= 0)
  {
  fprintf(stderr,
    "\n ERROR: Non-positive argument passed to log10l.\n");
  signal(SIGFPE, SIG_DFL);
  raise(SIGFPE);
  exit(EXIT_FAILURE);
  }

if(__iFPU==0)__iFPU=_detect_80387();
if(__iFPU==0)return((long double)log10(ldArg));
asm("fyl2x" : "=t" (ldResult) : "0" (ldArg), "u" (ldLog10_2) : "st(1)");
return(ldResult);
}
/**********************************************************************/
long double log2l(long double ldArg)
{
long double ldResult, ldOne=1.0L;

if(ldArg <= 0)
  {
  fprintf(stderr,
    "\n ERROR: Non-positive argument passed to log2l.\n");
  signal(SIGFPE, SIG_DFL);
  raise(SIGFPE);
  exit(EXIT_FAILURE);
  }

if(__iFPU==0)__iFPU=_detect_80387();
if(__iFPU==0)return((long double)(log(ldArg)/log(2)));
asm("fyl2x" : "=t" (ldResult) : "0" (ldArg), "u" (ldOne) : "st(1)");
return(ldResult);
}
/**********************************************************************/
long double powl(long double ldBase, long double ldExp)
{
long double ld2Exp, ldInt, ldFrac, ldMant, ldResult;

if(ldBase <= 0)
  {
  fprintf(stderr,
    "\n ERROR: Non-positive base passed to powl.\n");
  signal(SIGFPE, SIG_DFL);
  raise(SIGFPE);
  exit(EXIT_FAILURE);
  }

if(__iFPU==0)__iFPU=_detect_80387();
if(__iFPU==0)return((long double)pow(ldBase, ldExp));
/* Evaluate as 2^(ldExp*log(ldBase,2)); do exponent expression first */
asm("fyl2x" : "=t" (ld2Exp) : "0" (ldBase), "u" (ldExp) : "st(1)");
/* Separate exponent result into integer and fractional parts */
ldInt=floorl(ld2Exp);
ldFrac=ld2Exp - ldInt;
asm("f2xm1" : "=t" (ldMant) : "0" (ldFrac));  /* 2^(fr part) - 1 */
ldMant += 1.0L;  /* 2^(fr part) */
/* Now multiply by 2^(integer part */
asm ("fscale" : "=t" (ldResult) : "0" (ldMant), "u" (ldInt));
return(ldResult);
}
/**********************************************************************/
long double sqrtl(long double ldArg)
{
long double ldResult;

if(ldArg < 0)
  {
  fprintf(stderr,
    "\n ERROR: Negative argument passed to sqrtl.\n");
  signal(SIGFPE, SIG_DFL);
  raise(SIGFPE);
  exit(EXIT_FAILURE);
  }
if(__iFPU==0)__iFPU=_detect_80387();
if(__iFPU==0)return((long double)sqrt(ldArg));
asm("fsqrt" : "=t" (ldResult) : "0" (ldArg));
return(ldResult);
}
/**********************************************************************/
#endif  /* i387 and DJGPP <= 2.04 */
/**********************************************************************/
long double __nearbyintl(long double ldArg)
{
/* The nearbyintl function of C99 is simulated. This is done for two
   reasons: (1) DJGPP 2.03 does not support nearbyintl; (2) GCC 4.14,
   at least as implemented in SUSE Linux 10.0, has a bug in nearbyintl
   which unpredictably interferes with the cast of its value to an
   unsigned long long.

   Thus, -4.5 and -3.5 must both be rounded to -4. No error trapping is
   included. Assuming a mantissa of 64 bits (as in the x87 hardware),
   the return will be unreliable for values of |ld| > 2^63. Be aware
   also that some implementations of strtold (also _atold, printf, etc.)
   have problems correctly converting the 20th and succeeding significant
   decimal digits (if present). */

unsigned short uhCWSave, uhCWTemp;
long double ldResult, ld2, ldInt, ldFrac;

#if defined(__i386__) && defined(__DJGPP__) && (__DJGPP <= 2) \
  && defined(__DJGPP_MINOR__) && (__DJGPP_MINOR__ <= 4)

if(__iFPU==0)__iFPU=_detect_80387();
if(__iFPU)
  {
  asm("fstcw %0" : "=m" (uhCWSave) :);  /* store FPU control word */
  uhCWTemp=uhCWSave & 0xF3FF;  /* clear rounding bits ==> nearest/even */
  asm("fldcw %0" : : "m" (uhCWTemp));  /* load new control word */
  asm("frndint" : "=t" (ldResult) : "0" (ldArg));  /* bankers' rounding */
  asm("fldcw %0" : : "m" (uhCWSave));  /* restore previous control word */
  return(ldResult);
  }

#endif  /* i387 and DJGPP <= 2.04 */

ld2=floorl(ldArg);
ldFrac=modfl(ldArg, &ldInt);
if(fabsl(ldFrac)==0.5L)  /* Round to nearest even integer */
  {
  if(fabsl(fmodl(ld2, 2)) < 0.5L)  /* Is ld2 even? */
    return(ld2);
  else
    return(ld2 + 1);
  }
return(floorl(ldArg + 0.5L));
}
/**********************************************************************/
#ifdef __i386__
/**********************************************************************/
char *szLDtoHex(char *sz, long double ld)
{
/*
 * Converts a long double to a string containing the ten-byte (Intel
 * x86/x87) hex representation. ASSUMPTIONS: short integers are 16 bits;
 * long longs are 64 bits; long doubles are 80-bit format (IEEE
 * 754 double extended), or 96 bits including 16 bits of padding.
 *
 * Returning the result as both a function argument and function value
 * may appear redundant. However, returning the result from a local
 * automatic variable is not allowed. Returning the result from a local
 * static variable is allowed, but would produce unexpected results in
 * a statement such as
 *
 * printf("\n 10==>%s   -10==>%s\n", szLDtoHex2(10), szLDtoHex2(-10));
 *
 * A single value (the result for 10) is printed twice! This will also
 * occur if the present function is used and the same target string
 * is referenced in both calls. Looks like a bug in printf to me---but
 * that's the way it works in both DJGPP DOS and SUSE Linux.
 *
 */

short h;
long long *pll, ll;

pll=(long long *)(&ld);
ll=*(pll);
h=*((short *)(++pll));
sprintf(sz, "0x%04hX%016llX", h, ll);
return(sz);
}
/**********************************************************************/
#endif  /* i386 */
/**********************************************************************/
/**********************************************************************/
/*                    GMP mpz BIGINT functions                        */
/**********************************************************************/
/**********************************************************************/
unsigned long long _mpz_get_ull(mpz_t mpz)
{
/* Return the value of mpz as an unsigned long long.  If the value of mpz
   overflows the ULL range, abort.

   It is assumed that mpz limbs and unsigned longs have equal allocation
   (usually 32 bits), and an unsigned long long has twice as much
   allocation (usually 64 bits). */

unsigned long          iLimbs;
static int             iConforms=0;

/* If the host system does not conform to the above assumptions, use
   mpz_set_str, mpz_get_str, and sprintf to carry out the assignment. */

if(!iConforms)
  {
  unsigned long ul, ul2, ul3;
  ul=sizeof(mp_limb_t);
  ul2=sizeof(unsigned long);
  ul3=sizeof(unsigned long long);
  if((ul != ul2) || (ul3 != ul2 << 1))
    {
    mpz_t mpzMAX;
    char *szULL = (char *)malloc(2 + ceil(log10(ULONG_LONG_MAX)));
    mpz_init2(mpzMAX, floor(0.5 + log10(ULONG_LONG_MAX)/log10(2)));
    iConforms=0;
    sprintf(szULL, "%llu", ULONG_LONG_MAX);
    __mpz_set_str(mpzMAX, szULL, 10);
    if((mpz_sgn(mpz) >= 0) && (mpz_cmp(mpz, mpzMAX) <= 0))
      {
      mpz_get_str(szULL, 10, mpz);
      unsigned long long ull=strtoull(szULL, NULL, 10);
      free(szULL);
      mpz_clear(mpzMAX);
      return(ull);
      }
    else
      {
      fprintf(stderr, "\n\n ERROR: Domain error in _mpz_get_ull:\nmpz=");
      mpz_out_str(stderr, 10, mpz);
      fprintf(stderr, "\n\n");
      exit(EXIT_FAILURE);
      }
    }
  else
    iConforms=1;
  }

iLimbs=mpz->_mp_size;
if(iLimbs==0)return(0);
if(iLimbs==1)return((unsigned long long)mpz->_mp_d[0]);
if(iLimbs==2)
  return((ULONG_MAX + 1ULL)*mpz->_mp_d[1] + mpz->_mp_d[0]);
fprintf(stderr, "\n\n ERROR: Domain error in _mpz_get_ull:\nmpz=");
mpz_out_str(stderr, 10, mpz);
fprintf(stderr, "\n\n");
exit(EXIT_FAILURE);
}
/**********************************************************************/
void _mpz_set_ull(mpz_t mpz, unsigned long long ull)
{
/* Set a previously initialized mpz to the unsigned long long value ull.
   It is assumed that mpz limbs and unsigned longs have equal allocation
   (usually 32 bits), and an unsigned long long has twice as much
   allocation (usually 64 bits). */

unsigned long          ul;
static int             iConforms=0;

if(ull <= ULONG_MAX)
  {
  mpz_set_ui(mpz, (unsigned long)ull);
  return;
  }

/* If the host system does not conform to the above assumptions, use
   sprintf and mpz_set_str to carry out the assignment. */

if(!iConforms)
  {
  unsigned long ul2, ul3;
  ul=sizeof(mp_limb_t);
  ul2=sizeof(unsigned long);
  ul3=sizeof(unsigned long long);
  if((ul != ul2) || (ul3 != ul2 << 1))
    {
    char *szULL=
      (char *)malloc(3 + (sizeof(unsigned long long)*CHAR_BIT*3)/10);
    iConforms=0;
    sprintf(szULL, "%llu", ull);
    __mpz_set_str(mpz, szULL, 10);
    free(szULL);
    return;
    }
  else
    iConforms=1;
  }

/* Conforming system, true unsigned long long */

if(mpz->_mp_alloc < 2)_mpz_realloc(mpz,2);
ul=ull/(ULONG_MAX + 1ULL);  /* high doubleword */
mpz->_mp_d[1]=ul;
mpz->_mp_d[0]=ull - ul*(ULONG_MAX + 1ULL);  /* low doubleword */
mpz->_mp_size=2;

return;
}
/**********************************************************************/
long double _mpz_get_ld(mpz_t mpz)
{
char            *pch;
long double     ld;

pch=(char *)malloc(mpz_sizeinbase(mpz, 10) + 2);
mpz_get_str(pch, 10, mpz);
ld=__strtold(pch, NULL);
free(pch);
return(ld);
}
/**********************************************************************/
void _mpz_set_ld(mpz_t mpz, long double ld)
{
char *pch;

if(ld==0)
  {
  mpz_set_ui(mpz, 0);
  return;
  }
pch=(char *)malloc((unsigned long)(5 + fabsl(log10l(fabsl(ld)))));
sprintf(pch, "%.0Lf", ld);
__mpz_set_str(mpz, pch, 10);
free(pch);
return;
}
/**********************************************************************/
int _mpz_cmp_ld(mpz_t mpz, long double ld)
{
int iSignMPZ, iComp;
mpz_t mpzLD;

iSignMPZ=mpz_sgn(mpz);
if((iSignMPZ < 0) && (ld >=0))return(-1);
if((iSignMPZ >= 0) && (ld < 0))return(1);
if((iSignMPZ==0) && (ld==0))return(0);

mpz_init2(mpzLD, (1 + ceill(log10l(fabsl(ld))))*mp_bits_per_limb);
_mpz_set_ld(mpzLD, ld);
iComp=mpz_cmp(mpz, mpzLD);
mpz_clear(mpzLD);
return(iComp);
}
/**********************************************************************/
long double _mpz_log10l(mpz_t mpz)
{
char            *pch, szMant[26];
int             i;
unsigned long   ulExp;
long double     ld;

if(mpz_sgn(mpz) <= 0)
  {
  fprintf(stderr, "\n ERROR: Domain error in _mpz_log10l.\n\n");
  exit(EXIT_FAILURE);
  }
gmp_asprintf(&pch, "%Zd", mpz);
ulExp=strlen(pch)-1;
if(mpz_sgn(mpz) < 0)
  {
  ulExp--;
  szMant[0]=pch[0];
  szMant[1]=pch[1];
  szMant[2]='.';
  for(i=3; i < 25; i++)szMant[i]=pch[i-1];
  szMant[25]=0;
  }
else
  {
  szMant[0]=pch[0];
  szMant[1]='.';
  for(i=2; i < 24; i++)szMant[i]=pch[i-1];
  szMant[24]=0;
  }
ld=ulExp + log10l(__strtold(szMant, NULL));
free(pch);
return(ld);
}
/**********************************************************************/
long double _mpz_logl(mpz_t mpz)
{
return(_mpz_log10l(mpz)*M_LN10);
}
/**********************************************************************/
void _mpz_powl(mpz_t mpz, long double ldBase, long double ldExp)
{
long double ld10Exp, ldIntExp, ldFracExp, ldMant, ldMant2, ld;
mpz_t mpz1, mpz2;

if(ldBase <= 0)
  {
  fprintf(stderr,
    "\n ERROR: Domain error (base <= 0) in _mpz_powl.\n\n");
  exit(EXIT_FAILURE);
  }
ld=powl(ldBase, ldExp);
_mpz_set_ld(mpz, ld);
return;
#if 0
ld10Exp=ldExp*log10l(ldBase);
ldIntExp=floorl(ld10Exp);    /* whole part of exponent */
ldFracExp=ld10Exp-ldIntExp;  /* fractional part */
ldMant=powl(10, ldFracExp);
if(ldIntExp > 20)
  {
  mpz_init2(mpz1, ceil(ldIntExp/M_LOG_2_BASE10));
  mpz_ui_pow_ui(mpz1, 10, (unsigned long)(ldIntExp - 20));
  ldMant2=floorl(ldMant*1e20L + 0.5L);
  mpz_init2(mpz2, 4*mp_bits_per_limb);
  _mpz_set_ld(mpz2, ldMant2);
  mpz_mul(mpz, mpz1, mpz2);
  }
else
  {
  ldMant2=floorl(ldMant*powl(10, ldIntExp) + 0.5);
  _mpz_set_ld(mpz, ldMant2);
  }
mpz_clear(mpz1);
mpz_clear(mpz2);
return;
#endif
}
/**********************************************************************/
void _mpz_expl(mpz_t mpz, long double ldExp)
{
long double ld;

ld=expl(ldExp);
_mpz_set_ld(mpz, ld);
return;

#if 0  /* alternate implementation has limitations */
_mpz_powl(mpz, M_E, ldExp);
return;
#endif
}
/**********************************************************************/
/**********************************************************************/
/*                         GMP mpf functions                          */
/**********************************************************************/
/**********************************************************************/
#ifdef __i386__
/**********************************************************************/
long double _mpf_get_ld(mpf_t mpf)
{
/* Convert an mpf to a long double stored in IEEE 754 extended double
   format (Intel x86/x87 ten-byte extended or temporary reals). The
   use of 39 mantissa digits works around a GMP bug. */

static char sz[64];

gmp_sprintf(sz, "%.39Fe", mpf);
return(__strtold(sz, NULL));  /* assumes long double is 10-byte IEEE 754 */
}
/***********************************************************************/
void _mpf_set_ld(mpf_t mpf, long double ld)
{
/* Convert an intrinsic long double to its decimal mpf representation.
   It is assumed that the long doubles are stored in IEEE 754 extended
   double format (Intel x86/x87 ten-byte extended or temporary reals). */

int iSign=1;
unsigned short uh;
int iExp;
unsigned long ulLS, ulMS, *pLS, *pMS;
unsigned long long *pull, ull;

pull=(unsigned long long *)(&ld);
ull=*(pull);  /* Integer form of the ld mantissa */
uh=*((unsigned short *)(++pull));  /* Biased exponent plus sign bit */
if(uh & 0x8000)  /* Is ld negative? */
  {
  uh = uh & 0x7FFF;  /* Convert to magnitude */
  iSign=-1;
  }

iExp = uh - 0x3FFF;  /* Subtract bias */

/* Now iExp contains the exponent, iSign the sign, and ull the mantissa
   (shifted 63 bits to the right). Since GMP has no routine for assigning
   an unsigned long long to an mpf, we must retrieve the high and low
   32 bits of ull and calculate the mpf for ull indirectly. */

pMS=(unsigned long *)(&ld);
pLS=pMS++;
ulLS=*pLS;
ulMS=*pMS;

mpf_set_ui(mpf, ulMS);
mpf_mul_2exp(mpf, mpf, 32);
mpf_add_ui(mpf, mpf, ulLS);
mpf_div_2exp(mpf, mpf, 63);  /* True mantissa is shifted 63 bits */
if(iExp > 0)mpf_mul_2exp(mpf, mpf, iExp);
if(iExp < 0)mpf_div_2exp(mpf, mpf, -iExp);
if(iSign==-1)mpf_neg(mpf, mpf);

return;
}
/**********************************************************************/
long double __strtold(char *sz, char **ep)
{
/* Convert a string to the equivalent long double value; specifically,
   to the long double whose value is nearer to the string value than
   any other long double. Intended to give greater and more consistent
   precision than strtold, _strold, and _atold.

   NOTES:

   (1) It is assumed that the long doubles are stored in IEEE 754
       extended double format (Intel x86/x87 ten-byte extended
       or temporary reals). Otherwise, use strtold and hope for
       the best.
   (2) Some of the mpf's are redundant, but have been retained for
       readability.
*/

unsigned short uh, *puh;
int iSign, iExp;
static int iFirst=1;
unsigned long ulMSL, ulLSL, *pMSL, *pLSL;
unsigned long long *pull;
static long double ld;  /* ld must have an address to be returned */
static mpf_t mpf, mpf2, mpf3, mpf4, mpf5, mpfHalf;

if(ep)strtold(sz, ep);  /* Lazy method of setting ep */

if(iFirst)
  {
  mpf_init2(mpf, 512);
  mpf_init2(mpf2, 512);
  mpf_init2(mpf3, 512);
  mpf_init2(mpf4, 512);
  mpf_init2(mpf5, 512);
  mpf_init2(mpfHalf, 32);
  mpf_set_ui(mpfHalf, 1);
  mpf_div_2exp(mpfHalf, mpfHalf, 1);
  iFirst=0;
  }

__mpf_set_str(mpf, sz, 10);
iSign=mpf_sgn(mpf);
if(!iSign)return(0);
mpf_set(mpf2, mpf);
mpf_abs(mpf2, mpf2);
iExp=0;
if(mpf_cmp_ui(mpf2, 1) > 0)
  {
  while(mpf_cmp_ui(mpf2, 2) >= 0)
    {
    mpf_div_2exp(mpf2, mpf2, 1);
    iExp++;
    }
  }
else
  {
  while(mpf_cmp_ui(mpf2, 1) <= 0)
    {
    mpf_mul_2exp(mpf2, mpf2, 1);
    iExp--;
    }
  }
mpf_mul_2exp(mpf2, mpf2, 63);
mpf_add(mpf2, mpf2, mpfHalf);
mpf_floor(mpf2, mpf2);

/* mpf2 now contains the integer value of the 64-bit mantissa in
   the long double representation of sz. */

mpf_div_2exp(mpf3, mpf2, 32);
mpf_floor(mpf3, mpf3);  /* mpf3 = high 64-32 bits of mpf2 */
ulMSL=mpf_get_ui(mpf3);
mpf_mul_2exp(mpf4, mpf3, 32);  /* mpf2 with low 32 bits zeroed */
mpf_sub(mpf5, mpf2, mpf4);  /* mpf5 = low 64-32 bits of mpf2 */
ulLSL=mpf_get_ui(mpf5);

/* ulMSL and ulLSL are now the most significant and least significant
   32-bit unsigned integers of the 64-bit integer mantissa. */

pMSL=(unsigned long *)(&ld);
pLSL=pMSL++;
*pMSL=ulMSL;
*pLSL=ulLSL;

uh=iExp + 0x3FFF;  /* Exponent bias */
if(iSign < 0)uh += 0x8000;  /* Sign bit incorporated */

/* uh now contains the value of the 16-bit sign+biased exponent
   field of the long double representation of sz. */

pull=(unsigned long long *)(&ld);
puh=((unsigned short *)(++pull));
*puh=uh;

return(ld);
}
/**********************************************************************/
#endif  /* i386 */
/**********************************************************************/
int __mpz_set_str(mpz_t mpz, char *sz, int iBase)
{
/* Fixes a bug (feature?) in the GNU GMP floating-point library (noted
   in both version 4.01 and version 4.14). A leading plus sign in sz is
   not properly recognized, causing an erroneous value of zero to be
   assigned to mpz. The fix used is to check the first visible character
   in sz; if it is a '+', replace it with a space. */

char ch;
int i, j=-1, iRet;

for(i=0; i < strlen(sz); i++)
  {
  ch=sz[i];
  if(ch=='+')
    {
    sz[i]=' ';
    j=i;  /* save the change */
    break;
    }
  if(isgraph(ch))break; /* printing characters except space */
  }
iRet=mpz_set_str(mpz, sz, iBase);
if(j != -1)sz[i]='+';  /* restore sz */
return(iRet);
}
/**********************************************************************/
int __mpf_set_str(mpf_t mpf, char *sz, int iBase)
{
/* Fixes a bug (feature?) in the GNU GMP floating-point library (noted
   in both version 4.01 and version 4.14). A leading plus sign in sz is
   not properly recognized, causing an erroneous value of zero to be
   assigned to mpf. The fix used is to check the first visible character
   in sz; if it is a '+', replace it with a space. */

char ch;
int i, j=-1, iRet;

for(i=0; i < strlen(sz); i++)
  {
  ch=sz[i];
  if(ch=='+')
    {
    sz[i]=' ';
    j=i;  /* save the change */
    break;
    }
  if(isgraph(ch))break; /* printing characters except space */
  }
iRet=mpf_set_str(mpf, sz, iBase);
if(j != -1)sz[i]='+';  /* restore sz */
return(iRet);
}
/**********************************************************************/
long double _mpf_get_ld2(mpf_t mpf)
{
/* Returns a long double representation of the value of mpf. This version
   has better speed than _mpf_get_ld, and is not tied to the 80-bit IEEE
   floating point architecture. However, it may be inaccurate in the 19th
   and succeeding significant decimal digits, due to limitations in some
   implementations of gmp_sprintf. There is no overflow or other error
   trapping. The use of 39 mantissa digits works around a DJGPP 2.03 bug. */

static char sz[64];

gmp_sprintf(sz, "%.39Fe", mpf);
return(__strtold(sz, NULL));
}
/**********************************************************************/
void _mpf_set_ld2(mpf_t mpf, long double ld)
{
/* Converts a long double ld to its mpf equivalent. This version has
   better speed than _mpf_set_ld, and is not tied to the 80-bit IEEE
   floating point architecture. However, it may be inaccurate in the
   19th and succeeding significant decimal digits, due to limitations
   in some implementations of sprintf. There is no overflow or other error
   trapping. The use of 39 mantissa digits works around a DJGPP 2.03 bug. */

static char sz[64];

sprintf(sz, "%.39Le", ld);
__mpf_set_str(mpf, sz, 10);
return;
}
/**********************************************************************/
/**********************************************************************/
/*              Prime number generation and testing                   */
/**********************************************************************/
/**********************************************************************/
void vGenPrimes16(void)
{
/* Generate from scratch all the primes < 2^16 + 2. There are 6543 such
   primes, having a sum of 202353624. */

int             i;
unsigned long	ulSum=0, ulN, ul2, ulDivisor, ulQuot, ulRem;

if(ulPrime16[1]==2)return;
#if 0
for(i=1; i <= 6543; i++)ulSum += ulPrime16[i];
if(ulSum==202353624UL)return;
#endif

ulPrime16[0]=1;  /* just a marker */
ulPrime16[1]=2;
ulPrime16[2]=3;
i=3;
for(ulN=5; ulN < 65538UL; ulN += 2)
  {
  ul2=2;
  while(1)
    {
    ulDivisor=ulPrime16[ul2++];
    ulQuot=ulN/ulDivisor;
    if(ulQuot < ulDivisor)
      {
      ulPrime16[i++]=ulN;
      break;
      }
    ulRem=ulN - ulQuot*ulDivisor;
    if(ulRem==0)break;
    }
  }
ulPrime16[6544]=0;  /* end marker */

return;
}
/**********************************************************************/
int iIsPrime32(unsigned long ulN)
{
/* Returns 1 if ulN is prime, zero otherwise. No sieving is used. The
   routine simply checks for prime divisors up to the sqrt of ulN. */

unsigned long ulSqrtN, ul=2, ulDiv;

if((ulN < 3) || ((ulN & 1)==0))return(ulN==2 ? 1 : 0);
if(ulPrime16[6543] != 65537UL)vGenPrimes16();
ulSqrtN=ulSqrt(ulN);

while(1)
  {
  ulDiv=ulPrime16[ul++];
  if(ulDiv > ulSqrtN)return(1);
  if(ulN%ulDiv==0)return(0);
  }
}
/**********************************************************************/
int iIsPrime64(unsigned long long ullN, unsigned long ulMaxDivisor)
{
/* Returns 1 if ullN is prime, zero otherwise.  No sieving is used.
   The routine checks for prime divisors up to the smaller of the
   sqrt of ullN or ulMaxDivisor. If no prime divisor is found, and
   N > ulMaxDivisor^2 exceeds 2^32, the strong BPSW primality test
   is invoked. If 0 or 1 is specified for ulMaxDivisor, a default
   value of 65536 is used. */

int                iPrime;
unsigned long	   ulSqrtN, ul=2, ulDiv;
mpz_t              mpzN;

if((ullN < 3) || ((ullN & 1)==0))return(ullN==2 ? 1 : 0);
if(ulPrime16[6543] != 65537UL)vGenPrimes16();

if(ulMaxDivisor < 2)ulMaxDivisor=65536UL;
if(ulMaxDivisor > 65536UL)ulMaxDivisor=65536UL;

ulSqrtN=ulSqrt(ullN);
while(1)
  {
  ulDiv=ulPrime16[ul++];
  if(ulDiv > ulSqrtN)return(1);
  if(ulDiv > ulMaxDivisor)break;
  if(ullN%ulDiv==0)return(0);
  }

/* If there are no small prime divisors, we use the strong BPSW test
   for primality. */

mpz_init2(mpzN, 2*mp_bits_per_limb);
_mpz_set_ull(mpzN, ullN);
iPrime=iPrP(mpzN, 1, 1000);
mpz_clear(mpzN);
return(iPrime);
}
/**********************************************************************/
int iPrP(mpz_t mpzN, unsigned long ulNMR, unsigned long ulMaxDivisor)
{
/* Returns 1 if mpzN is a probable prime according to the strong
 * modified Baillie-PSW test.
 *
 * Returns 0 if mpzN is definitely composite.
 *
 * ulNMR indicates the total number of Miller-Rabin tests to be used;
 * the default is one (with b=2). If ulNMR > 1, ulNMR - 1 extra
 * Miller-Rabin tests will be carried out (ulNMR <= 6543), along with
 * with an additional floor(ulNMR/5) extra strong Lucas tests.
 *
 * ulMaxDivisor specifies the upper bound for small prime trial divisors
 * If 0 or 1 is specified, a default of 65536 is used.
 *
 * This test consists of the standard Baillie-PSW test enhanced as
 * follows: (1) The domain of trial divisors may be altered; (2) The
 * standard Lucas-Selfridge test is replaced with the strong
 * Lucas-Selfridge test; (2) The number of Miller-Rabin tests may be
 * increased by specifying ulNMR > 1; (3) if the total number of
 * Miller-Rabin tests ulNMR > 4, an additional extra strong Lucas test
 * is performed after each five Miller-Rabin tests.
 *
 */

int iComp2;
unsigned long ulDiv, ul;

/* First eliminate all N < 3 and all even N. */

iComp2=mpz_cmp_si(mpzN, 2);
if(iComp2 < 0)return(0);
if(iComp2==0)return(1);
if(mpz_even_p(mpzN))return(0);

/* Check for small prime divisors. */

if(ulMaxDivisor < 2)ulMaxDivisor=65536UL;

if(ulMaxDivisor > 2)
  {
  ulDiv=ulPrmDiv(mpzN, ulMaxDivisor);
  if(ulDiv==1)return(1);
  if(ulDiv > 1)return(0);
  }

/* Carry out the Miller-Rabin test with base 2. */

if(iMillerRabin(mpzN, 2)==0)return(0);

/* Now N is a prime, or a base-2 strong pseudoprime with no prime
   divisor < 65536. Apply the strong Lucas-Selfridge primality
   test. */

if(iStrongLucasSelfridge(mpzN)==0)return(0);

/* The following is in addition to the strong Baillie-PSW test.
   Additional Miller-Rabin tests (numbering ulNMR - 1) can be
   mandated, a strategy rumored to be in use by M*thematica.
   In addition, after each five Miller-Rabin tests, we perform
   an extra strong Lucas test. */

if(ulNMR < 2)return(1);
if(ulNMR > 6543)ulNMR=6543;
if(ulPrime16[6543] != 65537UL)vGenPrimes16();
for(ul=2; ul <= ulNMR; ul++)
  {
  if(iMillerRabin(mpzN, ulPrime16[ul])==0)return(0);
  if(ul%5==0)
    if(iExtraStrongLucas(mpzN, ulPrime16[ul/5 + 1])==0)return(0);
  }

return(1);
}
/**********************************************************************/
unsigned long ulPrmDiv(mpz_t mpzN, unsigned long ulMaxDivisor)
{
/* Returns the smallest proper prime divisor (p <= ulMaxDivisor) of N.

   If N < 2, return 0.
   If N is prime and "small", return 1. "Small" means N < approximately
     ulMaxDivisor^2.
   If N is prime and "large", return 0. "Large" means N > approximately
     ulMaxDivisor^2.
   If N is composite and its smallest prime divisor p <= ulMaxDivisor,
     return p.
   If N is composite but its smallest prime divisor p > ulMaxDivisor,
     return 0. In this case N will be "large", as above.

   A return of 0 indicates "no conclusion"; N might be < 2
   (questionable input), or N might be "large" (either prime
   or composite) and have no prime divisor p <= ulMaxDivisor.

   A return of 1 indicates that N is a "small" prime.

   A return > 1 indicates that N is composite, and the
   returned value is the smallest proper prime divisor of N.

   If ulMaxDivisor is zero or one, a default value of
   65536 is used.
*/

int iComp2;
unsigned long ul, ulDiv;
mpz_t mpzSqrt;

#undef RETURN
#define RETURN(n) {mpz_clear(mpzSqrt); return(n);}

/* First eliminate all N < 3 and all even N. */

iComp2=mpz_cmp_si(mpzN, 2);
if(iComp2 < 0)return(0);
if(iComp2==0)return(1);
if(mpz_even_p(mpzN))return(2);

if(ulPrime16[6543] != 65537UL)vGenPrimes16();
if(ulMaxDivisor < 2)ulMaxDivisor=65536UL;

mpz_init2(mpzSqrt, mpz_sizeinbase(mpzN, 2)/2 + mp_bits_per_limb);
mpz_sqrt(mpzSqrt, mpzN);

ul=2;  /* first trial divisor will be 3 */
while(1)
  {
  ulDiv=ulPrime16[ul++];
  if(ulDiv > ulMaxDivisor)RETURN(0);
  if(ulDiv > 65536UL)break;
  if(mpz_cmp_ui(mpzSqrt, ulDiv) < 0)RETURN(1);
  if(mpz_divisible_ui_p(mpzN, ulDiv))RETURN(ulDiv);
  }

/* If ulMaxDivisor exceeds 2^16, use trial divisors of the
   form 6n +/- 1. */

if(ulMaxDivisor > ULONG_MAX - 7)ulMaxDivisor=ULONG_MAX-7;

ulDiv=65537UL;
while(1)
  {
  if(ulDiv > ulMaxDivisor)break;
  if(mpz_cmp_ui(mpzSqrt, ulDiv) < 0)RETURN(1);
  if(mpz_divisible_ui_p(mpzN, ulDiv))RETURN(ulDiv);
  ulDiv += 2;
  if(ulDiv > ulMaxDivisor)break;
  if(mpz_cmp_ui(mpzSqrt, ulDiv) < 0)RETURN(1);
  if(mpz_divisible_ui_p(mpzN, ulDiv))RETURN(ulDiv);
  ulDiv += 4;
  }

RETURN(0);
}
/**********************************************************************/
int iMillerRabin(mpz_t mpzN, unsigned long ulB)
{
/* Test N for primality using the Miller-Rabin strong probable prime
   test with base B. Returns 1 if N is a prime or a base-B strong
   probable prime. Returns 0 if N is definitely composite. */

int           iComp2;
unsigned long ulGCD, ulBits, r, s;
mpz_t         mpzNm1, mpzd, mpzRem, mpzB;

#undef RETURN
#define RETURN(n)      \
  {                    \
  mpz_clear(mpzNm1);   \
  mpz_clear(mpzd);     \
  mpz_clear(mpzRem);   \
  mpz_clear(mpzB);     \
  return(n);           \
  }

/* First eliminate all N < 3 and all even N. */

iComp2=mpz_cmp_si(mpzN, 2);
if(iComp2 < 0)return(0);
if(iComp2==0)return(1);
if(mpz_even_p(mpzN))return(0);

/* The following steps prevent false negatives (e.g., N=B=3) by
   making sure N and B are relatively prime, and incrementing B
   if they are not. if 1 < GCD(N,B) < N, GCD is a proper
   divisor of N, and N is returned as composite. */

if(ulB < 2)ulB=2;

while(1)
  {
  ulGCD=mpz_gcd_ui(NULL, mpzN, ulB);
  if(ulGCD==1)break;
  if(mpz_cmp_ui(mpzN, ulGCD) > 0)return(0);
  ulB++;
  }

/* Application of a Fermat test at this point offers little
   or no overall speed advantage, and is omitted. We now
   allocate memory for the work variables. */

mpz_init_set_ui(mpzB, ulB);
ulBits=mpz_sizeinbase(mpzN, 2) + mp_bits_per_limb;
mpz_init2(mpzNm1, ulBits);
mpz_init2(mpzd, ulBits);
mpz_init2(mpzRem, 2*ulBits);  /* must contain products */

/* Find d and s, where d is odd and N - 1 = (2^s)*d. */

mpz_sub_ui(mpzNm1, mpzN, 1);
s=mpz_scan1(mpzNm1, 0);
mpz_tdiv_q_2exp(mpzd, mpzNm1, s);

/* Now proceed with the Miller-Rabin algorithm. First, if
   B^d is congruent to 1 or -1, mod N, N is a strong
   probable prime to base B. */

mpz_powm(mpzRem, mpzB, mpzd, mpzN);
if(mpz_cmp_ui(mpzRem, 1)==0)RETURN(1);
if(mpz_cmp(mpzRem, mpzNm1)==0)RETURN(1);

/* Now calculate B^2d, B^4d, B^8d, ..., B^((N-1)/2) by successive
   squaring. If any of these is congruent to -1 mod N, N is a
   sprp base B. */

for(r=1; r < s; r++)
  {
  mpz_mul(mpzRem, mpzRem, mpzRem);
  mpz_mod(mpzRem, mpzRem, mpzN);
  if(mpz_cmp(mpzRem, mpzNm1)==0)RETURN(1);
  }
RETURN(0);
}
/**********************************************************************/
int iLucasSelfridge(mpz_t mpzN)
{
/* Test mpzN for primality using Lucas's test with Selfridge's parameters.
   Returns 1 if mpzN is prime or a Lucas-Selfridge pseudoprime. Returns
   0 if mpzN is definitely composite. Note that a Lucas-Selfridge test
   typically requires three to seven times as many bit operations as a
   single Miller-Rabin test. The frequency of Lucas-Selfridge pseudoprimes
   appears to be roughly four times that of base-2 strong pseudoprimes;
   the Baillie-PSW test is based on the hope (verified by the author,
   May, 2005, for all N < 10^13; and by Martin Fuller, January, 2007,
   for all N < 10^15) that the two tests have no common pseudoprimes. */

int iComp2, iP, iJ, iSign;
long lDabs, lD, lQ;
unsigned long ulMaxBits, ulNbits, ul, ulGCD;
mpz_t mpzU, mpzV, mpzNplus1, mpzU2m, mpzV2m, mpzQm, mpz2Qm,
      mpzT1, mpzT2, mpzT3, mpzT4, mpzD;

#undef RETURN
#define RETURN(n)           \
  {                         \
  mpz_clear(mpzU);          \
  mpz_clear(mpzV);          \
  mpz_clear(mpzNplus1);     \
  mpz_clear(mpzU2m);        \
  mpz_clear(mpzV2m);        \
  mpz_clear(mpzQm);         \
  mpz_clear(mpz2Qm);        \
  mpz_clear(mpzT1);         \
  mpz_clear(mpzT2);         \
  mpz_clear(mpzT3);         \
  mpz_clear(mpzT4);         \
  mpz_clear(mpzD);          \
  return(n);                \
  }

/* This implementation of the algorithm assumes N is an odd integer > 2,
   so we first eliminate all N < 3 and all even N. As a practical matter,
   we also need to filter out all perfect square values of N, such as
   1093^2 (a base-2 strong pseudoprime); this is because we will later
   require an integer D for which Jacobi(D,N) = -1, and no such integer
   exists if N is a perfect square. The algorithm as written would
   still eventually return zero in this case, but would require
   nearly sqrt(N)/2 iterations. */

iComp2=mpz_cmp_si(mpzN, 2);
if(iComp2 < 0)return(0);
if(iComp2==0)return(1);
if(mpz_even_p(mpzN))return(0);
if(mpz_perfect_square_p(mpzN))return(0);

/* Allocate storage for the mpz_t variables. Most require twice
   the storage of mpzN, since multiplications of order O(mpzN)*O(mpzN)
   will be performed. */

ulMaxBits=2*mpz_sizeinbase(mpzN, 2) + mp_bits_per_limb;
mpz_init2(mpzU, ulMaxBits);
mpz_init2(mpzV, ulMaxBits);
mpz_init2(mpzNplus1, ulMaxBits);
mpz_init2(mpzU2m, ulMaxBits);
mpz_init2(mpzV2m, ulMaxBits);
mpz_init2(mpzQm, ulMaxBits);
mpz_init2(mpz2Qm, ulMaxBits);
mpz_init2(mpzT1, ulMaxBits);
mpz_init2(mpzT2, ulMaxBits);
mpz_init2(mpzT3, ulMaxBits);
mpz_init2(mpzT4, ulMaxBits);
mpz_init(mpzD);

/* Find the first element D in the sequence {5, -7, 9, -11, 13, ...}
   such that Jacobi(D,N) = -1 (Selfridge's algorithm). Although
   D will nearly always be "small" (perfect square N's having
   been eliminated), an overflow trap for D is present. */

lDabs=5;
iSign=1;
while(1)
  {
  lD=iSign*lDabs;
  iSign = -iSign;
  ulGCD=mpz_gcd_ui(NULL, mpzN, lDabs);
  /* if 1 < GCD < N then N is composite with factor lDabs, and
     Jacobi(D,N) is technically undefined (but often returned
     as zero). */
  if((ulGCD > 1) && mpz_cmp_ui(mpzN, ulGCD) > 0)RETURN(0);
  mpz_set_si(mpzD, lD);
  iJ=mpz_jacobi(mpzD, mpzN);
  if(iJ==-1)break;
  lDabs += 2;
  if(lDabs > ulDmax)ulDmax=lDabs;  /* tracks global max of |D| */
  if(lDabs > LONG_MAX-2)
    {
    fprintf(stderr,
      "\n ERROR: D overflows signed long in Lucas-Selfridge test.");
    fprintf(stderr, "\n N=");
    mpz_out_str(stderr, 10, mpzN);
    fprintf(stderr, "\n |D|=%ld\n\n", lDabs);
    exit(EXIT_FAILURE);
    }
  }

iP=1;         /* Selfridge's choice */
lQ=(1-lD)/4;  /* Required so D = P*P - 4*Q */

/* NOTE: The conditions (a) N does not divide Q, and
   (b) D is square-free or not a perfect square, are included by
   some authors; e.g., "Prime numbers and computer methods for
   factorization," Hans Riesel (2nd ed., 1994, Birkhauser, Boston),
   p. 130. For this particular application of Lucas sequences,
   these conditions were found to be immaterial. */

mpz_add_ui(mpzNplus1, mpzN, 1); /* must compute U_(N - Jacobi(D,N)) */

/* mpzNplus1 is always even, so the accumulated values U and V
   are initialized to U_0 and V_0 (if the target index were odd,
   U and V would be initialized to U_1=1 and V_1=P). In either case,
   the values of U_2m and V_2m are initialized to U_1 and V_1;
   the FOR loop calculates in succession U_2 and V_2, U_4 and
   V_4, U_8 and V_8, etc. If the corresponding bits of N+1 are
   on, these values are then combined with the previous totals
   for U and V, using the composition formulas for addition
   of indices. */

mpz_set_ui(mpzU, 0);           /* U=U_0 */
mpz_set_ui(mpzV, 2);           /* V=V_0 */
mpz_set_ui(mpzU2m, 1);         /* U_1 */
mpz_set_si(mpzV2m, iP);        /* V_1 */
mpz_set_si(mpzQm, lQ);
mpz_set_si(mpz2Qm, 2*lQ);

ulNbits=mpz_sizeinbase(mpzNplus1, 2);
for(ul=1; ul < ulNbits; ul++)  /* zero bit off, already accounted for */
  {
/* Formulas for doubling of indices (carried out mod N). Note that
 * the indices denoted as "2m" are actually powers of 2, specifically
 * 2^(ul-1) beginning each loop and 2^ul ending each loop.
 *
 * U_2m = U_m*V_m
 * V_2m = V_m*V_m - 2*Q^m
 */
  mpz_mul(mpzU2m, mpzU2m, mpzV2m);
  mpz_mod(mpzU2m, mpzU2m, mpzN);
  mpz_mul(mpzV2m, mpzV2m, mpzV2m);
  mpz_sub(mpzV2m, mpzV2m, mpz2Qm);
  mpz_mod(mpzV2m, mpzV2m, mpzN);
  if(mpz_tstbit(mpzNplus1, ul))
    {
/* Formulas for addition of indices (carried out mod N);
 *
 * U_(m+n) = (U_m*V_n + U_n*V_m)/2
 * V_(m+n) = (V_m*V_n + D*U_m*U_n)/2
 *
 * Be careful with division by 2 (mod N)!
 */
    mpz_mul(mpzT1, mpzU2m, mpzV);
    mpz_mul(mpzT2, mpzU, mpzV2m);
    mpz_mul(mpzT3, mpzV2m, mpzV);
    mpz_mul(mpzT4, mpzU2m, mpzU);
    mpz_mul_si(mpzT4, mpzT4, lD);
    mpz_add(mpzU, mpzT1, mpzT2);
    if(mpz_odd_p(mpzU))mpz_add(mpzU, mpzU, mpzN);
    mpz_fdiv_q_2exp(mpzU, mpzU, 1);
    mpz_add(mpzV, mpzT3, mpzT4);
    if(mpz_odd_p(mpzV))mpz_add(mpzV, mpzV, mpzN);
    mpz_fdiv_q_2exp(mpzV, mpzV, 1);
    mpz_mod(mpzU, mpzU, mpzN);
    mpz_mod(mpzV, mpzV, mpzN);
    }
/* Calculate Q^m for next bit position, doubling the exponent.
   The irrelevant final iteration is omitted. */
  if(ul < ulNbits - 1)  /* Q^m not needed for MSB. */
    {

    mpz_mul(mpzQm, mpzQm, mpzQm);
    mpz_mod(mpzQm, mpzQm, mpzN);  /* prevents overflow */
    mpz_add(mpz2Qm, mpzQm, mpzQm);
    }
  }

/* If U_(N - Jacobi(D,N)) is congruent to 0 mod N, then N is
   a prime or a Lucas pseudoprime; otherwise it is definitely
   composite. */

if(mpz_sgn(mpzU)==0)RETURN(1);
RETURN(0);
}
/**********************************************************************/
int iStrongLucasSelfridge(mpz_t mpzN)
{
/* Test N for primality using the strong Lucas test with Selfridge's
   parameters. Returns 1 if N is prime or a strong Lucas-Selfridge
   pseudoprime (in which case N is also a pseudoprime to the standard
   Lucas-Selfridge test). Returns 0 if N is definitely composite.

   The running time of the strong Lucas-Selfridge test is, on average,
   roughly 10 % greater than the running time for the standard
   Lucas-Selfridge test (3 to 7 times that of a single Miller-Rabin
   test). However, the frequency of strong Lucas pseudoprimes appears
   to be only (roughly) 30 % that of (standard) Lucas pseudoprimes, and
   only slightly greater than the frequency of base-2 strong pseudoprimes,
   indicating that the strong Lucas-Selfridge test is more computationally
   effective than the standard version. */

int iComp2, iP, iJ, iSign;
long lDabs, lD, lQ;
unsigned long ulMaxBits, uldbits, ul, ulGCD, r, s;
mpz_t mpzU, mpzV, mpzNplus1, mpzU2m, mpzV2m, mpzQm, mpz2Qm,
      mpzT1, mpzT2, mpzT3, mpzT4, mpzD, mpzd, mpzQkd, mpz2Qkd;

#undef RETURN
#define RETURN(n)           \
  {                         \
  mpz_clear(mpzU);          \
  mpz_clear(mpzV);          \
  mpz_clear(mpzNplus1);     \
  mpz_clear(mpzU2m);        \
  mpz_clear(mpzV2m);        \
  mpz_clear(mpzQm);         \
  mpz_clear(mpz2Qm);        \
  mpz_clear(mpzT1);         \
  mpz_clear(mpzT2);         \
  mpz_clear(mpzT3);         \
  mpz_clear(mpzT4);         \
  mpz_clear(mpzD);          \
  mpz_clear(mpzd);          \
  mpz_clear(mpzQkd);        \
  mpz_clear(mpz2Qkd);       \
  return(n);                \
  }

/* This implementation of the algorithm assumes N is an odd integer > 2,
   so we first eliminate all N < 3 and all even N. As a practical matter,
   we also need to filter out all perfect square values of N, such as
   1093^2 (a base-2 strong pseudoprime); this is because we will later
   require an integer D for which Jacobi(D,N) = -1, and no such integer
   exists if N is a perfect square. The algorithm as written would
   still eventually return zero in this case, but would require
   nearly sqrt(N)/2 iterations. */

iComp2=mpz_cmp_si(mpzN, 2);
if(iComp2 < 0)return(0);
if(iComp2==0)return(1);
if(mpz_even_p(mpzN))return(0);
if(mpz_perfect_square_p(mpzN))return(0);

/* Allocate storage for the mpz_t variables. Most require twice
   the storage of mpzN, since multiplications of order O(mpzN)*O(mpzN)
   will be performed. */

ulMaxBits=2*mpz_sizeinbase(mpzN, 2) + mp_bits_per_limb;
mpz_init2(mpzU, ulMaxBits);
mpz_init2(mpzV, ulMaxBits);
mpz_init2(mpzNplus1, ulMaxBits);
mpz_init2(mpzU2m, ulMaxBits);
mpz_init2(mpzV2m, ulMaxBits);
mpz_init2(mpzQm, ulMaxBits);
mpz_init2(mpz2Qm, ulMaxBits);
mpz_init2(mpzT1, ulMaxBits);
mpz_init2(mpzT2, ulMaxBits);
mpz_init2(mpzT3, ulMaxBits);
mpz_init2(mpzT4, ulMaxBits);
mpz_init(mpzD);
mpz_init2(mpzd, ulMaxBits);
mpz_init2(mpzQkd, ulMaxBits);
mpz_init2(mpz2Qkd, ulMaxBits);

/* Find the first element D in the sequence {5, -7, 9, -11, 13, ...}
   such that Jacobi(D,N) = -1 (Selfridge's algorithm). Theory
   indicates that, if N is not a perfect square, D will "nearly
   always" be "small." Just in case, an overflow trap for D is
   included. */

lDabs=5;
iSign=1;
while(1)
  {
  lD=iSign*lDabs;
  iSign = -iSign;
  ulGCD=mpz_gcd_ui(NULL, mpzN, lDabs);
  /* if 1 < GCD < N then N is composite with factor lDabs, and
     Jacobi(D,N) is technically undefined (but often returned
     as zero). */
  if((ulGCD > 1) && mpz_cmp_ui(mpzN, ulGCD) > 0)RETURN(0);
  mpz_set_si(mpzD, lD);
  iJ=mpz_jacobi(mpzD, mpzN);
  if(iJ==-1)break;
  lDabs += 2;
  if(lDabs > ulDmax)ulDmax=lDabs;  /* tracks global max of |D| */
  if(lDabs > LONG_MAX-2)
    {
    fprintf(stderr,
      "\n ERROR: D overflows signed long in Lucas-Selfridge test.");
    fprintf(stderr, "\n N=");
    mpz_out_str(stderr, 10, mpzN);
    fprintf(stderr, "\n |D|=%ld\n\n", lDabs);
    exit(EXIT_FAILURE);
    }
  }

iP=1;         /* Selfridge's choice */
lQ=(1-lD)/4;  /* Required so D = P*P - 4*Q */

/* NOTE: The conditions (a) N does not divide Q, and
   (b) D is square-free or not a perfect square, are included by
   some authors; e.g., "Prime numbers and computer methods for
   factorization," Hans Riesel (2nd ed., 1994, Birkhauser, Boston),
   p. 130. For this particular application of Lucas sequences,
   these conditions were found to be immaterial. */

/* Now calculate N - Jacobi(D,N) = N + 1 (even), and calculate the
   odd positive integer d and positive integer s for which
   N + 1 = 2^s*d (similar to the step for N - 1 in the Miller-Rabin
   test). The strong Lucas-Selfridge test then returns N as a
   strong Lucas probable prime (slprp) if any of the following
   conditions is met: U_d=0, V_d=0, V_2d=0, V_4d=0, V_8d=0,
   V_16d=0, ..., etc., ending with V_{2^(s-1)*d}=V_{(N+1)/2}=0
   (all equalities mod N). Thus d is the highest index of U that
   must be computed (since V_2m is independent of U), compared
   to U_{N+1} for the standard Lucas-Selfridge test; and no
   index of V beyond (N+1)/2 is required, just as in the
   standard Lucas-Selfridge test. However, the quantity Q^d must
   be computed for use (if necessary) in the latter stages of
   the test. The result is that the strong Lucas-Selfridge test
   has a running time only slightly greater (order of 10 %) than
   that of the standard Lucas-Selfridge test, while producing
   only (roughly) 30 % as many pseudoprimes (and every strong
   Lucas pseudoprime is also a standard Lucas pseudoprime). Thus
   the evidence indicates that the strong Lucas-Selfridge test is
   more effective than the standard Lucas-Selfridge test, and a
   Baillie-PSW test based on the strong Lucas-Selfridge test
   should be more reliable. */


mpz_add_ui(mpzNplus1, mpzN, 1);
s=mpz_scan1(mpzNplus1, 0);
mpz_tdiv_q_2exp(mpzd, mpzNplus1, s);

/* We must now compute U_d and V_d. Since d is odd, the accumulated
   values U and V are initialized to U_1 and V_1 (if the target
   index were even, U and V would be initialized instead to U_0=0
   and V_0=2). The values of U_2m and V_2m are also initialized to
   U_1 and V_1; the FOR loop calculates in succession U_2 and V_2,
   U_4 and V_4, U_8 and V_8, etc. If the corresponding bits
   (1, 2, 3, ...) of t are on (the zero bit having been accounted
   for in the initialization of U and V), these values are then
   combined with the previous totals for U and V, using the
   composition formulas for addition of indices. */

mpz_set_ui(mpzU, 1);                      /* U=U_1 */
mpz_set_ui(mpzV, iP);                     /* V=V_1 */
mpz_set_ui(mpzU2m, 1);                    /* U_1 */
mpz_set_si(mpzV2m, iP);                   /* V_1 */
mpz_set_si(mpzQm, lQ);
mpz_set_si(mpz2Qm, 2*lQ);
mpz_set_si(mpzQkd, lQ);  /* Initializes calculation of Q^d */

uldbits=mpz_sizeinbase(mpzd, 2);
for(ul=1; ul < uldbits; ul++)  /* zero bit on, already accounted for */
  {
/* Formulas for doubling of indices (carried out mod N). Note that
 * the indices denoted as "2m" are actually powers of 2, specifically
 * 2^(ul-1) beginning each loop and 2^ul ending each loop.
 *
 * U_2m = U_m*V_m
 * V_2m = V_m*V_m - 2*Q^m
 */
  mpz_mul(mpzU2m, mpzU2m, mpzV2m);
  mpz_mod(mpzU2m, mpzU2m, mpzN);
  mpz_mul(mpzV2m, mpzV2m, mpzV2m);
  mpz_sub(mpzV2m, mpzV2m, mpz2Qm);
  mpz_mod(mpzV2m, mpzV2m, mpzN);
  /* Must calculate powers of Q for use in V_2m, also for Q^d later */
  mpz_mul(mpzQm, mpzQm, mpzQm);
  mpz_mod(mpzQm, mpzQm, mpzN);  /* prevents overflow */
  mpz_mul_2exp(mpz2Qm, mpzQm, 1);
  if(mpz_tstbit(mpzd, ul))
    {
/* Formulas for addition of indices (carried out mod N);
 *
 * U_(m+n) = (U_m*V_n + U_n*V_m)/2
 * V_(m+n) = (V_m*V_n + D*U_m*U_n)/2
 *
 * Be careful with division by 2 (mod N)!
 */
    mpz_mul(mpzT1, mpzU2m, mpzV);
    mpz_mul(mpzT2, mpzU, mpzV2m);
    mpz_mul(mpzT3, mpzV2m, mpzV);
    mpz_mul(mpzT4, mpzU2m, mpzU);
    mpz_mul_si(mpzT4, mpzT4, lD);
    mpz_add(mpzU, mpzT1, mpzT2);
    if(mpz_odd_p(mpzU))mpz_add(mpzU, mpzU, mpzN);
    mpz_fdiv_q_2exp(mpzU, mpzU, 1);
    mpz_add(mpzV, mpzT3, mpzT4);
    if(mpz_odd_p(mpzV))mpz_add(mpzV, mpzV, mpzN);
    mpz_fdiv_q_2exp(mpzV, mpzV, 1);
    mpz_mod(mpzU, mpzU, mpzN);
    mpz_mod(mpzV, mpzV, mpzN);
    mpz_mul(mpzQkd, mpzQkd, mpzQm);  /* Calculating Q^d for later use */
    mpz_mod(mpzQkd, mpzQkd, mpzN);
    }
  }

/* If U_d or V_d is congruent to 0 mod N, then N is a prime or a
   strong Lucas pseudoprime. */

if(mpz_sgn(mpzU)==0)RETURN(1);
if(mpz_sgn(mpzV)==0)RETURN(1);

/* NOTE: Ribenboim ("The new book of prime number records," 3rd ed.,
   1995/6) omits the condition Vð0 on p.142, but includes it on
   p. 130. The condition is NECESSARY; otherwise the test will
   return false negatives---e.g., the primes 29 and 2000029 will be
   returned as composite. */

/* Otherwise, we must compute V_2d, V_4d, V_8d, ..., V_{2^(s-1)*d}
   by repeated use of the formula V_2m = V_m*V_m - 2*Q^m. If any of
   these are congruent to 0 mod N, then N is a prime or a strong
   Lucas pseudoprime. */

mpz_mul_2exp(mpz2Qkd, mpzQkd, 1);  /* Initialize 2*Q^(d*2^r) for V_2m */
for(r=1; r < s; r++)
  {
  mpz_mul(mpzV, mpzV, mpzV);
  mpz_sub(mpzV, mpzV, mpz2Qkd);
  mpz_mod(mpzV, mpzV, mpzN);
  if(mpz_sgn(mpzV)==0)RETURN(1);
/* Calculate Q^{d*2^r} for next r (final iteration irrelevant). */
  if(r < s-1)
    {
    mpz_mul(mpzQkd, mpzQkd, mpzQkd);
    mpz_mod(mpzQkd, mpzQkd, mpzN);
    mpz_mul_2exp(mpz2Qkd, mpzQkd, 1);
    }
  }

/* Otherwise N is definitely composite. */

RETURN(0);
}
/**********************************************************************/
int iExtraStrongLucas(mpz_t mpzN, long lB)
{
/* Test N for primality using the extra strong Lucas test with base B,
   as formulated by Zhaiyu Mo and James P. Jones ("A new primality test
   using Lucas sequences," preprint, circa 1997), and described by Jon
   Grantham in "Frobenius pseudoprimes," (preprint, 16 July 1998),
   available at <http://www.pseudoprime.com/pseudo1.ps>.

   Returns 1 if N is prime or an extra strong Lucas pseudoprime (base B).
   Returns 0 if N is definitely composite.

   Even N and N < 3 are eliminated before applying the Lucas test.

   In this implementation of the algorithm, Q=1, and B is an integer
   in 2 < B < LONG_MAX (2147483647 on 32-bit machines); the default value
   is B=3. B is incremented as necessary if the values of B and N are
   inconsistent with the hypotheses of Jones and Mo: P=B, Q=1,
   D=P*P - 4*Q, GCD(N,2D)=1, Jacobi(D,N) <> 0.

   Since the base B is used solely to calculate the discriminant
   D=B*B - 4, negative values of B are redundant. The bases B=0 and
   B=1 are excluded because they produce huge numbers of pseudoprimes,
   and B=2 is excluded because the resulting D=0 fails the Jones-Mo
   hypotheses.

   Note that the choice Q=1 eliminates the computation of powers of Q
   which appears in the weak and strong Lucas tests.

   The running time of the extra strong Lucas-Selfridge test is, on
   average, roughly 80 % that of the standard Lucas-Selfridge test
   or 2 to 6 times that of a single Miller-Rabin test. This is superior
   in speed to both the standard and strong Lucas-Selfridge tests. The
   frequency of extra strong Lucas pseudoprimes also appears to be
   about 80 % that of the strong Lucas-Selfridge test and 30 % that of
   the standard Lucas-Selfridge test, comparable to the frequency of
   spsp(2).

   Unfortunately, the apparent superior peformance of the extra strong
   Lucas test is offset by the fact that it is not "backwards compatible"
   with the Lucas-Selfridge tests, due to the differing choice of
   parameters: P=B and Q=1 in the extra strong test, while P=1 and
   Q=(1 - D)/4 in the standard and strong Lucas-Selfridge tests (with D
   chosen from the sequence 5, -7, 9, ...). Thus, although every extra
   strong Lucas pseudoprime to base B is also both a strong and standard
   Lucas pseudoprime with parameters P=B and Q=1, the extra strong
   pseudoprimes do *NOT* constitute a proper subset of the Lucas-Selfridge
   standard and strong pseudoprimes. As a specific example, 4181 is an
   extra strong Lucas pseudoprime to base 3, but is neither a standard
   nor strong Lucas-Selfridge pseudoprime.

   As a result, the corresponding Baillie-PSW test is fatally flawed.
   Regardless of the base chosen for the extra strong Lucas test, it
   appears that there exist numerous N for which the corresponding
   extra strong Lucas pseudoprimes (xslpsp) will also be strong
   pseudoprimes to base 2 (or any other particular Miller-Rabin base).
   For example, 6368689 is both spsp(2) and xslpsp(3); 8725753
   is both spsp(2) and xslpsp(11); 80579735209 is spsp(2) and
   simultaneously xslpsp for the bases 3, 5, and 7; 105919633 is
   spsp(3) and xslpsp(11); 1121176981 is spsp(19) and xslpsp(31);
   and so on. Perhaps some combination of the extra strong test
   and multiple Miller's test could match the performance of the
   Lucas-Selfridge BPSW tests, but the prospects do not look bright.
*/

int iComp2, iJ;
long lD, lP, lQ;
unsigned long ulMaxBits, uldbits, ul, ulGCD, r, s;
mpz_t mpzU, mpzV, mpzM, mpzU2m, mpzV2m, mpzT1, mpzT2, mpzT3, mpzT4,
      mpzD, mpzd, mpzTwo, mpzMinusTwo;

#undef RETURN
#define RETURN(n)           \
  {                         \
  mpz_clear(mpzU);          \
  mpz_clear(mpzV);          \
  mpz_clear(mpzM);          \
  mpz_clear(mpzU2m);        \
  mpz_clear(mpzV2m);        \
  mpz_clear(mpzT1);         \
  mpz_clear(mpzT2);         \
  mpz_clear(mpzT3);         \
  mpz_clear(mpzT4);         \
  mpz_clear(mpzD);          \
  mpz_clear(mpzd);          \
  mpz_clear(mpzTwo);        \
  mpz_clear(mpzMinusTwo);   \
  return(n);                \
  }

/* This implementation of the algorithm assumes N is an odd integer > 2,
   so we first eliminate all N < 3 and all even N. */

iComp2=mpz_cmp_si(mpzN, 2);
if(iComp2 < 0)return(0);
if(iComp2==0)return(1);
if(mpz_even_p(mpzN))return(0);

/* Allocate storage for the mpz_t variables. Most require twice
   the storage of mpzN, since multiplications of order O(mpzN)*O(mpzN)
   will be performed. */

ulMaxBits=2*mpz_sizeinbase(mpzN, 2) + mp_bits_per_limb;
mpz_init2(mpzU, ulMaxBits);
mpz_init2(mpzV, ulMaxBits);
mpz_init2(mpzM, ulMaxBits);
mpz_init2(mpzU2m, ulMaxBits);
mpz_init2(mpzV2m, ulMaxBits);
mpz_init2(mpzT1, ulMaxBits);
mpz_init2(mpzT2, ulMaxBits);
mpz_init2(mpzT3, ulMaxBits);
mpz_init2(mpzT4, ulMaxBits);
mpz_init(mpzD);
mpz_init2(mpzd, ulMaxBits);
mpz_init_set_si(mpzTwo, 2);
mpz_init_set_si(mpzMinusTwo, -2);

/* The parameters specified by Zhaiyu Mo and James P. Jones,
   as set forth in Grantham's paper, are P=B, Q=1, D=P*P - 4*Q,
   with (N,2D)=1 so that Jacobi(D,N) <> 0. As explained above,
   bases B < 3 are excluded. */

if(lB < 3)
  lP=3;
else
  lP=lB;
lQ=1;

/* We check to make sure that N and D are relatively prime. If not,
   then either 1 < (D,N) < N, in which case N is composite with
   divisor (D,N); or N = (D,N), in which case N divides D and may be
   either prime or composite, so we increment the base B=P and
   try again. */

while(1)
  {
  lD=lP*lP - 4*lQ;
  ulGCD=mpz_gcd_ui(NULL, mpzN, labs(lD));
  if(ulGCD==1)break;
  if(mpz_cmp_ui(mpzN, ulGCD) > 0)RETURN(0);
  lP++;
  }

/* Now calculate M = N - Jacobi(D,N) (M even), and calculate the
   odd positive integer d and positive integer s for which
   M = 2^s*d (similar to the step for N - 1 in the Miller-Rabin
   test). The extra strong Lucas-Selfridge test then returns N as
   an extra strong Lucas probable prime (eslprp) if any of the
   following conditions is met: U_d=0 and V_dðñ2; or V_d=0; or
   V_2d=0, V_4d=0, V_8d=0, V_16d=0, ..., etc., ending with
   V_{2^(s-2)*d}=V_{M/4}ð0 (all equalities mod N). Thus d is the
   highest index of U that must be computed (since V_2m is
   independent of U), compared to U_M for the standard Lucas
   test; and no index of V beyond M/4 is required, compared to
   M/2 for the standard and strong Lucas tests. Furthermore,
   since Q=1, the powers of Q required in the standard and
   strong Lucas tests can be dispensed with. The result is that
   the extra strong Lucas test has a running time shorter than
   that of either the standard or strong Lucas-Selfridge tests
   (roughly two to six times that of a single Miller-Rabin
   test). The extra strong test also produces fewer pseudoprimes.
   Unfortunately, the pseudoprimes produced are *NOT* a subset
   of the standard or strong Lucas-Selfridge pseudoprimes (due
   to the incompatible parameters P and Q), and consequently the
   extra strong test does not combine with a single Miller-Rabin
   test to produce a Baillie-PSW test of the reliability level of
   the BPSW tests based on the standard or strong Lucas-Selfridge
   tests. */

mpz_set_si(mpzD, lD);
iJ=mpz_jacobi(mpzD, mpzN);
assert(iJ != 0);
if(iJ==1)
  mpz_sub_ui(mpzM, mpzN, 1);
else
  mpz_add_ui(mpzM, mpzN, 1);

s=mpz_scan1(mpzM, 0);
mpz_tdiv_q_2exp(mpzd, mpzM, s);

/* We must now compute U_d and V_d. Since d is odd, the accumulated
   values U and V are initialized to U_1 and V_1 (if the target
   index were even, U and V would be initialized instead to U_0=0
   and V_0=2). The values of U_2m and V_2m are also initialized to
   U_1 and V_1; the FOR loop calculates in succession U_2 and V_2,
   U_4 and V_4, U_8 and V_8, etc. If the corresponding bits
   (1, 2, 3, ...) of t are on (the zero bit having been accounted
   for in the initialization of U and V), these values are then
   combined with the previous totals for U and V, using the
   composition formulas for addition of indices. */

mpz_set_ui(mpzU, 1);                       /* U=U_1 */
mpz_set_si(mpzV, lP);                      /* V=V_1 */
mpz_set_ui(mpzU2m, 1);                     /* U_1 */
mpz_set_si(mpzV2m, lP);                    /* V_1 */

uldbits=mpz_sizeinbase(mpzd, 2);
for(ul=1; ul < uldbits; ul++)  /* zero bit on, already accounted for */
  {
/* Formulas for doubling of indices (carried out mod N). Note that
 * the indices denoted as "2m" are actually powers of 2, specifically
 * 2^(ul-1) beginning each loop and 2^ul ending each loop.
 *
 * U_2m = U_m*V_m
 * V_2m = V_m*V_m - 2*Q^m
 */
  mpz_mul(mpzU2m, mpzU2m, mpzV2m);
  mpz_mod(mpzU2m, mpzU2m, mpzN);
  mpz_mul(mpzV2m, mpzV2m, mpzV2m);
  mpz_sub_ui(mpzV2m, mpzV2m, 2);
  mpz_mod(mpzV2m, mpzV2m, mpzN);
  if(mpz_tstbit(mpzd, ul))
    {
/* Formulas for addition of indices (carried out mod N);
 *
 * U_(m+n) = (U_m*V_n + U_n*V_m)/2
 * V_(m+n) = (V_m*V_n + D*U_m*U_n)/2
 *
 * Be careful with division by 2 (mod N)!
 */
    mpz_mul(mpzT1, mpzU2m, mpzV);
    mpz_mul(mpzT2, mpzU, mpzV2m);
    mpz_mul(mpzT3, mpzV2m, mpzV);
    mpz_mul(mpzT4, mpzU2m, mpzU);
    mpz_mul_si(mpzT4, mpzT4, lD);
    mpz_add(mpzU, mpzT1, mpzT2);
    if(mpz_odd_p(mpzU))mpz_add(mpzU, mpzU, mpzN);
    mpz_fdiv_q_2exp(mpzU, mpzU, 1);
    mpz_add(mpzV, mpzT3, mpzT4);
    if(mpz_odd_p(mpzV))mpz_add(mpzV, mpzV, mpzN);
    mpz_fdiv_q_2exp(mpzV, mpzV, 1);
    mpz_mod(mpzU, mpzU, mpzN);
    mpz_mod(mpzV, mpzV, mpzN);
    }
  }

/* N first passes the extra strong Lucas test if V_dð0, or if V_dðñ2
   and U_dð0.  U and V are tested for divisibility by N, rather than
   zero, in case the previous FOR is a zero-iteration loop.*/

if(mpz_divisible_p(mpzV, mpzN))RETURN(1);
if(mpz_divisible_p(mpzU, mpzN))
  {
  if(mpz_congruent_p(mpzV, mpzTwo, mpzN))RETURN(1);
  if(mpz_congruent_p(mpzV, mpzMinusTwo, mpzN))RETURN(1);
  }

/* Otherwise, we must compute V_2d, V_4d, V_8d, ..., V_{2^(s-2)*d}
   by repeated use of the formula V_2m = V_m*V_m - 2*Q^m. If any of
   these are congruent to 0 mod N, then N is a prime or an extra
   strong Lucas pseudoprime. */

for(r=1; r < s-1; r++)
  {
  mpz_mul(mpzV, mpzV, mpzV);
  mpz_sub_ui(mpzV, mpzV, 2);
  mpz_mod(mpzV, mpzV, mpzN);
  if(mpz_sgn(mpzV)==0)RETURN(1);
  }

/* Otherwise N is definitely composite. */

RETURN(0);
}
/**********************************************************************/
/**********************************************************************/
/*              Li(x); Hardy-Littlewood Integrals;                    */
/*    Riemann Zeta function; Riemann Prime Counting function R(x)     */
/**********************************************************************/
/**********************************************************************/
long double ldLogInt(long double ldx, long double *ldHL2,
  long double *ldHL3, long double *ldHL4)
{
/* The logarithmic integral expressions Li(x), L2(x), L3(x), and L4(x),
   approximating pi(x), pi_2(x), pi_3(x), and pi_4(x) respectively---the
   counts from 0 to x of the primes, twin-prime pairs, prime triplets,
   and prime quadruplets---are approximated using a series obtained as
   explained below.

   The fact that Li(x) is asymptotic to pi(x) is one statement of the
   Prime Number Theorem. The use of L2(x), L3(x), and L4(x) as
   approximations to pi_2(x), pi_3(x), and pi_4(x) is a consequence
   of the prime k-tuples conjecture of Hardy and Littlewood (ca. 1922).


   The technique is as follows. In I4=int(1/(ln t)^4, t) substitute
   u=ln(t), yielding the integral int(exp(u)/u^4, u). Substitute the
   Maclaurin series for exp(u). Integrate the first five terms separately
   to yield

   I4=-1/(3u^3) - 1/(2u^2) - 1/(2u) + (ln u)/6 + u/24
                                          + sum(u^k/(k*(k+3)!), k, 2, inf).

   Replace u by ln(t) and apply the limits t=2 to t=x to produce the
   result for the integral in L4.  Note that the terms in the resulting
   series are related by

   T(k+1)=T(k)*(ln t)*k/((k+1)(k+4).

   Iterate the series until the ratio of successive terms is < M_EPSILON1
   (LDBL_EPSILON/4, approximately 2.71e-20 on an x386 system).

   Once I4 is evaluated, I3, I2, and I1 can be obtained using (reverse)
   integration by parts on I1(t)=int(1/(ln t), t):

   I1(t)=t/(ln t) + I2(t)=t/(ln t) + t/(ln t)^2 + 2*I3(t)
        =t/(ln t) + t/(ln t)^2 + 2t/(ln t)^3 + 6*I4(t) ,
   or

   I3(t)=t/(ln t)^3 + 3*I4(t)

   I2(t)=t/(ln t)^2 + 2*I3(t)

   I1(t)=t/(ln t) + I2(t).

   Now apply the limits 2 to x. Add ldLi2 to L1 to account for
   the lower limit being 0 rather than 2. Multiply I4, I3, and I2
   by the appropriate Hardy-Littlewood constants to obtain the
   estimates for pi_4(x), pi_3(x), and pi_2(x).

   NOTE: The domain of the algorithm is x > 1; the accuracy degrades
   near x=1, a singular point of Li(x). For x < 2, this routine returns
   artificial values of zero. This eliminates additional code of
   considerable complexity and limited value; Li(x) and the
   Hardy-Littlewood integrals are rarely called with for such arguments.
*/

unsigned long ul;
long double ldTerm1, ldTerm2, ldDelta, ldLx, ldLx2, ldLx3, ldIntegral2,
  ldIntegral3, ldIntegral4, ldI1, ld;

if(ldx < 2)
  {
  *ldHL2=0;
  *ldHL3=0;
  *ldHL4=0;
  return(0);
  }

ldLx=logl(ldx);
ldLx2=ldLx*ldLx;
ldLx3=ldLx*ldLx2;

ldIntegral4=-1/(3*ldLx3) + 1/(3*M_LN2_CUBED) - 1/(2*ldLx2)
  + 1/(2*M_LN2_SQUARED) - 1/(2*ldLx) + 1/(2*M_LN2) + logl(ldLx/M_LN2)/6;
ldTerm1=ldLx/24;
ldTerm2=M_LN2/24;
for(ul=1; ; ul++)
  {
  ldIntegral4 += ldTerm1 - ldTerm2;
  ldDelta=M_EPSILON1*ldIntegral4;
  ld=((long double)ul)/((ul+1)*(ul+4.0L));
  ldTerm1 *= ldLx*ld;
  if(ldTerm1 < ldDelta)break;
  if(ldTerm2 > ldDelta)ldTerm2 *= M_LN2*ld; else ldTerm2=0;
  }

*ldHL4=M_HL4*ldIntegral4;

ldIntegral3=3*ldIntegral4 + ldx/ldLx3 - 2/M_LN2_CUBED;
*ldHL3=M_HL3*ldIntegral3;

ldIntegral2=2*ldIntegral3 + ldx/ldLx2 - 2/M_LN2_SQUARED;
*ldHL2=M_HL2*ldIntegral2;

ldI1=ldIntegral2 + ldx/ldLx - 2/M_LN2 + M_LI2;

return(ldI1);
}
/**********************************************************************/
long double ldLi(long double ldx)
{
/* Returns Li(ldx). For ldx < 2, an artificial value of zero is
   returned, for simplicity. */

long double ld2, ld3, ld4;

return(ldLogInt(ldx, &ld2, &ld3, &ld4));
}
/**********************************************************************/
long double ldRPCF(long double ldx)
{
/* Approximate Riemann's prime counting function R(x) using a truncated
   Gram series. For additional details, see "Prime numbers and
   computer methods for factorization," Hans Reisel (Birkhauser, Boston,
   1994), pp. 50-51, especially eqn 2.27.

   NOTE:  The domain of the algorithm is x > 1, but zero is returned
   for x < 2, to avoid unnecessarily complicating the code; R(x) is
   rarely evaluated for x < 2. */

static unsigned long	ulMaxNumTerms=1000;
unsigned long		ul;
long double		ldt, ldTerm, ldSum, ldFactor;

if(ldx < 2)return(0); /* For practical usage, x < 2 ==> R(x)=0 */
ldt=logl(ldx);
ldFactor=ldt;
ldSum=ldFactor/ldZeta(2);
for(ul=2; ul < ulMaxNumTerms; ul++)
  {
  ldFactor *= (ldt/ul)/ul*(ul-1.0L);
  ldTerm=ldFactor/ldZeta(ul + 1);
  ldSum += ldTerm;
  if(ldTerm/ldSum < M_EPSILON1)break;
  }
return(1 + ldSum);
}
/**********************************************************************/
void vDefineZetaArray(void)
{
/* Stores pre-computed values of the Riemann zeta function for integer
   arguments 0, 2, 3, ..., 65. */

if(ldZ[0] != 0)return;  /* external array already initialized */
ldZ[ 0]=-0.5L;
ldZ[ 2]=1.64493406684822643647241516664602518921894990120680L;
ldZ[ 3]=1.20205690315959428539973816151144999076498629234050L;
ldZ[ 4]=1.08232323371113819151600369654116790277475095191873L;
ldZ[ 5]=1.03692775514336992633136548645703416805708091950191L;
ldZ[ 6]=1.01734306198444913971451792979092052790181749003285L;
ldZ[ 7]=1.00834927738192282683979754984979675959986356056524L;
ldZ[ 8]=1.00407735619794433937868523850865246525896079064985L;
ldZ[ 9]=1.00200839282608221441785276923241206048560585139489L;
ldZ[10]=1.00099457512781808533714595890031901700601953156448L;
ldZ[11]=1.00049418860411946455870228252646993646860643575821L;
ldZ[12]=1.00024608655330804829863799804773967096041608845800L;
ldZ[13]=1.00012271334757848914675183652635739571427510589551L;
ldZ[14]=1.00006124813505870482925854510513533374748169616915L;
ldZ[15]=1.00003058823630702049355172851064506258762794870686L;
ldZ[16]=1.00001528225940865187173257148763672202323738899047L;
ldZ[17]=1.00000763719763789976227360029356302921308824909026L;
ldZ[18]=1.00000381729326499983985646164462193973045469721895L;
ldZ[19]=1.00000190821271655393892565695779510135325857114484L;
ldZ[20]=1.00000095396203387279611315203868344934594379418741L;
ldZ[21]=1.00000047693298678780646311671960437304596644669478L;
ldZ[22]=1.00000023845050272773299000364818675299493504182178L;
ldZ[23]=1.00000011921992596531107306778871888232638725499778L;
ldZ[24]=1.00000005960818905125947961244020793580122750391884L;
ldZ[25]=1.00000002980350351465228018606370506936601184473092L;
ldZ[26]=1.00000001490155482836504123465850663069862886478817L;
ldZ[27]=1.00000000745071178983542949198100417060411945471903L;
ldZ[28]=1.00000000372533402478845705481920401840242323289306L;
ldZ[29]=1.00000000186265972351304900640390994541694806166533L;
ldZ[30]=1.00000000093132743241966818287176473502121981356796L;
ldZ[31]=1.00000000046566290650337840729892332512200710626919L;
ldZ[32]=1.00000000023283118336765054920014559759404950248298L;
ldZ[33]=1.00000000011641550172700519775929738354563095165225L;
ldZ[34]=1.00000000005820772087902700889243685989106305417312L;
ldZ[35]=1.00000000002910385044497099686929425227884046410698L;
ldZ[36]=1.00000000001455192189104198423592963224531842098381L;
ldZ[37]=1.00000000000727595983505748101452086901233805926485L;
ldZ[38]=1.00000000000363797954737865119023723635587327351265L;
ldZ[39]=1.00000000000181898965030706594758483210073008503059L;
ldZ[40]=1.00000000000090949478402638892825331183869490875386L;
ldZ[41]=1.00000000000045474737830421540267991120294885703390L;
ldZ[42]=1.00000000000022737368458246525152268215779786912138L;
ldZ[43]=1.00000000000011368684076802278493491048380259064374L;
ldZ[44]=1.00000000000005684341987627585609277182967524068553L;
ldZ[45]=1.00000000000002842170976889301855455073704942662074L;
ldZ[46]=1.00000000000001421085482803160676983430714173953768L;
ldZ[47]=1.00000000000000710542739521085271287735447995680002L;
ldZ[48]=1.00000000000000355271369133711367329846953405934299L;
ldZ[49]=1.00000000000000177635684357912032747334901440027957L;
ldZ[50]=1.00000000000000088817842109308159030960913863913863L;
ldZ[51]=1.00000000000000044408921031438133641977709402681213L;
ldZ[52]=1.00000000000000022204460507980419839993200942046539L;
ldZ[53]=1.00000000000000011102230251410661337205445699213827L;
ldZ[54]=1.00000000000000005551115124845481243723736590509430L;
ldZ[55]=1.00000000000000002775557562136124172581632453854069L;
ldZ[56]=1.00000000000000001387778780972523276283909490650022L;
ldZ[57]=1.00000000000000000693889390454415369744608532624980L;
ldZ[58]=1.00000000000000000346944695216592262474427149610933L;
ldZ[59]=1.00000000000000000173472347604757657204897296993759L;
ldZ[60]=1.00000000000000000086736173801199337283420550673429L;
ldZ[61]=1.00000000000000000043368086900206504874970235659062L;
ldZ[62]=1.00000000000000000021684043449972197850139101683209L;
ldZ[63]=1.00000000000000000010842021724942414063012711165461L;
ldZ[64]=1.00000000000000000005421010862456645410918700404388L;
ldZ[65]=1.00000000000000000002710505431223468831954621311949L;

return;
}
/**********************************************************************/
long double ldZeta(long double ldx)
{
/* Computes approximate values of the Riemann zeta function for real
   non-negative arguments. Pre-computed values are returned for integer
   arguments 0 to 65; extrapolated values for x > 65. Riemann's analytic
   continuation series is used for non-integer values. For additional
   details, see "Prime numbers and computer methods for factorization,"
   Hans Reisel (Birkhauser, Boston, 1994), pp. 44-46. */

static unsigned long	ulMaxNumTerms=1000;
static long double ldZ65m1=2.710505431223468831954621311949e-20L;
  /* zeta(65) - 1 */
long			lSign;
unsigned long		ul;
long double		ldSum, ldSumOld, ldDelta, ldDivisor, ldResult;

if((ldx < 0) || (ldx==1))
  {
  fprintf(stderr, "\n ERROR: ldZeta called with illegal argument %.Le", ldx);
  exit(EXIT_FAILURE);
  }

if(ldZ[0]==0)vDefineZetaArray();  /* initialize zeta(n) */

/* Pre-computed values for n=0,1,2,..,65. */

if((ldx==floorl(ldx)) && (ldx > 1) && (ldx < 66))
  {
  ul=floorl(ldx);
  return(ldZ[ul]);
  }

/* For n > 65, the difference between zeta(n) and 1 is halved
   for each unit increase in n, to at least 20D precision (64 bits). */

if(ldx > 65)
  {
  if(ldx > 1-log2l(LDBL_EPSILON))return(1);
    /* in above case, zeta(ldx)==1 to the limit of long dbl precision */
  ldResult=1 + ldZ65m1*powl(2, 65 - ldx);
  return(ldResult);
  }

/* For positive non-integer arguments < 65, zeta is computed using
   Riemann's analytic continuation formula,

   zeta(s)=1/(1 - 2^(1-s))*sum((-1)^(n-1)/n^s, n, 1, inf). */

lSign=-1;
ldSum=1;
for(ul=2; ul < ulMaxNumTerms; ul++)
  {
  ldSumOld=ldSum;
  ldDelta=lSign*powl(ul, -ldx);
  ldSum += ldDelta;
  if(fabsl(ldDelta) < M_EPSILON1)break;
  lSign *= -1;
  }
ldSum=(ldSum + ldSumOld)/2;
ldDivisor=(1 - powl(2, 1 - ldx));
ldResult=ldSum/ldDivisor;

return(ldResult);
}
/**********************************************************************/
/**********************************************************************/
/*                       string editing                               */
/**********************************************************************/
/**********************************************************************/
char *szTrimMWS(char *pch)
{
return(szTrimLWS(szTrimTWS(pch)));
}
/**********************************************************************/
char *szTrimTWS(char *pch)
{
char            *pchStart;
long            sl;
unsigned long   ulLen;

if(*pch==0)return(pch);
pchStart=pch;
ulLen=strlen(pch);
pch=pchStart + ulLen - 1;
while(1)
  {
  if(*pch > 32)
    return(pchStart);
  else
    *pch=0;
  if(pch==pchStart)
    {
    *pch=0;
    return(pch);
    }
  pch--;
  }
}
/**********************************************************************/
char *szTrimLWS(char *pch)
{
char            *pchStart;

pchStart=pch;
while(1)
  {
  if(*pch==0)
    {
    *pchStart=0;
    return(pch);
    }
  else if(*pch > 32)
    {
    if(pch==pchStart)
      return(pch);
    else
      {
      memmove(pchStart, pch, strlen(pch)+1);
      return(pch);
      }
    }
  else
    pch++;
  }
}
/**********************************************************************/
/**********************************************************************/
/*          Analysis and processing of prime gap records              */
/**********************************************************************/
/**********************************************************************/
int iRecordValidExt(char *sz)
{
/* Returns 0 for invalid record, 6 for a valid gap6 record, 9 for a
   valid gap9 record, 1 for a record of the form gggg pppp.
   Continuation lines return zero (invalid). */

#undef RETURN
#define RETURN(n) {mpz_clear(mpzP1); return(n);}

static char szTemp[41];
char *ep;
long sl;
unsigned long ulMaxBits;
double lf;
mpz_t mpzP1;

if(strlen(sz) < 41)goto GAP1;

/* Test for gap6 format */

if((sz[7]==' ') && (sz[8]=='C')
    && (sz[11]==' ') && (sz[20]==' ') && (sz[29]=='.') && (sz[38]==' ')
    && (sz[39]=' '))
  {
  strncpy(szTemp, sz, 6); szTemp[6]=0;
  sl=strtol(szTemp, NULL, 10);  /* gap field */
  if(sl < 1)goto GAP9;
  if((sl&1==1) && (sl != 1))goto GAP9;
  lf=strtod(sz+25, NULL);  /* merit field */
  if(lf <= 0)goto GAP9;
  sl=strtol(sz+32, NULL, 10);  /* digits field */
  if(sl < 1)goto GAP9;
  return(6);
  }

GAP9:

if(strlen(sz) < 47)goto GAP1;

if((sz[10]==' ') && (sz[11]=='C')
    && (sz[14]==' ') && (sz[23]==' ') && (sz[32]=='.') && (sz[45]==' ')
    && (sz[46]=' '))
  {
  strncpy(szTemp, sz, 9); szTemp[9]=0;
  sl=strtol(szTemp, NULL, 10);  /* gap field */
  if(sl < 1)return(0);
  if((sl&1==1) && (sl != 1))return(0);
  lf=strtod(sz+28, NULL);  /* merit field */
  if(lf <= 0)goto GAP1;
  sl=strtol(sz+37, NULL, 10);  /* digits field */
  if(sl < 1)goto GAP1;
  return(9);
  }

GAP1:

lf=strtod(sz, &ep);  /* gap field */
if(lf < 1)return(0);
if(lf > 999999999.5)return(0);
sl=floor(lf + 0.5);
if(sl < 1)return(0);
if((sl&1==1) && (sl != 1))return(0);

/* Check the P1 value of type 1 gaps for plausibility. Assume a
   merit > 1 in allocating space for mpzP1 directly (if this
   fails, fall back on GMP's erratic dynamic reallocation).
   The following calculation is based on M=G/ln(P1)=1 ==> P1=e^G
   ==> P1 = 2^(log_2(e)*G) = 2^(1.442695*G) ==> 1.442695*G bits. */

ulMaxBits=ceil(1.4426950408889634*sl) + mp_bits_per_limb;
if(ulMaxBits > __MAX_BITS__)ulMaxBits=__MAX_BITS__;

mpz_init2(mpzP1, ulMaxBits);
if(__mpz_set_str(mpzP1, ep, 0))
  if(iEvalExprMPZ(mpzP1, ep))
    RETURN(0);  /* unable to parse P1 */

/* The following plausibility test for P1 uses Nicely's observation
   that P1 > 0.122985*sqrt(g)*exp(sqrt(g)) for all first occurrence
   and maximal prime gaps to 5e16, with this relationship conjectured
   to hold for indefinitely large g and P1. See "New prime gaps
   between 1e15 and 5e16", Bertil Nyman and Thomas R. Nicely,
   Journal of Integer Sequences 6 (13 August 2003), no. 3,
   Article 03.3.1, 6 pp., MR1997838 (2004e:11143), available
   electronically at <http://www.math.uwaterloo.ca/JIS/>. */

if(mpz_sizeinbase(mpzP1, 10) <
  log10(0.122985) + 0.5*log10(sl) + M_LOG_E_BASE10*sqrt(sl))RETURN(0);

RETURN(1);
}
/**********************************************************************/
int iGetGapRecExt(char *szGapRec, FILE *fpIn)
{
/* Returns 0 for failure, 6 for successful gap6 record, 9 for successful
   gap8 record, 1 for gap1 record.  Terminating newline is removed. */

char *pchCont, *pch;
int iStat;
unsigned long ul;

szGapRec[0]=0;
if(!fgets(szGapRec, __MAX_DIGITS__, fpIn))return(0);
if(feof(fpIn))return(0);
szTrimTWS(szGapRec);
iStat=iRecordValidExt(szGapRec);
if(iStat < 2)return(iStat);

pchCont=strpbrk(szGapRec+24, "_~\\");  /* Continuation lines coming? */
if(pchCont)*pchCont=0;
while(pchCont)
  {
  ul=strlen(szGapRec);
  fgets(szGapRec+ul+1, __MAX_DIGITS__, fpIn);
  if(feof(fpIn))
    {
    szGapRec[0]=0;
    return(0);
    }
  pch=szGapRec+ul+1;
  while(*pch < 33)pch++;
  strcat(szGapRec, pch);
  szTrimTWS(szGapRec);
  pchCont=strpbrk(szGapRec+24, "_~\\");  /* More continuation lines coming? */
  if(pchCont)*pchCont=0;
  }
return(iStat);
}
/**********************************************************************/
void vGapContExt(char *szContRec, char *szGapRec)
{
/* Creates a line continued gap6 or gap9 structure, or NULL on failure.
   NOTE: No terminating newline is appended. */

static char szSpacer[48];
int iStat;
unsigned long ulLen, ulOffset=40, ul;

iStat=iRecordValidExt(szGapRec);
if(iStat==0)
  {
  szContRec[0]=0;
  return;
  }
else if(iStat==6)
  ulOffset=40;
else if(iStat==9)
  ulOffset=47;

szTrimTWS(szGapRec);
ulLen=strlen(szGapRec);
if(ulLen <= ulOffset + 200)
  {
  strcpy(szContRec, szGapRec);
  return;
  }

strncpy(szContRec, szGapRec, ulOffset);
szContRec[ulOffset]=0;
for(ul=0; ul < ulOffset; ul++)szSpacer[ul]=' ';
szSpacer[ulOffset]=0;
while(1)
  {
  strncat(szContRec, szGapRec + ulOffset, 200);
  ulOffset += 200;
  if(ulOffset >= ulLen)break;
  strcat(szContRec, "\\\n");
  strcat(szContRec, szSpacer);
  }
return;
}
/**********************************************************************/
int iGetGapRec(char *szGapRec, FILE *fpIn)
{
/* Returns -1 on EOF, -2 on memory failure, zero for invalid record,
   1 for success.  Terminating newline is removed. */

static int iInit=0;
static char *szIn;
char *pchCont;

if(!iInit)
  {
  szIn=(char *)malloc(32000);
  if(!szIn)
    {
    szGapRec[0]=0;
    fprintf(stderr,
      "\n ERROR: malloc failed in iGetGapRec.\n\n");
    exit(EXIT_FAILURE);
    }
  iInit=1;
  }

fgets(szIn, 32000, fpIn);
if(feof(fpIn))return(-1);
if(!iRecordValid(szIn))
  {
  strcpy(szGapRec, szIn);
  return(0);
  }
szTrimTWS(szIn);
pchCont=strpbrk(szIn+24, "_~\\");  /* Continuation lines coming? */
if(pchCont)*pchCont=0;
strcpy(szGapRec, szIn);
while(pchCont)
  {
  fgets(szIn, 32000, fpIn);
  if(feof(fpIn))return(-1);
  szTrimTWS(szIn);
  pchCont=strpbrk(szIn+24, "_~\\");  /* More continuation lines coming? */
  if(pchCont)*pchCont=0;
  strcat(szGapRec, szIn+40);
  }
return(1);
}
/**********************************************************************/
int iRecordValid(char *szRec)
{
/* Returns 0 for failure, 1 for success. Continuation lines are
   returned as invalid. */

static char szTemp[41];
long    sl;
float   f;

if(strlen(szRec) < 41)return(0);
strncpy(szTemp, szRec, 40);
szTemp[40]=0;
sl=strtol(szTemp, NULL, 0);  /* gap field */
if(sl < 1)return(0);
if((sl&1==1) && (sl != 1))return(0);
sl=strtol(szTemp+20, NULL, 0);  /* year field */
if(sl==0)return(0);
f=strtod(szTemp+25, NULL);  /* merit field */
if(f <= 0)return(0);
sl=strtol(szTemp+32, NULL, 0);  /* digits field */
if(sl < 1)return(0);
if(*(szTemp+ 7) != ' ')return(0);
if(*(szTemp+11) != ' ')return(0);
if(*(szTemp+20) != ' ')return(0);
if(*(szTemp+38) != ' ')return(0);
if(*(szTemp+39) != ' ')return(0);

return(1);
}
/**********************************************************************/
void vGapCont(char *szContRec, char *szGapRec)
{
/* NOTE: No terminating newline is added. */

static char szSpacer[]="                                        ";
unsigned long ulLen, ulOffset=40;

szTrimTWS(szGapRec);
ulLen=strlen(szGapRec);
if(ulLen < 241)
  {
  strcpy(szContRec, szGapRec);
  return;
  }
strncpy(szContRec, szGapRec, 40);
szContRec[40]=0;
while(1)
  {
  strncat(szContRec, szGapRec + ulOffset, 200);
  ulOffset += 200;
  if(ulOffset >= ulLen)break;
  strcat(szContRec, "\\\n");
  strcat(szContRec, szSpacer);
  }
return;
}
/**********************************************************************/
/**********************************************************************/
/*                      miscellaneous routines                        */
/**********************************************************************/
/**********************************************************************/
void vFlush(void)
{
/* Attempts to flush all buffers to disk. */

fflush(NULL);
sync();
#ifdef __DJGPP__
  _flush_disk_cache();
#endif
return;
}
/***********************************************************************/
int __iLockMemory(void *MemStartAddress, unsigned long ulBytes)
{
#ifdef __DJGPP__
  return(_go32_dpmi_lock_data(MemStartAddress, ulBytes));
#else
  return(mlock(MemStartAddress, ulBytes));
#endif
}
/***********************************************************************/
// These things don't play nicely with OSX and are not needed by bpsw
/*
unsigned long __ulPhysicalMemoryAvailable(void)
{
#ifdef __DJGPP__
  return((unsigned long)_go32_dpmi_remaining_physical_memory());
#else
  return(((unsigned long)get_avphys_pages())*((unsigned long)getpagesize()));
#endif
}
*/
/***********************************************************************/
int iSignum(long double ldArg)
{
if(ldArg==0)return(0);
return((ldArg > 0) ? +1 : -1);
}
/**********************************************************************/
int _isFile(char *szFileName)
{
/* Returns 1 if the file exists as a regular file (e.g., not a directory
   or volume label); returns 0 otherwise. */

int iExists;
struct stat st;

iExists = !stat(szFileName, &st);
if(iExists && S_ISREG(st.st_mode))return(1);
return(0);
}
/**********************************************************************/
int _isRFile(char *szFileName)
{
/* Returns 1 if the file exists as a regular file (e.g., not a directory
   or volume label) and the user has read privilege; returns 0 otherwise. */

int iExists;
struct stat st;

iExists = !stat(szFileName, &st);
if(iExists && S_ISREG(st.st_mode) && (st.st_mode & S_IRUSR))return(1);
return(0);
}
/**********************************************************************/
int _isRWFile(char *szFileName)
{
/* Returns 1 if the file exists as a regular file (e.g., not a directory
   or volume label) and the user has read and write privileges; returns
   0 otherwise. */

int iExists;
struct stat st;

iExists = !stat(szFileName, &st);
if(iExists && S_ISREG(st.st_mode) && (st.st_mode & S_IRUSR) &&
    (st.st_mode & S_IWUSR))return(1);
return(0);
}
/**********************************************************************/
double lfSeconds2(void)
{
/* Returns the number of seconds elapsed since some fixed event,
   dependent upon the function call and platform. The clock()
   based routine normally returns the number of seconds since
   either the beginning of program execution or the first call
   to the function. The gettimeofday and time(NULL) based routines
   return the number of seconds since the beginning of the Un*x epoch
   (00:00:00 GMT 1 Jan 1970). The granularity of the clock()
   routine is generally either 0.01 sec or 0.055 sec. The
   granularity of gettimeofday is nominally 1 microsecond, but
   in reality 0.01 second is more common. The granularity of
   time(NULL) is 1 second.

   PORTABILITY AND BUGS: The clock() and time(NULL) functions are
   part of standard C. The gettimeofday function is not part of
   standard C, but is available on the great majority of platforms
   (some System V platforms may lack it).

   The only known bug in clock() is the rollover problem, which
   will usually cause LONG_MAX to rollover to LONG_MIN after
   2^31 ticks. This is a major problem on systems (including many
   GNU/Linux systems) which comply with the P*SIX standard
   CLOCKS_PER_SECOND=1000000; then the first rollover occurs after
   less than 36 minutes. Rollover results in clock() failing to be
   monotonic increasing, so that simply differencing clock() values
   may not reflect the true time difference (and may even generate
   a ridiculous negative time difference). Rollover can generally
   be ignored on systems where CLOCKS_PER_SECOND <= 1000, where
   rollover will take at least 24.85 days. Otherwise, it must be
   trapped in the routine, and this can become quite problematical
   because of the possibility of multiple rollovers and masked
   rollovers.

   Bugs in gettimeofday have been reported by several users; these
   are either "backward jumps" in value in rare instances, or
   anomalous values returned at local midnight and then quickly
   self-correcting. More recent versions of gettimeofday (starting
   with GNU/Linux 2.4) appear to be more reliable, but I have
   observed the midnight anomaly on my own W*nd*ws systems, using
   the gettimeofday in DJGPP 2.03. It appears to have no rollover
   problem, although one may be coming in 2038, when the Un*x
   epoch attains 2^31 seconds.

   The only bugs of which I am aware in time(NULL) are a midnight
   rollover anomaly, similar to the one exhibited by gettimeofday,
   on some W*nd*ws systems; and the same Y2K type problem
   looming in 2038. Its huge disadvantage is the poor granularity.

   The first choice here is to use clock() on systems with
   CLOCKS_PER_SEC <= 1000. Otherwise gettimeofday is used, if
   available (if it is not, a compile error will result unless
   you undef __HAVE_GETTIMEOFDAY_). If your system has neither
   option available, time(NULL) is used as a last resort. You can
   alter this priority by adjusting the macros.

   The clock() routine has a correction factor to compensate for
   DJGPP's use of 91/5 PC clock ticks per second (the correct
   value is 1193180/65536 = 18.2046819336). */

#define __HAVE_GETTIMEOFDAY_ 1  /* undef if library doesn't have it */

double lft;

#if (CLOCKS_PER_SEC <= 1000)

lft=clock()/((double)CLOCKS_PER_SEC);
#if defined(__DJGPP__) && (CLOCKS_PER_SEC==91)
lft=0.9996439766*lft;
#endif

#elif defined(__HAVE_GETTIMEOFDAY_)

struct timeval tv;

gettimeofday(&tv, NULL);
lft=tv.tv_sec + tv.tv_usec/1000000.0;

#else

lft=time(NULL);

#endif

return(lft);
}
/**********************************************************************/
#ifndef __DJGPP__
/**********************************************************************/
char *strlwr(char *sz)
{
char *pch;

for(pch=sz; pch; pch++)*pch=tolower((unsigned char)*pch);
return(sz);
}
/**********************************************************************/
char *strupr(char *sz)
{
char *pch;

for(pch=sz; pch; pch++)*pch=toupper((unsigned char)*pch);
return(sz);
}
/**********************************************************************/
#endif  /* not DJGPP */
/**********************************************************************/
unsigned long ulSqrt(unsigned long long ull)
{
/* Computes the (integer truncated) square root of ull, using a
 * Newton-Raphson method. Returns floor(sqrt(ull)).
 *
 * Adapted from a similar routine in the BIGINT ultraprecision
 * integer package, developed (1988-91) and graciously placed in the
 * public domain by Arjen K. Lenstra, Mark Riordan, and Marc Ringuette.
 * The original BIGINT package is available (19 March 2001) at
 * <http://www.funet.fi/pub/crypt/cryptography/rpem/rpem/>
 * (thanks to Charles Doty for this pointer).
 *
 */

unsigned long long ull2, ull3, ull4;

if(ull==0)return(0);
if(ull < 4)return(1);
if(ull < 9)return(2);
if(ull >= (1ULL*ULONG_MAX)*ULONG_MAX)return(ULONG_MAX);
ull2=ull/2;
while(1)
  {
  ull3=ull/ull2;
  ull4=(ull3 + ull2)/2;
  if((ull4 - ull3 < 2) || (ull3 - ull4 < 2))
    if(ull4*ull4 <= ull)
      return(ull4);
    else
      return(ull3);
  ull2=ull4;
  }
}
/**********************************************************************/
void vAtExit(void)
{
__OBSL__;
return;
}
/**********************************************************************/
void vSigInt(int iSig)
{
/* Graceful exit after interrupt. */

signal(SIGINT, SIG_IGN);
signal(SIGQUIT, SIG_IGN);
signal(SIGTERM, SIG_IGN);
exit(EXIT_FAILURE);
return;
}
/**********************************************************************/

void _vZeroFile(FILE *fp, char *szName)
{
/* Delete empty data files. */

long slFL;

if(!fp)return;
fclose(fp);
fp=fopen(szName, "rb");
/* Get the file length without using non-ANSI filelength(fileno(fpIn)) */
fseek(fp, 0, SEEK_END);
slFL=ftell(fp);
rewind(fp);
if(slFL <= 0)
  {
  fclose(fp);
  remove(szName);
  }
else
  fclose(fp);
return;
}
/**********************************************************************/
/**********************************************************************/
/*       iEvalExprMPZ --- expression parser for mpz bigints           */
/**********************************************************************/
/**********************************************************************/
/* parser.c    GCC 3.04    GMP 4.01    DJGPP 2.03    2006.05.16.2240

Also tested for compatibility with GCC 4.02 and GMP 4.14
(-std=gnu99) running under GNU/Linux (kernel release
2.6.13-15-default, SUSE Linux 10.0 i386).

Procedure for evaluating integer expressions in string form to multiple
precision integers (mpz_t) using the GNU Multiple Precision Arithmetic
Library (GMP).

Copyright 1997-2006 Free Software Foundation, Inc. (FSF) under the
terms of the GNU General Public License (GPL). Mailing address:
Free Software Foundation, Inc., 59 Temple Place - Suite 330,
Boston, MA 02111-1307, USA.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU GPL as published by the FSF; either
version 2 of the license, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
GPL for additional details. */

/* This code is derived from PEXPR.C, received as part of the DJGPP
   GMP 4.01 package, downloaded April 2002 from the Arlington VA AOL
   mirror site. Modified 2002-2006 by Thomas R. Nicely
   <http://www.trnicely.net> from a standalone to a callable procedure.
   The error jumptables were eliminated in favor of an error return
   value, and the timing and printing options were removed (except
   after fatal errors). The procedure free_expr has been disabled
   (it simply returns) to alleviate an untraced fatal SIGSEGV violation,
   at the cost of a memory leak. This is one of many problems encountered
   with GMP's allocation, re-allocation, and memory clearing algorithms;
   either the GMP source code must be cleaned up, or workarounds must be
   introduced into each application code (as TRN has done in the
   preceding routines). However, iEvalExprMPZ, having been written by
   other parties, has largely been left "as is"; in general, TRN treats
   this code as a "black box"; until it breaks again, don't fix it. */

/* This expression evaluator works by building an expression tree (using a
   recursive descent parser) which is then evaluated.  The expression tree
   is useful since we want to optimize certain expressions (like a^b % c).

   int iEvalExprMPZ(mpz_t mpzResult, char *szExpression)

   Success returns zero.  Any non-zero return is failure, and mpzResult
   will contain zero.

   The expression may be in C or BASIC format, with some exceptions.
   Note that the exponentiation operator is "^" and the modulus
   operator is "%".  The primorial operator is "#" (unary postfix,
   like the factorial operator "!").
*/

#if __THIS_MODULE_STANDS_ALONE__
  #include <ctype.h>
  #include <stdlib.h>
  #include <string.h>
  #include <gmp.h>
#endif

#undef _PROTO
#if __GMP_HAVE_PROTOTYPES
#  define _PROTO(x) x
#else
#  define _PROTO(x) ()
#endif

enum op_t {NOP, LIT, NEG, NOT, PLUS, MINUS, MULT, DIV, MOD, REM, INVMOD, POW,
	   AND, IOR, XOR, SLL, SRA, POPCNT, HAMDIST, GCD, LCM, SQRT, ROOT, FAC,
	   LOG, LOG2, FERMAT, MERSENNE, FIBONACCI, RANDOM, NEXTPRIME,
           PRIMORIAL};

/* Type for the expression tree.  */
struct expr
{
  enum op_t op;
  union
  {
    struct {struct expr *lhs, *rhs;} ops;
    mpz_t val;
  } operands;
};
typedef struct expr *expr_t;

struct functions
{
  char *spelling;
  enum op_t op;
  int arity; /* 1 or 2 means real arity; 0 means arbitrary.  */
};
struct functions fns[] =
{
  {"sqrt", SQRT, 1},
#if __GNU_MP_VERSION >= 2
  {"root", ROOT, 2},
  {"popc", POPCNT, 1},
  {"hamdist", HAMDIST, 2},
#endif
  {"gcd", GCD, 0},
#if __GNU_MP_VERSION > 2 || __GNU_MP_VERSION_MINOR >= 1
  {"lcm", LCM, 0},
#endif
  {"and", AND, 0},
  {"ior", IOR, 0},
#if __GNU_MP_VERSION > 2 || __GNU_MP_VERSION_MINOR >= 1
  {"xor", XOR, 0},
#endif
  {"plus", PLUS, 0},
  {"pow", POW, 2},
  {"minus", MINUS, 2},
  {"mul", MULT, 0},
  {"div", DIV, 2},
  {"mod", MOD, 2},
  {"rem", REM, 2},
#if __GNU_MP_VERSION >= 2
  {"invmod", INVMOD, 2},
#endif
  {"log", LOG, 2},
  {"log2", LOG2, 1},
  {"F", FERMAT, 1},
  {"M", MERSENNE, 1},
  {"fib", FIBONACCI, 1},
  {"Fib", FIBONACCI, 1},
  {"random", RANDOM, 1},
  {"nextprime", NEXTPRIME, 1},
  {"", NOP, 0}
};

int iEvalExprMPZ(mpz_t mpzResult, char *szExpression);
static char *skipspace _PROTO ((char *));
static void makeexp _PROTO ((expr_t *, enum op_t, expr_t, expr_t));
static void free_expr _PROTO ((expr_t));
static char *expr _PROTO ((char *, expr_t *));
static char *term _PROTO ((char *, expr_t *));
static char *power _PROTO ((char *, expr_t *));
static char *factor _PROTO ((char *, expr_t *));
static int match _PROTO ((char *, char *));
static int matchp _PROTO ((char *, char *));
static void mpz_eval_expr _PROTO ((mpz_ptr, expr_t));
static void mpz_eval_mod_expr _PROTO ((mpz_ptr, expr_t, mpz_ptr));

char *error;
int iGlobalError;
char *newline = "";
gmp_randstate_t rstate;

/**********************************************************************/
int iEvalExprMPZ(mpz_t mpzResult, char *szExpression)
{
char *str, *pchAstAst, *szCopy;
struct expr *e;

iGlobalError=0;
gmp_randinit(rstate, GMP_RAND_ALG_LC, 128);

/* The following statements have been replaced to avoid problems
   caused by the absence of gettimeofday on some platforms:

   struct timeval tv;
   gettimeofday(&tv, NULL);
   gmp_randseed_ui(rstate, tv.tv_sec + tv.tv_usec); */

gmp_randseed_ui(rstate, 1 + time(NULL)*(314159311L + clock()));
szCopy=(char *)malloc(strlen(szExpression) + 1);
strcpy(szCopy, szExpression);  // Don't modify input
szTrimMWS(szCopy);
pchAstAst=strstr(szCopy, "**");  // Replace Fortran/Cobol ** by ^
while(pchAstAst)
  {
  *pchAstAst=' ';
  *(pchAstAst+1)='^';
  pchAstAst=strstr(pchAstAst+2, "**");
  }
str=expr(szCopy, &e);
if (str[0] != 0)
  {
  mpz_set_ui(mpzResult, 0);
  iGlobalError=1;
  free_expr(e);
  free(szCopy);
  return(EXIT_FAILURE);
  }
else
  {
  mpz_eval_expr(mpzResult, e);
  free_expr(e);
  free(szCopy);
  return(EXIT_SUCCESS);
  }
}
/**********************************************************************/
static char *expr (char *str, expr_t *e)
{
  expr_t e2;

  str = skipspace (str);
  if (str[0] == '+')
    {
      str = term (str + 1, e);
    }
  else if (str[0] == '-')
    {
      str = term (str + 1, e);
      makeexp (e, NEG, *e, NULL);
    }
  else if (str[0] == '~')
    {
      str = term (str + 1, e);
      makeexp (e, NOT, *e, NULL);
    }
  else
    {
      str = term (str, e);
    }

  for (;;)
    {
      str = skipspace (str);
      switch (str[0])
	{
	case 'p':
	  if (match ("plus", str))
	    {
	      str = term (str + 4, &e2);
	      makeexp (e, PLUS, *e, e2);
	    }
	  else
	    return str;
	  break;
	case 'm':
	  if (match ("minus", str))
	    {
	      str = term (str + 5, &e2);
	      makeexp (e, MINUS, *e, e2);
	    }
	  else
	    return str;
	  break;
	case '+':
	  str = term (str + 1, &e2);
	  makeexp (e, PLUS, *e, e2);
	  break;
	case '-':
	  str = term (str + 1, &e2);
	  makeexp (e, MINUS, *e, e2);
	  break;
	default:
	  return str;
	}
    }
}
/**********************************************************************/
static char *term (char *str, expr_t *e)
{
  expr_t e2;

  str = power (str, e);
  for (;;)
    {
      str = skipspace (str);
      switch (str[0])
	{
	case 'm':
	  if (match ("mul", str))
	    {
	      str = power (str + 3, &e2);
	      makeexp (e, MULT, *e, e2);
	      break;
	    }
	  if (match ("mod", str))
	    {
	      str = power (str + 3, &e2);
	      makeexp (e, MOD, *e, e2);
	      break;
	    }
	  return str;
	case 'd':
	  if (match ("div", str))
	    {
	      str = power (str + 3, &e2);
	      makeexp (e, DIV, *e, e2);
	      break;
	    }
	  return str;
	case 'r':
	  if (match ("rem", str))
	    {
	      str = power (str + 3, &e2);
	      makeexp (e, REM, *e, e2);
	      break;
	    }
	  return str;
	case 'i':
	  if (match ("invmod", str))
	    {
	      str = power (str + 6, &e2);
	      makeexp (e, REM, *e, e2);
	      break;
	    }
	  return str;
	case 't':
	  if (match ("times", str))
	    {
	      str = power (str + 5, &e2);
	      makeexp (e, MULT, *e, e2);
	      break;
	    }
	  if (match ("thru", str))
	    {
	      str = power (str + 4, &e2);
	      makeexp (e, DIV, *e, e2);
	      break;
	    }
	  if (match ("through", str))
	    {
	      str = power (str + 7, &e2);
	      makeexp (e, DIV, *e, e2);
	      break;
	    }
	  return str;
	case '*':
	  str = power (str + 1, &e2);
	  makeexp (e, MULT, *e, e2);
	  break;
	case '/':
	  str = power (str + 1, &e2);
	  makeexp (e, DIV, *e, e2);
	  break;
	case '%':
	  str = power (str + 1, &e2);
	  makeexp (e, MOD, *e, e2);
	  break;
	default:
	  return str;
	}
    }
}
/**********************************************************************/
static char *power (char *str, expr_t *e)
{
  expr_t e2;

  str = factor (str, e);
  while (str[0] == '!')
    {
      str++;
      makeexp (e, FAC, *e, NULL);
    }
  while (str[0] == '#')
    {
      str++;
      makeexp (e, PRIMORIAL, *e, NULL);
    }
  str = skipspace (str);
  if (str[0] == '^')
    {
      str = power (str + 1, &e2);
      makeexp (e, POW, *e, e2);
    }

  return str;
}
/**********************************************************************/
static int match (char *s, char *str)
{
  char *ostr = str;
  int i;

  for (i = 0; s[i] != 0; i++)
    {
      if (str[i] != s[i])
	return 0;
    }
  str = skipspace (str + i);
  return str - ostr;
}
/**********************************************************************/
static int matchp (char *s, char *str)
{
  char *ostr = str;
  int i;

  for (i = 0; s[i] != 0; i++)
    {
      if (str[i] != s[i])
	return 0;
    }
  str = skipspace (str + i);
  if (str[0] == '(')
    return str - ostr + 1;
  return 0;
}
/**********************************************************************/
static char *factor (char *str, expr_t *e)
{
  expr_t e1, e2;

  str = skipspace (str);

  if (isalpha (str[0]))
    {
      int i;
      int cnt;

      for (i = 0; fns[i].op != NOP; i++)
	{
	  if (fns[i].arity == 1)
	    {
	      cnt = matchp (fns[i].spelling, str);
	      if (cnt != 0)
		{
		  str = expr (str + cnt, &e1);
		  str = skipspace (str);
		  if (str[0] != ')')
		    {
                      iGlobalError=1;
                      return("1");
		    }
		  makeexp (e, fns[i].op, e1, NULL);
		  return str + 1;
		}
	    }
	}

      for (i = 0; fns[i].op != NOP; i++)
	{
	  if (fns[i].arity != 1)
	    {
	      cnt = matchp (fns[i].spelling, str);
	      if (cnt != 0)
		{
		  str = expr (str + cnt, &e1);
		  str = skipspace (str);

		  if (str[0] != ',')
		    {
                      iGlobalError=1;
                      return("1");
		    }

		  str = skipspace (str + 1);
		  str = expr (str, &e2);
		  str = skipspace (str);

		  if (fns[i].arity == 0)
		    {
		      while (str[0] == ',')
			{
			  makeexp (&e1, fns[i].op, e1, e2);
			  str = skipspace (str + 1);
			  str = expr (str, &e2);
			  str = skipspace (str);
			}
		    }

		  if (str[0] != ')')
		    {
                      iGlobalError=1;
                      return("1");
		    }

		  makeexp (e, fns[i].op, e1, e2);
		  return str + 1;
		}
	    }
	}
    }

  if (str[0] == '(')
    {
      str = expr (str + 1, e);
      str = skipspace (str);
      if (str[0] != ')')
	{
          iGlobalError=1;
          return("1");
	}
      str++;
    }
  else if (str[0] >= '0' && str[0] <= '9')
    {
      expr_t res;
      char *s, *sc;

      res = malloc (sizeof (struct expr));
      res -> op = LIT;
      mpz_init (res->operands.val);

      s = str;
      while (isalnum (str[0]))
	str++;
      sc = malloc (str - s + 1);
      memcpy (sc, s, str - s);
      sc[str - s] = 0;

      __mpz_set_str (res->operands.val, sc, 0);
      *e = res;
      free (sc);
    }
  else
    {
      iGlobalError=1;
      return("1");
    }
  return str;
}
/**********************************************************************/
static char *skipspace(char *str)
{
  while (str[0] == ' ')
    str++;
  return str;
}
/**********************************************************************/
static void makeexp(expr_t *r, enum op_t op, expr_t lhs, expr_t rhs)
{
/* Make a new expression with operation OP and right hand side
   RHS and left hand side lhs.  Put the result in R.  */

  expr_t res;
  res = malloc (sizeof (struct expr));
  res -> op = op;
  res -> operands.ops.lhs = lhs;
  res -> operands.ops.rhs = rhs;
  *r = res;
  return;
}
/**********************************************************************/
static void free_expr(expr_t e)
{
/* Free the memory used by expression E.  */

  return;

/* Bug-fixing hack (T. R. Nicely 2003.10.10).  This routine was
   generating unpredictable crashes (non-trappable SIGSEGV violations).
   Signal trapping and other measures failed to solve the problem,
   and the ultimate fault has not been fixed or even pinned down.
   Disabling the routine leaves a potential memory leak in the
   program, which has thus far not been a problem. */

  if (e->op != LIT)
    {
      free_expr (e->operands.ops.lhs);
      if (e->operands.ops.rhs != NULL)
	free_expr (e->operands.ops.rhs);
    }
  else
    {
      mpz_clear (e->operands.val);
    }
  return;
}
/**********************************************************************/
static void mpz_eval_expr(mpz_ptr r, expr_t e)
{
/* Evaluate the expression E and put the result in R.  */

  mpz_t lhs, rhs;

  switch (e->op)
    {
    case LIT:
      mpz_set (r, e->operands.val);
      return;
    case PLUS:
      mpz_init (lhs); mpz_init (rhs);
      mpz_eval_expr (lhs, e->operands.ops.lhs);
      mpz_eval_expr (rhs, e->operands.ops.rhs);
      mpz_add (r, lhs, rhs);
      mpz_clear (lhs); mpz_clear (rhs);
      return;
    case MINUS:
      mpz_init (lhs); mpz_init (rhs);
      mpz_eval_expr (lhs, e->operands.ops.lhs);
      mpz_eval_expr (rhs, e->operands.ops.rhs);
      mpz_sub (r, lhs, rhs);
      mpz_clear (lhs); mpz_clear (rhs);
      return;
    case MULT:
      mpz_init (lhs); mpz_init (rhs);
      mpz_eval_expr (lhs, e->operands.ops.lhs);
      mpz_eval_expr (rhs, e->operands.ops.rhs);
      mpz_mul (r, lhs, rhs);
      mpz_clear (lhs); mpz_clear (rhs);
      return;
    case DIV:
      mpz_init (lhs); mpz_init (rhs);
      mpz_eval_expr (lhs, e->operands.ops.lhs);
      mpz_eval_expr (rhs, e->operands.ops.rhs);
      mpz_fdiv_q (r, lhs, rhs);
      mpz_clear (lhs); mpz_clear (rhs);
      return;
    case MOD:
      mpz_init (rhs);
      mpz_eval_expr (rhs, e->operands.ops.rhs);
      mpz_abs (rhs, rhs);
      mpz_eval_mod_expr (r, e->operands.ops.lhs, rhs);
      mpz_clear (rhs);
      return;
    case REM:
      /* Check if lhs operand is POW expression and optimize for that case.  */
      if (e->operands.ops.lhs->op == POW)
	{
	  mpz_t powlhs, powrhs;
	  mpz_init (powlhs);
	  mpz_init (powrhs);
	  mpz_init (rhs);
	  mpz_eval_expr (powlhs, e->operands.ops.lhs->operands.ops.lhs);
	  mpz_eval_expr (powrhs, e->operands.ops.lhs->operands.ops.rhs);
	  mpz_eval_expr (rhs, e->operands.ops.rhs);
	  mpz_powm (r, powlhs, powrhs, rhs);
	  if (mpz_cmp_si (rhs, 0L) < 0)
	    mpz_neg (r, r);
	  mpz_clear (powlhs);
	  mpz_clear (powrhs);
	  mpz_clear (rhs);
	  return;
	}
      mpz_init (lhs); mpz_init (rhs);
      mpz_eval_expr (lhs, e->operands.ops.lhs);
      mpz_eval_expr (rhs, e->operands.ops.rhs);
      mpz_fdiv_r (r, lhs, rhs);
      mpz_clear (lhs); mpz_clear (rhs);
      return;
#if __GNU_MP_VERSION >= 2
    case INVMOD:
      mpz_init (lhs); mpz_init (rhs);
      mpz_eval_expr (lhs, e->operands.ops.lhs);
      mpz_eval_expr (rhs, e->operands.ops.rhs);
      mpz_invert (r, lhs, rhs);
      mpz_clear (lhs); mpz_clear (rhs);
      return;
#endif
    case POW:
      mpz_init (lhs); mpz_init (rhs);
      mpz_eval_expr (lhs, e->operands.ops.lhs);
      mpz_eval_expr (rhs, e->operands.ops.rhs);
      if (mpz_cmp_si (rhs, 0L) == 0)
	/* x^0 is 1 */
	mpz_set_ui (r, 1L);
      else if (mpz_cmp_si (lhs, 0L) == 0)
	/* 0^y (where y != 0) is 0 */
	mpz_set_ui (r, 0L);
      else if (mpz_cmp_ui (lhs, 1L) == 0)
	/* 1^y is 1 */
	mpz_set_ui (r, 1L);
      else if (mpz_cmp_si (lhs, -1L) == 0)
	/* (-1)^y just depends on whether y is even or odd */
	mpz_set_si (r, (mpz_get_ui (rhs) & 1) ? -1L : 1L);
      else if (mpz_cmp_si (rhs, 0L) < 0)
	/* x^(-n) is 0 */
	mpz_set_ui (r, 0L);
      else
	{
	  unsigned long int cnt;
	  unsigned long int y;
	  /* error if exponent does not fit into an unsigned long int.  */
	  if (mpz_cmp_ui (rhs, ~(unsigned long int) 0) > 0)
	    goto pow_err;

	  y = mpz_get_ui (rhs);
	  /* x^y == (x/(2^c))^y * 2^(c*y) */
#if __GNU_MP_VERSION >= 2
	  cnt = mpz_scan1 (lhs, 0);
#else
	  cnt = 0;
#endif
	  if (cnt != 0)
	    {
	      if (y * cnt / cnt != y)
		goto pow_err;
	      mpz_tdiv_q_2exp (lhs, lhs, cnt);
	      mpz_pow_ui (r, lhs, y);
	      mpz_mul_2exp (r, r, y * cnt);
	    }
	  else
	    mpz_pow_ui (r, lhs, y);
	}
      mpz_clear (lhs); mpz_clear (rhs);
      return;
    pow_err:
      error = "result of `pow' operator too large";
      mpz_clear (lhs); mpz_clear (rhs);
      iGlobalError=1;
      mpz_set_ui(r,1);
      return;
    case GCD:
      mpz_init (lhs); mpz_init (rhs);
      mpz_eval_expr (lhs, e->operands.ops.lhs);
      mpz_eval_expr (rhs, e->operands.ops.rhs);
      mpz_gcd (r, lhs, rhs);
      mpz_clear (lhs); mpz_clear (rhs);
      return;
#if __GNU_MP_VERSION > 2 || __GNU_MP_VERSION_MINOR >= 1
    case LCM:
      mpz_init (lhs); mpz_init (rhs);
      mpz_eval_expr (lhs, e->operands.ops.lhs);
      mpz_eval_expr (rhs, e->operands.ops.rhs);
      mpz_lcm (r, lhs, rhs);
      mpz_clear (lhs); mpz_clear (rhs);
      return;
#endif
    case AND:
      mpz_init (lhs); mpz_init (rhs);
      mpz_eval_expr (lhs, e->operands.ops.lhs);
      mpz_eval_expr (rhs, e->operands.ops.rhs);
      mpz_and (r, lhs, rhs);
      mpz_clear (lhs); mpz_clear (rhs);
      return;
    case IOR:
      mpz_init (lhs); mpz_init (rhs);
      mpz_eval_expr (lhs, e->operands.ops.lhs);
      mpz_eval_expr (rhs, e->operands.ops.rhs);
      mpz_ior (r, lhs, rhs);
      mpz_clear (lhs); mpz_clear (rhs);
      return;
#if __GNU_MP_VERSION > 2 || __GNU_MP_VERSION_MINOR >= 1
    case XOR:
      mpz_init (lhs); mpz_init (rhs);
      mpz_eval_expr (lhs, e->operands.ops.lhs);
      mpz_eval_expr (rhs, e->operands.ops.rhs);
      mpz_xor (r, lhs, rhs);
      mpz_clear (lhs); mpz_clear (rhs);
      return;
#endif
    case NEG:
      mpz_eval_expr (r, e->operands.ops.lhs);
      mpz_neg (r, r);
      return;
    case NOT:
      mpz_eval_expr (r, e->operands.ops.lhs);
      mpz_com (r, r);
      return;
    case SQRT:
      mpz_init (lhs);
      mpz_eval_expr (lhs, e->operands.ops.lhs);
      if (mpz_sgn (lhs) < 0)
	{
	  error = "cannot take square root of negative numbers";
	  mpz_clear (lhs);
	  iGlobalError=1;
          mpz_set_ui(r,1);
          return;
	}
      mpz_sqrt (r, lhs);
      return;
#if __GNU_MP_VERSION > 2 || __GNU_MP_VERSION_MINOR >= 1
    case ROOT:
      mpz_init (lhs); mpz_init (rhs);
      mpz_eval_expr (lhs, e->operands.ops.lhs);
      mpz_eval_expr (rhs, e->operands.ops.rhs);
      if (mpz_sgn (rhs) <= 0)
	{
	  error = "cannot take non-positive root orders";
	  mpz_clear (lhs); mpz_clear (rhs);
	  iGlobalError=1;
          mpz_set_ui(r,1);
          return;
	}
      if (mpz_sgn (lhs) < 0 && (mpz_get_ui (rhs) & 1) == 0)
	{
	  error = "cannot take even root orders of negative numbers";
	  mpz_clear (lhs); mpz_clear (rhs);
	  iGlobalError=1;
          mpz_set_ui(r,1);
          return;
	}

      {
	unsigned long int nth = mpz_get_ui (rhs);
	if (mpz_cmp_ui (rhs, ~(unsigned long int) 0) > 0)
	  {
	    /* If we are asked to take an awfully large root order, cheat and
	       ask for the largest order we can pass to mpz_root.  This saves
	       some error prone special cases.  */
	    nth = ~(unsigned long int) 0;
	  }
	mpz_root (r, lhs, nth);
      }
      mpz_clear (lhs); mpz_clear (rhs);
      return;
#endif
    case FAC:
      mpz_eval_expr (r, e->operands.ops.lhs);
      if (mpz_size (r) > 1)
	{
	  error = "result of `!' operator too large";
	  iGlobalError=1;
          mpz_set_ui(r,1);
          return;
	}
      mpz_fac_ui (r, mpz_get_ui (r));
      return;
    case PRIMORIAL:
      mpz_eval_expr (r, e->operands.ops.lhs);
      if (mpz_size (r) > 1)
	{
	  error = "result of `#' operator too large";
	  iGlobalError=1;
          mpz_set_ui(r,1);
          return;
	}
      { unsigned long ulArg;
        ulArg=mpz_get_ui(r);
        if(ulArg < 2){mpz_set_ui(r,1);return;}
        mpz_set_ui(r,2);
        if(ulArg < 3)return;
        mpz_init(lhs); mpz_init(rhs);
        mpz_set_ui(rhs, 2);
        while(1)
          {
          mpz_nextprime(lhs,rhs); /* rhs=prev_prime, lhs=next_prime */
          if(mpz_cmp_ui(lhs,ulArg) > 0)break;
          mpz_mul(r,lhs,r);
          mpz_set(rhs,lhs);
          }
        mpz_clear(lhs);mpz_clear(rhs);
      }
      return;
#if __GNU_MP_VERSION >= 2
    case POPCNT:
      mpz_eval_expr (r, e->operands.ops.lhs);
      { long int cnt;
	cnt = mpz_popcount (r);
	mpz_set_si (r, cnt);
      }
      return;
    case HAMDIST:
      { long int cnt;
        mpz_init (lhs); mpz_init (rhs);
	mpz_eval_expr (lhs, e->operands.ops.lhs);
	mpz_eval_expr (rhs, e->operands.ops.rhs);
	cnt = mpz_hamdist (lhs, rhs);
	mpz_clear (lhs); mpz_clear (rhs);
	mpz_set_si (r, cnt);
      }
      return;
#endif
    case LOG2:
      mpz_eval_expr (r, e->operands.ops.lhs);
      { unsigned long int cnt;
	if (mpz_sgn (r) <= 0)
	  {
	    error = "logarithm of non-positive number";
            iGlobalError=1;
            mpz_set_ui(r,1);
            return;
	  }
	cnt = mpz_sizeinbase (r, 2);
	mpz_set_ui (r, cnt - 1);
      }
      return;
    case LOG:
      { unsigned long int cnt;
	mpz_init (lhs); mpz_init (rhs);
	mpz_eval_expr (lhs, e->operands.ops.lhs);
	mpz_eval_expr (rhs, e->operands.ops.rhs);
	if (mpz_sgn (lhs) <= 0)
	  {
	    error = "logarithm of non-positive number";
	    mpz_clear (lhs); mpz_clear (rhs);
            iGlobalError=1;
            mpz_set_ui(r,1);
            return;
	  }
	if (mpz_cmp_ui (rhs, 256) >= 0)
	  {
	    error = "logarithm base too large";
	    mpz_clear (lhs); mpz_clear (rhs);
            iGlobalError=1;
            mpz_set_ui(r,1);
            return;
	  }
	cnt = mpz_sizeinbase (lhs, mpz_get_ui (rhs));
	mpz_set_ui (r, cnt - 1);
	mpz_clear (lhs); mpz_clear (rhs);
      }
      return;
    case FERMAT:
      {
	unsigned long int t;
	mpz_init (lhs);
	mpz_eval_expr (lhs, e->operands.ops.lhs);
	t = (unsigned long int) 1 << mpz_get_ui (lhs);
	if (mpz_cmp_ui (lhs, ~(unsigned long int) 0) > 0 || t == 0)
	  {
	    error = "too large Mersenne number index";
	    mpz_clear (lhs);
            iGlobalError=1;
            mpz_set_ui(r,1);
            return;
	  }
	mpz_set_ui (r, 1);
	mpz_mul_2exp (r, r, t);
	mpz_add_ui (r, r, 1);
	mpz_clear (lhs);
      }
      return;
    case MERSENNE:
      mpz_init (lhs);
      mpz_eval_expr (lhs, e->operands.ops.lhs);
      if (mpz_cmp_ui (lhs, ~(unsigned long int) 0) > 0)
	{
	  error = "too large Mersenne number index";
	  mpz_clear (lhs);
          iGlobalError=1;
          mpz_set_ui(r,1);
          return;
	}
      mpz_set_ui (r, 1);
      mpz_mul_2exp (r, r, mpz_get_ui (lhs));
      mpz_sub_ui (r, r, 1);
      mpz_clear (lhs);
      return;
    case FIBONACCI:
      { mpz_t t;
	unsigned long int n, i;
	mpz_init (lhs);
	mpz_eval_expr (lhs, e->operands.ops.lhs);
	if (mpz_sgn (lhs) <= 0 || mpz_cmp_si (lhs, 1000000000) > 0)
	  {
	    error = "Fibonacci index out of range";
	    mpz_clear (lhs);
            iGlobalError=1;
            mpz_set_ui(r,1);
            return;
	  }
	n = mpz_get_ui (lhs);
	mpz_clear (lhs);

#if __GNU_MP_VERSION > 2 || __GNU_MP_VERSION_MINOR >= 1
	mpz_fib_ui (r, n);
#else
	mpz_init_set_ui (t, 1);
	mpz_set_ui (r, 1);

	if (n <= 2)
	  mpz_set_ui (r, 1);
	else
	  {
	    for (i = 3; i <= n; i++)
	      {
		mpz_add (t, t, r);
		mpz_swap (t, r);
	      }
	  }
	mpz_clear (t);
#endif
      }
      return;
    case RANDOM:
      {
	unsigned long int n;
	mpz_init (lhs);
	mpz_eval_expr (lhs, e->operands.ops.lhs);
	if (mpz_sgn (lhs) <= 0 || mpz_cmp_si (lhs, 1000000000) > 0)
	  {
	    error = "random number size out of range";
	    mpz_clear (lhs);
            iGlobalError=1;
            mpz_set_ui(r,1);
            return;
	  }
	n = mpz_get_ui (lhs);
	mpz_clear (lhs);
	mpz_urandomb (r, rstate, n);
      }
      return;
    case NEXTPRIME:
      {
	mpz_eval_expr (r, e->operands.ops.lhs);
	mpz_nextprime (r, r);
      }
      return;
    default:
      abort ();
    }
}
/**********************************************************************/
static void mpz_eval_mod_expr (mpz_ptr r, expr_t e, mpz_ptr mod)
{
/* Evaluate the expression E modulo MOD and put the result in R.  */
  mpz_t lhs, rhs;

  switch (e->op)
    {
      case POW:
	mpz_init (lhs); mpz_init (rhs);
	mpz_eval_mod_expr (lhs, e->operands.ops.lhs, mod);
	mpz_eval_expr (rhs, e->operands.ops.rhs);
	mpz_powm (r, lhs, rhs, mod);
	mpz_clear (lhs); mpz_clear (rhs);
	return;
      case PLUS:
	mpz_init (lhs); mpz_init (rhs);
	mpz_eval_mod_expr (lhs, e->operands.ops.lhs, mod);
	mpz_eval_mod_expr (rhs, e->operands.ops.rhs, mod);
	mpz_add (r, lhs, rhs);
	if (mpz_cmp_si (r, 0L) < 0)
	  mpz_add (r, r, mod);
	else if (mpz_cmp (r, mod) >= 0)
	mpz_sub (r, r, mod);
	mpz_clear (lhs); mpz_clear (rhs);
	return;
      case MINUS:
	mpz_init (lhs); mpz_init (rhs);
	mpz_eval_mod_expr (lhs, e->operands.ops.lhs, mod);
	mpz_eval_mod_expr (rhs, e->operands.ops.rhs, mod);
	mpz_sub (r, lhs, rhs);
	if (mpz_cmp_si (r, 0L) < 0)
	  mpz_add (r, r, mod);
	else if (mpz_cmp (r, mod) >= 0)
	  mpz_sub (r, r, mod);
	mpz_clear (lhs); mpz_clear (rhs);
	return;
      case MULT:
	mpz_init (lhs); mpz_init (rhs);
	mpz_eval_mod_expr (lhs, e->operands.ops.lhs, mod);
	mpz_eval_mod_expr (rhs, e->operands.ops.rhs, mod);
	mpz_mul (r, lhs, rhs);
	mpz_mod (r, r, mod);
	mpz_clear (lhs); mpz_clear (rhs);
	return;
      default:
	mpz_init (lhs);
	mpz_eval_expr (lhs, e);
	mpz_mod (r, lhs, mod);
	mpz_clear (lhs);
	return;
    }
}
/**********************************************************************/
/**********************************************************************/

/**********************************************************************/
/**********************************************************************/
/*                        Inactive routines                           */
/**********************************************************************/
/**********************************************************************/
#if 0
/**********************************************************************/
unsigned long ulSqrt(unsigned long long ullN)
/*
 * Computes floor(sqrt(ullN)), using a Newton-Raphson method for
 * arguments exceeding double precision integer capacity.
 *
 * This is an alternative to the ulSqrt routine currently active.
 *
 */
{
#ifndef DBL_MANT_DIG
  #define DBL_MANT_DIG 53
#endif

unsigned long long ullA, ullNdiva, ullNewa, ullDoubleMax=1;

if(ullN >= ULONG_MAX*ULONG_MAX)return(ULONG_MAX);
if(ullN==0)return(0);
if(ullN < 4)return(1);
if(ullN < 9)return(2);
ullDoubleMax <<= (DBL_MANT_DIG - 1);
if(ullN < ullDoubleMax)
  return((unsigned long)(floor(sqrt(ullN + 0.5))));
/*
 * The following algorithm was adapted from Arjen Lenstra's ZBIGINT code.
 */
ullA = ullN/2;
while (1)
  {
  ullNdiva = ullN/ullA;
  ullNewa = (ullNdiva+ullA)/2;
  if(ullNewa-ullNdiva <= 1)
    if(ullNewa*ullNewa <= ullN)
      return(ullNewa);
    else
      return(ullNdiva);
  ullA=ullNewa;
  }
}
/**********************************************************************/
long double _mpz_log10l(mpz_t mpz)
{
/* Version valid only for mpz's within long double range */
char            *pch;
long double     ld;

if(mpz_sgn(mpz) <= 0)
  {
  fprintf(stderr, "\n ERROR: Domain error (mpz <= 0) in _mpz_log10l.\n\n");
  exit(EXIT_FAILURE);
  }
if(mpz_sizeinbase(mpz, 2) >= -LDBL_MIN_EXP)
  {
  fprintf(stderr,
    "\n ERROR: Domain error (|mpz| too large) in _mpz_log10l.\n\n");
  exit(EXIT_FAILURE);
  }
pch=(char *)malloc(mpz_sizeinbase(mpz, 10) + 2);
mpz_get_str(pch, 10, mpz);
ld=__strtold(pch, NULL);
ld=log10l(ld);
free(pch);
return(ld);
}
/**********************************************************************/
#endif  /* Inactive routines */
