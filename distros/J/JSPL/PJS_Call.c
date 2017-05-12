#include "JS.h"

PJS_EXTERN SV *
PJS_CallPerlMethod(
    pTHX_
    JSContext *cx,
    const char *method,
    ...
) {
    dSP;
    va_list ap;
    SV *arg, *ret;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    
    sv_setiv(save_scalar(PJS_Context_SV), PTR2IV(PJS_GET_CONTEXT(cx)));

    va_start(ap, method);
    while( (arg = va_arg(ap, SV*)) ) XPUSHs(arg);
    va_end(ap);
    PUTBACK;

    call_method(method, G_SCALAR | G_EVAL);
    ret = newSVsv(*PL_stack_sp--);

    FREETMPS;
    LEAVE;

    if (SvTRUE(ERRSV)) {
	jsval rval;
	SV* cp = newSVsv(ERRSV);
	if(!PJS_ReflectPerl2JS(aTHX_ cx, NULL, cp, &rval)) 
	    croak("Can't convert perl error into JSVAL");
	JS_SetPendingException(cx, rval);
	sv_setsv(ERRSV, &PL_sv_undef);            
	sv_free(ret); // Don't want leaks
	sv_free(cp);
	return NULL;
    }

    return sv_2mortal(ret);
}

PJS_EXTERN JSBool
PJS_Call_sv_with_jsvals_rsv(
    pTHX_
    JSContext *cx,
    JSObject *obj,
    SV *code,
    SV *caller, /* Will be disposed inside */
    uintN argc,
    jsval *argv,
    SV **rsv,
    I32 flag
) {
    dSP;
    JSBool ok = JS_TRUE;
    uintN arg;
    I32 rcount = caller ? 1 : 0;
    
    if(SvROK(code) && SvTYPE(SvRV(code)) == SVt_PVCV) {
        ENTER; SAVETMPS;
        PUSHMARK(SP) ;

	sv_setiv(save_scalar(PJS_Context_SV), PTR2IV(PJS_GET_CONTEXT(cx)));
	
	EXTEND(SP, argc + rcount);
	PUTBACK;
        
	/* From here we are working with the global stack,
	 * a) at PUSH time we can fail, so we need to abort the call
	 * b) Want to avoid copying local <=> global SP at every single PUSH
	 *
	 * Before 'call_sv', rcount is the number of SVs pushed so far
	 */
        if(caller) *++PL_stack_sp = sv_2mortal(caller);

	if(argv && !(flag & G_NOARGS)) {
	    /* HACK: We use G_NOARGS as a guard against use argv[-1] to get This.
	     * Needed for the use in PJS_invoke_perl_property_setter where given
	     * argc is faked
	     */
	    SV *This;
	    ok = PJS_ReflectJS2Perl(aTHX_ cx, argv[-1], &This, 0);
	    if(ok) sv_setsv(save_scalar(PJS_This), sv_2mortal(This));
	    else goto forget;
	}
	else flag &= ~G_NOARGS;

        for(arg = 0; arg < argc; arg++) {
            SV *sv;
            ok = PJS_ReflectJS2Perl(aTHX_ cx, argv[arg], &sv, 1);
            if(!ok) {
		rcount += arg;
                goto forget;
	    }
	    *++PL_stack_sp = sv_2mortal(sv);
        }
        
        rcount = call_sv(code, flag | G_EVAL);

	if(rsv) {
	    if(flag == G_SCALAR || rcount == 1)
		*rsv = SvREFCNT_inc_simple_NN(*PL_stack_sp);
	    else
		*rsv = newRV((SV *)av_make(rcount, PL_stack_sp-rcount+1));

	    SAVEMORTALIZESV(*rsv);
	}

	forget:
	PL_stack_sp -= rcount;
        FREETMPS; LEAVE;

        if(ok && SvTRUE(ERRSV)) {
            jsval rval;
            SV* cp = newSVsv(ERRSV);
            if(!PJS_ReflectPerl2JS(aTHX_ cx, obj, cp, &rval))
		croak("Can't convert perl error into JSVAL");
	    JS_SetPendingException(cx, rval);
	    sv_setsv(ERRSV, &PL_sv_undef);
	    sv_free(cp);
	    ok = JS_FALSE;
        }
    }
    else croak("Not a coderef");
    return ok;
}

PJS_EXTERN JSBool
PJS_Call_sv_with_jsvals(
    pTHX_
    JSContext *cx,
    JSObject *obj,
    SV *code,
    SV *caller,
    uintN argc,
    jsval *argv,
    jsval *rval,
    I32 flag
) {
    SV *rsv;
    ENTER; SAVETMPS;
    JSBool ok = PJS_Call_sv_with_jsvals_rsv(aTHX_ cx, obj, code, caller, argc, argv,
                                             rval ? &rsv : NULL, flag);
    
    if(rval && ok) ok = PJS_ReflectPerl2JS(aTHX_ cx, obj, rsv, rval);
    FREETMPS; LEAVE;
    return ok;
}

PJS_EXTERN JSBool
PJS_Call_js_function(
    pTHX_
    JSContext *cx,
    JSObject *gobj,
    jsval func,
    AV *av,
    jsval *rval
) {
    jsval *arg_list;
    SV *val;
    int arg_count, i;
    JSBool res;
    
    arg_count = av_len(av);

    Newz(1, arg_list, arg_count + 1, jsval);
    if(!arg_list) {
	JS_ReportOutOfMemory(cx);
	return JS_FALSE;
    }

    for(i = 0; i <= arg_count; i++) {
        val = *av_fetch(av, i, 0);

        if (!PJS_ReflectPerl2JS(aTHX_ cx, gobj, val, &(arg_list[i]))) {
            Safefree(arg_list);
            croak("Can't convert argument number %d to jsval", i);
        }
    }
    res = JS_CallFunctionValue(cx, gobj, func, i, arg_list, rval);
    Safefree(arg_list);
    return res;
}
