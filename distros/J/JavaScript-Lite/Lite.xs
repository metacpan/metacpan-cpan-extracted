#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#define XP_UNIX
#define INCLUDES_IN_MOZJS
#define JS_THREADSAFE

#include <jsapi.h>

jsval build_value(JSContext* , SV*);

/* Global class, does nothing */
static JSClass global_class = {
    "global", 0,
    JS_PropertyStub,  JS_PropertyStub,  JS_PropertyStub,  JS_PropertyStub,
    JS_EnumerateStub, JS_ResolveStub,   JS_ConvertStub,   JS_FinalizeStub,
    JSCLASS_NO_OPTIONAL_MEMBERS
};

typedef struct xsjs_err {
  char* file;
  char* message;
  int32 line;
} xsjs_err;

typedef struct xsjs_appdata {
  SV*               branch_callback;
  unsigned long     branch_interval;
  unsigned long     branch_counter;
} xsjs_appdata;

const xsjs_err unknown_err = { "(null)", "(null)", 0 };

typedef struct xsjs_rv {
  JSBool succ;
  jsval  rv;
} xsjs_rv;

xsjs_err get_error(JSContext* cx) {
  xsjs_err rv = unknown_err;
  jsval val;
  JSObject* eobj;
  JSString* sobj;

  if(JS_IsExceptionPending(cx) == JS_FALSE) {
    rv.message = "(no exception)";
    return rv;
  }
  
  JS_GetPendingException(cx, &val);

  if(JSVAL_IS_OBJECT(val)) {
    eobj = JSVAL_TO_OBJECT(val);
    if(JS_GetProperty(cx, eobj, "message", &val) == JS_TRUE) {
      if((sobj = JS_ValueToString(cx, val))) {
        rv.message = JS_GetStringBytes(sobj);
      } else {
        rv.message = "(failed to retrieve exception)";
      }
    } else {
      rv.message = "(unknown exception)";
    }

    if(JS_GetProperty(cx, eobj, "fileName", &val) == JS_TRUE) {
      if((sobj = JS_ValueToString(cx, val))) {
        rv.file = JS_GetStringBytes(sobj);
      } else {
        rv.file = "(failed to retrieve filename)";
      }
    } else {
      rv.file = "(unknown)";
    }

    if(JS_GetProperty(cx, eobj, "lineNumber", &val) == JS_TRUE) {
      if(JS_ValueToInt32(cx, val, &(rv.line)) == JS_FALSE) rv.line = 0;
    }
  } else {
    rv.message = "(invalid exception)";
  }

  return rv;
}

xsjs_rv run_eval(JSContext* cx, const char* str, const char* fname) {
  JSObject* g = JS_GetGlobalObject(cx);
  JSScript* scr = JS_CompileScript(cx, g, str, strlen(str), fname, 1);
  xsjs_rv rv;

  if(scr) {
    rv.succ = JS_ExecuteScript(cx, g, scr, &(rv.rv));
  } else {
    rv.succ = JS_FALSE;
    rv.rv = JSVAL_VOID;
  }

  return rv;
}

char* get_key_name(HE* hashent) {
  SV* keysv;
  char* keyname;
  keysv = HeSVKEY(hashent);
    
  if (keysv) {
    keyname = SvPVbyte(keysv, SvLEN( keysv ) );
  } else {
    keyname = HeKEY(hashent);
  }
    
  return keyname;
}

jsval build_string(JSContext* cx, SV* v) {
  jsdouble js_nv;
  jsval js_v;
  STRLEN len;
  char* c_sv;
  JSBool succ;
  JSString *js_s;

  if(SvOK(v)) {
    if(SvIOK(v) || SvNOK(v)) {
      js_nv = SvNV(v);
      succ = JS_NewDoubleValue(cx, js_nv, &js_v);
      if(succ == JS_FALSE) {
        croak("Failed to create a new number value!");
        return JSVAL_VOID;
      }
    } else {
      c_sv = SvPV(v, len);
      if((js_s = JS_NewStringCopyN(cx, c_sv, len))) {
        js_v = STRING_TO_JSVAL(js_s);
      } else {
        croak("Failed to create a new string value!");
        return JSVAL_VOID;
      }
    }
  } else {
    js_v = JSVAL_NULL;
  }

  return js_v;
}

