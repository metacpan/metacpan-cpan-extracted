#include "JS.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct PJS_Class PJS_Class;
typedef struct PJS_Function PJS_Function;
typedef struct PJS_Property PJS_Property;

struct PJS_Class {
    /* Clasp */
    JSClass *clasp;
	
    /* Package name in Perl */
    char *pkg;
      
    /* Reference to Perl subroutine that returns an instance of the object */
    SV *cons;

    /* Reference to prototype object */
    JSObject *proto;

    /* Linked list of methods bound to class */
    PJS_Function *methods;
    JSFunctionSpec *fs;
    JSFunctionSpec *static_fs;
    
    /* Linked list of properties bound to class */
    int8 next_property_id;
    PJS_Property *properties;
    JSPropertySpec *ps;
    JSPropertySpec *static_ps;

    /* Flags such as JS_CLASS_NO_INSTANCE */
    I32 flags;

    // struct PJS_Class *_next;    
    SV *ref;
};

#ifdef __cplusplus
}
#endif

static PJS_Class *
get_class_by_name(
    pTHX_
    const char *name
) {
    HV	*cstore = get_hv(NAMESPACE"PerlClass::ClassStore", 0);
    SV  **svp;

    svp = hv_fetch(cstore, name, strlen(name), 0);
    if(!svp) return NULL;
    return INT2PTR(PJS_Class *, SvIV((SV *) SvRV(*svp)));
}

/* Property Handling */

struct PJS_Property {
    int8 tinyid;
    
    SV *getter;    /* these are coderefs! */
    SV *setter;

    struct PJS_Property *_next;
};

static void 
free_JSPropertySpec(
    JSPropertySpec *ps_list
) {
    JSPropertySpec *ps;
    
    if(!ps_list) return;

    for (ps = ps_list; ps->name; ps++)
        Safefree(ps->name);

    Safefree(ps_list);
}

