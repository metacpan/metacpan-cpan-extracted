/*!
    @header PJS_Function.h
    @abstract Types and functions related to function bindings
*/

#ifndef __PJS_PROPERTY_H__
#define __PJS_PROPERTY_H__

#ifdef _cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"

#include "JavaScript_Env.h"
#include "PJS_Types.h"
#include "PJS_Common.h"

struct PJS_Property {
    int8 tinyid;
    
    SV *getter;    /* these are coderefs! */
    SV *setter;

    struct PJS_Property *_next;
};

PJS_EXTERN void
PJS_free_property(PJS_Property *);

PJS_EXTERN void
PJS_free_JSPropertySpec(JSPropertySpec *);

PJS_EXTERN JSBool
PJS_invoke_perl_property_getter(JSContext *cx, JSObject *, jsval, jsval *);

PJS_EXTERN JSBool
PJS_invoke_perl_property_setter(JSContext *cx, JSObject *, jsval, jsval *);                

#endif
