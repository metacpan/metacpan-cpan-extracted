
#ifdef  __MINGW32__
#ifndef __USE_MINGW_ANSI_STDIO
#define __USE_MINGW_ANSI_STDIO 1
#endif
#endif

#define PERL_NO_GET_CONTEXT 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


#include "math_complex_c_include.h"

#define MATH_COMPLEX double _Complex

#ifdef USE_CPOWL
#define MY_CPOW (MATH_COMPLEX)cpowl
#else
#define MY_CPOW cpow
#endif

int nnum = 0;

void d_set_prec(pTHX_ int x) {
    if(x < 1)croak("1st arg (precision) to d_set_prec must be at least 1");
    _MATH_COMPLEX_C_DIGITS = x;
}

int d_get_prec(void) {
    return _MATH_COMPLEX_C_DIGITS;
}

int _is_nan(double x) {
    if(x == x) return 0;
    return 1;
}

int _is_inf(double x) {
    if(x == 0) return 0;
    if(_is_nan(x)) return 0;
    if(x / x == x / x) return 0;
    if(x < 0) return -1;
    return 1;
}

double _get_nan(void) {
    double nanval = 0.0 / 0.0;
    return nanval;
}

double _get_inf(void) {
    double infval = 1.0 / 0.0;
    return infval;
}

double _get_neg_inf(void) {
    double inf = -1.0 / 0.0;
    return inf;
}

SV * create_c(pTHX) {

     MATH_COMPLEX *pc;
     SV * obj_ref, * obj;

     New(42, pc, 1, MATH_COMPLEX);
     if(pc == NULL) croak("Failed to allocate memory in create_c function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Complex_C");

     __real__ *pc = _get_nan();
     __imag__ *pc = _get_nan();

     sv_setiv(obj, INT2PTR(IV,pc));
     SvREADONLY_on(obj);
     return obj_ref;

}

void assign_c(pTHX_ SV * rop, SV * d1, SV * d2) {
     double _d1, _d2;

     if(SvUOK(d1)) {
       _d1 = (double)SvUVX(d1);
     }
     else {
       if(SvIOK(d1)) {
         _d1 = (double)SvIVX(d1);
       }
       else {
         if(SvNOK(d1)) {
           _d1 = (double)SvNVX(d1);
         }
         else {
           if(SvPOK(d1)) {
             if(!looks_like_number(d1)) nnum++;
             _d1 = strtod(SvPV_nolen(d1), NULL);
           }
           else {
             croak("Invalid 2nd arg supplied to assign_c function");
           }
         }
       }
     }

     if(SvUOK(d2)) {
       _d2 = (double)SvUVX(d2);
     }
     else {
       if(SvIOK(d2)) {
         _d2 = (double)SvIVX(d2);
       }
       else {
         if(SvNOK(d2)) {
           _d2 = (double)SvNVX(d2);
         }
         else {
           if(SvPOK(d2)) {
             if(!looks_like_number(d2)) nnum++;
             _d2 = strtod(SvPV_nolen(d2), NULL) ;
           }
           else {
             croak("Invalid 3rd arg supplied to assign_c function");
           }
         }
       }
     }

     __real__ *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = _d1;
     __imag__ *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = _d2;
}

void set_real_c(pTHX_ SV * rop, SV * d1) {
     double _d1;

     if(SvUOK(d1)) {
       _d1 = (double)SvUVX(d1);
     }
     else {
       if(SvIOK(d1)) {
         _d1 = (double)SvIVX(d1);
       }
       else {
         if(SvNOK(d1)) {
           _d1 = (double)SvNVX(d1);
         }
         else {
           if(SvPOK(d1)) {
             if(!looks_like_number(d1)) nnum++;
             _d1 = strtod(SvPV_nolen(d1), NULL) ;
           }
           else {
             croak("Invalid 2nd arg supplied to set_real_c function");
           }
         }
       }
     }

     __real__ *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = _d1;
}

void set_imag_c(pTHX_ SV * rop, SV * d2) {
     double _d2;

     if(SvUOK(d2)) {
       _d2 = (double)SvUVX(d2);
     }
     else {
       if(SvIOK(d2)) {
         _d2 = (double)SvIVX(d2);
       }
       else {
         if(SvNOK(d2)) {
           _d2 = (double)SvNVX(d2);
         }
         else {
           if(SvPOK(d2)) {
             if(!looks_like_number(d2)) nnum++;
             _d2 = strtod(SvPV_nolen(d2), NULL) ;
           }
           else {
             croak("Invalid 2nd arg supplied to set_imag_c function");
           }
         }
       }
     }

     __imag__ *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = _d2;
}


