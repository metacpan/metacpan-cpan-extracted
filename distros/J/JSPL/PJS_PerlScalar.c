#include "JS.h"

static const char *PerlScalarPkg = NAMESPACE"PerlScalar";

JSClass perlscalar_class = {
    "PerlScalar",
    JSCLASS_PRIVATE_IS_PERL,
    JS_PropertyStub, JS_PropertyStub, JS_PropertyStub, PJS_SetterPropStub,
    JS_EnumerateStub, JS_ResolveStub, JS_ConvertStub, PJS_unrootJSVis,
    JSCLASS_NO_OPTIONAL_MEMBERS
};

JSObject *
PJS_NewPerlScalar(
    pTHX_
    JSContext *cx,
    JSObject *parent,
    SV *sref
) {
    JSObject *newobj = JS_NewObject(cx, &perlscalar_class, NULL, parent);
    return PJS_CreateJSVis(aTHX_ cx, newobj, sref);
}

static JSBool
perlscalar_value(
    JSContext *cx, 
    DEFJSFFARGS_
) {
    dTHX;
    DECJSFFARGS;
    SV *iref = (SV *)JS_GetPrivate(cx, obj);
    SV *ref = SvRV(iref);
    return PJS_ReflectPerl2JS(aTHX_ cx, obj, ref, rval);
}

static JSPropertySpec perlscalar_props[] = {
    {0, 0, 0, 0, 0}
};

static JSFunctionSpec perlscalar_methods[] = {
    JS_FN("valueOf", perlscalar_value, 0, 0),
    JS_FS_END
};

/* Public JS space constructor */
static JSBool
PerlScalar(
    JSContext *cx,
    DEFJSFSARGS_
) {
    dTHX;
    DECJSFSARGS;
    SV *ref = &PL_sv_undef;

    /* If the path fails, the object will be finalized */
    if(!obj) obj = JS_NewObject(cx, &perlscalar_class, NULL, NULL);
    JS_SetPrivate(cx, obj, (void *)newRV(ref));

    if(argc == 1 && !PJS_ReflectJS2Perl(aTHX_ cx, argv[0], &ref, 1))
	return JS_FALSE;

    return PJS_ReflectPerl2JS(aTHX_ cx, JS_GetParent(cx, obj),
	                           newRV_noinc(ref), rval);
}


JSObject *
PJS_InitPerlScalarClass(
    pTHX_
    JSContext *cx,
    JSObject *global
) {
    JSObject *proto;
    JSObject *stash = PJS_GetPackageObject(aTHX_ cx, PerlScalarPkg);
    proto = JS_InitClass(
        cx, global,
	stash,
	&perlscalar_class,
	PerlScalar, 1, 
        perlscalar_props,
	perlscalar_methods,
        NULL, NULL
    );
    JS_DefineProperty(cx, stash, PJS_PROXY_PROP,
	              OBJECT_TO_JSVAL(proto), NULL, NULL, 0);
    return PJS_CreateJSVis(aTHX_ cx, proto,
		get_sv(NAMESPACE"PerlScalar::prototype", 1));
}
