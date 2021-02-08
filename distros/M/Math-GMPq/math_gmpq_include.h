#include <stdio.h>
#include <stdlib.h>
#include <gmp.h>
#include <limits.h>

#if defined(NV_IS_FLOAT128)
#include <quadmath.h>
#endif

#ifdef _MSC_VER
#pragma warning(disable:4700 4715 4716)
#endif

#if defined MATH_GMPQ_NEED_LONG_LONG_INT
#ifndef _MSC_VER
#include <inttypes.h>
#endif
#endif

#ifdef OLDPERL
#define SvUOK SvIsUV
#endif

#ifndef Newx
#  define Newx(v,n,t) New(0,v,n,t)
#endif

#ifndef Newxz
#  define Newxz(v,n,t) Newz(0,v,n,t)
#endif

#define _overload_callback(_1st_arg,_2nd_arg,_3rd_arg)					\
  dSP;											\
  SV * ret;										\
  int count;										\
  char buf[32];										\
  ENTER;										\
  PUSHMARK(SP);										\
  XPUSHs(b);										\
  XPUSHs(a);										\
  XPUSHs(sv_2mortal(_3rd_arg));								\
  PUTBACK;										\
  sprintf(buf, "%s", _1st_arg);								\
  count = call_pv(buf, G_SCALAR);							\
  SPAGAIN;										\
  if (count != 1)									\
   croak("Error in %s callback to %s\n", _2nd_arg, _1st_arg);				\
  ret = POPs;										\
  SvREFCNT_inc(ret);									\
  LEAVE;										\
  return ret