void mul_c(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) *
                                                   *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op2))));
}

void mul_c_nv(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) *
                                                   (double)SvNV(op2);
}

void mul_c_iv(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) *
                                                   (double)SvIV(op2);
}

void mul_c_uv(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) *
                                                   (double)SvUV(op2);
}

void mul_c_pv(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) *
                                                   strtod(SvPV_nolen(op2), NULL);
}

void div_c(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) /
                                                   *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op2))));
}

void div_c_nv(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) /
                                                   (double)SvNV(op2);
}

void div_c_iv(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) /
                                                   (double)SvIV(op2);
}

void div_c_uv(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) /
                                                   (double)SvUV(op2);
}

void div_c_pv(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) /
                                                   strtod(SvPV_nolen(op2), NULL);
}

void add_c(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) +
                                                   *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op2))));
}

void add_c_nv(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) +
                                                   (double)SvNV(op2);
}

void add_c_iv(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) +
                                                   (double)SvIV(op2);
}

void add_c_uv(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) +
                                                   (double)SvUV(op2);
}

void add_c_pv(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) +
                                                   strtod(SvPV_nolen(op2), NULL);
}

void sub_c(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) -
                                                   *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op2))));
}

void sub_c_nv(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) -
                                                   (double)SvNV(op2);
}

void sub_c_iv(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) -
                                                   (double)SvIV(op2);
}

void sub_c_uv(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) -
                                                   (double)SvUV(op2);
}

void sub_c_pv(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) -
                                                   strtod(SvPV_nolen(op2), NULL);
}

void DESTROY(pTHX_ SV *  op) {
     Safefree(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op))));
}

SV * real_c(pTHX_ SV * op) {
     return newSVnv(creal(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op))))));
}

SV * imag_c(pTHX_ SV * op) {
     return newSVnv(cimag(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op))))));
}

SV * arg_c(pTHX_ SV * op) {
     return newSVnv(carg(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op))))));
}

SV * abs_c(pTHX_ SV * op) {
     return newSVnv(cabs(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op))))));
}

void conj_c(pTHX_ SV * rop, SV * op) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = conj(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
}

void acos_c(pTHX_ SV * rop, SV * op) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = cacos(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
}

void asin_c(pTHX_ SV * rop, SV * op) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = casin(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
}

void atan_c(pTHX_ SV * rop, SV * op) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = catan(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
}

void cos_c(pTHX_ SV * rop, SV * op) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = ccos(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
}

void sin_c(pTHX_ SV * rop, SV * op) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = csin(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
}

void tan_c(pTHX_ SV * rop, SV * op) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = ctan(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
}

void acosh_c(pTHX_ SV * rop, SV * op) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = cacosh(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
}

void asinh_c(pTHX_ SV * rop, SV * op) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = casinh(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
}

void atanh_c(pTHX_ SV * rop, SV * op) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = catanh(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
}

void cosh_c(pTHX_ SV * rop, SV * op) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = ccosh(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
}

void sinh_c(pTHX_ SV * rop, SV * op) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = csinh(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
}

void tanh_c(pTHX_ SV * rop, SV * op) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = ctanh(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
}

void exp_c(pTHX_ SV * rop, SV * op) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = cexp(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
}

void log_c(pTHX_ SV * rop, SV * op) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = clog(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
}

void sqrt_c(pTHX_ SV * rop, SV * op) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = csqrt(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
}

void proj_c(pTHX_ SV * rop, SV * op) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = cproj(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
}

void pow_c(pTHX_ SV * rop, SV * op, SV * exp) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = MY_CPOW(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))),
                                                        *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(exp)))));
}

SV * _overload_true(pTHX_ SV * rop, SV * second, SV * third) {
     if (_is_nan(creal(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))))) &&
         _is_nan(cimag(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop))))))) return newSVuv(0);
     if(creal(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop))))) ||
        cimag(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))))) return newSVuv(1);
     return newSVuv(0);
}

SV * _overload_not(pTHX_ SV * rop, SV * second, SV * third) {
     if (_is_nan(creal(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))))) &&
         _is_nan(cimag(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop))))))) return newSVuv(1);
     if(creal(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop))))) ||
        cimag(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))))) return newSVuv(0);
     return newSVuv(1);
}

