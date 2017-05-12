/*!
    @header JavaScript.pm
    @abstract This module provides an interface between SpiderMonkey and perl.
        
    @copyright Claes Jakobsson 2001-2007
    @copyright Matias Software Group 2008-2012
*/

#ifndef __JAVASCRIPT_H__
#define __JAVASCRIPT_H__

#include "JS_Env.h"
#ifndef WIN32
#define PERL_NO_GET_CONTEXT
#endif
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#if defined(__cplusplus) && defined(__GNUC__)
#undef dNOOP
#define dNOOP	extern int __attribute__ ((unused)) Perl___notused
#endif

#undef Move /* Used in new SM */

#include <jsapi.h>
#include <jsdbgapi.h>

#ifndef JS_ARGV_CALLEE
#define JS_ARGV_CALLEE(argv)	    ((argv)[-2])
#endif

#ifdef	JS_THREADSAFE
#define PJS_BeginRequest(cx)	    JS_BeginRequest(cx)
#define PJS_EndRequest(cx)	    JS_EndRequest(cx)
#else
#define PJS_BeginRequest(cx)	    /**/
#define PJS_EndRequest(cx)	    /**/
#endif

#define	PJS_GET_CLASS(cx,obj)	    JS_GET_CLASS(cx,obj)

#if PJS_UTF8_NATIVE
#define PJS_SvPV(sv, len)	    SvPVutf8(sv, len)
#else
#define	PJS_SvPV(sv, len)	    (!JS_CStringsAreUTF8() ? PJS_ConvertUC(aTHX_ sv, &len) : SvPVutf8(sv, len))
#endif

#if JS_VERSION == 185
# define PJS_GC(cx)		    {\
    JSErrorReporter older = JS_SetErrorReporter(cx,NULL);\
    JS_GC(cx);\
    JS_SetErrorReporter(cx,older);\
}
# define PJS_SetterPropStub	    JS_StrictPropertyStub
# define pjsid			    jsid
# define PJSID_IS(type, id)	    JSID_IS_ ## type(id)
# define PJSID_TO(type, id)	    JSID_TO_ ## type(id)
# define DEFSTRICT_		    JSBool strict,
# define PASSTRICT_		    strict,
# define PJS_JSV2PSV(psv,jsv)	    sv_setref_pvn(psv,PJS_RAW_JSVAL,(char *)&(jsv),sizeof(jsv))
# define PJS_PSV2JSV(jsv,psv)	    ((jsv)=*(jsval *)(SvPVX(SvRV(psv))))
#else
# define PJS_GC(cx)		    JS_GC(cx)
# define PJS_SetterPropStub	    JS_PropertyStub
# define pjsid			    jsval
# define PJSID_IS(type, id)	    JSVAL_IS_ ## type(id)
# define PJSID_TO(type, id)	    JSVAL_TO_ ## type(id)
# define DEFSTRICT_		    /**/
# define PASSTRICT_		    /**/
# define PJS_JSV2PSV(psv,jsv)	    sv_setref_iv(psv,PJS_RAW_JSVAL,(IV)jsv)
# define PJS_PSV2JSV(jsv,psv)	    ((jsv)=(jsval)(SvIV(SvRV(psv))))
#endif

#ifdef JSS_IS_OBJ
# define PJS_Script		    JSObject
# define PJS_O2S(cx,obj)	    (obj)
# define PJS_S2O(cx,scr)	    (scr)
# define JS_DestroyScript(cx,scr)   /**/
#else
# define PJS_Script		    JSScript
# ifdef JSS_IS_NEW
#   define PJS_O2S(cx,obj)	    ((JSScript *)JS_GetPrivate(cx, obj))
#   define PJS_S2O(cx,scr)	    JS_GetObjectFromScript(scr)
#   define JS_DestroyScript(cx,scr)   /**/
# else
#   define PJS_O2S(cx,obj)	    ((JSScript *)JS_GetPrivate(cx, obj))
#   define PJS_S2O(cx,scr)	    JS_NewScriptObject(cx, scr)
# endif
#endif

