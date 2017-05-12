#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "JavaScript_Env.h"

#include "PJS_Class.h"
#include "PJS_Types.h"
#include "PJS_Context.h"
#include "PJS_Property.h"
#include "PJS_Function.h"
#include "PJS_Common.h"

PJS_Function * PJS_get_method_by_name(PJS_Class *cls, const char *name) {
    PJS_Function *ret;
    
    ret = cls->methods;

    while(ret != NULL) {
        if(strcmp(ret->name, name) == 0) {
            return ret;
        }
        
        ret = ret->_next;
    }
    
    return NULL;
}

PJS_Property *PJS_get_property_by_id(PJS_Class *pcls, int8 tinyid) {
    PJS_Property *prop;
    
    prop = pcls->properties;
    
    while(prop != NULL) {
        if (prop->tinyid == tinyid) {
            return prop;
        }
        
        prop = prop->_next;
    }
    
    return NULL;
}

/*
  Free memory occupied by PJS_Class structure
*/
void PJS_free_class(PJS_Class *pcls) {
    PJS_Function *method;
    PJS_Property *property;
    if (pcls == NULL) {
        return;
    }

    if (pcls->cons != NULL) {
        SvREFCNT_dec(pcls->cons);
    }

    if (pcls->pkg != NULL) {
        Safefree(pcls->pkg);
    }
    
    method = pcls->methods;
    while (method != NULL) {
        PJS_Function *next = method->_next;
        PJS_DestroyFunction(method);
        method = next;
    }
    PJS_free_JSFunctionSpec(pcls->fs);
    PJS_free_JSFunctionSpec(pcls->static_fs);
    
    property = pcls->properties;
    while (property != NULL) {
        PJS_Property *next = property->_next;
        PJS_free_property(property);
        property = next;
    }
    PJS_free_JSPropertySpec(pcls->ps);
    PJS_free_JSPropertySpec(pcls->static_ps);
    
    /* Seems like SM handles this part for us */
/*    if (pcls->flags & PJS_FREE_JSCLASS) {
        Safefree(pcls->clasp->name);
        Safefree(pcls->clasp);
    }  */
    
    Safefree(pcls);
}

void PJS_bind_class(PJS_Context *pcx, char *name, char *pkg, SV *cons, HV *fs, HV *static_fs, HV *ps, HV *static_ps, U32 flags) {
    PJS_Class *pcls;
    
    if (pcx == NULL) {
        croak("Can't bind_class in an undefined context");
    }

    Newz(1, pcls, 1, PJS_Class);
    if (pcls == NULL) {
        croak("Failed to allocate memory for PJS_Class");
    }

    /* Add "package" */
    Newz(1, pcls->pkg, strlen(pkg) + 1, char);
    if (pcls->pkg == NULL) {
        PJS_free_class(pcls);
        croak("Failed to allocate memory for pkg");
    }
    Copy(pkg, pcls->pkg, strlen(pkg), char);

    /* Create JSClass "clasp" */
    Newz(1, pcls->clasp, 1, JSClass);
    Zero(pcls->clasp, 1, JSClass);
    
    if (pcls->clasp == NULL) {
        PJS_free_class(pcls);
        croak("Failed to allocate memory for JSClass");
    }

    Newz(1, pcls->clasp->name, strlen(name) + 1, char);
    if (pcls->clasp->name == NULL) {
        PJS_free_class(pcls);
        croak("Failed to allocate memory for name in JSClass");
    }
    Copy(name, pcls->clasp->name, strlen(name), char);

    pcls->methods = NULL;
    pcls->properties = NULL;
    
    pcls->clasp->flags = JSCLASS_HAS_PRIVATE;
    pcls->clasp->addProperty = JS_PropertyStub;
    pcls->clasp->delProperty = JS_PropertyStub;  
    pcls->clasp->getProperty = PJS_invoke_perl_property_getter;
    pcls->clasp->setProperty = PJS_invoke_perl_property_setter;
    pcls->clasp->enumerate = JS_EnumerateStub;
    pcls->clasp->resolve = JS_ResolveStub;
    pcls->clasp->convert = JS_ConvertStub;
    pcls->clasp->finalize = PJS_finalize;

    pcls->clasp->getObjectOps = NULL;
    pcls->clasp->checkAccess = NULL;
    pcls->clasp->call = NULL;
    pcls->clasp->construct = NULL;
    pcls->clasp->hasInstance = NULL;

    pcls->next_property_id = 0;
    
    /* Per-object functions and properties */
    pcls->fs = PJS_add_class_functions(pcls, fs, PJS_INSTANCE_METHOD);
    pcls->ps = PJS_add_class_properties(pcls, ps, PJS_INSTANCE_METHOD);
    
    /* Class functions and properties */
    pcls->static_fs = PJS_add_class_functions(pcls, static_fs, PJS_CLASS_METHOD);
    pcls->static_ps = PJS_add_class_properties(pcls, static_ps, PJS_CLASS_METHOD);

    /* Initialize class */
    pcls->proto = JS_InitClass(PJS_GetJSContext(pcx), JS_GetGlobalObject(PJS_GetJSContext(pcx)),
                               NULL, pcls->clasp,
                               PJS_construct_perl_object, 0,
                               pcls->ps /* ps */, pcls->fs,
                               pcls->static_ps /* static_ps */, pcls->static_fs /* static_fs */);
                                                   
    if (pcls->proto == NULL) {
        PJS_free_class(pcls);
        croak("Failed to initialize class in context");
    }

    /* refcount constructor */
    pcls->cons = SvREFCNT_inc(cons);
    pcls->flags |= PJS_FREE_JSCLASS;
    
    PJS_store_class(pcx, pcls);
}

