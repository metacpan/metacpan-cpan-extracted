
#ifdef  __MINGW32__
#ifndef __USE_MINGW_ANSI_STDIO
#define __USE_MINGW_ANSI_STDIO 1
#endif
#endif

#define PERL_NO_GET_CONTEXT 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef NV_IS_FLOAT128
#include <quadmath.h>
#ifdef __MINGW64__
typedef __float128 float128 __attribute__ ((aligned(8)));
#else
typedef __float128 float128;
#endif
#endif
#include <stdlib.h>
#include <float.h>

#ifdef _MSC_VER
#ifndef strtold
#define strtold strtod
#endif
#endif

#ifndef Newx
#  define Newx(v,n,t) New(0,v,n,t)
#endif

#ifdef NV_IS_FLOAT128
typedef float128 ARGTYPE;
#endif
#ifdef NV_IS_LONG_DOUBLE
typedef long double ARGTYPE;
#endif
#ifdef NV_IS_DOUBLE
typedef double ARGTYPE;
#endif

SV * _itsa(pTHX_ SV * a) {
     if(SvUOK(a)) return newSVuv(1);
     if(SvIOK(a)) return newSVuv(2);
     if(SvNOK(a)) return newSVuv(3);
     if(SvPOK(a)) return newSVuv(4);
     return newSVuv(0);
}

void nv(pTHX_ SV * str) {
   dXSARGS;
   char * unparsed;
#ifdef NV_IS_FLOAT128
   float128 num = strtoflt128(SvPV_nolen(str), &unparsed);
#endif
#ifdef NV_IS_LONG_DOUBLE
   long double num = strtold(SvPV_nolen(str), &unparsed);
#endif
#ifdef NV_IS_DOUBLE
   double num = strtod (SvPV_nolen(str), &unparsed);
#endif

   if(!SvIV(get_sv("Math::NV::no_warn", 0))) {
     if(SvUV(_itsa(aTHX_ str)) != 4)
       warn("Argument given to nv function is not a string - probably not what you want");
   }

   ST(0) = sv_2mortal(newSVnv(num));
   if(GIMME == G_ARRAY) {
     EXTEND(SP, 1);
     if(unparsed)
       ST(1) = sv_2mortal(newSViv(strlen(unparsed)));
     else
       ST(1) = sv_2mortal(newSViv(0));
     XSRETURN(2);
   }
   XSRETURN(1);
}

SV * nv_type(pTHX) {
#ifdef NV_IS_FLOAT128
   return newSVpv("__float128", 0);
#endif
#ifdef NV_IS_LONG_DOUBLE
   return newSVpv("long double", 0);
#endif
#ifdef NV_IS_DOUBLE
   return newSVpv("double", 0);
#endif
}

unsigned long mant_dig(void) {
#ifdef NV_IS_FLOAT128
   return FLT128_MANT_DIG;
#endif
#ifdef NV_IS_LONG_DOUBLE
   return LDBL_MANT_DIG;
#endif
#ifdef NV_IS_DOUBLE
   return DBL_MANT_DIG;
#endif
}

int Isnan_ld (ARGTYPE d) {
  if(d == d) return 0;
  return 1;
}

/********************************************************
   Code for _ld2binary and _ld_str2binary plagiarised from
   tests/tset_ld.c in the mpfr library source.
********************************************************/

