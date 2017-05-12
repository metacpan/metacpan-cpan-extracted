#include "JS.h"

#if !defined(JS_HAS_BRANCH_HANDLER)
#define JS_HAS_OPCB
#endif

#if defined(JS_HAS_OPCB)
JSBool
PJS_operation_callback(
    JSContext *cx
) {
    dTHX;
    PJS_Context *pcx;
    SV *rv;
    JSBool status = JS_TRUE;
    JSOperationCallback ocb = JS_GetOperationCallback(cx);
    
    pcx = PJS_GET_CONTEXT(cx);

    if(pcx && pcx->branch_handler) {
	dSP;

	JS_SetOperationCallback(cx, NULL);
        ENTER; SAVETMPS;
        PUSHMARK(SP);
	sv_setiv(save_scalar(PJS_Context_SV), PTR2IV(pcx));
        
        (void)call_sv(SvRV(pcx->branch_handler), G_SCALAR | G_EVAL);

        SPAGAIN;
        rv = POPs;
        if(!SvTRUE(rv))
            status = JS_FALSE;

        PUTBACK;
        FREETMPS; LEAVE;

        if(SvTRUE(ERRSV)) {
	    jsval rval;
	    SV* cp = newSVsv(ERRSV);
	    if(!PJS_ReflectPerl2JS(aTHX_ cx, NULL, cp, &rval)) 
		croak("Can't convert perl error into JSVAL");
	    JS_SetPendingException(cx, rval);
	    sv_setsv(ERRSV, &PL_sv_undef);            
	    sv_free(cp);
	}
        
	JS_SetOperationCallback(cx, ocb);
    }
    return status;
}
#endif

MODULE = JSPL::Context::Timeout	PACKAGE = JSPL::Context
PROTOTYPES: DISABLE

void
jsc_set_opcb(pcx, handler)
    JSPL::Context pcx;
    SV *handler;
    CODE:
#ifdef JS_HAS_OPCB
	if (!SvOK(handler)) { /* Remove handler */
	    sv_free(pcx->branch_handler);
	    pcx->branch_handler = NULL;
	    JS_SetOperationCallback(PJS_getJScx(pcx), NULL);
	}
	else if (SvROK(handler) && SvTYPE(SvRV(handler)) == SVt_PVCV) {
	    sv_free(pcx->branch_handler);
	    pcx->branch_handler = SvREFCNT_inc_simple_NN(handler);
	    JS_SetOperationCallback(PJS_getJScx(pcx), PJS_operation_callback);
	} 
	else croak("%s: %s is not a CODE reference",
	           NAMESPACE"RawRT::jsc_set_opcb",
		   "handler");
#else
	PERL_UNUSED_VAR(handler);
	croak("%s: not available in this SpiderMonkey",
	      NAMESPACE"RatRT::jsc_set_opcb");
#endif

#ifndef JS_HAS_OPCB
void
_set_tocb(pcx, handler)
    JSPL::Context pcx;
    SV *handler;
    CODE:
	sv_free(pcx->branch_handler);
	pcx->branch_handler = NULL;
	if (!SvTRUE(handler))
	    JS_SetBranchCallback(PJS_getJScx(pcx), NULL);
	else
	    JS_SetBranchCallback(PJS_getJScx(pcx), PJS_branch_handler);

void
_trigger_tocb(pcx, handler)
    JSPL::Context pcx;
    SV *handler;
    CODE:
	if(SvROK(handler) && SvTYPE(SvRV(handler)) == SVt_PVCV)
	    pcx->branch_handler = SvREFCNT_inc_simple_NN(handler);
	else {
	    sv_free(pcx->branch_handler);
	    pcx->branch_handler = NULL;
	}

#endif

void
jsc_trigger_opcb(pcx)
    JSPL::Context pcx;
    CODE:
#ifdef	JS_HAS_OPCB
	JS_TriggerOperationCallback(PJS_getJScx(pcx));
#else
	croak("%s: not available in this SpiderMonkey",
		  NAMESPACE"RatRT::jsc_trigger_opcb");
#endif

