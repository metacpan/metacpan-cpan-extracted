#include "XSUB.h"

#include "JavaScript_Env.h"

#include "PJS_Context.h"
#include "PJS_Class.h"
#include "PJS_PerlArray.h"

static void perlarray_finalize(JSContext *cx, JSObject *obj);
static JSBool PerlArray(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval);

static JSBool perlarray_push(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval);
static JSBool perlarray_unshift(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval);
static JSBool perlarray_shift(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval);
static JSBool perlarray_pop(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval);

static JSBool perlarray_get(JSContext *cx, JSObject *obj, jsval id, jsval *vp);
static JSBool perlarray_set(JSContext *cx, JSObject *obj, jsval id, jsval *vp);
static JSBool perlarray_property_length(JSContext *cx, JSObject *obj, jsval id, jsval *vp);

static const char *PerlArrayPkg = "JavaScript::PerlArray";

static JSClass perlarray_class = {
    "PerlArray", JSCLASS_HAS_PRIVATE,
    JS_PropertyStub, JS_PropertyStub,
    perlarray_get, perlarray_set,
    JS_EnumerateStub, JS_ResolveStub,
    JS_ConvertStub, perlarray_finalize,
    JSCLASS_NO_OPTIONAL_MEMBERS
};

static JSPropertySpec perlarray_props[] = {
    {"length", 0, JSPROP_READONLY | JSPROP_PERMANENT, perlarray_property_length, 0 },
    {0, 0, 0, 0, 0}
};

static JSFunctionSpec perlarray_methods[] = {
    {"push", perlarray_push, 1, 0, 0},
    {"unshift", perlarray_unshift, 1, 0, 0},
    {"shift", perlarray_shift, 0, 0, 0},
    {"pop", perlarray_pop, 0, 0, 0},
    {0, 0, 0, 0 ,0}
};

PJS_PerlArray * PJS_NewPerlArray() {
    dTHX;
    PJS_PerlArray *obj;
    
    Newz(1, obj, 1, PJS_PerlArray);
    obj->av = newAV();
    
    return obj;
}

JSObject *PJS_InitPerlArrayClass(PJS_Context *pcx, JSObject *global) {
    dTHX;
    PJS_Class *cls;
    
    Newz(1, cls, 1, PJS_Class);
    
    cls->pkg  = savepv(PerlArrayPkg);
    cls->clasp = &perlarray_class;
    
    cls->proto = JS_InitClass(
        pcx->cx, global, NULL, &perlarray_class, PerlArray, 0, 
        perlarray_props, perlarray_methods,
        NULL, NULL
    );
    
    PJS_store_class(pcx, cls);
    
    return cls->proto;
}

static void perlarray_finalize(JSContext *cx, JSObject *obj) {
    dTHX;
    SV *self = (SV *) JS_GetPrivate(cx, obj);
    SvREFCNT_dec(self);
}

static JSBool PerlArray(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval) {
    dTHX;
    PJS_PerlArray *arr = PJS_NewPerlArray();

    SV *sv = newSV(0);
    sv_setref_pv(sv, "JavaScript::PerlArray", (void*) arr);
    JS_SetPrivate(cx, obj, (void *) sv); 
    
    return JS_TRUE;
}

static JSBool perlarray_push(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval) {
    dTHX;
    IV tmp = SvIV((SV *) SvRV((SV *) JS_GetPrivate(cx, obj)));
    PJS_PerlArray *arr = INT2PTR(PJS_PerlArray *, tmp);
    AV *av = arr->av;
    
    if (argc) {
        for (tmp = 0; tmp < argc; tmp++) {
            SV *sv = newSV(0);
            if (JSVALToSV(cx, NULL, argv[tmp], &sv) != JS_TRUE) {
                JS_ReportError(cx, "Failed to convert argument %d to Perl", tmp);
                return JS_FALSE;
            }
            av_push(av, sv);
        }
    }
    
    return JS_TRUE;
}

