#include "JS.h"

static const char *PerlHashPkg = NAMESPACE"PerlHash";

#define PJS_HASH_CHECK	    \
    if(SvTYPE(hv) != SVt_PVHV) {\
	JS_ReportError(cx, "Not a HASH");\
	return JS_FALSE; \
    }

static JSBool
perlhash_del(
    JSContext *cx,
    JSObject *obj,
    pjsid id,
    jsval *vp
) {
    dTHX;
    SV *ref = (SV *)JS_GetPrivate(cx, obj);
    HV *hv = (HV *)SvRV(ref);
    SV *svk;
    
    PJS_HASH_CHECK

    if(!PJSID_IS(STRING, id))
	return JS_TRUE;

    svk = PJS_JSString2SV(aTHX_ cx, PJSID_TO(STRING, id));
    (void)hv_delete_ent(hv, svk, G_DISCARD, 0);
    sv_free(svk);
    return JS_TRUE;
}

static JSBool
perlhash_get(
    JSContext *cx,
    JSObject *obj,
    pjsid id,
    jsval *vp
) {
    dTHX;
    SV *ref = (SV *)JS_GetPrivate(cx, obj);
    HV *hv = (HV *)SvRV(ref);
    SV *svk;
    HE *he;
    JSBool ok = JS_TRUE;
    
    PJS_HASH_CHECK

    if(!PJSID_IS(STRING, id))
	return JS_TRUE;

    ENTER; SAVETMPS;
    svk = PJS_JSString2SV(aTHX_ cx, PJSID_TO(STRING, id));
    sv_2mortal(svk);
    PJS_DEBUG1("HASH get: %s\n", SvPV_nolen(svk));

    he = hv_fetch_ent(hv, svk, 0, 0);
    if(SvGMAGICAL(hv)) mg_get(HeVAL(he));
    if(he)
        ok = PJS_ReflectPerl2JS(aTHX_ cx, obj, sv_mortalcopy(HeVAL(he)), vp);
    FREETMPS; LEAVE;
    return ok;
}

static JSBool
perlhash_set(
    JSContext *cx,
    JSObject *obj,
    pjsid id,
    DEFSTRICT_
    jsval *vp
) {
    dTHX;
    SV *ref = (SV *)JS_GetPrivate(cx, obj);
    HV *hv = (HV *)SvRV(ref);
    SV *sv;
    SV *svk;
    JSBool ok = JS_TRUE;

    PJS_HASH_CHECK

    if(!PJSID_IS(STRING, id))
        return JS_TRUE;

    if(!PJS_ReflectJS2Perl(aTHX_ cx, *vp, &sv, 1))
	return JS_FALSE;

    svk = PJS_JSString2SV(aTHX_ cx, PJSID_TO(STRING, id));

    if(!hv_store_ent(hv, svk, sv, 0)) {
	if(SvSMAGICAL(hv)) mg_set(sv);
	else ok = JS_FALSE; // TODO: Check error to report
    }
    sv_free(svk);
    
    return ok;
}

static JSBool perlhash_enumerate(
    JSContext *cx,
    JSObject *obj,
    JSIterateOp enum_op,
    jsval *statep,
    jsid  *idp
) {
    dTHX;
    SV *ref = (SV *)JS_GetPrivate(cx, obj);
    HV *hv = (HV *)SvRV(ref);

    PJS_HASH_CHECK

    if(enum_op == JSENUMERATE_INIT) {
	int items = hv_iterinit(hv);
	*statep = PRIVATE_TO_JSVAL(hv);
	if(idp)
	    *idp = INT_TO_JSID(items);
	return JS_TRUE;
    }
    if(enum_op == JSENUMERATE_NEXT) {
	HE *hkey;
	if(hv != (HV *)JSVAL_TO_PRIVATE(*statep) || SvTYPE(hv) != SVt_PVHV) {
	    JS_ReportError(cx, "Wrong iterator");
	    return JS_FALSE;
	}
	hkey = hv_iternext(hv);
	if(!hkey) *statep = JSVAL_NULL;
	else {
	    STRLEN len;
	    SV *keysv = hv_iterkeysv(hkey);
	    char *keyname = PJS_SvPV(keysv, len);
	    JSString *jstr = ((int)len >= 0) 
		? JS_NewStringCopyN(cx, keyname, len)
		: JS_NewUCStringCopyN(cx, (jschar *)keyname, -(int)len);
	    if(!jstr) return JS_FALSE;
	    return JS_ValueToId(cx, STRING_TO_JSVAL(jstr), idp);
	}
	return JS_TRUE;
    }
    return JS_TRUE;
}

