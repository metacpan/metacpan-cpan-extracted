#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "JavaScript_Env.h"

#include "PJS_Call.h"
#include "PJS_Context.h"
#include "PJS_TypeConversion.h"

SV *PJS_call_perl_method(const char *method, ...) {
    dSP;
    va_list ap;
    SV *arg, *ret = sv_newmortal();
    int rcount;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    va_start(ap, method);
    while ((arg = va_arg(ap, SV*)) != NULL) {
        XPUSHs(arg);
    }

    PUTBACK;

    rcount = perl_call_method(method, G_SCALAR);

    SPAGAIN;

    sv_setsv(ret, POPs);

    PUTBACK;
    FREETMPS;
    LEAVE;

    return ret;
}

I32 perl_call_sv_with_jsvals_rsv(JSContext *cx, JSObject *obj, SV *code, SV *caller, uintN argc, jsval *argv, SV **rsv) {
    dSP;
    I32 rcount = 0;
    int arg;
    
    if (SvROK(code) && SvTYPE(SvRV(code)) == SVt_PVCV) {
        ENTER ;
        SAVETMPS ;
        PUSHMARK(SP) ;
        
        if (caller) {
            XPUSHs(caller);
        }
        
        for (arg = 0; arg < argc; arg++) {
            SV *sv = sv_newmortal();

            PUTBACK ; /* Make perl take note of our local SP*/

            JSVALToSV(cx, NULL, argv[arg], &sv);

            SPAGAIN ; /* Just to be safe */
	
            XPUSHs(sv);
        }
        
        PUTBACK ;
        
        rcount = perl_call_sv(SvRV(code), G_SCALAR|G_EVAL);
        
        SPAGAIN ;
        
        if(rcount) {
            int i;
            /* XXX: this is wrong */
            for (i = 0; i < rcount; ++i) {
                if (rsv) {
                    *rsv = POPs;
                    SvREFCNT_inc(*rsv);
                }
            }
        }
        else {
        }

        if (SvTRUE(ERRSV)) {
            jsval rval;
            SV* cp = sv_mortalcopy( ERRSV );
            if (PJS_ConvertPerlToJSType(cx, NULL, obj, cp, &rval) != JS_FALSE) {
                JS_SetPendingException(cx, rval);
                rcount = -1;

                /* ERRSV is now converted into JS space. If it leaves again,
                    we'll turn it into a perl exception, so we can drop the
                    perl-space error here. */
                sv_setsv(ERRSV, &PL_sv_undef);            
            }
            else {
                croak("Can't convert perl error into JSVAL");
            }
        }
        
        PUTBACK ;
        FREETMPS ;
        LEAVE ;
    }
    else {
        warn("not a coderef");
    }
    
    return rcount;
}

I32 perl_call_sv_with_jsvals(JSContext *cx, JSObject *obj, SV *code, SV *caller, uintN argc, jsval *argv, jsval *rval) {
    SV *rsv;
    I32 rcount = perl_call_sv_with_jsvals_rsv(cx, obj, code, caller, argc, argv, rval ? &rsv : NULL);
    
    if (rval) {
        PJS_ConvertPerlToJSType(cx, NULL, obj, rsv, rval);
    }
    
    return rcount;
}

JSBool PJS_call_javascript_function(PJS_Context *pcx, jsval func, SV *args, jsval *rval) {
    jsval *arg_list;
    SV *val;
    AV *av;
    int arg_count, i;
    JSFunction *js_fun;
    
    /* Clear $@ */
    sv_setsv(ERRSV, &PL_sv_undef);
    
    av = (AV *) SvRV(args);
    arg_count = av_len(av);

    Newz(1, arg_list, arg_count + 1, jsval);
    if (arg_list == NULL) {
        croak("Failed to allocate memory for argument list");
    }

    for (i = 0; i <= arg_count; i++) {
        val = *av_fetch(av, i, 0);

        if (PJS_ConvertPerlToJSType(PJS_GetJSContext(pcx), NULL, JS_GetGlobalObject(PJS_GetJSContext(pcx)), val, &(arg_list[i])) == JS_FALSE) {
            Safefree(arg_list);
            croak("Can't convert argument number %d to jsval", i);
        }
    }

    js_fun = JS_ValueToFunction(PJS_GetJSContext(pcx), func);
    if (JS_CallFunction(PJS_GetJSContext(pcx), JS_GetGlobalObject(PJS_GetJSContext(pcx)), js_fun,
                        arg_count + 1, (jsval *) arg_list, (jsval *) rval) == JS_FALSE) {
        PJS_report_exception(pcx);
        return JS_FALSE;
    }

    return JS_IsExceptionPending(PJS_GetJSContext(pcx)) ? JS_FALSE : JS_TRUE;
}

JSBool perl_call_jsfunc(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval) {
    jsval tmp;
    SV *code;
    JSFunction *jsfun = PJS_FUNC_SELF;
    JSObject *funobj = JS_GetFunctionObject(jsfun);

    if (JS_GetProperty(cx, funobj, "_perl_func", &tmp) == JS_FALSE) {
        croak("Can't get coderef\n");
    }
    
    code = JSVAL_TO_PRIVATE(tmp);
    if (perl_call_sv_with_jsvals(cx, obj, code, NULL, argc, argv, rval) < 0 || JS_IsExceptionPending(cx)) {
        return JS_FALSE;
    }
    
    return JS_TRUE;   
}
