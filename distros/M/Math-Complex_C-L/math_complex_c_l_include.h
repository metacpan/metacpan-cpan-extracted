
#include <complex.h>

#ifdef OLDPERL
#define SvUOK SvIsUV
#endif

#ifndef Newx
#  define Newx(v,n,t) New(0,v,n,t)
#endif

#ifndef Newxz
#  define Newxz(v,n,t) Newz(0,v,n,t)
#endif

/* A perl bug in perl-5.20 onwards can break &PL_sv_yes and  *
 * &PL_sv_no. In the overload subs we therefore instead      *
 * use  SvTRUE_nomg_NN where possible, which is available    *
 * beginning with perl-5.18.0.                               *
 * Otherwise we continue using &PL_sv_yes as original        *
 * (&PL_sv_no is not used by this module.)                   *
 * See See https://github.com/sisyphus/math-decimal64/pull/1 */

#if defined SvTRUE_nomg_NN
#define SWITCH_ARGS SvTRUE_nomg_NN(third)
#else
#define SWITCH_ARGS third==&PL_sv_yes
#endif

#if defined(LDBL_MANT_DIG)
#if LDBL_MANT_DIG == 53
#define _DIGITS 17
#endif
#if LDBL_MANT_DIG == 64
#define _DIGITS 21
#endif
#if LDBL_MANT_DIG == 106
#define _DIGITS 33
#endif
#if LDBL_MANT_DIG == 113
#define _DIGITS 36
#endif
#elif defined(DBL_MANT_DIG)
#if DBL_MANT_DIG == 53
#define _DIGITS 17
#endif
#else
#define _DIGITS 21
#endif

#ifndef _DIGITS
#define _DIGITS 21
#endif

int _MATH_COMPLEX_C_L_DIGITS = _DIGITS;
