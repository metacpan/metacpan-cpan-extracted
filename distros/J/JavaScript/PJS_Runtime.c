#include "JavaScript.h"

JSTrapStatus PJS_trap_handler(JSContext *cx, JSScript *script, jsbytecode *pc, jsval *rval, void *closure) {
    PJS_Runtime *rt = (PJS_Runtime *) closure;
    PJS_TrapHandler *handler = rt->trap_handlers;
    JSTrapStatus status = JSTRAP_CONTINUE;

    while (handler && status == JSTRAP_CONTINUE) {
        status = (handler->handler)(cx, script, pc, rval, handler->data);
        handler = handler->_next;
    }
    
    return status;
}

/* Perl callback interrupt handler */
JSTrapStatus PJS_perl_trap_handler(JSContext *cx, JSScript *script, jsbytecode *pc, jsval *rval, void *closure) {
    dSP;
    PJS_Context *pcx = PJS_GET_CONTEXT(cx);
    SV *handler = (SV *) closure;
    SV *scx, *rv;
    int rc;
    JSTrapStatus status = JSTRAP_CONTINUE;

    if (handler) {
        ENTER ;
        SAVETMPS ;
        PUSHMARK(SP) ;

        scx = sv_newmortal();
        sv_setref_pv(scx, Nullch, (void*) pcx);
        
        XPUSHs(scx);
        XPUSHs(newSViv(*pc));
        
        PUTBACK;
        
        rc = perl_call_sv(SvRV(handler), G_SCALAR | G_EVAL);

        SPAGAIN;

        rv = POPs;

        if (!SvTRUE(rv)) {
            status = JSTRAP_ERROR;
        }

        if (SvTRUE(ERRSV)) {
            sv_setsv(ERRSV, &PL_sv_undef);
        }
        
        PUTBACK;

        FREETMPS;
        LEAVE;
    }
   
    return status;
}

/* Create a runtime */
#if defined(JS_C_STRINGS_ARE_UTF8) && JS_VERSION >= 180
static bool initialized_utf8_cstrings = FALSE;
#endif

PJS_Runtime *
PJS_CreateRuntime(int maxbytes) {
    PJS_Runtime *runtime;
    
    Newz(1, runtime, 1, PJS_Runtime);
    if(runtime == NULL) {
        croak("Failed to allocate memoery for PJS_Runtime");
    }
    
#if defined(JS_C_STRINGS_ARE_UTF8) && JS_VERSION >= 180
    if (initialized_utf8_cstrings == FALSE) {
        JS_SetCStringsAreUTF8();
        initialized_utf8_cstrings = TRUE;
    }
#endif
    
    runtime->rt = JS_NewRuntime(maxbytes);
    if(runtime->rt == NULL) {
        Safefree(runtime);
        croak("Failed to create runtime");
    }
        
    return runtime;
}

/* Free the runtime and any memory allocated by it */
void
PJS_DestroyRuntime(PJS_Runtime *runtime) {
    if (runtime != NULL) {
        JS_DestroyRuntime(runtime->rt);
        Safefree(runtime);
    }
}

/* Adds a trap handler */
void
PJS_AddTrapHandler(PJS_Runtime *inRuntime, PJS_TrapHandler *trapHandler) {
    PJS_TrapHandler *baseHandler = inRuntime->trap_handlers;

    trapHandler->_next = NULL;
    if (inRuntime->trap_handlers) {
        baseHandler = inRuntime->trap_handlers;
        while(baseHandler->_next != NULL) {
            baseHandler = baseHandler->_next;
        }
        baseHandler->_next = trapHandler;
    }
    else {
        inRuntime->trap_handlers = trapHandler;
        JS_SetInterrupt(inRuntime->rt, PJS_trap_handler, (void *) inRuntime);            
    }
}

/* Removes a trap handler */
void
PJS_RemoveTrapHandler(PJS_Runtime *fromRuntime, PJS_TrapHandler *trapHandler) {
    PJS_TrapHandler *current;
    JSTrapHandler old_handler;
    void *ptr;

    if (fromRuntime->trap_handlers == trapHandler) {
        fromRuntime->trap_handlers = trapHandler->_next;
    }
    else {
        /* seek and destroy */
        current = fromRuntime->trap_handlers;
        while (current->_next != NULL && current->_next != trapHandler) {
            current = current->_next;
        }
        if (current->_next == trapHandler) {
            current->_next = current->_next->_next;
        }
    }
    /* Removed last handler, disable trap */
    if (fromRuntime->trap_handlers == NULL) {
        JS_ClearInterrupt(fromRuntime->rt, &old_handler, &ptr);
    }
}
