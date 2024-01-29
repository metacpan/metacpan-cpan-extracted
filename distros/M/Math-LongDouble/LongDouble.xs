
#ifdef  __MINGW32__
#ifndef __USE_MINGW_ANSI_STDIO
#define __USE_MINGW_ANSI_STDIO 1
#endif
#endif

#define PERL_NO_GET_CONTEXT 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


#include "math_longdouble_include.h"

#if defined(LDBL_MANT_DIG)
#  if LDBL_MANT_DIG == 53
#    define MATH_LONGDOUBLE_DIGITS 17
#    define MATH_LONGDOUBLE_SIZE 8
#  elif LDBL_MANT_DIG == 64
#    define MATH_LONGDOUBLE_DIGITS 21
#    define MATH_LONGDOUBLE_SIZE 10
#  elif LDBL_MANT_DIG == 106
#    define MATH_LONGDOUBLE_DIGITS 33
#    define MATH_LONGDOUBLE_SIZE 16
#  elif LDBL_MANT_DIG == 113
#    define MATH_LONGDOUBLE_DIGITS 36
#    define MATH_LONGDOUBLE_SIZE 16
#  else
#    define MATH_LONGDOUBLE_DIGITS 21
#    define MATH_LONGDOUBLE_SIZE 10
#  endif

#elif defined CFG_LONGDBLKIND
#  if CFG_LONGDBLKIND == 0
#    define MATH_LONGDOUBLE_DIGITS 17
#    define MATH_LONGDOUBLE_SIZE 8
#  elif CFG_LONGDBLKIND == 1 || CFG_LONGDBLKIND == 2 || CFG_LONGDBLKIND == 9
#    define MATH_LONGDOUBLE_DIGITS 36
#    define MATH_LONGDOUBLE_SIZE 16
#  elif CFG_LONGDBLKIND == 3 || CFG_LONGDBLKIND == 4
#    define MATH_LONGDOUBLE_DIGITS 21
#    define MATH_LONGDOUBLE_SIZE 10
#  elif CFG_LONGDBLKIND >= 5 && CFG_LONGDBLKIND <= 8
#    define MATH_LONGDOUBLE_DIGITS 33
#    define MATH_LONGDOUBLE_SIZE 16
#  else
#    define MATH_LONGDOUBLE_DIGITS 21
#    define MATH_LONGDOUBLE_SIZE 10
#  endif

#elif defined(DBL_MANT_DIG)
#  if DBL_MANT_DIG == 53
#    define MATH_LONGDOUBLE_DIGITS 17
#    define MATH_LONGDOUBLE_SIZE 8
#  else
#    define MATH_LONGDOUBLE_DIGITS 21
#    define MATH_LONGDOUBLE_SIZE 10
#  endif

#else
#  define MATH_LONGDOUBLE_DIGITS 21
#  define MATH_LONGDOUBLE_SIZE 10
#endif

int _DIGITS = MATH_LONGDOUBLE_DIGITS;

#if defined(__GNUC__)
# if defined(__GNUC_PATCHLEVEL__)
#  define __GNUC_VERSION__ (__GNUC__ * 10000 \
                            + __GNUC_MINOR__ * 100 \
                            + __GNUC_PATCHLEVEL__)
# else
#  define __GNUC_VERSION__ (__GNUC__ * 10000 \
                            + __GNUC_MINOR__ * 100)
#endif
#endif

typedef long double ldbl;

