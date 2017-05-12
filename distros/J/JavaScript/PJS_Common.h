/*!
    @header PJS_Common.h
    @abstract Common macros and functions
*/

#ifndef __PJS_COMMON_H__
#define __PJS_COMMON_H__

#ifdef _cpluslpus
extern "C" {
#endif

#include "EXTERN.h"

#ifdef JS_THREADSAFE
#define PJS_GET_CLASS(cx,obj) JS_GetClass(cx,obj)
#else
#define PJS_GET_CLASS(cx,obj) JS_GetClass(obj)
#endif

#define PJS_INSTANCE_METHOD  0
#define PJS_CLASS_METHOD     1

#define PJS_GET_CONTEXT(cx)  (PJS_Context *) JS_GetContextPrivate(cx)

#define PJS_FUNC_SELF        JS_ValueToFunction(cx, argv[-2])
#define PJS_FUNC_PARENT      (JSObject *) JSVAL_TO_OBJECT(argv[-1])

/*! @define PJS_ERROR_PACKAGE
    @abstract Perl package to bless errors into
*/
#define PJS_ERROR_PACKAGE     "JavaScript::Error"

/*! @define PJS_FUNCTION_PACKAGE
    @abstract Perl package to bless functions into
*/
#define PJS_FUNCTION_PACKAGE  "JavaScript::Function"

/*! @define PJS_GENERATOR_PACKAGE
    @abstract Perl package to bless Generators into
*/
#define PJS_GENERATOR_PACKAGE "JavaScript::Generator"

/*! @define PJS_BOXED_PACKAGE
    @abstract Perl package to bless boxed values into
*/
#define PJS_BOXED_PACKAGE     "JavaScript::Boxed"

#define PJS_PROP_PRIVATE      	0x1
#define PJS_PROP_READONLY     	0x2
#define PJS_PROP_ACCESSOR     	0x4
#define PJS_CLASS_NO_INSTANCE	0x1
#define PJS_FREE_JSCLASS		0x2

#define _IS_UNDEF(a) (SvANY(a) == SvANY(&PL_sv_undef))

#define PJS_EXTERN EXT

#ifdef _cplusplus
}
#endif

#endif
