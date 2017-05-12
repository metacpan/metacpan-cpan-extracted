#include "JS.h"

extern JSClass perlhash_class;
extern JSClass perlarray_class;
extern JSClass perl_class;

static const char *PJS_EXPORT_PROP = "__export__";

static JSBool perlpackage_add(JSContext *cx, JSObject *obj, pjsid id, jsval *vp);
static JSBool perlpackage_set(JSContext *cx, JSObject *obj, pjsid id, DEFSTRICT_ jsval *vp);
static JSBool perlpackage_get(JSContext *cx, JSObject *obj, pjsid id, jsval *vp);
static JSBool perlpackage_resolve(JSContext *, JSObject *, pjsid, uintN, JSObject **);

#if !defined(gv_const_sv)
static SV *
Perl_gv_const_sv(pTHX_ GV *gv) {
    if(SvTYPE(gv) == SVt_PVGV)
	return cv_const_sv(GvCVu(gv));
    return NULL;
}
#if !defined(PERL_IMPLICIT_CONTEXT)
#define gv_const_sv	Perl_gv_const_sv
#else
#define gv_const_sv(a)	Perl_gv_const_sv(aTHX_ a)
#endif
#endif

JSClass perlpackage_class = {
    PJS_PACKAGE_CLASS_NAME,
    JSCLASS_HAS_PRIVATE /* Must be wrapped */
	| JSCLASS_NEW_RESOLVE | JSCLASS_HAS_RESERVED_SLOTS(1),
    perlpackage_add, JS_PropertyStub, perlpackage_get, perlpackage_set,
    JS_EnumerateStub, (JSResolveOp)perlpackage_resolve,
    JS_ConvertStub, PJS_unrootJSVis,
    JSCLASS_NO_OPTIONAL_MEMBERS
};

static JSBool
perlpackage_add(
    JSContext *cx,
    JSObject *obj,
    pjsid id,
    jsval *vp
) {
    dTHX;
    SV *ref = (SV *)JS_GetInstancePrivate(cx, obj, &perlpackage_class, NULL);
    char *key;
    SV *sv;
    jsval temp;
    JSBool can, ok = JS_TRUE;
    
    if(!PJSID_IS(STRING, id))
	return JS_TRUE;

    assert(ref != NULL);


#if JS_VERSION < 185
    key = JS_GetStringBytes(PJSID_TO(STRING, id));
#else
    JSAutoByteString bytes(cx, PJSID_TO(STRING, id));
    key = bytes.ptr();
#endif
    PJS_DEBUG1("In PC add for '%s'\n", key);

    if(*key == '$' || JSVAL_IS_VOID(*vp) || JSVAL_IS_NULL(*vp) ||
       strEQ(key, PJS_EXPORT_PROP) || strEQ(key, PJS_PASSPORT_PROP))
	return JS_TRUE;

    if(!JS_GetProperty(cx, obj, PJS_EXPORT_PROP, &temp) ||
       !JS_ValueToBoolean(cx, temp, &can))
	return JS_FALSE;

    /* Vetoed */
    if(!can) return JS_TRUE;

    ENTER; SAVETMPS;
    PJS_DEBUG2("Want add '%s' in '%s'\n", key, HvNAME((HV *)SvRV(ref)));
    if(!PJS_ReflectJS2Perl(aTHX_ cx, *vp, &sv, 0))
	ok = JS_FALSE;

    if(ok && sv_isobject(sv_2mortal(sv)) && sv_derived_from(sv, PJS_OBJECT_PACKAGE)) {
	SV *res = PJS_CallPerlMethod(aTHX_ cx,
	    "__bind_to_stash",
	    sv,
	    sv_2mortal(newSVpv(HvNAME((HV *)SvRV(ref)) ,0)),
	    sv_2mortal(newSVpv(key,0)),
	    NULL
	);
	if(!res || !SvTRUE(res)) 
	    ok = JS_FALSE;
    }
    FREETMPS; LEAVE;
    return ok;
}

static char* form_name(const char *package, const char *key) {
    char *name;
    New(1, name, strlen(package)+strlen(key)+2, char);
    if(name) {
	strcpy(name, package);
	strcat(name, "::");
	strcat(name, key+1); // skip sigil
    }
    return name;
}

