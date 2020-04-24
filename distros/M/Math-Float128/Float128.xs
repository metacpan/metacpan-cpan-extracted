
#ifdef  __MINGW32__
#ifndef __USE_MINGW_ANSI_STDIO
#define __USE_MINGW_ANSI_STDIO 1
#endif
#endif

#define PERL_NO_GET_CONTEXT 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


#include "math_float128_include.h"

int nnum = 0;

int nok_pok = 0; /* flag that is incremented whenever a scalar that is both
                 NOK and POK is passed to new or an overloaded operator */

int NOK_POK_val(pTHX) {
  /* return the numeric value of $Math::MPFR::NOK_POK */
  return SvIV(get_sv("Math::Float128::NOK_POK", 0));
}

int _win32_infnanstring(char * s) { /* MS Windows only - detect 1.#INF and 1.#IND
                                     * Need to do this to correctly handle a scalar
                                     * that is both NOK and POK on older win32 perls */

  /*************************************
  * if input string    =~ /^\-1\.#INF$/ return -1
  * elsif input string =~ /^\+?1\.#INF$/i return 1
  * elsif input string =~ /^(\-|\+)?1\.#IND$/i return 2
  * else return 0
  **************************************/

#ifdef _WIN32_BIZARRE_INFNAN

  int sign = 1;
  int factor = 1;

  if(s[0] == '-') {
    sign = -1;
    s++;
  }
  else {
    if(s[0] == '+') s++;
  }

  if(!strcmp(s, "1.#INF")) return sign;
  if(!strcmp(s, "1.#IND")) return 2;

  return 0;
#else
  croak("Math::Float128::_win32_infnanstring not implemented for this build of perl");
#endif
}

void flt128_set_prec(pTHX_ int x) {
    if(x < 1)croak("1st arg (precision) to flt128_set_prec must be at least 1");
    _DIGITS = x;
}

int flt128_get_prec(void) {
     return _DIGITS;
}

int _is_nan(float128 x) {
    if(x != x) return 1;
    return 0;
}

int  _is_inf(float128 x) {
     if(x != x) return 0; /* NaN  */
     if(x == 0.0Q) return 0; /* Zero */
     if(x/x != x/x) {
       if(x < 0.0Q) return -1;
       else return 1;
     }
     return 0; /* Finite Real */
}

/* Replaced */
/*
//int  _is_zero(float128 x) {
//     char * buffer;
//
//     if(x != 0.0Q) return 0;
//
//     Newx(buffer, 2, char);
//
//     quadmath_snprintf(buffer, sizeof buffer, "%.0Qf", x);
//
//     if(!strcmp(buffer, "-0")) {
//       Safefree(buffer);
//       return -1;
//     }
//
//     Safefree(buffer);
//     return 1;
//}
*/

int _is_zero(float128 x) {

  int n = sizeof(float128);
  void * p = &x;

  if(x != 0.0Q) return 0;

#ifdef WE_HAVE_BENDIAN /* Big Endian architecture */
  if(((unsigned char*)p)[0] >= 128) return -1;
#else
  if(((unsigned char*)p)[n - 1] >= 128) return -1;
#endif
  return 1;
}

float128 _get_inf(int sign) {
    float128 ret;
    ret = FLT128_MAX * 2.0Q;
    if(sign < 0) ret *= -1.0Q;
    return ret;
}

float128 _get_nan(void) {
     float128 inf = _get_inf(1);
     return inf / inf;
}

SV * InfF128(pTHX_ int sign) {
     float128 * f;
     SV * obj_ref, * obj;

     Newx(f, 1, float128);
     if(f == NULL) croak("Failed to allocate memory in InfF128 function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Float128");

     *f = _get_inf(sign);

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * NaNF128(pTHX) {
     float128 * f;
     SV * obj_ref, * obj;

     Newx(f, 1, float128);
     if(f == NULL) croak("Failed to allocate memory in NaNF128 function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Float128");

     *f = _get_nan();

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * ZeroF128(pTHX_ int sign) {
     float128 * f;
     SV * obj_ref, * obj;

     Newx(f, 1, float128);
     if(f == NULL) croak("Failed to allocate memory in ZeroF128 function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Float128");

     *f = 0.0Q;
     if(sign < 0) *f *= -1;

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * UnityF128(pTHX_ int sign) {
     float128 * f;
     SV * obj_ref, * obj;

     Newx(f, 1, float128);
     if(f == NULL) croak("Failed to allocate memory in UnityF128 function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Float128");

     *f = 1.0Q;
     if(sign < 0) *f *= -1;

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * is_NaNF128(pTHX_ SV * b) {
     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Float128"))
         return newSViv(_is_nan(*(INT2PTR(float128 *, SvIVX(SvRV(b))))));
     }
     croak("Invalid argument supplied to Math::Float128::isNaNF128 function");
}

SV * is_InfF128(pTHX_ SV * b) {
     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Float128"))
         return newSViv(_is_inf(*(INT2PTR(float128 *, SvIVX(SvRV(b))))));
     }
     croak("Invalid argument supplied to Math::Float128::is_InfF128 function");
}

SV * is_ZeroF128(pTHX_ SV * b) {
     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Float128"))
         return newSViv(_is_zero(*(INT2PTR(float128 *, SvIVX(SvRV(b))))));
     }
     croak("Invalid argument supplied to Math::Float128::is_ZeroF128 function");
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

SV * STRtoF128(pTHX_ SV * str) {
     float128 * f;
     SV * obj_ref, * obj;
     char * p;
     int inf_or_nan = 0;

     Newx(f, 1, float128);
     if(f == NULL) croak("Failed to allocate memory in STRtoF128 function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Float128");

#ifdef _WIN32_BIZARRE_INFNAN
     inf_or_nan = _win32_infnanstring(SvPV_nolen(str));
     if(inf_or_nan) {
       if(inf_or_nan == 2) *f = _get_nan();
       else *f = _get_inf(inf_or_nan);
     }
     else *f = strtoflt128(SvPV_nolen(str), &p);
#else
     *f = strtoflt128(SvPV_nolen(str), &p);
#endif

     if(!inf_or_nan) _nnum_inc(p);

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
}

void fromSTR(pTHX_ float128 * f, SV * str) {
     char * p;
     int inf_or_nan = 0;

#ifdef _WIN32_BIZARRE_INFNAN
     inf_or_nan = _win32_infnanstring(SvPV_nolen(str));
     if(inf_or_nan) {
       if(inf_or_nan == 2) *f = _get_nan();
       else *f = _get_inf(inf_or_nan);
     }
     else *f = strtoflt128(SvPV_nolen(str), &p);
#else
     *f = strtoflt128(SvPV_nolen(str), &p);
#endif

     if(!inf_or_nan) _nnum_inc(p);

}

SV * NVtoF128(pTHX_ SV * nv) {
     float128 * f;
     SV * obj_ref, * obj;

     Newx(f, 1, float128);
     if(f == NULL) croak("Failed to allocate memory in NVtoF128 function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Float128");

     *f = (float128)SvNV(nv);

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
}

void fromNV(pTHX_ float128 * f, SV * nv) {
     *f = (float128)SvNV(nv);
}

SV * IVtoF128(pTHX_ SV * iv) {
     float128 * f;
     SV * obj_ref, * obj;

     Newx(f, 1, float128);
     if(f == NULL) croak("Failed to allocate memory in IVtoF128 function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Float128");

     *f = (float128)SvIV(iv);

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
}

void fromIV(pTHX_ float128 * f, SV * iv) {
     *f = (float128)SvIV(iv);
}

SV * UVtoF128(pTHX_ SV * uv) {
     float128 * f;
     SV * obj_ref, * obj;

     Newx(f, 1, float128);
     if(f == NULL) croak("Failed to allocate memory in UVtoF128 function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Float128");

     *f = (float128)SvUV(uv);

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
}

void fromUV(pTHX_ float128 * f,SV * uv) {
     *f = (float128)SvUV(uv);
}

void F128toSTR(pTHX_ SV * f) {
     dXSARGS;
     float128 t;
     char * buffer;

     if(sv_isobject(f)) {
       const char *h = HvNAME(SvSTASH(SvRV(f)));
       if(strEQ(h, "Math::Float128")) {
          EXTEND(SP, 1);
          t = *(INT2PTR(float128 *, SvIVX(SvRV(f))));

          Newx(buffer, 15 + _DIGITS, char);
          if(buffer == NULL) croak("Failed to allocate memory in F128toSTR");
          quadmath_snprintf(buffer, 15 + _DIGITS, "%.*Qe", _DIGITS - 1, t);
          ST(0) = sv_2mortal(newSVpv(buffer, 0));
          Safefree(buffer);
          XSRETURN(1);
       }
       else croak("Invalid object supplied to Math::Float128::F128toSTR function");
     }
     else croak("Invalid argument supplied to Math::Float128::F128toSTR function");
}

void F128toSTRP(pTHX_ SV * f, int decimal_prec) {
     dXSARGS;
     float128 t;
     char * buffer;

     if(decimal_prec < 1)croak("2nd arg (precision) to F128toSTRP  must be at least 1");

     if(sv_isobject(f)) {
       const char *h = HvNAME(SvSTASH(SvRV(f)));
       if(strEQ(h, "Math::Float128")) {
          EXTEND(SP, 1);
          t = *(INT2PTR(float128 *, SvIVX(SvRV(f))));

          Newx(buffer, 12 + decimal_prec, char);
          if(buffer == NULL) croak("Failed to allocate memory in F128toSTRP");
          quadmath_snprintf(buffer, 12 + decimal_prec, "%.*Qe", decimal_prec - 1, t);
          ST(0) = sv_2mortal(newSVpv(buffer, 0));
          Safefree(buffer);
          XSRETURN(1);
       }
       else croak("Invalid object supplied to Math::Float128::F128toSTRP function");
     }
     else croak("Invalid argument supplied to Math::Float128::F128toSTRP function");
}

void DESTROY(pTHX_ SV *  f) {
     Safefree(INT2PTR(float128 *, SvIVX(SvRV(f))));
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

SV * _FLT128_DIG(pTHX) {
#ifdef FLT128_DIG
     return newSViv(FLT128_DIG);
#else
     croak("FLT128_DIG not implemented");
#endif
}

SV * _overload_add(pTHX_ SV * a, SV * b, SV * third) {

     float128 * ld;
     SV * obj_ref, * obj;

     Newx(ld, 1, float128);
     if(ld == NULL) croak("Failed to allocate memory in _overload_add function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Float128");

     sv_setiv(obj, INT2PTR(IV,ld));
     SvREADONLY_on(obj);

    if(SvUOK(b)) {
       *ld = *(INT2PTR(float128 *, SvIVX(SvRV(a)))) + (float128)SvUVX(b);
        return obj_ref;
    }

    if(SvIOK(b)) {
       *ld = *(INT2PTR(float128 *, SvIVX(SvRV(a)))) + (float128)SvIVX(b);
        return obj_ref;
    }

    if(SvPOK(b)) {
       char * p;
#ifdef _WIN32_BIZARRE_INFNAN
       int inf_or_nan = _win32_infnanstring(SvPV_nolen(b));
#endif

       NOK_POK_DUALVAR_CHECK , "overload_add");}

#ifdef _WIN32_BIZARRE_INFNAN
       if(inf_or_nan) {
         if(inf_or_nan == 2) *ld = _get_nan();
         else *ld = *(INT2PTR(float128 *, SvIVX(SvRV(a)))) + _get_inf(inf_or_nan);
       }
       else {
         *ld = *(INT2PTR(float128 *, SvIVX(SvRV(a)))) + strtoflt128(SvPV_nolen(b), &p);
         _nnum_inc(p);
       }
#else
       *ld = *(INT2PTR(float128 *, SvIVX(SvRV(a)))) + strtoflt128(SvPV_nolen(b), &p);
       _nnum_inc(p);
#endif
       return obj_ref;
    }

    if(SvNOK(b)) {
#if defined(AVOID_INF_CAST)
       if(SvNVX(b) != 0.0L && SvNVX(b) == SvNVX(b) && SvNVX(b) / SvNVX(b) != SvNVX(b) / SvNVX(b)) {
         *ld = *(INT2PTR(float128 *, SvIVX(SvRV(a)))) + _get_inf(SvNVX(b) > 0 ? 1 : -1);
         return obj_ref;
       }
#endif
       *ld = *(INT2PTR(float128 *, SvIVX(SvRV(a)))) + (float128)SvNVX(b);
        return obj_ref;
    }

    if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Float128")) {
        *ld = *(INT2PTR(float128 *, SvIVX(SvRV(a)))) + *(INT2PTR(float128 *, SvIVX(SvRV(b))));
        return obj_ref;
      }
      croak("Invalid object supplied to Math::Float128::_overload_add function");
    }

    croak("Invalid argument supplied to Math::Float128::_overload_add function");
}

SV * _overload_mul(pTHX_ SV * a, SV * b, SV * third) {

     float128 * ld;
     SV * obj_ref, * obj;

     Newx(ld, 1, float128);
     if(ld == NULL) croak("Failed to allocate memory in _overload_mul function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Float128");

     sv_setiv(obj, INT2PTR(IV,ld));
     SvREADONLY_on(obj);

    if(SvUOK(b)) {
       *ld = *(INT2PTR(float128 *, SvIVX(SvRV(a)))) * (float128)SvUVX(b);
        return obj_ref;
    }

    if(SvIOK(b)) {
       *ld = *(INT2PTR(float128 *, SvIVX(SvRV(a)))) * (float128)SvIVX(b);
        return obj_ref;
    }

    if(SvPOK(b)) {
       char * p;
#ifdef _WIN32_BIZARRE_INFNAN
       int inf_or_nan = _win32_infnanstring(SvPV_nolen(b));
#endif

       NOK_POK_DUALVAR_CHECK , "overload_mul");}

