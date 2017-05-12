#include "JS.h"

GV *PJS_Context_SV = NULL;
GV *PJS_This = NULL;

JSRuntime *plGRuntime = NULL;
JSPrincipals *gMyPri = NULL;

#ifndef PJS_CONTEXT_IN_PERL
/* Global class, does nothing */
static JSClass global_class = {
    "global", JSCLASS_GLOBAL_FLAGS,
    JS_PropertyStub,  JS_PropertyStub,  JS_PropertyStub,  PJS_SetterPropStub,
    JS_EnumerateStub, JS_ResolveStub,   JS_ConvertStub,   JS_FinalizeStub,
    JSCLASS_NO_OPTIONAL_MEMBERS
};
#endif

static void
perl_class_finalize (
    JSContext *cx,
    JSObject *object
) {
    dTHX;
    PJS_Context *pcx;
#ifdef PJS_CONTEXT_IN_PERL
    pcx = JS_GetPrivate(cx, object);
#else
    pcx = PJS_GET_CONTEXT(cx);
#endif
    sv_free((SV *)pcx->class_by_name);
    pcx->class_by_name = NULL;
    JS_SetReservedSlot(cx, object, 0, JSVAL_VOID);
    pcx->pvisitors = NULL;
    JS_SetReservedSlot(cx, object, 1, JSVAL_VOID);
    pcx->flags = NULL;
#ifdef PJS_CONTEXT_IN_PERL
    {
	SV *method = newSVpvf("JSPL::Context::_destroy(%ld)", (IV)pcx); 
	eval_sv(method, 1);
	sv_free(method);
	assert(pcx->cx==NULL);
    }
#else
    JS_SetContextPrivate(cx, NULL);
#endif
    PJS_DEBUG("JSPL Context finalized\n");
}

JSClass perl_class = {
    "perl", 
#ifdef PJS_CONTEXT_IN_PERL
    JSCLASS_HAS_PRIVATE |
#endif
    JSCLASS_HAS_RESERVED_SLOTS(2),
    JS_PropertyStub,  JS_PropertyStub,  JS_PropertyStub,  PJS_SetterPropStub,
    JS_EnumerateStub, JS_ResolveStub,   JS_ConvertStub,   perl_class_finalize,
    JSCLASS_NO_OPTIONAL_MEMBERS
};

JSBool
PJS_InitPerlClasses(pTHX_ PJS_Context *pcx, JSObject *gobj)
{
    JSObject *perl;
    JSContext *cx = PJS_getJScx(pcx);

    perl = JS_NewObject(cx, &perl_class, NULL, gobj);
    if(perl && JS_DefineProperty(cx, gobj, "__PERL__",
                      OBJECT_TO_JSVAL(perl), NULL, NULL, JSPROP_PERMANENT) &&
       (pcx->pvisitors = JS_NewObject(cx, NULL, NULL, perl)) &&
       JS_SetReservedSlot(cx, perl, 0, OBJECT_TO_JSVAL(pcx->pvisitors)) &&
       (pcx->flags = JS_NewObject(cx, NULL,  NULL, perl)) &&
       JS_SetReservedSlot(cx, perl, 1, OBJECT_TO_JSVAL(pcx->flags))
    ) {
#ifdef PJS_CONTEXT_IN_PERL
	JS_SetPrivate(cx, perl, (void *)pcx);
#else
	JS_SetContextPrivate(cx, (void *)pcx);
#endif
	pcx->jsvisitors = newHV();
	pcx->class_by_name = newHV();
	if(PJS_InitPerlArrayClass(aTHX_ cx, gobj) &&
	   PJS_InitPerlHashClass(aTHX_ cx, gobj) &&
	   PJS_InitPerlScalarClass(aTHX_ cx, gobj) &&
           PJS_InitPerlSubClass(aTHX_ cx, gobj)) {
	    return JS_TRUE;
	}
    }
    return JS_FALSE;
}

