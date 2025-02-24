#include <stdio.h>
#include <stdlib.h>
#include <gmp.h>

#if defined(USE_QUADMATH) || defined(LD_PRINTF_BROKEN)
#include <quadmath.h>
#endif

#if !defined(__GNU_MP_VERSION) || __GNU_MP_VERSION < 5
#define mp_bitcnt_t unsigned long int
#endif

/*
#ifdef _MSC_VER
#pragma warning(disable:4700 4715 4716)
#endif
*/

#if defined MATH_GMPZ_NEED_LONG_LONG_INT
#include <inttypes.h>
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

#define SV_IS_IOK(x) \
     SvIOK(x)

#define SV_IS_POK(x) \
     SvPOK(x)

#define SV_IS_NOK(x) \
     SvNOK(x)

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


#if defined(_GMP_INDEX_OVERFLOW) && __GNU_MP_VERSION < 7
#define CHECK_MP_BITCNT_T_OVERFLOW(x)							\
     if((mp_bitcnt_t)SvUV(x) < SvUV(x))							\
       croak("Magnitude of UV argument overflows mp_bitcnt_t");
#else
#define CHECK_MP_BITCNT_T_OVERFLOW(x)
#endif

#define RMPZ_IMPORT_UTF8_WARN \
"  UTF8 string encountered in Rmpz_import. It will be utf8-downgraded\n\
  before being passed to mpz_import, and then will be restored to\n\
  its original condition by a utf8::upgrade if:\n\
    1) the downgrade was successful\n\
      OR\n\
    2) $Math::GMPz::utf8_no_croak is set to a true integer value.\n\
  Otherwise, a downgrade failure will cause the program to croak\n\
  with an explanatory error message.\n\
  To disable the croak on downgrade failure set $Math::GMPz::utf8_no_croak to 1.\n\
  See the Rmpz_import documentation for a more detailed explanation.\n"

#define RMPZ_IMPORT_DOWNGRADE_WARN \
"  An attempted utf8 downgrade has failed, but you have opted to allow\n\
  the Rmpz_import() to continue. Should you decide that this is not the\n\
  behaviour that you want, then please reset $Math::GMPz::utf8_no_croak\n\
  to its original value of 0\n"