#ifdef _WIN32_BIZARRE_INFNAN
       if(inf_or_nan) {
         if(inf_or_nan == 2) *ld = _get_nan();
         else *ld = *(INT2PTR(float128 *, SvIVX(SvRV(a)))) * _get_inf(inf_or_nan);
       }
       else {
         *ld = *(INT2PTR(float128 *, SvIVX(SvRV(a)))) * strtoflt128(SvPV_nolen(b), &p);
         _nnum_inc(p);
       }
#else
       *ld = *(INT2PTR(float128 *, SvIVX(SvRV(a)))) * strtoflt128(SvPV_nolen(b), &p);
       _nnum_inc(p);
#endif
       return obj_ref;
    }

    if(SvNOK(b)) {
#if defined(AVOID_INF_CAST)
       if(SvNVX(b) != 0.0L && SvNVX(b) == SvNVX(b) && SvNVX(b) / SvNVX(b) != SvNVX(b) / SvNVX(b)) {
         *ld = *(INT2PTR(float128 *, SvIVX(SvRV(a)))) * _get_inf(SvNVX(b) > 0 ? 1 : -1);
         return obj_ref;
       }
#endif
       *ld = *(INT2PTR(float128 *, SvIVX(SvRV(a)))) * (float128)SvNVX(b);
        return obj_ref;
    }

    if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Float128")) {
        *ld = *(INT2PTR(float128 *, SvIVX(SvRV(a)))) * *(INT2PTR(float128 *, SvIVX(SvRV(b))));
        return obj_ref;
      }
      croak("Invalid object supplied to Math::Float128::_overload_mul function");
    }
    croak("Invalid argument supplied to Math::Float128::_overload_mul function");
}

SV * _overload_sub(pTHX_ SV * a, SV * b, SV * third) {
     float128 * ld;
     SV * obj_ref, * obj;

     Newx(ld, 1, float128);
     if(ld == NULL) croak("Failed to allocate memory in _overload_sub function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Float128");

     sv_setiv(obj, INT2PTR(IV,ld));
     SvREADONLY_on(obj);

    if(SvUOK(b)) {
       if(third == &PL_sv_yes) *ld = (float128)SvUVX(b) - *(INT2PTR(float128 *, SvIVX(SvRV(a))));
       else *ld = *(INT2PTR(float128 *, SvIVX(SvRV(a)))) - (float128)SvUVX(b);
       return obj_ref;
    }

    if(SvIOK(b)) {
       if(third == &PL_sv_yes) *ld = (float128)SvIVX(b) - *(INT2PTR(float128 *, SvIVX(SvRV(a))));
       else *ld = *(INT2PTR(float128 *, SvIVX(SvRV(a)))) - (float128)SvIVX(b);
       return obj_ref;
    }

    if(SvPOK(b)) {
       char * p;
#ifdef _WIN32_BIZARRE_INFNAN
       int inf_or_nan = _win32_infnanstring(SvPV_nolen(b));
#endif

       NOK_POK_DUALVAR_CHECK , "overload_sub");}

#ifdef _WIN32_BIZARRE_INFNAN
       if(inf_or_nan) {
         if(inf_or_nan == 2) *ld = _get_nan();
         else {
           if(third == &PL_sv_yes) *ld = _get_inf(inf_or_nan) - *(INT2PTR(float128 *, SvIVX(SvRV(a))));
           else *ld = *(INT2PTR(float128 *, SvIVX(SvRV(a)))) - _get_inf(inf_or_nan);
         }
       }
       else {
         if(third == &PL_sv_yes) *ld = strtoflt128(SvPV_nolen(b), &p) - *(INT2PTR(float128 *, SvIVX(SvRV(a))));
         else *ld = *(INT2PTR(float128 *, SvIVX(SvRV(a)))) - strtoflt128(SvPV_nolen(b), &p);
         _nnum_inc(p);
       }
#else
       if(third == &PL_sv_yes) *ld = strtoflt128(SvPV_nolen(b), &p) - *(INT2PTR(float128 *, SvIVX(SvRV(a))));
       else *ld = *(INT2PTR(float128 *, SvIVX(SvRV(a)))) - strtoflt128(SvPV_nolen(b), &p);
       _nnum_inc(p);
#endif
       return obj_ref;
    }

    if(SvNOK(b)) {
#if defined(AVOID_INF_CAST)
       if(SvNVX(b) != 0.0L && SvNVX(b) == SvNVX(b) && SvNVX(b) / SvNVX(b) != SvNVX(b) / SvNVX(b)) {
         if(third == &PL_sv_yes) *ld = _get_inf(SvNVX(b) > 0 ? 1 : -1) - *(INT2PTR(float128 *, SvIVX(SvRV(a))));
         else *ld = *(INT2PTR(float128 *, SvIVX(SvRV(a)))) - _get_inf(SvNVX(b) > 0 ? 1 : -1);
         return obj_ref;
       }
#endif
       if(third == &PL_sv_yes) *ld = (float128)SvNVX(b) - *(INT2PTR(float128 *, SvIVX(SvRV(a))));
       else *ld = *(INT2PTR(float128 *, SvIVX(SvRV(a)))) - (float128)SvNVX(b);
       return obj_ref;
    }

    if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Float128")) {
        *ld = *(INT2PTR(float128 *, SvIVX(SvRV(a)))) - *(INT2PTR(float128 *, SvIVX(SvRV(b))));
        return obj_ref;
      }
      croak("Invalid object supplied to Math::Float128::_overload_sub function");
    }

    /*
    else {
      if(third == &PL_sv_yes) {
        *ld = *(INT2PTR(float128 *, SvIVX(SvRV(a)))) * -1.0L;
        return obj_ref;
      }
    }
    */

    croak("Invalid argument supplied to Math::Float128::_overload_sub function");

}

SV * _overload_div(pTHX_ SV * a, SV * b, SV * third) {
     float128 * ld;
     SV * obj_ref, * obj;

     Newx(ld, 1, float128);
     if(ld == NULL) croak("Failed to allocate memory in _overload_div function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Float128");

     sv_setiv(obj, INT2PTR(IV,ld));
     SvREADONLY_on(obj);

    if(SvUOK(b)) {
       if(third == &PL_sv_yes) *ld = (float128)SvUVX(b) / *(INT2PTR(float128 *, SvIVX(SvRV(a))));
       else *ld = *(INT2PTR(float128 *, SvIVX(SvRV(a)))) / (float128)SvUVX(b);
       return obj_ref;
    }

    if(SvIOK(b)) {
       if(third == &PL_sv_yes) *ld = (float128)SvIVX(b) / *(INT2PTR(float128 *, SvIVX(SvRV(a))));
       else *ld = *(INT2PTR(float128 *, SvIVX(SvRV(a)))) / (float128)SvIVX(b);
       return obj_ref;
    }

    if(SvPOK(b)) {
       char * p;
#ifdef _WIN32_BIZARRE_INFNAN
       int inf_or_nan = _win32_infnanstring(SvPV_nolen(b));
#endif

       NOK_POK_DUALVAR_CHECK , "overload_div");}

#ifdef _WIN32_BIZARRE_INFNAN
       if(inf_or_nan) {
         if(inf_or_nan == 2) *ld = _get_nan();
         else {
           if(third == &PL_sv_yes) *ld = _get_inf(inf_or_nan) / *(INT2PTR(float128 *, SvIVX(SvRV(a))));
           else *ld = *(INT2PTR(float128 *, SvIVX(SvRV(a)))) / _get_inf(inf_or_nan);
         }
       }
       else {
         if(third == &PL_sv_yes) *ld = strtoflt128(SvPV_nolen(b), &p) / *(INT2PTR(float128 *, SvIVX(SvRV(a))));
         else *ld = *(INT2PTR(float128 *, SvIVX(SvRV(a)))) / strtoflt128(SvPV_nolen(b), &p);
         _nnum_inc(p);
       }
#else
       if(third == &PL_sv_yes) *ld = strtoflt128(SvPV_nolen(b), &p) / *(INT2PTR(float128 *, SvIVX(SvRV(a))));
       else *ld = *(INT2PTR(float128 *, SvIVX(SvRV(a)))) / strtoflt128(SvPV_nolen(b), &p);
       _nnum_inc(p);
#endif
       return obj_ref;
    }

    if(SvNOK(b)) {
#if defined(AVOID_INF_CAST)
       if(SvNVX(b) != 0.0L && SvNVX(b) == SvNVX(b) && SvNVX(b) / SvNVX(b) != SvNVX(b) / SvNVX(b)) {
         if(third == &PL_sv_yes) *ld = _get_inf(SvNVX(b) > 0 ? 1 : -1) / *(INT2PTR(float128 *, SvIVX(SvRV(a))));
         else *ld = *(INT2PTR(float128 *, SvIVX(SvRV(a)))) / _get_inf(SvNVX(b) > 0 ? 1 : -1);
         return obj_ref;
       }
#endif
       if(third == &PL_sv_yes) *ld = (float128)SvNVX(b) / *(INT2PTR(float128 *, SvIVX(SvRV(a))));
       else *ld = *(INT2PTR(float128 *, SvIVX(SvRV(a)))) / (float128)SvNVX(b);
       return obj_ref;
    }

    if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Float128")) {
        *ld = *(INT2PTR(float128 *, SvIVX(SvRV(a)))) / *(INT2PTR(float128 *, SvIVX(SvRV(b))));
        return obj_ref;
      }
      croak("Invalid object supplied to Math::Float128::_overload_div function");
    }
    croak("Invalid argument supplied to Math::Float128::_overload_div function");
}

SV * _overload_equiv(pTHX_ SV * a, SV * b, SV * third) {

    if(SvUOK(b)) {
       if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) == (float128)SvUVX(b)) return newSViv(1);
        return newSViv(0);
    }

    if(SvIOK(b)) {
       if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) == (float128)SvIVX(b)) return newSViv(1);
        return newSViv(0);
    }

    if(SvPOK(b)) {
       char * p;
#ifdef _WIN32_BIZARRE_INFNAN
       int inf_or_nan = _win32_infnanstring(SvPV_nolen(b));
#endif

       NOK_POK_DUALVAR_CHECK , "overload_equiv");}

#ifdef _WIN32_BIZARRE_INFNAN
       if(inf_or_nan) {
         if(inf_or_nan == 2) return newSViv(0);
         else {
           if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) == _get_inf(inf_or_nan)) return newSViv(1);
           return newSViv(0);
         }
       }
       else {
         if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) == strtoflt128(SvPV_nolen(b), &p)) {
           _nnum_inc(p);
           return newSViv(1);
         }
         _nnum_inc(p);
         return newSViv(0);
       }
#else
       if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) == strtoflt128(SvPV_nolen(b), &p)) {
         _nnum_inc(p);
         return newSViv(1);
       }
       _nnum_inc(p);
       return newSViv(0);
#endif
    }

    if(SvNOK(b)) {
#if defined(AVOID_INF_CAST)
       if(SvNVX(b) != 0.0L && SvNVX(b) == SvNVX(b) && SvNVX(b) / SvNVX(b) != SvNVX(b) / SvNVX(b)) {
         if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) == _get_inf(SvNVX(b) > 0 ? 1 : -1))
           return newSViv(1);
         return newSViv(0);
       }
#endif
       if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) == (float128)SvNVX(b)) return newSViv(1);
        return newSViv(0);
    }

    if(sv_isobject(b)) {
      const char *h = HvNAME(SvSTASH(SvRV(b)));
      if(strEQ(h, "Math::Float128")) {
        if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) == *(INT2PTR(float128 *, SvIVX(SvRV(b))))) return newSViv(1);
        return newSViv(0);
      }
      croak("Invalid object supplied to Math::Float128::_overload_equiv function");
    }
    croak("Invalid argument supplied to Math::Float128::_overload_equiv function");
}

SV * _overload_not_equiv(pTHX_ SV * a, SV * b, SV * third) {

    if(SvUOK(b)) {
       if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) != (float128)SvUVX(b)) return newSViv(1);
        return newSViv(0);
    }

    if(SvIOK(b)) {
       if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) != (float128)SvIVX(b)) return newSViv(1);
        return newSViv(0);
    }

    if(SvPOK(b)) {
       char * p;
#ifdef _WIN32_BIZARRE_INFNAN
       int inf_or_nan = _win32_infnanstring(SvPV_nolen(b));
#endif

       NOK_POK_DUALVAR_CHECK , "overload_not_equiv");}

#ifdef _WIN32_BIZARRE_INFNAN
       if(inf_or_nan) {
         if(inf_or_nan == 2) return newSViv(1);
         else {
           if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) != _get_inf(inf_or_nan)) return newSViv(1);
           return newSViv(0);
         }
       }
       else {
         if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) != strtoflt128(SvPV_nolen(b), &p)) {
           _nnum_inc(p);
           return newSViv(1);
         }
         _nnum_inc(p);
         return newSViv(0);
       }
#else

       if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) != strtoflt128(SvPV_nolen(b), &p)) {
         _nnum_inc(p);
         return newSViv(1);
       }
       _nnum_inc(p);
       return newSViv(0);
#endif
    }

    if(SvNOK(b)) {
#if defined(AVOID_INF_CAST)
       if(SvNVX(b) != 0.0L && SvNVX(b) == SvNVX(b) && SvNVX(b) / SvNVX(b) != SvNVX(b) / SvNVX(b)) {
         if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) != _get_inf(SvNVX(b) > 0 ? 1 : -1))
           return newSViv(1);
         return newSViv(0);
       }
#endif
       if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) != (float128)SvNVX(b)) return newSViv(1);
        return newSViv(0);
    }

    if(sv_isobject(b)) {
      const char *h = HvNAME(SvSTASH(SvRV(b)));
      if(strEQ(h, "Math::Float128")) {
        if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) == *(INT2PTR(float128 *, SvIVX(SvRV(b))))) return newSViv(0);
        return newSViv(1);
      }
      croak("Invalid object supplied to Math::Float128::_overload_not_equiv function");
    }
    croak("Invalid argument supplied to Math::Float128::_overload_not_equiv function");
}

