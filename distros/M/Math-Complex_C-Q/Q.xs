
#ifdef  __MINGW32__
#ifndef __USE_MINGW_ANSI_STDIO
#define __USE_MINGW_ANSI_STDIO 1
#endif
#endif

#define PERL_NO_GET_CONTEXT 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


#include "math_complex_c_q_include.h"

int _MATH_COMPLEX_C_Q_DIGITS = 36;

#if defined(__MINGW32__) && !defined(__MINGW64__)
typedef __float128 float128 __attribute__ ((aligned(32)));
typedef __complex128 complex128 __attribute__ ((aligned(32)));
#elif defined(__MINGW64__) || (defined(DEBUGGING) && defined(NV_IS_DOUBLE))
typedef __float128 float128 __attribute__ ((aligned(8)));
typedef __complex128 complex128 __attribute__ ((aligned(8)));
#else
typedef __float128 float128;
typedef __complex128 complex128;
#endif

#if defined(__MINGW64_VERSION_MAJOR) && __MINGW64_VERSION_MAJOR < 4 /* mingw-w64 compiler - this condition needs tweaking */
#define MINGW_W64_BUGGY 1
#elif defined(__MINGW32__) && !defined(NO_GCC_TAN_BUG)
#ifndef GCC_TAN_BUG
#define GCC_TAN_BUG 1
#endif
#endif

int nnum = 0;

#define MATH_COMPLEX complex128

void q_set_prec(int x) {
    if(x < 1)croak("1st arg (precision) to q_set_prec must be at least 1");
    _MATH_COMPLEX_C_Q_DIGITS = x;
}

int q_get_prec(void) {
    return _MATH_COMPLEX_C_Q_DIGITS;
}

int _is_nan(float128 x) {
    if(x == x) return 0;
    return 1;
}

int _is_inf(float128 x) {
    if(x == 0) return 0;
    if(_is_nan(x)) return 0;
    if(x / x == x / x) return 0;
    if(x < 0) return -1;
    return 1;
}

float128 _get_nan(void) {
    float nanval = 0.0Q / 0.0Q;
    return nanval;
}

float128 _get_inf(void) {
    float128 infval = 1.0Q / 0.0Q;
    return infval;
}

float128 _get_neg_inf(void) {
    float128 inf = -1.0Q / 0.0Q;
    return inf;
}

int is_nanq(pTHX_ SV * a) {
     if(SvNV(a) == SvNV(a)) return 0;
     return 1;
}

int is_infq(pTHX_ SV * a) {
     if(SvNV(a) == 0) return 0;
     if(SvNV(a) != SvNV(a)) return 0;
     if(SvNV(a) / SvNV(a) == SvNV(a) / SvNV(a)) return 0;
     if(SvNV(a) < 0) return -1;
     return 1;
}

SV * create_cq(pTHX) {

     MATH_COMPLEX *pc;
     SV * obj_ref, * obj;

     New(42, pc, 1, MATH_COMPLEX);
     if(pc == NULL) croak("Failed to allocate memory in create_cq function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Complex_C::Q");

     __real__ *pc = _get_nan();
     __imag__ *pc = _get_nan();

     sv_setiv(obj, INT2PTR(IV,pc));
     SvREADONLY_on(obj);
     return obj_ref;

}

void assign_cq(pTHX_ SV * rop, SV * d1, SV * d2) {
     float128 _d1, _d2;

     if(SvUOK(d1)) {
       _d1 = (float128)SvUVX(d1);
     }
     else {
       if(SvIOK(d1)) {
         _d1 = (float128)SvIVX(d1);
       }
       else {
         if(SvNOK(d1)) {
           _d1 = (float128)SvNVX(d1);
         }
         else {
           if(SvPOK(d1)) {
             if(!looks_like_number(d1)) nnum++;
             _d1 = strtoflt128(SvPV_nolen(d1), NULL) ;
           }
           else {
             if(sv_isobject(d1)) {
               const char *h = HvNAME(SvSTASH(SvRV(d1)));
               if(strEQ(h, "Math::Float128"))
                 _d1 = *(INT2PTR(float128 *, SvIVX(SvRV(d1))));
               else croak("Invalid object given as 2nd arg to assign_cq function");
             }
             else {
               croak("Invalid 2nd arg supplied to assign_cq function");
             }
           }
         }
       }
     }

     if(SvUOK(d2)) {
       _d2 = (float128)SvUVX(d2);
     }
     else {
       if(SvIOK(d2)) {
         _d2 = (float128)SvIVX(d2);
       }
       else {
         if(SvNOK(d2)) {
            _d2 = (float128)SvNVX(d2);
         }
         else {
           if(SvPOK(d2)) {
             if(!looks_like_number(d2)) nnum++;
             _d2 = strtoflt128(SvPV_nolen(d2), NULL) ;
           }
           else {
             if(sv_isobject(d2)) {
               const char *h = HvNAME(SvSTASH(SvRV(d2)));
               if(strEQ(h, "Math::Float128"))
                 _d2 = *(INT2PTR(float128 *, SvIVX(SvRV(d2))));
               else croak("Invalid object given as 3rd arg to assign_cq function");
             }
             else {
               croak("Invalid 3rd arg supplied to assign_cq function");
             }
           }
         }
       }
     }

     __real__ *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = _d1;
     __imag__ *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = _d2;
}

void set_real_cq(pTHX_ SV * rop, SV * d1) {
     float128 _d1;

     if(SvUOK(d1)) {
       _d1 = (float128)SvUVX(d1);
     }
     else {
       if(SvIOK(d1)) {
         _d1 = (float128)SvIVX(d1);
       }
       else {
         if(SvNOK(d1)) {
           _d1 = (float128)SvNVX(d1);
         }
         else {
           if(SvPOK(d1)) {
             if(!looks_like_number(d1)) nnum++;
             _d1 = strtoflt128(SvPV_nolen(d1), NULL) ;
           }
           else {
             if(sv_isobject(d1)) {
               const char *h = HvNAME(SvSTASH(SvRV(d1)));
               if(strEQ(h, "Math::Float128"))
                 _d1 = *(INT2PTR(float128 *, SvIVX(SvRV(d1))));
               else croak("Invalid object given as 2nd arg to set_real_cq function");
             }
             else {
               croak("Invalid 2nd arg supplied to set_real_cq function");
             }
           }
         }
       }
     }

     __real__ *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = _d1;
}