static JSBool perlarray_unshift(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval) {
    dTHX;
    IV tmp = SvIV((SV *) SvRV((SV *) JS_GetPrivate(cx, obj)));
    PJS_PerlArray *arr = INT2PTR(PJS_PerlArray *, tmp);
    AV *av = arr->av;
    
    if (argc) {
        av_unshift(av, argc);
        for (tmp = 0; tmp < argc; tmp++) {
            SV *sv = newSV(0);
            if (JSVALToSV(cx, NULL, argv[tmp], &sv) != JS_TRUE) {
                JS_ReportError(cx, "Failed to convert argument %d to Perl", tmp);
                return JS_FALSE;
            }
            av_store(av, tmp, sv);
        }
    }
    
    return JS_TRUE;
}

static JSBool perlarray_shift(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval) {
    dTHX;
    IV tmp = SvIV((SV *) SvRV((SV *) JS_GetPrivate(cx, obj)));
    PJS_PerlArray *arr = INT2PTR(PJS_PerlArray *, tmp);
    AV *av = arr->av;
    
    SV *sv = av_shift(av);
    
    if (sv == NULL || sv == &PL_sv_undef) {
        *rval = JSVAL_VOID;
        return JS_TRUE;
    }
    
    PJS_ConvertPerlToJSType(cx, NULL, obj, sv, rval);
    
    return JS_TRUE;
}

static JSBool perlarray_pop(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval) {
    dTHX;
    IV tmp = SvIV((SV *) SvRV((SV *) JS_GetPrivate(cx, obj)));
    PJS_PerlArray *arr = INT2PTR(PJS_PerlArray *, tmp);
    AV *av = arr->av;
    
    SV *sv = av_pop(av);
    
    if (sv == NULL || sv == &PL_sv_undef) {
        *rval = JSVAL_VOID;
        return JS_TRUE;
    }
    
    PJS_ConvertPerlToJSType(cx, NULL, obj, sv, rval);
    
    return JS_TRUE;
}

static JSBool perlarray_get(JSContext *cx, JSObject *obj, jsval id, jsval *vp) {
    dTHX;
    IV tmp = SvIV((SV *) SvRV((SV *) JS_GetPrivate(cx, obj)));
    PJS_PerlArray *arr = INT2PTR(PJS_PerlArray *, tmp);
    AV *av = arr->av;
    
    if (JSVAL_IS_INT(id)) {
        IV ix = JSVAL_TO_INT(id);
        SV **v;
        v = av_fetch(av, ix, 0);
        if (v != NULL) {
            PJS_ConvertPerlToJSType(cx, NULL, obj, *v, vp);
        }
        else {
            JS_ReportError(cx, "Failed to retrieve element at index: %d", ix);
            return JS_FALSE;
        }
    }
    
    return JS_TRUE;
}

static JSBool perlarray_set(JSContext *cx, JSObject *obj, jsval id, jsval *vp) {
    dTHX;
    IV tmp = SvIV((SV *) SvRV((SV *) JS_GetPrivate(cx, obj)));
    PJS_PerlArray *arr = INT2PTR(PJS_PerlArray *, tmp);
    AV *av = arr->av;
    
    if (JSVAL_IS_INT(id)) {
        IV ix = JSVAL_TO_INT(id);
        SV *sv = newSV(0);
        
        if (JSVALToSV(cx, NULL, *vp, &sv) != JS_TRUE) {
            JS_ReportError(cx, "Failed to convert argument %d to Perl", tmp);
            return JS_FALSE;
        }    
        
        av_store(av, ix, sv);
    }
    
    return JS_TRUE;
}


static JSBool perlarray_property_length(JSContext *cx, JSObject *obj, jsval id, jsval *vp) {
    dTHX;
    IV tmp = SvIV((SV *) SvRV((SV *) JS_GetPrivate(cx, obj)));
    PJS_PerlArray *arr = INT2PTR(PJS_PerlArray *, tmp);
    AV *av = arr->av;
    I32 len = av_len(av) + 1;
    
    *vp = INT_TO_JSVAL(len);
    
    return JS_TRUE;
}