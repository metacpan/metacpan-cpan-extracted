
#ifdef  __MINGW32__
#ifndef __USE_MINGW_ANSI_STDIO
#define __USE_MINGW_ANSI_STDIO 1
#endif
#endif

#define PERL_NO_GET_CONTEXT 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define TYPE_PRECISION 24
#define TYPE_EMIN -148
#define TYPE_EMAX 128


SV * _itsa(pTHX_ SV * a) {
  if(SvIOK(a)) {
    return newSVuv(2);               /* IV */
  }
  if(SvPOK(a)) {
    return newSVuv(4);               /* PV */
  }
  if(SvNOK(a)) return newSVuv(3);    /* NV */
  if(sv_isobject(a)) {
    const char* h = HvNAME(SvSTASH(SvRV(a)));
    if(strEQ(h, "Math::Bfloat16")) return newSVuv(20);
    if(strEQ(h, "Math::Float32")) return newSVuv(22);
  }
  croak("The Math::Float32::_itsa XSub has been given an invalid argument (probably undefined)");
}

int is_flt_nan( float * obj) {
    if(*obj == *obj) return 0;
    return 1;
}

int is_flt_inf( float * obj) {
    if(*obj == 0) return 0;
    if(*obj / *obj != *obj / *obj) {
      if(*obj > 0) return 1;
      return -1;
    }
    return 0;
}

SV * _fromFloat32(pTHX_  float * in) {

   float * f_obj;
  SV * obj_ref, * obj;

  Newx(f_obj, 1,  float);
  if(f_obj == NULL) croak("Failed to allocate memory in _fromFloat32 function");
  obj_ref = newSV(0);
  obj = newSVrv(obj_ref, "Math::Float32");

  *f_obj = *in;

  sv_setiv(obj, INT2PTR(IV,f_obj));
  SvREADONLY_on(obj);
  return obj_ref;
}

SV * _fromNV(pTHX_ SV * in) {

   float * f_obj;
  SV * obj_ref, * obj;

  Newx(f_obj, 1,  float);
  if(f_obj == NULL) croak("Failed to allocate memory in _fromNV function");
  obj_ref = newSV(0);
  obj = newSVrv(obj_ref, "Math::Float32");

  *f_obj = (float)SvNV(in);

  sv_setiv(obj, INT2PTR(IV,f_obj));
  SvREADONLY_on(obj);
  return obj_ref;
}

SV * _fromIV(pTHX_ SV * in) {

   float * f_obj;
  SV * obj_ref, * obj;

  Newx(f_obj, 1,  float);
  if(f_obj == NULL) croak("Failed to allocate memory in _fromIV function");
  obj_ref = newSV(0);
  obj = newSVrv(obj_ref, "Math::Float32");

  if(SvUOK(in)) *f_obj = ( float)SvUV(in);
  else *f_obj = ( float)SvIV(in);

  sv_setiv(obj, INT2PTR(IV,f_obj));
  SvREADONLY_on(obj);
  return obj_ref;
}

SV * _fromPV(pTHX_ SV * in) {

   float * f_obj;
  SV * obj_ref, * obj;

  Newx(f_obj, 1,  float);
  if(f_obj == NULL) croak("Failed to allocate memory in _fromPV function");
  obj_ref = newSV(0);
  obj = newSVrv(obj_ref, "Math::Float32");

  *f_obj = strtof(SvPV_nolen(in), NULL);

  sv_setiv(obj, INT2PTR(IV,f_obj));
  SvREADONLY_on(obj);
  return obj_ref;
}

SV * flt_to_NV(pTHX_   float * obj) {
   return newSVnv(*obj);
}

void _flt_set( float * a,  float * b) {
  *a = *b;
}

void flt_set_nan( float * a) {
  *a = strtof("NaN", NULL);
}

void flt_set_inf( float * a, int is_pos) {
  if(is_pos > 0) *a = strtof("Inf", NULL);
  else *a = strtof("-Inf", NULL);
}

void flt_set_zero( float * a, int is_pos) {
  if(is_pos > 0) *a = strtof("0.0", NULL);
  else *a = strtof("-0.0", NULL);
}


SV * _oload_add(pTHX_  float * a,  float * b, SV * third) {

   float * f_obj;
  SV * obj_ref, * obj;

  Newx(f_obj, 1,  float);
  if(f_obj == NULL) croak("Failed to allocate memory in _oload_add function");
  obj_ref = newSV(0);
  obj = newSVrv(obj_ref, "Math::Float32");

  *f_obj = *a + *b;

  sv_setiv(obj, INT2PTR(IV,f_obj));
  SvREADONLY_on(obj);
  return obj_ref;
}