void set_imag_cq(pTHX_ SV * rop, SV * d2) {
     float128 _d2;

     if(SvUOK(d2)) {
       _d2 = (float128)SvUVX(d2);
     }
     else {
       if(SvIOK(d2)) {
         _d2 = (float128)SvIVX(d2);
       }
       else {
         if(SvNOK(d2)) {
           _d2 = (float128)SvNVX(d2);
         }
         else {
           if(SvPOK(d2)) {
             if(!looks_like_number(d2)) nnum++;
             _d2 = strtoflt128(SvPV_nolen(d2), NULL) ;
           }
           else {
             if(sv_isobject(d2)) {
               const char *h = HvNAME(SvSTASH(SvRV(d2)));
               if(strEQ(h, "Math::Float128"))
                 _d2 = *(INT2PTR(float128 *, SvIVX(SvRV(d2))));
               else croak("Invalid object given as 2nd arg to set_imag_cq function");
             }
             else {
               croak("Invalid 2nd arg supplied to set_imag_cq function");
             }
           }
         }
       }
     }

     __imag__ *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = _d2;
}


void F2cq(pTHX_ SV * rop, SV * d1, SV * d2) {
     float128 _d1, _d2;

     if(sv_isobject(d1) && sv_isobject(d2)) {
       const char *h1 = HvNAME(SvSTASH(SvRV(d1)));
       const char *h2 = HvNAME(SvSTASH(SvRV(d2)));
       if(strEQ(h1, "Math::Float128") &&
          strEQ(h2, "Math::Float128")) {

          _d1 = *(INT2PTR(float128 *, SvIVX(SvRV(d1))));
          _d2 = *(INT2PTR(float128 *, SvIVX(SvRV(d2))));

          __real__ *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = _d1;
          __imag__ *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = _d2;
       }
       else croak("Both 2nd and 3rd args supplied to F2cq need to be Math::Float128 objects");
     }
     else croak("Both 2nd and 3rd args supplied to F2cq need to be Math::Float128 objects");
}

void cq2F(pTHX_ SV * rop1, SV * rop2, SV * op) {
     if(sv_isobject(rop1)) {
       const char *h = HvNAME(SvSTASH(SvRV(rop1)));
       if(strEQ(h, "Math::Float128")) {
         *(INT2PTR(float128 *, SvIVX(SvRV(rop1)))) = crealq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
       }
       else croak("1st arg (a %s object) supplied to cq2F needs to be a Math::Float128 object", h);
     }
     else croak("1st arg (which needs to be a Math::Float128 object) supplied to cq2F is not an object");

     if(sv_isobject(rop2)) {
       const char *h = HvNAME(SvSTASH(SvRV(rop2)));
       if(strEQ(h, "Math::Float128")) {
         *(INT2PTR(float128 *, SvIVX(SvRV(rop2)))) = cimagq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
       }
       else croak("2nd arg (a %s object) supplied to cq2F needs to be a Math::Float128 object", h);
     }
     else croak("2nd arg (which needs to be a Math::Float128 object) supplied to cq2F is not an object");
}

void mul_cq(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) *
                                                   *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op2))));
}

void mul_c_nvq(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) *
                                                   (float128)SvNV(op2);
}

void mul_c_ivq(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) *
                                                   (float128)SvIV(op2);
}

void mul_c_uvq(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) *
                                                   (float128)SvUV(op2);
}

void mul_c_pvq(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) *
                                                   strtoflt128(SvPV_nolen(op2), NULL);
}

void div_cq(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) /
                                                   *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op2))));
}

void div_c_nvq(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) /
                                                   (float128)SvNV(op2);
}

void div_c_ivq(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) /
                                                   (float128)SvIV(op2);
}

void div_c_uvq(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) /
                                                   (float128)SvUV(op2);
}

void div_c_pvq(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) /
                                                   strtoflt128(SvPV_nolen(op2), NULL);
}

void add_cq(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) +
                                                   *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op2))));
}

void add_c_nvq(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) +
                                                   (float128)SvNV(op2);
}

void add_c_ivq(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) +
                                                   (float128)SvIV(op2);
}

void add_c_uvq(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) +
                                                   (float128)SvUV(op2);
}

void add_c_pvq(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) +
                                                   strtoflt128(SvPV_nolen(op2), NULL);
}

void sub_cq(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) -
                                                   *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op2))));
}

void sub_c_nvq(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) -
                                                   (float128)SvNV(op2);
}

void sub_c_ivq(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) -
                                                   (float128)SvIV(op2);
}

void sub_c_uvq(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) -
                                                   (float128)SvUV(op2);
}

void sub_c_pvq(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) -
                                                   strtoflt128(SvPV_nolen(op2), NULL);
}

void DESTROY(pTHX_ SV *  op) {
     Safefree(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op))));
}

SV * real_cq(pTHX_ SV * op) {
     return newSVnv(crealq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op))))));
}

SV * real_cq2F(pTHX_ SV * op) {
     float128 * f;
     SV * obj_ref, * obj;

     Newx(f, 1, float128);
     if(f == NULL) croak("Failed to allocate memory in real_cq2F function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Float128");

     *f = crealq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
}

void real_cq2str(pTHX_ SV * op) {
     dXSARGS;
     float128 t;
     char * buffer;

     if(sv_isobject(op)) {
       const char *h = HvNAME(SvSTASH(SvRV(op)));
       if(strEQ(h, "Math::Complex_C::Q")) {
          EXTEND(SP, 1);
          t = crealq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));

          Newx(buffer, 15 + _MATH_COMPLEX_C_Q_DIGITS, char);
          if(buffer == NULL) croak("Failed to allocate memory in real_cq2str");
          quadmath_snprintf(buffer, 15 + _MATH_COMPLEX_C_Q_DIGITS, "%.*Qe", _MATH_COMPLEX_C_Q_DIGITS - 1, t);
          ST(0) = sv_2mortal(newSVpv(buffer, 0));
          Safefree(buffer);
          XSRETURN(1);
       }
       else croak("Invalid object supplied to Math::Complex_C::Q::real_cq2str function");
     }
     else croak("Invalid argument supplied to Math::Complex_C::Q::real_cq2str function");
}

SV * imag_cq(pTHX_ SV * op) {
     return newSVnv(cimagq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op))))));
}

SV * imag_cq2F(pTHX_ SV * op) {
     float128 * f;
     SV * obj_ref, * obj;

     Newx(f, 1, float128);
     if(f == NULL) croak("Failed to allocate memory in imag_cq2F function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Float128");

     *f = cimagq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
}

void imag_cq2str(pTHX_ SV * op) {
     dXSARGS;
     float128 t;
     char * buffer;

     if(sv_isobject(op)) {
       const char *h = HvNAME(SvSTASH(SvRV(op)));
       if(strEQ(h, "Math::Complex_C::Q")) {
          EXTEND(SP, 1);
          t = cimagq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));

          Newx(buffer, 15 + _MATH_COMPLEX_C_Q_DIGITS, char);
          if(buffer == NULL) croak("Failed to allocate memory in imag_cq2str");
          quadmath_snprintf(buffer, 15 + _MATH_COMPLEX_C_Q_DIGITS, "%.*Qe", _MATH_COMPLEX_C_Q_DIGITS - 1, t);
          ST(0) = sv_2mortal(newSVpv(buffer, 0));
          Safefree(buffer);
          XSRETURN(1);
       }
       else croak("Invalid object supplied to Math::Complex_C::Q::imag_cq2str function");
     }
     else croak("Invalid argument supplied to Math::Complex_C::Q::imag_cq2str function");
}

