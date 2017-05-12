#include "JS.h"
#include "const-c.inc"

JSObject *
PJS_GetScope(
    pTHX_
    JSContext *cx,
    SV *sv
) {
    jsval val;
    JSObject *newobj = NULL;
    if(!SvOK(sv))
	return JS_GetGlobalObject(cx);

    if(SvROK(sv) && sv_derived_from(sv, PJS_RAW_OBJECT))
	return INT2PTR(JSObject *, SvIV((SV*)SvRV(sv)));

    if(PJS_ReflectPerl2JS(aTHX_ cx, NULL, sv, &val) && JSVAL_IS_OBJECT(val))
	return JSVAL_TO_OBJECT(val);

    if(JS_ValueToObject(cx, val, &newobj) && newobj)
	return newobj;

    croak("%s not a valid value for 'this'", SvPV_nolen(sv));
    return NULL;
}

PJS_Script *
PJS_MakeScript(
    pTHX_
    JSContext *cx,
    JSObject *scope,
    SV *source,
    const char *name
) {
    svtype type = SvTYPE(source);
    PJS_Script *script;

    if(!SvOK(source)) {
	if(strlen(name))
	    script = JS_CompileFile(cx, scope, name);
	else 
	    croak("Must supply a STRING or FileName");
    } else if(SvROK(source) || type == SVt_PVIO || type == SVt_PVGV) {
	FILE *file = PerlIO_findFILE(IoIFP(sv_2io(source)));
	if(!file) croak("FD not opened");
	script = JS_CompileFileHandle(cx, scope, name, file);
#if JS_VERSION < 180
	PerlIO_releaseFILE(IoIFP(sv_2io(source)), file);
#endif
    } else {
	STRLEN len;
	char *src = SvPV(source, len);
	script = gMyPri
	    ? JS_CompileScriptForPrincipals(cx, scope, gMyPri, src, len, name, 1)
	    : JS_CompileScript(cx, scope, src, len, name, 1);
    }
    return script;
}

MODULE = JSPL     PACKAGE = JSPL
PROTOTYPES: DISABLE
INCLUDE: const-xs.inc

char *
js_get_engine_version()
    CODE:
	RETVAL = (char *)JS_GetImplementationVersion();
    OUTPUT:
	RETVAL

IV
get_internal_version()
    CODE:
	RETVAL = (IV)JS_VERSION;
    OUTPUT:
	RETVAL

SV*
does_support_utf8(...)
    CODE:
	PERL_UNUSED_VAR(items); /* -W */
	RETVAL = JS_CStringsAreUTF8() ? &PL_sv_yes : &PL_sv_no;
    OUTPUT:
	RETVAL

SV*
does_support_e4x(...)
    CODE:
	PERL_UNUSED_VAR(items); /* -W */
	RETVAL = JS_HAS_XML_SUPPORT ? &PL_sv_yes : &PL_sv_no;
    OUTPUT:
	RETVAL

SV*
does_support_anonfunfix(...)
    CODE:
	PERL_UNUSED_VAR(items); /* -W */
#ifdef	JSOPTION_ANONFUNFIX
	RETVAL = &PL_sv_yes;
#else
	RETVAL = &PL_sv_no;
#endif
    OUTPUT:
	RETVAL

SV*
does_support_jit(...)
    CODE:
	PERL_UNUSED_VAR(items); /* -W */
#ifdef	JSOPTION_JIT
	RETVAL = &PL_sv_yes;
#else
	RETVAL = &PL_sv_no;
#endif
    OUTPUT:
	RETVAL

SV*
does_support_opcb(...)
    CODE:
	PERL_UNUSED_VAR(items); /* -W */
#ifdef JS_HAS_BRANCH_HANDLER
	RETVAL = &PL_sv_no;
#else /* Imply OPCB available */
	RETVAL = &PL_sv_yes;
#endif
    OUTPUT:
	RETVAL