SV * _oload_sub(pTHX_  float * a,  float * b, SV * third) {

   float * f_obj;
  SV * obj_ref, * obj;

  Newx(f_obj, 1,  float);
  if(f_obj == NULL) croak("Failed to allocate memory in _oload_sub function");
  obj_ref = newSV(0);
  obj = newSVrv(obj_ref, "Math::Float32");

  if(SvTRUE_nomg_NN(third)) *f_obj = *b - *a;
  else *f_obj = *a - *b;

  sv_setiv(obj, INT2PTR(IV,f_obj));
  SvREADONLY_on(obj);
  return obj_ref;
}

SV * _oload_mul(pTHX_  float * a,  float * b, SV * third) {

   float * f_obj;
  SV * obj_ref, * obj;

  Newx(f_obj, 1,  float);
  if(f_obj == NULL) croak("Failed to allocate memory in _oload_mul function");
  obj_ref = newSV(0);
  obj = newSVrv(obj_ref, "Math::Float32");

  *f_obj = *a * *b;

  sv_setiv(obj, INT2PTR(IV,f_obj));
  SvREADONLY_on(obj);
  return obj_ref;
}

SV * _oload_div(pTHX_  float * a,  float * b, SV * third) {

   float * f_obj;
  SV * obj_ref, * obj;

  Newx(f_obj, 1,  float);
  if(f_obj == NULL) croak("Failed to allocate memory in _oload_div function");
  obj_ref = newSV(0);
  obj = newSVrv(obj_ref, "Math::Float32");

  if(SvTRUE_nomg_NN(third)) *f_obj = *b / *a;
  else *f_obj = *a / *b;

  sv_setiv(obj, INT2PTR(IV,f_obj));
  SvREADONLY_on(obj);
  return obj_ref;
}

SV * _oload_fmod(pTHX_  float * a,  float * b, SV * third) {

   float * f_obj;
  SV * obj_ref, * obj;

  Newx(f_obj, 1,  float);
  if(f_obj == NULL) croak("Failed to allocate memory in _oload_fmod function");
  obj_ref = newSV(0);
  obj = newSVrv(obj_ref, "Math::Float32");

  if(SvTRUE_nomg_NN(third)) *f_obj = fmodf(*b, *a);
  else *f_obj = fmodf(*a, *b);

  sv_setiv(obj, INT2PTR(IV,f_obj));
  SvREADONLY_on(obj);
  return obj_ref;
}

SV * _oload_pow(pTHX_  float * a,  float * b, SV * third) {

  float * f_obj;
  SV * obj_ref, * obj;

  Newx(f_obj, 1,  float);
  if(f_obj == NULL) croak("Failed to allocate memory in _oload_pow function");
  obj_ref = newSV(0);
  obj = newSVrv(obj_ref, "Math::Float32");

  if(SvTRUE_nomg_NN(third)) *f_obj = powf(*b, *a);  /* b ** a */
  else *f_obj = powf(*a, *b);                       /* a ** b */

  sv_setiv(obj, INT2PTR(IV,f_obj));
  SvREADONLY_on(obj);
  return obj_ref;
}

int _oload_equiv( float * a,  float * b, SV * third) {
  if(*a == *b) return 1;
  return 0;
}

int _oload_not_equiv( float * a,  float * b, SV * third) {
  if(*a != *b) return 1;
  return 0;
}

int _oload_gt(pTHX_  float * a,  float * b, SV * third) {
  if(SvTRUE_nomg_NN(third)) {
    if(*b > *a) return 1;
    return 0;
  }
  if(*a > *b) return 1;
  return 0;
}

int _oload_gte(pTHX_  float * a,  float * b, SV * third) {
  if(SvTRUE_nomg_NN(third)) {
    if(*b >= *a) return 1;
    return 0;
  }
  if(*a >= *b) return 1;
  return 0;
}

int _oload_lt(pTHX_  float * a,  float * b, SV * third) {
  if(SvTRUE_nomg_NN(third)) {
    if(*b < *a) return 1;
    return 0;
  }
  if(*a < *b) return 1;
  return 0;
}

int _oload_lte(pTHX_  float * a,  float * b, SV * third) {
  if(SvTRUE_nomg_NN(third)) {
    if(*b <= *a) return 1;
    return 0;
  }
  if(*a <= *b) return 1;
  return 0;
}

SV * _oload_spaceship(pTHX_  float * a,  float * b, SV * third) {
  if(*a == *b) return newSViv(0);
  if(is_flt_nan(a) || is_flt_nan(b)) return &PL_sv_undef;
  if(SvTRUE_nomg_NN(third)) {
    if(*b > *a) return newSViv(1);
    return newSViv(-1);
  }
  if(*a > *b) return newSViv(1);
  return newSViv(-1);
}