jsval
build_hash(cx,hv)
  JSContext *cx;
  HV *hv;
{
  HE* i;
  char* k;
  SV* v;
  jsval jval;
  jsval rv;
  JSBool succ;

  JSObject* rvo = JS_NewObject(cx, NULL, NULL, NULL);

  if(!rvo) {
    croak("Failed to instantiate a JavaScript object!");
    return JSVAL_VOID;
  }

  hv_iterinit(hv);

  while((i = hv_iternext(hv)) != NULL) {
    k = get_key_name(i);
    v = (SV *)hv_iterval(hv, i);
    jval = build_value(cx, v);
    succ = JS_SetProperty(cx, rvo, k, &jval);
    if(succ == JS_FALSE) {
      croak("Failed to assign property '%s'!", k);
      return JSVAL_VOID;
    }
  }

  rv = OBJECT_TO_JSVAL(rvo);
  return rv;
}

jsval
build_array(cx,av)
  JSContext *cx;
  AV *av;
{
  JSObject* rvo = JS_NewArrayObject(cx, 0, NULL);
  jsval rv;
  SV** entry;
  jsval jsentry;
  int i;
  JSBool succ;

  for(i=0;i<=av_len(av);i++) {
    entry = av_fetch(av, i, 0);
    if(*entry) {
      jsentry = build_value(cx, *entry);
      succ = JS_SetElement(cx, rvo, i, &jsentry);
      if(succ == JS_FALSE) {
        croak("Failed to assign array entry #%d!", i);
        return JSVAL_VOID;
      }
    } else {
      croak("Entry #%d of array not found!", i);
      return JSVAL_VOID;
    }
  }

  rv = OBJECT_TO_JSVAL(rvo);
  return rv;  
}

jsval
build_value(cx,v)
  JSContext *cx;
  SV *v;
{
  jsval jval;

  if(SvOK(v)) {
    if(SvROK(v)) {
      switch(SvTYPE(SvRV(v))) {
        case SVt_PVAV:
          jval = build_array(cx, (AV*)(SvRV(v)));
          break;
        case SVt_PVHV:
          jval = build_hash(cx, (HV*)(SvRV(v)));
          break;
        default:
          croak("Cannot dereference %p!", v);
          jval = JSVAL_VOID;
      }
    } else {
      jval = build_string(cx, v);
    }
  } else {
    jval = JSVAL_NULL;
  }

  return jval;  
}

JSBool run_branch_callback(cx, script)
  JSContext *cx;
  JSScript *script;
{
  xsjs_appdata* appdata = JS_GetRuntimePrivate(JS_GetRuntime(cx));

  appdata->branch_counter ++;

  if(appdata->branch_counter >= appdata->branch_interval) {
    SV* rv;
    bool rv_b;
    int count;

    appdata->branch_counter = 0;

    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);

    count = call_sv(appdata->branch_callback, G_SCALAR | G_EVAL);

    SPAGAIN;

    if(SvTRUE(ERRSV)) {
      STRLEN n_a;
      JS_ReportError(cx, "Branch Callback failed: %s", SvPV(ERRSV, n_a));
      rv_b = 0;
    } else {
      if(count == 0) {
        rv_b = 0;
      } else if(count != 1) {
        croak("Bad arguments!");
      } else {
        rv = POPs;
        rv_b = SvTRUE(rv);
        if(!rv_b) {
          JS_ReportError(cx, "Branch Callback aborted script");
        }
      }
    }

    PUTBACK;
    FREETMPS;
    LEAVE;

    if(rv_b) {
      return JS_TRUE;
    } else {
      return JS_FALSE;
    }
  } else {
    return JS_TRUE;
  }
}