SV * _overload_equiv(pTHX_ SV * a, SV * b, SV * third) {
      if(SvUOK(b)) {
       if((double)SvUVX(b) == creal(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))))) &&
          0.0              == cimag(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))))) return newSVuv(1);
       return newSVuv(0);
     }
     if(SvIOK(b)) {
       if((double)SvIVX(b) == creal(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))))) &&
          0.0              == cimag(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))))) return newSVuv(1);
       return newSVuv(0);
     }
     if(SvNOK(b)) {
       if((double)SvNVX(b) == creal(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))))) &&
          0.0    == cimag(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))))) return newSVuv(1);
       return newSVuv(0);
     }

     if(SvPOK(b)) {
       if(!looks_like_number(b)) nnum++;
       if(strtod(SvPV_nolen(b), NULL) == creal(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))))) &&
          0.0 == cimag(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))))) return newSVuv(1);
       return newSVuv(0);
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Complex_C")) {
         if(creal(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))))) == creal(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(b))))) &&
            cimag(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))))) == cimag(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(b))))))
              return newSVuv(1);
         return newSVuv(0);
       }
     }

     croak("Invalid argument supplied to Math::Complex_C::_overload_equiv function");
}

SV * _overload_not_equiv(pTHX_ SV * a, SV * b, SV * third) {
     if(SvUOK(b)) {
       if((double)SvUVX(b) == creal(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))))) &&
          0.0              == cimag(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))))) return newSVuv(0);
       return newSVuv(1);
     }
     if(SvIOK(b)) {
       if((double)SvIVX(b) == creal(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))))) &&
          0.0              == cimag(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))))) return newSVuv(0);
       return newSVuv(1);
     }
     if(SvNOK(b)) {
       if((double)SvNVX(b) == creal(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))))) &&
          0.0    == cimag(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))))) return newSVuv(0);
       return newSVuv(1);
     }
     if(SvPOK(b)) {
       if(!looks_like_number(b)) nnum++;
       if(strtod(SvPV_nolen(b), NULL) == creal(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))))) &&
          0.0 == cimag(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))))) return newSVuv(0);
       return newSVuv(1);
     }
     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Complex_C")) {
         if(creal(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))))) == creal(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(b))))) &&
            cimag(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))))) == cimag(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(b))))))
              return newSVuv(0);
         return newSVuv(1);
       }
     }

     croak("Invalid argument supplied to Math::Complex_C::_overload_not_equiv function");
}


SV * _overload_pow(pTHX_ SV * a, SV * b, SV * third) {
     MATH_COMPLEX *pc, t;
     SV * obj_ref, * obj;

     New(42, pc, 1, MATH_COMPLEX);
     if(pc == NULL) croak("Failed to allocate memory in _overload_pow function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Complex_C");

     sv_setiv(obj, INT2PTR(IV,pc));
     SvREADONLY_on(obj);

     if(SvUOK(b)) {
       __real__ t = (double)SvUVX(b);
       __imag__ t = 0.0;
       if(SWITCH_ARGS) {
         *pc = MY_CPOW( t, *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) );
         return obj_ref;
       }
       *pc = MY_CPOW(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))), t);
       return obj_ref;
     }

     if(SvIOK(b)) {
       __real__ t = (double)SvIVX(b);
       __imag__ t = 0.0;
       if(SWITCH_ARGS) {
         *pc = MY_CPOW( t, *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) );
         return obj_ref;
       }
       *pc = MY_CPOW(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))), t);
       return obj_ref;
     }

     if(SvNOK(b)) {
       __real__ t = (double)SvNVX(b);
       __imag__ t = 0.0;
       if(SWITCH_ARGS) {
         *pc = MY_CPOW( t, *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) );
         return obj_ref;
       }
       *pc = MY_CPOW(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))), t);
       return obj_ref;
     }

     if(SvPOK(b)) {
       if(!looks_like_number(b)) nnum++;
       __real__ t = strtod(SvPV_nolen(b), NULL);
       __imag__ t = 0.0;
       if(SWITCH_ARGS) {
         *pc = MY_CPOW( t, *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) );
         return obj_ref;
       }
       *pc = MY_CPOW(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))), t);
       return obj_ref;
     }
     else if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Complex_C")) {
         *pc = MY_CPOW(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))), *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(b)))));
         return obj_ref;
       }
     }
     else croak("Invalid argument supplied to Math::Complex_C::_overload_pow function");
}