void _print_bytes(const void* p, int n) {
  int i;

#ifdef WE_HAVE_BENDIAN /* Big Endian architecture */
  for (i = 0; i < n; i++) {
#else
  for (i = n - 1; i >= 0; i--) {
#endif
    printf("%02x", ((const unsigned char*)p)[i]);
  }
  printf("\n");
}

int nnum = 0;

void ld_set_prec(pTHX_ int x) {
    if(x < 1)croak("1st arg (precision) to ld_set_prec must be at least 1");
    _DIGITS = x;
}

int _is_nan(long double x) {
    if(x != x) return 1;
    return 0;
}

int  _is_inf(long double x) {
     if(x != x) return 0; /* NaN  */
     if(x == 0.0L) return 0; /* Zero */
     if(x/x != x/x) {
       if(x < 0.0L) return -1;
       else return 1;
     }
     return 0; /* Finite Real */
}

/* Resurrected - not terribly efficient but at least it seems to generally work */
int _is_zero(long double x) {
    char * buffer;

    if(x != 0.0L) return 0;

    Newx(buffer, 2, char);

    sprintf(buffer, "%.0Lf", x);

    if(!strcmp(buffer, "-0")) {
      Safefree(buffer);
      return -1;
    }

    Safefree(buffer);
    return 1;
}

long double _get_inf(int sign) {
    long double ret;
    ret = 1.0L / 0.0L;
    if(sign < 0) ret *= -1.0L;
    return ret;
}

long double _get_nan(void) {
     long double inf = _get_inf(1);
     return inf / inf;
}

SV * InfLD(pTHX_ int sign) {
     long double * ld;
     SV * obj_ref, * obj;

     Newx(ld, 1, long double);
     if(ld == NULL) croak("Failed to allocate memory in InfLD function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::LongDouble");

     *ld = _get_inf(sign);

     sv_setiv(obj, INT2PTR(IV,ld));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * NaNLD(pTHX) {
     long double * ld;
     SV * obj_ref, * obj;

     Newx(ld, 1, long double);
     if(ld == NULL) croak("Failed to allocate memory in NaNLD function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::LongDouble");

     *ld = _get_nan();

     sv_setiv(obj, INT2PTR(IV,ld));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * ZeroLD(pTHX_ int sign) {
     long double * ld;
     SV * obj_ref, * obj;

     Newx(ld, 1, long double);
     if(ld == NULL) croak("Failed to allocate memory in ZeroLD function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::LongDouble");

     *ld = 0.0L;
     if(sign < 0) *ld *= -1.0L;

     sv_setiv(obj, INT2PTR(IV,ld));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * UnityLD(pTHX_ int sign) {
     long double * ld;
     SV * obj_ref, * obj;

     Newx(ld, 1, long double);
     if(ld == NULL) croak("Failed to allocate memory in UnityLD function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::LongDouble");

     *ld = 1.0L;
     if(sign < 0) *ld *= -1.0L;

     sv_setiv(obj, INT2PTR(IV,ld));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * is_NaNLD(pTHX_ SV * b) {
     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::LongDouble"))
         return newSViv(_is_nan(*(INT2PTR(long double *, SvIVX(SvRV(b))))));
     }
     croak("Invalid argument supplied to Math::LongDouble::isNaNLD function");
}

int is_InfLD(pTHX_ SV * b) {
     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::LongDouble"))
         return _is_inf(*(INT2PTR(long double *, SvIVX(SvRV(b)))));
     }
     croak("Invalid argument supplied to Math::LongDouble::is_InfLD function");
}

int is_ZeroLD(pTHX_ SV * b) {
     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::LongDouble"))
         return _is_zero(*(INT2PTR(long double *, SvIVX(SvRV(b)))));
     }
     croak("Invalid argument supplied to Math::LongDouble::is_ZeroLD function");
}

void _nnum_inc (char * p) {
  int i = 0;
  for(;;i++) {
    if(p[i] == 0) break;
    if(p[i] != ' ' && p[i] != '\t' && p[i] != '\n' && p[i] != '\r' && p[i] != '\f') {
       nnum++;
       break;
    }
  }
}

SV * STRtoLD(pTHX_ char * str) {
     long double * ld;
     SV * obj_ref, * obj;
     char * p;

     Newx(ld, 1, long double);
     if(ld == NULL) croak("Failed to allocate memory in STRtoLD function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::LongDouble");

     *ld = strtold(str, &p);

     _nnum_inc(p);

     sv_setiv(obj, INT2PTR(IV,ld));
     SvREADONLY_on(obj);
     return obj_ref;
}

void LDtoSTR(pTHX_ SV * ld) {
     dXSARGS;
     long double t;
     char * buffer;

     if(sv_isobject(ld)) {
       const char *h = HvNAME(SvSTASH(SvRV(ld)));
       if(strEQ(h, "Math::LongDouble")) {
          EXTEND(SP, 1);
          t = *(INT2PTR(long double *, SvIVX(SvRV(ld))));

          Newx(buffer, 8 + _DIGITS, char);
          if(buffer == NULL) croak("Failed to allocate memory in LDtoSTR");
          sprintf(buffer, "%.*Le", _DIGITS - 1, t);
          ST(0) = sv_2mortal(newSVpv(buffer, 0));
          Safefree(buffer);
          XSRETURN(1);
       }
       else croak("Invalid object supplied to Math::LongDouble::LDtoSTR function");
     }
     else croak("Invalid argument supplied to Math::LongDouble::LDtoSTR function");
}

void LDtoSTRP(pTHX_ SV * ld, int decimal_prec) {
     dXSARGS;
     long double t;
     char * buffer;

     if(decimal_prec < 1)croak("2nd arg (precision) to LDtoSTRP  must be at least 1");

     if(sv_isobject(ld)) {
       const char *h = HvNAME(SvSTASH(SvRV(ld)));
       if(strEQ(h, "Math::LongDouble")) {
          EXTEND(SP, 1);
          t = *(INT2PTR(long double *, SvIVX(SvRV(ld))));

          Newx(buffer, 8 + decimal_prec, char);
          if(buffer == NULL) croak("Failed to allocate memory in LDtoSTRP");
          sprintf(buffer, "%.*Le", decimal_prec - 1, t);
          ST(0) = sv_2mortal(newSVpv(buffer, 0));
          Safefree(buffer);
          XSRETURN(1);
       }
       else croak("Invalid object supplied to Math::LongDouble::LDtoSTRP function");
     }
     else croak("Invalid argument supplied to Math::LongDouble::LDtoSTRP function");
}

SV * NVtoLD(pTHX_ SV * x) {
     long double * ld;
     SV * obj_ref, * obj;

     Newx(ld, 1, long double);
     if(ld == NULL) croak("Failed to allocate memory in NVtoLD function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::LongDouble");

     *ld = (long double)SvNV(x);

     sv_setiv(obj, INT2PTR(IV,ld));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * UVtoLD(pTHX_ SV * x) {
     long double * ld;
     SV * obj_ref, * obj;

     Newx(ld, 1, long double);
     if(ld == NULL) croak("Failed to allocate memory in UVtoLD function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::LongDouble");

     *ld = (long double)SvUV(x);

     sv_setiv(obj, INT2PTR(IV,ld));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * IVtoLD(pTHX_ SV * x) {
     long double * ld;
     SV * obj_ref, * obj;

     Newx(ld, 1, long double);
     if(ld == NULL) croak("Failed to allocate memory in IVtoLD function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::LongDouble");

     *ld = (long double)SvIV(x);

     sv_setiv(obj, INT2PTR(IV,ld));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * LDtoNV(pTHX_ SV * ld) {
/*
 Because of a bug in gcc (versions 4.9.x to 6.x.x) we avoid casting
 a long double "inf" to a __float128 (for those affected versions of gcc).
 Instead cast a double "inf" to __float128.
 See https://sourceforge.net/p/mingw-w64/bugs/479/
*/
#if defined(NO_INF_CAST_TO_NV) && defined(__GNUC__) && ((__GNUC__ > 4 && __GNUC__ < 7) || (__GNUC__ == 4 && __GNUC_MINOR__ >= 9))
     int t;
     long double temp = *(INT2PTR(long double *, SvIVX(SvRV(ld))));
     t = _is_inf(temp);
     if(t) {
       if(t < 0) return newSVnv((NV)strtod("-inf", NULL));
       return newSVnv((NV)strtod("inf", NULL));
     }

#endif
     return newSVnv((NV)(*(INT2PTR(long double *, SvIVX(SvRV(ld))))));
}

SV * _overload_add(pTHX_ SV * a, SV * b, SV * third) {

     long double * ld;
     SV * obj_ref, * obj;

     Newx(ld, 1, long double);
     if(ld == NULL) croak("Failed to allocate memory in _overload_add function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::LongDouble");

     sv_setiv(obj, INT2PTR(IV,ld));
     SvREADONLY_on(obj);

    if(SvUOK(b)) {
       *ld = *(INT2PTR(ldbl *, SvIVX(SvRV(a)))) + (ldbl)SvUVX(b);
        return obj_ref;
    }

    if(SvIOK(b)) {
       *ld = *(INT2PTR(ldbl *, SvIVX(SvRV(a)))) + (ldbl)SvIVX(b);
        return obj_ref;
    }

    if(SvNOK(b)) {
       *ld = *(INT2PTR(ldbl *, SvIVX(SvRV(a)))) + (ldbl)SvNVX(b);
        return obj_ref;
    }

    if(SvPOK(b)) {
       char * p;
       *ld = *(INT2PTR(ldbl *, SvIVX(SvRV(a)))) + strtold(SvPV_nolen(b), &p);
       _nnum_inc(p);
       return obj_ref;
    }

    if(sv_isobject(b)) {
      const char *h = HvNAME(SvSTASH(SvRV(b)));
      if(strEQ(h, "Math::LongDouble")) {
        *ld = *(INT2PTR(long double *, SvIVX(SvRV(a)))) + *(INT2PTR(long double *, SvIVX(SvRV(b))));
        return obj_ref;
      }
      croak("Invalid object supplied to Math::LongDouble::_overload_add function");
    }
    croak("Invalid argument supplied to Math::LongDouble::_overload_add function");
}

SV * _overload_mul(pTHX_ SV * a, SV * b, SV * third) {

     long double * ld;
     SV * obj_ref, * obj;

     Newx(ld, 1, long double);
     if(ld == NULL) croak("Failed to allocate memory in _overload_mul function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::LongDouble");

     sv_setiv(obj, INT2PTR(IV,ld));
     SvREADONLY_on(obj);

    if(SvUOK(b)) {
       *ld = *(INT2PTR(ldbl *, SvIVX(SvRV(a)))) * (ldbl)SvUVX(b);
        return obj_ref;
    }

    if(SvIOK(b)) {
       *ld = *(INT2PTR(ldbl *, SvIVX(SvRV(a)))) * (ldbl)SvIVX(b);
        return obj_ref;
    }

    if(SvNOK(b)) {
       *ld = *(INT2PTR(ldbl *, SvIVX(SvRV(a)))) * (ldbl)SvNVX(b);
        return obj_ref;
    }

    if(SvPOK(b)) {
       char * p;
       *ld = *(INT2PTR(ldbl *, SvIVX(SvRV(a)))) * strtold(SvPV_nolen(b), &p);
       _nnum_inc(p);
       return obj_ref;
    }

    if(sv_isobject(b)) {
      const char *h = HvNAME(SvSTASH(SvRV(b)));
      if(strEQ(h, "Math::LongDouble")) {
        *ld = *(INT2PTR(long double *, SvIVX(SvRV(a)))) * *(INT2PTR(long double *, SvIVX(SvRV(b))));
        return obj_ref;
      }
      croak("Invalid object supplied to Math::LongDouble::_overload_mul function");
    }
    croak("Invalid argument supplied to Math::LongDouble::_overload_mul function");
}

SV * _overload_sub(pTHX_ SV * a, SV * b, SV * third) {
     long double * ld;
     SV * obj_ref, * obj;

     Newx(ld, 1, long double);
     if(ld == NULL) croak("Failed to allocate memory in _overload_sub function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::LongDouble");

     sv_setiv(obj, INT2PTR(IV,ld));
     SvREADONLY_on(obj);

    if(SvUOK(b)) {
       if(SWITCH_ARGS) *ld = (ldbl)SvUVX(b) - *(INT2PTR(ldbl *, SvIVX(SvRV(a))));
       else *ld = *(INT2PTR(ldbl *, SvIVX(SvRV(a)))) - (ldbl)SvUVX(b);
       return obj_ref;
    }

    if(SvIOK(b)) {
       if(SWITCH_ARGS) *ld = (ldbl)SvIVX(b) - *(INT2PTR(ldbl *, SvIVX(SvRV(a))));
       else *ld = *(INT2PTR(ldbl *, SvIVX(SvRV(a)))) - (ldbl)SvIVX(b);
       return obj_ref;
    }

    if(SvNOK(b)) {
       if(SWITCH_ARGS) *ld = (ldbl)SvNVX(b) - *(INT2PTR(ldbl *, SvIVX(SvRV(a))));
       else *ld = *(INT2PTR(ldbl *, SvIVX(SvRV(a)))) - (ldbl)SvNVX(b);
       return obj_ref;
    }

    if(SvPOK(b)) {
       char * p;
       if(SWITCH_ARGS) *ld = strtold(SvPV_nolen(b), &p) - *(INT2PTR(ldbl *, SvIVX(SvRV(a))));
       else *ld = *(INT2PTR(ldbl *, SvIVX(SvRV(a)))) - strtold(SvPV_nolen(b), &p);
       _nnum_inc(p);
       return obj_ref;
    }

    if(sv_isobject(b)) {
      const char *h = HvNAME(SvSTASH(SvRV(b)));
      if(strEQ(h, "Math::LongDouble")) {
        *ld = *(INT2PTR(long double *, SvIVX(SvRV(a)))) - *(INT2PTR(long double *, SvIVX(SvRV(b))));
        return obj_ref;
      }
      croak("Invalid object supplied to Math::LongDouble::_overload_sub function");
    }

    /*
    else {
      if(SWITCH_ARGS) {
        *ld = *(INT2PTR(long double *, SvIVX(SvRV(a)))) * -1.0L;
        return obj_ref;
      }
    }
    */

    croak("Invalid argument supplied to Math::LongDouble::_overload_sub function");

}

SV * _overload_div(pTHX_ SV * a, SV * b, SV * third) {
     long double * ld;
     SV * obj_ref, * obj;

     Newx(ld, 1, long double);
     if(ld == NULL) croak("Failed to allocate memory in _overload_div function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::LongDouble");

     sv_setiv(obj, INT2PTR(IV,ld));
     SvREADONLY_on(obj);

    if(SvUOK(b)) {
       if(SWITCH_ARGS) *ld = (ldbl)SvUVX(b) / *(INT2PTR(ldbl *, SvIVX(SvRV(a))));
       else *ld = *(INT2PTR(ldbl *, SvIVX(SvRV(a)))) / (ldbl)SvUVX(b);
       return obj_ref;
    }

    if(SvIOK(b)) {
       if(SWITCH_ARGS) *ld = (ldbl)SvIVX(b) / *(INT2PTR(ldbl *, SvIVX(SvRV(a))));
       else *ld = *(INT2PTR(ldbl *, SvIVX(SvRV(a)))) / (ldbl)SvIVX(b);
       return obj_ref;
    }

    if(SvNOK(b)) {
       if(SWITCH_ARGS) *ld = (ldbl)SvNVX(b) / *(INT2PTR(ldbl *, SvIVX(SvRV(a))));
       else *ld = *(INT2PTR(ldbl *, SvIVX(SvRV(a)))) / (ldbl)SvNVX(b);
       return obj_ref;
    }

    if(SvPOK(b)) {
       char * p;
       if(SWITCH_ARGS) *ld = strtold(SvPV_nolen(b), &p) / *(INT2PTR(ldbl *, SvIVX(SvRV(a))));
       else *ld = *(INT2PTR(ldbl *, SvIVX(SvRV(a)))) / strtold(SvPV_nolen(b), &p);
       _nnum_inc(p);
       return obj_ref;
    }

    if(sv_isobject(b)) {
      const char *h = HvNAME(SvSTASH(SvRV(b)));
      if(strEQ(h, "Math::LongDouble")) {
        *ld = *(INT2PTR(long double *, SvIVX(SvRV(a)))) / *(INT2PTR(long double *, SvIVX(SvRV(b))));
        return obj_ref;
      }
      croak("Invalid object supplied to Math::LongDouble::_overload_div function");
    }
    croak("Invalid argument supplied to Math::LongDouble::_overload_div function");
}

SV * _overload_equiv(pTHX_ SV * a, SV * b, SV * third) {

    if(SvUOK(b)) {
       if(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))) == (ldbl)SvUVX(b)) return newSViv(1);
        return newSViv(0);
    }

    if(SvIOK(b)) {
       if(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))) == (ldbl)SvIVX(b)) return newSViv(1);
        return newSViv(0);
    }

    if(SvNOK(b)) {
       if(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))) == (ldbl)SvNVX(b)) return newSViv(1);
        return newSViv(0);
    }

    if(SvPOK(b)) {
       char *p;
       if(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))) == strtold(SvPV_nolen(b), &p)) {
         _nnum_inc(p);
         return newSViv(1);
       }
       _nnum_inc(p);
       return newSViv(0);
    }

    if(sv_isobject(b)) {
      const char *h = HvNAME(SvSTASH(SvRV(b)));
      if(strEQ(h, "Math::LongDouble")) {
        if(*(INT2PTR(long double *, SvIVX(SvRV(a)))) == *(INT2PTR(long double *, SvIVX(SvRV(b))))) return newSViv(1);
        return newSViv(0);
      }
      croak("Invalid object supplied to Math::LongDouble::_overload_equiv function");
    }
    croak("Invalid argument supplied to Math::LongDouble::_overload_equiv function");
}

SV * _overload_not_equiv(pTHX_ SV * a, SV * b, SV * third) {

    if(SvUOK(b)) {
       if(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))) != (ldbl)SvUVX(b)) return newSViv(1);
        return newSViv(0);
    }

    if(SvIOK(b)) {
       if(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))) != (ldbl)SvIVX(b)) return newSViv(1);
        return newSViv(0);
    }

    if(SvNOK(b)) {
       if(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))) != (ldbl)SvNVX(b)) return newSViv(1);
        return newSViv(0);
    }

    if(SvPOK(b)) {
       char * p;
       if(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))) != strtold(SvPV_nolen(b), &p)) {
         _nnum_inc(p);
         return newSViv(1);
       }
       _nnum_inc(p);
       return newSViv(0);
    }

    if(sv_isobject(b)) {
      const char *h = HvNAME(SvSTASH(SvRV(b)));
      if(strEQ(h, "Math::LongDouble")) {
        if(*(INT2PTR(long double *, SvIVX(SvRV(a)))) == *(INT2PTR(long double *, SvIVX(SvRV(b))))) return newSViv(0);
        return newSViv(1);
      }
      croak("Invalid object supplied to Math::LongDouble::_overload_not_equiv function");
    }
    croak("Invalid argument supplied to Math::LongDouble::_overload_not_equiv function");
}

SV * _overload_true(pTHX_ SV * a, SV * b, SV * third) {

     if(_is_nan(*(INT2PTR(long double *, SvIVX(SvRV(a)))))) return newSViv(0);
     if(*(INT2PTR(long double *, SvIVX(SvRV(a)))) != 0.0L) return newSViv(1);
     return newSViv(0);
}

SV * _overload_not(pTHX_ SV * a, SV * b, SV * third) {
     if(_is_nan(*(INT2PTR(long double *, SvIVX(SvRV(a)))))) return newSViv(1);
     if(*(INT2PTR(long double *, SvIVX(SvRV(a)))) != 0.0L) return newSViv(0);
     return newSViv(1);
}

SV * _overload_add_eq(pTHX_ SV * a, SV * b, SV * third) {

    SvREFCNT_inc(a);

    if(SvUOK(b)) {
       *(INT2PTR(ldbl *, SvIVX(SvRV(a)))) += (ldbl)SvUVX(b);
        return a;
    }

    if(SvIOK(b)) {
       *(INT2PTR(ldbl *, SvIVX(SvRV(a)))) += (ldbl)SvIVX(b);
        return a;
    }

    if(SvNOK(b)) {
       *(INT2PTR(ldbl *, SvIVX(SvRV(a)))) += (ldbl)SvNVX(b);
        return a;
    }

    if(SvPOK(b)) {
       char * p;
       *(INT2PTR(ldbl *, SvIVX(SvRV(a)))) += strtold(SvPV_nolen(b), &p);
       _nnum_inc(p);
       return a;
    }

    if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::LongDouble")) {
        *(INT2PTR(long double *, SvIVX(SvRV(a)))) += *(INT2PTR(long double *, SvIVX(SvRV(b))));
        return a;
      }
      SvREFCNT_dec(a);
      croak("Invalid object supplied to Math::LongDouble::_overload_add_eq function");
    }
    SvREFCNT_dec(a);
    croak("Invalid argument supplied to Math::LongDouble::_overload_add_eq function");
}