SV*
does_support_threading(...)
    CODE:
	PERL_UNUSED_VAR(items); /* -W */
#ifdef JS_THREADSAFE
	RETVAL = &PL_sv_yes;
#else
	RETVAL = &PL_sv_no;
#endif
    OUTPUT:
	RETVAL

SV* exact_doubles(...)
    CODE:
	PERL_UNUSED_VAR(items); /* -W */
	RETVAL = sizeof(NV) == sizeof(jsdouble) ? &PL_sv_yes : &PL_sv_no;
    OUTPUT:
	RETVAL
	
void
jsvisitor(sv)
    SV *sv
    PPCODE:
	if(SvOK(sv) && SvROK(sv) && (sv = SvRV(sv)) && SvMAGICAL(sv)) {
	    MAGIC *mg = mg_find(sv, PERL_MAGIC_jsvis);
	    while(mg) {
		if(mg->mg_type == PERL_MAGIC_jsvis && mg->mg_private == 0x4a53) {
		    jsv_mg *jsvis = (jsv_mg *)mg->mg_ptr;
		    XPUSHs(sv_2mortal(newSViv(PTR2IV(jsvis->pcx))));
		}
		mg = mg->mg_moremagic;
	    }
	}

MODULE = JSPL     PACKAGE = JSPL::RawRT	PREFIX = jsr_

JSPL::RawRT
jsr_create(maxbytes)
    int maxbytes
    CODE:
	Newxz(RETVAL, 1, PJS_Runtime);
	if(!RETVAL) XSRETURN_UNDEF;
	if(plGRuntime) RETVAL->rt = plGRuntime;
	else if(maxbytes) RETVAL->rt = JS_NewRuntime(maxbytes);
	if(!RETVAL->rt) {
	    Safefree(RETVAL);
	    croak("Failed to create Runtime");
	}
    OUTPUT:
	RETVAL

void
jsr_DESTROY(runtime)
    JSPL::RawRT runtime
    CODE:
	if(!PL_dirty && !plGRuntime) JS_DestroyRuntime(runtime->rt);
	runtime->rt = NULL;
	Safefree(runtime);

MODULE = JSPL     PACKAGE = JSPL::Context

JSPL::Context 
create(rt, ...)
    JSPL::RawRT rt;
    INIT:
    JSContext *imported = NULL;
    CODE:
	if(items == 3) {
	    warn("Importing context\n");
	    imported = (JSContext *)SvIV(ST(1));
	    gMyPri = (JSPrincipals *)SvIV(ST(2));
	}
	RETVAL = PJS_CreateContext(aTHX_ rt, ST(0), imported);
    OUTPUT:
	RETVAL

void
DESTROY(pcx)
    JSPL::Context pcx;
    CODE:
	PJS_DestroyContext(aTHX_ pcx);

void
jsc_begin_request(pcx)
    JSPL::Context pcx;
    CODE:
	PJS_BeginRequest(PJS_getJScx(pcx));

void
jsc_end_request(pcx)
    JSPL::Context pcx;
    CODE:
	PJS_EndRequest(PJS_getJScx(pcx));

const char *
get_version(pcx)
    JSPL::Context pcx;
    CODE:
	RETVAL = JS_VersionToString(JS_GetVersion(PJS_getJScx(pcx)));
    OUTPUT:
	RETVAL

const char *
set_version(pcx, version)
    JSPL::Context pcx;
    const char *version;
    CODE:
	RETVAL = JS_VersionToString(JS_SetVersion(
	    PJS_getJScx(pcx), JS_StringToVersion(version)
	));
    OUTPUT:
	RETVAL

U32
jsc_get_options(pcx)
    JSPL::Context pcx;
    CODE:
	RETVAL = JS_GetOptions(PJS_getJScx(pcx));
    OUTPUT:
	RETVAL