SV * _overload_mul(pTHX_ SV * a, SV * b, SV * third) {
     MATH_COMPLEX *pc;
     SV * obj_ref, * obj;

     New(42, pc, 1, MATH_COMPLEX);
     if(pc == NULL) croak("Failed to allocate memory in _overload_mul function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Complex_C");

     sv_setiv(obj, INT2PTR(IV,pc));
     SvREADONLY_on(obj);

     if(SvUOK(b)) {
       *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) * (double)SvUVX(b);
       return obj_ref;
     }

     if(SvIOK(b)) {
       *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) * (double)SvIVX(b);
       return obj_ref;
     }

     if(SvNOK(b)) {
       *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) * (double)SvNVX(b);
       return obj_ref;
     }
     if(SvPOK(b)) {
       if(!looks_like_number(b)) nnum++;
       *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) * strtod(SvPV_nolen(b), NULL);
       return obj_ref;
     }
     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Complex_C")) {
         *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) * *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(b))));
         return obj_ref;
       }
     }

     croak("Invalid argument supplied to Math::Complex_C::_overload_mul function");
}

SV * _overload_add(pTHX_ SV * a, SV * b, SV * third) {
     MATH_COMPLEX *pc;
     SV * obj_ref, * obj;

     New(42, pc, 1, MATH_COMPLEX);
     if(pc == NULL) croak("Failed to allocate memory in _overload_add function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Complex_C");

     sv_setiv(obj, INT2PTR(IV,pc));
     SvREADONLY_on(obj);

     if(SvUOK(b)) {
       *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) + (double)SvUVX(b);
       return obj_ref;
     }

     if(SvIOK(b)) {
       *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) + (double)SvIVX(b);
       return obj_ref;
     }

     if(SvNOK(b)) {
       *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) + (double)SvNVX(b);
       return obj_ref;
     }
     if(SvPOK(b)) {
       if(!looks_like_number(b)) nnum++;
       *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) + strtod(SvPV_nolen(b), NULL);
       return obj_ref;
     }
     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Complex_C")) {
         *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) + *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(b))));
         return obj_ref;
       }
     }

     croak("Invalid argument supplied to Math::Complex_C::_overload_add function");
}

SV * _overload_div(pTHX_ SV * a, SV * b, SV * third) {
     MATH_COMPLEX *pc;
     SV * obj_ref, * obj;

     New(42, pc, 1, MATH_COMPLEX);
     if(pc == NULL) croak("Failed to allocate memory in _overload_div function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Complex_C");

     sv_setiv(obj, INT2PTR(IV,pc));
     SvREADONLY_on(obj);

     if(SvUOK(b)) {
       if(SWITCH_ARGS) *pc = (double)SvUVX(b) / *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))));
       else *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) / (double)SvUVX(b);
       return obj_ref;
     }

     if(SvIOK(b)) {
       if(SWITCH_ARGS) *pc = (double)SvIVX(b) / *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))));
       else *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) / (double)SvIVX(b);
       return obj_ref;
     }

     if(SvNOK(b)) {
       if(SWITCH_ARGS) *pc = (double)SvNVX(b) / *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))));
       else *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) / (double)SvNVX(b);
       return obj_ref;
     }
     if(SvPOK(b)) {
       if(!looks_like_number(b)) nnum++;
       if(SWITCH_ARGS) *pc = strtod(SvPV_nolen(b), NULL) / *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))));
       else *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) / strtod(SvPV_nolen(b), NULL);
       return obj_ref;
     }
     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Complex_C")) {
         *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) / *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(b))));
         return obj_ref;
       }
     }

     croak("Invalid argument supplied to Math::Complex_C::_overload_div function");
}

SV * _overload_sub(pTHX_ SV * a, SV * b, SV * third) {
     MATH_COMPLEX *pc;
     SV * obj_ref, * obj;

     New(42, pc, 1, MATH_COMPLEX);
     if(pc == NULL) croak("Failed to allocate memory in _overload_sub function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Complex_C");

     sv_setiv(obj, INT2PTR(IV,pc));
     SvREADONLY_on(obj);

     if(SvUOK(b)) {
       if(SWITCH_ARGS) *pc = (double)SvUVX(b) - *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))));
       else *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) - (double)SvUVX(b);
       return obj_ref;
     }

     if(SvIOK(b)) {
       if(SWITCH_ARGS) *pc = (double)SvIVX(b) - *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))));
       else *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) - (double)SvIVX(b);
       return obj_ref;
     }

     if(SvNOK(b)) {
       if(SWITCH_ARGS) *pc = (double)SvNVX(b) - *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))));
       else *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) - (double)SvNVX(b);
       return obj_ref;
     }
     if(SvPOK(b)) {
       if(!looks_like_number(b)) nnum++;
       if(SWITCH_ARGS) *pc = strtod(SvPV_nolen(b), NULL) - *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))));
       else *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) - strtod(SvPV_nolen(b), NULL);
       return obj_ref;
     }
     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Complex_C")) {
         *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) - *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(b))));
         return obj_ref;
       }
     }

     croak("Invalid argument supplied to Math::Complex_C::_overload_sub function");
}

