/*!
    @header PJS_Context.h
    @abstract Types and functions related to context handling
*/

#ifndef __PJS_CONTEXT_H__
#define __PJS_CONTEXT_H__

#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"

#include "JavaScript_Env.h"

#include "PJS_Types.h"
#include "PJS_Common.h"

/*! @struct PJS_Context
    @abstract
*/
struct PJS_Context {
    /* The JavaScript context which this instance belongs to */
    JSContext *cx;

    /* Pointer to the first callback item that is registered */
	HV *function_by_name;

    /* Pointer to the first bound class */
	HV *class_by_name;
	HV *class_by_package;
	
    PJS_Context *next;      /* Pointer to the next created context */
    PJS_Runtime *rt;

    /* Set to a SVt_PVCV if we have an branch handler */
    SV *branch_handler;
    
    /* Flags */
    U32 flags;
};

/*! @function PJS_DestroyContext
    @abstract Frees a PJS_Context and the underlying JSContext
    @param context The context to free
*/
PJS_EXTERN void
PJS_DestroyContext(PJS_Context *context);

/*! @function PJS_DefineFunction
    @abstract Binds a Perl function to JavaScript
    @param inContext The context to add the function to
    @param functionName The name that the function will be callable as from JavaScript.
    @param functionRef A SVt_PVCV that we call when the function is called.
    @result A pointer to a PJS_Function that represents the function if binding was successful or NULL if otherwise.
*/
PJS_EXTERN PJS_Function *
PJS_DefineFunction(PJS_Context *inContext, const char *functionName, SV *functionRef);

/*! @function PJS_CreateContext
    @abstract Creates a new context
    @discussion This function creates a new context in the given runtime and sets
    up initial classes and global object.
    @param runtime Runtime that'll execute the context.
    @result A pointer to a PJS_Context structure if successfull.
*/
PJS_EXTERN PJS_Context *
PJS_CreateContext(PJS_Runtime *runtime);

PJS_EXTERN JSBool
PJS_branch_handler(JSContext *, JSScript *);

/*! @functiongroup Querying contexts */

/*! @function PJS_GetFunctionByName
    @abstract Retrieves a function by name from a given context
    @param fromContext  Context to retrieve the function from
    @param functionName Name of the function
    @result A pointer to a PJS_Function structure if the function was found 
    or NULL if the function did not exist.
*/
PJS_EXTERN PJS_Function *
PJS_GetFunctionByName(PJS_Context *fromContext, const char *functionName);

/*! @function PJS_GetJSContext
    @abstract Retrieve the JSContext from a PJS_Context
    @param fromContext The context to search in
    @result A pointer to the underlying JSContext
*/
#define PJS_GetJSContext(fromContext) (fromContext->cx)

/*PJS_EXTERN JSContext *
PJS_GetJSContext(PJS_Context *fromContext);*/

/*! @function PJS_GetClassByName
    @abstract Retrieve a bound class from a context
    @param fromContext The Context to search in
    @param className The name exposed to JavaScript
    @result a pointer to a PJS_Class if it exists, NULL otherwise
*/
PJS_EXTERN PJS_Class *
PJS_GetClassByName(PJS_Context *fromContext, const char *className);

/*! @function PJS_GetClassByPackage
    @abstract Retrieve a bound class from a context
    @param fromContext The Context to search in
    @param className The package name used in Perl to represent the class
    @result a pointer to a PJS_Class if it exists, NULL otherwise
*/
PJS_EXTERN PJS_Class *
PJS_GetClassByPackage(PJS_Context *fromContext, const char *packageName);

#ifdef _cplusplus
}
#endif

#endif