U32
jsc_set_options(pcx, options)
    JSPL::Context pcx;
    U32	    options;
    CODE:
	RETVAL = JS_SetOptions(PJS_getJScx(pcx), options);
    OUTPUT:
	RETVAL
    
void
jsc_toggle_options(pcx, options)
    JSPL::Context pcx;
    U32         options;
    CODE:
	JS_ToggleOptions(PJS_getJScx(pcx), options);


void
jsc_set_branch_handler(pcx, handler)
    JSPL::Context pcx;
    SV *handler;
    CODE:
#ifdef JS_HAS_BRANCH_HANDLER
	if (!SvOK(handler)) {
	    /* Remove handler */
	    sv_free(pcx->branch_handler);
	    pcx->branch_handler = NULL;
	    JS_SetBranchCallback(PJS_getJScx(pcx), NULL);
	}
	else if (SvROK(handler) && SvTYPE(SvRV(handler)) == SVt_PVCV) {
	    sv_free(pcx->branch_handler);
	    pcx->branch_handler = SvREFCNT_inc_simple_NN(handler);
	    JS_SetBranchCallback(PJS_getJScx(pcx), PJS_branch_handler);
	} 
	else croak("%s: %s is not a CODE reference",
	           NAMESPACE"RawRT::jsc_set_branch_handler",
		   "handler"); 
#else
	PERL_UNUSED_VAR(handler);
	PERL_UNUSED_VAR(pcx);
	croak("%s: not available in this SpiderMonkey",
	      NAMESPACE"RatRT::jsc_set_branch_handler");
#endif

SV *
jsc_rta(pcx)
    JSPL::Context pcx;
    CODE:
	RETVAL = SvREFCNT_inc_simple_NN(pcx->rrt);
    OUTPUT:
	RETVAL

SV *
jsvisitor(pcx, sv)
    JSPL::Context pcx;
    SV *sv
    ALIAS:
    _isjsvis = 1
    CODE:
	RETVAL = NULL;
	if(SvOK(sv) && SvROK(sv) && (sv = SvRV(sv)) && SvMAGICAL(sv)) {
	    MAGIC *mg = mg_find(sv, PERL_MAGIC_jsvis);
	    jsv_mg *jsvis;
	    while(mg) {
		if(mg->mg_type == PERL_MAGIC_jsvis &&
		   mg->mg_private == 0x4a53 &&
		  (jsvis = (jsv_mg *)mg->mg_ptr) &&
		  jsvis->pcx == pcx
		) {
		    if(!ix) {
			AV *avbox;
			SV **myref;
			JSObject *object = jsvis->object;
			SV *robj = newSV(0);
			SV *rjsv = newSV(0);
			jsval aval = OBJECT_TO_JSVAL(object);
			sv_setref_pv(robj, PJS_RAW_OBJECT, (void*)object);
			PJS_JSV2PSV(rjsv, aval);
			RETVAL = PJS_CallPerlMethod(aTHX_ PJS_getJScx(jsvis->pcx),
			    "__new",
			    sv_2mortal(newSVpv(NAMESPACE"Visitor", 0)),	// package
			    sv_2mortal(robj),			        // content
			    sv_2mortal(rjsv),			        // jsval
			    NULL
			);
			avbox = (AV *)SvRV(SvRV(RETVAL));
			myref = av_fetch(avbox, 6, 1); /* Overload Array cache slot */
			sv_setsv(*myref, ST(1));
			sv_rvweaken(*myref);
			SvREFCNT_inc_void_NN(RETVAL);
		    } else RETVAL = &PL_sv_yes;
		    break;
		}
		else mg = mg->mg_moremagic;
	    }
	    if(!RETVAL) XSRETURN_UNDEF; /* None found */
	}
	else XSRETURN_UNDEF;
    OUTPUT:
	RETVAL