static JSBool perlpackage_set(
    JSContext *cx,
    JSObject *obj,
    pjsid id,
    DEFSTRICT_
    jsval *vp
) {
    dTHX;
    SV *ref = (SV *)JS_GetInstancePrivate(cx, obj, &perlpackage_class, NULL);
    const char *key;
    const char *package;
    jsval temp;
    JSBool can;
    
    if(!PJSID_IS(STRING, id))
	return JS_TRUE;

    assert(ref != NULL);
    
#if JS_VERSION < 185
    key = JS_GetStringBytes(PJSID_TO(STRING, id));
#else
    JSAutoByteString bytes(cx, PJSID_TO(STRING, id));
    key = bytes.ptr();
#endif
    package = HvNAME((HV *)SvRV(ref));

    if(*key == '$') {
	/* Don't want to allow @ nor % yet, to much dangerous */
	char *name;
	SV *nsv;
	SV *sv;
	if(JS_GetProperty(cx, obj, PJS_EXPORT_PROP, &temp) &&
	   JS_ValueToBoolean(cx, temp, &can) && !can)
	    return JS_TRUE; /* Export vetoed */
	if(!PJS_ReflectJS2Perl(aTHX_ cx, *vp, &nsv, 1)) 
	    return JS_FALSE;
	name = form_name(package, key);
	PJS_DEBUG1("In PCS set for $%s\n", name);
	sv = get_sv(name, GV_ADD | GV_ADDMULTI);
	Safefree(name);
	SvSetMagicSV(sv, nsv);
    }
    return JS_TRUE;
}

static JSBool perlpackage_get(
    JSContext *cx,
    JSObject *obj,
    pjsid id,
    jsval *vp
) {
    dTHX;
    SV *ref = NULL;
    const char *key;
    const char *package;
    
    if(!PJSID_IS(STRING, id)) 
	return JS_TRUE;

    while(obj) {
	ref = (SV *)JS_GetInstancePrivate(cx, obj, &perlpackage_class, NULL);
	if(ref) break;
	obj = JS_GetPrototype(cx, obj);
    }
    if(!ref) return JS_TRUE;

#if JS_VERSION < 185
    key = JS_GetStringBytes(PJSID_TO(STRING, id));
#else
    JSAutoByteString bytes(cx, PJSID_TO(STRING, id));
    key = bytes.ptr();
#endif
    package = HvNAME((HV *)SvRV(ref));

    if(*key == '$') {
	char *name = form_name(package, key);
	SV *sv = get_sv(name, 0);
	PJS_DEBUG1("In PCS get for $%s\n", name);
	Safefree(name);
	if(sv) return PJS_ReflectPerl2JS(aTHX_ cx, obj, sv, vp);
    }
    return JS_TRUE;
}

static JSBool perlpackage_resolve(
    JSContext *cx,
    JSObject *obj,
    pjsid id,
    uintN flags,
    JSObject **objp
) {
    dTHX;
    SV *ref = (SV *)JS_GetInstancePrivate(cx, obj, &perlpackage_class, NULL);
    const char *key;
    const char *package;
    HV *stash;
    GV *gv;
    SV *sv = NULL;
    jsval temp;
    JSBool ok = TRUE;
    
    if(!PJSID_IS(STRING, id))
	return JS_TRUE;

#if JS_VERSION < 185
    key = JS_GetStringBytes(PJSID_TO(STRING, id));
#else
    JSAutoByteString bytes(cx, PJSID_TO(STRING, id));
    key = bytes.ptr();
#endif
    if(strEQ(key, PJS_PASSPORT_PROP)) {
	*objp = obj;
	return JS_TRUE;
    }

    stash = (HV *)SvRV(ref);
    package = HvNAME(stash);
    PJS_DEBUG2("In PCS resolve for %s::%s\n", package, key);
    switch(*key) {
	AV *av; HV *hv; CV *cv; char *name;
	case '%':
	    name = form_name(package, key);
	    hv = get_hv(name, 0);
	    if(hv && HvARRAY(hv)) {
		PJS_DEBUG1("Hash %s found\n", name);
		sv = newRV((SV *)hv);
	    }
	    Safefree(name);
	    break;
	case '@':
	    name = form_name(package, key);
	    av = get_av(name, 0);
	    if(av && AvMAX(av) >= 0) {
		PJS_DEBUG1("Array %s found\n", name);
		sv = newRV((SV *)av);
	    }
	    Safefree(name);
	    break;
	case '&':
	    name = form_name(package, key);
	    cv = get_cv(name, 0);
	    if(cv && (CvROOT(cv) || CvXSUB(sv))) {
		PJS_DEBUG1("Sub %s found\n", name);
		sv = newRV((SV *)cv);
	    }
	    Safefree(name);
	    break;
	case '$':
	    name = form_name(package, key);
	    sv = get_sv(name, 0);
	    // if(sv && SvOK(sv)) PJS_DEBUG1("Scalar %s found\n", name);
	    Safefree(name);
	    /* Make property defined, but lets getter do its work */
	    if(sv || (flags & JSRESOLVE_DECLARING)) {
		if(JS_DefineProperty(cx, obj, key, JSVAL_VOID, NULL, NULL, 0)) {
		    *objp = obj;
		    return JS_TRUE;
		}
		return JS_FALSE;
	    }
    }
    if(!sv && PJS_getFlag(PJS_GET_CONTEXT(cx), "ConstantsValue")) {
	GV **gvp;
	gvp = (GV**)hv_fetch(stash, key, strlen(key), 0);
	if(gvp && *gvp != (GV*)&PL_sv_undef)
	    sv = gv_const_sv(*gvp);
    }
    if(sv) {
	if(PJS_ReflectPerl2JS(aTHX_ cx, obj, sv, &temp) &&
	   JS_DefineProperty(cx, obj, key, temp, NULL, NULL, 0)
	)
	    *objp = obj;
	else ok = JS_FALSE;
	sv_free(sv);
	return ok;
    }
    /* Now try method resolution */
    gv = gv_fetchmeth(stash, key, strlen(key), 0);
    if(gv) {
	PJS_DEBUG("Method found\n");
	// TODO: Make method resolution dynamic
	if(PJS_ReflectPerl2JS(aTHX_ cx, obj,
	                           (sv = newRV_inc((SV *)GvCV(gv))), &temp) &&
	   JS_DefineProperty(cx, obj, key, temp, NULL, NULL, 0))
	    *objp = obj;
	else ok = JS_FALSE;
	sv_free(sv);
    }
    return JS_TRUE;
}