#ifdef PJS_CONTEXT_IN_PERL
PJS_Context *
PJS_GetContext(JSContext *cx)
{
    JSObject *tobj;
    jsval temp;
    if((tobj = JS_GetGlobalObject(cx))
       && JS_LookupProperty(cx, tobj, "__PERL__", &temp)
       && JSVAL_IS_OBJECT(temp)
       && (tobj = JSVAL_TO_OBJECT(temp))
       && PJS_GET_CLASS(cx, tobj) == &perl_class) {
	return (PJS_Context *)JS_GetPrivate(cx, tobj);
    }
    return NULL;
}
#endif

static void 
js_error_reporter(
    JSContext *cx,
    const char *message,
    JSErrorReport *report
) {
    dTHX;
    if(report->flags & JSREPORT_WARNING) 
	warn(message);
    else {
	// warn("================= Uncaught error: %s", message);
	sv_setsv(ERRSV, newSVpv(message,0));
    }
}

/*
  Create PJS_Context structure
*/
PJS_Context *
PJS_CreateContext(pTHX_ PJS_Runtime *rt, SV *ref, JSContext *imported) {
    PJS_Context *pcx;
    JSObject *gobj;

    Newxz(pcx, 1, PJS_Context);
    if(!pcx)
        croak("Failed to allocate memory for PJS_Context");
        
#ifdef PJS_CONTEXT_IN_PERL
    if(!imported)
	croak("JSPL::Context::create: need a JSContext to wrap!\n");

    pcx->cx = imported;
#else
    if(imported)
	croak("JSPL::Context::create: can't import a context!\n");
    pcx->cx = JS_NewContext(rt->rt, 8192);

    if(!pcx->cx) {
        Safefree(pcx);
        croak("Failed to create JSContext");
    }
    PJS_BeginRequest(pcx->cx);
#endif
#ifdef PJS_CONTEXT_IN_PERL
    gobj = JS_GetGlobalObject(pcx->cx);
#else
    JS_SetOptions(pcx->cx, JSOPTION_DONT_REPORT_UNCAUGHT);
    JS_SetErrorReporter(pcx->cx, &js_error_reporter);

#if JS_VERSION == 185
    gobj = JS_NewCompartmentAndGlobalObject(pcx->cx, &global_class, NULL);
#else
    gobj = JS_NewObject(pcx->cx, &global_class, NULL, NULL);
#endif
    if(!gobj || !JS_InitStandardClasses(pcx->cx, gobj)) {
        PJS_DestroyContext(aTHX_ pcx);
        croak("Standard classes not loaded properly.");
    }
#endif /* PJS_CONTEXT_IN_PERL */

    pcx->rt = rt;
    if(ref && SvOK(ref))
	pcx->rrt = SvREFCNT_inc_simple_NN(ref);
    pcx->svconv = 0;

    if(PJS_InitPerlClasses(aTHX_ pcx, gobj)) {
	return pcx;
    }
    else {
        PJS_DestroyContext(aTHX_ pcx);
        croak("Perl classes not loaded properly.");        
    }
    return NULL; /* Not really reached */
}

static void
PJS_unmagic(
    pTHX_
    PJS_Context *pcx,
    SV *sv
) {
    MAGIC* mg;
    MAGIC** mgp;

    assert(SvMAGIC(sv));
#if PERL_VERSION > 9
    mgp = &(((XPVMG*) SvANY(sv))->xmg_u.xmg_magic);
#else
    mgp = &(SvMAGIC(sv));
#endif
    jsv_mg *jsvis;
    for(mg = *mgp; mg; mg = *mgp) {
	if(mg->mg_type == PERL_MAGIC_jsvis &&
	   mg->mg_private == 0x4a53 &&
	   (jsvis = (jsv_mg *)mg->mg_ptr) &&
	   jsvis->pcx == pcx
	) { // Found my magic
	    *mgp = mg->mg_moremagic;
	    Safefree(jsvis); // Free struct;
	    Safefree(mg);
	    goto exit;
	}
	mgp = &mg->mg_moremagic;
    }
    exit:
    if (!SvMAGIC(sv)) {
        SvMAGICAL_off(sv);
        SvFLAGS(sv) |= (SvFLAGS(sv) & (SVp_IOK|SVp_NOK|SVp_POK)) >> PRIVSHIFT;
        SvMAGIC_set(sv, NULL);
    }
}

