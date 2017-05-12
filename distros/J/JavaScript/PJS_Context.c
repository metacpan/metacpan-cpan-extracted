#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "JavaScript_Env.h"

#include "PJS_Types.h"
#include "PJS_Common.h"
#include "PJS_Function.h"
#include "PJS_Context.h"
#include "PJS_Runtime.h"
#include "PJS_Class.h"
#include "PJS_PerlArray.h"
#include "PJS_PerlHash.h"
#include "PJS_PerlSub.h"

/* Global class, does nothing */
static JSClass global_class = {
    "global", 0,
    JS_PropertyStub,  JS_PropertyStub,  JS_PropertyStub,  JS_PropertyStub,
    JS_EnumerateStub, JS_ResolveStub,   JS_ConvertStub,   JS_FinalizeStub,
    JSCLASS_NO_OPTIONAL_MEMBERS
};

PJS_Function * PJS_GetFunctionByName(PJS_Context *cx, const char *name) {
    PJS_Function *func = NULL;
    SV **sv;
    IV tmp;

    sv = hv_fetch(cx->function_by_name, name, strlen(name), 0);
    if (sv == NULL) {
        return NULL;
    }
    tmp = SvIV((SV *) SvRV(*sv));
    func = INT2PTR(PJS_Function *, tmp);
        
    return func;
}
    
PJS_Class * 
PJS_GetClassByName(PJS_Context *cx, const char *name) {
    PJS_Class *cls = NULL;
    SV        **sv;
    IV        tmp;

    sv = hv_fetch(cx->class_by_name, name, strlen(name), 0);
    if (sv == NULL) {
        return NULL;
    }
    tmp = SvIV((SV *) SvRV(*sv));
    cls = INT2PTR(PJS_Class *, tmp);
        
    return cls;
}

PJS_Class *
PJS_GetClassByPackage(PJS_Context *cx, const char *pkg) {
    PJS_Class *cls = NULL;
    SV        **sv;
    IV        tmp;
    
    sv = hv_fetch(cx->class_by_package, pkg, strlen(pkg), 0);
    if (sv == NULL) {
        return NULL;
    }
    tmp = SvIV((SV *) SvRV(*sv));
    cls = INT2PTR(PJS_Class *, tmp);
    
    return cls;
}

/*
  Create PJS_Context structure
*/
PJS_Context * PJS_CreateContext(PJS_Runtime *rt) {
    PJS_Context *pcx;
    JSObject *obj;

    Newz(1, pcx, 1, PJS_Context);
    if (pcx == NULL) {
        croak("Failed to allocate memory for PJS_Context");
    }
    
    /* 
        The 'stack size' param here isn't actually the stack size, it's
        the "chunk size of the stack pool--an obscure memory management
        tuning knob"
        
        http://groups.google.com/group/mozilla.dev.tech.js-engine/browse_thread/thread/be9f404b623acf39
    */
    
    pcx->cx = JS_NewContext(rt->rt, 8192);

    if(pcx->cx == NULL) {
        Safefree(pcx);
        croak("Failed to create JSContext");
    }

    JS_SetOptions(pcx->cx, JSOPTION_DONT_REPORT_UNCAUGHT);

    obj = JS_NewObject(pcx->cx, &global_class, NULL, NULL);
    if (JS_InitStandardClasses(pcx->cx, obj) == JS_FALSE) {
        PJS_DestroyContext(pcx);
        croak("Standard classes not loaded properly.");
    }
    
    pcx->function_by_name = newHV();
    pcx->class_by_name = newHV();
    pcx->class_by_package = newHV();
    
    if (PJS_InitPerlArrayClass(pcx, obj) == JS_FALSE) {
        PJS_DestroyContext(pcx);
        croak("Perl classes not loaded properly.");        
    }

    if (PJS_InitPerlHashClass(pcx, obj) == JS_FALSE) {
        PJS_DestroyContext(pcx);
        croak("Perl classes not loaded properly.");        
    }

    if (PJS_InitPerlSubClass(pcx, obj) == JS_FALSE) {
        PJS_DestroyContext(pcx);
        croak("Perl class 'PerlSub' not loaded properly.");        
    }

    pcx->rt = rt;
    /* Add context to context list */
    pcx->next = rt->list;
    rt->list = pcx;

    JS_SetContextPrivate(pcx->cx, (void *) pcx);

    return pcx;
}

/*
  Free memory occupied by PJS_Context structure
*/
void PJS_DestroyContext(PJS_Context *pcx) {
    if (pcx == NULL) {
        return;
    }

    if (pcx->function_by_name) {
        SvREFCNT_dec(pcx->function_by_name);
        pcx->function_by_name = NULL;
    }
        
    if (pcx->class_by_name) {
        SvREFCNT_dec(pcx->class_by_name);
        pcx->class_by_name = NULL;
    }
    
    if (pcx->class_by_package) {
        SvREFCNT_dec(pcx->class_by_package);
        pcx->class_by_package = NULL;   
    }
    
    /* Destory context */
    if (pcx->cx) {
        JS_DestroyContext(pcx->cx);
        pcx->cx = NULL;
    }

    Safefree(pcx);
}

PJS_Function *
PJS_DefineFunction(PJS_Context *inContext, const char *functionName, SV *perlCallback) {
    PJS_Function *function;
    JSContext    *js_context = inContext->cx;
    SV *sv;
    
    if (PJS_GetFunctionByName(inContext, functionName) != NULL) {
        warn("Function named '%s' is already defined in the context");
        return NULL;
    }
    
    if ((function = PJS_CreateFunction(functionName, perlCallback)) == NULL) {
        return NULL;
    }
    
    /* Add the function to the javascript context */
    if (JS_DefineFunction(js_context, JS_GetGlobalObject(js_context), functionName, PJS_invoke_perl_function, 0, 0) == JS_FALSE) {
        warn("Failed to define function");
        PJS_DestroyFunction(function);
        return NULL;
    }

    sv = newSV(0);
	sv_setref_pv(sv, "JavaScript::PerlFunction", (void*) function);
	
    if (functionName != NULL) {
        SvREFCNT_inc(sv);
        hv_store(inContext->function_by_name, functionName, strlen(functionName), sv, 0);
    }
    
    return function;
}

/* Called by context when a branch occurs */
JSBool PJS_branch_handler(JSContext *cx, JSScript *script) {
    dSP;

    PJS_Context *pcx;
    SV *rv;
    I32 rc = 0;
    JSBool status = JS_TRUE;
    
    pcx = PJS_GET_CONTEXT(cx);

    if (pcx != NULL && pcx->branch_handler) {
        ENTER ;
        SAVETMPS ;

        PUSHMARK(SP);
        
        rc = perl_call_sv(SvRV(pcx->branch_handler), G_SCALAR | G_EVAL);

        SPAGAIN;

        rv = POPs;

        if (!SvTRUE(rv)) {
            status = JS_FALSE;
        }

        if (SvTRUE(ERRSV)) {
            sv_setsv(ERRSV, &PL_sv_undef);
            status = JS_FALSE;
        }
        
        PUTBACK;

        FREETMPS;
        LEAVE;
    }

    return status;
}

/*JSContext *
PJS_GetJSContext(PJS_Context *fromContext) {
    if (fromContext != NULL) {
        return fromContext->cx;
    }
    
    return NULL;
}*/