void PJS_store_class(PJS_Context *pcx, PJS_Class *cls) {
    /* Add class to list of classes in contexts */
    SV *sv = newSV(0);
    sv_setref_pv(sv, "JavaScript::PerlClass", (void*) cls);
	
    if (cls->clasp->name != NULL) {
      if(hv_store(pcx->class_by_name, cls->clasp->name, strlen(cls->clasp->name), sv, 0) == NULL) {
        /* TODO: better error here */
        croak("Failed to store class: %s in class_by_name in context", cls->clasp->name);
        return;
      }
    }
    
    if (cls->pkg != NULL) {
      SvREFCNT_inc(sv);
      hv_store(pcx->class_by_package, cls->pkg, strlen(cls->pkg), sv, 0);
    }
}

void PJS_finalize(JSContext *cx, JSObject *obj) {
    void *ptr = JS_GetPrivate(cx, obj);

    if(ptr != NULL) {
        if (SvTYPE((SV *) ptr) == SVt_RV) {
            SvREFCNT_dec(SvRV((SV *) ptr));
        }
    }
}

/* Universal call back for functions */
JSBool PJS_construct_perl_object(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval) {
    PJS_Class *pcls;
    PJS_Context *pcx;
    JSFunction *jfunc = PJS_FUNC_SELF;
    char *name;
    
    if ((pcx = PJS_GET_CONTEXT(cx)) == NULL) {
        JS_ReportError(cx, "Can't find context %d", cx);
        return JS_FALSE;
    }

    name = (char *) JS_GetFunctionName(jfunc);
    
    if ((pcls = PJS_GetClassByName(pcx, name)) == NULL) {
        JS_ReportError(cx, "Can't find class %s", name);
        return JS_FALSE;
    }

    /* Check if we are allowed to instanciate this class */
    if (pcls->flags & PJS_CLASS_NO_INSTANCE) {
        JS_ReportError(cx, "Class '%s' can't be instanciated", pcls->clasp->name);
        return JS_FALSE;
    }

    if (SvROK(pcls->cons)) {
        SV *rsv;
        SV *pkg = newSVpv(pcls->pkg, 0);
        if (perl_call_sv_with_jsvals_rsv(cx, obj, pcls->cons, pkg, argc, argv, &rsv) < 0) {
            /* We must have thrown an exception */
            return JS_FALSE;
        }
                
        JS_SetPrivate(cx, obj, (void *) rsv); 
    }
    
    return JS_TRUE;
}

JSPropertySpec *PJS_add_class_properties(PJS_Class *pcls, HV *ps, U8 flags) {
    JSPropertySpec *ps_list, *current_ps;
    PJS_Property *pprop;
    HE *entry;
    char *name;
    I32 len;
    AV *callbacks;
    SV **getter, **setter;
    
    I32 number_of_keys = hv_iterinit(ps);

    Newz(1, ps_list, number_of_keys + 1, JSPropertySpec);

    current_ps = ps_list;

    while((entry = hv_iternext(ps)) != NULL) {
        name = hv_iterkey(entry, &len);
        callbacks = (AV *) SvRV(hv_iterval(ps, entry));

        len = strlen(name);
        
        Newz(1, pprop, 1, PJS_Property);
        if (pprop == NULL) {
            /* We might need to free more memory stuff here */
            croak("Failed to allocate memory for PJS_Property");
        }

        /* Setup JSFunctionSpec */
        Newz(1, current_ps->name, len + 1, char);
        if (current_ps->name == NULL) {
            Safefree(pprop);
            croak("Failed to allocate memory for JSPropertySpec name");
        }
        Copy(name, current_ps->name, len, char);
        
        getter = av_fetch(callbacks, 0, 0);
        setter = av_fetch(callbacks, 1, 0);

        pprop->getter = getter != NULL && SvTRUE(*getter) ? SvREFCNT_inc(*getter) : NULL;
        pprop->setter = setter != NULL && SvTRUE(*setter) ? SvREFCNT_inc(*setter) : NULL;

        current_ps->getter = PJS_invoke_perl_property_getter;
        current_ps->setter = PJS_invoke_perl_property_setter;
        current_ps->tinyid = pcls->next_property_id++;

        current_ps->flags = JSPROP_ENUMERATE;
        
        if (setter == NULL) {
            current_ps->flags |= JSPROP_READONLY;
        }

        pprop->tinyid = current_ps->tinyid;
        pprop->_next = pcls->properties;
        pcls->properties = pprop;

        current_ps++;
    }
    
    current_ps->name = 0;
    current_ps->tinyid = 0;
    current_ps->flags = 0;
    current_ps->getter = 0;
    current_ps->setter = 0;
        
    return ps_list;
}

