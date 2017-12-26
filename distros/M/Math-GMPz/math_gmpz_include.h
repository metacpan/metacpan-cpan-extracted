#include <stdio.h>
#include <stdlib.h>
#include <gmp.h>

#if defined(NV_IS_FLOAT128)
#include <quadmath.h>
#endif

#if !defined(__GNU_MP_VERSION) || __GNU_MP_VERSION < 5
#define mp_bitcnt_t unsigned long int
#endif

#ifdef _MSC_VER
#pragma warning(disable:4700 4715 4716)
#endif

#if defined MATH_GMPZ_NEED_LONG_LONG_INT
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

/* for Math::BigInt overloading */
#define MBI_DECLARATIONS		\
     mpz_t * mpz = (mpz_t *)NULL;	\
     const char * sign;			\
     SV ** sign_key;

#define VALIDATE_MBI_OBJECT				\
     sign_key  = hv_fetch((HV*)SvRV(b), "sign", 4, 0);	\
     sign = SvPV_nolen(*sign_key);			\
     if(strNE("-", sign) && strNE("+", sign))

#ifdef ENABLE_MATH_BIGINT_GMP_OVERLOAD		/* start ENABLE_MATH_BIGINT_GMP_OVERLOAD */

#ifndef PERL_MAGIC_ext
#  define PERL_MAGIC_ext '~'
#endif

#ifdef sv_magicext
#  define MATH_GMPz_HAS_MAGICEXT 1
#else
#  define MATH_GMPz_HAS_MAGICEXT 0
#endif

#define MBI_GMP_DECLARATIONS 	\
     const char * h2;		\
     MAGIC * mg;		\
     SV ** value_key;

#if MATH_GMPz_HAS_MAGICEXT

#define VALUE_TO_MPZ 							\
  for(mg = SvMAGIC(SvRV(*value_key)); mg; mg = mg->mg_moremagic) {	\
    if(mg->mg_type == PERL_MAGIC_ext) {					\
      mpz = (mpz_t *)mg->mg_ptr;					\
      break;								\
    }	 								\
  }

#else

#define VALUE_TO_MPZ 							\
  for(mg = SvMAGIC(SvRV(*value_key)); mg; mg = mg->mg_moremagic) {	\
    if(mg->mg_type == PERL_MAGIC_ext) {					\
      mpz = INT2PTR(mpz_t *, SvIV((SV *)mg->mg_ptr));			\
      break;								\
    }									\
  }

#endif

#define MBI_GMP_INSERT 							\
  value_key = hv_fetch((HV*)SvRV(b), "value", 5, 0);			\
  if(sv_isobject(*value_key)) {						\
    h2 = HvNAME(SvSTASH(SvRV(*value_key)));				\
    if(strEQ(h2, "Math::BigInt::GMP")) {				\
      VALUE_TO_MPZ							\
    }									\
  }


#else

#define MBI_GMP_DECLARATIONS
#define MBI_GMP_INSERT

#endif						/* end ENABLE_MATH_BIGINT_GMP_OVERLOAD */

#define _overload_callback(_1st_arg,_2nd_arg,_3rd_arg)						\
  dSP;											\
  SV * ret;										\
  int count;										\
  char buf[32];										\
  ENTER;										\
  PUSHMARK(SP);										\
  XPUSHs(b);										\
  XPUSHs(a);										\
  XPUSHs(sv_2mortal(_3rd_arg));							\
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