SV * _overload_sqrt(pTHX_ SV * a, SV * b, SV * third) {
     MATH_COMPLEX *pc;
     SV * obj_ref, * obj;

     New(42, pc, 1, MATH_COMPLEX);
     if(pc == NULL) croak("Failed to allocate memory in _overload_sqrt function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Complex_C");

     *pc = csqrt(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))));

     sv_setiv(obj, INT2PTR(IV,pc));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * _overload_pow_eq(pTHX_ SV * a, SV * b, SV * third) {
     MATH_COMPLEX t;
     SvREFCNT_inc(a);

     if(SvUOK(b)) {
       __real__ t = (double)SvUVX(b);
       __imag__ t = 0.0;
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) = MY_CPOW(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))), t);
       return a;
     }
     if(SvIOK(b)) {
       __real__ t = (double)SvIVX(b);
       __imag__ t = 0.0;
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) = MY_CPOW(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))), t);
       return a;
     }
     if(SvNOK(b)) {
       __real__ t = (double)SvNVX(b);
       __imag__ t = 0.0;
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) = MY_CPOW(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))), t);
       return a;
     }
     if(SvPOK(b)) {
       if(!looks_like_number(b)) nnum++;
       __real__ t = strtod(SvPV_nolen(b), NULL);
       __imag__ t = 0.0;
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) = MY_CPOW(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))), t);
       return a;
     }
     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Complex_C")) {
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) = MY_CPOW(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))),
                                                        *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(b)))));
         return a;
       }
     }
     SvREFCNT_dec(a);
     croak("Invalid argument supplied to Math::Complex_C::_overload_pow_eq function");
}

SV * _overload_mul_eq(pTHX_ SV * a, SV * b, SV * third) {
     SvREFCNT_inc(a);

     if(SvUOK(b)) {
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) *= (double)SvUVX(b);
       return a;
     }

     if(SvIOK(b)) {
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) *= (double)SvIVX(b);
       return a;
     }

     if(SvNOK(b)) {
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) *= (double)SvNVX(b);
       return a;
     }

     if(SvPOK(b)) {
       if(!looks_like_number(b)) nnum++;
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) *= strtod(SvPV_nolen(b), NULL);
       return a;
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Complex_C")) {
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) *= *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(b))));
         return a;
       }
     }

     SvREFCNT_dec(a);
     croak("Invalid argument supplied to Math::Complex_C::_overload_mul_eq function");
}

SV * _overload_add_eq(pTHX_ SV * a, SV * b, SV * third) {
     SvREFCNT_inc(a);

     if(SvUOK(b)) {
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) += (double)SvUVX(b);
       return a;
     }

     if(SvIOK(b)) {
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) += (double)SvIVX(b);
       return a;
     }

     if(SvNOK(b)) {
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) += (double)SvNVX(b);
       return a;
     }

     if(SvPOK(b)) {
       if(!looks_like_number(b)) nnum++;
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) += strtod(SvPV_nolen(b), NULL);
       return a;
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Complex_C")) {
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) += *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(b))));
         return a;
       }
     }

     SvREFCNT_dec(a);
     croak("Invalid argument supplied to Math::Complex_C::_overload_add_eq function");
}

SV * _overload_div_eq(pTHX_ SV * a, SV * b, SV * third) {
     SvREFCNT_inc(a);

     if(SvUOK(b)) {
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) /= (double)SvUVX(b);
       return a;
     }

     if(SvIOK(b)) {
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) /= (double)SvIVX(b);
       return a;
     }

     if(SvNOK(b)) {
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) /= (double)SvNVX(b);
       return a;
     }

     if(SvPOK(b)) {
       if(!looks_like_number(b)) nnum++;
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) /= strtod(SvPV_nolen(b), NULL);
       return a;
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Complex_C")) {
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) /= *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(b))));
         return a;
       }
     }

     SvREFCNT_dec(a);
     croak("Invalid argument supplied to Math::Complex_C::_overload_div_eq function");
}

