
#ifdef  __MINGW32__
#ifndef __USE_MINGW_ANSI_STDIO
#define __USE_MINGW_ANSI_STDIO 1
#endif
#endif

#define PERL_NO_GET_CONTEXT 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


#include "math_complex_c_l_include.h"

int nnum = 0;

#define MATH_COMPLEX long double _Complex

void l_set_prec(int x) {
    if(x < 1)croak("1st arg (precision) to l_set_prec must be at least 1");
    _MATH_COMPLEX_C_L_DIGITS = x;
}

int l_get_prec(void) {
    return _MATH_COMPLEX_C_L_DIGITS;
}

int _is_nan(long double x) {
    if(x == x) return 0;
    return 1;
}

int _is_inf(long double x) {
    if(x == 0) return 0;
    if(_is_nan(x)) return 0;
    if(x / x == x / x) return 0;
    if(x < 0) return -1;
    return 1;
}

long double _get_nan(void) {
    float nanval = 0.0L / 0.0L;
    return nanval;
}

long double _get_inf(void) {
    long double infval = 1.0L / 0.0L;
    return infval;
}

long double _get_neg_inf(void) {
    long double inf = -1.0L / 0.0L;
    return inf;
}

SV * create_cl(pTHX) {

     MATH_COMPLEX *pc;
     SV * obj_ref, * obj;

     New(42, pc, 1, MATH_COMPLEX);
     if(pc == NULL) croak("Failed to allocate memory in create_cl function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Complex_C::L");

     __real__ *pc = _get_nan();
     __imag__ *pc = _get_nan();

     sv_setiv(obj, INT2PTR(IV,pc));
     SvREADONLY_on(obj);
     return obj_ref;

}

void assign_cl(pTHX_ SV * rop, SV * d1, SV * d2) {
     long double _d1, _d2;

     if(SvUOK(d1)) {
       _d1 = (long double)SvUVX(d1);
     }
     else {
       if(SvIOK(d1)) {
         _d1 = (long double)SvIVX(d1);
       }
       else {
         if(SvNOK(d1)) {
           _d1 = (long double)SvNVX(d1);
         }
         else {
           if(SvPOK(d1)) {
             if(!looks_like_number(d1)) nnum++;
             _d1 = strtold(SvPV_nolen(d1), NULL);
           }
           else {
             if(sv_isobject(d1)) {
               const char *h = HvNAME(SvSTASH(SvRV(d1)));
               if(strEQ(h, "Math::LongDouble"))
                 _d1 = *(INT2PTR(long double *, SvIVX(SvRV(d1))));
               else croak("Invalid object given as 2nd arg to assign_cl function");
             }
             else {
               croak("Invalid 2nd arg supplied to assign_cl function");
             }
           }
         }
       }
     }

     if(SvUOK(d2)) {
       _d2 = (long double)SvUVX(d2);
     }
     else {
       if(SvIOK(d2)) {
         _d2 = (long double)SvIVX(d2);
       }
       else {
         if(SvNOK(d2)) {
           _d2 = (long double)SvNVX(d2);
         }
         else {
           if(SvPOK(d2)) {
             if(!looks_like_number(d2)) nnum++;
             _d2 = strtold(SvPV_nolen(d2), NULL) ;
           }
           else {
             if(sv_isobject(d2)) {
               const char *h = HvNAME(SvSTASH(SvRV(d2)));
               if(strEQ(h, "Math::LongDouble"))
                 _d2 = *(INT2PTR(long double *, SvIVX(SvRV(d2))));
               else croak("Invalid object given as 3rd arg to assign_cl function");
             }
             else {
               croak("Invalid 3rd arg supplied to assign_cl function");
             }
           }
         }
       }
     }

     __real__ *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = _d1;
     __imag__ *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = _d2;
}

void set_real_cl(pTHX_ SV * rop, SV * d1) {
     long double _d1;

     if(SvUOK(d1)) {
       _d1 = (long double)SvUVX(d1);
     }
     else {
       if(SvIOK(d1)) {
         _d1 = (long double)SvIVX(d1);
       }
       else {
         if(SvNOK(d1)) {
           _d1 = (long double)SvNVX(d1);
         }
         else {
           if(SvPOK(d1)) {
             if(!looks_like_number(d1)) nnum++;
             _d1 = strtold(SvPV_nolen(d1), NULL) ;
           }
           else {
             if(sv_isobject(d1)) {
               const char *h = HvNAME(SvSTASH(SvRV(d1)));
               if(strEQ(h, "Math::LongDouble"))
                 _d1 = *(INT2PTR(long double *, SvIVX(SvRV(d1))));
               else croak("Invalid object given as 2nd arg to set_real_cl function");
             }
             else {
               croak("Invalid 2nd arg supplied to set_real_cl function");
             }
           }
         }
       }
     }

     __real__ *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = _d1;
}

void set_imag_cl(pTHX_ SV * rop, SV * d2) {
     long double _d2;

     if(SvUOK(d2)) {
       _d2 = (long double)SvUVX(d2);
     }
     else {
       if(SvIOK(d2)) {
         _d2 = (long double)SvIVX(d2);
       }
       else {
         if(SvNOK(d2)) {
           _d2 = (long double)SvNVX(d2);
         }
         else {
           if(SvPOK(d2)) {
             if(!looks_like_number(d2)) nnum++;
             _d2 = strtold(SvPV_nolen(d2), NULL) ;
           }
           else {
             if(sv_isobject(d2)) {
               const char *h = HvNAME(SvSTASH(SvRV(d2)));
               if(strEQ(h, "Math::LongDouble"))
                 _d2 = *(INT2PTR(long double *, SvIVX(SvRV(d2))));
               else croak("Invalid object given as 2nd arg to set_imag_cl function");
             }
             else {
               croak("Invalid 2nd arg supplied to set_imag_cl function");
             }
           }
         }
       }
     }

     __imag__ *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = _d2;
}


