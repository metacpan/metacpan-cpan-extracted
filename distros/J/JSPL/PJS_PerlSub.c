#include "JS.h"

extern JSClass perlpackage_class;
static const char *PerlSubPkg = NAMESPACE"PerlSub";
static JSBool perlsub_call(JSContext *, DEFJSFSARGS_);
static JSBool perlsub_construct(JSContext *, DEFJSFSARGS_);

static JSClass perlsub_class = {
    "PerlSub", JSCLASS_PRIVATE_IS_PERL,
    JS_PropertyStub, JS_PropertyStub, JS_PropertyStub, PJS_SetterPropStub,
    JS_EnumerateStub, JS_ResolveStub, JS_ConvertStub, PJS_unrootJSVis,
    NULL,
    NULL,
    perlsub_call,
    perlsub_construct,
    NULL,
    NULL,
    NULL,
    NULL
};

static JSBool
perlsub_call(
    JSContext *cx, 
    DEFJSFSARGS_
) {
    dTHX;
    DECJSFSARGS;
    JSObject *func = JSVAL_TO_OBJECT(JS_ARGV_CALLEE(argv));
    SV *callee = (SV *)JS_GetPrivate(cx, func);
    JSObject *This = JSVAL_TO_OBJECT(argv[-1]);
    JSClass *clasp = PJS_GET_CLASS(cx, This);
    SV *caller;
    JSBool wanta, isclass = JS_FALSE;

    if(!JS_GetProperty(cx, func, "$wantarray", rval) ||
       !JS_ValueToBoolean(cx, *rval, &wanta))
	return JS_FALSE;

    PJS_DEBUG1("In PSC: obj is %s\n", PJS_GET_CLASS(cx, obj)->name);
    if(clasp == &perlpackage_class) {
       if(!JS_GetProperty(cx, This, "$__im_a_class", rval) ||
          !JS_ValueToBoolean(cx, *rval, &isclass))
	    return JS_FALSE;
    }

    if(isclass ||
       ( clasp == &perlsub_class /* Constructors has a Stash in __proto__ */
         && (func = JS_GetPrototype(cx, This))
         && PJS_GET_CLASS(cx, func) == &perlpackage_class)
    ) { // Caller is a stash, make a static call
	char *pkgname = PJS_GetPackageName(aTHX_ cx, This);
	if(!pkgname) return JS_FALSE;
	caller = newSVpv(pkgname, 0);
	PJS_DEBUG1("Caller is a stash: %s\n", pkgname);
#if JS_VERSION >= 185
	Safefree(pkgname);
#endif
    }
    else if(IS_PERL_CLASS(clasp) &&
	    sv_isobject(caller = (SV *)JS_GetPrivate(cx, This))
    ) { // Caller is a perl object
	SvREFCNT_inc_void_NN(caller);
	PJS_DEBUG1("Caller is an object: %s\n", SvPV_nolen(caller));
    }
    else {
	caller = NULL;
	PJS_DEBUG1("Caller is %s\n", clasp->name);
    }

    return PJS_Call_sv_with_jsvals(aTHX_ cx, obj, callee, caller, argc, argv,
                                   rval, wanta ? G_ARRAY : G_SCALAR);
}

static JSBool
perlsub_construct(
    JSContext *cx,
    DEFJSFSARGS_
) {
    dTHX;
    DECJSFSARGS;
    JSObject *func = JSVAL_TO_OBJECT(JS_ARGV_CALLEE(argv));
    SV *callee = (SV *)JS_GetPrivate(cx, func);
    SV *caller = NULL;
#if JS_VERSION < 185
    JSObject *This = JSVAL_TO_OBJECT(argv[-1]);
#else
    JSObject *This = JS_NewObjectForConstructor(cx, vp);
#endif
    JSObject *proto = JS_GetPrototype(cx, This);

    PJS_DEBUG1("Want construct, This is a %s", PJS_GET_CLASS(cx, This)->name);
    if(PJS_GET_CLASS(cx, proto) == &perlpackage_class ||
       ( JS_LookupProperty(cx, func, "prototype", &argv[-1])
         && JSVAL_IS_OBJECT(argv[-1]) && !JSVAL_IS_NULL(argv[-1])
         && (proto = JS_GetPrototype(cx, JSVAL_TO_OBJECT(argv[-1]))) 
         && strEQ(PJS_GET_CLASS(cx, proto)->name, PJS_PACKAGE_CLASS_NAME))
    ) {
	SV *rsv = NULL;
	char *pkgname = PJS_GetPackageName(aTHX_ cx, proto);
#if JS_VERSION >= 185
	JSAutoByteString bytes;
	bytes.initBytes(pkgname);
#endif
	caller = newSVpv(pkgname, 0);

	argv[-1] = OBJECT_TO_JSVAL(This);
	if(!PJS_Call_sv_with_jsvals_rsv(aTHX_ cx, obj, callee, caller,
	                                argc, argv, &rsv, G_SCALAR))
	    return JS_FALSE;

	if(SvROK(rsv) && sv_derived_from(rsv, pkgname)) {
	    JSObject *newobj = PJS_NewPerlObject(aTHX_ cx, JS_GetParent(cx, func), rsv);
	    *rval = OBJECT_TO_JSVAL(newobj);
	    return JS_TRUE;
	}
	JS_ReportError(cx, "%s's constructor don't return an object",
	               SvPV_nolen(caller));
    }
    else JS_ReportError(cx, "Can't use as a constructor"); // Yet! ;-)

    return JS_FALSE;
}