SV * _overload_sub_eq(pTHX_ SV * a, SV * b, SV * third) {
     SvREFCNT_inc(a);

     if(SvUOK(b)) {
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) -= (double)SvUVX(b);
       return a;
     }

     if(SvIOK(b)) {
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) -= (double)SvIVX(b);
       return a;
     }

     if(SvNOK(b)) {
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) -= (double)SvNVX(b);
       return a;
     }

     if(SvPOK(b)) {
       if(!looks_like_number(b)) nnum++;
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) -= strtod(SvPV_nolen(b), NULL);
       return a;
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Complex_C")) {
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) -= *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(b))));
         return a;
       }
     }

     SvREFCNT_dec(a);
     croak("Invalid argument supplied to Math::Complex_C::_overload_sub_eq function");
}

SV * _overload_copy(pTHX_ SV * a, SV * second, SV * third) {

     MATH_COMPLEX *pc;
     SV * obj_ref, * obj;

     New(42, pc, 1, MATH_COMPLEX);
     if(pc == NULL) croak("Failed to allocate memory in _overload_copy function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Complex_C");

     __real__ *pc = __real__ *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))));
     __imag__ *pc = __imag__ *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))));

     sv_setiv(obj, INT2PTR(IV,pc));
     SvREADONLY_on(obj);
     return obj_ref;

}

SV * _overload_abs(pTHX_ SV * rop, SV * second, SV * third) {
     return newSVnv(cabs(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop))))));
}

SV * _overload_exp(pTHX_ SV * a, SV * b, SV * third) {
     MATH_COMPLEX *pc;
     SV * obj_ref, * obj;

     New(42, pc, 1, MATH_COMPLEX);
     if(pc == NULL) croak("Failed to allocate memory in _overload_exp function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Complex_C");

     *pc = cexp(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))));

     sv_setiv(obj, INT2PTR(IV,pc));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * _overload_log(pTHX_ SV * a, SV * b, SV * third) {
     MATH_COMPLEX *pc;
     SV * obj_ref, * obj;

     New(42, pc, 1, MATH_COMPLEX);
     if(pc == NULL) croak("Failed to allocate memory in _overload_log function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Complex_C");

     *pc = clog(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))));

     sv_setiv(obj, INT2PTR(IV,pc));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * _overload_sin(pTHX_ SV * a, SV * b, SV * third) {
     MATH_COMPLEX *pc;
     SV * obj_ref, * obj;

     New(42, pc, 1, MATH_COMPLEX);
     if(pc == NULL) croak("Failed to allocate memory in _overload_sin function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Complex_C");

     *pc = csin(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))));

     sv_setiv(obj, INT2PTR(IV,pc));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * _overload_cos(pTHX_ SV * a, SV * b, SV * third) {
     MATH_COMPLEX *pc;
     SV * obj_ref, * obj;

     New(42, pc, 1, MATH_COMPLEX);
     if(pc == NULL) croak("Failed to allocate memory in _overload_cos function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Complex_C");

     *pc = ccos(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))));

     sv_setiv(obj, INT2PTR(IV,pc));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * _overload_atan2(pTHX_ SV * a, SV * b, SV * third) {
     MATH_COMPLEX *pc;
     SV * obj_ref, * obj;

     New(42, pc, 1, MATH_COMPLEX);
     if(pc == NULL) croak("Failed to allocate memory in _overload_atan2 function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Complex_C");

     *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) /
           *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(b)))) ;

     *pc = catan(*pc);

     sv_setiv(obj, INT2PTR(IV,pc));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * get_nan(pTHX) {
     return newSVnv(_get_nan());
}

SV * get_inf(pTHX) {
     return newSVnv(_get_inf());
}

SV * get_neg_inf(pTHX) {
     return newSVnv(_get_neg_inf());
}

SV * is_nan(pTHX_ SV * a) {
     if(SvNV(a) == SvNV(a)) return newSVuv(0);
     return newSVuv(1);
}

SV * is_inf(pTHX_ SV * a) {
     double t = (double)SvNV(a);
     if(t == 0) return newSVuv(0);
     if(t != t) return newSVuv(0);
     if(t / t == t / t) return newSVuv(0);
     if(t < 0) return newSViv(-1);
     return newSViv(1);
}

SV * _complex_type(pTHX) {
    return newSVpv("__complex128", 0);
}