/*
  Free memory occupied by PJS_Context structure
*/
void PJS_DestroyContext(pTHX_ PJS_Context *pcx) {
    SV *rrt = NULL;
    if(pcx->cx && pcx->rt && pcx->rt->rt) {
	JSContext *cx = pcx->cx; 
	HV *hv = pcx->jsvisitors;
	I32 len = hv_iterinit(hv);
	if(len) {
	    /* As SM don't warrant us that every object will be finalized in 
	     * JS_DestroyContext, we can't depend of UnrootJSVis for magic clearing
	     */
	    SV *val;
	    char *key;
	    while( (val = hv_iternextsv(hv, &key, &len)) ) {
		JSObject *shell = (JSObject *)SvIVX(val);
		SV *ref = (SV *)JS_GetPrivate(cx, shell);
		if(ref && SvROK(ref)) PJS_unmagic(aTHX_ pcx, SvRV(ref));
		// TODO: Assert needed?
	    }
	}
#ifndef PJS_CONTEXT_IN_PERL
	JS_SetErrorReporter(cx, NULL);
	JS_ClearScope(cx, JS_GetGlobalObject(cx));
	JS_GC(cx);
	pcx->cx = NULL; /* Mark global clean */
	PJS_EndRequest(cx);
	JS_DestroyContext(cx);
#else
	pcx->cx = NULL;
#endif
	len = hv_iterinit(hv);
	// warn("Orphan jsvisitors: %d\n", len);
	sv_free((SV *)hv);
	rrt = pcx->rrt;
    } else croak("PJS_Assert: Without runtime at context destruction\n");
    Safefree(pcx);
    pcx = NULL;
    if(rrt) sv_free(rrt); // Liberate runtime reference
}

JSBool
PJS_rootObject(
    PJS_Context *pcx,
    JSObject *object
) {
    char hkey[32];

    (void)snprintf(hkey, 32, "%p", (void *)object);
    return JS_DefineProperty(pcx->cx, pcx->pvisitors, hkey,
	OBJECT_TO_JSVAL(object), NULL, NULL, 0
    );
}

static int jsv_free(pTHX_ SV *sv, MAGIC *mg) {
    jsv_mg *jsvis = (jsv_mg *)mg->mg_ptr;
    assert(mg->mg_private == 0x4a53);
    Safefree(jsvis);
    return 1;
}

static MGVTBL vtbl_jsvt = { 0, 0, 0, 0, jsv_free };

JSObject *
PJS_CreateJSVis(
    pTHX_
    JSContext *cx,
    JSObject *object,
    SV *ref
) {
    jsv_mg *jsvis;
    MAGIC *mg;
    char hkey[32];

    if(!object) return NULL;
    Newz(1, jsvis, 1, jsv_mg);
    if(jsvis) {
	SV *sv = SvRV(ref);
#if 0	/* Will be needed for Subs prototype chain mangling */
	JSObject *stash = NULL;
	HV *st = (SvTYPE(sv) == SVt_PVCV) ? CvSTASH(sv) : SvSTASH(sv);
	char *package = st ? HvNAME(st) : NULL;
	if(package) {
	    stash = PJS_GetPackageObject(cx, package);
	    warn("ST: %s %d\n", package, SvTYPE(sv));
	}
#endif
	snprintf(hkey, 32, "%p", (void *)sv);
	jsvis->pcx = PJS_GET_CONTEXT(cx);
	jsvis->object = object;
	if(hv_store(jsvis->pcx->jsvisitors, hkey, strlen(hkey),
		    newSViv((IV)object), 0))
	{
	    sv_free((SV *)JS_GetPrivate(cx, object)); // Don't leak
	    mg = sv_magicext(sv, NULL, PERL_MAGIC_jsvis,
		             &vtbl_jsvt, (char *)jsvis, 0);
	    mg->mg_private = 0x4a53;
#ifdef PJSDEBUG
	    warn("New jsvisitor %s: %s RC %d,%d\n",
		 hkey, SvPV_nolen(ref), SvREFCNT(ref), SvREFCNT(sv)
	    );
#endif
	    /* The shell object takes ownership of ref */
	    JS_SetPrivate(cx, object, (void *)SvREFCNT_inc_simple_NN(ref));
	    return object;
	} 
	else {
	    JS_ReportError(cx, "Can't register a JSVis");
	    Safefree(jsvis);
	}
    }
    else JS_ReportOutOfMemory(cx);
    return NULL;
}

