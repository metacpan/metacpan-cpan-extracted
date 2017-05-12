/*!
    @header PJS_Class.h
    @abstract Types and functions related to class bindings
*/

#ifndef __PJS_CLASS_H__
#define __PJS_CLASS_H__

#ifdef __cplusplus
extern "C" {
#endif

#include "perl.h"

#include "JavaScript_Env.h"

#include "PJS_Types.h"
#include "PJS_Common.h"

struct PJS_Class {
    /* Clasp */
    JSClass *clasp;
	
    /* Package name in Perl */
    char *pkg;
      
    /* Reference to Perl subroutine that returns an instance of the object */
    SV *cons;

    /* Reference to prototype object */
    JSObject *proto;

    /* Linked list of methods bound to class */
    PJS_Function *methods;
    JSFunctionSpec *fs;
    JSFunctionSpec *static_fs;
    
    /* Linked list of properties bound to class */
    int8 next_property_id;
    PJS_Property *properties;
    JSPropertySpec *ps;
    JSPropertySpec *static_ps;

    /* Flags such as JS_CLASS_NO_INSTANCE */
    I32 flags;

    struct PJS_Class *_next;    
};

PJS_EXTERN PJS_Function *
PJS_get_method_by_name(PJS_Class *, const char *);

PJS_EXTERN PJS_Property *
PJS_get_property_by_id(PJS_Class *, int8);

PJS_EXTERN void
PJS_free_class(PJS_Class *);

PJS_EXTERN void
PJS_bind_class(PJS_Context *, char *, char *, SV *, HV *, HV *, HV *, HV *, U32);

PJS_EXTERN void
PJS_finalize(JSContext *, JSObject *);

PJS_EXTERN JSBool
PJS_construct_perl_object(JSContext *, JSObject *, uintN , jsval *, jsval *);

PJS_EXTERN JSFunctionSpec *
PJS_add_class_functions(PJS_Class *, HV *, U8);

PJS_EXTERN JSPropertySpec *
PJS_add_class_properties(PJS_Class *, HV *, U8);

PJS_EXTERN JSBool
PJS_invoke_perl_object_method(JSContext *, JSObject *, uintN , jsval *, jsval *);

PJS_EXTERN void
PJS_store_class(PJS_Context *pcx, PJS_Class *cls);

/*!  @functiongroup Query functions */

PJS_EXTERN const char *
PJS_GetClassName(PJS_Class *class);

PJS_EXTERN const char *
PJS_GetClassPackage(PJS_Class *class);    
    
#ifdef __cplusplus
}
#endif

#endif

