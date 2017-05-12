/*!
    @header PJS_TypeConversion.h
*/

#ifndef __PJS_TYPECONVERSION_H__
#define __PJS_TYPECONVERSION_H__

#ifdef _cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"

#include "JavaScript_Env.h"

#include "PJS_Common.h"

PJS_EXTERN SV *
JSHASHToSV(JSContext *, HV *, JSObject *);

PJS_EXTERN SV *
JSARRToSV(JSContext *, HV *, JSObject *);

PJS_EXTERN JSBool
JSVALToSV(JSContext *, HV *, jsval, SV **);

PJS_EXTERN JSBool
PJS_ConvertPerlToJSType(JSContext *, JSObject *, JSObject *, SV *, jsval *);

#ifdef _cplusplus
}
#endif

#endif
