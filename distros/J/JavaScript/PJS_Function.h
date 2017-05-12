/*!
    @header PJS_Function.h
    @abstract Types and functions related to function bindings
*/

#ifndef __PJS_FUNCTION_H__
#define __PJS_FUNCTION_H__

#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"

#include "JavaScript_Env.h"

#include "PJS_Types.h"
#include "PJS_Common.h"

/*! @struct     PJS_Function
    @abstract   This type maps Perl subroutines to JavaScript functions by name
    @discussion A linked list of these structures are maintained by each context.
                In the future this should change to a HV *.
*/
struct PJS_Function {
    /* The name of the JavaScript function which this perl function is bound to */
    char *name;
    
    /* The perl reference to the function */
    SV *callback;
    
    /* Next function in list */
    struct PJS_Function *_next;
};

/*! @function PJS_FreeFunction
    @abstract Frees the memory consumed by a PJS_Function struct
    @param function The function to free
*/
PJS_EXTERN void
PJS_DestroyFunction(PJS_Function *function);

PJS_EXTERN void
PJS_free_JSFunctionSpec(JSFunctionSpec *);

PJS_EXTERN JSBool
PJS_invoke_perl_function(JSContext *, JSObject *, uintN, jsval *, jsval *);

/*! @functiongroup Initialize functions */

/*! @function PJS_CreateFunction
    @abstract Allocates memory and initializes a PJS_Function structure.
    @result A pointer to a new function or NULL on failure.
*/
PJS_EXTERN PJS_Function *
PJS_CreateFunction(const char *functionName, SV *perlCallback);

/*! @functiongroup Query functions */

/*! @function PJS_GetFunctionName
    @abstract Retrieves the name of a function
    @param function The function to query
    @result The name the function is bound as
*/
PJS_EXTERN const char *
PJS_GetFunctionName(PJS_Function *function);

/*! @function PJS_GetFunctionTarget
    @abstract Retrieves the target Perl subroutine
    @param function The function to query
    @result An SV pointer to the target subroutine
*/
PJS_EXTERN const SV *
PJS_GetFunctionTarget(PJS_Function *function);

#ifdef __cplusplus
}
#endif

#endif