SV * _overload_true(pTHX_ SV * a, SV * b, SV * third) {

     if(_is_nan(*(INT2PTR(float128 *, SvIVX(SvRV(a)))))) return newSViv(0);
     if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) != 0.0Q) return newSViv(1);
     return newSViv(0);
}

SV * _overload_not(pTHX_ SV * a, SV * b, SV * third) {
     if(_is_nan(*(INT2PTR(float128 *, SvIVX(SvRV(a)))))) return newSViv(1);
     if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) != 0.0L) return newSViv(0);
     return newSViv(1);
}

SV * _overload_add_eq(pTHX_ SV * a, SV * b, SV * third) {

    SvREFCNT_inc(a);

    if(SvUOK(b)) {
       *(INT2PTR(float128 *, SvIVX(SvRV(a)))) += (float128)SvUVX(b);
        return a;
    }

    if(SvIOK(b)) {
       *(INT2PTR(float128 *, SvIVX(SvRV(a)))) += (float128)SvIVX(b);
        return a;
    }

    if(SvPOK(b)) {
       char * p;
#ifdef _WIN32_BIZARRE_INFNAN
       int inf_or_nan = _win32_infnanstring(SvPV_nolen(b));
#endif

       NOK_POK_DUALVAR_CHECK , "overload_add_eq");}

#ifdef _WIN32_BIZARRE_INFNAN

       if(inf_or_nan) {
         if(inf_or_nan == 2) {
           *(INT2PTR(float128 *, SvIVX(SvRV(a)))) = _get_nan();
           return a;
         }

         *(INT2PTR(float128 *, SvIVX(SvRV(a)))) += _get_inf(inf_or_nan);
         return a;
       }

       *(INT2PTR(float128 *, SvIVX(SvRV(a)))) += strtoflt128(SvPV_nolen(b), &p);
       _nnum_inc(p);
       return a;
#else

       *(INT2PTR(float128 *, SvIVX(SvRV(a)))) += strtoflt128(SvPV_nolen(b), &p);
       _nnum_inc(p);
       return a;
#endif
    }

    if(SvNOK(b)) {
#if defined(AVOID_INF_CAST)
       if(SvNVX(b) != 0.0L && SvNVX(b) == SvNVX(b) && SvNVX(b) / SvNVX(b) != SvNVX(b) / SvNVX(b)) {
         *(INT2PTR(float128 *, SvIVX(SvRV(a)))) += _get_inf(SvNVX(b) > 0 ? 1 : -1);
         return a;
       }
#endif
       *(INT2PTR(float128 *, SvIVX(SvRV(a)))) += (float128)SvNVX(b);
        return a;
    }

    if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Float128")) {
        *(INT2PTR(float128 *, SvIVX(SvRV(a)))) += *(INT2PTR(float128 *, SvIVX(SvRV(b))));
        return a;
      }
      SvREFCNT_dec(a);
      croak("Invalid object supplied to Math::Float128::_overload_add_eq function");
    }
    SvREFCNT_dec(a);
    croak("Invalid argument supplied to Math::Float128::_overload_add_eq function");
}

SV * _overload_mul_eq(pTHX_ SV * a, SV * b, SV * third) {

    SvREFCNT_inc(a);

    if(SvUOK(b)) {
       *(INT2PTR(float128 *, SvIVX(SvRV(a)))) *= (float128)SvUVX(b);
        return a;
    }

    if(SvIOK(b)) {
       *(INT2PTR(float128 *, SvIVX(SvRV(a)))) *= (float128)SvIVX(b);
        return a;
    }

    if(SvPOK(b)) {
       char * p;
#ifdef _WIN32_BIZARRE_INFNAN
       int inf_or_nan = _win32_infnanstring(SvPV_nolen(b));
#endif

       NOK_POK_DUALVAR_CHECK , "overload_mul_eq");}

#ifdef _WIN32_BIZARRE_INFNAN

       if(inf_or_nan) {
         if(inf_or_nan == 2) {
           *(INT2PTR(float128 *, SvIVX(SvRV(a)))) = _get_nan();
           return a;
         }

         *(INT2PTR(float128 *, SvIVX(SvRV(a)))) *= _get_inf(inf_or_nan);
         return a;
       }

       *(INT2PTR(float128 *, SvIVX(SvRV(a)))) *= strtoflt128(SvPV_nolen(b), &p);
       _nnum_inc(p);
       return a;
#else

       *(INT2PTR(float128 *, SvIVX(SvRV(a)))) *= strtoflt128(SvPV_nolen(b), &p);
       _nnum_inc(p);
       return a;
#endif
    }

    if(SvNOK(b)) {
#if defined(AVOID_INF_CAST)
       if(SvNVX(b) != 0.0L && SvNVX(b) == SvNVX(b) && SvNVX(b) / SvNVX(b) != SvNVX(b) / SvNVX(b)) {
         *(INT2PTR(float128 *, SvIVX(SvRV(a)))) *= _get_inf(SvNVX(b) > 0 ? 1 : -1);
         return a;
       }
#endif
       *(INT2PTR(float128 *, SvIVX(SvRV(a)))) *= (float128)SvNVX(b);
        return a;
    }

    if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Float128")) {
        *(INT2PTR(float128 *, SvIVX(SvRV(a)))) *= *(INT2PTR(float128 *, SvIVX(SvRV(b))));
        return a;
      }
      SvREFCNT_dec(a);
      croak("Invalid object supplied to Math::Float128::_overload_mul_eq function");
    }
    SvREFCNT_dec(a);
    croak("Invalid argument supplied to Math::Float128::_overload_mul_eq function");
}

SV * _overload_sub_eq(pTHX_ SV * a, SV * b, SV * third) {

    SvREFCNT_inc(a);

    if(SvUOK(b)) {
       *(INT2PTR(float128 *, SvIVX(SvRV(a)))) -= (float128)SvUVX(b);
        return a;
    }

    if(SvIOK(b)) {
       *(INT2PTR(float128 *, SvIVX(SvRV(a)))) -= (float128)SvIVX(b);
        return a;
    }

    if(SvPOK(b)) {
       char * p;
#ifdef _WIN32_BIZARRE_INFNAN
       int inf_or_nan = _win32_infnanstring(SvPV_nolen(b));
#endif

       NOK_POK_DUALVAR_CHECK , "overload_sub_eq");}

#ifdef _WIN32_BIZARRE_INFNAN

       if(inf_or_nan) {
         if(inf_or_nan == 2) {
           *(INT2PTR(float128 *, SvIVX(SvRV(a)))) = _get_nan();
           return a;
         }

         *(INT2PTR(float128 *, SvIVX(SvRV(a)))) -= _get_inf(inf_or_nan);
         return a;
       }

       *(INT2PTR(float128 *, SvIVX(SvRV(a)))) -= strtoflt128(SvPV_nolen(b), &p);
       _nnum_inc(p);
       return a;
#else

       *(INT2PTR(float128 *, SvIVX(SvRV(a)))) -= strtoflt128(SvPV_nolen(b), &p);
       _nnum_inc(p);
       return a;
#endif
    }


    if(SvNOK(b)) {
#if defined(AVOID_INF_CAST)
       if(SvNVX(b) != 0.0L && SvNVX(b) == SvNVX(b) && SvNVX(b) / SvNVX(b) != SvNVX(b) / SvNVX(b)) {
         *(INT2PTR(float128 *, SvIVX(SvRV(a)))) -= _get_inf(SvNVX(b) > 0 ? 1 : -1);
         return a;
       }
#endif
       *(INT2PTR(float128 *, SvIVX(SvRV(a)))) -= (float128)SvNVX(b);
        return a;
    }

    if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Float128")) {
        *(INT2PTR(float128 *, SvIVX(SvRV(a)))) -= *(INT2PTR(float128 *, SvIVX(SvRV(b))));
        return a;
      }
      SvREFCNT_dec(a);
      croak("Invalid object supplied to Math::Float128::_overload_sub_eq function");
    }
    SvREFCNT_dec(a);
    croak("Invalid argument supplied to Math::Float128::_overload_sub_eq function");
}

SV * _overload_div_eq(pTHX_ SV * a, SV * b, SV * third) {

    SvREFCNT_inc(a);

    if(SvUOK(b)) {
       *(INT2PTR(float128 *, SvIVX(SvRV(a)))) /= (float128)SvUVX(b);
        return a;
    }

    if(SvIOK(b)) {
       *(INT2PTR(float128 *, SvIVX(SvRV(a)))) /= (float128)SvIVX(b);
        return a;
    }

    if(SvPOK(b)) {
       char * p;
#ifdef _WIN32_BIZARRE_INFNAN
       int inf_or_nan = _win32_infnanstring(SvPV_nolen(b));
#endif

       NOK_POK_DUALVAR_CHECK , "overload_div_eq");}

#ifdef _WIN32_BIZARRE_INFNAN

       if(inf_or_nan) {
         if(inf_or_nan == 2) {
           *(INT2PTR(float128 *, SvIVX(SvRV(a)))) = _get_nan();
           return a;
         }

         *(INT2PTR(float128 *, SvIVX(SvRV(a)))) /= _get_inf(inf_or_nan);
         return a;
       }

       *(INT2PTR(float128 *, SvIVX(SvRV(a)))) /= strtoflt128(SvPV_nolen(b), &p);
       _nnum_inc(p);
       return a;
#else

       *(INT2PTR(float128 *, SvIVX(SvRV(a)))) /= strtoflt128(SvPV_nolen(b), &p);
       _nnum_inc(p);
       return a;
#endif
    }

    if(SvNOK(b)) {
#if defined(AVOID_INF_CAST)
       if(SvNVX(b) != 0.0L && SvNVX(b) == SvNVX(b) && SvNVX(b) / SvNVX(b) != SvNVX(b) / SvNVX(b)) {
         *(INT2PTR(float128 *, SvIVX(SvRV(a)))) /= _get_inf(SvNVX(b) > 0 ? 1 : -1);
         return a;
       }
#endif
       *(INT2PTR(float128 *, SvIVX(SvRV(a)))) /= (float128)SvNVX(b);
        return a;
    }

    if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Float128")) {
        *(INT2PTR(float128 *, SvIVX(SvRV(a)))) /= *(INT2PTR(float128 *, SvIVX(SvRV(b))));
        return a;
      }
      SvREFCNT_dec(a);
      croak("Invalid object supplied to Math::Float128::_overload_div_eq function");
    }
    SvREFCNT_dec(a);
    croak("Invalid argument supplied to Math::Float128::_overload_div_eq function");
}

SV * _overload_lt(pTHX_ SV * a, SV * b, SV * third) {

    if(SvUOK(b)) {
      if(third == &PL_sv_yes) {
        if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) > (float128)SvUVX(b)) return newSViv(1);
        return newSViv(0);
      }
      if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) < (float128)SvUVX(b)) return newSViv(1);
      return newSViv(0);
    }

    if(SvIOK(b)) {
      if(third == &PL_sv_yes) {
        if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) > (float128)SvIVX(b)) return newSViv(1);
        return newSViv(0);
      }
      if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) < (float128)SvIVX(b)) return newSViv(1);
      return newSViv(0);
    }

    if(SvPOK(b)) {
      char * p;
#ifdef _WIN32_BIZARRE_INFNAN
       int inf_or_nan = _win32_infnanstring(SvPV_nolen(b));
#endif

      NOK_POK_DUALVAR_CHECK , "overload_lt");}

#ifdef _WIN32_BIZARRE_INFNAN
      if(inf_or_nan) {
        if(inf_or_nan == 2) return newSViv(0);
        if(third == &PL_sv_yes) {
          if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) > _get_inf(inf_or_nan)) return newSViv(1);
          return newSViv(0);
        }
        if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) < _get_inf(inf_or_nan)) return newSViv(1);
        return newSViv(0);
      }
      if(third == &PL_sv_yes) {
        if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) > strtoflt128(SvPV_nolen(b), &p)) {
          _nnum_inc(p);
          return newSViv(1);
        }
        _nnum_inc(p);
        return newSViv(0);
      }

      if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) < strtoflt128(SvPV_nolen(b), &p)) {
        _nnum_inc(p);
        return newSViv(1);
      }
      _nnum_inc(p);
      return newSViv(0);
#else

      if(third == &PL_sv_yes) {
        if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) > strtoflt128(SvPV_nolen(b), &p)) {
          _nnum_inc(p);
          return newSViv(1);
        }
        _nnum_inc(p);
        return newSViv(0);
      }

      if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) < strtoflt128(SvPV_nolen(b), &p)) {
        _nnum_inc(p);
        return newSViv(1);
      }
      _nnum_inc(p);
      return newSViv(0);
#endif
    }

    if(SvNOK(b)) {
#if defined(AVOID_INF_CAST)
       if(SvNVX(b) != 0.0L && SvNVX(b) == SvNVX(b) && SvNVX(b) / SvNVX(b) != SvNVX(b) / SvNVX(b)) {
         if(third == &PL_sv_yes) {
           if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) > _get_inf(SvNVX(b) > 0 ? 1 : -1))
             return newSViv(1);
           return newSViv(0);
         }
         if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) < _get_inf(SvNVX(b) > 0 ? 1 : -1))
           return newSViv(1);
         return newSViv(0);
       }
#endif
      if(third == &PL_sv_yes) {
        if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) > (float128)SvNVX(b)) return newSViv(1);
        return newSViv(0);
      }
      if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) < (float128)SvNVX(b)) return newSViv(1);
      return newSViv(0);
    }

    if(sv_isobject(b)) {
      const char *h = HvNAME(SvSTASH(SvRV(b)));
      if(strEQ(h, "Math::Float128")) {
        if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) < *(INT2PTR(float128 *, SvIVX(SvRV(b))))) return newSViv(1);
        return newSViv(0);
      }
      croak("Invalid object supplied to Math::Float128::_overload_lt function");
    }
    croak("Invalid argument supplied to Math::Float128::_overload_lt function");
}