void
set_branch_callback(cx,cb,interval)
  JSContext *cx;
  unsigned long interval;
  SV *cb;
{
  xsjs_appdata *appdata = JS_GetRuntimePrivate(JS_GetRuntime(cx));

  if(appdata->branch_callback) {
    croak("branch callback has already been set");
  }

  SvREFCNT_inc(cb);
  appdata->branch_callback = cb;
  appdata->branch_interval = interval;
  appdata->branch_counter = 0;

  JS_SetBranchCallback(cx, run_branch_callback);
}

void
clear_branch_callback(cx)
  JSContext *cx;
{
  xsjs_appdata* appdata = JS_GetRuntimePrivate(JS_GetRuntime(cx));

  if(appdata->branch_callback) {
    SvREFCNT_dec(appdata->branch_callback);
    appdata->branch_callback = NULL;
    appdata->branch_interval = 0;
    appdata->branch_counter = 0;
    JS_SetBranchCallback(cx, NULL);
  }
}

void
assign_property(cx,obj,k,v)
  JSContext *cx;
  JSObject *obj;
  const char *k;
  SV *v;
{
  JSBool succ;
  jsval jval = build_value(cx, v);
  succ = JS_SetProperty(cx, obj, k, &jval);
  if(succ == JS_FALSE) {
    croak("Failed to assign property '%s'!", k);
  }
}

MODULE = JavaScript::Lite       PACKAGE = JavaScript::Lite

void
assign(cx,k,v)
    JSContext *cx;
    const char *k;
    SV *v;
  PREINIT:
    JSObject* jobj;
  CODE:
    if((jobj = JS_GetGlobalObject(cx))) {
      assign_property(cx, jobj, k, v);
    } else {
      croak("Failed to get JavaScript global object!");
    }

void
assign_property(cx,n,k,v)
    JSContext *cx;
    const char *n;
    const char *k;
    SV *v;
  PREINIT:
    JSObject* gobj;
    JSObject* jobj;
    jsval jobjv;
    JSBool rv;
  CODE:
    if((gobj = JS_GetGlobalObject(cx))) {
      rv = JS_GetProperty(cx, gobj, n, &jobjv);
      if(rv == JS_FALSE)
        croak("Failed to find an object named '%s'!", n);
      if(!JSVAL_IS_OBJECT(jobjv))
        croak("Global property '%s' is not an object!", n);
      jobj = JSVAL_TO_OBJECT(jobjv);
      assign_property(cx,jobj,k,v);
    } else {
      croak("Failed to get JavaScript global object!");
    }

void
clear_error(cx)
    JSContext *cx;
  CODE:
    JS_ClearPendingException(cx);

void
eval_void(cx, str, fname)
    JSContext *cx;
    const char *str;
    const char *fname;
  PREINIT:
    xsjs_rv rv;
    xsjs_err err;
  CODE:
    rv = run_eval(cx, str, fname);
    if(rv.succ == JS_FALSE) {
      err = get_error(cx);
      croak("JavaScript: %s at %s line %d", err.message, err.file, err.line);
    }

SV*
eval_js(cx, str, fname)
    JSContext* cx;
    const char* str;
    const char* fname;
  PREINIT:
    char* rv_str;
    JSString* s_rval;
    xsjs_rv rv;
    xsjs_err err;
  CODE:
    rv = run_eval(cx, str, fname);
    if(rv.succ == JS_FALSE) {
      err = get_error(cx);
      croak("JavaScript: %s at %s line %d", err.message, err.file, err.line);
    }
    if(JSVAL_IS_NULL(rv.rv) || JSVAL_IS_VOID(rv.rv)) {
      XSRETURN_UNDEF;
    }
    if((s_rval = JS_ValueToString(cx, rv.rv))) {
      if((rv_str = JS_GetStringBytes(s_rval))) {
        RETVAL = newSVpv(rv_str, 0);
      } else {
        croak("Failed to convert return value of JavaScript function '%s'!", fname);
      }
    } else {
      croak("Failed to obtain return value of JavaScript function '%s'!", fname);
    }
  OUTPUT:
    RETVAL