void broken_overload_add_eq(pTHX_ SV * a, SV * b, SV * third) {
    long double ld;
    if(third == &PL_sv_undef) printf("UNDEF in broken_overload_add\n");
    if(SvUOK(b)) {
       ld = (ldbl)SvUVX(b);
       *(INT2PTR(ldbl *, SvIVX(SvRV(a)))) += ld;
    }

    else if(SvIOK(b)) {
       ld = (ldbl)SvIVX(b);
       printf("From SvIV: %Lf\n", ld);
       *(INT2PTR(ldbl *, SvIVX(SvRV(a)))) += ld;
    }

    else if(SvNOK(b)) {
       ld = (ldbl)SvNVX(b);
       printf("From SvNV: %Lf\n", ld);
       *(INT2PTR(ldbl *, SvIVX(SvRV(a)))) += ld;
    }

    else if(SvPOK(b)) {
       char * p;
       *(INT2PTR(ldbl *, SvIVX(SvRV(a)))) += strtold(SvPV_nolen(b), &p);
       _nnum_inc(p);
    }

    else if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::LongDouble")) {
         ld = (ldbl)*(INT2PTR(long double *, SvIVX(SvRV(b))));
         *(INT2PTR(long double *, SvIVX(SvRV(a)))) += ld;
      }
    }
    else {
      croak("Invalid argument supplied to Math::LongDouble::broken_overload_add_eq function");
    }
}

SV * _overload_mul_eq(pTHX_ SV * a, SV * b, SV * third) {

    SvREFCNT_inc(a);

    if(SvUOK(b)) {
       *(INT2PTR(ldbl *, SvIVX(SvRV(a)))) *= (ldbl)SvUVX(b);
        return a;
    }

    if(SvIOK(b)) {
       *(INT2PTR(ldbl *, SvIVX(SvRV(a)))) *= (ldbl)SvIVX(b);
        return a;
    }

    if(SvNOK(b)) {
       *(INT2PTR(ldbl *, SvIVX(SvRV(a)))) *= (ldbl)SvNVX(b);
        return a;
    }

    if(SvPOK(b)) {
       char * p;
       *(INT2PTR(ldbl *, SvIVX(SvRV(a)))) *= strtold(SvPV_nolen(b), &p);
       _nnum_inc(p);
       return a;
    }

    if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::LongDouble")) {
        *(INT2PTR(long double *, SvIVX(SvRV(a)))) *= *(INT2PTR(long double *, SvIVX(SvRV(b))));
        return a;
      }
      SvREFCNT_dec(a);
      croak("Invalid object supplied to Math::LongDouble::_overload_mul_eq function");
    }
    SvREFCNT_dec(a);
    croak("Invalid argument supplied to Math::LongDouble::_overload_mul_eq function");
}

SV * _overload_sub_eq(pTHX_ SV * a, SV * b, SV * third) {

    SvREFCNT_inc(a);

    if(SvUOK(b)) {
       *(INT2PTR(ldbl *, SvIVX(SvRV(a)))) -= (ldbl)SvUVX(b);
        return a;
    }

    if(SvIOK(b)) {
       *(INT2PTR(ldbl *, SvIVX(SvRV(a)))) -= (ldbl)SvIVX(b);
        return a;
    }

    if(SvNOK(b)) {
       *(INT2PTR(ldbl *, SvIVX(SvRV(a)))) -= (ldbl)SvNVX(b);
        return a;
    }

    if(SvPOK(b)) {
       char * p;
       *(INT2PTR(ldbl *, SvIVX(SvRV(a)))) -= strtold(SvPV_nolen(b), &p);
       _nnum_inc(p);
       return a;
    }

    if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::LongDouble")) {
        *(INT2PTR(long double *, SvIVX(SvRV(a)))) -= *(INT2PTR(long double *, SvIVX(SvRV(b))));
        return a;
      }
      SvREFCNT_dec(a);
      croak("Invalid object supplied to Math::LongDouble::_overload_sub_eq function");
    }
    SvREFCNT_dec(a);
    croak("Invalid argument supplied to Math::LongDouble::_overload_sub_eq function");
}

SV * _overload_div_eq(pTHX_ SV * a, SV * b, SV * third) {

    SvREFCNT_inc(a);

    if(SvUOK(b)) {
       *(INT2PTR(ldbl *, SvIVX(SvRV(a)))) /= (ldbl)SvUVX(b);
        return a;
    }

    if(SvIOK(b)) {
       *(INT2PTR(ldbl *, SvIVX(SvRV(a)))) /= (ldbl)SvIVX(b);
        return a;
    }

    if(SvNOK(b)) {
       *(INT2PTR(ldbl *, SvIVX(SvRV(a)))) /= (ldbl)SvNVX(b);
        return a;
    }

    if(SvPOK(b)) {
       char * p;
       *(INT2PTR(ldbl *, SvIVX(SvRV(a)))) /= strtold(SvPV_nolen(b), &p);
       _nnum_inc(p);
       return a;
    }

    if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::LongDouble")) {
         *(INT2PTR(long double *, SvIVX(SvRV(a)))) /= *(INT2PTR(long double *, SvIVX(SvRV(b))));
         return a;
       }
       SvREFCNT_dec(a);
       croak("Invalid object supplied to Math::LongDouble::_overload_div_eq function");
    }
    SvREFCNT_dec(a);
    croak("Invalid argument supplied to Math::LongDouble::_overload_div_eq function");
}

SV * _overload_lt(pTHX_ SV * a, SV * b, SV * third) {
    char *p;
    int reversal = 0;
    if(SWITCH_ARGS) reversal = 1;

    if(SvUOK(b)) {
      if(reversal) {
        if(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))) > (ldbl)SvUVX(b)) return newSViv(1);
        return newSViv(0);
      }
      if(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))) < (ldbl)SvUVX(b)) return newSViv(1);
      return newSViv(0);
    }

    if(SvIOK(b)) {
      if(reversal) {
        if(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))) > (ldbl)SvIVX(b)) return newSViv(1);
        return newSViv(0);
      }
      if(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))) < (ldbl)SvIVX(b)) return newSViv(1);
      return newSViv(0);
    }

    if(SvNOK(b)) {
      if(reversal) {
        if(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))) > (ldbl)SvNVX(b)) return newSViv(1);
        return newSViv(0);
      }
      if(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))) < (ldbl)SvNVX(b)) return newSViv(1);
      return newSViv(0);
    }

    if(SvPOK(b)) {
      if(reversal) {
        if(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))) > strtold(SvPV_nolen(b), &p)) {
          _nnum_inc(p);
          return newSViv(1);
        }
        _nnum_inc(p);
        return newSViv(0);
      }

      if(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))) < strtold(SvPV_nolen(b), &p)) {
        _nnum_inc(p);
        return newSViv(1);
      }
      _nnum_inc(p);
      return newSViv(0);
    }

    if(sv_isobject(b)) {
      const char *h = HvNAME(SvSTASH(SvRV(b)));
      if(strEQ(h, "Math::LongDouble")) {
        if(*(INT2PTR(long double *, SvIVX(SvRV(a)))) < *(INT2PTR(long double *, SvIVX(SvRV(b))))) return newSViv(1);
        return newSViv(0);
      }
      croak("Invalid object supplied to Math::LongDouble::_overload_lt function");
    }
    croak("Invalid argument supplied to Math::LongDouble::_overload_lt function");
}

SV * _overload_gt(pTHX_ SV * a, SV * b, SV * third) {
    char *p;
    int reversal = 0;
    if(SWITCH_ARGS) reversal = 1;

    if(SvUOK(b)) {
      if(reversal) {
        if(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))) < (ldbl)SvUVX(b)) return newSViv(1);
        return newSViv(0);
      }
      if(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))) > (ldbl)SvUVX(b)) return newSViv(1);
      return newSViv(0);
    }

    if(SvIOK(b)) {
      if(reversal) {
        if(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))) < (ldbl)SvIVX(b)) return newSViv(1);
        return newSViv(0);
      }
      if(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))) > (ldbl)SvIVX(b)) return newSViv(1);
      return newSViv(0);
    }

    if(SvNOK(b)) {
      if(reversal) {
        if(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))) < (ldbl)SvNVX(b)) return newSViv(1);
        return newSViv(0);
      }
      if(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))) > (ldbl)SvNVX(b)) return newSViv(1);
      return newSViv(0);
    }

    if(SvPOK(b)) {
      if(reversal) {
        if(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))) < strtold(SvPV_nolen(b), &p)) {
          _nnum_inc(p);
          return newSViv(1);
        }
        _nnum_inc(p);
        return newSViv(0);
      }
      if(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))) > strtold(SvPV_nolen(b), &p)) {
        _nnum_inc(p);
        return newSViv(1);
      }
      _nnum_inc(p);
      return newSViv(0);
    }

    if(sv_isobject(b)) {
      const char *h = HvNAME(SvSTASH(SvRV(b)));
      if(strEQ(h, "Math::LongDouble")) {
        if(*(INT2PTR(long double *, SvIVX(SvRV(a)))) > *(INT2PTR(long double *, SvIVX(SvRV(b))))) return newSViv(1);
        return newSViv(0);
      }
      croak("Invalid object supplied to Math::LongDouble::_overload_gt function");
    }
    croak("Invalid argument supplied to Math::LongDouble::_overload_gt function");
}

SV * _overload_lte(pTHX_ SV * a, SV * b, SV * third) {
    char *p;
    int reversal = 0;
    if(SWITCH_ARGS) reversal = 1;

    if(SvUOK(b)) {
      if(reversal) {
        if(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))) >= (ldbl)SvUVX(b)) return newSViv(1);
        return newSViv(0);
      }
      if(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))) <= (ldbl)SvUVX(b)) return newSViv(1);
      return newSViv(0);
    }

    if(SvIOK(b)) {
      if(reversal) {
        if(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))) >= (ldbl)SvIVX(b)) return newSViv(1);
        return newSViv(0);
      }
      if(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))) <= (ldbl)SvIVX(b)) return newSViv(1);
      return newSViv(0);
    }

    if(SvNOK(b)) {
      if(reversal) {
        if(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))) >= (ldbl)SvNVX(b)) return newSViv(1);
        return newSViv(0);
      }
      if(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))) <= (ldbl)SvNVX(b)) return newSViv(1);
      return newSViv(0);
    }

    if(SvPOK(b)) {
      if(reversal) {
        if(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))) >= strtold(SvPV_nolen(b), &p)) {
          _nnum_inc(p);
          return newSViv(1);
        }
        _nnum_inc(p);
        return newSViv(0);
      }
      if(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))) <= strtold(SvPV_nolen(b), &p)) {
        _nnum_inc(p);
        return newSViv(1);
      }
      _nnum_inc(p);
      return newSViv(0);
    }

    if(sv_isobject(b)) {
      const char *h = HvNAME(SvSTASH(SvRV(b)));
      if(strEQ(h, "Math::LongDouble")) {
        if(*(INT2PTR(long double *, SvIVX(SvRV(a)))) <= *(INT2PTR(long double *, SvIVX(SvRV(b))))) return newSViv(1);
        return newSViv(0);
      }
      croak("Invalid object supplied to Math::LongDouble::_overload_lte function");
    }
    croak("Invalid argument supplied to Math::LongDouble::_overload_lte function");
}

