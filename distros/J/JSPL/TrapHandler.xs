#include "JS.h"

/*!
    @struct PJS_TrapHandler
    @abstract A structure that encapsulates a closure.
    @field callback an SV reference to a CV
    @field data an SV, any
*/

typedef struct PJS_TrapHandler PJS_TrapHandler;

struct PJS_TrapHandler {
    SV	*callback;
    SV  *data;
};

PJS_TYPEDEF(TrapHandler);

static JSTrapStatus
PJS_trap_handler(
    JSContext *cx,
    JSScript *script,
    jsbytecode *pc,
    jsval *rval,
    void *closure 
) {
    dTHX;
    JSTrapStatus status = JSTRAP_CONTINUE;

    PJS_Runtime *runtime = (PJS_Runtime *)closure;
    IV tmp = SvIV( (SV*)SvRV( runtime->trap_handler) );
    PJS_TrapHandler *handler = INT2PTR(PJS_TrapHandler *, tmp);

    if(handler && handler->callback) {
	dSP;
	PJS_Context *pcx = PJS_GET_CONTEXT(cx);
	SV *scx, *rv;
	
	ENTER; SAVETMPS;
	PUSHMARK(SP) ;

	scx = sv_newmortal();
	sv_setref_pv(scx, Nullch, (void*) pcx);
	
	XPUSHs(scx);
	XPUSHs(sv_2mortal(newSViv(*pc)));
	XPUSHs(sv_mortalcopy(handler->data));
	
	PUTBACK;
	
	call_sv(handler->callback, G_SCALAR | G_EVAL);

	SPAGAIN;

	rv = POPs;

	if(!SvTRUE(rv)) status = JSTRAP_ERROR;

	if(SvTRUE(ERRSV)) {
	    sv_setsv(ERRSV, &PL_sv_undef);
	}
	
	PUTBACK;
	FREETMPS; LEAVE;
    }
    return status;
}

MODULE = JSPL::TrapHandler    PACKAGE = JSPL::TrapHandler
PROTOTYPES: DISABLE

JSPL::TrapHandler
new(self, cb, data = &PL_sv_undef)
    SV *self;
    CV *cb;
    SV *data;
    CODE:
	PERL_UNUSED_VAR(self); /* -W */
	Newxz(RETVAL, 1, PJS_TrapHandler);
	if(!RETVAL) XSRETURN_UNDEF;
	RETVAL->callback = newRV_inc((SV*)cb);
	RETVAL->data = SvREFCNT_inc_simple_NN(data);
    OUTPUT:
	RETVAL
        
void
DESTROY(handler)
    JSPL::TrapHandler handler;
    CODE:
	sv_free((SV *)handler->data);
	sv_free((SV *)handler->callback);
	Safefree(handler);


MODULE = JSPL::TrapHandler    PACKAGE = JSPL::RawRT	PREFIX = jsr_

void
jsr_add_interrupt_handler(runtime, handler)
    JSPL::RawRT runtime
    JSPL::TrapHandler handler
    CODE:
	PERL_UNUSED_VAR(handler); /* -W */
	if(runtime->trap_handler && SvOK(runtime->trap_handler))
	    sv_free(runtime->trap_handler);
	runtime->trap_handler = SvREFCNT_inc(ST(1));
	JS_SetInterrupt(runtime->rt, PJS_trap_handler, (void *)runtime);

void
jsr_remove_interrupt_handler(runtime)
    JSPL::RawRT runtime;
    CODE:
	if(runtime->trap_handler && SvOK(runtime->trap_handler))
	    SvREFCNT_dec(runtime->trap_handler);
	JS_SetInterrupt(runtime->rt, NULL, (void *)runtime);
	runtime->trap_handler = NULL;