SV * arg_cq(pTHX_ SV * op) {
     return newSVnv(cargq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op))))));
}

SV * arg_cq2F(pTHX_ SV * op) {
     float128 * f;
     SV * obj_ref, * obj;

     Newx(f, 1, float128);
     if(f == NULL) croak("Failed to allocate memory in arg_cq2F function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Float128");

     *f = cargq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
}

void arg_cq2str(pTHX_ SV * op) {
     dXSARGS;
     float128 t;
     char * buffer;

     if(sv_isobject(op)) {
       const char *h = HvNAME(SvSTASH(SvRV(op)));
       if(strEQ(h, "Math::Complex_C::Q")) {
          EXTEND(SP, 1);
          t = cargq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));

          Newx(buffer, 15 + _MATH_COMPLEX_C_Q_DIGITS, char);
          if(buffer == NULL) croak("Failed to allocate memory in arg_cq2str");
          quadmath_snprintf(buffer, 15 + _MATH_COMPLEX_C_Q_DIGITS, "%.*Qe", _MATH_COMPLEX_C_Q_DIGITS - 1, t);
          ST(0) = sv_2mortal(newSVpv(buffer, 0));
          Safefree(buffer);
          XSRETURN(1);
       }
       else croak("Invalid object supplied to Math::Complex_C::Q::arg_cq2str function");
     }
     else croak("Invalid argument supplied to Math::Complex_C::Q::arg_cq2str function");
}

SV * abs_cq(pTHX_ SV * op) {
     return newSVnv(cabsq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op))))));
}

SV * abs_cq2F(pTHX_ SV * op) {
     float128 * f;
     SV * obj_ref, * obj;

     Newx(f, 1, float128);
     if(f == NULL) croak("Failed to allocate memory in cabs_cq2F function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Float128");

     *f = cabsq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
}

void abs_cq2str(pTHX_ SV * op) {
     dXSARGS;
     float128 t;
     char * buffer;

     if(sv_isobject(op)) {
       const char *h = HvNAME(SvSTASH(SvRV(op)));
       if(strEQ(h, "Math::Complex_C::Q")) {
          EXTEND(SP, 1);
          t = cabsq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));

          Newx(buffer, 15 + _MATH_COMPLEX_C_Q_DIGITS, char);
          if(buffer == NULL) croak("Failed to allocate memory in arg_cq2str");
          quadmath_snprintf(buffer, 15 + _MATH_COMPLEX_C_Q_DIGITS, "%.*Qe", _MATH_COMPLEX_C_Q_DIGITS - 1, t);
          ST(0) = sv_2mortal(newSVpv(buffer, 0));
          Safefree(buffer);
          XSRETURN(1);
       }
       else croak("Invalid object supplied to Math::Complex_C::Q::abs_cq2str function");
     }
     else croak("Invalid argument supplied to Math::Complex_C::Q::abs_cq2str function");
}

void conj_cq(pTHX_ SV * rop, SV * op) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = conjq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
}

void acos_cq(pTHX_ SV * rop, SV * op) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = cacosq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
}

void asin_cq(pTHX_ SV * rop, SV * op) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = casinq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
}

void atan_cq(pTHX_ SV * rop, SV * op) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = catanq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
}

void cos_cq(pTHX_ SV * rop, SV * op) {
#ifdef MINGW_W64_BUGGY
     croak("cos_cq not implemented for mingw-w64 compilers");
#else
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = ccosq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
#endif
}

void sin_cq(pTHX_ SV * rop, SV * op) {
#ifdef MINGW_W64_BUGGY
     croak("sin_cq not implemented for mingw-w64 compilers");
#else
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = csinq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
#endif
}

void tan_cq(pTHX_ SV * rop, SV * op) {
#if defined(MINGW_W64_BUGGY)
     croak("tan_cq not implemented for mingw-w64 compilers");
#elif defined(GCC_TAN_BUG)
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = csinq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op))))) /
                                                   ccosq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
#else
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = ctanq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
#endif
}

void acosh_cq(pTHX_ SV * rop, SV * op) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = cacoshq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
}

void asinh_cq(pTHX_ SV * rop, SV * op) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = casinhq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
}

void atanh_cq(pTHX_ SV * rop, SV * op) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = catanhq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
}

void cosh_cq(pTHX_ SV * rop, SV * op) {
#ifdef MINGW_W64_BUGGY
     croak("cosh_cq not implemented for mingw-w64 compilers");
#else
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = ccoshq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
#endif
}

void sinh_cq(pTHX_ SV * rop, SV * op) {
#ifdef MINGW_W64_BUGGY
     croak("sinh_cq not implemented for mingw-w64 compilers");
#else
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = csinhq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
#endif
}

void tanh_cq(pTHX_ SV * rop, SV * op) {
#ifdef MINGW_W64_BUGGY
     croak("tanh_cq not implemented for mingw-w64 compilers");
#elif defined(GCC_TAN_BUG)
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = csinhq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op))))) /
                                                   ccoshq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
#else
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = ctanhq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
#endif
}

void exp_cq(pTHX_ SV * rop, SV * op) {
#ifdef MINGW_W64_BUGGY /* avoid calling expq() as it's buggy */
     croak("exp_cq not implemented for mingw-w64 compilers");
#else
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = cexpq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
#endif
}

void log_cq(pTHX_ SV * rop, SV * op) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = clogq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
}

void sqrt_cq(pTHX_ SV * rop, SV * op) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = csqrtq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
}

void proj_cq(pTHX_ SV * rop, SV * op) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = cprojq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
}

void pow_cq(pTHX_ SV * rop, SV * op, SV * exp) {
#ifdef MINGW_W64_BUGGY
     croak("pow_cq not implemented for mingw-w64 compilers");
#else
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = cpowq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))),
                                                        *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(exp)))));
#endif
}

SV * _overload_true(pTHX_ SV * rop, SV * second, SV * third) {
     if (_is_nan(crealq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))))) &&
         _is_nan(cimagq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop))))))) return newSVuv(0);
     if(crealq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop))))) ||
        cimagq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))))) return newSVuv(1);
     return newSVuv(0);
}

SV * _overload_not(pTHX_ SV * rop, SV * second, SV * third) {
     if (_is_nan(crealq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))))) &&
         _is_nan(cimagq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop))))))) return newSVuv(1);
     if(crealq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop))))) ||
        cimagq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))))) return newSVuv(0);
     return newSVuv(1);
}