void LD2cl(pTHX_ SV * rop, SV * d1, SV * d2) {
     long double _d1, _d2;

     if(sv_isobject(d1) && sv_isobject(d2)) {
       const char *h1 = HvNAME(SvSTASH(SvRV(d1)));
       const char *h2 = HvNAME(SvSTASH(SvRV(d2)));
       if(strEQ(h1, "Math::LongDouble") &&
          strEQ(h2, "Math::LongDouble")) {

          _d1 = *(INT2PTR(long double *, SvIVX(SvRV(d1))));
          _d2 = *(INT2PTR(long double *, SvIVX(SvRV(d2))));

          __real__ *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = _d1;
          __imag__ *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = _d2;
       }
       else croak("Both 2nd and 3rd args supplied to LD2cl need to be Math::LongDouble objects");
     }
     else croak("Both 2nd and 3rd args supplied to LD2cl need to be Math::LongDouble objects");
}

void cl2LD(pTHX_ SV * rop1, SV * rop2, SV * op) {
     if(sv_isobject(rop1)) {
       const char *h = HvNAME(SvSTASH(SvRV(rop1)));
       if(strEQ(h, "Math::LongDouble")) {
         *(INT2PTR(long double *, SvIVX(SvRV(rop1)))) = creall(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
       }
       else croak("1st arg (a %s object) supplied to cl2LD needs to be a Math::LongDouble object", h);
     }
     else croak("1st arg (which needs to be a Math::LongDouble object) supplied to cl2LD is not an object");

     if(sv_isobject(rop2)) {
       const char *h = HvNAME(SvSTASH(SvRV(rop2)));
       if(strEQ(h, "Math::LongDouble")) {
         *(INT2PTR(long double *, SvIVX(SvRV(rop2)))) = cimagl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
       }
       else croak("2nd arg (a %s object) supplied to cl2LD needs to be a Math::LongDouble object", h);
     }
     else croak("2nd arg (which needs to be a Math::LongDouble object) supplied to cl2LD is not an object");
}

void mul_cl(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) *
                                                   *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op2))));
}

void mul_c_nvl(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) *
                                                   (long double)SvNV(op2);
}

void mul_c_ivl(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) *
                                                   (long double)SvIV(op2);
}

void mul_c_uvl(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) *
                                                   (long double)SvUV(op2);
}

void mul_c_pvl(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) *
                                                   strtold(SvPV_nolen(op2), NULL);
}

void div_cl(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) /
                                                   *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op2))));
}

void div_c_nvl(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) /
                                                   (long double)SvNV(op2);
}

void div_c_ivl(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) /
                                                   (long double)SvIV(op2);
}

void div_c_uvl(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) /
                                                   (long double)SvUV(op2);
}

void div_c_pvl(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) /
                                                   strtold(SvPV_nolen(op2), NULL);
}

void add_cl(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) +
                                                   *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op2))));
}

void add_c_nvl(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) +
                                                   (long double)SvNV(op2);
}

void add_c_ivl(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) +
                                                   (long double)SvIV(op2);
}

void add_c_uvl(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) +
                                                   (long double)SvUV(op2);
}

void add_c_pvl(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) +
                                                   strtold(SvPV_nolen(op2), NULL);
}

void sub_cl(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) -
                                                   *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op2))));
}

void sub_c_nvl(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) -
                                                   (long double)SvNV(op2);
}

void sub_c_ivl(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) -
                                                   (long double)SvIV(op2);
}

void sub_c_uvl(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) -
                                                   (long double)SvUV(op2);
}

void sub_c_pvl(pTHX_ SV * rop, SV * op1, SV * op2) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op1)))) -
                                                   strtold(SvPV_nolen(op2), NULL);
}

void DESTROY(pTHX_ SV *  op) {
     Safefree(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op))));
}

SV * real_cl(pTHX_ SV * op) {
#if defined(NO_INF_CAST_TO_NV) && defined(__GNUC__) && ((__GNUC__ > 4 && __GNUC__ < 7) || (__GNUC__ == 4 && __GNUC_MINOR__ >= 9))
     int t;
     long double temp = creall(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
     t = _is_inf(temp);
     if(t) {
       if(t < 0) return newSVnv((NV)strtod("-inf", NULL));
       return newSVnv((NV)strtod( "inf", NULL));
     }

#endif
     return newSVnv(creall(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op))))));
}

SV * real_cl2LD(pTHX_ SV * op) {
     long double * f;
     SV * obj_ref, * obj;

     Newx(f, 1, long double);
     if(f == NULL) croak("Failed to allocate memory in real_cl2LD function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::LongDouble");

     *f = creall(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
}

void real_cl2str(pTHX_ SV * op) {
     dXSARGS;
     long double t;
     char * buffer;

     if(sv_isobject(op)) {
       const char *h = HvNAME(SvSTASH(SvRV(op)));
       if(strEQ(h, "Math::Complex_C::L")) {
          EXTEND(SP, 1);
          t = creall(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));

          Newx(buffer, 8 + _MATH_COMPLEX_C_L_DIGITS, char);
          if(buffer == NULL) croak("Failed to allocate memory in real_cl2str");
          sprintf(buffer, "%.*Le", _MATH_COMPLEX_C_L_DIGITS - 1, t);
          ST(0) = sv_2mortal(newSVpv(buffer, 0));
          Safefree(buffer);
          XSRETURN(1);
       }
       else croak("Invalid object supplied to Math::Complex_C::L::real_cl2str function");
     }
     else croak("Invalid argument supplied to Math::Complex_C::L::real_cl2str function");
}

