
#ifdef  __MINGW32__
#ifndef __USE_MINGW_ANSI_STDIO
#define __USE_MINGW_ANSI_STDIO 1
#endif
#endif

#define PERL_NO_GET_CONTEXT 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


#include "../math_mpfr_include.h"

SV * ___GNU_MP_VERSION(pTHX) {
     return newSVuv(__GNU_MP_VERSION);
}

SV * ___GNU_MP_VERSION_MINOR(pTHX) {
     return newSVuv(__GNU_MP_VERSION_MINOR);
}

SV * ___GNU_MP_VERSION_PATCHLEVEL(pTHX) {
     return newSVuv(__GNU_MP_VERSION_PATCHLEVEL);
}

SV * ___GMP_CC(pTHX) {
#ifdef __GMP_CC
     char * ret = __GMP_CC;
     return newSVpv(ret, 0);
#else
     return &PL_sv_undef;
#endif
}

SV * ___GMP_CFLAGS(pTHX) {
#ifdef __GMP_CFLAGS
     char * ret = __GMP_CFLAGS;
     return newSVpv(ret, 0);
#else
     return &PL_sv_undef;
#endif
}

/*
Removed - don't want library functions in this module

SV * gmp_v(pTHX) {
#if __GNU_MP_VERSION >= 4
     return newSVpv(gmp_version, 0);
#else
     warn("From Math::MPFR::V::gmp_v function: 'gmp_version' is not implemented - returning '0'");
     return newSVpv("0", 0);
#endif
}
*/

SV * _MPFR_VERSION(pTHX) {
     return newSVuv(MPFR_VERSION);
}

SV * _MPFR_VERSION_MAJOR(pTHX) {
     return newSVuv(MPFR_VERSION_MAJOR);
}

SV * _MPFR_VERSION_MINOR(pTHX) {
     return newSVuv(MPFR_VERSION_MINOR);
}

SV * _MPFR_VERSION_PATCHLEVEL(pTHX) {
     return newSVuv(MPFR_VERSION_PATCHLEVEL);
}

SV * _MPFR_VERSION_STRING(pTHX) {
     return newSVpv(MPFR_VERSION_STRING, 0);
}

/*
Removed - don't want library functions in this module

SV * Rmpfr_get_version(pTHX) {
     return newSVpv(mpfr_get_version(), 0);
}
*/


MODULE = Math::MPFR::V  PACKAGE = Math::MPFR::V

PROTOTYPES: DISABLE


SV *
___GNU_MP_VERSION ()
CODE:
  RETVAL = ___GNU_MP_VERSION (aTHX);
OUTPUT:  RETVAL


SV *
___GNU_MP_VERSION_MINOR ()
CODE:
  RETVAL = ___GNU_MP_VERSION_MINOR (aTHX);
OUTPUT:  RETVAL


SV *
___GNU_MP_VERSION_PATCHLEVEL ()
CODE:
  RETVAL = ___GNU_MP_VERSION_PATCHLEVEL (aTHX);
OUTPUT:  RETVAL


SV *
___GMP_CC ()
CODE:
  RETVAL = ___GMP_CC (aTHX);
OUTPUT:  RETVAL


SV *
___GMP_CFLAGS ()
CODE:
  RETVAL = ___GMP_CFLAGS (aTHX);
OUTPUT:  RETVAL


SV *
_MPFR_VERSION ()
CODE:
  RETVAL = _MPFR_VERSION (aTHX);
OUTPUT:  RETVAL


SV *
_MPFR_VERSION_MAJOR ()
CODE:
  RETVAL = _MPFR_VERSION_MAJOR (aTHX);
OUTPUT:  RETVAL


SV *
_MPFR_VERSION_MINOR ()
CODE:
  RETVAL = _MPFR_VERSION_MINOR (aTHX);
OUTPUT:  RETVAL


SV *
_MPFR_VERSION_PATCHLEVEL ()
CODE:
  RETVAL = _MPFR_VERSION_PATCHLEVEL (aTHX);
OUTPUT:  RETVAL


SV *
_MPFR_VERSION_STRING ()
CODE:
  RETVAL = _MPFR_VERSION_STRING (aTHX);
OUTPUT:  RETVAL