SV * _overload_equiv(pTHX_ SV * a, SV * b, SV * third) {
      if(SvUOK(b)) {
       if((float128)SvUVX(b) == crealq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))))) &&
          0.0Q              == cimagq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))))) return newSVuv(1);
       return newSVuv(0);
     }
     if(SvIOK(b)) {
       if((float128)SvIVX(b) == crealq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))))) &&
          0.0Q              == cimagq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))))) return newSVuv(1);
       return newSVuv(0);
     }
     if(SvNOK(b)) {
       if((float128)SvNVX(b) == crealq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))))) &&
          0.0Q    == cimagq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))))) return newSVuv(1);
       return newSVuv(0);
     }

     if(SvPOK(b)) {
       if(!looks_like_number(b)) nnum++;
       if(strtoflt128(SvPV_nolen(b), NULL) == crealq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))))) &&
          0.0Q == cimagq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))))) return newSVuv(1);
       return newSVuv(0);
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Complex_C::Q")) {
         if(crealq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))))) == crealq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(b))))) &&
            cimagq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))))) == cimagq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(b))))))
              return newSVuv(1);
         return newSVuv(0);
       }
     }

     croak("Invalid argument supplied to Math::Complex_C::Q::_overload_equiv function");
}

SV * _overload_not_equiv(pTHX_ SV * a, SV * b, SV * third) {
     if(SvUOK(b)) {
       if((float128)SvUVX(b) == crealq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))))) &&
          0.0Q              == cimagq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))))) return newSVuv(0);
       return newSVuv(1);
     }
     if(SvIOK(b)) {
       if((float128)SvIVX(b) == crealq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))))) &&
          0.0Q              == cimagq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))))) return newSVuv(0);
       return newSVuv(1);
     }
     if(SvNOK(b)) {
       if((float128)SvNVX(b) == crealq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))))) &&
          0.0Q    == cimagq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))))) return newSVuv(0);
       return newSVuv(1);
     }
     if(SvPOK(b)) {
       if(!looks_like_number(b)) nnum++;
       if(strtoflt128(SvPV_nolen(b), NULL) == crealq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))))) &&
          0.0Q == cimagq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))))) return newSVuv(0);
       return newSVuv(1);
     }
     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Complex_C::Q")) {
         if(crealq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))))) == crealq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(b))))) &&
            cimagq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))))) == cimagq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(b))))))
              return newSVuv(0);
         return newSVuv(1);
       }
     }

     croak("Invalid argument supplied to Math::Complex_C::Q::_overload_not_equiv function");
}


SV * _overload_pow(pTHX_ SV * a, SV * b, SV * third) {
#ifdef MINGW_W64_BUGGY
     croak("** (pow) not overloaded for mingw-w64 compilers");
#else
     MATH_COMPLEX *pc, t;
     SV * obj_ref, * obj;

     New(42, pc, 1, MATH_COMPLEX);
     if(pc == NULL) croak("Failed to allocate memory in _overload_pow function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Complex_C::Q");

     sv_setiv(obj, INT2PTR(IV,pc));
     SvREADONLY_on(obj);

     if(SvUOK(b)) {
       __real__ t = (float128)SvUVX(b);
       __imag__ t = 0.0Q;
       if(SWITCH_ARGS) {
         *pc = cpowq( t, *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) );
         return obj_ref;
       }
       *pc = cpowq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))), t);
       return obj_ref;
     }

     if(SvIOK(b)) {
       __real__ t = (float128)SvIVX(b);
       __imag__ t = 0.0Q;
       if(SWITCH_ARGS) {
         *pc = cpowq( t, *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) );
         return obj_ref;
       }
       *pc = cpowq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))), t);
       return obj_ref;
     }

     if(SvNOK(b)) {
       __real__ t = (float128)SvNVX(b);
       __imag__ t = 0.0Q;
       if(SWITCH_ARGS) {
         *pc = cpowq( t, *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) );
         return obj_ref;
       }
       *pc = cpowq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))), t);
       return obj_ref;
     }

     if(SvPOK(b)) {
       if(!looks_like_number(b)) nnum++;
       __real__ t = strtoflt128(SvPV_nolen(b), NULL);
       __imag__ t = 0.0Q;
       if(SWITCH_ARGS) {
         *pc = cpowq( t, *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) );
         return obj_ref;
       }
       *pc = cpowq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))), t);
       return obj_ref;
     }

     else if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Complex_C::Q")) {
         *pc = cpowq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))), *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(b)))));
         return obj_ref;
       }
     }
     else croak("Invalid argument supplied to Math::Complex_C::Q::_overload_pow function");
#endif
}

SV * _overload_mul(pTHX_ SV * a, SV * b, SV * third) {
     MATH_COMPLEX *pc;
     SV * obj_ref, * obj;

     New(42, pc, 1, MATH_COMPLEX);
     if(pc == NULL) croak("Failed to allocate memory in _overload_mul function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Complex_C::Q");

     sv_setiv(obj, INT2PTR(IV,pc));
     SvREADONLY_on(obj);

     if(SvUOK(b)) {
       *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) * (float128)SvUVX(b);
       return obj_ref;
     }

     if(SvIOK(b)) {
       *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) * (float128)SvIVX(b);
       return obj_ref;
     }

     if(SvNOK(b)) {
       *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) * (float128)SvNVX(b);
       return obj_ref;
     }
     if(SvPOK(b)) {
       if(!looks_like_number(b)) nnum++;
       *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) * strtoflt128(SvPV_nolen(b), NULL);
       return obj_ref;
     }
     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Complex_C::Q")) {
         *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) * *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(b))));
         return obj_ref;
       }
     }

     croak("Invalid argument supplied to Math::Complex_C::Q::_overload_mul function");
}

SV * _overload_add(pTHX_ SV * a, SV * b, SV * third) {
     MATH_COMPLEX *pc;
     SV * obj_ref, * obj;

     New(42, pc, 1, MATH_COMPLEX);
     if(pc == NULL) croak("Failed to allocate memory in _overload_add function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Complex_C::Q");

     sv_setiv(obj, INT2PTR(IV,pc));
     SvREADONLY_on(obj);

     if(SvUOK(b)) {
       *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) + (float128)SvUVX(b);
       return obj_ref;
     }

     if(SvIOK(b)) {
       *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) + (float128)SvIVX(b);
       return obj_ref;
     }

     if(SvNOK(b)) {
       *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) + (float128)SvNVX(b);
       return obj_ref;
     }
     if(SvPOK(b)) {
       if(!looks_like_number(b)) nnum++;
       *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) + strtoflt128(SvPV_nolen(b), NULL);
       return obj_ref;
     }
     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Complex_C::Q")) {
         *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) + *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(b))));
         return obj_ref;
       }
     }

     croak("Invalid argument supplied to Math::Complex_C::Q::_overload_add function");
}

