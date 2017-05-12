#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "JavaScript_Env.h"

#include "PJS_Context.h"
#include "PJS_Property.h"
#include "PJS_Class.h"
#include "PJS_Types.h"
#include "PJS_Common.h"

void PJS_free_property(PJS_Property *pfunc) {
    dSP;
    if (pfunc == NULL) {
        return;
    }

    if (pfunc->getter != NULL) {
        SvREFCNT_dec(pfunc->getter);
    }

    if (pfunc->setter != NULL) {
        SvREFCNT_dec(pfunc->setter);
    }

    Safefree(pfunc);
}

void PJS_free_JSPropertySpec(JSPropertySpec *ps_list) {
    dSP;
    JSPropertySpec *ps;
    
    if (ps_list == NULL) {
        return;
    }

    for (ps = ps_list; ps->name; ps++) {
        Safefree(ps->name);
    }

    Safefree(ps_list);
}

JSBool PJS_invoke_perl_property_getter(JSContext *cx, JSObject *obj, jsval id, jsval *vp) {
    dSP;
    PJS_Context *pcx;
    PJS_Class *pcls;
    PJS_Property *pprop;
    SV *caller;
    char *name;
    jsint slot;
    U8 invocation_mode;

    if (!JSVAL_IS_INT(id)) {
        return JS_TRUE;
    }
    
    if((pcx = PJS_GET_CONTEXT(cx)) == NULL) {
        JS_ReportError(cx, "Can't find context %d", cx);
        return JS_FALSE;
    }

    if (JS_TypeOfValue(cx, OBJECT_TO_JSVAL(obj)) == JSTYPE_OBJECT) {
        /* Called as instsance */
        JSClass *clasp = PJS_GET_CLASS(cx, obj);
        name = (char *) clasp->name;
        invocation_mode = 1;
    }
    else {
        /* Called as static */
        JSFunction *parent_jfunc = JS_ValueToFunction(cx, OBJECT_TO_JSVAL(obj));
        if (parent_jfunc == NULL) {
            JS_ReportError(cx, "Failed to extract class for static property getter");
            return JS_FALSE;
        }
        name = (char *) JS_GetFunctionName(parent_jfunc);
        invocation_mode = 0;
    }
    
    if ((pcls = PJS_GetClassByName(pcx, name)) == NULL) {
        JS_ReportError(cx, "Can't find class '%s'", name);
        return JS_FALSE;
    }

    slot = JSVAL_TO_INT(id);

    if ((pprop = PJS_get_property_by_id(pcls,  (int8) slot)) == NULL) {
        JS_ReportError(cx, "Can't find property handler");
        return JS_FALSE;
    }

    if (pprop->getter == NULL) {
        JS_ReportError(cx, "Property is write-only");
        return JS_FALSE;
    }

    if (invocation_mode) {
        caller = (SV *) JS_GetPrivate(cx, obj);
    }
    else {
        caller = newSVpv(pcls->pkg, 0);
    }

    if (perl_call_sv_with_jsvals(cx, obj, pprop->getter,
                                 caller, 0, NULL, vp) < 0) {
        return JS_FALSE;
    }

    return JS_TRUE;
}

JSBool PJS_invoke_perl_property_setter(JSContext *cx, JSObject *obj, jsval id, jsval *vp) {
    dSP;
    PJS_Context *pcx;
    PJS_Class *pcls;
    PJS_Property *pprop;
    SV *caller;
    char *name;
    jsint slot;
    U8 invocation_mode;

    if (!JSVAL_IS_INT(id)) {
        return JS_TRUE;
    }
    
    if((pcx = PJS_GET_CONTEXT(cx)) == NULL) {
        JS_ReportError(cx, "Can't find context %d", cx);
        return JS_FALSE;
    }

    if (JS_TypeOfValue(cx, OBJECT_TO_JSVAL(obj)) == JSTYPE_OBJECT) {
        /* Called as instsance */
        JSClass *clasp = PJS_GET_CLASS(cx, obj);
        name = (char *) clasp->name;
        invocation_mode = 1;
    }
    else {
        /* Called as static */
        JSFunction *parent_jfunc = JS_ValueToFunction(cx, OBJECT_TO_JSVAL(obj));
        if (parent_jfunc == NULL) {
            JS_ReportError(cx, "Failed to extract class for static property getter");
            return JS_FALSE;
        }
        name = (char *) JS_GetFunctionName(parent_jfunc);
        invocation_mode = 0;
    }
    
    if ((pcls = PJS_GetClassByName(pcx, name)) == NULL) {
        JS_ReportError(cx, "Can't find class '%s'", name);
        return JS_FALSE;
    }

    slot = JSVAL_TO_INT(id);

    if ((pprop = PJS_get_property_by_id(pcls,  (int8) slot)) == NULL) {
        JS_ReportError(cx, "Can't find property handler");
        return JS_FALSE;
    }

    if (pprop->setter == NULL) {
        JS_ReportError(cx, "Property is read-only");
        return JS_FALSE;
    }

    if (invocation_mode) {
        caller = (SV *) JS_GetPrivate(cx, obj);
    }
    else {
        caller = newSVpv(pcls->pkg, 0);
    }

    if (perl_call_sv_with_jsvals(cx, obj, pprop->setter,
                                 caller, 1, vp, NULL) < 0) {
        return JS_FALSE;
    }

    return JS_TRUE;
}
