/*!
    @header PJS_Common.h
    @abstract Common macros and functions
*/

#ifndef __PJS_COMMON_H__
#define __PJS_COMMON_H__

#define PJS_INSTANCE_METHOD  0
#define PJS_CLASS_METHOD     1

#ifdef PJS_CONTEXT_IN_PERL
#define PJS_GET_CONTEXT(cx)  PJS_GetContext(cx)
#else
#define PJS_GET_CONTEXT(cx)  ((PJS_Context *) JS_GetContextPrivate(cx))
#endif

#define PJS_FUNC_SELF        JS_ValueToFunction(cx, argv[-2])
#define PJS_FUNC_PARENT      ((JSObject *) JSVAL_TO_OBJECT(argv[-1]))

/*! @define PJS_ERROR_PACKAGE
    @abstract Perl package to bless errors into
*/
#define PJS_ERROR_PACKAGE     NAMESPACE"Error"

/*! @define PJS_FUNCTION_PACKAGE
    @abstract Perl package to bless functions into
*/
#define PJS_FUNCTION_PACKAGE  NAMESPACE"Function"

/*! @define PJS_BOXED_PACKAGE
    @abstract Perl package to bless boxed values into
*/
#define PJS_BOXED_PACKAGE     NAMESPACE"Boxed"
#define PJS_BOOLEAN           NAMESPACE"Boolean"

#define PJS_ARRAY_PACKAGE     NAMESPACE"Array"
#define PJS_OBJECT_PACKAGE    NAMESPACE"Object"
#define PJS_XMLOBJ_PACKAGE    NAMESPACE"XMLObject"

#define PJS_STASH_PACKAGE     NAMESPACE"Stash"
#define PJS_RAW_OBJECT	      NAMESPACE"RawObj"
#define PJS_RAW_JSVAL	      NAMESPACE"JSVAL"

#define PJS_PROXY_PROP	      "Proxy"
#define PJS_PACKAGE_PROP      "__PACKAGE__"

#define PJS_PROP_PRIVATE      	0x1
#define PJS_PROP_READONLY     	0x2
#define PJS_PROP_ACCESSOR     	0x4
#define PJS_CLASS_NO_INSTANCE	0x1
#define PJS_FREE_JSCLASS	0x2
#define PJS_CLASS_EXMODE	0x4

#define _IS_UNDEF(a) (SvANY(a) == SvANY(&PL_sv_undef))

#define PJS_EXTERN extern

PJS_EXTERN JSObject*
PJS_GetScope(pTHX_ JSContext *cx, SV *sv);

PJS_EXTERN PJS_Script *
PJS_MakeScript(pTHX_ JSContext *cx, JSObject *scope, SV *source, const char *name);

#endif