SV * _overload_div(pTHX_ SV * a, SV * b, SV * third) {
     MATH_COMPLEX *pc;
     SV * obj_ref, * obj;

     New(42, pc, 1, MATH_COMPLEX);
     if(pc == NULL) croak("Failed to allocate memory in _overload_div function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Complex_C::Q");

     sv_setiv(obj, INT2PTR(IV,pc));
     SvREADONLY_on(obj);

     if(SvUOK(b)) {
       if(SWITCH_ARGS) *pc = (float128)SvUVX(b) / *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))));
       else *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) / (float128)SvUVX(b);
       return obj_ref;
     }

     if(SvIOK(b)) {
       if(SWITCH_ARGS) *pc = (float128)SvIVX(b) / *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))));
       else *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) / (float128)SvIVX(b);
       return obj_ref;
     }

     if(SvNOK(b)) {
       if(SWITCH_ARGS) *pc = (float128)SvNVX(b) / *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))));
       else *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) / (float128)SvNVX(b);
       return obj_ref;
     }
     if(SvPOK(b)) {
       if(!looks_like_number(b)) nnum++;
       if(SWITCH_ARGS) *pc = strtoflt128(SvPV_nolen(b), NULL) / *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))));
       else *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) / strtoflt128(SvPV_nolen(b), NULL);
       return obj_ref;
     }
     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Complex_C::Q")) {
         *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) / *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(b))));
         return obj_ref;
       }
     }

     croak("Invalid argument supplied to Math::Complex_C::Q::_overload_div function");
}

SV * _overload_sub(pTHX_ SV * a, SV * b, SV * third) {
     MATH_COMPLEX *pc;
     SV * obj_ref, * obj;

     New(42, pc, 1, MATH_COMPLEX);
     if(pc == NULL) croak("Failed to allocate memory in _overload_sub function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Complex_C::Q");

     sv_setiv(obj, INT2PTR(IV,pc));
     SvREADONLY_on(obj);

     if(SvUOK(b)) {
       if(SWITCH_ARGS) *pc = (float128)SvUVX(b) - *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))));
       else *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) - (float128)SvUVX(b);
       return obj_ref;
     }

     if(SvIOK(b)) {
       if(SWITCH_ARGS) *pc = (float128)SvIVX(b) - *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))));
       else *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) - (float128)SvIVX(b);
       return obj_ref;
     }

     if(SvNOK(b)) {
       if(SWITCH_ARGS) *pc = (float128)SvNVX(b) - *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))));
       else *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) - (float128)SvNVX(b);
       return obj_ref;
     }
     if(SvPOK(b)) {
       if(!looks_like_number(b)) nnum++;
       if(SWITCH_ARGS) *pc = strtoflt128(SvPV_nolen(b), NULL) - *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))));
       else *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) - strtoflt128(SvPV_nolen(b), NULL);
       return obj_ref;
     }
     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Complex_C::Q")) {
         *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) - *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(b))));
         return obj_ref;
       }
     }

     croak("Invalid argument supplied to Math::Complex_C::Q::_overload_sub function");
}

SV * _overload_sqrt(pTHX_ SV * a, SV * b, SV * third) {
     MATH_COMPLEX *pc;
     SV * obj_ref, * obj;

     New(42, pc, 1, MATH_COMPLEX);
     if(pc == NULL) croak("Failed to allocate memory in _overload_sqrt function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Complex_C::Q");

     *pc = csqrtq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))));

     sv_setiv(obj, INT2PTR(IV,pc));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * _overload_pow_eq(pTHX_ SV * a, SV * b, SV * third) {
#ifdef MINGW_W64_BUGGY
     croak("**= (pow-equal) not overloaded for mingw-w64 compilers");
#else
     MATH_COMPLEX t;
     SvREFCNT_inc(a);

     if(SvUOK(b)) {
       __real__ t = (float128)SvUVX(b);
       __imag__ t = 0.0Q;
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) = cpowq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))), t);
       return a;
     }
     if(SvIOK(b)) {
       __real__ t = (float128)SvIVX(b);
       __imag__ t = 0.0Q;
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) = cpowq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))), t);
       return a;
     }
     if(SvNOK(b)) {
       __real__ t = (float128)SvNVX(b);
       __imag__ t = 0.0Q;
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) = cpowq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))), t);
       return a;
     }
     if(SvPOK(b)) {
       if(!looks_like_number(b)) nnum++;
       __real__ t = strtoflt128(SvPV_nolen(b), NULL);
       __imag__ t = 0.0Q;
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) = cpowq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))), t);
       return a;
     }
     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Complex_C::Q")) {
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) = cpowq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))),
                                                        *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(b)))));
         return a;
       }
     }
     SvREFCNT_dec(a);
     croak("Invalid argument supplied to Math::Complex_C::Q::_overload_pow_eq function");
#endif
}

SV * _overload_mul_eq(pTHX_ SV * a, SV * b, SV * third) {
     SvREFCNT_inc(a);

     if(SvUOK(b)) {
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) *= (float128)SvUVX(b);
       return a;
     }

     if(SvIOK(b)) {
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) *= (float128)SvIVX(b);
       return a;
     }

     if(SvNOK(b)) {
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) *= (float128)SvNVX(b);
       return a;
     }

     if(SvPOK(b)) {
       if(!looks_like_number(b)) nnum++;
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) *= strtoflt128(SvPV_nolen(b), NULL);
       return a;
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Complex_C::Q")) {
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) *= *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(b))));
         return a;
       }
     }

     SvREFCNT_dec(a);
     croak("Invalid argument supplied to Math::Complex_C::Q::_overload_mul_eq function");
}

SV * _overload_add_eq(pTHX_ SV * a, SV * b, SV * third) {
     SvREFCNT_inc(a);

     if(SvUOK(b)) {
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) += (float128)SvUVX(b);
       return a;
     }

     if(SvIOK(b)) {
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) += (float128)SvIVX(b);
       return a;
     }

     if(SvNOK(b)) {
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) += (float128)SvNVX(b);
       return a;
     }

     if(SvPOK(b)) {
       if(!looks_like_number(b)) nnum++;
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) += strtoflt128(SvPV_nolen(b), NULL);
       return a;
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Complex_C::Q")) {
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) += *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(b))));
         return a;
       }
     }

     SvREFCNT_dec(a);
     croak("Invalid argument supplied to Math::Complex_C::Q::_overload_add_eq function");
}

SV * _overload_div_eq(pTHX_ SV * a, SV * b, SV * third) {
     SvREFCNT_inc(a);

     if(SvUOK(b)) {
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) /= (float128)SvUVX(b);
       return a;
     }

     if(SvIOK(b)) {
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) /= (float128)SvIVX(b);
       return a;
     }

     if(SvNOK(b)) {
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) /= (float128)SvNVX(b);
       return a;
     }

     if(SvPOK(b)) {
       if(!looks_like_number(b)) nnum++;
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) /= strtoflt128(SvPV_nolen(b), NULL);
       return a;
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Complex_C::Q")) {
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) /= *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(b))));
         return a;
       }
     }

     SvREFCNT_dec(a);
     croak("Invalid argument supplied to Math::Complex_C::Q::_overload_div_eq function");
}