SV * _overload_gt(pTHX_ SV * a, SV * b, SV * third) {

    if(SvUOK(b)) {
      if(third == &PL_sv_yes) {
        if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) < (float128)SvUVX(b)) return newSViv(1);
        return newSViv(0);
      }
      if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) > (float128)SvUVX(b)) return newSViv(1);
      return newSViv(0);
    }

    if(SvIOK(b)) {
      if(third == &PL_sv_yes) {
        if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) < (float128)SvIVX(b)) return newSViv(1);
        return newSViv(0);
      }
      if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) > (float128)SvIVX(b)) return newSViv(1);
      return newSViv(0);
    }

    if(SvPOK(b)) {
      char * p;
#ifdef _WIN32_BIZARRE_INFNAN
       int inf_or_nan = _win32_infnanstring(SvPV_nolen(b));
#endif

      NOK_POK_DUALVAR_CHECK , "overload_gt");}

#ifdef _WIN32_BIZARRE_INFNAN
      if(inf_or_nan) {
        if(inf_or_nan == 2) return newSViv(0);
        if(third == &PL_sv_yes) {
          if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) < _get_inf(inf_or_nan)) return newSViv(1);
          return newSViv(0);
        }
        if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) > _get_inf(inf_or_nan)) return newSViv(1);
        return newSViv(0);
      }
      if(third == &PL_sv_yes) {
        if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) < strtoflt128(SvPV_nolen(b), &p)) {
          _nnum_inc(p);
          return newSViv(1);
        }
        _nnum_inc(p);
        return newSViv(0);
      }

      if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) > strtoflt128(SvPV_nolen(b), &p)) {
        _nnum_inc(p);
        return newSViv(1);
      }
      _nnum_inc(p);
      return newSViv(0);
#else
      if(third == &PL_sv_yes) {
        if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) < strtoflt128(SvPV_nolen(b), &p)) {
          _nnum_inc(p);
          return newSViv(1);
        }
        _nnum_inc(p);
        return newSViv(0);
      }

      if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) > strtoflt128(SvPV_nolen(b), &p)) {
        _nnum_inc(p);
        return newSViv(1);
      }
      _nnum_inc(p);
      return newSViv(0);
#endif
    }

    if(SvNOK(b)) {
#if defined(AVOID_INF_CAST)
       if(SvNVX(b) != 0.0L && SvNVX(b) == SvNVX(b) && SvNVX(b) / SvNVX(b) != SvNVX(b) / SvNVX(b)) {
         if(third == &PL_sv_yes) {
           if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) < _get_inf(SvNVX(b) > 0 ? 1 : -1))
             return newSViv(1);
           return newSViv(0);
         }
         if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) > _get_inf(SvNVX(b) > 0 ? 1 : -1))
           return newSViv(1);
         return newSViv(0);
       }
#endif
      if(third == &PL_sv_yes) {
        if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) < (float128)SvNVX(b)) return newSViv(1);
        return newSViv(0);
      }
      if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) > (float128)SvNVX(b)) return newSViv(1);
      return newSViv(0);
    }

    if(sv_isobject(b)) {
      const char *h = HvNAME(SvSTASH(SvRV(b)));
      if(strEQ(h, "Math::Float128")) {
        if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) > *(INT2PTR(float128 *, SvIVX(SvRV(b))))) return newSViv(1);
        return newSViv(0);
      }
      croak("Invalid object supplied to Math::Float128::_overload_gt function");
    }
     croak("Invalid argument supplied to Math::Float128::_overload_gt function");
}

SV * _overload_lte(pTHX_ SV * a, SV * b, SV * third) {

    if(SvUOK(b)) {
      if(third == &PL_sv_yes) {
        if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) >= (float128)SvUVX(b)) return newSViv(1);
        return newSViv(0);
      }
      if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) <= (float128)SvUVX(b)) return newSViv(1);
      return newSViv(0);
    }

    if(SvIOK(b)) {
      if(third == &PL_sv_yes) {
        if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) >= (float128)SvIVX(b)) return newSViv(1);
        return newSViv(0);
      }
      if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) <= (float128)SvIVX(b)) return newSViv(1);
      return newSViv(0);
    }

    if(SvPOK(b)) {
      char * p;
#ifdef _WIN32_BIZARRE_INFNAN
       int inf_or_nan = _win32_infnanstring(SvPV_nolen(b));
#endif

      NOK_POK_DUALVAR_CHECK , "overload_lte");}

#ifdef _WIN32_BIZARRE_INFNAN
      if(inf_or_nan) {
        if(inf_or_nan == 2) return newSViv(0);
        if(third == &PL_sv_yes) {
          if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) >= _get_inf(inf_or_nan)) return newSViv(1);
          return newSViv(0);
        }
        if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) <= _get_inf(inf_or_nan)) return newSViv(1);
        return newSViv(0);
      }
      if(third == &PL_sv_yes) {
        if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) >= strtoflt128(SvPV_nolen(b), &p)) {
          _nnum_inc(p);
          return newSViv(1);
        }
        _nnum_inc(p);
        return newSViv(0);
      }

      if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) <= strtoflt128(SvPV_nolen(b), &p)) {
        _nnum_inc(p);
        return newSViv(1);
      }
      _nnum_inc(p);
      return newSViv(0);
#else
      if(third == &PL_sv_yes) {
        if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) >= strtoflt128(SvPV_nolen(b), &p)) {
          _nnum_inc(p);
          return newSViv(1);
        }
        _nnum_inc(p);
        return newSViv(0);
      }
      if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) <= strtoflt128(SvPV_nolen(b), &p)) {
        _nnum_inc(p);
        return newSViv(1);
      }
      _nnum_inc(p);
      return newSViv(0);
#endif
    }

    if(SvNOK(b)) {
#if defined(AVOID_INF_CAST)
       if(SvNVX(b) != 0.0L && SvNVX(b) == SvNVX(b) && SvNVX(b) / SvNVX(b) != SvNVX(b) / SvNVX(b)) {
         if(third == &PL_sv_yes) {
           if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) >= _get_inf(SvNVX(b) > 0 ? 1 : -1))
             return newSViv(1);
           return newSViv(0);
         }
         if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) <= _get_inf(SvNVX(b) > 0 ? 1 : -1))
           return newSViv(1);
         return newSViv(0);
       }
#endif
      if(third == &PL_sv_yes) {
        if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) >= (float128)SvNVX(b)) return newSViv(1);
        return newSViv(0);
      }
      if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) <= (float128)SvNVX(b)) return newSViv(1);
      return newSViv(0);
    }

    if(sv_isobject(b)) {
      const char *h = HvNAME(SvSTASH(SvRV(b)));
      if(strEQ(h, "Math::Float128")) {
        if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) <= *(INT2PTR(float128 *, SvIVX(SvRV(b))))) return newSViv(1);
        return newSViv(0);
      }
      croak("Invalid object supplied to Math::Float128::_overload_lte function");
    }
    croak("Invalid argument supplied to Math::Float128::_overload_lte function");
}

SV * _overload_gte(pTHX_ SV * a, SV * b, SV * third) {

    if(SvUOK(b)) {
      if(third == &PL_sv_yes) {
        if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) <= (float128)SvUVX(b)) return newSViv(1);
        return newSViv(0);
      }
      if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) >= (float128)SvUVX(b)) return newSViv(1);
      return newSViv(0);
    }

    if(SvIOK(b)) {
      if(third == &PL_sv_yes) {
        if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) <= (float128)SvIVX(b)) return newSViv(1);
        return newSViv(0);
      }
      if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) >= (float128)SvIVX(b)) return newSViv(1);
      return newSViv(0);
    }

    if(SvPOK(b)) {
      char * p;
#ifdef _WIN32_BIZARRE_INFNAN
       int inf_or_nan = _win32_infnanstring(SvPV_nolen(b));
#endif

      NOK_POK_DUALVAR_CHECK , "overload_gte");}

#ifdef _WIN32_BIZARRE_INFNAN
      if(inf_or_nan) {
        if(inf_or_nan == 2) return newSViv(0);
        if(third == &PL_sv_yes) {
          if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) <= _get_inf(inf_or_nan)) return newSViv(1);
          return newSViv(0);
        }
        if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) >= _get_inf(inf_or_nan)) return newSViv(1);
        return newSViv(0);
      }
      if(third == &PL_sv_yes) {
        if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) <= strtoflt128(SvPV_nolen(b), &p)) {
          _nnum_inc(p);
          return newSViv(1);
        }
        _nnum_inc(p);
        return newSViv(0);
      }

      if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) >= strtoflt128(SvPV_nolen(b), &p)) {
        _nnum_inc(p);
        return newSViv(1);
      }
      _nnum_inc(p);
      return newSViv(0);
#else

      if(third == &PL_sv_yes) {
        if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) <= strtoflt128(SvPV_nolen(b), &p)) {
          _nnum_inc(p);
          return newSViv(1);
        }
        _nnum_inc(p);
        return newSViv(0);
      }

      if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) >= strtoflt128(SvPV_nolen(b), &p)) {
        _nnum_inc(p);
        return newSViv(1);
      }
      _nnum_inc(p);
      return newSViv(0);
#endif
    }


    if(SvNOK(b)) {
#if defined(AVOID_INF_CAST)
       if(SvNVX(b) != 0.0L && SvNVX(b) == SvNVX(b) && SvNVX(b) / SvNVX(b) != SvNVX(b) / SvNVX(b)) {
         if(third == &PL_sv_yes) {
           if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) <= _get_inf(SvNVX(b) > 0 ? 1 : -1))
             return newSViv(1);
           return newSViv(0);
         }
         if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) >= _get_inf(SvNVX(b) > 0 ? 1 : -1))
           return newSViv(1);
         return newSViv(0);
       }
#endif
      if(third == &PL_sv_yes) {
        if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) <= (float128)SvNVX(b)) return newSViv(1);
        return newSViv(0);
      }
      if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) >= (float128)SvNVX(b)) return newSViv(1);
      return newSViv(0);
    }

    if(sv_isobject(b)) {
      const char *h = HvNAME(SvSTASH(SvRV(b)));
      if(strEQ(h, "Math::Float128")) {
        if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) >= *(INT2PTR(float128 *, SvIVX(SvRV(b))))) return newSViv(1);
        return newSViv(0);
      }
      croak("Invalid object supplied to Math::Float128::_overload_gte function");
    }
    croak("Invalid argument supplied to Math::Float128::_overload_gte function");
}

SV * _overload_spaceship(pTHX_ SV * a, SV * b, SV * third) {
    int reversal = 1;
    if(third == &PL_sv_yes) reversal = -1;

    if(SvUOK(b)) {
       if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) == (float128)SvUVX(b)) return newSViv( 0 * reversal);
       if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) <  (float128)SvUVX(b)) return newSViv(-1 * reversal);
       if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) >  (float128)SvUVX(b)) return newSViv( 1 * reversal);
       return &PL_sv_undef; /* it's a nan */
    }

    if(SvIOK(b)) {
       if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) == (float128)SvIVX(b)) return newSViv( 0);
       if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) <  (float128)SvIVX(b)) return newSViv(-1 * reversal);
       if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) >  (float128)SvIVX(b)) return newSViv( 1 * reversal);
       return &PL_sv_undef; /* it's a nan */
    }

    if(SvPOK(b)) {
       char *p;
#ifdef _WIN32_BIZARRE_INFNAN
       int inf_or_nan = _win32_infnanstring(SvPV_nolen(b));
#endif

       NOK_POK_DUALVAR_CHECK , "overload_spaceship");}

#ifdef _WIN32_BIZARRE_INFNAN

       if(inf_or_nan) {
         if(inf_or_nan == 2) return &PL_sv_undef;
         if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) == _get_inf(inf_or_nan))
           return newSViv(0);
         if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) < _get_inf(inf_or_nan))
           return newSViv(-1 * reversal);
         return newSViv(reversal);
       }

       if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) == strtoflt128(SvPV_nolen(b), &p)) {
         _nnum_inc(p);
         return newSViv( 0);
       }
       if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) <  strtoflt128(SvPV_nolen(b), &p)) {
         _nnum_inc(p);
         return newSViv(-1 * reversal);
       }
       if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) >  strtoflt128(SvPV_nolen(b), &p)) {
         _nnum_inc(p);
         return newSViv(reversal);
       }
       return &PL_sv_undef; /* it's a nan */
#else
       if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) == strtoflt128(SvPV_nolen(b), &p)) {
         _nnum_inc(p);
         return newSViv( 0);
       }
       if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) <  strtoflt128(SvPV_nolen(b), &p)) {
         _nnum_inc(p);
         return newSViv(-1 * reversal);
       }
       if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) >  strtoflt128(SvPV_nolen(b), &p)) {
         _nnum_inc(p);
         return newSViv(reversal);
       }
       return &PL_sv_undef; /* it's a nan */
#endif
    }

    if(SvNOK(b)) {
#if defined(AVOID_INF_CAST)
       if(SvNVX(b) != 0.0L && SvNVX(b) == SvNVX(b) && SvNVX(b) / SvNVX(b) != SvNVX(b) / SvNVX(b)) {
         if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) == _get_inf(SvNVX(b) > 0 ? 1 : -1))
           return newSViv(0);
         if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) < _get_inf(SvNVX(b) > 0 ? 1 : -1))
           return newSViv(-1 * reversal);
         if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) > _get_inf(SvNVX(b) > 0 ? 1 : -1))
           return newSViv(reversal);
       }