SV * imag_cl(pTHX_ SV * op) {
#if defined(NO_INF_CAST_TO_NV) && defined(__GNUC__) && ((__GNUC__ > 4 && __GNUC__ < 7) || (__GNUC__ == 4 && __GNUC_MINOR__ >= 9))
     int t;
     long double temp = cimagl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
     t = _is_inf(temp);
     if(t) {
       if(t < 0) return newSVnv((NV)strtod("-inf", NULL));
       return newSVnv((NV)strtod( "inf", NULL));
     }

#endif
     return newSVnv(cimagl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op))))));
}

SV * imag_cl2LD(pTHX_ SV * op) {
     long double * f;
     SV * obj_ref, * obj;

     Newx(f, 1, long double);
     if(f == NULL) croak("Failed to allocate memory in imag_cl2LD function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::LongDouble");

     *f = cimagl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
}

void imag_cl2str(pTHX_ SV * op) {
     dXSARGS;
     long double t;
     char * buffer;

     if(sv_isobject(op)) {
       const char *h = HvNAME(SvSTASH(SvRV(op)));
       if(strEQ(h, "Math::Complex_C::L")) {
          EXTEND(SP, 1);
          t = cimagl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));

          Newx(buffer, 8 + _MATH_COMPLEX_C_L_DIGITS, char);
          if(buffer == NULL) croak("Failed to allocate memory in imag_cl2str");
          sprintf(buffer, "%.*Le", _MATH_COMPLEX_C_L_DIGITS - 1, t);
          ST(0) = sv_2mortal(newSVpv(buffer, 0));
          Safefree(buffer);
          XSRETURN(1);
       }
       else croak("Invalid object supplied to Math::Complex_C::L::imag_cl2str function");
     }
     else croak("Invalid argument supplied to Math::Complex_C::L::imag_cl2str function");
}

SV * arg_cl(pTHX_ SV * op) {
     return newSVnv(cargl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op))))));
}

SV * arg_cl2LD(pTHX_ SV * op) {
     long double * f;
     SV * obj_ref, * obj;

     Newx(f, 1, long double);
     if(f == NULL) croak("Failed to allocate memory in arg_cl2LD function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::LongDouble");

     *f = cargl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
}

void arg_cl2str(pTHX_ SV * op) {
     dXSARGS;
     long double t;
     char * buffer;

     if(sv_isobject(op)) {
       const char *h = HvNAME(SvSTASH(SvRV(op)));
       if(strEQ(h, "Math::Complex_C::L")) {
          EXTEND(SP, 1);
          t = cargl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));

          Newx(buffer, 8 + _MATH_COMPLEX_C_L_DIGITS, char);
          if(buffer == NULL) croak("Failed to allocate memory in arg_cl2str");
          sprintf(buffer, "%.*Le", _MATH_COMPLEX_C_L_DIGITS - 1, t);
          ST(0) = sv_2mortal(newSVpv(buffer, 0));
          Safefree(buffer);
          XSRETURN(1);
       }
       else croak("Invalid object supplied to Math::Complex_C::L::arg_cl2str function");
     }
     else croak("Invalid argument supplied to Math::Complex_C::L::arg_cl2str function");
}

SV * abs_cl(pTHX_ SV * op) {
     return newSVnv(cabsl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op))))));
}

SV * abs_cl2LD(pTHX_ SV * op) {
     long double * f;
     SV * obj_ref, * obj;

     Newx(f, 1, long double);
     if(f == NULL) croak("Failed to allocate memory in cabs_cl2LD function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::LongDouble");

     *f = cabsl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));

     sv_setiv(obj, INT2PTR(IV,f));
     SvREADONLY_on(obj);
     return obj_ref;
}

void abs_cl2str(pTHX_ SV * op) {
     dXSARGS;
     long double t;
     char * buffer;

     if(sv_isobject(op)) {
       const char *h = HvNAME(SvSTASH(SvRV(op)));
       if(strEQ(h, "Math::Complex_C::L")) {
          EXTEND(SP, 1);
          t = cabsl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));

          Newx(buffer, 8 + _MATH_COMPLEX_C_L_DIGITS, char);
          if(buffer == NULL) croak("Failed to allocate memory in arg_cl2str");
          sprintf(buffer, "%.*Le", _MATH_COMPLEX_C_L_DIGITS - 1, t);
          ST(0) = sv_2mortal(newSVpv(buffer, 0));
          Safefree(buffer);
          XSRETURN(1);
       }
       else croak("Invalid object supplied to Math::Complex_C::L::abs_cl2str function");
     }
     else croak("Invalid argument supplied to Math::Complex_C::L::abs_cl2str function");
}

void conj_cl(pTHX_ SV * rop, SV * op) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = conjl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
}

void acos_cl(pTHX_ SV * rop, SV * op) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = cacosl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
}

void asin_cl(pTHX_ SV * rop, SV * op) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = casinl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
}

void atan_cl(pTHX_ SV * rop, SV * op) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = catanl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
}

void cos_cl(pTHX_ SV * rop, SV * op) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = ccosl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
}

void sin_cl(pTHX_ SV * rop, SV * op) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = csinl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
}

void tan_cl(pTHX_ SV * rop, SV * op) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = ctanl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
}

void acosh_cl(pTHX_ SV * rop, SV * op) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = cacoshl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
}

void asinh_cl(pTHX_ SV * rop, SV * op) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = casinhl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
}

void atanh_cl(pTHX_ SV * rop, SV * op) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = catanhl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
}

void cosh_cl(pTHX_ SV * rop, SV * op) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = ccoshl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
}

void sinh_cl(pTHX_ SV * rop, SV * op) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = csinhl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
}

