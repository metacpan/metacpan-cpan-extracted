#include "XSUB.h"

#include "JavaScript_Env.h"
#include "PJS_Function.h"
#include "PJS_Common.h"
#include "PJS_Context.h"

void PJS_free_JSFunctionSpec(JSFunctionSpec *fs_list) {
    JSFunctionSpec *fs;
    
    if (fs_list == NULL) {
        return;
    }

    for (fs = fs_list; fs->name != NULL; fs++) {
        Safefree(fs->name);
    }

    Safefree(fs_list);
}

/* Universal call back for functions */
JSBool PJS_invoke_perl_function(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval) {
    PJS_Function *callback;
    PJS_Context *context;
    JSFunction *fun = PJS_FUNC_SELF;

    if (!(context = PJS_GET_CONTEXT(cx))) {
        croak("Can't get context\n");
    }

    if (!(callback = PJS_GetFunctionByName(context, (const char *) JS_GetFunctionName(fun)))) {
        croak("Couldn't find perl callback");
    }
    
    if (perl_call_sv_with_jsvals(cx, obj, callback->callback, NULL, argc, argv, rval) < 0) {
        return JS_FALSE;
    }

    return JS_TRUE;
}

PJS_Function *
PJS_CreateFunction(const char *functionName, SV *perlCallback) {
    dTHX;
    
    PJS_Function *function = NULL;
            
    /* Allocate memory for a new callback */
    Newz(1, function, 1, PJS_Function);
    if (function == NULL) {
        return NULL;
    }
        
    /* Allocate memory for the native name */
    Newz(1, function->name, strlen(functionName) + 1, char);
    if (function->name == NULL) {
        Safefree(function);
        return NULL;
    }
    Copy(functionName, function->name, strlen(functionName), char);
    
    if (SvTRUE(perlCallback)) {
        function->callback = SvREFCNT_inc(perlCallback);
    }
    
    return function;
}

/*
  Free memory occupied by PJS_Function structure
*/
void PJS_DestroyFunction(PJS_Function *function) {
    dTHX;
    
    if (function == NULL) {
        return;
    }

    if (function->callback != NULL && SvTRUE(function->callback)) {
        SvREFCNT_dec(function->callback);
    }
    
    if (function->name != NULL) {
        Safefree(function->name);
    }

    if (function != NULL) {
        Safefree(function);
    }
}

const char *
PJS_GetFunctionName(PJS_Function *function) {
    if (function != NULL) {
       return (const char *) function->name;
    }
    
    return NULL;
}

const SV *
PJS_GetFunctionTarget(PJS_Function *function) {
    if (function != NULL) {
        return (const SV *) function->callback;
    }
    
    return NULL;
}