static PJS_Property *
get_property_by_id(
    PJS_Class *pcls,
    int8 tinyid
) {
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

static JSBool
invoke_perl_property_getter(
    JSContext *cx,
    JSObject *obj,
    pjsid id,
    jsval *vp
) {
    dTHX;
    PJS_Class *pcls;
    PJS_Property *pprop;
    SV *caller;
    char *name;
#if JS_VERSION >= 185
    JSAutoByteString bytes;
#endif
    jsint slot;
    U8 invocation_mode;

    if (!PJSID_IS(INT, id)) 
	return JS_TRUE;
    
    if (JS_TypeOfValue(cx, OBJECT_TO_JSVAL(obj)) == JSTYPE_OBJECT) {
        /* Called as instance */
        JSClass *clasp = PJS_GET_CLASS(cx, obj);
        name = (char *) clasp->name;
        invocation_mode = 1;
    }
    else {
        /* Called as static */
        JSFunction *parent_jfunc = JS_ValueToFunction(cx, OBJECT_TO_JSVAL(obj));
        if(!parent_jfunc) {
            JS_ReportError(cx, "Failed to extract class for static property getter");
            return JS_FALSE;
        }
#if JS_VERSION < 185
        name = (char *) JS_GetFunctionName(parent_jfunc);
#else
        name = bytes.encode(cx, JS_GetFunctionId(parent_jfunc));
#endif
        invocation_mode = 0;
    }
    
    if ((pcls = get_class_by_name(aTHX_ name)) == NULL) {
        JS_ReportError(cx, "Can't find class '%s'", name);
        return JS_FALSE;
    }

    slot = PJSID_TO(INT, id);

    if ((pprop = get_property_by_id(pcls, (int8)slot)) == NULL) {
        JS_ReportError(cx, "Can't find property handler");
        return JS_FALSE;
    }

    if (pprop->getter == NULL) {
        JS_ReportError(cx, "Property is write-only");
        return JS_FALSE;
    }

    if (invocation_mode) {
        caller = (SV *)JS_GetPrivate(cx, obj);
	SvREFCNT_inc_void_NN(caller);
    }
    else {
        caller = newSVpv(pcls->pkg, 0);
    }

    if (!PJS_Call_sv_with_jsvals(aTHX_ cx, obj, pprop->getter, caller,
	                         0, NULL, vp, G_SCALAR)) {
        return JS_FALSE;
    }

    return JS_TRUE;
}

static JSBool
invoke_perl_property_setter(
    JSContext *cx,
    JSObject *obj,
    pjsid id,
    DEFSTRICT_
    jsval *vp
) {
    dTHX;
    PJS_Class *pcls;
    PJS_Property *pprop;
    SV *caller;
    char *name;
#if JS_VERSION >= 185
    JSAutoByteString bytes;
#endif
    jsint slot;
    U8 invocation_mode;


    if(!PJSID_IS(INT, id)) return JS_TRUE;

    if (JS_TypeOfValue(cx, OBJECT_TO_JSVAL(obj)) == JSTYPE_OBJECT) {
        /* Called as instance */
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
#if JS_VERSION < 185
        name = (char *) JS_GetFunctionName(parent_jfunc);
#else
        name = bytes.encode(cx, JS_GetFunctionId(parent_jfunc));
#endif
        invocation_mode = 0;
    }
    
    if ((pcls = get_class_by_name(aTHX_ name)) == NULL) {
        JS_ReportError(cx, "Can't find class '%s'", name);
        return JS_FALSE;
    }

    slot = PJSID_TO(INT, id);

    if ((pprop = get_property_by_id(pcls, (int8)slot)) == NULL) {
        JS_ReportError(cx, "Can't find property handler");
        return JS_FALSE;
    }

    if (pprop->setter == NULL) {
        JS_ReportError(cx, "Property is read-only");
        return JS_FALSE;
    }

    if (invocation_mode) {
        caller = (SV *)JS_GetPrivate(cx, obj);
	SvREFCNT_inc_void_NN(caller);
    }
    else caller = newSVpv(pcls->pkg, 0);

    if (!PJS_Call_sv_with_jsvals(aTHX_ cx, obj, pprop->setter, caller,
                                 1, vp, NULL, G_SCALAR | G_NOARGS))
        return JS_FALSE;

    return JS_TRUE;
}

/* Function Handling */

struct PJS_Function {
    /* The name of the JS function which this perl function is bound to */
    char *name;
    
    /* The perl reference to the function */
    SV *callback;
    
    /* Next function in list */
    struct PJS_Function *_next;
};

static PJS_Function *
get_method_by_name(
    PJS_Class *cls,
    const char *name
) {
    PJS_Function *ret = cls->methods;

    while(ret) {
        if(strEQ(ret->name, name)) break;
        ret = ret->_next;
    }
    return ret;
}

/*
  Free memory occupied by PJS_Class structure
*/

static void
free_JSFunctionSpec(
    JSFunctionSpec *fs_list
) {
    JSFunctionSpec *fs;
    
    if(!fs_list) return;

    for (fs = fs_list; fs->name != NULL; fs++)
        Safefree(fs->name);

    Safefree(fs_list);
}

/* Universal call back for constructors */
static JSBool
construct_perl_object(
    JSContext *cx,
    DEFJSFSARGS_
) {
    DECJSFSARGS;
    dTHX;
    PJS_Class *pcls;
    JSFunction *jfunc = JS_ValueToFunction(cx, JS_ARGV_CALLEE(argv));
    char *name;
    SV *rsv = NULL;
    JSBool ok = JS_FALSE;
#if JS_VERSION >= 185
    JSAutoByteString bytes;

    name = bytes.encode(cx, JS_GetFunctionId(jfunc));
    if(!obj && !(obj = JS_NewObjectForConstructor(cx, vp)))
	return JS_FALSE;
    argv[-1] = OBJECT_TO_JSVAL(obj);
#else
    name = (char *)JS_GetFunctionName(jfunc);
#endif

    JS_SetPrivate(cx, obj, newRV(&PL_sv_undef)); /* Object is clean */
    
    if ((pcls = get_class_by_name(aTHX_ name)) == NULL) {
        JS_ReportError(cx, "Can't find class %s", name);
        return JS_FALSE;
    }

    /* Check if we are allowed to instantiate this class */
    if ((pcls->flags & PJS_CLASS_NO_INSTANCE)) {
        JS_ReportError(cx, "Class '%s' can't be instantiated",
		           pcls->clasp->name);
        return JS_FALSE;
    }

    if (!PJS_Call_sv_with_jsvals_rsv(aTHX_ cx, NULL, pcls->cons,
				     newSVpv(pcls->pkg, 0),
				     argc, argv, &rsv, G_SCALAR))
	return JS_FALSE; /* We must have thrown an exception */

    if (sv_isobject(rsv)) ok = PJS_CreateJSVis(aTHX_ cx, obj, rsv) != NULL;
    else JS_ReportError(cx, "%s's constructor don't return an object",
		   pcls->clasp->name);
    if(ok) PJS_SET_RVAL(cx, OBJECT_TO_JSVAL(obj));
    return ok;
}

static JSPropertySpec *
add_class_properties(
    pTHX_
    PJS_Class *pcls,
    HV *ps,
    U8 flags
) {
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

        pprop->getter = getter != NULL && SvTRUE(*getter) 
	    ? SvREFCNT_inc_simple_NN(*getter) : NULL;
        pprop->setter = setter != NULL && SvTRUE(*setter) 
	    ? SvREFCNT_inc_simple_NN(*setter) : NULL;

        current_ps->getter = invoke_perl_property_getter;
        current_ps->setter = invoke_perl_property_setter;
        current_ps->tinyid = pcls->next_property_id++;

        current_ps->flags = JSPROP_ENUMERATE | JSPROP_SHARED;
        
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

static JSBool
invoke_perl_object_method(
    JSContext *cx,
    DEFJSFSARGS_
) {
    dTHX;
    DECJSFSARGS;
    PJS_Class *pcls;
    PJS_Function *pfunc;
    JSFunction *jfunc = PJS_FUNC_SELF;
    SV *caller;
    char *name;
#if JS_VERSION >= 185
    JSAutoByteString bytes;
#endif
    U8 invocation_mode;
   
    if (JS_TypeOfValue(cx, OBJECT_TO_JSVAL(obj)) == JSTYPE_OBJECT) {
        /* Called as instance */
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
#if JS_VERSION < 185
        name = (char *) JS_GetFunctionName(parent_jfunc);
#else
	name = bytes.encode(cx, JS_GetFunctionId(parent_jfunc));
#endif
        invocation_mode = 0;
    }

    if (!(pcls = get_class_by_name(aTHX_ name))) {
        JS_ReportError(cx, "Can't find class '%s'", name);
        return JS_FALSE;
    }

#if JS_VERSION < 185
    name = (char *) JS_GetFunctionName(jfunc);
#else
    bytes.clear();
    name = bytes.encode(cx, JS_GetFunctionId(jfunc));
#endif

    if((pfunc = get_method_by_name(pcls, name)) == NULL) {
        JS_ReportError(cx, "Can't find method '%s' in '%s'", name, pcls->clasp->name);
        return JS_FALSE;
    }

    if (invocation_mode) {
        caller = (SV *)JS_GetPrivate(cx, obj);
	SvREFCNT_inc_void_NN(caller);
    }
    else {
        caller = newSVpv(pcls->pkg,0);
    }

    return PJS_Call_sv_with_jsvals(aTHX_ cx, obj, pfunc->callback,
                                   caller, argc, argv, rval, G_SCALAR);
}

static JSFunctionSpec *
add_class_functions(
    pTHX_
    PJS_Class *pcls,
    HV *fs,
    U8 flags
) {
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
        callback = hv_iterval(fs, entry); // FIXME, check callback != NULL

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

        current_fs->call = invoke_perl_object_method;
        current_fs->nargs = 0;
        current_fs->flags = 0;
        // current_fs->extra = 0;

        pfunc->callback = SvREFCNT_inc_simple_NN(callback);
        
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
    // current_fs->extra = 0;

    return fs_list;
}

static void 
free_class(
    pTHX_
    PJS_Class *pcls
) {
    PJS_Function *method;
    PJS_Property *property;

    assert(pcls);

    if(pcls->pkg) Safefree(pcls->pkg);

    method = pcls->methods;
    while(method != NULL) {
        PJS_Function *next = method->_next;
	if(method->callback && SvTRUE(method->callback))
	    SvREFCNT_dec(method->callback);
	if(method->name)
	    Safefree(method->name);
        method = next;
    }
    free_JSFunctionSpec(pcls->fs);
    free_JSFunctionSpec(pcls->static_fs);
    
    property = pcls->properties;
    while (property != NULL) {
        PJS_Property *next = property->_next;
	sv_free(property->getter);
	sv_free(property->setter);
	Safefree(property);
        property = next;
    }
    free_JSPropertySpec(pcls->ps);
    free_JSPropertySpec(pcls->static_ps);
    
    if(pcls->clasp) {
	if(pcls->clasp->name) Safefree(pcls->clasp->name);
        Safefree(pcls->clasp);
    }
    sv_free(pcls->cons);
    
    Safefree(pcls);
}

static SV* 
store_class(
    pTHX_
    PJS_Class *pcls
) {
    /* Add class to list of classes in context */
    SV *sv = newSV(0);
    HV *cstore = get_hv(NAMESPACE"PerlClass::ClassStore", 1);
    sv_setref_pv(sv, NAMESPACE"PerlClass", (void*)pcls);
	
    SvREFCNT_inc_void_NN(sv);
    (void)hv_store(cstore, pcls->clasp->name, strlen(pcls->clasp->name), sv, 0);
    return sv;
}

static SV *
create_class(
    char *name,
    char *pkg,
    CV *cons,
    HV *fs,
    HV *static_fs,
    HV *ps,
    HV *static_ps,
    U32 flags
) {
    dTHX;
    PJS_Class *pcls;

    Newxz(pcls, 1, PJS_Class);
    if(!pcls) 
        croak("Failed to allocate memory for PJS_Class");
    
    /* Copy Flags */
    pcls->flags = flags;

    /* Add "package" */
    if(!(pcls->pkg = savepv(pkg))) {
        free_class(aTHX_ pcls);
        croak("Failed to allocate memory for pkg");
    }

    /* Create JSClass "clasp" */
    Newxz(pcls->clasp, 1, JSClass);
    if (pcls->clasp == NULL) {
        free_class(aTHX_ pcls);
        croak("Failed to allocate memory for JSClass");
    }

    if(!(pcls->clasp->name = savepv(name))) {
        free_class(aTHX_ pcls);
        croak("Failed to allocate memory for name in JSClass");
    }

    pcls->clasp->flags = JSCLASS_PRIVATE_IS_PERL;
    pcls->clasp->addProperty = JS_PropertyStub;
    pcls->clasp->delProperty = JS_PropertyStub;  
    pcls->clasp->getProperty = invoke_perl_property_getter;
    pcls->clasp->setProperty = invoke_perl_property_setter;
    pcls->clasp->enumerate = JS_EnumerateStub;
    pcls->clasp->resolve = JS_ResolveStub;
    pcls->clasp->convert = JS_ConvertStub;
    pcls->clasp->finalize = PJS_unrootJSVis;

    /* Per-object functions and properties */
    pcls->fs = add_class_functions(aTHX_ pcls, fs, PJS_INSTANCE_METHOD);
    pcls->ps = add_class_properties(aTHX_ pcls, ps, PJS_INSTANCE_METHOD);
    
    /* Class functions and properties */
    pcls->static_fs = add_class_functions(aTHX_ pcls, static_fs, PJS_CLASS_METHOD);
    pcls->static_ps = add_class_properties(aTHX_ pcls, static_ps, PJS_CLASS_METHOD);
    /* refcount constructor */
    pcls->cons = newRV_inc((SV *)cons);

    return store_class(aTHX_ pcls);
}

static JSObject *
bind_class(
    pTHX_
    JSContext *cx, 
    JSObject *gobj,
    PJS_Class *pcls
) {
    JSObject *proto;
    JSObject *stash = PJS_GetPackageObject(aTHX_ cx, pcls->pkg);

    if(!stash) croak("Can't register namespace %s\n", pcls->pkg);
    
    /* Initialize class */
    proto = JS_InitClass(cx,
			 gobj,
			 stash,
			 pcls->clasp,
			 construct_perl_object,
			 0,
			 pcls->ps /* ps */,
			 pcls->fs,
			 pcls->static_ps /* static_ps */,
			 pcls->static_fs /* static_fs */
    );

    if(!JS_DefineProperty(cx, stash, PJS_PROXY_PROP,
	              OBJECT_TO_JSVAL(proto), NULL, NULL, 0))
        return NULL;

    if(!PJS_CreateJSVis(aTHX_ cx, proto,
		    sv_2mortal(sv_bless(newRV(newSV(0)), gv_stashpv(pcls->pkg,0))))
    ) {
	croak("Failed to initialize class in context");
	return NULL;
    }
    return proto;
}

PJS_GTYPEDEF(PJS_Class, PerlClass);

MODULE = JSPL::PerlClass  PACKAGE = JSPL::PerlClass
PROTOTYPES: DISABLE

SV *
create_class(name, pkg, cons, fs, static_fs, ps, static_ps, flags)
    char *name;
    char *pkg;
    CV *cons;
    HV *fs;
    HV *static_fs;
    HV *ps;
    HV *static_ps;
    U32 flags;

void
bind(pcls, pcx, gobj)
    JSPL::PerlClass pcls;
    JSPL::Context pcx;
    JSObject *scope = NO_INIT;
    CODE:
	scope = PJS_GetScope(aTHX_ PJS_getJScx(pcx), ST(2));
	if(!bind_class(aTHX_ PJS_getJScx(pcx), scope, pcls))
	    PJS_report_exception(aTHX_ pcx);

void
DESTROY(pcls)
    JSPL::PerlClass pcls;
    CODE:
	PJS_DEBUG1("In free_class %s\n", pcls->clasp->name);
	free_class(aTHX_ pcls);