static JSBool
perlpackage_eget(
    JSContext *cx,
    JSObject *obj,
    pjsid id,
    jsval *vp
) {
    dTHX;
    SV *ref = (SV *)JS_GetInstancePrivate(cx, obj, &perlpackage_class, NULL);
    const char *package = HvNAME((HV *)SvRV(ref));
#if JS_VERSION < 185
    char *key = JS_GetStringBytes(PJSID_TO(STRING, id));
#else
    JSAutoByteString bytes(cx, PJSID_TO(STRING, id));
    char *key = bytes.ptr();
#endif
    
    if(strEQ(key, PJS_EXPORT_PROP)) {
	char *name = form_name(package, "__allow_js_export");
	SV *sv = get_sv(name, 0);
	Safefree(name);
	*vp = (sv && SvOK(sv) && SvTRUE(sv)) ? JSVAL_TRUE : JSVAL_FALSE;
    }
    return JS_TRUE;
}

JSObject *
PJS_GetPackageObject(
    pTHX_
    JSContext *cx,
    const char *package
) {
    JSObject *scope;

    scope = JS_GetScopeChain(cx);
    if(!scope) scope = JS_GetGlobalObject(cx);
    while(scope) {
	jsval temp = JSVAL_VOID;
	JSObject *stashes;
	if(JS_LookupProperty(cx, scope, "__PERL__", &temp)
	   && JSVAL_IS_OBJECT(temp) 
	   && (stashes = JSVAL_TO_OBJECT(temp))
	   && PJS_GET_CLASS(cx, stashes) == &perl_class
	) {
	    if(JS_LookupProperty(cx, stashes, package, &temp)) {
		HV *stash;
		JSObject *pkg;

		if(JSVAL_IS_OBJECT(temp) &&
		   (PJS_GET_CLASS(cx, JSVAL_TO_OBJECT(temp)) == &perlpackage_class))
		    return JSVAL_TO_OBJECT(temp);
		if(!JSVAL_IS_VOID(temp)) {
		    croak("OOPS! Garbage in controller!");
		    return NULL;
		}

		/* Must create */
		stash = gv_stashpv(package, GV_ADD);
		pkg = JS_NewObject(cx, &perlpackage_class, NULL, stashes);
		if(pkg) {
		    JSObject *proto;
		    PJS_CreateJSVis(aTHX_ cx, pkg, newRV_noinc((SV *)stash));
		    if((proto = JS_NewObject(cx, NULL, pkg, scope)) &&
		       JS_DefineProperty(cx, pkg, PJS_PROXY_PROP,
					 OBJECT_TO_JSVAL(proto),
					 NULL, NULL, 0) &&
		       JS_DefineProperty(cx, stashes, package, OBJECT_TO_JSVAL(pkg),
					 NULL, NULL,
			    JSPROP_READONLY | JSPROP_PERMANENT | JSPROP_ENUMERATE) &&
		       JS_DefineProperty(cx, pkg, PJS_EXPORT_PROP,
					 JSVAL_VOID, perlpackage_eget, NULL,
					 JSPROP_READONLY | JSPROP_PERMANENT) &&
		       JS_DefineProperty(cx, pkg, PJS_PACKAGE_PROP,
				     STRING_TO_JSVAL(JS_InternString(cx, package)),
			    NULL, NULL, JSPROP_READONLY | JSPROP_PERMANENT) &&
		       JS_DefineProperty(cx, proto, "constructor", JSVAL_VOID,
					 NULL, perlsub_as_constructor, 0)
		    ) return pkg;
		    else PJS_unrootJSVis(cx, pkg); /* Let GC do its work */
		}
	    }
	    return NULL; /* Failed */
	}
	scope = JS_GetParent(cx, scope);
    }
    croak("Can't get my controller!\n");
    return NULL;
}