SV * _overload_gte(pTHX_ SV * a, SV * b, SV * third) {
    char *p;
    int reversal = 0;
    if(SWITCH_ARGS) reversal = 1;

    if(SvUOK(b)) {
      if(reversal) {
        if(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))) <= (ldbl)SvUVX(b)) return newSViv(1);
        return newSViv(0);
      }
      if(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))) >= (ldbl)SvUVX(b)) return newSViv(1);
      return newSViv(0);
    }

    if(SvIOK(b)) {
      if(reversal) {
        if(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))) <= (ldbl)SvIVX(b)) return newSViv(1);
        return newSViv(0);
      }
      if(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))) >= (ldbl)SvIVX(b)) return newSViv(1);
      return newSViv(0);
    }

    if(SvNOK(b)) {
      if(reversal) {
        if(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))) <= (ldbl)SvNVX(b)) return newSViv(1);
        return newSViv(0);
      }
      if(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))) >= (ldbl)SvNVX(b)) return newSViv(1);
      return newSViv(0);
    }

    if(SvPOK(b)) {
      if(reversal) {
        if(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))) <= strtold(SvPV_nolen(b), &p)) {
          _nnum_inc(p);
          return newSViv(1);
        }
        _nnum_inc(p);
        return newSViv(0);
      }
      if(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))) >= strtold(SvPV_nolen(b), &p)) {
        _nnum_inc(p);
        return newSViv(1);
      }
      _nnum_inc(p);
      return newSViv(0);
    }

    if(sv_isobject(b)) {
      const char *h = HvNAME(SvSTASH(SvRV(b)));
      if(strEQ(h, "Math::LongDouble")) {
        if(*(INT2PTR(long double *, SvIVX(SvRV(a)))) >= *(INT2PTR(long double *, SvIVX(SvRV(b))))) return newSViv(1);
        return newSViv(0);
      }
      croak("Invalid object supplied to Math::LongDouble::_overload_gte function");
    }
    croak("Invalid argument supplied to Math::LongDouble::_overload_gte function");
}

SV * _overload_spaceship(pTHX_ SV * a, SV * b, SV * third) {
    char *p;
    int reversal = 1;
    if(SWITCH_ARGS) reversal = -1;

    if(SvUOK(b)) {
       if(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))) == (ldbl)SvUVX(b)) return newSViv( 0);
       if(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))) <  (ldbl)SvUVX(b)) return newSViv(-1 * reversal);
       if(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))) >  (ldbl)SvUVX(b)) return newSViv( 1 * reversal);
       return &PL_sv_undef; /* it's a nan */
    }

    if(SvIOK(b)) {
       if(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))) == (ldbl)SvIVX(b)) return newSViv( 0);
       if(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))) <  (ldbl)SvIVX(b)) return newSViv(-1 * reversal);
       if(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))) >  (ldbl)SvIVX(b)) return newSViv( 1 * reversal);
       return &PL_sv_undef; /* it's a nan */
    }

    if(SvNOK(b)) {
       if(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))) == (ldbl)SvNVX(b)) return newSViv( 0);
       if(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))) <  (ldbl)SvNVX(b)) return newSViv(-1 * reversal);
       if(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))) >  (ldbl)SvNVX(b)) return newSViv( 1 * reversal);
       return &PL_sv_undef; /* it's a nan */
    }

    if(SvPOK(b)) {

       if(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))) == strtold(SvPV_nolen(b), &p)) {
         _nnum_inc(p);
         return newSViv( 0);
       }
       if(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))) <  strtold(SvPV_nolen(b), &p)) {
         _nnum_inc(p);
         return newSViv(-1 * reversal);
       }
       if(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))) >  strtold(SvPV_nolen(b), &p)) {
         _nnum_inc(p);
         return newSViv( 1 * reversal);
       }
       return &PL_sv_undef; /* it's a nan */
    }

    if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::LongDouble")) {
        if(*(INT2PTR(long double *, SvIVX(SvRV(a)))) < *(INT2PTR(long double *, SvIVX(SvRV(b))))) return newSViv(-1);
        if(*(INT2PTR(long double *, SvIVX(SvRV(a)))) > *(INT2PTR(long double *, SvIVX(SvRV(b))))) return newSViv(1);
        if(*(INT2PTR(long double *, SvIVX(SvRV(a)))) == *(INT2PTR(long double *, SvIVX(SvRV(b))))) return newSViv(0);
        return &PL_sv_undef; /* it's a nan */
      }
      croak("Invalid object supplied to Math::LongDouble::_overload_spaceship function");
    }
    croak("Invalid argument supplied to Math::LongDouble::_overload_spaceship function");
}

SV * _overload_copy(pTHX_ SV * a, SV * b, SV * third) {

     long double * ld;
     SV * obj_ref, * obj;

     Newx(ld, 1, long double);
     if(ld == NULL) croak("Failed to allocate memory in _overload_copy function");

     *ld = *(INT2PTR(long double *, SvIVX(SvRV(a))));

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::LongDouble");
     sv_setiv(obj, INT2PTR(IV,ld));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * LDtoLD(pTHX_ SV * a) {
     long double * ld;
     SV * obj_ref, * obj;

     if(sv_isobject(a)) {
       const char *h = HvNAME(SvSTASH(SvRV(a)));
       if(strEQ(h, "Math::LongDouble")) {

         Newx(ld, 1, long double);
         if(ld == NULL) croak("Failed to allocate memory in LDtoLD function");

         *ld = *(INT2PTR(long double *, SvIVX(SvRV(a))));

         obj_ref = newSV(0);
         obj = newSVrv(obj_ref, "Math::LongDouble");
         sv_setiv(obj, INT2PTR(IV,ld));
         SvREADONLY_on(obj);
         return obj_ref;
       }
       croak("Invalid object supplied to Math::LongDouble::LDtoLD function");
     }
     croak("Invalid argument supplied to Math::LongDouble::LDtoLD function");
}

SV * _itsa(pTHX_ SV * a) {
     if(SvUOK(a)) return newSVuv(1);
     if(SvIOK(a)) return newSVuv(2);
     if(SvNOK(a)) return newSVuv(3);
     if(SvPOK(a)) return newSVuv(4);
     if(sv_isobject(a)) {
       const char *h = HvNAME(SvSTASH(SvRV(a)));
       if(strEQ(h, "Math::LongDouble")) return newSVuv(96);
     }
     return newSVuv(0);
}

void DESTROY(pTHX_ SV *  rop) {
     Safefree(INT2PTR(long double *, SvIVX(SvRV(rop))));
}

SV * _overload_abs(pTHX_ SV * a, SV * b, SV * third) {

     long double * ld;
     SV * obj_ref, * obj;

     Newx(ld, 1, long double);
     if(ld == NULL) croak("Failed to allocate memory in _overload_abs function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::LongDouble");

     sv_setiv(obj, INT2PTR(IV,ld));
     SvREADONLY_on(obj);

     *ld = *(INT2PTR(long double *, SvIVX(SvRV(a))));
     /*
     There exists at least one compiler/libc where -0.0 * -1.0 is still -0.0
     So we can't do:
     if(_is_zero(*ld) < 0 || *ld < 0 ) *ld *= -1.0L;
     Instead we do:
     */
     if(*ld <= 0) *ld = *ld == 0 ? 0.0L
                                 : *ld * -1.0L;
     return obj_ref;
}

SV * cmp_NV(pTHX_ SV * ld_obj, SV * sv) {
     long double ld;
     NV nv;

     if(sv_isobject(ld_obj)) {
       const char *h = HvNAME(SvSTASH(SvRV(ld_obj)));
       if(strEQ(h, "Math::LongDouble")) {
         ld = *(INT2PTR(long double *, SvIVX(SvRV(ld_obj))));
         nv = SvNV(sv);
         if((ld != ld) || (nv != nv)) return &PL_sv_undef;
#if ACTUAL_NVSIZE <= MATH_LONGDOUBLE_SIZE
         if( ld < (long double)nv ) return newSViv(-1);
         if( ld > (long double)nv ) return newSViv(1);
#else
         if( (NV)ld < nv ) return newSViv(-1);
         if( (NV)ld > nv ) return newSViv(1);
#endif
         return newSViv(0);
       }
       croak("Invalid object supplied to Math::LongDouble::cmp_NV function");
     }
     croak("Invalid argument supplied to Math::LongDouble::cmp_NV function");
}

int _double_size(void) {
    return sizeof(double);
}

int _long_double_size(void) {
    return sizeof(long double);
}

SV * _overload_int(pTHX_ SV * a, SV * b, SV * third) {

     long double * ld;
     SV * obj_ref, * obj;

     Newx(ld, 1, long double);
     if(ld == NULL) croak("Failed to allocate memory in _overload_int function");

     *ld = *(INT2PTR(long double *, SvIVX(SvRV(a))));

     if(*ld < 0.0L) *ld = ceill(*ld);
     else *ld = floorl(*ld);

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::LongDouble");
     sv_setiv(obj, INT2PTR(IV,ld));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * _overload_sqrt(pTHX_ SV * a, SV * b, SV * third) {

     long double * ld;
     SV * obj_ref, * obj;

     Newx(ld, 1, long double);
     if(ld == NULL) croak("Failed to allocate memory in _overload_sqrt function");

     *ld = sqrtl(*(INT2PTR(long double *, SvIVX(SvRV(a)))));

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::LongDouble");
     sv_setiv(obj, INT2PTR(IV,ld));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * _overload_log(pTHX_ SV * a, SV * b, SV * third) {

     long double * ld;
     SV * obj_ref, * obj;

     Newx(ld, 1, long double);
     if(ld == NULL) croak("Failed to allocate memory in _overload_log function");

     *ld = logl(*(INT2PTR(long double *, SvIVX(SvRV(a)))));


     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::LongDouble");
     sv_setiv(obj, INT2PTR(IV,ld));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * _overload_exp(pTHX_ SV * a, SV * b, SV * third) {

     long double * ld;
     SV * obj_ref, * obj;

     Newx(ld, 1, long double);
     if(ld == NULL) croak("Failed to allocate memory in _overload_exp function");

     *ld = expl(*(INT2PTR(long double *, SvIVX(SvRV(a)))));


     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::LongDouble");
     sv_setiv(obj, INT2PTR(IV,ld));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * _overload_sin(pTHX_ SV * a, SV * b, SV * third) {

     long double * ld;
     SV * obj_ref, * obj;

     Newx(ld, 1, long double);
     if(ld == NULL) croak("Failed to allocate memory in _overload_sin function");

     *ld = sinl(*(INT2PTR(long double *, SvIVX(SvRV(a)))));


     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::LongDouble");
     sv_setiv(obj, INT2PTR(IV,ld));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * _overload_cos(pTHX_ SV * a, SV * b, SV * third) {

     long double * ld;
     SV * obj_ref, * obj;

     Newx(ld, 1, long double);
     if(ld == NULL) croak("Failed to allocate memory in _overload_cos function");

     *ld = cosl(*(INT2PTR(long double *, SvIVX(SvRV(a)))));


     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::LongDouble");
     sv_setiv(obj, INT2PTR(IV,ld));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * _overload_atan2(pTHX_ SV * a, SV * b, SV * third) {

     long double * ld;
     SV * obj_ref, * obj;

     Newx(ld, 1, long double);
     if(ld == NULL) croak("Failed to allocate memory in _overload_atan2 function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::LongDouble");
     sv_setiv(obj, INT2PTR(IV,ld));
     SvREADONLY_on(obj);

     if(SvUOK(b)) {
       if(SWITCH_ARGS)
            *ld = atan2l((ldbl)SvUVX(b), *(INT2PTR(ldbl *, SvIVX(SvRV(a)))));
       else *ld = atan2l(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))), (ldbl)SvUVX(b));
       return obj_ref;
     }

     if(SvIOK(b)) {
       if(SWITCH_ARGS)
            *ld = atan2l((ldbl)SvIVX(b), *(INT2PTR(ldbl *, SvIVX(SvRV(a)))));
       else *ld = atan2l(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))), (ldbl)SvIVX(b));
       return obj_ref;
     }

     if(SvNOK(b)) {
       if(SWITCH_ARGS)
            *ld = atan2l((ldbl)SvNVX(b), *(INT2PTR(ldbl *, SvIVX(SvRV(a)))));
       else *ld = atan2l(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))), (ldbl)SvNVX(b));
       return obj_ref;
     }

     if(SvPOK(b)) {
       char * p;
       if(SWITCH_ARGS)
            *ld = atan2l(strtold(SvPV_nolen(b), &p), *(INT2PTR(ldbl *, SvIVX(SvRV(a)))));
       else *ld = atan2l(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))), strtold(SvPV_nolen(b), &p));
       _nnum_inc(p);
       return obj_ref;
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::LongDouble")) {
         *ld = atan2l(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))), *(INT2PTR(ldbl *, SvIVX(SvRV(b)))));
         return obj_ref;
       }
       croak("Invalid object supplied to Math::LongDouble::_overload_atan2 function");
     }
     croak("Invalid argument supplied to Math::LongDouble::_overload_atan2 function");
}