void _ld2binary (pTHX_ SV * ld) {

  dXSARGS;
  ARGTYPE d = (ARGTYPE)SvNV(ld);
  ARGTYPE e;
  int exp = 1;
  unsigned long int prec = 0;
  int returns = 0;

  sp = mark;

  if(Isnan_ld(d)) {
      XPUSHs(sv_2mortal(newSVpv("@NaN@", 0)));
      XPUSHs(sv_2mortal(newSViv(exp)));
      XPUSHs(sv_2mortal(newSViv(prec)));
      XSRETURN(3);
  }

  if (d < (ARGTYPE) 0.0 || (d == (ARGTYPE) 0.0 && (1.0 / (double) d < 0.0))) {
      XPUSHs(sv_2mortal(newSVpv("-", 0)));
      returns++;
      d = -d;
  }

  /* now d >= 0 */
  /* Use 2 differents tests for Inf, to avoid potential bugs
     in implementations. */
  if (Isnan_ld (d - d) || (d > 1 && d * 0.5 == d)) {
      XPUSHs(sv_2mortal(newSVpv("@Inf@", 0)));
      XPUSHs(sv_2mortal(newSViv(exp)));
      XPUSHs(sv_2mortal(newSViv(prec)));
      returns += 3;
      XSRETURN(returns);
  }

  if (d == (ARGTYPE) 0.0) {
      XPUSHs(sv_2mortal(newSVpv("0.0", 0)));
      XPUSHs(sv_2mortal(newSViv(exp)));
      XPUSHs(sv_2mortal(newSViv(prec)));
      returns += 3;
      XSRETURN(returns);
  }

  /* now d > 0 */
  e = (ARGTYPE) 1.0;
  while (e > d) {
      e = e * (ARGTYPE) 0.5;
      exp --;
  }

  /* now d >= e */
  while (d >= e + e) {
      e = e + e;
      exp ++;
  }

  /* now e <= d < 2e */
  XPUSHs(sv_2mortal(newSVpv("0.", 0)));
  returns ++;

  while (d > (ARGTYPE) 0.0) {
      prec++;
      if(d >= e) {
        XPUSHs(sv_2mortal(newSVpv("1", 0)));
        returns ++;
        d = (ARGTYPE) ((ARGTYPE) d - (ARGTYPE) e);
      }
      else {
        XPUSHs(sv_2mortal(newSVpv("0", 0)));
        returns ++;
      }
      e *= (ARGTYPE) 0.5;
  }

  XPUSHs(sv_2mortal(newSViv(exp)));
  XPUSHs(sv_2mortal(newSViv(prec)));
  returns += 2;
  XSRETURN(returns);
}

void _ld_str2binary (pTHX_ char * ld) {

  dXSARGS;
  ARGTYPE d;
  ARGTYPE e;
  int exp = 1;
  unsigned long int prec = 0;
  int returns = 0;

#ifdef NV_IS_FLOAT128
  d = strtoflt128(ld, NULL);
#endif
#ifdef NV_IS_LONG_DOUBLE
  d = strtold(ld, NULL);
#endif
#ifdef NV_IS_DOUBLE
  d = strtod(ld, NULL);
#endif

  sp = mark;

  if(Isnan_ld(d)) {
      XPUSHs(sv_2mortal(newSVpv("@NaN@", 0)));
      XPUSHs(sv_2mortal(newSViv(exp)));
      XPUSHs(sv_2mortal(newSViv(prec)));
      XSRETURN(3);
  }

  if (d < (ARGTYPE) 0.0 || (d == (ARGTYPE) 0.0 && (1.0 / (double) d < 0.0))) {
      XPUSHs(sv_2mortal(newSVpv("-", 0)));
      returns++;
      d = -d;
  }

  /* now d >= 0 */
  /* Use 2 differents tests for Inf, to avoid potential bugs
     in implementations. */
  if (Isnan_ld (d - d) || (d > 1 && d * 0.5 == d)) {
      XPUSHs(sv_2mortal(newSVpv("@Inf@", 0)));
      XPUSHs(sv_2mortal(newSViv(exp)));
      XPUSHs(sv_2mortal(newSViv(prec)));
      returns += 3;
      XSRETURN(returns);
  }

  if (d == (ARGTYPE) 0.0) {
      XPUSHs(sv_2mortal(newSVpv("0.0", 0)));
      XPUSHs(sv_2mortal(newSViv(exp)));
      XPUSHs(sv_2mortal(newSViv(prec)));
      returns += 3;
      XSRETURN(returns);
  }

  /* now d > 0 */
  e = (ARGTYPE) 1.0;
  while (e > d) {
      e = e * (ARGTYPE) 0.5;
      exp --;
  }

  /* now d >= e */
  while (d >= e + e) {
      e = e + e;
      exp ++;
  }

  /* now e <= d < 2e */
  XPUSHs(sv_2mortal(newSVpv("0.", 0)));
  returns ++;

  while (d > (ARGTYPE) 0.0) {
      prec++;
      if(d >= e) {
        XPUSHs(sv_2mortal(newSVpv("1", 0)));
        returns ++;
        d = (ARGTYPE) ((ARGTYPE) d - (ARGTYPE) e);
      }
      else {
        XPUSHs(sv_2mortal(newSVpv("0", 0)));
        returns ++;
      }
      e *= (ARGTYPE) 0.5;
  }

  XPUSHs(sv_2mortal(newSViv(exp)));
  XPUSHs(sv_2mortal(newSViv(prec)));
  returns += 2;
  XSRETURN(returns);
}