SV * _overload_sub_eq(pTHX_ SV * a, SV * b, SV * third) {
     SvREFCNT_inc(a);

     if(SvUOK(b)) {
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) -= (float128)SvUVX(b);
       return a;
     }

     if(SvIOK(b)) {
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) -= (float128)SvIVX(b);
       return a;
     }

     if(SvNOK(b)) {
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) -= (float128)SvNVX(b);
       return a;
     }

     if(SvPOK(b)) {
       if(!looks_like_number(b)) nnum++;
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) -= strtoflt128(SvPV_nolen(b), NULL);
       return a;
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Complex_C::Q")) {
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) -= *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(b))));
         return a;
       }
     }

     SvREFCNT_dec(a);
     croak("Invalid argument supplied to Math::Complex_C::Q::_overload_sub_eq function");
}

SV * _overload_copy(pTHX_ SV * a, SV * second, SV * third) {

     MATH_COMPLEX *pc;
     SV * obj_ref, * obj;

     New(42, pc, 1, MATH_COMPLEX);
     if(pc == NULL) croak("Failed to allocate memory in _overload_copy function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Complex_C::Q");

     __real__ *pc = __real__ *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))));
     __imag__ *pc = __imag__ *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))));

     sv_setiv(obj, INT2PTR(IV,pc));
     SvREADONLY_on(obj);
     return obj_ref;

}

SV * _overload_abs(pTHX_ SV * rop, SV * second, SV * third) {
     return newSVnv(cabsq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop))))));
}

SV * _overload_exp(pTHX_ SV * a, SV * b, SV * third) {
#ifdef MINGW_W64_BUGGY
     croak("exp not overloaded with mingw-w64 compilers");
#else
     MATH_COMPLEX *pc;
     SV * obj_ref, * obj;

     New(42, pc, 1, MATH_COMPLEX);
     if(pc == NULL) croak("Failed to allocate memory in _overload_exp function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Complex_C::Q");

     *pc = cexpq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))));

     sv_setiv(obj, INT2PTR(IV,pc));
     SvREADONLY_on(obj);
     return obj_ref;
#endif
}

SV * _overload_log(pTHX_ SV * a, SV * b, SV * third) {
     MATH_COMPLEX *pc;
     SV * obj_ref, * obj;

     New(42, pc, 1, MATH_COMPLEX);
     if(pc == NULL) croak("Failed to allocate memory in _overload_log function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Complex_C::Q");

     *pc = clogq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))));

     sv_setiv(obj, INT2PTR(IV,pc));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * _overload_sin(pTHX_ SV * a, SV * b, SV * third) {
#ifdef MINGW_W64_BUGGY
     croak("sin not overloaded for mingw-w64 compilers");
#else
     MATH_COMPLEX *pc;
     SV * obj_ref, * obj;

     New(42, pc, 1, MATH_COMPLEX);
     if(pc == NULL) croak("Failed to allocate memory in _overload_sin function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Complex_C::Q");

     *pc = csinq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))));

     sv_setiv(obj, INT2PTR(IV,pc));
     SvREADONLY_on(obj);
     return obj_ref;
#endif
}

SV * _overload_cos(pTHX_ SV * a, SV * b, SV * third) {
#ifdef MINGW_W64_BUGGY
     croak("cos not overloaded for mingw-w64 compilers");
#else
     MATH_COMPLEX *pc;
     SV * obj_ref, * obj;

     New(42, pc, 1, MATH_COMPLEX);
     if(pc == NULL) croak("Failed to allocate memory in _overload_cos function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Complex_C::Q");

     *pc = ccosq(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))));

     sv_setiv(obj, INT2PTR(IV,pc));
     SvREADONLY_on(obj);
     return obj_ref;
#endif
}

SV * _overload_atan2(pTHX_ SV * a, SV * b, SV * third) {
     MATH_COMPLEX *pc;
     SV * obj_ref, * obj;

     New(42, pc, 1, MATH_COMPLEX);
     if(pc == NULL) croak("Failed to allocate memory in _overload_atan2 function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Complex_C::Q");

     *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) /
           *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(b)))) ;

     *pc = catanq(*pc);

     sv_setiv(obj, INT2PTR(IV,pc));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * get_nanq(pTHX) {
     return newSVnv(_get_nan());
}

SV * get_infq(pTHX) {
     return newSVnv(_get_inf());
}

SV * get_neg_infq(pTHX) {
     return newSVnv(_get_neg_inf());
}

SV * _complex_type(pTHX) {
    return newSVpv("__complex128", 0);
}

SV * _double_type(pTHX) {
    return newSVpv("__float128", 0);
}

SV * _get_nv(pTHX_ SV * x) {
     return newSVnv(SvNV(x));
}

SV * _which_package(pTHX_ SV * b) {
     if(sv_isobject(b)) return newSVpv(HvNAME(SvSTASH(SvRV(b))), 0);
     return newSVpv("Not an object", 0);
}

SV * _wrap_count(pTHX) {
     return newSVuv(PL_sv_count);
}

SV * _ivsize(pTHX) {
     return newSViv(sizeof(IV));
}

SV * _nvsize(pTHX) {
     return newSViv(sizeof(NV));
}

SV * _doublesize(pTHX) {
     return newSViv(sizeof(double));
}

SV * _longdoublesize(pTHX) {
     return newSViv(sizeof(long double));
}

SV * _float128size(pTHX) {
     return newSViv(sizeof(float128));
}

SV * _double_Complexsize(pTHX) {
     return newSViv(sizeof(double _Complex));
}

SV * _longdouble_Complexsize(pTHX) {
     return newSViv(sizeof(long double _Complex));
}


SV * _float128_Complexsize(pTHX) {
     return newSViv(sizeof(complex128));
}

void _q_to_str(pTHX_ SV * ld) {
     dXSARGS;
     MATH_COMPLEX t;
     char *rbuffer;
     int query;

     if(sv_isobject(ld)) {
       const char *h = HvNAME(SvSTASH(SvRV(ld)));
       if(strEQ(h, "Math::Complex_C::Q")) {
          EXTEND(SP, 2);

          t = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(ld))));
/**/
          Newx(rbuffer, 15 + _MATH_COMPLEX_C_Q_DIGITS, char);
          if(rbuffer == NULL) croak("Failed to allocate memory in q_to_str");

          query = _is_inf(__real__ t);
          if(query || _is_nan(__real__ t))
            sprintf(rbuffer, "%s", query ? query > 0 ? "inf"
                                                     : "-inf"
                                         : "nan");
          else
           quadmath_snprintf(rbuffer, 15 + _MATH_COMPLEX_C_Q_DIGITS, "%.*Qe",
                             _MATH_COMPLEX_C_Q_DIGITS - 1, __real__ t);

          ST(0) = sv_2mortal(newSVpv(rbuffer, 0));

          query = _is_inf(__imag__ t);
          if(query || _is_nan(__imag__ t))
            sprintf(rbuffer, "%s", query ? query > 0 ? "inf"
                                                     : "-inf"
                                         : "nan");
          else
           quadmath_snprintf(rbuffer, 15 + _MATH_COMPLEX_C_Q_DIGITS, "%.*Qe",
                             _MATH_COMPLEX_C_Q_DIGITS - 1, __imag__ t);

          ST(1) = sv_2mortal(newSVpv(rbuffer, 0));