void tanh_cl(pTHX_ SV * rop, SV * op) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = ctanhl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
}

void exp_cl(pTHX_ SV * rop, SV * op) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = cexpl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
}

void log_cl(pTHX_ SV * rop, SV * op) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = clogl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
}

void sqrt_cl(pTHX_ SV * rop, SV * op) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = csqrtl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
}

void proj_cl(pTHX_ SV * rop, SV * op) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = cprojl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))));
}

void pow_cl(pTHX_ SV * rop, SV * op, SV * exp) {
     *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))) = cpowl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(op)))),
                                                        *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(exp)))));
}

SV * _overload_true(pTHX_ SV * rop, SV * second, SV * third) {
     if (_is_nan(creall(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))))) &&
         _is_nan(cimagl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop))))))) return newSVuv(0);
     if(creall(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop))))) ||
        cimagl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))))) return newSVuv(1);
     return newSVuv(0);
}

SV * _overload_not(pTHX_ SV * rop, SV * second, SV * third) {
     if (_is_nan(creall(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))))) &&
         _is_nan(cimagl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop))))))) return newSVuv(1);
     if(creall(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop))))) ||
        cimagl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop)))))) return newSVuv(0);
     return newSVuv(1);
}

SV * _overload_equiv(pTHX_ SV * a, SV * b, SV * third) {
      if(SvUOK(b)) {
       if((long double)SvUVX(b) == creall(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))))) &&
          0.0L              == cimagl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))))) return newSVuv(1);
       return newSVuv(0);
     }
     if(SvIOK(b)) {
       if((long double)SvIVX(b) == creall(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))))) &&
          0.0L              == cimagl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))))) return newSVuv(1);
       return newSVuv(0);
     }
     if(SvNOK(b)) {
       if((long double)SvNVX(b) == creall(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))))) &&
          0.0L    == cimagl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))))) return newSVuv(1);
       return newSVuv(0);
     }

     if(SvPOK(b)) {
       if(!looks_like_number(b)) nnum++;
       if(strtold(SvPV_nolen(b), NULL) == creall(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))))) &&
          0.0L == cimagl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))))) return newSVuv(1);
       return newSVuv(0);
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Complex_C::L")) {
         if(creall(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))))) == creall(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(b))))) &&
            cimagl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))))) == cimagl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(b))))))
              return newSVuv(1);
         return newSVuv(0);
       }
     }

     croak("Invalid argument supplied to Math::Complex_C::L::_overload_equiv function");
}

SV * _overload_not_equiv(pTHX_ SV * a, SV * b, SV * third) {
     if(SvUOK(b)) {
       if((long double)SvUVX(b) == creall(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))))) &&
          0.0L              == cimagl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))))) return newSVuv(0);
       return newSVuv(1);
     }
     if(SvIOK(b)) {
       if((long double)SvIVX(b) == creall(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))))) &&
          0.0L              == cimagl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))))) return newSVuv(0);
       return newSVuv(1);
     }
     if(SvNOK(b)) {
       if((long double)SvNVX(b) == creall(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))))) &&
          0.0L    == cimagl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))))) return newSVuv(0);
       return newSVuv(1);
     }
     if(SvPOK(b)) {
       if(!looks_like_number(b)) nnum++;
       if(strtold(SvPV_nolen(b), NULL) == creall(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))))) &&
          0.0L == cimagl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))))) return newSVuv(0);
       return newSVuv(1);
     }
     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Complex_C::L")) {
         if(creall(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))))) == creall(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(b))))) &&
            cimagl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))))) == cimagl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(b))))))
              return newSVuv(0);
         return newSVuv(1);
       }
     }

     croak("Invalid argument supplied to Math::Complex_C::L::_overload_not_equiv function");
}


SV * _overload_pow(pTHX_ SV * a, SV * b, SV * third) {
     MATH_COMPLEX *pc, t;
     SV * obj_ref, * obj;

     New(42, pc, 1, MATH_COMPLEX);
     if(pc == NULL) croak("Failed to allocate memory in _overload_pow function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Complex_C::L");

     sv_setiv(obj, INT2PTR(IV,pc));
     SvREADONLY_on(obj);

     if(SvUOK(b)) {
       __real__ t = (long double)SvUVX(b);
       __imag__ t = 0.0L;
       if(SWITCH_ARGS) {
         *pc = cpowl( t, *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) );
         return obj_ref;
       }
       *pc = cpowl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))), t);
       return obj_ref;
     }

     if(SvIOK(b)) {
       __real__ t = (long double)SvIVX(b);
       __imag__ t = 0.0L;
       if(SWITCH_ARGS) {
         *pc = cpowl( t, *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) );
         return obj_ref;
       }
       *pc = cpowl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))), t);
       return obj_ref;
     }

     if(SvNOK(b)) {
       __real__ t = (long double)SvNVX(b);
       __imag__ t = 0.0L;
       if(SWITCH_ARGS) {
         *pc = cpowl( t, *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) );
         return obj_ref;
       }
       *pc = cpowl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))), t);
       return obj_ref;
     }

     if(SvPOK(b)) {
       if(!looks_like_number(b)) nnum++;
       __real__ t = strtold(SvPV_nolen(b), NULL);
       __imag__ t = 0.0L;
       if(SWITCH_ARGS) {
         *pc = cpowl( t, *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) );
         return obj_ref;
       }
       *pc = cpowl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))), t);
       return obj_ref;
     }
     else if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Complex_C::L")) {
         *pc = cpowl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))), *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(b)))));
         return obj_ref;
       }
     }
     else croak("Invalid argument supplied to Math::Complex_C::L::_overload_pow function");
}