static JSBool perlhash_resolve(
    JSContext *cx,
    JSObject *obj,
    pjsid id,
    uintN flags,
    JSObject **objp
) {
    dTHX;
    SV *ref = (SV *)JS_GetPrivate(cx, obj);
    HV *hv = (HV *)SvRV(ref);
    HE *he;
    SV *svk;
    JSString *key;

    PJS_HASH_CHECK

    if(!PJSID_IS(STRING, id))
	return JS_TRUE;

    key = PJSID_TO(STRING, id);
    svk = PJS_JSString2SV(aTHX_ cx, key);
    he = hv_fetch_ent(hv, svk, 0, 0);
    sv_free(svk);
    if(he) {
	PJS_DEBUG1("Resolved %s\n", key);
#if JS_VERSION < 185
	if(!JS_DefineUCProperty(cx, obj,
				JS_GetStringChars(key), JS_GetStringLength(key),
				JSVAL_VOID, NULL, NULL, 0))
#else
	if(!JS_DefinePropertyById(cx, obj, id, JSVAL_VOID, NULL, NULL,  0))
#endif
	    return JS_FALSE;
	*objp = obj;
    }
    return JS_TRUE;
}

JSClass perlhash_class = {
    "PerlHash",
    JSCLASS_PRIVATE_IS_PERL | JSCLASS_NEW_ENUMERATE | JSCLASS_NEW_RESOLVE,
    JS_PropertyStub, perlhash_del, perlhash_get, perlhash_set,
    (JSEnumerateOp)perlhash_enumerate, (JSResolveOp)perlhash_resolve,
    JS_ConvertStub, PJS_unrootJSVis,
    JSCLASS_NO_OPTIONAL_MEMBERS
};

JSObject *
PJS_NewPerlHash(
    pTHX_
    JSContext *cx,
    JSObject *parent,
    SV *href
) {
    return PJS_CreateJSVis(
			   aTHX_ cx,
			   JS_NewObject(cx, &perlhash_class, NULL, parent),
			   href
    );
}

static JSBool
PerlHash(
    JSContext *cx,
    DEFJSFSARGS_
) {
    DECJSFSARGS;
    dTHX;
    HV *hv = newHV();
    SV *ref = newRV_noinc((SV *)hv);
    uintN arg;
    JSBool ok = JS_FALSE;
    SV *sv, *key;

    /* If the path fails, the object will be finalized */
    if(!obj) obj = JS_NewObject(cx, &perlhash_class, NULL, NULL);
    JS_SetPrivate(cx, obj, (void *)newRV(&PL_sv_undef));

    for(arg = 0; arg < argc; arg += 2) {
	JSString *jstr = JS_ValueToString(cx, argv[arg]);
	if(!jstr) goto fail;
	key = PJS_JSString2SV(aTHX_ cx, jstr);
	if(!PJS_ReflectJS2Perl(aTHX_ cx, argv[arg+1], &sv, 1) ||
	   !hv_store_ent(hv, key, sv, 0)) goto fail;
	sv_free(key);
    }

    if(SvTRUEx(get_sv(NAMESPACE"PerlHash::construct_blessed", 0)))
	sv_bless(ref, gv_stashpv(PerlHashPkg, 0));

    ok = PJS_CreateJSVis(aTHX_ cx, obj, ref) != NULL;
    if(ok) PJS_SET_RVAL(cx, OBJECT_TO_JSVAL(obj));
    fail:
    sv_free(ref);
    return ok;
}

JSObject *
PJS_InitPerlHashClass(
    pTHX_
    JSContext *cx,
    JSObject *global
) {
    JSObject *proto;
    JSObject *stash = PJS_GetPackageObject(aTHX_ cx, PerlHashPkg);
    proto = JS_InitClass(
        cx, global,
	stash,
	&perlhash_class,
	PerlHash, 0, 
        NULL, NULL,
        NULL, NULL
    );
    
    if(!proto ||
       !JS_DefineProperty(cx, stash, PJS_PROXY_PROP,
	                  OBJECT_TO_JSVAL(proto), NULL, NULL, 0))
	return NULL;

    return PJS_CreateJSVis(aTHX_ cx, proto,
		newRV_inc((SV *)get_hv(NAMESPACE"PerlHash::prototype", 1)));
}