/**/
          Safefree(rbuffer);
          XSRETURN(2);
       }
       else croak("q_to_str function needs a Math::Complex_C::Q arg but was supplied with a %s arg", h);
     }
     else croak("Invalid argument supplied to Math::Complex_C::Q::q_to_str function");
}

void _q_to_strp(pTHX_ SV * ld, int decimal_prec) {
     dXSARGS;
     MATH_COMPLEX t;
     char *rbuffer;
     int query;

     if(decimal_prec < 1)croak("2nd arg (precision) to _q_to_strp  must be at least 1");

     if(sv_isobject(ld)) {
       const char *h = HvNAME(SvSTASH(SvRV(ld)));
       if(strEQ(h, "Math::Complex_C::Q")) {
          EXTEND(SP, 2);
          t = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(ld))));
/* new */
          Newx(rbuffer, 12 + decimal_prec, char);
          if(rbuffer == NULL) croak("Failed to allocate memory in q_to_strp");

          query = _is_inf(__real__ t);
          if(query || _is_nan(__real__ t))
            sprintf(rbuffer, "%s", query ? query > 0 ? "inf"
                                                     : "-inf"
                                         : "nan");
          else
           quadmath_snprintf(rbuffer, 12 + _MATH_COMPLEX_C_Q_DIGITS, "%.*Qe",
                             decimal_prec - 1, __real__ t);

          ST(0) = sv_2mortal(newSVpv(rbuffer, 0));

          query = _is_inf(__imag__ t);
          if(query || _is_nan(__imag__ t))
            sprintf(rbuffer, "%s", query ? query > 0 ? "inf"
                                                     : "-inf"
                                         : "nan");
          else
           quadmath_snprintf(rbuffer, 12 + _MATH_COMPLEX_C_Q_DIGITS, "%.*Qe",
                             decimal_prec - 1, __imag__ t);

          ST(1) = sv_2mortal(newSVpv(rbuffer, 0));
/**/
/* old
          Newx(rbuffer, 12 + decimal_prec, char);
          if(rbuffer == NULL) croak("Failed to allocate memory in q_to_strp");

          quadmath_snprintf(rbuffer, 12 + decimal_prec, "%.*Qe", decimal_prec - 1, __real__ t);
          ST(0) = sv_2mortal(newSVpv(rbuffer, 0));

          quadmath_snprintf(rbuffer, 12 + decimal_prec, "%.*Qe", decimal_prec - 1, __imag__ t);
          ST(1) = sv_2mortal(newSVpv(rbuffer, 0));
*/

          Safefree(rbuffer);
          XSRETURN(2);
       }
       else croak("q_to_strp function needs a Math::Complex_C::Q arg but was supplied with a %s arg", h);
     }
     else croak("Invalid argument supplied to Math::Complex_C::Q::q_to_strp function");
}

SV * _LDBL_DIG(pTHX) {
#ifdef LDBL_DIG
     return newSViv(LDBL_DIG);
#else
     return 0;
#endif
}

SV * _FLT128_DIG(pTHX) {
#ifdef FLT128_DIG
     return newSViv(FLT128_DIG);
#else
     return 0;
#endif
}

SV * _get_xs_version(pTHX) {
     return newSVpv(XS_VERSION, 0);
}

SV * _itsa(pTHX_ SV * a) {
     if(SvUOK(a)) return newSVuv(1);
     if(SvIOK(a)) return newSVuv(2);
     if(SvNOK(a)) return newSVuv(3);
     if(SvPOK(a)) return newSVuv(4);
     if(sv_isobject(a)) {
       const char *h = HvNAME(SvSTASH(SvRV(a)));
       if(strEQ(h, "Math::Float128"))     return newSVuv(113);
       if(strEQ(h, "Math::Complex_C::Q")) return newSVuv(226);
     }
     return newSVuv(0);
}

int _mingw_w64_bug(void) {
#ifdef MINGW_W64_BUGGY
    return 1;
#else
    return 0;
#endif
}