void _overload_inc(pTHX_ SV * a, SV * b, SV * third) {
     *(INT2PTR(long double *, SvIVX(SvRV(a)))) += 1.0L;
}

void _overload_dec(pTHX_ SV * a, SV * b, SV * third) {
     *(INT2PTR(long double *, SvIVX(SvRV(a)))) -= 1.0L;
}

SV * _overload_pow(pTHX_ SV * a, SV * b, SV * third) {

     long double * ld;
     SV * obj_ref, * obj;

     Newx(ld, 1, long double);
     if(ld == NULL) croak("Failed to allocate memory in _overload_pow function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::LongDouble");
     sv_setiv(obj, INT2PTR(IV,ld));
     SvREADONLY_on(obj);

     if(SvUOK(b)) {
       if(SWITCH_ARGS)
            *ld = powl((ldbl)SvUVX(b), *(INT2PTR(ldbl *, SvIVX(SvRV(a)))));
       else *ld = powl(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))), (ldbl)SvUVX(b));
       return obj_ref;
     }

     if(SvIOK(b)) {
       if(SWITCH_ARGS)
            *ld = powl((ldbl)SvIVX(b), *(INT2PTR(ldbl *, SvIVX(SvRV(a)))));
       else {
#ifdef NAN_POW_BUG
         if(_is_nan(*(INT2PTR(ldbl *, SvIVX(SvRV(a))))) && SvIVX(b) == 0) *ld = 1.0L;
         else *ld = powl(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))), (ldbl)SvIVX(b));
#else
         *ld = powl(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))), (ldbl)SvIVX(b));
#endif
       }
       return obj_ref;
     }

     if(SvNOK(b)) {
#ifdef NAN_POW_BUG
       if(SWITCH_ARGS) {
         if(_is_nan(SvNVX(b)) && *(INT2PTR(ldbl *, SvIVX(SvRV(a)))) == 0) *ld = 1.0L;
         else *ld = powl((ldbl)SvNVX(b), *(INT2PTR(ldbl *, SvIVX(SvRV(a)))));
       }
       else {
         if(_is_nan(*(INT2PTR(ldbl *, SvIVX(SvRV(a))))) && SvNVX(b) == 0) *ld = 1.0L;
         else *ld = powl(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))), (ldbl)SvNVX(b));
       }
#else
       if(SWITCH_ARGS)
            *ld = powl((ldbl)SvNVX(b), *(INT2PTR(ldbl *, SvIVX(SvRV(a)))));
       else *ld = powl(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))), (ldbl)SvNVX(b));
#endif
       return obj_ref;
     }

     if(SvPOK(b)) {
       char * p;
#ifdef NAN_POW_BUG
       if(SWITCH_ARGS) {
         if(_is_nan(strtold(SvPV_nolen(b), &p)) && *(INT2PTR(ldbl *, SvIVX(SvRV(a)))) == 0.0L) *ld = 1.0L;
         else *ld = powl(strtold(SvPV_nolen(b), &p), *(INT2PTR(ldbl *, SvIVX(SvRV(a)))));
       }
       else {
         if(_is_nan(*(INT2PTR(ldbl *, SvIVX(SvRV(a))))) && strtold(SvPV_nolen(b), &p) == 0.0L) *ld = 1.0L;
         else *ld = powl(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))), strtold(SvPV_nolen(b), &p));
       }
#else
       if(SWITCH_ARGS)
            *ld = powl(strtold(SvPV_nolen(b), &p), *(INT2PTR(ldbl *, SvIVX(SvRV(a)))));
       else *ld = powl(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))), strtold(SvPV_nolen(b), &p));
#endif
       _nnum_inc(p);
       return obj_ref;
     }

    if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::LongDouble")) {
#ifdef NAN_POW_BUG
        if(_is_nan(*(INT2PTR(long double *, SvIVX(SvRV(a)))))
                && *(INT2PTR(long double *, SvIVX(SvRV(b)))) == 0.0L ) *ld = 1.0L;
        else *ld = powl(*(INT2PTR(long double *, SvIVX(SvRV(a)))), *(INT2PTR(long double *, SvIVX(SvRV(b)))));
#else
        *ld = powl(*(INT2PTR(long double *, SvIVX(SvRV(a)))), *(INT2PTR(long double *, SvIVX(SvRV(b)))));
#endif
        return obj_ref;
      }
      croak("Invalid object supplied to Math::LongDouble::_overload_pow function");
    }
    croak("Invalid argument supplied to Math::LongDouble::_overload_pow function");
}

SV * _overload_pow_eq(pTHX_ SV * a, SV * b, SV * third) {

    SvREFCNT_inc(a);

    if(SvUOK(b)) {
       *(INT2PTR(ldbl *, SvIVX(SvRV(a)))) = powl(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))),
                                                    (ldbl)SvUVX(b));

        return a;
    }

    if(SvIOK(b)) {
#ifdef NAN_POW_BUG
       *(INT2PTR(ldbl *, SvIVX(SvRV(a)))) = _is_nan(*(INT2PTR(ldbl *, SvIVX(SvRV(a))))) && SvIVX(b) == 0
                                         ? 1.0L
                                         : powl(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))),
                                                    (ldbl)SvIVX(b));
#else
       *(INT2PTR(ldbl *, SvIVX(SvRV(a)))) = powl(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))),
                                                    (ldbl)SvIVX(b));
#endif
        return a;
    }

    if(SvNOK(b)) {
#ifdef NAN_POW_BUG
       *(INT2PTR(ldbl *, SvIVX(SvRV(a)))) = (_is_nan(*(INT2PTR(ldbl *, SvIVX(SvRV(a))))) && SvNVX(b) == 0) ||
                                           (_is_nan(SvNVX(b)) && *(INT2PTR(ldbl *, SvIVX(SvRV(a)))) == 0.0L)
                                         ? 1.0L
                                         : powl(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))),
                                                    (ldbl)SvNVX(b));
#else
       *(INT2PTR(ldbl *, SvIVX(SvRV(a)))) = powl(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))),
                                                    (ldbl)SvNVX(b));
#endif
        return a;
    }

    if(SvPOK(b)) {
       char * p;
#ifdef NAN_POW_BUG
       *(INT2PTR(ldbl *, SvIVX(SvRV(a)))) = _is_nan(*(INT2PTR(ldbl *, SvIVX(SvRV(a))))) &&
                                           strtold(SvPV_nolen(b), &p) == 0.0L
                                         ? 1.0L
                                         : powl(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))),
                                                    strtold(SvPV_nolen(b), &p));
#else
       *(INT2PTR(ldbl *, SvIVX(SvRV(a)))) = powl(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))),
                                                    strtold(SvPV_nolen(b), &p));
#endif
       _nnum_inc(p);
       return a;
    }

    if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::LongDouble")) {
#ifdef NAN_POW_BUG
       *(INT2PTR(ldbl *, SvIVX(SvRV(a)))) = _is_nan(*(INT2PTR(ldbl *, SvIVX(SvRV(a))))) &&
                                                   *(INT2PTR(ldbl *, SvIVX(SvRV(b)))) == 0.0L
                                         ? 1.0L
                                         : powl(*(INT2PTR(ldbl *, SvIVX(SvRV(a)))),
                                                    (ldbl)SvNV(b));
#else
        *(INT2PTR(long double *, SvIVX(SvRV(a)))) = powl(*(INT2PTR(long double *, SvIVX(SvRV(a)))),
                                                        *(INT2PTR(long double *, SvIVX(SvRV(b)))));
#endif
        return a;
      }
      SvREFCNT_dec(a);
      croak("Invalid object supplied to Math::LongDouble::_overload_pow_eq function");
    }
    SvREFCNT_dec(a);
    croak("Invalid argument supplied to Math::LongDouble::_overload_pow_eq function");
}

SV * _wrap_count(pTHX) {
     return newSVuv(PL_sv_count);
}

SV * ld_get_prec(pTHX) {
     return newSVuv(_DIGITS);
}

SV * _LDBL_DIG(pTHX) {
#ifdef LDBL_DIG
     return newSViv(LDBL_DIG);
#else
     croak("LDBL_DIG not implemented");
#endif
}

SV * _DBL_DIG(pTHX) {
#ifdef DBL_DIG
     return newSViv(DBL_DIG);
#else
     croak("DBL_DIG not implemented");
#endif
}

SV * _LDBL_MANT_DIG(pTHX) {
#ifdef LDBL_MANT_DIG
     return newSViv(LDBL_MANT_DIG);
#else
     croak("LDBL_MANT_DIG not implemented");
#endif
}

SV * _DBL_MANT_DIG(pTHX) {
#ifdef DBL_MANT_DIG
     return newSViv(DBL_MANT_DIG);
#else
     croak("DBL_MANT_DIG not implemented");
#endif
}

SV * _get_xs_version(pTHX) {
     return newSVpv(XS_VERSION, 0);
}

SV * _ld_bytes(pTHX_ SV * arg) {

  long double ld;
  int i;
  SV * ret = NEWSV(0, MATH_LONGDOUBLE_SIZE);

  if(sv_isobject(arg)) {
    const char *h = HvNAME(SvSTASH(SvRV(arg)));
    if(!strEQ(h, "Math::LongDouble")) croak("Argument provided to ld_bytes is not a Math::LongDouble object");
  }
  else croak("Argument provided to ld_bytes is not an object. (It needs to be a Math::LongDouble object.)");

  ld = *(INT2PTR(ldbl *, SvIVX(SvRV(arg))));

  sv_setpvn(ret, (char *) &ld, MATH_LONGDOUBLE_SIZE);
  return ret;
}

void acos_LD(ldbl * rop, ldbl * op) {
  *rop = acosl(*op);
}

void acosh_LD(ldbl * rop, ldbl * op) {
  *rop = acoshl(*op);
}

void asin_LD(ldbl * rop, ldbl * op) {
  *rop = asinl(*op);
}

void asinh_LD(ldbl * rop, ldbl * op) {
  *rop = asinhl(*op);
}

void atan_LD(ldbl * rop, ldbl * op) {
  *rop = atanl(*op);
}

void atanh_LD(ldbl * rop, ldbl * op) {
  *rop = atanhl(*op);
}

void atan2_LD(ldbl * rop, ldbl * op1, ldbl * op2) {
  *rop = atan2l(*op1, *op2);
}

void cbrt_LD(ldbl * rop, ldbl * op) {
  *rop = cbrtl(*op);
}

void ceil_LD(ldbl * rop, ldbl * op) {
  *rop = ceill(*op);
}

void copysign_LD(ldbl * rop, ldbl * op1, ldbl * op2) {
  *rop = copysignl(*op1, *op2);
}

void cosh_LD(ldbl * rop, ldbl * op) {
  *rop = coshl(*op);
}

void cos_LD(ldbl * rop, ldbl * op) {
  *rop = cosl(*op);
}

void erf_LD(ldbl * rop, ldbl * op) {
  *rop = erfl(*op);
}

void erfc_LD(ldbl * rop, ldbl * op) {
  *rop = erfcl(*op);
}

void exp_LD(ldbl * rop, ldbl * op) {
  *rop = expl(*op);
}

void expm1_LD(ldbl * rop, ldbl * op) {
  *rop = expm1l(*op);
}

void fabs_LD(ldbl * rop, ldbl * op) {
  *rop = fabsl(*op);
}

void fdim_LD(ldbl * rop, ldbl * op1, ldbl * op2) {
  *rop = fdiml(*op1, *op2);
}

int finite_LD(ldbl * op) {
#ifdef WIN32
  return _finite(*op);
#else
  return finite(*op);
#endif
}

void floor_LD(ldbl * rop, ldbl * op) {
  *rop = floorl(*op);
}

void fma_LD(ldbl * rop, ldbl * op1, ldbl * op2, ldbl * op3) {
  *rop = fmal(*op1, *op2, *op3);
}