char *
PJS_GetPackageName(pTHX_ JSContext *cx, JSObject *package)
{
    SV *ref = (SV *)JS_GetInstancePrivate(cx, package, &perlpackage_class, NULL);
    if(ref) return savepv(HvNAME((HV *)SvRV(ref)));
    else {
	jsval pkg;
	if(JS_LookupProperty(cx, package, PJS_PACKAGE_PROP, &pkg) &&
	   JSVAL_IS_STRING(pkg)) {
#if JS_VERSION < 185
	    return JS_GetStringBytes(JSVAL_TO_STRING(pkg));
#else
	    char *pkgname = JS_EncodeString(cx, JSVAL_TO_STRING(pkg));
	    char *copy = savepv(pkgname);
	    JS_free(cx, pkgname);
	    return copy;
#endif
	}
    }
    return NULL;
}

static JSBool perlobj_get(
    JSContext *cx,
    JSObject *obj,
    pjsid id,
    jsval *vp
) {
    // dTHX;
    SV *ref = (SV *)JS_GetPrivate(cx, obj);
    SV *sv = SvRV(ref);
    if(SvTYPE(sv) == SVt_PVHV)
	return (perlhash_class.getProperty)(cx, obj, id, vp);
    else if(SvTYPE(sv) == SVt_PVAV)
	return (perlarray_class.getProperty)(cx, obj, id, vp);
    return JS_TRUE;
}

static JSBool perlobj_set(
    JSContext *cx,
    JSObject *obj,
    pjsid id,
    DEFSTRICT_
    jsval *vp
) {
    dTHX;
    SV *ref = (SV *)JS_GetPrivate(cx, obj);
    SV *sv = SvRV(ref);
    JSBool ok = TRUE;
    if(SvTYPE(sv) == SVt_PVHV && PJSID_IS(STRING, id)) {
	SV *svk;
	ENTER; SAVETMPS;
	svk = PJS_JSString2SV(aTHX_ cx, PJSID_TO(STRING, id));
	sv_2mortal(svk);
	if(hv_exists_ent((HV *)sv, svk, 0)) {
	    SV *nsv;
	    if(!PJS_ReflectJS2Perl(aTHX_ cx, *vp, &nsv, 1)) ok = JS_FALSE;
	    if(ok && hv_store_ent((HV *)sv, svk, nsv, 0) == NULL) {
		if(SvSMAGICAL((HV *)sv)) mg_set(nsv);
		else ok = JS_FALSE; // TODO: Check error to report
	    }
	}
	FREETMPS; LEAVE;
    }
    else if(SvTYPE(sv) == SVt_PVAV) {
	return (perlarray_class.setProperty)(cx, obj, PASSTRICT_ id, vp);
    }
    return ok;
}

JSClass perlobj_class = {
    "PerlObject", JSCLASS_PRIVATE_IS_PERL,
    JS_PropertyStub, JS_PropertyStub, perlobj_get, perlobj_set,
    JS_EnumerateStub, JS_ResolveStub, JS_ConvertStub, PJS_unrootJSVis,
    JSCLASS_NO_OPTIONAL_MEMBERS
};

JSObject *
PJS_NewPerlObject(pTHX_ JSContext *cx, JSObject *parent, SV *objref)
{
    JSObject *newobj = NULL;
    char *stname = HvNAME(SvSTASH(SvRV(objref)));
    JSObject *stash = PJS_GetPackageObject(aTHX_ cx, stname);
    
    if(stash) {
	JSClass *impl = &perlobj_class;
	JSObject *proto = NULL;
	jsval tmp;

	JS_LookupProperty(cx, stash, PJS_PROXY_PROP, &tmp);
	if(JSVAL_IS_OBJECT(tmp)) {
	    JSClass *cls = PJS_GET_CLASS(cx, proto = JSVAL_TO_OBJECT(tmp));
	    if(strNE(cls->name, "Object")) impl = cls;
	    PJS_DEBUG1("A new %s\n", impl->name);
	}
	else croak("Not an object!\n");

	newobj = JS_NewObject(cx, impl, proto, parent);
	return PJS_CreateJSVis(aTHX_ cx, newobj, objref);
    }
    return NULL;
}