int _oload_not( float * a, SV * second, SV * third) {
  if(is_flt_nan(a) || *a == 0) return 1;
  return 0;
}

int _oload_bool( float * a, SV * second, SV * third) {
  if(is_flt_nan(a) || *a == 0) return 0;
  return 1;
}

SV * _oload_int(pTHX_  float * a, SV * second, SV * third) {
   float * f_obj;
  SV * obj_ref, * obj;

  Newx(f_obj, 1,  float);
  if(f_obj == NULL) croak("Failed to allocate memory in _oload_int function");
  obj_ref = newSV(0);
  obj = newSVrv(obj_ref, "Math::Float32");

  if(*a >= 0) *f_obj = floorf(*a);
  else *f_obj = ceilf(*a);

  sv_setiv(obj, INT2PTR(IV,f_obj));
  SvREADONLY_on(obj);
  return obj_ref;
}

SV * _oload_log(pTHX_  float * a, SV * second, SV * third) {
   float * f_obj;
  SV * obj_ref, * obj;

  Newx(f_obj, 1,  float);
  if(f_obj == NULL) croak("Failed to allocate memory in _oload_log function");
  obj_ref = newSV(0);
  obj = newSVrv(obj_ref, "Math::Float32");

  *f_obj = logf(*a);

  sv_setiv(obj, INT2PTR(IV,f_obj));
  SvREADONLY_on(obj);
  return obj_ref;
}

SV * _oload_exp(pTHX_  float * a, SV * second, SV * third) {
   float * f_obj;
  SV * obj_ref, * obj;

  Newx(f_obj, 1,  float);
  if(f_obj == NULL) croak("Failed to allocate memory in _oload_exp function");
  obj_ref = newSV(0);
  obj = newSVrv(obj_ref, "Math::Float32");

  *f_obj = expf(*a);

  sv_setiv(obj, INT2PTR(IV,f_obj));
  SvREADONLY_on(obj);
  return obj_ref;
}

SV * _oload_sqrt(pTHX_  float * a, SV * second, SV * third) {
  float * f_obj;
  SV * obj_ref, * obj;


  Newx(f_obj, 1,  float);
  if(f_obj == NULL) croak("Failed to allocate memory in _oload_sqrt function");
  obj_ref = newSV(0);
  obj = newSVrv(obj_ref, "Math::Float32");

  *f_obj = sqrtf(*a);

  sv_setiv(obj, INT2PTR(IV,f_obj));
  SvREADONLY_on(obj);
  return obj_ref;
}