void
PJS_unrootJSVis(
    JSContext *cx,
    JSObject *object
) {
    dTHX;
    SV *ref = (SV *)JS_GetPrivate(cx, object);
    if(ref && SvOK(ref) && SvROK(ref)) {
	char hkey[32];
	PJS_Context *pcx = PJS_GET_CONTEXT(cx); // At Context destruction can be NULL
	(void)snprintf(hkey, 32, "%p", (void *)SvRV(ref));
	if(pcx && SvMAGICAL(SvRV(ref))) PJS_unmagic(aTHX_ pcx, SvRV(ref));
	if(pcx && pcx->jsvisitors) {
	    (void)hv_delete(pcx->jsvisitors, hkey, strlen(hkey), G_DISCARD);
	}
	sv_free(ref);
    }
    else croak("PJS_Assert: Not a REF in finalize for %s\n",
	       PJS_GET_CLASS(cx, object)->name);
}

JSObject *
PJS_IsPerlVisitor(
    pTHX_
    PJS_Context *pcx,
    SV *sv
) {
    char hkey[32];
    SV **oguardp;
    snprintf(hkey, 32, "%p", (void *)sv);
    PJS_DEBUG1("Check Visitor %s\n", hkey);
    oguardp = hv_fetch(pcx->jsvisitors, hkey, strlen(hkey), 0);
    if(oguardp) {
	assert(SvIOK(*oguardp));
	return (JSObject *)SvIVX(*oguardp);
    }
    else return NULL;
}

JSBool
PJS_setFlag(
    PJS_Context *pcx,
    const char *flag,
    JSBool val
) {
    //dTHX;
    JSContext *cx = PJS_getJScx(pcx);
    JSObject *flags = pcx->flags;
    if(!cx || !flags) croak("Flags missing(S)!\n");
    return JS_DefineProperty(cx, flags, flag,
	                     val ? JSVAL_TRUE : JSVAL_FALSE,
		             NULL, NULL,  0);
}

JSBool
PJS_getFlag(
    PJS_Context *pcx,
    const char *flag
) {
    //dTHX;
    jsval val;
    JSContext *cx = PJS_getJScx(pcx);
    JSObject *flags = pcx->flags;
    if(!cx || !flags) warn("Flags missing(G)!\n");
    JS_LookupProperty(PJS_getJScx(pcx), flags, flag, &val);
    return !JSVAL_IS_VOID(val) && JSVAL_TO_BOOLEAN(val);
}

#ifdef JS_HAS_BRANCH_HANDLER
/* Called by context when a branch occurs */
JSBool PJS_branch_handler(
    JSContext *cx,
    JSScript *script
) {
    dTHX;
    PJS_Context *pcx;
    SV *rv;
    JSBool status = JS_TRUE;
    
    pcx = PJS_GET_CONTEXT(cx);

    if(pcx && pcx->branch_handler) {
	dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        sv_setiv(save_scalar(PJS_Context_SV), PTR2IV(pcx));
        
        (void)call_sv(SvRV(pcx->branch_handler), G_SCALAR | G_EVAL);

        SPAGAIN;
        rv = POPs;
        if(!SvTRUE(rv))
            status = JS_FALSE;

        // if(SvTRUE(ERRSV)) {
        //     status = JS_FALSE;
        // }
        
        PUTBACK;
        FREETMPS; LEAVE;
    }
    return status;
}
#endif