JSFunctionSpec *PJS_add_class_functions(PJS_Class *pcls, HV *fs, U8 flags) {
    JSFunctionSpec *fs_list, *current_fs;
    PJS_Function *pfunc;
    HE *entry;
    char *name;
    I32 len;
    SV *callback;
    
    I32 number_of_keys = hv_iterinit(fs);

    Newz(1, fs_list, number_of_keys + 1, JSFunctionSpec);

    current_fs = fs_list;

    while((entry = hv_iternext(fs)) != NULL) {
        name = hv_iterkey(entry, &len);
        callback = hv_iterval(fs, entry);

        len = strlen(name);
        
        Newz(1, pfunc, 1, PJS_Function);
        if (pfunc == NULL) {
            /* We might need to free more memory stuff here */
            croak("Failed to allocate memory for PJS_Function");
        }

        /* Name of function */
        Newz(1, pfunc->name, len + 1, char);
        if (pfunc->name == NULL) {
            Safefree(pfunc);
            croak("Failed to allocate memory for PJS_Function name");
        }
        Copy(name, pfunc->name, len, char);

        /* Setup JSFunctionSpec */
        Newz(1, current_fs->name, len + 1, char);
        if (current_fs->name == NULL) {
            Safefree(pfunc->name);
            Safefree(pfunc);
            croak("Failed to allocate memory for JSFunctionSpec name");
        }
        Copy(name, current_fs->name, len, char);

        current_fs->call = PJS_invoke_perl_object_method;
        current_fs->nargs = 0;
        current_fs->flags = 0;
        current_fs->extra = 0;

        pfunc->callback = SvREFCNT_inc(callback);
        
        /* Add entry to linked list */
        pfunc->_next = pcls->methods;
        pcls->methods = pfunc;
        
        /* Get next function */
        current_fs++;
    }

    current_fs->name = 0;
    current_fs->call = 0;
    current_fs->nargs = 0;
    current_fs->flags = 0;
    current_fs->extra = 0;

    return fs_list;
}

JSBool PJS_invoke_perl_object_method(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval) {
    PJS_Context *pcx;
    PJS_Class *pcls;
    PJS_Function *pfunc;
    JSFunction *jfunc = PJS_FUNC_SELF;
    SV *caller;
    char *name;
    U8 invocation_mode;
    
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

    if (!(pcls = PJS_GetClassByName(pcx, name))) {
        JS_ReportError(cx, "Can't find class '%s'", name);
        return JS_FALSE;
    }

    name = (char *) JS_GetFunctionName(jfunc);

    if((pfunc = PJS_get_method_by_name(pcls, name)) == NULL) {
        JS_ReportError(cx, "Can't find method '%s' in '%s'", name, pcls->clasp->name);
        return JS_FALSE;
    }

    if (invocation_mode) {
        caller = (SV *) JS_GetPrivate(cx, obj);
    }
    else {
        caller = newSVpv(pcls->pkg, 0);
    }

    /* XXX: the original invocation here has slightly different
       retrun value handling.  if the returned value is reference
       same as priv, don't return it.  While the case is not
       covered by the tets */
    
    if (perl_call_sv_with_jsvals(cx, obj, pfunc->callback,
                                 caller, argc, argv, rval) < 0) {
        return JS_FALSE;
    }

    return JS_TRUE;
}

/* Query functions */
const char *
PJS_GetClassName(PJS_Class *clazz) {
    if (clazz == NULL) {
        return NULL;
    }
    
    return clazz->clasp->name;
}

const char *
PJS_GetClassPackage(PJS_Class *clazz) {
    if (clazz == NULL) {
        return NULL;
    }
    
    return clazz->pkg;
}