SV * _overload_mul(pTHX_ SV * a, SV * b, SV * third) {
     MATH_COMPLEX *pc;
     SV * obj_ref, * obj;

     New(42, pc, 1, MATH_COMPLEX);
     if(pc == NULL) croak("Failed to allocate memory in _overload_mul function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Complex_C::L");

     sv_setiv(obj, INT2PTR(IV,pc));
     SvREADONLY_on(obj);

     if(SvUOK(b)) {
       *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) * (long double)SvUVX(b);
       return obj_ref;
     }

     if(SvIOK(b)) {
       *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) * (long double)SvIVX(b);
       return obj_ref;
     }

     if(SvNOK(b)) {
       *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) * (long double)SvNVX(b);
       return obj_ref;
     }
     if(SvPOK(b)) {
       if(!looks_like_number(b)) nnum++;
       *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) * strtold(SvPV_nolen(b), NULL);
       return obj_ref;
     }
     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Complex_C::L")) {
         *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) * *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(b))));
         return obj_ref;
       }
     }

     croak("Invalid argument supplied to Math::Complex_C::L::_overload_mul function");
}

SV * _overload_add(pTHX_ SV * a, SV * b, SV * third) {
     MATH_COMPLEX *pc;
     SV * obj_ref, * obj;

     New(42, pc, 1, MATH_COMPLEX);
     if(pc == NULL) croak("Failed to allocate memory in _overload_add function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Complex_C::L");

     sv_setiv(obj, INT2PTR(IV,pc));
     SvREADONLY_on(obj);

     if(SvUOK(b)) {
       *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) + (long double)SvUVX(b);
       return obj_ref;
     }

     if(SvIOK(b)) {
       *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) + (long double)SvIVX(b);
       return obj_ref;
     }

     if(SvNOK(b)) {
       *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) + (long double)SvNVX(b);
       return obj_ref;
     }
     if(SvPOK(b)) {
       if(!looks_like_number(b)) nnum++;
       *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) + strtold(SvPV_nolen(b), NULL);
       return obj_ref;
     }
     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Complex_C::L")) {
         *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) + *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(b))));
         return obj_ref;
       }
     }

     croak("Invalid argument supplied to Math::Complex_C::L::_overload_add function");
}

SV * _overload_div(pTHX_ SV * a, SV * b, SV * third) {
     MATH_COMPLEX *pc;
     SV * obj_ref, * obj;

     New(42, pc, 1, MATH_COMPLEX);
     if(pc == NULL) croak("Failed to allocate memory in _overload_div function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Complex_C::L");

     sv_setiv(obj, INT2PTR(IV,pc));
     SvREADONLY_on(obj);

     if(SvUOK(b)) {
       if(SWITCH_ARGS) *pc = (long double)SvUVX(b) / *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))));
       else *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) / (long double)SvUVX(b);
       return obj_ref;
     }

     if(SvIOK(b)) {
       if(SWITCH_ARGS) *pc = (long double)SvIVX(b) / *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))));
       else *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) / (long double)SvIVX(b);
       return obj_ref;
     }

     if(SvNOK(b)) {
       if(SWITCH_ARGS) *pc = (long double)SvNVX(b) / *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))));
       else *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) / (long double)SvNVX(b);
       return obj_ref;
     }
     if(SvPOK(b)) {
       if(!looks_like_number(b)) nnum++;
       if(SWITCH_ARGS) *pc = strtold(SvPV_nolen(b), NULL) / *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))));
       else *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) / strtold(SvPV_nolen(b), NULL);
       return obj_ref;
     }
     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Complex_C::L")) {
         *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) / *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(b))));
         return obj_ref;
       }
     }

     croak("Invalid argument supplied to Math::Complex_C::L::_overload_div function");
}

SV * _overload_sub(pTHX_ SV * a, SV * b, SV * third) {
     MATH_COMPLEX *pc;
     SV * obj_ref, * obj;

     New(42, pc, 1, MATH_COMPLEX);
     if(pc == NULL) croak("Failed to allocate memory in _overload_sub function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Complex_C::L");

     sv_setiv(obj, INT2PTR(IV,pc));
     SvREADONLY_on(obj);

     if(SvUOK(b)) {
       if(SWITCH_ARGS) *pc = (long double)SvUVX(b) - *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))));
       else *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) - (long double)SvUVX(b);
       return obj_ref;
     }

     if(SvIOK(b)) {
       if(SWITCH_ARGS) *pc = (long double)SvIVX(b) - *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))));
       else *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) - (long double)SvIVX(b);
       return obj_ref;
     }

     if(SvNOK(b)) {
       if(SWITCH_ARGS) *pc = (long double)SvNVX(b) - *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))));
       else *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) - (long double)SvNVX(b);
       return obj_ref;
     }
     if(SvPOK(b)) {
       if(!looks_like_number(b)) nnum++;
       if(SWITCH_ARGS) *pc = strtold(SvPV_nolen(b), NULL) - *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))));
       else *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) - strtold(SvPV_nolen(b), NULL);
       return obj_ref;
     }
     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Complex_C::L")) {
         *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) - *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(b))));
         return obj_ref;
       }
     }

     croak("Invalid argument supplied to Math::Complex_C::L::_overload_sub function");
}