void fmax_LD(ldbl * rop, ldbl * op1, ldbl * op2) {
  *rop = fmaxl(*op1, *op2);
}

void fmin_LD(ldbl * rop, ldbl * op1, ldbl * op2) {
  *rop = fminl(*op1, *op2);
}

void fmod_LD(ldbl * rop, ldbl * op1, ldbl * op2) {
  *rop = fmodl(*op1, *op2);
}

void hypot_LD(ldbl * rop, ldbl * op1, ldbl * op2) {
  *rop = hypotl(*op1, *op2);
}

void frexp_LD(pTHX_ ldbl * frac, SV * exp, ldbl * op) {
  int e;
  *frac = frexpl(*op, &e);
  sv_setsv(exp, newSViv(e));
}

void ldexp_LD(ldbl * rop, ldbl * op, int pow) {
  *rop = ldexpl(*op, pow);
}

int isinf_LD(ldbl * op) {
  return isinf(*op);
}

int ilogb_LD(ldbl * op) {
  return ilogbl(*op);
}

int isnan_LD(ldbl * op) {
#ifdef ISNANL_IS_UNAVAILABLE
  return _is_nan(*op);
#else
  return isnanl(*op);
#endif
}

void lgamma_LD(ldbl * rop, ldbl * op) {
  *rop = lgammal(*op);
}

SV * llrint_LD(pTHX_ ldbl * op) {
#ifdef LONGLONG2IV_IS_OK
  return newSViv((IV)llrintl(*op));
#else
  warn("llrint_LD not implemented: IV size (%d) is smaller than longlong size (%d)\n", sizeof(IV), sizeof(long long int));
  croak("Use lrint_LD instead");
#endif
}

SV * llround_LD(pTHX_ ldbl * op) {
#ifdef LONGLONG2IV_IS_OK
  return newSViv((IV)llroundl(*op));
#else
  warn("llround_LD not implemented: IV size (%d) is smaller than longlong size (%d)\n", sizeof(IV), sizeof(long long int));
  croak("Use lround_LD instead");
#endif
}

SV * lrint_LD(pTHX_ ldbl * op) {
#ifdef LONG2IV_IS_OK
  return newSViv((IV)lrintl(*op));
#else
  croak("lrint_LD not implemented: IV size (%d) is smaller than long size (%d)", sizeof(IV), sizeof(long));
#endif
}

SV * lround_LD(pTHX_ ldbl * op) {
#ifdef LONG2IV_IS_OK
  return newSViv((IV)lroundl(*op));
#else
  croak("lround_LD not implemented: IV size (%d) is smaller than long size (%d)", sizeof(IV), sizeof(long));
#endif
}

void log_LD(ldbl * rop, ldbl * op) {
  *rop = logl(*op);
}

void log10_LD(pTHX_ ldbl * rop, ldbl * op) {
  *rop = log10l(*op);
}

void log2_LD(ldbl * rop, ldbl * op) {
  *rop = log2l(*op);
}

void log1p_LD(ldbl * rop, ldbl * op) {
  *rop = log1pl(*op);
}

void modf_LD(ldbl * integer, ldbl * frac, ldbl * op) {
#if defined(__MINGW64__) && (__MINGW64_VERSION_MAJOR == 4 || __MINGW64_VERSION_MAJOR == 5) \
                         && __MINGW64_VERSION_MINOR == 0 /* http://sourceforge.net/p/mingw-w64/bugs/478/ *
                                                          * fixed in runtime version 5.0.3               */
  *integer = truncl(*op);
  *frac = *op - *integer;
#else
  ldbl ret;
  *frac = modfl(*op, &ret);
  *integer = ret;
#endif
}

void nan_LD(pTHX_ ldbl * rop, SV * op) {
#ifdef NANL_IS_UNAVAILABLE
  *rop = _get_nan();
#else
  *rop = nanl(SvPV_nolen(op));
#endif
}

void nearbyint_LD(ldbl * rop, ldbl * op) {
  *rop = nearbyintl(*op);
}

void nextafter_LD(ldbl * rop, ldbl * op1, ldbl * op2) {
  *rop = nextafterl(*op1, *op2);
}

void pow_LD(pTHX_ ldbl * rop, ldbl * op1, ldbl * op2) {
#ifdef NAN_POW_BUG
  if(_is_nan(*op1) && *op2 == 0.0L) *rop = 1.0L;
  else *rop = powl(*op1, *op2);
#else
  *rop = powl(*op1, *op2);
#endif
}

void remainder_LD(ldbl * rop, ldbl * op1, ldbl * op2) {
  *rop = remainderl(*op1, *op2);
}

/*
remquol seems buggy with some compilers, and is therefore not tested.
Just wrap it, document that it's untested, and don't worry about it.
*/

void remquo_LD(pTHX_ ldbl * rop1, SV * rop2, ldbl * op1, ldbl * op2) {
  int ret;
  *rop1 = remquol(*op1, *op2, &ret);
  sv_setsv(rop2, newSViv(ret));
}

void rint_LD(ldbl * rop, ldbl * op) {
  *rop = rintl(*op);
}

void round_LD(ldbl * rop, ldbl * op) {
  *rop = roundl(*op);
}

void scalbln_LD(ldbl * rop, ldbl * op1, long op2) {
  *rop = scalblnl(*op1, op2);
}

void scalbn_LD(ldbl * rop, ldbl * op1, int op2) {
  *rop = scalbnl(*op1, op2);
}

int signbit_LD(ldbl * op) {
#ifdef SIGNBITL_IS_UNAVAILABLE
  return signbit(*op);
#else
  return signbitl(*op);
#endif
}

void sincos_LD(ldbl * sin, ldbl * cos, ldbl * op) {
#ifdef SINCOSL_IS_UNAVAILABLE
  *sin = sinl(*op);
  *cos = cosl(*op);
#else
  ldbl sine, cosine;
  sincosl(*op, &sine, &cosine);
  *sin = sine;
  *cos = cosine;
#endif
}

void sinh_LD(ldbl * rop, ldbl * op) {
  *rop = sinhl(*op);
}

void sin_LD(ldbl * rop, ldbl * op) {
  *rop = sinl(*op);
}

void sqrt_LD(ldbl * rop, ldbl * op) {
  *rop = sqrtl(*op);
}

void tan_LD(ldbl * rop, ldbl * op) {
  *rop = tanl(*op);
}

void tanh_LD(ldbl * rop, ldbl * op) {
  *rop = tanhl(*op);
}

void tgamma_LD(ldbl * rop, ldbl * op) {
  *rop = tgammal(*op);
}

void trunc_LD(ldbl * rop, ldbl * op) {
  *rop = truncl(*op);
}

SV * _sincosl_status(pTHX) {
#ifdef SINCOSL_IS_UNAVAILABLE
  return newSVpv("using own implementation of sincosl function", 0);
#else
  return newSVpv("built with sincosl function", 0);
#endif
}

int _longlong2iv_is_ok(void) {

/* Is longlong to IV conversion guaranteed to not lose precision ? */
#ifdef LONGLONG2IV_IS_OK
  return 1;
#else
  return 0;
#endif

}

/* Is long to IV conversion guaranteed to not lose precision ? */
int _long2iv_is_ok(void) {

#ifdef LONG2IV_IS_OK
  return 1;
#else
  return 0;
#endif

}

/* FLT_RADIX is probably 2, but we can use this if we need to be sure. */
int _flt_radix(void) {
#ifdef FLT_RADIX
  return (int)FLT_RADIX;
#else
  return 0;
#endif
}



SV * _LDBL_MAX(pTHX) {
#ifdef LDBL_MAX
     long double * f;
     SV * obj_ref, * obj;

     Newx(f, 1, long double);
     if(f == NULL) croak("Failed to allocate memory in _LDBL_MAX function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::LongDouble");

     *f = LDBL_MAX;

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
#else
     croak("LDBL_MAX not implemented");
#endif
}

SV * _LDBL_MIN(pTHX) {
#ifdef LDBL_MIN
     long double * f;
     SV * obj_ref, * obj;

     Newx(f, 1, long double);
     if(f == NULL) croak("Failed to allocate memory in _LDBL_MIN function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::LongDouble");

     *f = LDBL_MIN;

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
#else
     croak("LDBL_MIN not implemented");
#endif
}

SV * _LDBL_EPSILON(pTHX) {
#ifdef LDBL_EPSILON
     long double * f;
     SV * obj_ref, * obj;

     Newx(f, 1, long double);
     if(f == NULL) croak("Failed to allocate memory in _LDBL_EPSILON function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::LongDouble");

     *f = LDBL_EPSILON;

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
#else
     croak("LDBL_EPSILON not implemented");
#endif
}

SV * _LDBL_DENORM_MIN(pTHX) {
#ifdef LDBL_DENORM_MIN
     long double * f;
     SV * obj_ref, * obj;

     Newx(f, 1, long double);
     if(f == NULL) croak("Failed to allocate memory in _LDBL_DENORM_MIN function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::LongDouble");

     *f = LDBL_DENORM_MIN;

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
#else
     croak("LDBL_DENORM_MIN not implemented");
#endif
}

int _LDBL_MIN_EXP(pTHX) {
#ifdef LDBL_MIN_EXP
    return (int)LDBL_MIN_EXP;
#else
    croak("LDBL_MIN_EXP not implemented");
#endif
}

int _LDBL_MAX_EXP(pTHX) {
#ifdef LDBL_MAX_EXP
    return (int)LDBL_MAX_EXP;
#else
    croak("LDBL_MAX_EXP not implemented");
#endif
}

int _LDBL_MIN_10_EXP(pTHX) {
#ifdef LDBL_MIN_10_EXP
    return (int)LDBL_MIN_10_EXP;
#else
    croak("LDBL_MIN_10_EXP not implemented");
#endif
}

int _LDBL_MAX_10_EXP(pTHX) {
#ifdef LDBL_MAX_10_EXP
    return (int)LDBL_MAX_10_EXP;
#else
    croak("LDBL_MAX_10_EXP not implemented");
#endif
}



SV * _DBL_MAX(pTHX) {
#ifdef DBL_MAX
     long double * f;
     SV * obj_ref, * obj;

     Newx(f, 1, long double);
     if(f == NULL) croak("Failed to allocate memory in _DBL_MAX function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::LongDouble");

     *f = (long double)DBL_MAX;

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
#else
     croak("DBL_MAX not implemented");
#endif
}

SV * _DBL_MIN(pTHX) {
#ifdef DBL_MIN
     long double * f;
     SV * obj_ref, * obj;

     Newx(f, 1, long double);
     if(f == NULL) croak("Failed to allocate memory in _DBL_MIN function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::LongDouble");

     *f = (long double)DBL_MIN;

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
#else
     croak("DBL_MIN not implemented");
#endif
}

SV * _DBL_EPSILON(pTHX) {
#ifdef DBL_EPSILON
     long double * f;
     SV * obj_ref, * obj;

     Newx(f, 1, long double);
     if(f == NULL) croak("Failed to allocate memory in _DBL_EPSILON function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::LongDouble");

     *f = (long double)DBL_EPSILON;

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
#else
     croak("DBL_EPSILON not implemented");
#endif
}

SV * _DBL_DENORM_MIN(pTHX) {
#ifdef DBL_DENORM_MIN
     long double * f;
     SV * obj_ref, * obj;

     Newx(f, 1, long double);
     if(f == NULL) croak("Failed to allocate memory in _DBL_DENORM_MIN function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::LongDouble");

     *f = (long double)DBL_DENORM_MIN;

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
#else
     croak("DBL_DENORM_MIN not implemented");
#endif
}

int _DBL_MIN_EXP(pTHX) {
#ifdef DBL_MIN_EXP
    return (int)DBL_MIN_EXP;
#else
    croak("DBL_MIN_EXP not implemented");
#endif
}

int _DBL_MAX_EXP(pTHX) {
#ifdef DBL_MAX_EXP
    return (int)DBL_MAX_EXP;
#else
    croak("DBL_MAX_EXP not implemented");
#endif
}