SV * _double_type(pTHX) {
    return newSVpv("__long double", 0);
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

SV * _double_Complexsize(pTHX) {
     return newSViv(sizeof(double _Complex));
}

SV * _longdouble_Complexsize(pTHX) {
     return newSViv(sizeof(long double _Complex));
}


void _d_to_str(pTHX_ SV * ld) {
     dXSARGS;
     MATH_COMPLEX t;
     char *rbuffer;
     int query;

     if(sv_isobject(ld)) {
       const char *h = HvNAME(SvSTASH(SvRV(ld)));
       if(strEQ(h, "Math::Complex_C")) {
          EXTEND(SP, 2);

          t = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(ld))));
/**/
          Newx(rbuffer, 8 + _MATH_COMPLEX_C_DIGITS, char);
          if(rbuffer == NULL) croak("Failed to allocate memory in d_to_str");

          query = _is_inf(__real__ t);
          if(query || _is_nan(__real__ t))
            sprintf(rbuffer, "%s", query ? query > 0 ? "inf"
                                                     : "-inf"
                                         : "nan");
          else
           sprintf(rbuffer, "%.*e", _MATH_COMPLEX_C_DIGITS - 1, __real__ t);

          ST(0) = sv_2mortal(newSVpv(rbuffer, 0));

          query = _is_inf(__imag__ t);
          if(query || _is_nan(__imag__ t))
            sprintf(rbuffer, "%s", query ? query > 0 ? "inf"
                                                     : "-inf"
                                         : "nan");
          else
           sprintf(rbuffer, "%.*e", _MATH_COMPLEX_C_DIGITS - 1, __imag__ t);

          ST(1) = sv_2mortal(newSVpv(rbuffer, 0));
/**/
          Safefree(rbuffer);
          XSRETURN(2);
       }
       else croak("d_to_str function needs a Math::Complex_C arg but was supplied with a %s arg", h);
     }
     else croak("Invalid argument supplied to Math::Complex_C::d_to_str function");
}

void _d_to_strp(pTHX_ SV * ld, int decimal_prec) {
     dXSARGS;
     MATH_COMPLEX t;
     char *rbuffer;
     int query;

     if(decimal_prec < 1)croak("2nd arg (precision) to _d_to_strp  must be at least 1");

     if(sv_isobject(ld)) {
       const char *h = HvNAME(SvSTASH(SvRV(ld)));
       if(strEQ(h, "Math::Complex_C")) {
          EXTEND(SP, 2);
          t = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(ld))));
/* new */
          Newx(rbuffer, 8 + decimal_prec, char);
          if(rbuffer == NULL) croak("Failed to allocate memory in d_to_strp");

          query = _is_inf(__real__ t);
          if(query || _is_nan(__real__ t))
            sprintf(rbuffer, "%s", query ? query > 0 ? "inf"
                                                     : "-inf"
                                         : "nan");
          else
           sprintf(rbuffer, "%.*e", decimal_prec - 1, __real__ t);

          ST(0) = sv_2mortal(newSVpv(rbuffer, 0));

          query = _is_inf(__imag__ t);
          if(query || _is_nan(__imag__ t))
            sprintf(rbuffer, "%s", query ? query > 0 ? "inf"
                                                     : "-inf"
                                         : "nan");
          else
           sprintf(rbuffer, "%.*e", decimal_prec - 1, __imag__ t);

          ST(1) = sv_2mortal(newSVpv(rbuffer, 0));
/**/
          Safefree(rbuffer);
          XSRETURN(2);
       }
       else croak("d_to_strp function needs a Math::Complex_C arg but was supplied with a %s arg", h);
     }
     else croak("Invalid argument supplied to Math::Complex_C::d_to_strp function");
}

SV * _LDBL_DIG(pTHX) {
#ifdef LDBL_DIG
     return newSViv(LDBL_DIG);
#else
     return 0;
#endif
}

SV * _DBL_DIG(pTHX) {
#ifdef DBL_DIG
     return newSViv(DBL_DIG);
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
       if(strEQ(h, "Math::Complex_C")) return newSVuv(226);
     }
     return newSVuv(0);
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


MODULE = Math::Complex_C  PACKAGE = Math::Complex_C

PROTOTYPES: DISABLE


void
d_set_prec (x)
	int	x
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        d_set_prec(aTHX_ x);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

int
d_get_prec ()


int
_is_nan (x)
	double	x

int
_is_inf (x)
	double	x

double
_get_nan ()


double
_get_inf ()


double
_get_neg_inf ()


SV *
create_c ()
CODE:
  RETVAL = create_c (aTHX);
OUTPUT:  RETVAL