#endif
       if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) == (float128)SvNVX(b)) return newSViv( 0);
       if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) <  (float128)SvNVX(b)) return newSViv(-1 * reversal);
       if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) >  (float128)SvNVX(b)) return newSViv(reversal);
       return &PL_sv_undef; /* it's a nan */
    }

    if(sv_isobject(b)) {
      const char *h = HvNAME(SvSTASH(SvRV(b)));
      if(strEQ(h, "Math::Float128")) {
        if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) < *(INT2PTR(float128 *, SvIVX(SvRV(b))))) return newSViv(-1);
        if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) > *(INT2PTR(float128 *, SvIVX(SvRV(b))))) return newSViv(1);
        if(*(INT2PTR(float128 *, SvIVX(SvRV(a)))) == *(INT2PTR(float128 *, SvIVX(SvRV(b))))) return newSViv(0);
        return &PL_sv_undef; /* it's a nan */
      }
      croak("Invalid object supplied to Math::Float128::_overload_spaceship function");
    }
    croak("Invalid argument supplied to Math::Float128::_overload_spaceship function");
}

SV * _overload_copy(pTHX_ SV * a, SV * b, SV * third) {

     float128 * ld;
     SV * obj_ref, * obj;

     Newx(ld, 1, float128);
     if(ld == NULL) croak("Failed to allocate memory in _overload_copy function");

     *ld = *(INT2PTR(float128 *, SvIVX(SvRV(a))));

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Float128");
     sv_setiv(obj, INT2PTR(IV,ld));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * F128toF128(pTHX_ SV * a) {
     float128 * f;
     SV * obj_ref, * obj;

     if(sv_isobject(a)) {
       const char *h = HvNAME(SvSTASH(SvRV(a)));
       if(strEQ(h, "Math::Float128")) {

         Newx(f, 1, float128);
         if(f == NULL) croak("Failed to allocate memory in F128toF128 function");

         *f = *(INT2PTR(float128 *, SvIVX(SvRV(a))));

         obj_ref = newSV(0);
         obj = newSVrv(obj_ref, "Math::Float128");
         sv_setiv(obj, INT2PTR(IV,f));
         SvREADONLY_on(obj);
         return obj_ref;
       }
       croak("Invalid object supplied to Math::Float128::F128toF128 function");
     }
     croak("Invalid argument supplied to Math::Float128::F128toF128 function");
}

void fromF128(pTHX_ float128 * f, SV * a) {

     if(sv_isobject(a)) {
       const char *h = HvNAME(SvSTASH(SvRV(a)));
       if(strEQ(h, "Math::Float128")) {

         *f = *(INT2PTR(float128 *, SvIVX(SvRV(a))));
       }
       else croak("Invalid object supplied to Math::Float128::fromF128 function");
     }
     else croak("Invalid argument supplied to Math::Float128::fromF128 function");
}

SV * _itsa(pTHX_ SV * a) {
     if(SvUOK(a)) return newSVuv(1);
     if(SvIOK(a)) return newSVuv(2);
     if(SvPOK(a)) return newSVuv(4);
     if(SvNOK(a)) return newSVuv(3);
     if(sv_isobject(a)) {
       const char *h = HvNAME(SvSTASH(SvRV(a)));
       if(strEQ(h, "Math::Float128")) return newSVuv(113);
     }
     return newSVuv(0);
}

SV * _overload_abs(pTHX_ SV * a, SV * b, SV * third) {

     float128 * f;
     SV * obj_ref, * obj;

     Newx(f, 1, float128);
     if(f == NULL) croak("Failed to allocate memory in _overload_abs function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Float128");

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);

     *f = fabsq(*(INT2PTR(float128 *, SvIVX(SvRV(a)))));
     return obj_ref;
}

SV * _overload_int(pTHX_ SV * a, SV * b, SV * third) {

     float128 * f;
     SV * obj_ref, * obj;

     Newx(f, 1, float128);
     if(f == NULL) croak("Failed to allocate memory in _overload_int function");

     *f = *(INT2PTR(float128 *, SvIVX(SvRV(a))));

     if(*f < 0.0Q) *f = ceilq(*f);
     else *f = floorq(*f);

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Float128");
     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * _overload_sqrt(pTHX_ SV * a, SV * b, SV * third) {

     float128 * f;
     SV * obj_ref, * obj;

     Newx(f, 1, float128);
     if(f == NULL) croak("Failed to allocate memory in _overload_sqrt function");

     *f = sqrtq(*(INT2PTR(float128 *, SvIVX(SvRV(a)))));

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Float128");
     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * _overload_log(pTHX_ SV * a, SV * b, SV * third) {

     float128 * f;
     SV * obj_ref, * obj;

     Newx(f, 1, float128);
     if(f == NULL) croak("Failed to allocate memory in _overload_log function");

     *f = logq(*(INT2PTR(float128 *, SvIVX(SvRV(a)))));


     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Float128");
     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * _overload_exp(pTHX_ SV * a, SV * b, SV * third) {

     float128 * f;
     SV * obj_ref, * obj;

     Newx(f, 1, float128);
     if(f == NULL) croak("Failed to allocate memory in _overload_exp function");

#if defined(__MINGW64_VERSION_MAJOR) && __MINGW64_VERSION_MAJOR < 4  /* avoid calling expq() as it's buggy */
     *f = powq(M_Eq, *(INT2PTR(float128 *, SvIVX(SvRV(a)))));
#else
     *f = expq(*(INT2PTR(float128 *, SvIVX(SvRV(a)))));
#endif


     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Float128");
     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * _overload_sin(pTHX_ SV * a, SV * b, SV * third) {

     float128 * f;
     SV * obj_ref, * obj;

     Newx(f, 1, float128);
     if(f == NULL) croak("Failed to allocate memory in _overload_sin function");

     *f = sinq(*(INT2PTR(float128 *, SvIVX(SvRV(a)))));


     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Float128");
     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * _overload_cos(pTHX_ SV * a, SV * b, SV * third) {

     float128 * f;
     SV * obj_ref, * obj;

     Newx(f, 1, float128);
     if(f == NULL) croak("Failed to allocate memory in _overload_cos function");

     *f = cosq(*(INT2PTR(float128 *, SvIVX(SvRV(a)))));


     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Float128");
     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * _overload_atan2(pTHX_ SV * a, SV * b, SV * third) {

     float128 * f;
     SV * obj_ref, * obj;

     Newx(f, 1, float128);
     if(f == NULL) croak("Failed to allocate memory in _overload_atan2 function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Float128");
     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);

     if(SvUOK(b)) {
       if(third == &PL_sv_yes)
            *f = atan2q((float128)SvUVX(b), *(INT2PTR(float128 *, SvIVX(SvRV(a)))));
       else *f = atan2q(*(INT2PTR(float128 *, SvIVX(SvRV(a)))), (float128)SvUVX(b));
       return obj_ref;
     }

     if(SvIOK(b)) {
       if(third == &PL_sv_yes)
            *f = atan2q((float128)SvIVX(b), *(INT2PTR(float128 *, SvIVX(SvRV(a)))));
       else *f = atan2q(*(INT2PTR(float128 *, SvIVX(SvRV(a)))), (float128)SvIVX(b));
       return obj_ref;
     }

     if(SvPOK(b)) {
       char * p;
#ifdef _WIN32_BIZARRE_INFNAN
       int inf_or_nan = _win32_infnanstring(SvPV_nolen(b));
#endif

       NOK_POK_DUALVAR_CHECK , "overload_atan2");}

#ifdef _WIN32_BIZARRE_INFNAN

       if(inf_or_nan) {
         if(inf_or_nan == 2) {
           if(third == &PL_sv_yes)
                *f = atan2q(_get_nan(), *(INT2PTR(float128 *, SvIVX(SvRV(a)))));
           else *f = atan2q(*(INT2PTR(float128 *, SvIVX(SvRV(a)))), _get_nan());
         }
         else {
           if(third == &PL_sv_yes)
                *f = atan2q(_get_inf(inf_or_nan), *(INT2PTR(float128 *, SvIVX(SvRV(a)))));
           else *f = atan2q(*(INT2PTR(float128 *, SvIVX(SvRV(a)))), _get_inf(inf_or_nan));
         }
       }
       else {
         if(third == &PL_sv_yes)
              *f = atan2q(strtoflt128(SvPV_nolen(b), &p), *(INT2PTR(float128 *, SvIVX(SvRV(a)))));
         else *f = atan2q(*(INT2PTR(float128 *, SvIVX(SvRV(a)))), strtoflt128(SvPV_nolen(b), &p));
         _nnum_inc(p);
         return obj_ref;
       }
#else
       if(third == &PL_sv_yes)
            *f = atan2q(strtoflt128(SvPV_nolen(b), &p), *(INT2PTR(float128 *, SvIVX(SvRV(a)))));
       else *f = atan2q(*(INT2PTR(float128 *, SvIVX(SvRV(a)))), strtoflt128(SvPV_nolen(b), &p));
       _nnum_inc(p);
       return obj_ref;
#endif
     }

     if(SvNOK(b)) {
#if defined(AVOID_INF_CAST)
       if(SvNVX(b) != 0.0L && SvNVX(b) == SvNVX(b) && SvNVX(b) / SvNVX(b) != SvNVX(b) / SvNVX(b)) {
         if(third == &PL_sv_yes)
              *f = atan2q(_get_inf(SvNVX(b) > 0 ? 1 : -1), *(INT2PTR(float128 *, SvIVX(SvRV(a)))));
         else *f = atan2q(*(INT2PTR(float128 *, SvIVX(SvRV(a)))), _get_inf(SvNVX(b) > 0 ? 1 : -1));
         return obj_ref;
       }
#endif
       if(third == &PL_sv_yes)
            *f = atan2q((float128)SvNVX(b), *(INT2PTR(float128 *, SvIVX(SvRV(a)))));
       else *f = atan2q(*(INT2PTR(float128 *, SvIVX(SvRV(a)))), (float128)SvNVX(b));
       return obj_ref;
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Float128")) {
         *f = atan2q(*(INT2PTR(float128 *, SvIVX(SvRV(a)))), *(INT2PTR(float128 *, SvIVX(SvRV(b)))));
         return obj_ref;
       }
       croak("Invalid object supplied to Math::Float128::_overload_atan2 function");
     }
     croak("Invalid argument supplied to Math::Float128::_overload_atan2 function");
}

SV * _overload_inc(pTHX_ SV * a, SV * b, SV * third) {

     SvREFCNT_inc(a);

     *(INT2PTR(float128 *, SvIVX(SvRV(a)))) += 1.0Q;

     return a;
}

SV * _overload_dec(pTHX_ SV * a, SV * b, SV * third) {

     SvREFCNT_inc(a);

     *(INT2PTR(float128 *, SvIVX(SvRV(a)))) -= 1.0Q;

     return a;
}

SV * _overload_pow(pTHX_ SV * a, SV * b, SV * third) {

     float128 * f;
     SV * obj_ref, * obj;

     Newx(f, 1, float128);
     if(f == NULL) croak("Failed to allocate memory in _overload_pow function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Float128");
     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);

     if(SvUOK(b)) {
       if(third == &PL_sv_yes)
            *f = powq((float128)SvUVX(b), *(INT2PTR(float128 *, SvIVX(SvRV(a)))));
       else *f = powq(*(INT2PTR(float128 *, SvIVX(SvRV(a)))), (float128)SvUVX(b));
       return obj_ref;
     }

     if(SvIOK(b)) {
       if(third == &PL_sv_yes)
            *f = powq((float128)SvIVX(b), *(INT2PTR(float128 *, SvIVX(SvRV(a)))));
       else *f = powq(*(INT2PTR(float128 *, SvIVX(SvRV(a)))), (float128)SvIVX(b));
       return obj_ref;
     }

     if(SvPOK(b)) {
       char * p;
#ifdef _WIN32_BIZARRE_INFNAN
       int inf_or_nan = _win32_infnanstring(SvPV_nolen(b));
#endif

       NOK_POK_DUALVAR_CHECK , "overload_pow");}

#ifdef _WIN32_BIZARRE_INFNAN
       if(inf_or_nan) {
         if(inf_or_nan == 2) {
           if(third == &PL_sv_yes)
                *f = powq(_get_nan(), *(INT2PTR(float128 *, SvIVX(SvRV(a)))));
           else *f = powq(*(INT2PTR(float128 *, SvIVX(SvRV(a)))), _get_nan());
         }
         else {
           if(third == &PL_sv_yes)
                *f = powq(_get_inf(inf_or_nan), *(INT2PTR(float128 *, SvIVX(SvRV(a)))));
           else *f = powq(*(INT2PTR(float128 *, SvIVX(SvRV(a)))), _get_inf(inf_or_nan));
         }
       }
       else {
         if(third == &PL_sv_yes)
              *f = powq(strtoflt128(SvPV_nolen(b), &p), *(INT2PTR(float128 *, SvIVX(SvRV(a)))));
         else *f = powq(*(INT2PTR(float128 *, SvIVX(SvRV(a)))), strtoflt128(SvPV_nolen(b), &p));
         _nnum_inc(p);
       }
#else
       if(third == &PL_sv_yes)
            *f = powq(strtoflt128(SvPV_nolen(b), &p), *(INT2PTR(float128 *, SvIVX(SvRV(a)))));
       else *f = powq(*(INT2PTR(float128 *, SvIVX(SvRV(a)))), strtoflt128(SvPV_nolen(b), &p));
       _nnum_inc(p);
#endif
       return obj_ref;
     }

     if(SvNOK(b)) {
#if defined(AVOID_INF_CAST)
       if(SvNVX(b) != 0.0L && SvNVX(b) == SvNVX(b) && SvNVX(b) / SvNVX(b) != SvNVX(b) / SvNVX(b)) {
         if(third == &PL_sv_yes)
              *f = powq(_get_inf(SvNVX(b) > 0 ? 1 : -1), *(INT2PTR(float128 *, SvIVX(SvRV(a)))));
         else *f = powq(*(INT2PTR(float128 *, SvIVX(SvRV(a)))), _get_inf(SvNVX(b) > 0 ? 1 : -1));
         return obj_ref;
       }
#endif
       if(third == &PL_sv_yes)
            *f = powq((float128)SvNVX(b), *(INT2PTR(float128 *, SvIVX(SvRV(a)))));
       else *f = powq(*(INT2PTR(float128 *, SvIVX(SvRV(a)))), (float128)SvNVX(b));
       return obj_ref;
     }

    if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Float128")) {
        *f = powq(*(INT2PTR(float128 *, SvIVX(SvRV(a)))), *(INT2PTR(float128 *, SvIVX(SvRV(b)))));
        return obj_ref;
      }
      croak("Invalid object supplied to Math::Float128::_overload_pow function");
    }
    croak("Invalid argument supplied to Math::Float128::_overload_pow function");
}