SV * _overload_sqrt(pTHX_ SV * a, SV * b, SV * third) {
     MATH_COMPLEX *pc;
     SV * obj_ref, * obj;

     New(42, pc, 1, MATH_COMPLEX);
     if(pc == NULL) croak("Failed to allocate memory in _overload_sqrt function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Complex_C::L");

     *pc = csqrtl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))));

     sv_setiv(obj, INT2PTR(IV,pc));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * _overload_pow_eq(pTHX_ SV * a, SV * b, SV * third) {
     MATH_COMPLEX t;
     SvREFCNT_inc(a);

     if(SvUOK(b)) {
       __real__ t = (long double)SvUVX(b);
       __imag__ t = 0.0L;
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) = cpowl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))), t);
       return a;
     }
     if(SvIOK(b)) {
       __real__ t = (long double)SvIVX(b);
       __imag__ t = 0.0L;
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) = cpowl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))), t);
       return a;
     }
     if(SvNOK(b)) {
       __real__ t = (long double)SvNVX(b);
       __imag__ t = 0.0L;
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) = cpowl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))), t);
       return a;
     }
     if(SvPOK(b)) {
       if(!looks_like_number(b)) nnum++;
       __real__ t = strtold(SvPV_nolen(b), NULL);
       __imag__ t = 0.0L;
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) = cpowl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))), t);
       return a;
     }
     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Complex_C::L")) {
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) = cpowl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))),
                                                        *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(b)))));
         return a;
       }
     }
     SvREFCNT_dec(a);
     croak("Invalid argument supplied to Math::Complex_C::L::_overload_pow_eq function");
}

SV * _overload_mul_eq(pTHX_ SV * a, SV * b, SV * third) {
     SvREFCNT_inc(a);

     if(SvUOK(b)) {
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) *= (long double)SvUVX(b);
       return a;
     }

     if(SvIOK(b)) {
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) *= (long double)SvIVX(b);
       return a;
     }

     if(SvNOK(b)) {
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) *= (long double)SvNVX(b);
       return a;
     }

     if(SvPOK(b)) {
       if(!looks_like_number(b)) nnum++;
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) *= strtold(SvPV_nolen(b), NULL);
       return a;
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Complex_C::L")) {
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) *= *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(b))));
         return a;
       }
     }

     SvREFCNT_dec(a);
     croak("Invalid argument supplied to Math::Complex_C::L::_overload_mul_eq function");
}

SV * _overload_add_eq(pTHX_ SV * a, SV * b, SV * third) {
     SvREFCNT_inc(a);

     if(SvUOK(b)) {
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) += (long double)SvUVX(b);
       return a;
     }

     if(SvIOK(b)) {
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) += (long double)SvIVX(b);
       return a;
     }

     if(SvNOK(b)) {
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) += (long double)SvNVX(b);
       return a;
     }

     if(SvPOK(b)) {
       if(!looks_like_number(b)) nnum++;
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) += strtold(SvPV_nolen(b), NULL);
       return a;
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Complex_C::L")) {
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) += *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(b))));
         return a;
       }
     }

     SvREFCNT_dec(a);
     croak("Invalid argument supplied to Math::Complex_C::L::_overload_add_eq function");
}

SV * _overload_div_eq(pTHX_ SV * a, SV * b, SV * third) {
     SvREFCNT_inc(a);

     if(SvUOK(b)) {
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) /= (long double)SvUVX(b);
       return a;
     }

     if(SvIOK(b)) {
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) /= (long double)SvIVX(b);
       return a;
     }

     if(SvNOK(b)) {
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) /= (long double)SvNVX(b);
       return a;
     }

     if(SvPOK(b)) {
       if(!looks_like_number(b)) nnum++;
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) /= strtold(SvPV_nolen(b), NULL);
       return a;
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Complex_C::L")) {
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) /= *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(b))));
         return a;
       }
     }

     SvREFCNT_dec(a);
     croak("Invalid argument supplied to Math::Complex_C::L::_overload_div_eq function");
}

SV * _overload_sub_eq(pTHX_ SV * a, SV * b, SV * third) {
     SvREFCNT_inc(a);

     if(SvUOK(b)) {
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) -= (long double)SvUVX(b);
       return a;
     }

     if(SvIOK(b)) {
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) -= (long double)SvIVX(b);
       return a;
     }

     if(SvNOK(b)) {
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) -= (long double)SvNVX(b);
       return a;
     }

     if(SvPOK(b)) {
       if(!looks_like_number(b)) nnum++;
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) -= strtold(SvPV_nolen(b), NULL);
       return a;
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::Complex_C::L")) {
       *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) -= *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(b))));
         return a;
       }
     }

     SvREFCNT_dec(a);
     croak("Invalid argument supplied to Math::Complex_C::L::_overload_sub_eq function");
}

SV * _overload_copy(pTHX_ SV * a, SV * second, SV * third) {

     MATH_COMPLEX *pc;
     SV * obj_ref, * obj;

     New(42, pc, 1, MATH_COMPLEX);
     if(pc == NULL) croak("Failed to allocate memory in _overload_copy function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Complex_C::L");

     __real__ *pc = __real__ *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))));
     __imag__ *pc = __imag__ *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a))));

     sv_setiv(obj, INT2PTR(IV,pc));
     SvREADONLY_on(obj);
     return obj_ref;

}

SV * _overload_abs(pTHX_ SV * rop, SV * second, SV * third) {
     return newSVnv(cabsl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(rop))))));
}

SV * _overload_exp(pTHX_ SV * a, SV * b, SV * third) {
     MATH_COMPLEX *pc;
     SV * obj_ref, * obj;

     New(42, pc, 1, MATH_COMPLEX);
     if(pc == NULL) croak("Failed to allocate memory in _overload_exp function");

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::Complex_C::L");

     *pc = cexpl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))));

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
     obj = newSVrv(obj_ref, "Math::Complex_C::L");

     *pc = clogl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))));

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
     obj = newSVrv(obj_ref, "Math::Complex_C::L");

     *pc = csinl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))));

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
     obj = newSVrv(obj_ref, "Math::Complex_C::L");

     *pc = ccosl(*(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))));

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
     obj = newSVrv(obj_ref, "Math::Complex_C::L");

     *pc = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(a)))) /
           *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(b)))) ;

     *pc = catanl(*pc);

     sv_setiv(obj, INT2PTR(IV,pc));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * get_nanl(pTHX) {
     return newSVnv(_get_nan());
}