void
assign_c (rop, d1, d2)
	SV *	rop
	SV *	d1
	SV *	d2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        assign_c(aTHX_ rop, d1, d2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
set_real_c (rop, d1)
	SV *	rop
	SV *	d1
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        set_real_c(aTHX_ rop, d1);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
set_imag_c (rop, d2)
	SV *	rop
	SV *	d2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        set_imag_c(aTHX_ rop, d2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
mul_c (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        mul_c(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
mul_c_nv (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        mul_c_nv(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
mul_c_iv (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        mul_c_iv(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
mul_c_uv (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        mul_c_uv(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
mul_c_pv (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        mul_c_pv(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
div_c (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        div_c(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
div_c_nv (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        div_c_nv(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
div_c_iv (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        div_c_iv(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
div_c_uv (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        div_c_uv(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
div_c_pv (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        div_c_pv(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
add_c (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        add_c(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
add_c_nv (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        add_c_nv(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
add_c_iv (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        add_c_iv(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
add_c_uv (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        add_c_uv(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
add_c_pv (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        add_c_pv(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
sub_c (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        sub_c(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
sub_c_nv (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        sub_c_nv(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
sub_c_iv (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        sub_c_iv(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
sub_c_uv (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        sub_c_uv(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
sub_c_pv (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        sub_c_pv(aTHX_ rop, op1, op2);
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
real_c (op)
	SV *	op
CODE:
  RETVAL = real_c (aTHX_ op);
OUTPUT:  RETVAL

SV *
imag_c (op)
	SV *	op
CODE:
  RETVAL = imag_c (aTHX_ op);
OUTPUT:  RETVAL

SV *
arg_c (op)
	SV *	op
CODE:
  RETVAL = arg_c (aTHX_ op);
OUTPUT:  RETVAL

SV *
abs_c (op)
	SV *	op
CODE:
  RETVAL = abs_c (aTHX_ op);
OUTPUT:  RETVAL

void
conj_c (rop, op)
	SV *	rop
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        conj_c(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
acos_c (rop, op)
	SV *	rop
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        acos_c(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
asin_c (rop, op)
	SV *	rop
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        asin_c(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
atan_c (rop, op)
	SV *	rop
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        atan_c(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
cos_c (rop, op)
	SV *	rop
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        cos_c(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
sin_c (rop, op)
	SV *	rop
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        sin_c(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
tan_c (rop, op)
	SV *	rop
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        tan_c(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
acosh_c (rop, op)
	SV *	rop
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        acosh_c(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
asinh_c (rop, op)
	SV *	rop
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        asinh_c(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
atanh_c (rop, op)
	SV *	rop
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        atanh_c(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
cosh_c (rop, op)
	SV *	rop
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        cosh_c(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
sinh_c (rop, op)
	SV *	rop
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        sinh_c(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
tanh_c (rop, op)
	SV *	rop
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        tanh_c(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
exp_c (rop, op)
	SV *	rop
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        exp_c(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
log_c (rop, op)
	SV *	rop
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        log_c(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
sqrt_c (rop, op)
	SV *	rop
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        sqrt_c(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
proj_c (rop, op)
	SV *	rop
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        proj_c(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
pow_c (rop, op, exp)
	SV *	rop
	SV *	op
	SV *	exp
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        pow_c(aTHX_ rop, op, exp);
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
get_nan ()
CODE:
  RETVAL = get_nan (aTHX);
OUTPUT:  RETVAL


SV *
get_inf ()
CODE:
  RETVAL = get_inf (aTHX);
OUTPUT:  RETVAL


SV *
get_neg_inf ()
CODE:
  RETVAL = get_neg_inf (aTHX);
OUTPUT:  RETVAL


SV *
is_nan (a)
	SV *	a
CODE:
  RETVAL = is_nan (aTHX_ a);
OUTPUT:  RETVAL

SV *
is_inf (a)
	SV *	a
CODE:
  RETVAL = is_inf (aTHX_ a);
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
_double_Complexsize ()
CODE:
  RETVAL = _double_Complexsize (aTHX);
OUTPUT:  RETVAL


SV *
_longdouble_Complexsize ()
CODE:
  RETVAL = _longdouble_Complexsize (aTHX);
OUTPUT:  RETVAL


void
_d_to_str (ld)
	SV *	ld
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        _d_to_str(aTHX_ ld);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
_d_to_strp (ld, decimal_prec)
	SV *	ld
	int	decimal_prec
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        _d_to_strp(aTHX_ ld, decimal_prec);
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