JSBool
perlsub_as_constructor(
    JSContext *cx,
    JSObject *obj,
    pjsid id,
    DEFSTRICT_
    jsval *vp
) {
    // dTHX;
    const char *key;

    if(!PJSID_IS(STRING, id)) {
	return JS_TRUE;
    }

#if JS_VERSION < 185
    key = JS_GetStringBytes(PJSID_TO(STRING, id));
#else
    JSAutoByteString bytes(cx, PJSID_TO(STRING, id));
    key = bytes.ptr();
#endif

    if(strEQ(key, "constructor")) {
	JSObject *constructor;
	if(JSVAL_IS_OBJECT(*vp) && (constructor = JSVAL_TO_OBJECT(*vp)) &&  
	   PJS_GET_CLASS(cx, constructor) == &perlsub_class) {
	    /* TODO: Change the constructor 'name' */
	    jsval temp;
	    JSObject *stash = JS_GetPrototype(cx, obj);
	    JS_SetPrototype(cx, stash, JS_GetPrototype(cx, constructor));
	    JS_SetPrototype(cx, constructor, stash);
	    JS_DefineProperty(cx, constructor, "prototype", OBJECT_TO_JSVAL(obj),
		              NULL, NULL, 0);
	    JS_LookupProperty(cx, obj, "__PACKAGE__", &temp);
	    // warn("Constructor set for %s\n", JS_GetStringBytes(JSVAL_TO_STRING(temp)));
	    return JS_TRUE;
	} else {
	    JS_ReportError(cx, "Invalid constructor type");
	    return JS_FALSE;
	}
    } else
	warn ("Opps: setting %s?\n", key);
    return JS_TRUE;
}

JSObject*
PJS_NewPerlSub(
    pTHX_
    JSContext *cx,
    JSObject *parent,
    SV *cvref
) {
    JSObject *newobj = PJS_CreateJSVis(
	    aTHX_ cx,
	    JS_NewObject(cx, &perlsub_class, NULL, parent),
	    cvref
    );

    if(newobj) {
	CV *cv = (CV *)SvRV(cvref);
	const char *fname = CvANON(cv) ? "(anonymous)" : GvENAME(CvGV(cv));
	JSString *jstr = JS_InternString(cx, fname);
	if(!jstr || !JS_DefineProperty(cx, newobj, "name",
		                      STRING_TO_JSVAL(jstr),
		                      NULL, NULL,
		                      JSPROP_READONLY | JSPROP_PERMANENT)
	) {
	    PJS_unrootJSVis(cx, newobj);
	    newobj = NULL;
	}
    }

    return newobj;
}

/* The public JS side constructor */
static JSBool
PerlSub(
    JSContext *cx, 
    DEFJSFSARGS_
) {
    dTHX;
    DECJSFSARGS;
    // char *tmp;
    SV *cvref;
    JSBool ok = JS_FALSE;
    SV *source;
    /* If the path fails, the object will be finalized, so its needs the
     * private setted */

    if(!obj) obj = JS_NewObject(cx, &perlsub_class, NULL,  NULL); 
    JS_SetPrivate(cx, obj, (void *)newRV(&PL_sv_undef));
    ENTER; SAVETMPS;
    if(argc != 1) {
	JS_ReportError(cx, "PerlSub constructor requires more arguments");
	return JS_FALSE;
    }

    if((source = PJS_JSString2SV(aTHX_ cx, JS_ValueToString(cx, argv[0]))) &&
       (cvref = PJS_CallPerlMethod(aTHX_ cx,
                                     "_const_sub",
	                             sv_2mortal(newSVpv(PerlSubPkg, 0)),
	                             sv_2mortal(source),
	                             NULL)))
	ok = PJS_CreateJSVis(aTHX_ cx, obj, cvref) != NULL;
    if(ok) PJS_SET_RVAL(cx, OBJECT_TO_JSVAL(obj));
    FREETMPS; LEAVE;
    return ok;
}

JSObject*
PJS_InitPerlSubClass(
    pTHX_
    JSContext *cx,
    JSObject *global
) {
    CV *pcv = get_cv(NAMESPACE"PerlSub::prototype", 0);
    JSObject *proto;
    if(pcv && (CvROOT(pcv) || CvXSUB(pcv))) {
	proto = JS_InitClass(
	    cx,
	    global,
	    PJS_GetPackageObject(aTHX_ cx, PerlSubPkg),
	    &perlsub_class,
	    PerlSub, 1, 
	    NULL, NULL,
	    NULL, NULL
	);
	return PJS_CreateJSVis(aTHX_ cx, proto,
	                       sv_2mortal(newRV_inc((SV *)pcv)));
    }
    croak("Can't locate PerlSub::prototype");
    return NULL;
}
