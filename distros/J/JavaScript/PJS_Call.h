/*!
    @header PJS_Call.h
    @abstract Types and functions related to calling methods and functions
*/

#ifndef __PJS_CALL_H__
#define __PJS_CALL_H__

#ifdef _cplusplus
extern "C" {
#endif

#include "perl.h"

#include "JavaScript_Env.h"

#include "PJS_Types.h"
#include "PJS_Common.h"

PJS_EXTERN SV *
PJS_call_perl_method(const char *, ...);

PJS_EXTERN I32
perl_call_sv_with_jsvals_rsv(JSContext *, JSObject *, SV *, SV *, uintN, jsval *, SV **);

PJS_EXTERN I32
perl_call_sv_with_jsvals(JSContext *, JSObject *, SV *, SV *, uintN, jsval *, jsval *);

PJS_EXTERN JSBool
PJS_call_javascript_function(PJS_Context *, jsval, SV *, jsval *);

PJS_EXTERN JSBool
perl_call_jsfunc(JSContext *, JSObject *, uintN, jsval *, jsval *);

#endif