int _DBL_MIN_10_EXP(pTHX) {
#ifdef DBL_MIN_10_EXP
    return (int)DBL_MIN_10_EXP;
#else
    croak("DBL_MIN_10_EXP not implemented");
#endif
}

int _DBL_MAX_10_EXP(pTHX) {
#ifdef DBL_MAX_10_EXP
    return (int)DBL_MAX_10_EXP;
#else
    croak("DBL_MAX_10_EXP not implemented");
#endif
}

/* #define M_E			2.7182818284590452354	*/

SV * _M_El(pTHX) {
#ifndef M_El
#define M_El expl(1.0L)
#endif
     long double * f;
     SV * obj_ref, * obj;

     Newx(f, 1, long double);
     if(f == NULL) croak("Failed to allocate memory in _M_E function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::LongDouble");

     *f = M_El;

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
}

/* #define M_LOG2E		1.4426950408889634074	*/

SV * _M_LOG2El(pTHX) {
#ifndef M_LOG2El
#define M_LOG2El log2l(expl(1.0L))
#endif
     long double * f;
     SV * obj_ref, * obj;

     Newx(f, 1, long double);
     if(f == NULL) croak("Failed to allocate memory in _M_LOG2E function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::LongDouble");

     *f = M_LOG2El;

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
}

/* #define M_LOG10E		0.43429448190325182765	*/

SV * _M_LOG10El(pTHX) {
#ifndef M_LOG10El
#define M_LOG10El log10l(expl(1.0L))
#endif
     long double * f;
     SV * obj_ref, * obj;

     Newx(f, 1, long double);
     if(f == NULL) croak("Failed to allocate memory in _M_LOG10E function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::LongDouble");

     *f = M_LOG10El;

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
}

/* #define M_LN2		0.69314718055994530942	*/

SV * _M_LN2l(pTHX) {
#ifndef M_LN2l
#define M_LN2l logl(2.0L)
#endif
     long double * f;
     SV * obj_ref, * obj;

     Newx(f, 1, long double);
     if(f == NULL) croak("Failed to allocate memory in _M_LN2 function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::LongDouble");

     *f = M_LN2l;

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
}

/* #define M_LN10		2.30258509299404568402	*/

SV * _M_LN10l(pTHX) {
#ifndef M_LN10l
#define M_LN10l logl(10.0L)
#endif
     long double * f;
     SV * obj_ref, * obj;

     Newx(f, 1, long double);
     if(f == NULL) croak("Failed to allocate memory in _M_LN10 function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::LongDouble");

     *f = M_LN10l;

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
}

/* #define M_PI			3.14159265358979323846	*/

SV * _M_PIl(pTHX) {
#ifndef M_PIl
#define M_PIl 2.0L*asinl(1.0L)
#endif
     long double * f;
     SV * obj_ref, * obj;

     Newx(f, 1, long double);
     if(f == NULL) croak("Failed to allocate memory in _M_PI function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::LongDouble");

     *f = M_PIl;

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
}

/* #define M_PI_2		1.57079632679489661923	*/

SV * _M_PI_2l(pTHX) {
#ifndef M_PI_2l
#define M_PI_2l asinl(1.0L)
#endif
     long double * f;
     SV * obj_ref, * obj;

     Newx(f, 1, long double);
     if(f == NULL) croak("Failed to allocate memory in _M_PI_2 function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::LongDouble");

     *f = M_PI_2l;

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
}

/* #define M_PI_4		0.78539816339744830962	*/

SV * _M_PI_4l(pTHX) {
#ifndef M_PI_4l
#define M_PI_4l asinl(1.0L)/2
#endif
     long double * f;
     SV * obj_ref, * obj;

     Newx(f, 1, long double);
     if(f == NULL) croak("Failed to allocate memory in _M_PI_4 function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::LongDouble");

     *f = M_PI_4l;

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
}

/* #define M_1_PI		0.31830988618379067154	*/

SV * _M_1_PIl(pTHX) {
#ifndef M_1_PIl
#define M_1_PIl 0.5L/asinl(1.0L)
#endif
     long double * f;
     SV * obj_ref, * obj;

     Newx(f, 1, long double);
     if(f == NULL) croak("Failed to allocate memory in _M_1_PI function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::LongDouble");

     *f = M_1_PIl;

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
}

/* #define M_2_PI		0.63661977236758134308	*/

SV * _M_2_PIl(pTHX) {
#ifndef M_2_PIl
#define M_2_PIl 1.0L/asinl(1.0L)
#endif
     long double * f;
     SV * obj_ref, * obj;

     Newx(f, 1, long double);
     if(f == NULL) croak("Failed to allocate memory in _M_2_PI function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::LongDouble");

     *f = M_2_PIl;

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
}

/* #define M_2_SQRTPI		1.12837916709551257390	*/

SV * _M_2_SQRTPIl(pTHX) {
#ifndef M_2_SQRTPIl
#define M_2_SQRTPIl 2.0L/sqrtl(2.0L*asinl(1.0L))
#endif
     long double * f;
     SV * obj_ref, * obj;

     Newx(f, 1, long double);
     if(f == NULL) croak("Failed to allocate memory in _M_2_SQRTPI function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::LongDouble");

     *f = M_2_SQRTPIl;

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
}

/* #define M_SQRT2		1.41421356237309504880	*/

SV * _M_SQRT2l(pTHX) {
#ifndef M_SQRT2l
#define M_SQRT2l sqrtl(2.0L)
#endif
     long double * f;
     SV * obj_ref, * obj;

     Newx(f, 1, long double);
     if(f == NULL) croak("Failed to allocate memory in _M_SQRT2 function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::LongDouble");

     *f = M_SQRT2l;

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
}

/* #define M_SQRT1_2		0.70710678118654752440	*/

SV * _M_SQRT1_2l(pTHX) {
#ifndef M_SQRT1_2l
#define M_SQRT1_2l 1.0L/sqrtl(2.0L)
#endif
     long double * f;
     SV * obj_ref, * obj;

     Newx(f, 1, long double);
     if(f == NULL) croak("Failed to allocate memory in _M_SQRT1_2 function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::LongDouble");

     *f = M_SQRT1_2l;

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
}

int _nan_pow_bug(void) {
#ifdef NAN_POW_BUG
  return 1;
#else
  return 0;
#endif
}

int _have_isnanl(void) {
#ifdef ISNANL_IS_UNAVAILABLE
  return 0;
#else
  return 1;
#endif
}

int _have_nanl(void) {
#ifdef NANL_IS_UNAVAILABLE
  return 0;
#else
  return 1;
#endif
}

int _have_signbitl(void) {
#ifdef SIGNBITL_IS_UNAVAILABLE
  return 0;
#else
  return 1;
#endif
}

int nnumflag(void) {
  return nnum;
}

void clear_nnum(void) {
  nnum = 0;
}

void set_nnum(int x) {
  nnum = x;
}

int _lln(pTHX_ SV * x) {
  if(looks_like_number(x)) return 1;
  return 0;
}

int _get_actual_nvsize(void) {
  return ACTUAL_NVSIZE;
}

int _get_actual_ldblsize(void) {
  return MATH_LONGDOUBLE_SIZE;
}


MODULE = Math::LongDouble  PACKAGE = Math::LongDouble

PROTOTYPES: DISABLE


void
_print_bytes (p, n)
	void *	p
	int	n
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        _print_bytes(p, n);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
ld_set_prec (x)
	int	x
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        ld_set_prec(aTHX_ x);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
InfLD (sign)
	int	sign
CODE:
  RETVAL = InfLD (aTHX_ sign);
OUTPUT:  RETVAL

SV *
NaNLD ()
CODE:
  RETVAL = NaNLD (aTHX);
OUTPUT:  RETVAL


SV *
ZeroLD (sign)
	int	sign
CODE:
  RETVAL = ZeroLD (aTHX_ sign);
OUTPUT:  RETVAL

SV *
UnityLD (sign)
	int	sign
CODE:
  RETVAL = UnityLD (aTHX_ sign);
OUTPUT:  RETVAL

SV *
is_NaNLD (b)
	SV *	b
CODE:
  RETVAL = is_NaNLD (aTHX_ b);
OUTPUT:  RETVAL

int
is_InfLD (b)
	SV *	b
CODE:
  RETVAL = is_InfLD (aTHX_ b);
OUTPUT:  RETVAL

int
is_ZeroLD (b)
	SV *	b
CODE:
  RETVAL = is_ZeroLD (aTHX_ b);
OUTPUT:  RETVAL

void
_nnum_inc (p)
	char *	p
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        _nnum_inc(p);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
STRtoLD (str)
	char *	str
CODE:
  RETVAL = STRtoLD (aTHX_ str);
OUTPUT:  RETVAL

void
LDtoSTR (ld)
	SV *	ld
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        LDtoSTR(aTHX_ ld);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
LDtoSTRP (ld, decimal_prec)
	SV *	ld
	int	decimal_prec
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        LDtoSTRP(aTHX_ ld, decimal_prec);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
NVtoLD (x)
	SV *	x
CODE:
  RETVAL = NVtoLD (aTHX_ x);
OUTPUT:  RETVAL

SV *
UVtoLD (x)
	SV *	x
CODE:
  RETVAL = UVtoLD (aTHX_ x);
OUTPUT:  RETVAL

SV *
IVtoLD (x)
	SV *	x
CODE:
  RETVAL = IVtoLD (aTHX_ x);
OUTPUT:  RETVAL

SV *
LDtoNV (ld)
	SV *	ld
CODE:
  RETVAL = LDtoNV (aTHX_ ld);
OUTPUT:  RETVAL