SV * _overload_pow_eq(pTHX_ SV * a, SV * b, SV * third) {

    SvREFCNT_inc(a);

    if(SvUOK(b)) {
       *(INT2PTR(float128 *, SvIVX(SvRV(a)))) = powq(*(INT2PTR(float128 *, SvIVX(SvRV(a)))),
                                                    (float128)SvUVX(b));
        return a;
    }

    if(SvIOK(b)) {
       *(INT2PTR(float128 *, SvIVX(SvRV(a)))) = powq(*(INT2PTR(float128 *, SvIVX(SvRV(a)))),
                                                    (float128)SvIVX(b));
        return a;
    }

    if(SvPOK(b)) {
       char * p;
#ifdef _WIN32_BIZARRE_INFNAN
       int inf_or_nan = _win32_infnanstring(SvPV_nolen(b));
#endif

       NOK_POK_DUALVAR_CHECK , "overload_pow_eq");}

#ifdef _WIN32_BIZARRE_INFNAN

       if(inf_or_nan) {
         if(inf_or_nan == 2) {
           *(INT2PTR(float128 *, SvIVX(SvRV(a)))) = powq(*(INT2PTR(float128 *, SvIVX(SvRV(a)))),
                                                    _get_nan());
           return a;
         }

         *(INT2PTR(float128 *, SvIVX(SvRV(a)))) = powq(*(INT2PTR(float128 *, SvIVX(SvRV(a)))),
                                                    _get_inf(inf_or_nan));
         return a;
       }

       *(INT2PTR(float128 *, SvIVX(SvRV(a)))) = powq(*(INT2PTR(float128 *, SvIVX(SvRV(a)))),
                                                    strtoflt128(SvPV_nolen(b), &p));
       _nnum_inc(p);
       return a;
#else
       *(INT2PTR(float128 *, SvIVX(SvRV(a)))) = powq(*(INT2PTR(float128 *, SvIVX(SvRV(a)))),
                                                    strtoflt128(SvPV_nolen(b), &p));
       _nnum_inc(p);
       return a;
#endif
    }

    if(SvNOK(b)) {
#if defined(AVOID_INF_CAST)
       if(SvNVX(b) != 0.0L && SvNVX(b) == SvNVX(b) && SvNVX(b) / SvNVX(b) != SvNVX(b) / SvNVX(b)) {
         *(INT2PTR(float128 *, SvIVX(SvRV(a)))) = powq(*(INT2PTR(float128 *, SvIVX(SvRV(a)))),
                                                      _get_inf(SvNVX(b) > 0 ? 1 : -1));
          return a;
       }
#endif
       *(INT2PTR(float128 *, SvIVX(SvRV(a)))) = powq(*(INT2PTR(float128 *, SvIVX(SvRV(a)))),
                                                    (float128)SvNVX(b));
        return a;
    }

    if(sv_isobject(b)) {
      const char *h = HvNAME(SvSTASH(SvRV(b)));
      if(strEQ(h, "Math::Float128")) {
        *(INT2PTR(float128 *, SvIVX(SvRV(a)))) = powq(*(INT2PTR(float128 *, SvIVX(SvRV(a)))),
                                                        *(INT2PTR(float128 *, SvIVX(SvRV(b)))));
        return a;
      }
      SvREFCNT_dec(a);
      croak("Invalid object supplied to Math::Float128::_overload_pow_eq function");
    }
    SvREFCNT_dec(a);
    croak("Invalid argument supplied to Math::Float128::_overload_pow_eq function");
}

SV * cmp2NV(pTHX_ SV * flt128_obj, SV * sv) {
     float128 f;
     NV nv;

     if(sv_isobject(flt128_obj)) {
       const char *h = HvNAME(SvSTASH(SvRV(flt128_obj)));
       if(strEQ(h, "Math::Float128")) {
         f = *(INT2PTR(float128 *, SvIVX(SvRV(flt128_obj))));
         nv = SvNV(sv);

         if((f != f) || (nv != nv)) return &PL_sv_undef;
         if(f < (float128)nv) return newSViv(-1);
         if(f > (float128)nv) return newSViv(1);
         return newSViv(0);
       }
       croak("Invalid object supplied to Math::Float128::cmp2NV function");
     }
     croak("Invalid argument supplied to Math::Float128::cmp_NV function");
}

SV * F128toNV(pTHX_ SV * f) {
     return newSVnv((NV)(*(INT2PTR(float128 *, SvIVX(SvRV(f))))));
}

/* #define FLT128_MAX 1.18973149535723176508575932662800702e4932Q */

SV * _FLT128_MAX(pTHX) {
#ifdef FLT128_MAX
     float128 * f;
     SV * obj_ref, * obj;

     Newx(f, 1, float128);
     if(f == NULL) croak("Failed to allocate memory in _FLT128_MAX function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Float128");

     *f = FLT128_MAX;

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
#else
     croak("FLT128_MAX not implemented");
#endif
}

/* #define FLT128_MIN 3.36210314311209350626267781732175260e-4932Q */

SV * _FLT128_MIN(pTHX) {
#ifdef FLT128_MIN
     float128 * f;
     SV * obj_ref, * obj;

     Newx(f, 1, float128);
     if(f == NULL) croak("Failed to allocate memory in _FLT128_MIN function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Float128");

     *f = FLT128_MIN;

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
#else
     croak("FLT128_MIN not implemented");
#endif
}

/* #define FLT128_EPSILON 1.92592994438723585305597794258492732e-34Q */

SV * _FLT128_EPSILON(pTHX) {
#ifdef FLT128_EPSILON
     float128 * f;
     SV * obj_ref, * obj;

     Newx(f, 1, float128);
     if(f == NULL) croak("Failed to allocate memory in _FLT128_EPSILON function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Float128");

     *f = FLT128_EPSILON;

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
#else
     croak("FLT128_EPSILON not implemented");
#endif
}

/* #define FLT128_DENORM_MIN 6.475175119438025110924438958227646552e-4966Q */


SV * _FLT128_DENORM_MIN(pTHX) {
#ifdef FLT128_DENORM_MIN
     float128 * f;
     SV * obj_ref, * obj;

     Newx(f, 1, float128);
     if(f == NULL) croak("Failed to allocate memory in _FLT128_DENORM_MIN function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Float128");

     *f = FLT128_DENORM_MIN;

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
#else
     croak("FLT128_DENORM_MIN not implemented");
#endif
}

/* #define FLT128_MANT_DIG 113 */

int _FLT128_MANT_DIG(void) {
#ifdef FLT128_MANT_DIG
    return (int)FLT128_MANT_DIG;
#else
    croak("FLT128_MANT_DIG not implemented");
#endif
}

/* #define FLT128_MIN_EXP (-16381) */

int _FLT128_MIN_EXP(void) {
#ifdef FLT128_MIN_EXP
    return (int)FLT128_MIN_EXP;
#else
    croak("FLT128_MIN_EXP not implemented");
#endif
}

/* #define FLT128_MAX_EXP 16384 */

int _FLT128_MAX_EXP(void) {
#ifdef FLT128_MAX_EXP
    return (int)FLT128_MAX_EXP;
#else
    croak("FLT128_MAX_EXP not implemented");
#endif
}

/* #define FLT128_MIN_10_EXP (-4931) */

int _FLT128_MIN_10_EXP(void) {
#ifdef FLT128_MIN_10_EXP
    return (int)FLT128_MIN_10_EXP;
#else
    croak("FLT128_MIN_10_EXP not implemented");
#endif
}

/* #define FLT128_MAX_10_EXP 4932 */

int _FLT128_MAX_10_EXP(void) {
#ifdef FLT128_MAX_10_EXP
    return (int)FLT128_MAX_10_EXP;
#else
    croak("FLT128_MAX_10_EXP not implemented");
#endif
}

/* #define HUGE_VALQ __builtin_huge_valq() */


/*#define M_Eq		2.7182818284590452353602874713526625Q */  /* e */

SV * _M_Eq(pTHX) {
#ifndef M_Eq
#define M_Eq expq(1.0Q)
#endif
     float128 * f;
     SV * obj_ref, * obj;

     Newx(f, 1, float128);
     if(f == NULL) croak("Failed to allocate memory in _M_Eq function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Float128");

     *f = M_Eq;

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
}

/* #define M_LOG2Eq	1.4426950408889634073599246810018921Q */  /* log_2 e */

SV * _M_LOG2Eq(pTHX) {
#ifndef M_LOG2Eq
#define M_LOG2Eq log2q(expq(1.0Q))
#endif
     float128 * f;
     SV * obj_ref, * obj;

     Newx(f, 1, float128);
     if(f == NULL) croak("Failed to allocate memory in _M_LOG2Eq function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Float128");

     *f = M_LOG2Eq;

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
}

/* #define M_LOG10Eq	0.4342944819032518276511289189166051Q */  /* log_10 e */

SV * _M_LOG10Eq(pTHX) {
#ifndef M_LOG10Eq
#define M_LOG10Eq lo10q(expq(1.0Q))
#endif
     float128 * f;
     SV * obj_ref, * obj;

     Newx(f, 1, float128);
     if(f == NULL) croak("Failed to allocate memory in _M_LOG10Eq function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Float128");

     *f = M_LOG10Eq;

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
}

/* #define M_LN2q		0.6931471805599453094172321214581766Q */  /* log_e 2 */

SV * _M_LN2q(pTHX) {
#ifndef M_LN2q
#define M_LN2q logq(2.0Q)
#endif
     float128 * f;
     SV * obj_ref, * obj;

     Newx(f, 1, float128);
     if(f == NULL) croak("Failed to allocate memory in _M_LN2q function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Float128");

     *f = M_LN2q;

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
}

/* #define M_LN10q		2.3025850929940456840179914546843642Q */ /* log_e 10 */

SV * _M_LN10q(pTHX) {
#ifndef M_LN10q
#define M_LN10q logq(10.0Q)
#endif
     float128 * f;
     SV * obj_ref, * obj;

     Newx(f, 1, float128);
     if(f == NULL) croak("Failed to allocate memory in _M_LN10q function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Float128");

     *f = M_LN10q;

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
}

/* #define M_PIq		3.1415926535897932384626433832795029Q */  /* pi */

SV * _M_PIq(pTHX) {
#ifndef M_PIq
#define M_PIq 2.0Q*asinq(1.0Q)
#endif
     float128 * f;
     SV * obj_ref, * obj;

     Newx(f, 1, float128);
     if(f == NULL) croak("Failed to allocate memory in _M_PIq function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Float128");

     *f = M_PIq;

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
}

/* #define M_PI_2q		1.5707963267948966192313216916397514Q */  /* pi/2 */

SV * _M_PI_2q(pTHX) {
#ifndef M_PI_2q
#define M_PI_2q asinq(1.0Q)
#endif
     float128 * f;
     SV * obj_ref, * obj;

     Newx(f, 1, float128);
     if(f == NULL) croak("Failed to allocate memory in _M_PI_2q function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Float128");

     *f = M_PI_2q;

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
}

/* #define M_PI_4q		0.7853981633974483096156608458198757Q */  /* pi/4 */

SV * _M_PI_4q(pTHX) {
#ifndef M_PI_4q
#define M_PI_4q asinq(1.0Q)/2.0Q
#endif
     float128 * f;
     SV * obj_ref, * obj;

     Newx(f, 1, float128);
     if(f == NULL) croak("Failed to allocate memory in _M_PI_4q function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Float128");

     *f = M_PI_4q;

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
}

/* #define M_1_PIq		0.3183098861837906715377675267450287Q */  /* 1/pi */

SV * _M_1_PIq(pTHX) {
#ifndef M_1_PIq
#define M_1_PIq 0.5Q/asinq(1.0Q)
#endif
     float128 * f;
     SV * obj_ref, * obj;

     Newx(f, 1, float128);
     if(f == NULL) croak("Failed to allocate memory in _M_1_PIq function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Float128");

     *f = M_1_PIq;

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
}

/* #define M_2_PIq		0.6366197723675813430755350534900574Q */  /* 2/pi */

SV * _M_2_PIq(pTHX) {
#ifndef M_2_PIq
#define M_2_PIq 1.0Q/asinq(1.0Q)
#endif
     float128 * f;
     SV * obj_ref, * obj;

     Newx(f, 1, float128);
     if(f == NULL) croak("Failed to allocate memory in _M_2_PIq function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Float128");

     *f = M_2_PIq;

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
}

/* #define M_2_SQRTPIq	1.1283791670955125738961589031215452Q */  /* 2/sqrt(pi) */

SV * _M_2_SQRTPIq(pTHX) {
#ifndef M_2_SQRTPIq
#define M_2_SQRTPIq 2.0Q/sqrtq(2.0Q*asinq(1.0Q))
#endif
     float128 * f;
     SV * obj_ref, * obj;

     Newx(f, 1, float128);
     if(f == NULL) croak("Failed to allocate memory in _M_2_SQRTPIq function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Float128");

     *f = M_2_SQRTPIq;

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
}

/* #define M_SQRT2q	1.4142135623730950488016887242096981Q */  /* sqrt(2) */