void
jsc_unbind_value(pcx, parent, name)
    JSPL::Context pcx;
    char *parent;
    char *name;
    PREINIT:
	JSContext *cx;
	jsval pval,val;
	JSObject *gobj, *pobj;
    CODE:
	cx = PJS_getJScx(pcx);
	gobj = JS_GetGlobalObject(cx);

	if (strlen(parent)) {
	    if(JS_EvaluateScript(cx, gobj, parent, strlen(parent), "", 1, &pval) &&
	       JSVAL_IS_OBJECT(pval))
		pobj = JSVAL_TO_OBJECT(pval);
	    else
		croak("No property '%s' exists", parent);
	}
	else pobj = gobj;

	if(!JS_DeleteProperty2(cx, pobj, name, &val))
	    croak("Failed to unbind %s", name);
	if(val != JSVAL_TRUE)
	    croak("Can't delete %s", name);

SV*
get_global(pcx)
    JSPL::Context pcx;
    CODE:
	if(!PJS_ReflectJS2Perl(aTHX_ PJS_getJScx(pcx),
		      OBJECT_TO_JSVAL(JS_GetGlobalObject(PJS_getJScx(pcx))),
		      &RETVAL,
		      0) // Return untied wrapper
	) {
	    PJS_report_exception(aTHX_ pcx);
	    XSRETURN_UNDEF;
	};
    OUTPUT:
	RETVAL

SV*
new_object(pcx, parent=&PL_sv_undef)
    JSPL::Context pcx;
    JSObject *parent = NO_INIT;
    PREINIT:
	JSContext *cx;
	JSObject *newobj;
    CODE:
	cx = PJS_getJScx(pcx);
	parent = PJS_GetScope(aTHX_ cx, ST(1));
	newobj = JS_NewObject(cx, NULL, NULL, parent);
	if(!newobj || !PJS_ReflectJS2Perl(aTHX_ cx, OBJECT_TO_JSVAL(newobj), &RETVAL, 0)) {
	    PJS_report_exception(aTHX_ pcx);
	    XSRETURN_UNDEF;
	}
    OUTPUT:
	RETVAL

SV* 
jsc_eval(pcx, scope, source, name = "")
    JSPL::Context pcx;
    JSObject *scope = NO_INIT;
    SV *source;
    const char *name;
    PREINIT:
	jsval rval;
	JSContext *cx;
	PJS_Script *script;
	JSBool ok = JS_FALSE;
    CODE:
	cx = PJS_getJScx(pcx);
	scope = PJS_GetScope(aTHX_ cx, ST(1));

	sv_setsv(ERRSV, &PL_sv_undef);

	script = PJS_MakeScript(aTHX_ cx, scope, source, name);

	if(script != NULL) {
	    ok = JS_ExecuteScript(cx, scope, script, &rval);
	    JS_DestroyScript(cx, script);
	}
	if(!ok || !PJS_ReflectJS2Perl(aTHX_ cx, rval, &RETVAL, 1)) {
	    PJS_report_exception(aTHX_ pcx);
	    XSRETURN_UNDEF;
        }
	PJS_GC(cx);
    OUTPUT:
        RETVAL

SV*
jsc_call(pcx, scope, function, args)
    JSPL::Context pcx;
    JSObject *scope = NO_INIT;
    SV *function;
    AV *args;
    PREINIT:
	JSContext *cx;
        jsval rval;
        jsval fval;
    CODE:
        cx = PJS_getJScx(pcx);
	scope = PJS_GetScope(aTHX_ cx, ST(1));

	if(sv_derived_from(function, PJS_FUNCTION_PACKAGE)) {
	    SV *box = SvRV(function);
	    SV **fref = av_fetch((AV *)SvRV(box), 2, 0);
	    PJS_PSV2JSV(fval, *fref);
	} else if(sv_derived_from(function, PJS_RAW_JSVAL)) {
	    PJS_PSV2JSV(fval, function);
        } else {
	    char *name = SvPV_nolen(function);
	    JSObject *nextObj;

	    if (!JS_GetMethod(cx, scope, name, &nextObj, &fval))
		croak("No function named '%s' exists", name);

	    if(JSVAL_IS_VOID(fval) || JSVAL_IS_NULL(fval))
		croak("Undefined subroutine %s called\n", name);
	}

	if(!PJS_Call_js_function(aTHX_ cx, scope, fval, args, &rval) ||
	   !PJS_ReflectJS2Perl(aTHX_ cx, rval, &RETVAL, 1))
	{
	    PJS_report_exception(aTHX_ pcx);
	    XSRETURN_UNDEF;
        }
	PJS_GC(cx);
    OUTPUT:
	RETVAL

