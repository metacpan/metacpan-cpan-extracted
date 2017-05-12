#include "XSUB.h"

#include "JavaScript_Env.h"

#include "PJS_Context.h"
#include "PJS_Class.h"
#include "PJS_PerlHash.h"

static void perlhash_finalize(JSContext *cx, JSObject *obj);
static JSBool PerlHash(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval);

static JSBool perlhash_get(JSContext *cx, JSObject *obj, jsval id, jsval *vp);
static JSBool perlhash_set(JSContext *cx, JSObject *obj, jsval id, jsval *vp);

static const char *PerlHashPkg = "JavaScript::PerlHash";

static JSClass perlhash_class = {
    "PerlHash", JSCLASS_HAS_PRIVATE,
    JS_PropertyStub, JS_PropertyStub,
    perlhash_get, perlhash_set,
    JS_EnumerateStub, JS_ResolveStub,
    JS_ConvertStub, perlhash_finalize,
    JSCLASS_NO_OPTIONAL_MEMBERS
};

static JSPropertySpec perlhash_props[] = {
    {0, 0, 0, 0, 0}
};

static JSFunctionSpec perlhash_methods[] = {
    {0, 0, 0, 0 ,0}
};

PJS_PerlHash * PJS_NewPerlHash() {
    dTHX;
    PJS_PerlHash *obj;
    
    Newz(1, obj, 1, PJS_PerlHash);
    obj->hv = newHV();
    
    return obj;
}

JSObject *PJS_InitPerlHashClass(PJS_Context *pcx, JSObject *global) {
    dTHX;
    PJS_Class *cls;
    
    Newz(1, cls, 1, PJS_Class);
    
    cls->pkg  = savepv(PerlHashPkg);
    cls->clasp = &perlhash_class;
    
    cls->proto = JS_InitClass(
        pcx->cx, global, NULL, &perlhash_class, PerlHash, 0, 
        perlhash_props, perlhash_methods,
        NULL, NULL
    );
    
    PJS_store_class(pcx, cls);
    
    return cls->proto;
}

static void perlhash_finalize(JSContext *cx, JSObject *obj) {
    dTHX;
    SV *self = (SV *) JS_GetPrivate(cx, obj);
    SvREFCNT_dec(self);
}

static JSBool PerlHash(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval) {
    dTHX;
    PJS_PerlHash *hash = PJS_NewPerlHash();

    SV *sv = newSV(0);
    sv_setref_pv(sv, "JavaScript::PerlHash", (void*) hash);
    JS_SetPrivate(cx, obj, (void *) sv); 
    
    return JS_TRUE;
}

static JSBool perlhash_get(JSContext *cx, JSObject *obj, jsval id, jsval *vp) {
    dTHX;
    IV tmp = SvIV((SV *) SvRV((SV *) JS_GetPrivate(cx, obj)));
    PJS_PerlHash *hash = INT2PTR(PJS_PerlHash *, tmp);
    HV *hv = hash->hv;
    SV **v;
    const char *key;
    
    if (!JSVAL_IS_STRING(id)) {
        return JS_FALSE;
    }

    key = JS_GetStringBytes(JSVAL_TO_STRING(id));
    v = hv_fetch(hv, key, strlen(key), 0);
    if (v != NULL) {
        PJS_ConvertPerlToJSType(cx, NULL, obj, *v, vp);
    }
    else {
        *vp = JSVAL_NULL;
    }
    
    return JS_TRUE;
}

static JSBool perlhash_set(JSContext *cx, JSObject *obj, jsval id, jsval *vp) {
    dTHX;
    IV tmp = SvIV((SV *) SvRV((SV *) JS_GetPrivate(cx, obj)));
    PJS_PerlHash *hash = INT2PTR(PJS_PerlHash *, tmp);
    HV *hv = hash->hv;
    SV *sv;
    const char *key;

    if (!JSVAL_IS_STRING(id)) {
        return JS_FALSE;
    }

    key = JS_GetStringBytes(JSVAL_TO_STRING(id));
    sv = newSV(0);

    if (JSVALToSV(cx, NULL, *vp, &sv) != JS_TRUE) {
        JS_ReportError(cx, "Failed to convert argument %d to Perl", tmp);
        return JS_FALSE;
    }    

    hv_store(hv, key, strlen(key), sv, 0);
    
    return JS_TRUE;
}


