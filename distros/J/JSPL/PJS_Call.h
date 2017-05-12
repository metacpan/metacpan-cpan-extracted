/*!
    @header PJS_Call.h
    @abstract Types and functions related to calling methods and functions
*/

#ifndef __PJS_CALL_H__
#define __PJS_CALL_H__

#ifdef __cplusplus
extern "C" {
#endif

PJS_EXTERN SV *
PJS_CallPerlMethod(pTHX_ JSContext *, const char *, ...);

PJS_EXTERN JSBool
PJS_Call_sv_with_jsvals_rsv(pTHX_ JSContext *, JSObject *, SV *, SV *, uintN, jsval *, SV **, I32);

PJS_EXTERN JSBool
PJS_Call_sv_with_jsvals(pTHX_ JSContext *, JSObject *, SV *, SV *, uintN, jsval *, jsval *, I32);

PJS_EXTERN JSBool
PJS_Call_js_function(pTHX_ JSContext *, JSObject *, jsval, AV *, jsval *);

#ifdef __cplusplus
}
#endif

#endif