SV *
jsc_can(pcx, scope, func)
    JSPL::Context pcx;
    JSObject *scope = NO_INIT;
    SV *func;
    PREINIT:
	JSContext *cx;
	jsval val;
    CODE:
	cx = PJS_getJScx(pcx);
	scope = PJS_GetScope(aTHX_ cx, ST(1));

	if(sv_derived_from(func, PJS_FUNCTION_PACKAGE) ||
	   // Completeness and allow check if exported
	   (SvROK(func) && SvTYPE(SvRV(func)) == SVt_PVCV &&
	    SvMAGICAL(SvRV(func)) && mg_find(SvRV(func), PERL_MAGIC_jsvis))
	)
	    RETVAL = SvREFCNT_inc_simple_NN(func);
	else {
	    JSExceptionState *es = JS_SaveExceptionState(cx);
	    const char *fname = SvPV_nolen(func);
	    if(JS_GetProperty(cx, scope, fname, &val) &&
	       (JS_TypeOfValue(cx, val) == JSTYPE_FUNCTION
		|| JS_ValueToFunction(cx, val) != NULL)) {
		if(!PJS_ReflectJS2Perl(aTHX_ cx, val, &RETVAL, 1))
		    PJS_report_exception(aTHX_ pcx);
	    }
	    else RETVAL = &PL_sv_undef;
	    JS_RestoreExceptionState(cx, es);
	}
    OUTPUT:
	RETVAL

int
jsc_get_flag(pcx, flag)
    JSPL::Context pcx;
    const char *flag;
    CODE:
	RETVAL = (int)PJS_getFlag(pcx, flag);
    OUTPUT:
	RETVAL

void
jsc_set_flag(pcx, flag, val)
    JSPL::Context pcx;
    const char *flag;
    int val;
    CODE:
	PJS_setFlag(pcx, flag, val);

MODULE = JSPL    PACKAGE = JSPL::Controller

jsval
_get_stash(pcx, package)
    JSPL::Context pcx;
    char *package;
    PREINIT:
	JSContext *cx;
    CODE:
	cx = PJS_getJScx(pcx);
	RETVAL = OBJECT_TO_JSVAL(PJS_GetPackageObject(aTHX_ cx, package));
    OUTPUT:
	RETVAL

MODULE = JSPL	PACKAGE = JSPL::Boolean

SV *
False()
    ALIAS:
	True = 1
    CODE:
	RETVAL = newSV(0);
	sv_setref_iv(RETVAL, PJS_BOOLEAN, (IV)ix);
    OUTPUT:
	RETVAL

#ifdef __GNUC__
#pragma GCC diagnostic ignored "-Wnonnull"
#endif

BOOT:
    plGRuntime = (JSRuntime *)SvIV(get_sv("JSPL::_gruntime", 1));
    PJS_Context_SV = gv_fetchpv(NAMESPACE"Context::CURRENT", GV_ADDMULTI, SVt_IV);
    PJS_This = gv_fetchpv(NAMESPACE"This", GV_ADDMULTI, SVt_PV);
#if PJS_UTF8_NATIVE
    JS_SetCStringsAreUTF8();
#else
    eval_sv(sv_2mortal(newSVpv("require Encode",0)), G_DISCARD);
    if(SvTRUE(ERRSV)) croak(NULL);
#endif