SV * _bin2val(pTHX_  SV * precision, SV * exponent, SV * bin) {
  IV i, prec;
  prec = SvIV(precision);

  ARGTYPE d = (ARGTYPE)0.0;
  ARGTYPE exp  = (ARGTYPE)SvNV(exponent);
  for(i = 0; i < prec; i++) {
    if(SvIV(*(av_fetch((AV*)SvRV(bin), i, 0))))
#ifdef NV_IS_FLOAT128
     d += powq(2.0Q, exp);
#endif
#ifdef NV_IS_LONG_DOUBLE
     d += powl(2.0L, exp);
#endif
#ifdef NV_IS_DOUBLE
     d += pow(2.0, exp);
#endif
    exp -= (ARGTYPE)1.0;
  }

  return newSVnv(d);
}

SV * _bug_95e20(pTHX) {
#ifdef NV_IS_FLOAT128
  return newSVnv(95e20Q);
#endif
#ifdef NV_IS_LONG_DOUBLE
  return newSVnv(95e20L);
#endif
#ifdef NV_IS_DOUBLE
  return newSVnv(95e20);
#endif
}

SV * _bug_1175557635e10(pTHX) {
#ifdef NV_IS_FLOAT128
  return newSVnv(1175557635e10Q);
#endif
#ifdef NV_IS_LONG_DOUBLE
  return newSVnv(1175557635e10L);
#endif
#ifdef NV_IS_DOUBLE
  return newSVnv(1175557635e10);
#endif
}

void Cprintf(pTHX_ char * fmt, SV * nv) {
  printf(fmt, (ARGTYPE)SvNV(nv));
}

void Csprintf(pTHX_ char * fmt, SV * nv, int size) {
   dXSARGS;
   char * out;

   Newx(out, size, char);
   if(out == NULL) croak("Failed to allocate memory in Csprintf function");
#ifdef NV_IS_FLOAT128
   quadmath_snprintf(out, size, fmt, (__float128)SvNV(nv));
#else
   sprintf(out, fmt, (ARGTYPE)SvNV(nv));
#endif

   ST(0) = sv_2mortal(newSVpv(out, 0));
   Safefree(out);
   XSRETURN(1);

}

/* Provide our own looks_like_number() for use by test suite. */

int _looks_like_number(pTHX_ SV * x) {

   if(looks_like_number(x)) return 1;
   return 0;

}




MODULE = Math::NV  PACKAGE = Math::NV

PROTOTYPES: DISABLE


SV *
_itsa (a)
	SV *	a
CODE:
  RETVAL = _itsa (aTHX_ a);
OUTPUT:  RETVAL

void
nv (str)
	SV *	str
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        nv(aTHX_ str);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
nv_type ()
CODE:
  RETVAL = nv_type (aTHX);
OUTPUT:  RETVAL


unsigned long
mant_dig ()


void
_ld2binary (ld)
	SV *	ld
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        _ld2binary(aTHX_ ld);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
_ld_str2binary (ld)
	char *	ld
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        _ld_str2binary(aTHX_ ld);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
_bin2val (precision, exponent, bin)
	SV *	precision
	SV *	exponent
	SV *	bin
CODE:
  RETVAL = _bin2val (aTHX_ precision, exponent, bin);
OUTPUT:  RETVAL

SV *
_bug_95e20 ()
CODE:
  RETVAL = _bug_95e20 (aTHX);
OUTPUT:  RETVAL


SV *
_bug_1175557635e10 ()
CODE:
  RETVAL = _bug_1175557635e10 (aTHX);
OUTPUT:  RETVAL


void
Cprintf (fmt, nv)
	char *	fmt
	SV *	nv
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Cprintf(aTHX_ fmt, nv);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Csprintf (fmt, nv, size)
	char *	fmt
	SV *	nv
	int	size
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Csprintf(aTHX_ fmt, nv, size);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

int
_looks_like_number (x)
	SV *	x
CODE:
  RETVAL = _looks_like_number (aTHX_ x);
OUTPUT:  RETVAL

