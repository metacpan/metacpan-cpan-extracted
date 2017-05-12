#include "XSUB.h"

#include "JavaScript_Env.h"

#include "PJS_Context.h"
#include "PJS_Class.h"
#include "PJS_PerlSub.h"

static PJS_PerlSub * PJS_NewPerlSub();
static void perlsub_finalize(JSContext *cx, JSObject *obj);
static JSBool perlsub_call(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval);
static JSBool perlsub_apply(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval);

static const char *PerlSubPkg = "JavaScript::PerlSub";

static JSClass perlsub_class = {
    "PerlSub", JSCLASS_HAS_PRIVATE,
    JS_PropertyStub, JS_PropertyStub,
    JS_PropertyStub, JS_PropertyStub,
    JS_EnumerateStub, JS_ResolveStub,
    JS_ConvertStub, perlsub_finalize,
    NULL,
    NULL,
    perlsub_call,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL
};

static JSPropertySpec perlsub_props[] = {
    {0, 0, 0, 0, 0}
};

static JSFunctionSpec perlsub_methods[] = {
  {"apply", perlsub_apply, 2, 0, 0},
  {0, 0, 0, 0 ,0}
};

PJS_PerlSub * PJS_NewPerlSub() {
    dTHX;
    PJS_PerlSub *obj;
    
    Newz(1, obj, 1, PJS_PerlSub);
    obj->cv = NULL;
    
    return obj;
}

JSObject * PJS_NewPerlSubObject(JSContext *cx, JSObject *parent, SV *ref) {
    dTHX;
    JSObject *obj = JS_NewObject(cx, &perlsub_class, NULL, parent);
    PJS_PerlSub *sub = PJS_NewPerlSub();
    sub->cv = SvREFCNT_inc(ref);
    SV *sv = newSV(0);
    sv_setref_pv(sv, "JavaScript::PerlSub", (void*) sub);
    JS_SetPrivate(cx, obj, (void *) sv); 
    
    return obj;
    
}

JSObject *PJS_InitPerlSubClass(PJS_Context *pcx, JSObject *global) {
    dTHX;
    PJS_Class *cls;
    
    Newz(1, cls, 1, PJS_Class);
    
    cls->pkg  = savepv(PerlSubPkg);
    cls->clasp = &perlsub_class;
    
    cls->proto = JS_InitClass(
        pcx->cx, global, NULL, &perlsub_class, NULL, 0, 
        perlsub_props, perlsub_methods,
        NULL, NULL
    );
    
    PJS_store_class(pcx, cls);
    
    return cls->proto;
}

static void perlsub_finalize(JSContext *cx, JSObject *obj) {
    dTHX;
    SV *self = (SV *) JS_GetPrivate(cx, obj);
    if (self) {
        IV tmp = SvIV((SV *) SvRV((SV *) self));
        PJS_PerlSub *sub = INT2PTR(PJS_PerlSub *, tmp);
        SvREFCNT_dec(sub->cv);
        SvREFCNT_dec(self);
    }
}

static JSBool perlsub_apply(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval) {
  dTHX;

  jsuint jsarrlen;
  jsuint index;
  jsval *arg_list;
  jsval elem;

  JSObject *object = JSVAL_TO_OBJECT(argv[1]);

  /* flatten the array, as perl wants $this, arg1, arg2, arg3, etc... */
  JS_GetArrayLength(cx, object, &jsarrlen);
  Newz(1, arg_list, jsarrlen + 1, jsval);
  arg_list[0] = argv[0];
  for ( index = 0; index < jsarrlen; index++ ) {
    JS_GetElement(cx, object, index, &elem);
    arg_list[index+1] = elem;
  }

  SV *fn = (SV *) JS_GetPrivate(cx, (JSObject *) obj);
  if (fn != NULL) {
    IV tmp = SvIV((SV *) SvRV((SV *) fn));
    PJS_PerlSub *sub = INT2PTR(PJS_PerlSub *, tmp);
    if (perl_call_sv_with_jsvals(cx, obj, sub->cv, NULL, jsarrlen+1, arg_list, rval) < 0) {
      return JS_FALSE;
    }
    
    return JS_TRUE;
  }
    
    return JS_FALSE;
}

static JSBool perlsub_call(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval) {
    dTHX;
    SV *self = (SV *) JS_GetPrivate(cx, (JSObject *) argv[-2]);
    if (self != NULL) {
        IV tmp = SvIV((SV *) SvRV((SV *) self));
        PJS_PerlSub *sub = INT2PTR(PJS_PerlSub *, tmp);
        if (perl_call_sv_with_jsvals(cx, obj, sub->cv, NULL, argc, argv, rval) < 0 || JS_IsExceptionPending(cx)) {
            return JS_FALSE;
        }
        
        return JS_TRUE;
    }
    
    return JS_FALSE;
}