SV *
_overload_add (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_add (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_mul (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_mul (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_sub (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_sub (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_div (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_div (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_equiv (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_equiv (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_not_equiv (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_not_equiv (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_true (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_true (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_not (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_not (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_add_eq (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_add_eq (aTHX_ a, b, third);
OUTPUT:  RETVAL

void
broken_overload_add_eq (a, b, third)
	SV *	a
	SV *	b
	SV *	third
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        broken_overload_add_eq(aTHX_ a, b, third);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
_overload_mul_eq (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_mul_eq (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_sub_eq (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_sub_eq (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_div_eq (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_div_eq (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_lt (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_lt (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_gt (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_gt (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_lte (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_lte (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_gte (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_gte (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_spaceship (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_spaceship (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_copy (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_copy (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
LDtoLD (a)
	SV *	a
CODE:
  RETVAL = LDtoLD (aTHX_ a);
OUTPUT:  RETVAL

SV *
_itsa (a)
	SV *	a
CODE:
  RETVAL = _itsa (aTHX_ a);
OUTPUT:  RETVAL

void
DESTROY (rop)
	SV *	rop
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        DESTROY(aTHX_ rop);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
_overload_abs (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_abs (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
cmp_NV (ld_obj, sv)
	SV *	ld_obj
	SV *	sv
CODE:
  RETVAL = cmp_NV (aTHX_ ld_obj, sv);
OUTPUT:  RETVAL

int
_double_size ()


int
_long_double_size ()


SV *
_overload_int (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_int (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_sqrt (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_sqrt (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_log (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_log (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_exp (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_exp (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_sin (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_sin (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_cos (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_cos (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_atan2 (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_atan2 (aTHX_ a, b, third);
OUTPUT:  RETVAL

void
_overload_inc (a, b, third)
	SV *	a
	SV *	b
	SV *	third
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        _overload_inc(aTHX_ a, b, third);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
_overload_dec (a, b, third)
	SV *	a
	SV *	b
	SV *	third
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        _overload_dec(aTHX_ a, b, third);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
_overload_pow (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_pow (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_pow_eq (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_pow_eq (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_wrap_count ()
CODE:
  RETVAL = _wrap_count (aTHX);
OUTPUT:  RETVAL


SV *
ld_get_prec ()
CODE:
  RETVAL = ld_get_prec (aTHX);
OUTPUT:  RETVAL


SV *
_LDBL_DIG ()
CODE:
  RETVAL = _LDBL_DIG (aTHX);
OUTPUT:  RETVAL


SV *
_DBL_DIG ()
CODE:
  RETVAL = _DBL_DIG (aTHX);
OUTPUT:  RETVAL


SV *
_LDBL_MANT_DIG ()
CODE:
  RETVAL = _LDBL_MANT_DIG (aTHX);
OUTPUT:  RETVAL


SV *
_DBL_MANT_DIG ()
CODE:
  RETVAL = _DBL_MANT_DIG (aTHX);
OUTPUT:  RETVAL


SV *
_get_xs_version ()
CODE:
  RETVAL = _get_xs_version (aTHX);
OUTPUT:  RETVAL


SV *
_ld_bytes (arg)
	SV *	arg
CODE:
  RETVAL = _ld_bytes (aTHX_ arg);
OUTPUT:  RETVAL

void
acos_LD (rop, op)
	ldbl *	rop
	ldbl *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        acos_LD(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
acosh_LD (rop, op)
	ldbl *	rop
	ldbl *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        acosh_LD(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
asin_LD (rop, op)
	ldbl *	rop
	ldbl *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        asin_LD(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
asinh_LD (rop, op)
	ldbl *	rop
	ldbl *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        asinh_LD(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
atan_LD (rop, op)
	ldbl *	rop
	ldbl *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        atan_LD(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
atanh_LD (rop, op)
	ldbl *	rop
	ldbl *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        atanh_LD(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
atan2_LD (rop, op1, op2)
	ldbl *	rop
	ldbl *	op1
	ldbl *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        atan2_LD(rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
cbrt_LD (rop, op)
	ldbl *	rop
	ldbl *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        cbrt_LD(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
ceil_LD (rop, op)
	ldbl *	rop
	ldbl *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        ceil_LD(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
copysign_LD (rop, op1, op2)
	ldbl *	rop
	ldbl *	op1
	ldbl *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        copysign_LD(rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
cosh_LD (rop, op)
	ldbl *	rop
	ldbl *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        cosh_LD(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
cos_LD (rop, op)
	ldbl *	rop
	ldbl *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        cos_LD(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
erf_LD (rop, op)
	ldbl *	rop
	ldbl *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        erf_LD(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
erfc_LD (rop, op)
	ldbl *	rop
	ldbl *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        erfc_LD(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
exp_LD (rop, op)
	ldbl *	rop
	ldbl *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        exp_LD(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
expm1_LD (rop, op)
	ldbl *	rop
	ldbl *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        expm1_LD(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
fabs_LD (rop, op)
	ldbl *	rop
	ldbl *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        fabs_LD(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
fdim_LD (rop, op1, op2)
	ldbl *	rop
	ldbl *	op1
	ldbl *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        fdim_LD(rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

int
finite_LD (op)
	ldbl *	op

void
floor_LD (rop, op)
	ldbl *	rop
	ldbl *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        floor_LD(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
fma_LD (rop, op1, op2, op3)
	ldbl *	rop
	ldbl *	op1
	ldbl *	op2
	ldbl *	op3
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        fma_LD(rop, op1, op2, op3);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
fmax_LD (rop, op1, op2)
	ldbl *	rop
	ldbl *	op1
	ldbl *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        fmax_LD(rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
fmin_LD (rop, op1, op2)
	ldbl *	rop
	ldbl *	op1
	ldbl *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        fmin_LD(rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
fmod_LD (rop, op1, op2)
	ldbl *	rop
	ldbl *	op1
	ldbl *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        fmod_LD(rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
hypot_LD (rop, op1, op2)
	ldbl *	rop
	ldbl *	op1
	ldbl *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        hypot_LD(rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
frexp_LD (frac, exp, op)
	ldbl *	frac
	SV *	exp
	ldbl *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        frexp_LD(aTHX_ frac, exp, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
ldexp_LD (rop, op, pow)
	ldbl *	rop
	ldbl *	op
	int	pow
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        ldexp_LD(rop, op, pow);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

int
isinf_LD (op)
	ldbl *	op

int
ilogb_LD (op)
	ldbl *	op

int
isnan_LD (op)
	ldbl *	op

void
lgamma_LD (rop, op)
	ldbl *	rop
	ldbl *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        lgamma_LD(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
llrint_LD (op)
	ldbl *	op
CODE:
  RETVAL = llrint_LD (aTHX_ op);
OUTPUT:  RETVAL

SV *
llround_LD (op)
	ldbl *	op
CODE:
  RETVAL = llround_LD (aTHX_ op);
OUTPUT:  RETVAL

SV *
lrint_LD (op)
	ldbl *	op
CODE:
  RETVAL = lrint_LD (aTHX_ op);
OUTPUT:  RETVAL

SV *
lround_LD (op)
	ldbl *	op
CODE:
  RETVAL = lround_LD (aTHX_ op);
OUTPUT:  RETVAL

void
log_LD (rop, op)
	ldbl *	rop
	ldbl *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        log_LD(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
log10_LD (rop, op)
	ldbl *	rop
	ldbl *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        log10_LD(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
log2_LD (rop, op)
	ldbl *	rop
	ldbl *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        log2_LD(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
log1p_LD (rop, op)
	ldbl *	rop
	ldbl *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        log1p_LD(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
modf_LD (integer, frac, op)
	ldbl *	integer
	ldbl *	frac
	ldbl *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        modf_LD(integer, frac, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
nan_LD (rop, op)
	ldbl *	rop
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        nan_LD(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
nearbyint_LD (rop, op)
	ldbl *	rop
	ldbl *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        nearbyint_LD(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
nextafter_LD (rop, op1, op2)
	ldbl *	rop
	ldbl *	op1
	ldbl *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        nextafter_LD(rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
pow_LD (rop, op1, op2)
	ldbl *	rop
	ldbl *	op1
	ldbl *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        pow_LD(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
remainder_LD (rop, op1, op2)
	ldbl *	rop
	ldbl *	op1
	ldbl *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        remainder_LD(rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
remquo_LD (rop1, rop2, op1, op2)
	ldbl *	rop1
	SV *	rop2
	ldbl *	op1
	ldbl *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        remquo_LD(aTHX_ rop1, rop2, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
rint_LD (rop, op)
	ldbl *	rop
	ldbl *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        rint_LD(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
round_LD (rop, op)
	ldbl *	rop
	ldbl *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        round_LD(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
scalbln_LD (rop, op1, op2)
	ldbl *	rop
	ldbl *	op1
	long	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        scalbln_LD(rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
scalbn_LD (rop, op1, op2)
	ldbl *	rop
	ldbl *	op1
	int	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        scalbn_LD(rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

int
signbit_LD (op)
	ldbl *	op

void
sincos_LD (sin, cos, op)
	ldbl *	sin
	ldbl *	cos
	ldbl *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        sincos_LD(sin, cos, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
sinh_LD (rop, op)
	ldbl *	rop
	ldbl *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        sinh_LD(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
sin_LD (rop, op)
	ldbl *	rop
	ldbl *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        sin_LD(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
sqrt_LD (rop, op)
	ldbl *	rop
	ldbl *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        sqrt_LD(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
tan_LD (rop, op)
	ldbl *	rop
	ldbl *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        tan_LD(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
tanh_LD (rop, op)
	ldbl *	rop
	ldbl *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        tanh_LD(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
tgamma_LD (rop, op)
	ldbl *	rop
	ldbl *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        tgamma_LD(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
trunc_LD (rop, op)
	ldbl *	rop
	ldbl *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        trunc_LD(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
_sincosl_status ()
CODE:
  RETVAL = _sincosl_status (aTHX);
OUTPUT:  RETVAL


int
_longlong2iv_is_ok ()


int
_long2iv_is_ok ()


int
_flt_radix ()


SV *
_LDBL_MAX ()
CODE:
  RETVAL = _LDBL_MAX (aTHX);
OUTPUT:  RETVAL


SV *
_LDBL_MIN ()
CODE:
  RETVAL = _LDBL_MIN (aTHX);
OUTPUT:  RETVAL


SV *
_LDBL_EPSILON ()
CODE:
  RETVAL = _LDBL_EPSILON (aTHX);
OUTPUT:  RETVAL


SV *
_LDBL_DENORM_MIN ()
CODE:
  RETVAL = _LDBL_DENORM_MIN (aTHX);
OUTPUT:  RETVAL


int
_LDBL_MIN_EXP ()
CODE:
  RETVAL = _LDBL_MIN_EXP (aTHX);
OUTPUT:  RETVAL


int
_LDBL_MAX_EXP ()
CODE:
  RETVAL = _LDBL_MAX_EXP (aTHX);
OUTPUT:  RETVAL


int
_LDBL_MIN_10_EXP ()
CODE:
  RETVAL = _LDBL_MIN_10_EXP (aTHX);
OUTPUT:  RETVAL


int
_LDBL_MAX_10_EXP ()
CODE:
  RETVAL = _LDBL_MAX_10_EXP (aTHX);
OUTPUT:  RETVAL


SV *
_DBL_MAX ()
CODE:
  RETVAL = _DBL_MAX (aTHX);
OUTPUT:  RETVAL


SV *
_DBL_MIN ()
CODE:
  RETVAL = _DBL_MIN (aTHX);
OUTPUT:  RETVAL


SV *
_DBL_EPSILON ()
CODE:
  RETVAL = _DBL_EPSILON (aTHX);
OUTPUT:  RETVAL


SV *
_DBL_DENORM_MIN ()
CODE:
  RETVAL = _DBL_DENORM_MIN (aTHX);
OUTPUT:  RETVAL


int
_DBL_MIN_EXP ()
CODE:
  RETVAL = _DBL_MIN_EXP (aTHX);
OUTPUT:  RETVAL


int
_DBL_MAX_EXP ()
CODE:
  RETVAL = _DBL_MAX_EXP (aTHX);
OUTPUT:  RETVAL


int
_DBL_MIN_10_EXP ()
CODE:
  RETVAL = _DBL_MIN_10_EXP (aTHX);
OUTPUT:  RETVAL


int
_DBL_MAX_10_EXP ()
CODE:
  RETVAL = _DBL_MAX_10_EXP (aTHX);
OUTPUT:  RETVAL


SV *
_M_El ()
CODE:
  RETVAL = _M_El (aTHX);
OUTPUT:  RETVAL


SV *
_M_LOG2El ()
CODE:
  RETVAL = _M_LOG2El (aTHX);
OUTPUT:  RETVAL


SV *
_M_LOG10El ()
CODE:
  RETVAL = _M_LOG10El (aTHX);
OUTPUT:  RETVAL


SV *
_M_LN2l ()
CODE:
  RETVAL = _M_LN2l (aTHX);
OUTPUT:  RETVAL


SV *
_M_LN10l ()
CODE:
  RETVAL = _M_LN10l (aTHX);
OUTPUT:  RETVAL


SV *
_M_PIl ()
CODE:
  RETVAL = _M_PIl (aTHX);
OUTPUT:  RETVAL


SV *
_M_PI_2l ()
CODE:
  RETVAL = _M_PI_2l (aTHX);
OUTPUT:  RETVAL


SV *
_M_PI_4l ()
CODE:
  RETVAL = _M_PI_4l (aTHX);
OUTPUT:  RETVAL


SV *
_M_1_PIl ()
CODE:
  RETVAL = _M_1_PIl (aTHX);
OUTPUT:  RETVAL


SV *
_M_2_PIl ()
CODE:
  RETVAL = _M_2_PIl (aTHX);
OUTPUT:  RETVAL


SV *
_M_2_SQRTPIl ()
CODE:
  RETVAL = _M_2_SQRTPIl (aTHX);
OUTPUT:  RETVAL


SV *
_M_SQRT2l ()
CODE:
  RETVAL = _M_SQRT2l (aTHX);
OUTPUT:  RETVAL


SV *
_M_SQRT1_2l ()
CODE:
  RETVAL = _M_SQRT1_2l (aTHX);
OUTPUT:  RETVAL


int
_nan_pow_bug ()


int
_have_isnanl ()


int
_have_nanl ()


int
_have_signbitl ()


int
nnumflag ()


void
clear_nnum ()

        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        clear_nnum();
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
set_nnum (x)
	int	x
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        set_nnum(x);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

int
_lln (x)
	SV *	x
CODE:
  RETVAL = _lln (aTHX_ x);
OUTPUT:  RETVAL

int
_get_actual_nvsize ()


int
_get_actual_ldblsize ()


