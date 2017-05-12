#include "JavaScript.h"

#include "PJS_Call.h"
#include "PJS_Context.h"

JSBool checkSeen( JSContext *cx, JSObject *seen, SV *ref, jsval *rval ) {
    /* a string rep of a pointer to the object */
    char hkey[32];
    int klen = snprintf(hkey, 32, "%p", ref);

    jsval seen_value;
    if ( JS_GetProperty(cx, seen, hkey, &seen_value) == JS_FALSE )
        return JS_FALSE;

    if (!( JSVAL_IS_NULL(seen_value) || JSVAL_IS_VOID(seen_value))) {
        /* seen this before */
        *rval = seen_value;
        return JS_TRUE;
    }

    return JS_FALSE;
}

JSBool setSeen( JSContext *cx, JSObject *seen, SV *ref, jsval rval ) {
    /* a string rep of a pointer to the object */
    char hkey[32];
    int klen = snprintf(hkey, 32, "%p", ref);
    return JS_DefineProperty(cx, seen, hkey, rval, NULL, NULL, JSPROP_ENUMERATE);
}

/* Converts perl values to equivalent JavaScript values */
JSBool PJS_ConvertPerlToJSType(JSContext *cx, JSObject *seen, JSObject *obj, SV *ref, jsval *rval) {
    int destroy_seen = 0; /* TODO - do we _need_ to clean up after us? */
    
    if (sv_isobject(ref) && strcmp(HvNAME(SvSTASH(SvRV(ref))), PJS_BOXED_PACKAGE) == 0) {
        /* XXX: test this more */
        ref = *av_fetch((AV *) SvRV(SvRV(ref)), 0, 0);
    }

    if (sv_isobject(ref)) { /* blessed */
        PJS_Context *pcx;
        PJS_Class *pjsc;
        JSObject *newobj;
        HV *stash = SvSTASH(SvRV(ref));
        char *name = HvNAME(stash);

        if (strcmp(name, PJS_FUNCTION_PACKAGE) == 0) {
            JSFunction *func = INT2PTR(JSFunction *, SvIV((SV *) SvRV(PJS_call_perl_method("content", ref, NULL))));
            JSObject *obj = JS_GetFunctionObject(func);
            *rval = OBJECT_TO_JSVAL(obj);
            return JS_TRUE;
        }
        
	if (strcmp(name, PJS_GENERATOR_PACKAGE) == 0) {
	  JSObject *obj = INT2PTR(JSObject *, SvIV((SV *) SvRV(PJS_call_perl_method("content", ref, NULL))));
	  *rval = OBJECT_TO_JSVAL(obj);
	  return JS_TRUE;
	}

        /* ugly hack, this needs to be nicer */
        if((pcx = PJS_GET_CONTEXT(cx)) == NULL) {
            *rval = JSVAL_VOID;
            return JS_FALSE;
        }
                
        if((pjsc = PJS_GetClassByPackage(pcx, name)) == NULL) {
            *rval = JSVAL_VOID;
            return JS_FALSE;
        }
        
        SvREFCNT_inc(ref);
        
        newobj = JS_NewObject(cx, pjsc->clasp, NULL, obj);
        
        JS_SetPrivate(cx, newobj, (void *) ref);
        
        *rval = OBJECT_TO_JSVAL(newobj);
        
        return JS_TRUE;
    }

    if (!SvOK(ref)) {
        /* Returned value is undefined */
        *rval = JSVAL_VOID;
    }
    else if (SvIOK(ref)) {
        /* Returned value is an integer */
        if (SvIV(ref) <= JSVAL_INT_MAX) {
            *rval = INT_TO_JSVAL(SvIV(ref));
        } else {
            JS_NewDoubleValue(cx, (double) SvIV(ref), rval);
        }
    }
    else if (SvNOK(ref)) {
        JS_NewDoubleValue(cx, SvNV(ref), rval);
    }
    else if(SvPOK(ref)) {
        /* Returned value is a string */
        char *str;
        STRLEN len;

#ifdef JS_C_STRINGS_ARE_UTF8
        str = SvPVutf8(ref, len);
#else
        str = SvPVbyte(ref, len);
#endif
        *rval = STRING_TO_JSVAL(JS_NewStringCopyN(cx, str, len));
    }
    else if(SvROK(ref)) { /* reference */
        I32 type;

        if (!seen) {
            seen = JS_NewObject(cx, NULL, NULL, NULL);
            if(seen == NULL)
                croak("Failed to create new JavaScript object");
            destroy_seen = 1;
        }
        

        type = SvTYPE(SvRV(ref));

        /* Most likely it's an hash that is returned */
        if(type == SVt_PVHV) {
            JSObject *new_obj;
            HV *hv = (HV *) SvRV(ref);
            I32 items;
            HE *key;
            char *keyname;
            SV *keysv;
            STRLEN keylen;
            SV *keyval;
            jsval elem;
            
            if ( checkSeen( cx, seen, (SV*)hv, rval ) == JS_TRUE )
                return JS_TRUE;

            new_obj = JS_NewObject(cx, NULL, NULL, NULL);
            if(new_obj == NULL)
                croak("Failed to create new JavaScript object");

            setSeen( cx, seen, (SV*)hv, OBJECT_TO_JSVAL(new_obj) );

            /* Assign properties, lets iterate over the hash */
            items = hv_iterinit(hv);
            
            while((key = hv_iternext(hv)) != NULL) {
                /* although most hash keys are stored as char*, it's _way_
                   easier from a logic point of view to convert the bytes
                   to an SV (so we know the charset) and then back again.
                   TODO - we should only do this if we need to change the
                   encoding of the key. */

                /* if the key is an SV, this will return a *SV, otherwise null */
                keysv = HeSVKEY( key );
                if (keysv) {
                    /* great. Do nothing. */
                    warn ("here - got SV key %p", keysv);
#ifdef JS_C_STRINGS_ARE_UTF8
                    keyname = SvPVutf8(keysv, SvLEN( keysv ) );
#else
                    keyname = SvPVbyte(keysv, SvLEN( keysv ) );
#endif

                } else {
                    /* otherwise, just a pv key */
                    keyname = HeKEY( key );
#ifdef JS_C_STRINGS_ARE_UTF8
                    if (!HeKUTF8( key )) {
                        /* key is bytes, we want utf8. */
                        keysv = newSV(0);
                        sv_setpv( keysv, keyname );
                        keyname = SvPVutf8(keysv, SvLEN( keysv ) );
                        sv_2mortal( keysv );
                    }
#else
                    if (HeKUTF8( key )) {
                        /* key is utf8, we want bytes. */
                        keysv = newSV(0);
                        sv_setpv( keysv, keyname );
                        SvUTF8_on(keysv);
                        keyname = SvPVbyte(keysv, SvLEN( keysv ) );
                        sv_2mortal( keysv );
                    }
#endif
                }

                keyval = (SV *) hv_iterval(hv, key);
                if (PJS_ConvertPerlToJSType(cx, seen, obj, keyval, &elem) == JS_FALSE) {
                    *rval = JSVAL_VOID;
                    return JS_FALSE;
                }
                
                if (JS_DefineProperty(cx, new_obj, keyname, elem, NULL, NULL, JSPROP_ENUMERATE) == JS_FALSE) {
                    warn("Failed to defined property %%", keyname);
                }
            }
                
            *rval = OBJECT_TO_JSVAL(new_obj);
        } else if(type == SVt_PVAV) {
            jsint av_length;
            jsint cnt;
            jsval *elems;
            JSObject *arr_obj;
            /* Then it's probablly an array */
            AV *av = (AV *) SvRV(ref);

            if ( checkSeen( cx, seen, (SV*)av, rval ) == JS_TRUE )
                return JS_TRUE;

            arr_obj = JS_NewArrayObject(cx, 0, NULL);

            setSeen( cx, seen, (SV*)av, OBJECT_TO_JSVAL(arr_obj) );

            av_length = av_len(av);
            for(cnt = 0; cnt <= av_length; cnt++) {
                jsval value;
                if (PJS_ConvertPerlToJSType(cx, seen, obj, *(av_fetch(av, cnt, 0)), &value) == JS_FALSE) {
                    *rval = JSVAL_VOID;
                    return JS_FALSE;
                }
                JS_DefineElement(cx, arr_obj, cnt, value, NULL, NULL, JSPROP_ENUMERATE );
            }
            
            *rval = OBJECT_TO_JSVAL(arr_obj);
        }
        else if(type == SVt_PVGV) {
            *rval = PRIVATE_TO_JSVAL(ref);
        }
        else if(type == SVt_PV || type == SVt_IV || type == SVt_NV || type == SVt_RV) {
            /* Not very likely to return a reference to a primitive type, but we need to support that aswell */
            warn("returning references to primitive types is not supported yet");   
        }
        else if(type == SVt_PVCV) {
            JSObject *newobj = PJS_NewPerlSubObject(cx, obj, ref);            
            *rval = OBJECT_TO_JSVAL(newobj);
        }
        else {
            warn("JavaScript.pm not handling this yet");
            *rval = JSVAL_VOID;
            return JS_FALSE;
        }

    }
    else {
        warn("I have no idea what ref is (it's of type %i), I'll pretend it's null", SvTYPE(ref));
        *rval = JSVAL_VOID;
    }
    

    return JS_TRUE;
}
/* Converts a JavaScript value to equivalent Perl value */
JSBool JSVALToSV(JSContext *cx, HV *seen, jsval v, SV** sv) {
    if (JSVAL_IS_PRIMITIVE(v)) {
        if (JSVAL_IS_NULL(v) || JSVAL_IS_VOID(v)){
            *sv = &PL_sv_undef;
        }
        else if (JSVAL_IS_INT(v)) {
            sv_setiv(*sv, JSVAL_TO_INT(v));
        }
        else if (JSVAL_IS_DOUBLE(v)) {
            sv_setnv(*sv, *JSVAL_TO_DOUBLE(v));
        }
        else if (JSVAL_IS_STRING(v)) {
            /* XXX: review this, JS_GetStringBytes twice causing assertaion failure */
#ifdef JS_C_STRINGS_ARE_UTF8
            char *tmp = JS_smprintf("%hs", JS_GetStringChars(JSVAL_TO_STRING(v)));
            sv_setpv(*sv, tmp);
            SvUTF8_on(*sv);
            free(tmp);
#else
            sv_setpv(*sv, JS_GetStringBytes(JSVAL_TO_STRING(v)));
#endif         
        }
        else if (JSVAL_IS_BOOLEAN(v)) {
            if (JSVAL_TO_BOOLEAN(v)) {
                *sv = &PL_sv_yes;
            }
            else {
            *sv = &PL_sv_no;
            }
        }
        else {
            croak("Unknown primitive type");
        }
    }
    else {
        if (JSVAL_IS_OBJECT(v)) {
            JSObject *object = JSVAL_TO_OBJECT(v);
            int destroy_hv;
            SV **used;
            char hkey[32];
            int klen;
            
            /* stringify object with a default value for now, such as
               String.  We might want to actually tie the object in the
               future, so the additional properties won't go away */
            {
                jsval dvalue;
                if (OBJ_DEFAULT_VALUE(cx, object, JSTYPE_OBJECT, &dvalue) &&
                    JSVAL_IS_STRING(dvalue)) {
                    sv_setpv(*sv, JS_GetStringBytes(JSVAL_TO_STRING(dvalue)));
                    return JS_TRUE;
                }
            }

#ifdef JS_ENABLE_E4X
            if (OBJECT_IS_XML(cx,object)) {
                    /* We can't use private functions so let's call the toString method on the object */
                    jsval tv;
                    JSString *xmlstring;
                    JS_CallFunctionName(cx, object, "toXMLString", 0, NULL, &tv);
                    xmlstring = JS_ValueToString(cx,tv);
                    sv_setpv(*sv, JS_GetStringBytes(xmlstring));
                    SvUTF8_on(*sv);
                    return JS_TRUE;
            } 
            else if (JS_ObjectIsFunction(cx, object)) {
#else
            if (JS_ObjectIsFunction(cx, object)) {
#endif               
                JSFunction *jsfun = JS_ValueToFunction(cx, v);
                SV *pcx = sv_2mortal(newSViv(PTR2IV(PJS_GET_CONTEXT(cx))));
                SV *content = sv_2mortal(newRV_noinc(newSViv(PTR2IV(jsfun))));
                jsval *x;
                
                Newz(1, x, 1, jsval);
                if (x == NULL) {
                    croak("Failed to allocate memory for jsval");
                }
                *x = v;
                JS_AddRoot(cx, (void *)x);

                sv_setsv(*sv, PJS_call_perl_method("new",
                                                   newSVpv(PJS_FUNCTION_PACKAGE, 0),
                                                   content, pcx,
                                                   sv_2mortal(newSViv(PTR2IV(x))), NULL));
                return JS_TRUE;
            }
	    else if (!strcmp(JS_GET_CLASS(cx,object)->name, "RegExp")) {
	      jsval src;

	      if ( JS_GetProperty(cx, object, "source", &src) == JS_TRUE ) {
		dSP;
		ENTER;
		SAVETMPS;
		PUSHMARK(SP);
		SV *arg = sv_newmortal();	      
		sv_setpv(arg, JS_GetStringBytes(JS_ValueToString(cx, src)));		
		XPUSHs(arg);
		PUTBACK;
		call_pv("JavaScript::_compile_string_re", G_SCALAR);
		SPAGAIN;
		sv_setsv(*sv, POPs);
		PUTBACK;
		FREETMPS;
		LEAVE;
		return JS_TRUE;
	      }

	      return JS_FALSE;
	    }
            else if (OBJ_IS_NATIVE(object) &&
                     (OBJ_GET_CLASS(cx, object)->flags & JSCLASS_HAS_PRIVATE) &&
                     (strcmp(OBJ_GET_CLASS(cx, object)->name, "Error") != 0) &&
		     (strcmp(OBJ_GET_CLASS(cx, object)->name, "Generator") != 0)
		     ) {
                /* Object with a private means the actual perl object is there */
                /* This is kludgy because function is also object with private,
                   we need to turn this to use hidden property on object */
                SV *priv = (SV *)JS_GetPrivate(cx, object);
                if (priv && SvROK(priv)) {
                    sv_setsv(*sv, priv);
                    return JS_TRUE;
                }
            }
	    else if (OBJ_IS_NATIVE(object) &&
		     (OBJ_GET_CLASS(cx, object)->flags & JSCLASS_HAS_PRIVATE) &&
		     (strcmp(OBJ_GET_CLASS(cx, object)->name, "Generator") == 0)
		     ){
	      SV *content = sv_2mortal(newRV_noinc(newSViv(PTR2IV(object))));
	      SV *pcx = sv_2mortal(newSViv(PTR2IV(PJS_GET_CONTEXT(cx))));
	      jsval *x;
               
	      Newz(1, x, 1, jsval);
	      if (x == NULL) {
		croak("Failed to allocate memory for jsval");
	      }
	      *x = v;
	      JS_AddRoot(cx, (void *)x);

	      sv_setsv(*sv, PJS_call_perl_method("new",
						 newSVpv(PJS_GENERATOR_PACKAGE, 0),
						 content, pcx,
						 sv_2mortal(newSViv(PTR2IV(x))), NULL));
	      return JS_TRUE;	      
	    }

            destroy_hv = 0;
            if (!seen) {
                seen = newHV();
                destroy_hv = 1;
            }
            
            klen = snprintf(hkey, 32, "%p", object);
            if ((used = hv_fetch(seen, hkey, klen, 0)) != NULL) {
                sv_setsv(*sv, *used);
                return JS_TRUE;
            } else if(JS_IsArrayObject(cx, object)) {
                SV *arr_sv;
                
                arr_sv = JSARRToSV(cx, seen, object);
                
                sv_setsv(*sv, arr_sv);
            } else {
                SV *hash_sv;
                
                hash_sv = JSHASHToSV(cx, seen, object);
                sv_setsv(*sv, hash_sv);
            }
            
            if (destroy_hv) {
              SvREFCNT_dec(seen);
            }
        }
        else {
            croak("Not an object nor a primitive");
        }
    }
    
    
    return JS_TRUE;
}

/* Converts an JavaScript array object to an Perl array reference */
SV *JSARRToSV(JSContext *cx, HV *seen, JSObject *object) {
    jsuint jsarrlen;
    jsuint index;
    jsval elem;
    
    AV *av = newAV();
    SV *sv = sv_2mortal(newRV_noinc((SV *) av));

    char hkey[32];
    int klen = snprintf(hkey, 32, "%p", object);

    hv_store(seen, hkey, klen, sv, 0);
    SvREFCNT_inc(sv);

    JS_GetArrayLength(cx, object, &jsarrlen);
    for(index = 0; index < jsarrlen; index++) {
        SV *elem_sv;

        JS_GetElement(cx, object, index, &elem);        
        elem_sv = newSV(0);
        
        JSVALToSV(cx, seen, elem, &elem_sv);
        av_push(av, elem_sv);
    }

    return sv;
}

/* Converts a JavaScript object (not array) to a anonymous perl hash reference */
SV *JSHASHToSV(JSContext *cx, HV *seen, JSObject *object) {
    JSIdArray *prop_arr = JS_Enumerate(cx, object);
    int idx;

    HV *hv = newHV();
    SV *sv = sv_2mortal(newRV_noinc((SV *) hv));
    
    char hkey[32];
    int klen = snprintf(hkey, 32, "%p", object);
    hv_store(seen, hkey, klen, sv, 0);
    SvREFCNT_inc(sv);
    
    for(idx = 0; idx < prop_arr->length; idx++) {
        jsval key;
        
        JS_IdToValue(cx, (prop_arr->vector)[idx], &key);
        
        if(JSVAL_IS_STRING(key)) {
            jsval value;
            SV *val_sv;
            
            SV *js_key_sv = sv_newmortal();
            char *js_key = JS_GetStringBytes(JSVAL_TO_STRING(key));
            sv_setpv(js_key_sv, js_key);

#ifdef JS_C_STRINGS_ARE_UTF8
            /* char *js_key = JS_smprintf("%hs", JS_GetStringChars(JSVAL_TO_STRING(v))); */
            SvUTF8_on(js_key_sv);
#endif

            if ( JS_GetProperty(cx, object, js_key, &value) == JS_FALSE ) {
                /* we're enumerating the properties of an object. This returns
                   false if there's no such property. Urk. */
                croak("this can't happen.");
            }
            
            val_sv = newSV(0);
            JSVALToSV(cx, seen, value, &val_sv);
            hv_store_ent(hv, js_key_sv, val_sv, 0);
        }
        else {
            croak("can't coerce object key into a hash");
        }
    }
 
    JS_DestroyIdArray(cx, prop_arr);
  
    return sv;
}