#define DSLOWFUNARGS_		    JSObject *obj, uintN argc, jsval *argv, jsval *rval
#define DSLOWFUNARGS		    /**/
#define DFASTFUNARGS_		    uintN argc, jsval *vp
#define DFASTFUNARGS		    JSObject *obj = PJS_IsConstructing(cx, vp) ? NULL : JS_THIS_OBJECT(cx, vp);\
				    jsval *argv = JS_ARGV(cx, vp);\
				    jsval *rval = vp;
#ifdef JS_FN
# define DEFJSFFARGS_		    DFASTFUNARGS_
# define DECJSFFARGS		    DFASTFUNARGS
# if JS_VERSION < 185
#  define PJS_IsConstructing(cx,vp) FALSE 
#  define DEFJSFSARGS_		    DSLOWFUNARGS_
#  define DECJSFSARGS		    DSLOWFUNARGS
#  define PJS_SET_RVAL(cx, jsval)   (*rval = (jsval))
# else
#  define PJS_IsConstructing(cx,vp)  JS_IsConstructing(cx, vp)
#  define DEFJSFSARGS_		    DFASTFUNARGS_
#  define DECJSFSARGS		    DFASTFUNARGS
#  define PJS_SET_RVAL(cx, jsval)   JS_SET_RVAL(cx, vp, jsval)
# endif
#else
# define DEFJSFFARGS_		    DSLOWFUNARGS_
# define DECJSFFARGS		    DSLOWFUNARGS
# define DEFJSFSARGS_		    DSLOWFUNARGS_
# define DECJSFSARGS		    DSLOWFUNARGS
# define JS_FN(name,call,nargs,flags)    {name,call,nargs,flags,0}
# define JS_FS_END		    {0,0,0,0,0}
# define PJS_SET_RVAL(cx, jsval)    (*rval = (jsval))
#endif

#if defined(PJSDEBUG)
#define	PJS_DEBUG(x)		    warn(x)
#define	PJS_DEBUG1(x,x1)	    warn(x,x1)
#define	PJS_DEBUG2(x,x1,x2)	    warn(x,x1,x2)
#define	PJS_DEBUG3(x,x1,x2,x3)	    warn(x,x1,x2,x3)
#else
#define PJS_DEBUG(x)		    /**/
#define PJS_DEBUG1(x,x1)	    /**/
#define PJS_DEBUG2(x,x1,x2)	    /**/
#define PJS_DEBUG3(x,x1,x2,x3)	    /**/
#endif
    
#define JSCLASS_IS_BRIDGE	(1<<(JSCLASS_HIGH_FLAGS_SHIFT+7))
#define	JSCLASS_PRIVATE_IS_PERL	(JSCLASS_HAS_PRIVATE|JSCLASS_IS_BRIDGE|JSCLASS_HAS_RESERVED_SLOTS(1))

#define IS_PERL_CLASS(clasp)	(((clasp)->flags & JSCLASS_PRIVATE_IS_PERL)==JSCLASS_PRIVATE_IS_PERL)
#undef PJS_CONTEXT_IN_PERL

#define NAMESPACE		    "JSPL::"
#define PJS_GTYPEDEF(type, wrap)    typedef type * JSPL__ ## wrap
#define PJS_TYPEDEF(x)		    PJS_GTYPEDEF(PJS_ ## x, x)

#include "PJS_Types.h"
#include "PJS_Common.h"
#include "PJS_Call.h"
#include "PJS_Context.h"
#include "PJS_Reflection.h"
#include "PJS_Exceptions.h"
#include "PJS_PerlArray.h"
#include "PJS_PerlHash.h"
#include "PJS_PerlSub.h"
#include "PJS_PerlPackage.h"
#include "PJS_PerlScalar.h"

#ifndef SvREFCNT_inc_void_NN
#define SvREFCNT_inc_void_NN(x)	    SvREFCNT_inc(x)
#define SvREFCNT_inc_simple_NN(x)   SvREFCNT_inc(x)
#endif

#endif