SV * get_infl(pTHX) {
#if defined(NO_INF_CAST_TO_NV) && defined(__GNUC__) && ((__GNUC__ > 4 && __GNUC__ < 7) || (__GNUC__ == 4 && __GNUC_MINOR__ >= 9))
     return newSVnv((NV)strtod("inf", NULL));
#else
     return newSVnv(_get_inf());
#endif
}

SV * get_neg_infl(pTHX) {
#if defined(NO_INF_CAST_TO_NV) && defined(__GNUC__) && ((__GNUC__ > 4 && __GNUC__ < 7) || (__GNUC__ == 4 && __GNUC_MINOR__ >= 9))
     return newSVnv((NV)strtod("-inf", NULL));
#else
     return newSVnv(_get_neg_inf());
#endif
}

SV * is_nanl(pTHX_ SV * a) {
     if(SvNV(a) == SvNV(a)) return newSVuv(0);
     return newSVuv(1);
}

SV * is_infl(pTHX_ SV * a) {
     if(SvNV(a) == 0) return newSVuv(0);
     if(SvNV(a) != SvNV(a)) return newSVuv(0);
     if(SvNV(a) / SvNV(a) == SvNV(a) / SvNV(a)) return newSVuv(0);
     if(SvNV(a) < 0) return newSViv(-1);
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


void _l_to_str(pTHX_ SV * ld) {
     dXSARGS;
     MATH_COMPLEX t;
     char *rbuffer;
     int query;

     if(sv_isobject(ld)) {
       const char *h = HvNAME(SvSTASH(SvRV(ld)));
       if(strEQ(h, "Math::Complex_C::L")) {
          EXTEND(SP, 2);

          t = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(ld))));
/**/
          Newx(rbuffer, 8 + _MATH_COMPLEX_C_L_DIGITS, char);
          if(rbuffer == NULL) croak("Failed to allocate memory in l_to_str");

          query = _is_inf(__real__ t);
          if(query || _is_nan(__real__ t))
            sprintf(rbuffer, "%s", query ? query > 0 ? "inf"
                                                     : "-inf"
                                         : "nan");
          else
           sprintf(rbuffer, "%.*Le", _MATH_COMPLEX_C_L_DIGITS - 1, __real__ t);

          ST(0) = sv_2mortal(newSVpv(rbuffer, 0));

          query = _is_inf(__imag__ t);
          if(query || _is_nan(__imag__ t))
            sprintf(rbuffer, "%s", query ? query > 0 ? "inf"
                                                     : "-inf"
                                         : "nan");
          else
           sprintf(rbuffer, "%.*Le", _MATH_COMPLEX_C_L_DIGITS - 1, __imag__ t);

          ST(1) = sv_2mortal(newSVpv(rbuffer, 0));
/**/
          Safefree(rbuffer);
          XSRETURN(2);
       }
       else croak("l_to_str function needs a Math::Complex_C::L arg but was supplied with a %s arg", h);
     }
     else croak("Invalid argument supplied to Math::Complex_C::L::l_to_str function");
}