void _unpack_flt_hex(pTHX_  float * f) {
  dXSARGS;
  int i;
  char * buff;
   float bf16 = *f;
  void * p = &bf16;

  Newx(buff, 8, char);
  if(buff == NULL) croak("Failed to allocate memory in unpack_flt_hex");

  sp = mark;

#ifdef WE_HAVE_BENDIAN /* Big Endian architecture */
  for (i = 0; i < 4; i++) {
#else
  for (i = 3; i >= 0; i--) {
#endif
    sprintf(buff, "%02X", ((unsigned char*)p)[i]);
    XPUSHs(sv_2mortal(newSVpv(buff, 0)));
  }
  PUTBACK;
  Safefree(buff);
  XSRETURN(4);
}

void nextafter_flt(float * rop, float * op1, float * op2) {
  *rop = nextafterf(*op1, *op2);
}

void flt_nextabove( float * a) {
  float f = strtof("Inf", NULL);
  *a = nextafterf(*a, f);
}

void flt_nextbelow( float * a) {
  float f = strtof("-Inf", NULL);
  *a = nextafterf(*a, f);
}

void DESTROY(SV * obj) {
  /* printf("Destroying object\n"); *//* debugging check */
  Safefree(INT2PTR( float *, SvIVX(SvRV(obj))));
}





MODULE = Math::Float32  PACKAGE = Math::Float32

PROTOTYPES: DISABLE


SV *
_itsa (a)
	SV *	a
CODE:
  RETVAL = _itsa (aTHX_ a);
OUTPUT:  RETVAL

int
is_flt_nan (obj)
	float *	obj

int
is_flt_inf (obj)
	float *	obj

SV *
_fromFloat32 (in)
	float *	in
CODE:
  RETVAL = _fromFloat32 (aTHX_ in);
OUTPUT:  RETVAL

SV *
_fromNV (in)
	SV *	in
CODE:
  RETVAL = _fromNV (aTHX_ in);
OUTPUT:  RETVAL

SV *
_fromIV (in)
	SV *	in
CODE:
  RETVAL = _fromIV (aTHX_ in);
OUTPUT:  RETVAL

SV *
_fromPV (in)
	SV *	in
CODE:
  RETVAL = _fromPV (aTHX_ in);
OUTPUT:  RETVAL

SV *
flt_to_NV (obj)
	float *	obj
CODE:
  RETVAL = flt_to_NV (aTHX_ obj);
OUTPUT:  RETVAL

void
_flt_set (a, b)
	float *	a
	float *	b
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        _flt_set(a, b);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return;

void
flt_set_nan (a)
	float *	a
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        flt_set_nan(a);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return;

void
flt_set_inf (a, is_pos)
	float *	a
	int	is_pos
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        flt_set_inf(a, is_pos);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return;

void
flt_set_zero (a, is_pos)
	float *	a
	int	is_pos
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        flt_set_zero(a, is_pos);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return;

SV *
_oload_add (a, b, third)
	float *	a
	float *	b
	SV *	third
CODE:
  RETVAL = _oload_add (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_oload_sub (a, b, third)
	float *	a
	float *	b
	SV *	third
CODE:
  RETVAL = _oload_sub (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_oload_mul (a, b, third)
	float *	a
	float *	b
	SV *	third
CODE:
  RETVAL = _oload_mul (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_oload_div (a, b, third)
	float *	a
	float *	b
	SV *	third
CODE:
  RETVAL = _oload_div (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_oload_fmod (a, b, third)
	float *	a
	float *	b
	SV *	third
CODE:
  RETVAL = _oload_fmod (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_oload_pow (a, b, third)
	float *	a
	float *	b
	SV *	third
CODE:
  RETVAL = _oload_pow (aTHX_ a, b, third);
OUTPUT:  RETVAL

int
_oload_equiv (a, b, third)
	float *	a
	float *	b
	SV *	third

int
_oload_not_equiv (a, b, third)
	float *	a
	float *	b
	SV *	third

int
_oload_gt (a, b, third)
	float *	a
	float *	b
	SV *	third
CODE:
  RETVAL = _oload_gt (aTHX_ a, b, third);
OUTPUT:  RETVAL

int
_oload_gte (a, b, third)
	float *	a
	float *	b
	SV *	third
CODE:
  RETVAL = _oload_gte (aTHX_ a, b, third);
OUTPUT:  RETVAL

int
_oload_lt (a, b, third)
	float *	a
	float *	b
	SV *	third
CODE:
  RETVAL = _oload_lt (aTHX_ a, b, third);
OUTPUT:  RETVAL

int
_oload_lte (a, b, third)
	float *	a
	float *	b
	SV *	third
CODE:
  RETVAL = _oload_lte (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_oload_spaceship (a, b, third)
	float *	a
	float *	b
	SV *	third
CODE:
  RETVAL = _oload_spaceship (aTHX_ a, b, third);
OUTPUT:  RETVAL

int
_oload_not (a, second, third)
	float *	a
	SV *	second
	SV *	third

int
_oload_bool (a, second, third)
	float *	a
	SV *	second
	SV *	third

SV *
_oload_int (a, second, third)
	float *	a
	SV *	second
	SV *	third
CODE:
  RETVAL = _oload_int (aTHX_ a, second, third);
OUTPUT:  RETVAL

SV *
_oload_log (a, second, third)
	float *	a
	SV *	second
	SV *	third
CODE:
  RETVAL = _oload_log (aTHX_ a, second, third);
OUTPUT:  RETVAL

SV *
_oload_exp (a, second, third)
	float *	a
	SV *	second
	SV *	third
CODE:
  RETVAL = _oload_exp (aTHX_ a, second, third);
OUTPUT:  RETVAL

SV *
_oload_sqrt (a, second, third)
	float *	a
	SV *	second
	SV *	third
CODE:
  RETVAL = _oload_sqrt (aTHX_ a, second, third);
OUTPUT:  RETVAL

void
_unpack_flt_hex (f)
	float *	f
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        _unpack_flt_hex(aTHX_ f);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return;

void
nextafter_flt (rop, op1, op2)
	float *	rop
	float *	op1
	float *	op2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        nextafter_flt(rop, op1, op2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return;

void
flt_nextabove (a)
	float *	a
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        flt_nextabove(a);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return;

void
flt_nextbelow (a)
	float *	a
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        flt_nextbelow(a);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return;

void
DESTROY (obj)
	SV *	obj
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        DESTROY(obj);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return;