SV * _M_SQRT2q(pTHX) {
#ifndef M_SQRT2q
#define M_SQRT2q sqrtq(2.0Q)
#endif
     float128 * f;
     SV * obj_ref, * obj;

     Newx(f, 1, float128);
     if(f == NULL) croak("Failed to allocate memory in _M_SQRT2q function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Float128");

     *f = M_SQRT2q;

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
}

/* #define M_SQRT1_2q	0.7071067811865475244008443621048490Q */  /* 1/sqrt(2) */

SV * _M_SQRT1_2q(pTHX) {
#ifndef M_SQRT1_2q
#define M_SQRT1_2q 1.0Q/sqrtq(2.0Q)
#endif
     float128 * f;
     SV * obj_ref, * obj;

     Newx(f, 1, float128);
     if(f == NULL) croak("Failed to allocate memory in _M_SQRT1_2q function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Float128");

     *f = M_SQRT1_2q;

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
}

void _f128_bytes(pTHX_ SV * sv) {
  dXSARGS;
  float128 f128 = *(INT2PTR(float128 *, SvIVX(SvRV(sv))));
  int i, n = sizeof(float128);
  char * buff;
  void * p = &f128;

  Newx(buff, 4, char);
  if(buff == NULL) croak("Failed to allocate memory in _f128_bytes function");

  sp = mark;

#ifdef WE_HAVE_BENDIAN /* Big Endian architecture */
  for (i = 0; i < n; i++) {
#else
  for (i = n - 1; i >= 0; i--) {
#endif

    sprintf(buff, "%02X", ((unsigned char*)p)[i]);
    XPUSHs(sv_2mortal(newSVpv(buff, 0)));
  }
  PUTBACK;
  Safefree(buff);
  XSRETURN(n);
}

void acos_F128(float128 * rop, float128 * op) {
  *rop = acosq(*op);
}

void acosh_F128(float128 * rop, float128 * op) {
  *rop = acoshq(*op);
}

void asin_F128(float128 * rop, float128 * op) {
  *rop = asinq(*op);
}

void asinh_F128(float128 * rop, float128 * op) {
  *rop = asinhq(*op);
}

void atan_F128(float128 * rop, float128 * op) {
  *rop = atanq(*op);
}

void atanh_F128(float128 * rop, float128 * op) {
  *rop = atanhq(*op);
}

void atan2_F128(float128 * rop, float128 * op1, float128 * op2) {
  *rop = atan2q(*op1, *op2);
}

void cbrt_F128(float128 * rop, float128 * op) {
  *rop = cbrtq(*op);
}

void ceil_F128(float128 * rop, float128 * op) {
  *rop = ceilq(*op);
}

void copysign_F128(float128 * rop, float128 * op1, float128 * op2) {
  *rop = copysignq(*op1, *op2);
}

void cosh_F128(float128 * rop, float128 * op) {
#if defined(__MINGW64_VERSION_MAJOR) && __MINGW64_VERSION_MAJOR < 4 /* avoid calling coshq() as it's buggy */
  float128 temp = sinhq(*op);
  temp = powq(temp, 2) + 1.0Q;
  *rop = sqrtq(temp);
#else
  *rop = coshq(*op);
#endif
}

void cos_F128(float128 * rop, float128 * op) {
  *rop = cosq(*op);
}

void erf_F128(float128 * rop, float128 * op) {
  *rop = erfq(*op);
}

void erfc_F128(float128 * rop, float128 * op) {
  *rop = erfcq(*op);
}

void exp_F128(float128 * rop, float128 * op) {
#if defined(__MINGW64_VERSION_MAJOR) && __MINGW64_VERSION_MAJOR < 4 /* avoid calling expq() as it's buggy */
  *rop = powq(M_Eq, *op);
#else
  *rop = expq(*op);
#endif
}

void expm1_F128(float128 * rop, float128 * op) {
  *rop = expm1q(*op);
}

void fabs_F128(float128 * rop, float128 * op) {
  *rop = fabsq(*op);
}

void fdim_F128(float128 * rop, float128 * op1, float128 * op2) {
  *rop = fdimq(*op1, *op2);
}

int finite_F128(float128 * op) {
  return finiteq(*op);
}

void floor_F128(float128 * rop, float128 * op) {
  *rop = floorq(*op);
}

void fma_F128(float128 * rop, float128 * op1, float128 * op2, float128 * op3) {
#if defined(__MINGW64_VERSION_MAJOR) && __MINGW64_VERSION_MAJOR < 4 /* avoid calling fmaq() as it's buggy */
  float128 temp = *op1 * *op2;
  temp += *op3;
  *rop = temp;
#else
  *rop = fmaq(*op1, *op2, *op3);
#endif
}

void fmax_F128(float128 * rop, float128 * op1, float128 * op2) {
  *rop = fmaxq(*op1, *op2);
}

void fmin_F128(float128 * rop, float128 * op1, float128 * op2) {
  *rop = fminq(*op1, *op2);
}

void fmod_F128(float128 * rop, float128 * op1, float128 * op2) {
  *rop = fmodq(*op1, *op2);
}

void hypot_F128(float128 * rop, float128 * op1, float128 * op2) {
  *rop = hypotq(*op1, *op2);
}

void frexp_F128(pTHX_ float128 * frac, SV * exp, float128 * op) {
  int e;
  *frac = frexpq(*op, &e);
  sv_setsv(exp, newSViv(e));
}

void ldexp_F128(float128 * rop, float128 * op, int pow) {
  *rop = ldexpq(*op, pow);
}

int isinf_F128(float128 * op) {
  return isinfq(*op);
}

int ilogb_F128(float128 * op) {
  return ilogbq(*op);
}

int isnan_F128(float128 * op) {
  return isnanq(*op);
}

void j0_F128(float128 * rop, float128 * op) {
  *rop = j0q(*op);
}

void j1_F128(float128 * rop, float128 * op) {
  *rop = j1q(*op);
}

void jn_F128(float128 * rop, int n, float128 * op) {
  *rop = jnq(n, *op);
}

void lgamma_F128(float128 * rop, float128 * op) {
  *rop = lgammaq(*op);
}

SV * llrint_F128(pTHX_ float128 * op) {
#ifdef LONGLONG2IV_IS_OK
  return newSViv((IV)llrintq(*op));
#else
  warn("llrint_F128 not implemented: IV size (%d) is smaller than longlong size (%d)\n", sizeof(IV), sizeof(long long int));
  croak("Use lrint_F128 instead");
#endif
}

SV * llround_F128(pTHX_ float128 * op) {
#ifdef LONGLONG2IV_IS_OK
  return newSViv((IV)llroundq(*op));
#else
  warn("llround_F128 not implemented: IV size (%d) is smaller than longlong size (%d)\n", sizeof(IV), sizeof(long long int));
  croak("Use lround_F128 instead");
#endif
}

SV * lrint_F128(pTHX_ float128 * op) {
#ifdef LONG2IV_IS_OK
  return newSViv((IV)lrintq(*op));
#else
  croak("lrint_F128 not implemented: IV size (%d) is smaller than long size (%d)", sizeof(IV), sizeof(long));
#endif
}

SV * lround_F128(pTHX_ float128 * op) {
#ifdef LONG2IV_IS_OK
  return newSViv((IV)lroundq(*op));
#else
  croak("lround_F128 not implemented: IV size (%d) is smaller than long size (%d)", sizeof(IV), sizeof(long));
#endif
}

void log_F128(float128 * rop, float128 * op) {
  *rop = logq(*op);
}

void log10_F128(float128 * rop, float128 * op) {
  *rop = log10q(*op);
}

void log2_F128(float128 * rop, float128 * op) {
  *rop = log2q(*op);
}

void log1p_F128(float128 * rop, float128 * op) {
  *rop = log1pq(*op);
}

void modf_F128(float128 * integer, float128 * frac, float128 * op) {
  float128 ret;
  *frac = modfq(*op, &ret);
  *integer = ret;
}

void nan_F128(pTHX_ float128 * rop, SV * op) {
  *rop = nanq(SvPV_nolen(op));
}

void nearbyint_F128(float128 * rop, float128 * op) {
#if defined(__MINGW64_VERSION_MAJOR) && __MINGW64_VERSION_MAJOR < 4 /* avoid calling nearbyintq() as it's buggy */
  float128 do_floor, do_ceil;
  int rnd = fegetround();
  if(*op == 0.0Q || isinfq(*op) || isnanq(*op)) {
    *rop = *op;
    return;
  }
  do_floor = *op - floorq(*op);
  do_ceil  = ceilq(*op) - *op;
  if(do_ceil < do_floor) {
    *rop = ceilq(*op);
    return;
  }
  if(do_ceil > do_floor) {
    *rop = floorq(*op);
    return;
  }
  if(do_floor == do_ceil) {
    if(rnd == FE_TONEAREST) {
      if(remainderq(floorq(*op), 2.0Q) == 0.0Q) *rop = floorq(*op);
      else *rop = ceilq(*op);
      return;
    }
    if(rnd == FE_UPWARD) {
      *rop = ceilq(*op);
      return;
    }
    if(rnd == FE_DOWNWARD) {
      *rop = floorq(*op);
      return;
    }
    if(rnd == FE_TOWARDZERO) {
      if(*op < 0.0Q) *rop = ceilq(*op);
      if(*op > 0.0Q) *rop = floorq(*op);
      return;
    }
  croak("nearbyint_F128 workaround for mingw64 compiler failed\n");
  }
#else
  *rop = nearbyintq(*op);
#endif
}

void nextafter_F128(float128 * rop, float128 * op1, float128 * op2) {
  *rop = nextafterq(*op1, *op2);
}

void pow_F128(float128 * rop, float128 * op1, float128 * op2) {
  *rop = powq(*op1, *op2);
}

void remainder_F128(float128 * rop, float128 * op1, float128 * op2) {
  *rop = remainderq(*op1, *op2);
}

void remquo_F128(pTHX_ float128 * rop1, SV * rop2, float128 * op1, float128 * op2) {
  int ret;
  *rop1 = remquoq(*op1, *op2, &ret);
  sv_setsv(rop2, newSViv(ret));
}

void rint_F128(float128 * rop, float128 * op) {
  *rop = rintq(*op);
}

void round_F128(float128 * rop, float128 * op) {
  *rop = roundq(*op);
}

void scalbln_F128(float128 * rop, float128 * op1, long op2) {
  *rop = scalblnq(*op1, op2);
}

void scalbn_F128(float128 * rop, float128 * op1, int op2) {
  *rop = scalbnq(*op1, op2);
}

int signbit_F128(float128 * op) {
  return signbitq(*op);
}

void sincos_F128(float128 * sin, float128 * cos, float128 * op) {
  float128 sine, cosine;
  sincosq(*op, &sine, &cosine);
  *sin = sine;
  *cos = cosine;
}

void sinh_F128(float128 * rop, float128 * op) {
  *rop = sinhq(*op);
}

void sin_F128(float128 * rop, float128 * op) {
  *rop = sinq(*op);
}

void sqrt_F128(float128 * rop, float128 * op) {
  *rop = sqrtq(*op);
}

void tan_F128(float128 * rop, float128 * op) {
  *rop = tanq(*op);
}

void tanh_F128(float128 * rop, float128 * op) {
  *rop = tanhq(*op);
}

void tgamma_F128(float128 * rop, float128 * op) {
#if defined(__MINGW64_VERSION_MAJOR) && __MINGW64_VERSION_MAJOR < 4 /* avoid calling tgammaq() as it's buggy */
  *rop = powq(M_Eq, lgammaq(*op));
#else
  *rop = tgammaq(*op);
#endif
}

void trunc_F128(float128 * rop, float128 * op) {
  *rop = truncq(*op);
}

void y0_F128(float128 * rop, float128 * op) {
  *rop = y0q(*op);
}

void y1_F128(float128 * rop, float128 * op) {
  *rop = y1q(*op);
}

void yn_F128(float128 * rop, int n, float128 * op) {
  *rop = ynq(n, *op);
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

SV * _fegetround(pTHX) {
#ifdef __MINGW64_VERSION_MAJOR /* fenv.h has been included */
  int r = fegetround();
  if(r == FE_TONEAREST) return newSVpv("FE_TONEAREST", 0);
  if(r == FE_TOWARDZERO) return newSVpv("FE_TOWARDZERO", 0);
  if(r == FE_UPWARD) return newSVpv("FE_UPWARD", 0);
  if(r == FE_DOWNWARD) return newSVpv("FE_DOWNWARD", 0);
  return newSVpv("Unknown rounding mode", 0);
#else
  return newSVpv("Rounding mode undetermined - fenv.h not loaded", 0);
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

int nok_pokflag(void) {
  return nok_pok;
}

void clear_nok_pok(void){
  nok_pok = 0;
}

void set_nok_pok(int x) {
  nok_pok = x;
}

int _SvNOK(pTHX_ SV * in) {
  if(SvNOK(in)) return 1;
  return 0;
}

int _SvPOK(pTHX_ SV * in) {
  if(SvPOK(in)) return 1;
  return 0;
}

int _avoid_inf_cast(void) {
#if defined(AVOID_INF_CAST)
  return 1;
#else
  return 0;
#endif
}


MODULE = Math::Float128  PACKAGE = Math::Float128

PROTOTYPES: DISABLE


int
NOK_POK_val ()
CODE:
  RETVAL = NOK_POK_val (aTHX);
OUTPUT:  RETVAL


int
_win32_infnanstring (s)
	char *	s

void
flt128_set_prec (x)
	int	x
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        flt128_set_prec(aTHX_ x);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

int
flt128_get_prec ()


SV *
InfF128 (sign)
	int	sign
CODE:
  RETVAL = InfF128 (aTHX_ sign);
OUTPUT:  RETVAL

SV *
NaNF128 ()
CODE:
  RETVAL = NaNF128 (aTHX);
OUTPUT:  RETVAL


SV *
ZeroF128 (sign)
	int	sign
CODE:
  RETVAL = ZeroF128 (aTHX_ sign);
OUTPUT:  RETVAL

SV *
UnityF128 (sign)
	int	sign
CODE:
  RETVAL = UnityF128 (aTHX_ sign);
OUTPUT:  RETVAL

SV *
is_NaNF128 (b)
	SV *	b
CODE:
  RETVAL = is_NaNF128 (aTHX_ b);
OUTPUT:  RETVAL

SV *
is_InfF128 (b)
	SV *	b
CODE:
  RETVAL = is_InfF128 (aTHX_ b);
OUTPUT:  RETVAL

SV *
is_ZeroF128 (b)
	SV *	b
CODE:
  RETVAL = is_ZeroF128 (aTHX_ b);
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
STRtoF128 (str)
	SV *	str
CODE:
  RETVAL = STRtoF128 (aTHX_ str);
OUTPUT:  RETVAL

void
fromSTR (f, str)
	float128 *	f
	SV *	str
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        fromSTR(aTHX_ f, str);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
NVtoF128 (nv)
	SV *	nv
CODE:
  RETVAL = NVtoF128 (aTHX_ nv);
OUTPUT:  RETVAL

void
fromNV (f, nv)
	float128 *	f
	SV *	nv
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        fromNV(aTHX_ f, nv);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
IVtoF128 (iv)
	SV *	iv
CODE:
  RETVAL = IVtoF128 (aTHX_ iv);
OUTPUT:  RETVAL

void
fromIV (f, iv)
	float128 *	f
	SV *	iv
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        fromIV(aTHX_ f, iv);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
UVtoF128 (uv)
	SV *	uv
CODE:
  RETVAL = UVtoF128 (aTHX_ uv);
OUTPUT:  RETVAL

void
fromUV (f, uv)
	float128 *	f
	SV *	uv
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        fromUV(aTHX_ f, uv);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
F128toSTR (f)
	SV *	f
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        F128toSTR(aTHX_ f);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
F128toSTRP (f, decimal_prec)
	SV *	f
	int	decimal_prec
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        F128toSTRP(aTHX_ f, decimal_prec);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
DESTROY (f)
	SV *	f
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        DESTROY(aTHX_ f);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

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
_FLT128_DIG ()
CODE:
  RETVAL = _FLT128_DIG (aTHX);
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
F128toF128 (a)
	SV *	a
CODE:
  RETVAL = F128toF128 (aTHX_ a);
OUTPUT:  RETVAL

void
fromF128 (f, a)
	float128 *	f
	SV *	a
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        fromF128(aTHX_ f, a);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
_itsa (a)
	SV *	a
CODE:
  RETVAL = _itsa (aTHX_ a);
OUTPUT:  RETVAL

SV *
_overload_abs (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_abs (aTHX_ a, b, third);
OUTPUT:  RETVAL

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

SV *
_overload_inc (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_inc (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_dec (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_dec (aTHX_ a, b, third);
OUTPUT:  RETVAL

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
cmp2NV (flt128_obj, sv)
	SV *	flt128_obj
	SV *	sv
CODE:
  RETVAL = cmp2NV (aTHX_ flt128_obj, sv);
OUTPUT:  RETVAL

SV *
F128toNV (f)
	SV *	f
CODE:
  RETVAL = F128toNV (aTHX_ f);
OUTPUT:  RETVAL

SV *
_FLT128_MAX ()
CODE:
  RETVAL = _FLT128_MAX (aTHX);
OUTPUT:  RETVAL


SV *
_FLT128_MIN ()
CODE:
  RETVAL = _FLT128_MIN (aTHX);
OUTPUT:  RETVAL


SV *
_FLT128_EPSILON ()
CODE:
  RETVAL = _FLT128_EPSILON (aTHX);
OUTPUT:  RETVAL


SV *
_FLT128_DENORM_MIN ()
CODE:
  RETVAL = _FLT128_DENORM_MIN (aTHX);
OUTPUT:  RETVAL


int
_FLT128_MANT_DIG ()


int
_FLT128_MIN_EXP ()


int
_FLT128_MAX_EXP ()


int
_FLT128_MIN_10_EXP ()


int
_FLT128_MAX_10_EXP ()


SV *
_M_Eq ()
CODE:
  RETVAL = _M_Eq (aTHX);
OUTPUT:  RETVAL


SV *
_M_LOG2Eq ()
CODE:
  RETVAL = _M_LOG2Eq (aTHX);
OUTPUT:  RETVAL


SV *
_M_LOG10Eq ()
CODE:
  RETVAL = _M_LOG10Eq (aTHX);
OUTPUT:  RETVAL


SV *
_M_LN2q ()
CODE:
  RETVAL = _M_LN2q (aTHX);
OUTPUT:  RETVAL


SV *
_M_LN10q ()
CODE:
  RETVAL = _M_LN10q (aTHX);
OUTPUT:  RETVAL


SV *
_M_PIq ()
CODE:
  RETVAL = _M_PIq (aTHX);
OUTPUT:  RETVAL


SV *
_M_PI_2q ()
CODE:
  RETVAL = _M_PI_2q (aTHX);
OUTPUT:  RETVAL


SV *
_M_PI_4q ()
CODE:
  RETVAL = _M_PI_4q (aTHX);
OUTPUT:  RETVAL


SV *
_M_1_PIq ()
CODE:
  RETVAL = _M_1_PIq (aTHX);
OUTPUT:  RETVAL


SV *
_M_2_PIq ()
CODE:
  RETVAL = _M_2_PIq (aTHX);
OUTPUT:  RETVAL


SV *
_M_2_SQRTPIq ()
CODE:
  RETVAL = _M_2_SQRTPIq (aTHX);
OUTPUT:  RETVAL


SV *
_M_SQRT2q ()
CODE:
  RETVAL = _M_SQRT2q (aTHX);
OUTPUT:  RETVAL


SV *
_M_SQRT1_2q ()
CODE:
  RETVAL = _M_SQRT1_2q (aTHX);
OUTPUT:  RETVAL


void
_f128_bytes (sv)
	SV *	sv
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        _f128_bytes(aTHX_ sv);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
acos_F128 (rop, op)
	float128 *	rop
	float128 *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        acos_F128(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
acosh_F128 (rop, op)
	float128 *	rop
	float128 *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        acosh_F128(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
asin_F128 (rop, op)
	float128 *	rop
	float128 *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        asin_F128(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
asinh_F128 (rop, op)
	float128 *	rop
	float128 *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        asinh_F128(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
atan_F128 (rop, op)
	float128 *	rop
	float128 *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        atan_F128(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
atanh_F128 (rop, op)
	float128 *	rop
	float128 *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        atanh_F128(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
atan2_F128 (rop, op1, op2)
	float128 *	rop
	float128 *	op1
	float128 *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        atan2_F128(rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
cbrt_F128 (rop, op)
	float128 *	rop
	float128 *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        cbrt_F128(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
ceil_F128 (rop, op)
	float128 *	rop
	float128 *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        ceil_F128(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
copysign_F128 (rop, op1, op2)
	float128 *	rop
	float128 *	op1
	float128 *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        copysign_F128(rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
cosh_F128 (rop, op)
	float128 *	rop
	float128 *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        cosh_F128(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
cos_F128 (rop, op)
	float128 *	rop
	float128 *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        cos_F128(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
erf_F128 (rop, op)
	float128 *	rop
	float128 *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        erf_F128(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
erfc_F128 (rop, op)
	float128 *	rop
	float128 *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        erfc_F128(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
exp_F128 (rop, op)
	float128 *	rop
	float128 *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        exp_F128(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
expm1_F128 (rop, op)
	float128 *	rop
	float128 *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        expm1_F128(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
fabs_F128 (rop, op)
	float128 *	rop
	float128 *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        fabs_F128(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
fdim_F128 (rop, op1, op2)
	float128 *	rop
	float128 *	op1
	float128 *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        fdim_F128(rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

int
finite_F128 (op)
	float128 *	op

void
floor_F128 (rop, op)
	float128 *	rop
	float128 *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        floor_F128(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
fma_F128 (rop, op1, op2, op3)
	float128 *	rop
	float128 *	op1
	float128 *	op2
	float128 *	op3
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        fma_F128(rop, op1, op2, op3);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
fmax_F128 (rop, op1, op2)
	float128 *	rop
	float128 *	op1
	float128 *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        fmax_F128(rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
fmin_F128 (rop, op1, op2)
	float128 *	rop
	float128 *	op1
	float128 *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        fmin_F128(rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
fmod_F128 (rop, op1, op2)
	float128 *	rop
	float128 *	op1
	float128 *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        fmod_F128(rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
hypot_F128 (rop, op1, op2)
	float128 *	rop
	float128 *	op1
	float128 *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        hypot_F128(rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
frexp_F128 (frac, exp, op)
	float128 *	frac
	SV *	exp
	float128 *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        frexp_F128(aTHX_ frac, exp, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
ldexp_F128 (rop, op, pow)
	float128 *	rop
	float128 *	op
	int	pow
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        ldexp_F128(rop, op, pow);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

int
isinf_F128 (op)
	float128 *	op

int
ilogb_F128 (op)
	float128 *	op

int
isnan_F128 (op)
	float128 *	op

void
j0_F128 (rop, op)
	float128 *	rop
	float128 *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        j0_F128(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
j1_F128 (rop, op)
	float128 *	rop
	float128 *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        j1_F128(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
jn_F128 (rop, n, op)
	float128 *	rop
	int	n
	float128 *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        jn_F128(rop, n, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
lgamma_F128 (rop, op)
	float128 *	rop
	float128 *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        lgamma_F128(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
llrint_F128 (op)
	float128 *	op
CODE:
  RETVAL = llrint_F128 (aTHX_ op);
OUTPUT:  RETVAL

SV *
llround_F128 (op)
	float128 *	op
CODE:
  RETVAL = llround_F128 (aTHX_ op);
OUTPUT:  RETVAL

SV *
lrint_F128 (op)
	float128 *	op
CODE:
  RETVAL = lrint_F128 (aTHX_ op);
OUTPUT:  RETVAL

SV *
lround_F128 (op)
	float128 *	op
CODE:
  RETVAL = lround_F128 (aTHX_ op);
OUTPUT:  RETVAL

void
log_F128 (rop, op)
	float128 *	rop
	float128 *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        log_F128(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
log10_F128 (rop, op)
	float128 *	rop
	float128 *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        log10_F128(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
log2_F128 (rop, op)
	float128 *	rop
	float128 *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        log2_F128(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
log1p_F128 (rop, op)
	float128 *	rop
	float128 *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        log1p_F128(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
modf_F128 (integer, frac, op)
	float128 *	integer
	float128 *	frac
	float128 *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        modf_F128(integer, frac, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
nan_F128 (rop, op)
	float128 *	rop
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        nan_F128(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
nearbyint_F128 (rop, op)
	float128 *	rop
	float128 *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        nearbyint_F128(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
nextafter_F128 (rop, op1, op2)
	float128 *	rop
	float128 *	op1
	float128 *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        nextafter_F128(rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
pow_F128 (rop, op1, op2)
	float128 *	rop
	float128 *	op1
	float128 *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        pow_F128(rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
remainder_F128 (rop, op1, op2)
	float128 *	rop
	float128 *	op1
	float128 *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        remainder_F128(rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
remquo_F128 (rop1, rop2, op1, op2)
	float128 *	rop1
	SV *	rop2
	float128 *	op1
	float128 *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        remquo_F128(aTHX_ rop1, rop2, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
rint_F128 (rop, op)
	float128 *	rop
	float128 *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        rint_F128(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
round_F128 (rop, op)
	float128 *	rop
	float128 *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        round_F128(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
scalbln_F128 (rop, op1, op2)
	float128 *	rop
	float128 *	op1
	long	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        scalbln_F128(rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
scalbn_F128 (rop, op1, op2)
	float128 *	rop
	float128 *	op1
	int	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        scalbn_F128(rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

int
signbit_F128 (op)
	float128 *	op

void
sincos_F128 (sin, cos, op)
	float128 *	sin
	float128 *	cos
	float128 *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        sincos_F128(sin, cos, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
sinh_F128 (rop, op)
	float128 *	rop
	float128 *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        sinh_F128(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
sin_F128 (rop, op)
	float128 *	rop
	float128 *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        sin_F128(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
sqrt_F128 (rop, op)
	float128 *	rop
	float128 *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        sqrt_F128(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
tan_F128 (rop, op)
	float128 *	rop
	float128 *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        tan_F128(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
tanh_F128 (rop, op)
	float128 *	rop
	float128 *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        tanh_F128(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
tgamma_F128 (rop, op)
	float128 *	rop
	float128 *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        tgamma_F128(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
trunc_F128 (rop, op)
	float128 *	rop
	float128 *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        trunc_F128(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
y0_F128 (rop, op)
	float128 *	rop
	float128 *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        y0_F128(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
y1_F128 (rop, op)
	float128 *	rop
	float128 *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        y1_F128(rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
yn_F128 (rop, n, op)
	float128 *	rop
	int	n
	float128 *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        yn_F128(rop, n, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

int
_longlong2iv_is_ok ()


int
_long2iv_is_ok ()


int
_flt_radix ()


SV *
_fegetround ()
CODE:
  RETVAL = _fegetround (aTHX);
OUTPUT:  RETVAL


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
nok_pokflag ()


void
clear_nok_pok ()

        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        clear_nok_pok();
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
set_nok_pok (x)
	int	x
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        set_nok_pok(x);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

int
_SvNOK (in)
	SV *	in
CODE:
  RETVAL = _SvNOK (aTHX_ in);
OUTPUT:  RETVAL

int
_SvPOK (in)
	SV *	in
CODE:
  RETVAL = _SvPOK (aTHX_ in);
OUTPUT:  RETVAL

int
_avoid_inf_cast ()