int _gcc_tan_bug(void) {
#if defined(GCC_TAN_BUG)
    return 1;
#else
    return 0;
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






MODULE = Math::Complex_C::Q  PACKAGE = Math::Complex_C::Q

PROTOTYPES: DISABLE


void
q_set_prec (x)
	int	x
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        q_set_prec(x);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

int
q_get_prec ()


int
is_nanq (a)
	SV *	a
CODE:
  RETVAL = is_nanq (aTHX_ a);
OUTPUT:  RETVAL

int
is_infq (a)
	SV *	a
CODE:
  RETVAL = is_infq (aTHX_ a);
OUTPUT:  RETVAL

SV *
create_cq ()
CODE:
  RETVAL = create_cq (aTHX);
OUTPUT:  RETVAL


void
assign_cq (rop, d1, d2)
	SV *	rop
	SV *	d1
	SV *	d2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        assign_cq(aTHX_ rop, d1, d2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
set_real_cq (rop, d1)
	SV *	rop
	SV *	d1
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        set_real_cq(aTHX_ rop, d1);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
set_imag_cq (rop, d2)
	SV *	rop
	SV *	d2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        set_imag_cq(aTHX_ rop, d2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
F2cq (rop, d1, d2)
	SV *	rop
	SV *	d1
	SV *	d2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        F2cq(aTHX_ rop, d1, d2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
cq2F (rop1, rop2, op)
	SV *	rop1
	SV *	rop2
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        cq2F(aTHX_ rop1, rop2, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
mul_cq (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        mul_cq(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
mul_c_nvq (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        mul_c_nvq(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
mul_c_ivq (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        mul_c_ivq(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
mul_c_uvq (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        mul_c_uvq(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
mul_c_pvq (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        mul_c_pvq(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
div_cq (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        div_cq(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
div_c_nvq (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        div_c_nvq(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
div_c_ivq (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        div_c_ivq(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
div_c_uvq (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        div_c_uvq(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
div_c_pvq (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        div_c_pvq(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
add_cq (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        add_cq(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
add_c_nvq (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        add_c_nvq(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
add_c_ivq (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        add_c_ivq(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
add_c_uvq (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        add_c_uvq(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
add_c_pvq (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        add_c_pvq(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
sub_cq (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        sub_cq(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
sub_c_nvq (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        sub_c_nvq(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
sub_c_ivq (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        sub_c_ivq(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
sub_c_uvq (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        sub_c_uvq(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
sub_c_pvq (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        sub_c_pvq(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
DESTROY (op)
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        DESTROY(aTHX_ op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
real_cq (op)
	SV *	op
CODE:
  RETVAL = real_cq (aTHX_ op);
OUTPUT:  RETVAL

SV *
real_cq2F (op)
	SV *	op
CODE:
  RETVAL = real_cq2F (aTHX_ op);
OUTPUT:  RETVAL

void
real_cq2str (op)
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        real_cq2str(aTHX_ op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
imag_cq (op)
	SV *	op
CODE:
  RETVAL = imag_cq (aTHX_ op);
OUTPUT:  RETVAL

SV *
imag_cq2F (op)
	SV *	op
CODE:
  RETVAL = imag_cq2F (aTHX_ op);
OUTPUT:  RETVAL

void
imag_cq2str (op)
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        imag_cq2str(aTHX_ op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
arg_cq (op)
	SV *	op
CODE:
  RETVAL = arg_cq (aTHX_ op);
OUTPUT:  RETVAL

SV *
arg_cq2F (op)
	SV *	op
CODE:
  RETVAL = arg_cq2F (aTHX_ op);
OUTPUT:  RETVAL

void
arg_cq2str (op)
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        arg_cq2str(aTHX_ op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
abs_cq (op)
	SV *	op
CODE:
  RETVAL = abs_cq (aTHX_ op);
OUTPUT:  RETVAL

SV *
abs_cq2F (op)
	SV *	op
CODE:
  RETVAL = abs_cq2F (aTHX_ op);
OUTPUT:  RETVAL

void
abs_cq2str (op)
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        abs_cq2str(aTHX_ op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
conj_cq (rop, op)
	SV *	rop
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        conj_cq(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
acos_cq (rop, op)
	SV *	rop
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        acos_cq(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
asin_cq (rop, op)
	SV *	rop
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        asin_cq(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
atan_cq (rop, op)
	SV *	rop
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        atan_cq(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
cos_cq (rop, op)
	SV *	rop
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        cos_cq(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
sin_cq (rop, op)
	SV *	rop
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        sin_cq(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
tan_cq (rop, op)
	SV *	rop
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        tan_cq(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
acosh_cq (rop, op)
	SV *	rop
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        acosh_cq(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
asinh_cq (rop, op)
	SV *	rop
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        asinh_cq(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
atanh_cq (rop, op)
	SV *	rop
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        atanh_cq(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
cosh_cq (rop, op)
	SV *	rop
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        cosh_cq(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
sinh_cq (rop, op)
	SV *	rop
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        sinh_cq(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
tanh_cq (rop, op)
	SV *	rop
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        tanh_cq(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
exp_cq (rop, op)
	SV *	rop
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        exp_cq(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
log_cq (rop, op)
	SV *	rop
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        log_cq(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
sqrt_cq (rop, op)
	SV *	rop
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        sqrt_cq(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
proj_cq (rop, op)
	SV *	rop
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        proj_cq(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
pow_cq (rop, op, exp)
	SV *	rop
	SV *	op
	SV *	exp
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        pow_cq(aTHX_ rop, op, exp);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
_overload_true (rop, second, third)
	SV *	rop
	SV *	second
	SV *	third
CODE:
  RETVAL = _overload_true (aTHX_ rop, second, third);
OUTPUT:  RETVAL

SV *
_overload_not (rop, second, third)
	SV *	rop
	SV *	second
	SV *	third
CODE:
  RETVAL = _overload_not (aTHX_ rop, second, third);
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
_overload_pow (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_pow (aTHX_ a, b, third);
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
_overload_add (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_add (aTHX_ a, b, third);
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
_overload_sub (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_sub (aTHX_ a, b, third);
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
_overload_pow_eq (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_pow_eq (aTHX_ a, b, third);
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
_overload_add_eq (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_add_eq (aTHX_ a, b, third);
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
_overload_sub_eq (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_sub_eq (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_copy (a, second, third)
	SV *	a
	SV *	second
	SV *	third
CODE:
  RETVAL = _overload_copy (aTHX_ a, second, third);
OUTPUT:  RETVAL

SV *
_overload_abs (rop, second, third)
	SV *	rop
	SV *	second
	SV *	third
CODE:
  RETVAL = _overload_abs (aTHX_ rop, second, third);
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
_overload_log (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_log (aTHX_ a, b, third);
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
get_nanq ()
CODE:
  RETVAL = get_nanq (aTHX);
OUTPUT:  RETVAL


SV *
get_infq ()
CODE:
  RETVAL = get_infq (aTHX);
OUTPUT:  RETVAL


SV *
get_neg_infq ()
CODE:
  RETVAL = get_neg_infq (aTHX);
OUTPUT:  RETVAL


SV *
_complex_type ()
CODE:
  RETVAL = _complex_type (aTHX);
OUTPUT:  RETVAL


SV *
_double_type ()
CODE:
  RETVAL = _double_type (aTHX);
OUTPUT:  RETVAL


SV *
_get_nv (x)
	SV *	x
CODE:
  RETVAL = _get_nv (aTHX_ x);
OUTPUT:  RETVAL

SV *
_which_package (b)
	SV *	b
CODE:
  RETVAL = _which_package (aTHX_ b);
OUTPUT:  RETVAL

SV *
_wrap_count ()
CODE:
  RETVAL = _wrap_count (aTHX);
OUTPUT:  RETVAL


SV *
_ivsize ()
CODE:
  RETVAL = _ivsize (aTHX);
OUTPUT:  RETVAL


SV *
_nvsize ()
CODE:
  RETVAL = _nvsize (aTHX);
OUTPUT:  RETVAL


SV *
_doublesize ()
CODE:
  RETVAL = _doublesize (aTHX);
OUTPUT:  RETVAL


SV *
_longdoublesize ()
CODE:
  RETVAL = _longdoublesize (aTHX);
OUTPUT:  RETVAL


SV *
_float128size ()
CODE:
  RETVAL = _float128size (aTHX);
OUTPUT:  RETVAL


SV *
_double_Complexsize ()
CODE:
  RETVAL = _double_Complexsize (aTHX);
OUTPUT:  RETVAL


SV *
_longdouble_Complexsize ()
CODE:
  RETVAL = _longdouble_Complexsize (aTHX);
OUTPUT:  RETVAL


SV *
_float128_Complexsize ()
CODE:
  RETVAL = _float128_Complexsize (aTHX);
OUTPUT:  RETVAL


void
_q_to_str (ld)
	SV *	ld
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        _q_to_str(aTHX_ ld);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
_q_to_strp (ld, decimal_prec)
	SV *	ld
	int	decimal_prec
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        _q_to_strp(aTHX_ ld, decimal_prec);
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
_FLT128_DIG ()
CODE:
  RETVAL = _FLT128_DIG (aTHX);
OUTPUT:  RETVAL


SV *
_get_xs_version ()
CODE:
  RETVAL = _get_xs_version (aTHX);
OUTPUT:  RETVAL


SV *
_itsa (a)
	SV *	a
CODE:
  RETVAL = _itsa (aTHX_ a);
OUTPUT:  RETVAL

int
_mingw_w64_bug ()


int
_gcc_tan_bug ()


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