JSContext *
create(const char* class_name, long maxmem)
  PREINIT:
    JSRuntime* rt;
    JSContext* cx;
    JSObject* gobj;
    xsjs_appdata* appdata;
  CODE:
    rt = JS_NewRuntime(maxmem);
    if(rt == NULL)
      croak("%s: Failed to create JavaScript runtime!", class_name);
    cx = JS_NewContext(rt, 8192);
    if(cx == NULL)
      croak("%s: Failed to create JavaScript context!", class_name);
#ifdef JSOPTION_DONT_REPORT_UNCAUGHT
    JS_SetOptions(cx, JSOPTION_DONT_REPORT_UNCAUGHT);
#endif
    gobj = JS_NewObject(cx, &global_class, NULL, NULL);
    if(!gobj)
      croak("%s: Failed to create the global object", class_name);
    if (JS_InitStandardClasses(cx, gobj) == JS_FALSE)
      croak("%s: Standard classes not loaded properly.", class_name);
    JS_SetGlobalObject(cx, gobj);
    appdata = malloc(sizeof(xsjs_appdata));
    memset(appdata, 0, sizeof(xsjs_appdata));
    JS_SetRuntimePrivate(rt, appdata);

    RETVAL = cx;
  OUTPUT:
    RETVAL

void branch_callback(cx, callback, interval=0)
    JSContext*  cx;
    SV* callback;
    unsigned long interval;
  CODE:
    if(SvTRUE(callback)) {
      set_branch_callback(cx, callback, interval);
    } else {
      clear_branch_callback(cx);
    }

void clear_branch_counter(cx)
    JSContext* cx
  CODE:
    xsjs_appdata* appdata = JS_GetRuntimePrivate(JS_GetRuntime(cx));
    appdata->branch_counter = 0;

char* invoke(cx, name)
    JSContext*  cx;
    const char* name;
  PREINIT:
    jsval       fval;
    jsval       rval;
    JSObject*   global;
    JSBool      rv;  
    JSString*   s_rval;
    xsjs_err    err;
  CODE:
    if((global = JS_GetGlobalObject(cx))) {
      rv = JS_GetProperty(cx, global, name, &fval);
      if(rv == JS_FALSE)
        croak("Failed to find global javascript function '%s'!", name);
      if(JSVAL_IS_OBJECT(fval) && JS_ObjectIsFunction(cx, JSVAL_TO_OBJECT(fval))) {
        rv = JS_CallFunctionValue(cx, global, fval, 0, NULL, &rval);
        if(rv == JS_FALSE) {
          err = get_error(cx);
          croak("JavaScript: %s at %s line %d", err.message, err.file, err.line);
        }
        if(JSVAL_IS_NULL(rval) || JSVAL_IS_VOID(rval))
          XSRETURN_UNDEF;
        if((s_rval = JS_ValueToString(cx, rval))) {
          RETVAL = JS_GetStringBytes(s_rval);
        } else {
          croak("Failed to obtain return value from '%s'!", name);
        }
      } else {
        croak("Failed to convert '%s' into a function!", name);
      }
    } else {
      croak("Failed to find JavaScript global object!");
    }
  OUTPUT:
    RETVAL

void collect(cx)
    JSContext* cx;
  CODE:
    JS_MaybeGC(cx);

void DESTROY(cx)
    JSContext* cx;
  PREINIT:
    JSRuntime* rt;
    xsjs_appdata* appdata;
  CODE:
    rt = JS_GetRuntime(cx);
    clear_branch_callback(cx);
    appdata = (xsjs_appdata*) JS_GetRuntimePrivate(rt);
    JS_SetRuntimePrivate(rt, NULL);
    if(appdata) free(appdata);
    JS_DestroyContext(cx);
    JS_DestroyRuntime(rt);