void _l_to_strp(pTHX_ SV * ld, int decimal_prec) {
     dXSARGS;
     MATH_COMPLEX t;
     char *rbuffer;
     int query;

     if(decimal_prec < 1)croak("2nd arg (precision) to _l_to_strp  must be at least 1");

     if(sv_isobject(ld)) {
       const char *h = HvNAME(SvSTASH(SvRV(ld)));
       if(strEQ(h, "Math::Complex_C::L")) {
          EXTEND(SP, 2);
          t = *(INT2PTR(MATH_COMPLEX *, SvIVX(SvRV(ld))));
/* new */
          Newx(rbuffer, 8 + decimal_prec, char);
          if(rbuffer == NULL) croak("Failed to allocate memory in l_to_strp");

          query = _is_inf(__real__ t);
          if(query || _is_nan(__real__ t))
            sprintf(rbuffer, "%s", query ? query > 0 ? "inf"
                                                     : "-inf"
                                         : "nan");
          else
           sprintf(rbuffer, "%.*Le", decimal_prec - 1, __real__ t);

          ST(0) = sv_2mortal(newSVpv(rbuffer, 0));

          query = _is_inf(__imag__ t);
          if(query || _is_nan(__imag__ t))
            sprintf(rbuffer, "%s", query ? query > 0 ? "inf"
                                                     : "-inf"
                                         : "nan");
          else
           sprintf(rbuffer, "%.*Le", decimal_prec - 1, __imag__ t);

          ST(1) = sv_2mortal(newSVpv(rbuffer, 0));
/**/
          Safefree(rbuffer);
          XSRETURN(2);
       }
       else croak("l_to_strp function needs a Math::Complex_C::L arg but was supplied with a %s arg", h);
     }
     else croak("Invalid argument supplied to Math::Complex_C::L::l_to_strp function");
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
       if(strEQ(h, "Math::LongDouble"))   return newSVuv(96);
       if(strEQ(h, "Math::Float128"))     return newSVuv(113);
       if(strEQ(h, "Math::Complex_C::L")) return newSVuv(226);
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



MODULE = Math::Complex_C::L  PACKAGE = Math::Complex_C::L

PROTOTYPES: DISABLE


void
l_set_prec (x)
	int	x
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        l_set_prec(x);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

int
l_get_prec ()


SV *
create_cl ()
CODE:
  RETVAL = create_cl (aTHX);
OUTPUT:  RETVAL


void
assign_cl (rop, d1, d2)
	SV *	rop
	SV *	d1
	SV *	d2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        assign_cl(aTHX_ rop, d1, d2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
set_real_cl (rop, d1)
	SV *	rop
	SV *	d1
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        set_real_cl(aTHX_ rop, d1);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
set_imag_cl (rop, d2)
	SV *	rop
	SV *	d2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        set_imag_cl(aTHX_ rop, d2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
LD2cl (rop, d1, d2)
	SV *	rop
	SV *	d1
	SV *	d2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        LD2cl(aTHX_ rop, d1, d2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
cl2LD (rop1, rop2, op)
	SV *	rop1
	SV *	rop2
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        cl2LD(aTHX_ rop1, rop2, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
mul_cl (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        mul_cl(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
mul_c_nvl (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        mul_c_nvl(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
mul_c_ivl (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        mul_c_ivl(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
mul_c_uvl (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        mul_c_uvl(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
mul_c_pvl (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        mul_c_pvl(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
div_cl (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        div_cl(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
div_c_nvl (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        div_c_nvl(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
div_c_ivl (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        div_c_ivl(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
div_c_uvl (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        div_c_uvl(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
div_c_pvl (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        div_c_pvl(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
add_cl (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        add_cl(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
add_c_nvl (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        add_c_nvl(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
add_c_ivl (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        add_c_ivl(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
add_c_uvl (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        add_c_uvl(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
add_c_pvl (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        add_c_pvl(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
sub_cl (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        sub_cl(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
sub_c_nvl (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        sub_c_nvl(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
sub_c_ivl (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        sub_c_ivl(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
sub_c_uvl (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        sub_c_uvl(aTHX_ rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
sub_c_pvl (rop, op1, op2)
	SV *	rop
	SV *	op1
	SV *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        sub_c_pvl(aTHX_ rop, op1, op2);
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
real_cl (op)
	SV *	op
CODE:
  RETVAL = real_cl (aTHX_ op);
OUTPUT:  RETVAL

SV *
real_cl2LD (op)
	SV *	op
CODE:
  RETVAL = real_cl2LD (aTHX_ op);
OUTPUT:  RETVAL

void
real_cl2str (op)
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        real_cl2str(aTHX_ op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
imag_cl (op)
	SV *	op
CODE:
  RETVAL = imag_cl (aTHX_ op);
OUTPUT:  RETVAL

SV *
imag_cl2LD (op)
	SV *	op
CODE:
  RETVAL = imag_cl2LD (aTHX_ op);
OUTPUT:  RETVAL

void
imag_cl2str (op)
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        imag_cl2str(aTHX_ op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
arg_cl (op)
	SV *	op
CODE:
  RETVAL = arg_cl (aTHX_ op);
OUTPUT:  RETVAL

SV *
arg_cl2LD (op)
	SV *	op
CODE:
  RETVAL = arg_cl2LD (aTHX_ op);
OUTPUT:  RETVAL

void
arg_cl2str (op)
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        arg_cl2str(aTHX_ op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
abs_cl (op)
	SV *	op
CODE:
  RETVAL = abs_cl (aTHX_ op);
OUTPUT:  RETVAL

SV *
abs_cl2LD (op)
	SV *	op
CODE:
  RETVAL = abs_cl2LD (aTHX_ op);
OUTPUT:  RETVAL

void
abs_cl2str (op)
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        abs_cl2str(aTHX_ op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
conj_cl (rop, op)
	SV *	rop
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        conj_cl(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
acos_cl (rop, op)
	SV *	rop
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        acos_cl(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
asin_cl (rop, op)
	SV *	rop
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        asin_cl(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
atan_cl (rop, op)
	SV *	rop
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        atan_cl(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
cos_cl (rop, op)
	SV *	rop
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        cos_cl(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
sin_cl (rop, op)
	SV *	rop
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        sin_cl(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
tan_cl (rop, op)
	SV *	rop
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        tan_cl(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
acosh_cl (rop, op)
	SV *	rop
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        acosh_cl(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
asinh_cl (rop, op)
	SV *	rop
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        asinh_cl(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
atanh_cl (rop, op)
	SV *	rop
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        atanh_cl(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
cosh_cl (rop, op)
	SV *	rop
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        cosh_cl(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
sinh_cl (rop, op)
	SV *	rop
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        sinh_cl(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
tanh_cl (rop, op)
	SV *	rop
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        tanh_cl(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
exp_cl (rop, op)
	SV *	rop
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        exp_cl(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
log_cl (rop, op)
	SV *	rop
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        log_cl(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
sqrt_cl (rop, op)
	SV *	rop
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        sqrt_cl(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
proj_cl (rop, op)
	SV *	rop
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        proj_cl(aTHX_ rop, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
pow_cl (rop, op, exp)
	SV *	rop
	SV *	op
	SV *	exp
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        pow_cl(aTHX_ rop, op, exp);
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
get_nanl ()
CODE:
  RETVAL = get_nanl (aTHX);
OUTPUT:  RETVAL


SV *
get_infl ()
CODE:
  RETVAL = get_infl (aTHX);
OUTPUT:  RETVAL


SV *
get_neg_infl ()
CODE:
  RETVAL = get_neg_infl (aTHX);
OUTPUT:  RETVAL


SV *
is_nanl (a)
	SV *	a
CODE:
  RETVAL = is_nanl (aTHX_ a);
OUTPUT:  RETVAL

SV *
is_infl (a)
	SV *	a
CODE:
  RETVAL = is_infl (aTHX_ a);
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
_l_to_str (ld)
	SV *	ld
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        _l_to_str(aTHX_ ld);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
_l_to_strp (ld, decimal_prec)
	SV *	ld
	int	decimal_prec
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        _l_to_strp(aTHX_ ld, decimal_prec);
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

