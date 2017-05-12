#include "JS.h"

#ifdef IS_LITTLE_ENDIAN
#define PJS_STR_ENCODING    "UCS-2LE"
#else
#define PJS_STR_ENCODING    "UCS-2BE"
#endif

const char *PJS_PASSPORT_PROP = "__PASSPORT__";

static void
passport_finalize(
    JSContext *cx,
    JSObject *passport
) {
    dTHX;
    SV *box = (SV *)JS_GetPrivate(cx, passport);
    if(box && SvOK(box) && SvROK(box)) {
	AV *avbox = (AV *)SvRV(box);
#ifdef PJSDEBUG
	JSObject *parent = JS_GetParent(cx, passport);
#endif
	PJS_DEBUG3("About to free a %s rc:%d,%d\n", JS_GET_CLASS(cx, parent)->name, 
		   SvREFCNT(box), SvREFCNT(avbox)); 
	if(PL_dirty) return;
	av_store(avbox, 0, &PL_sv_undef);
	sv_free(box);
    } else croak("PJS_Assert: Bad finalize for passport\n"); /* Assertion */
}

/* Declare a JSClass for the __PASSPORT__ hidden attribute */
static JSClass passport_class = {
    "Passport",
    JSCLASS_HAS_PRIVATE | JSCLASS_HAS_RESERVED_SLOTS(1),
    JS_PropertyStub, /* Add */
    JS_PropertyStub, /* Del */
    JS_PropertyStub, /* Get */
    PJS_SetterPropStub, /* Set */
    JS_EnumerateStub,
    JS_ResolveStub,
    JS_ConvertStub,
    passport_finalize,
    JSCLASS_NO_OPTIONAL_MEMBERS
};

char *
PJS_ConvertUC(
    pTHX_
    SV *sv,
    STRLEN *len
) {
    dSP;
    char *ret;
    STRLEN elen;
    SvPV_force(sv, elen);
    if(SvUTF8(sv) && !sv_utf8_downgrade(sv, 1)) {
	SV *svtmp;
	ENTER; SAVETMPS;
	PUSHMARK(SP);
	XPUSHs(sv_2mortal(newSVpv(PJS_STR_ENCODING, 0)));
	XPUSHs(sv_mortalcopy(sv));
	PUTBACK;
	call_pv("Encode::encode", G_SCALAR);
	SPAGAIN;
	svtmp = newSVsv(POPs);
	SAVEMORTALIZESV(svtmp);
	ret = SvPV(svtmp, elen);
	PUTBACK;
	FREETMPS; LEAVE;
	*len = -(elen / 2);
    } else {
	ret = SvPV(sv, elen);
	*len = elen;
    }
    return ret;
}

SV *
PJS_JSString2SV(
    pTHX_
    JSContext *cx,
    JSString *jstr
) {
    SV *ret;
#if PJS_UTF8_NATIVE
# if JS_VERSION >= 185
    JSAutoByteString bytes(cx, jstr);
    char *str = bytes.ptr();
# else
    char *str = JS_GetStringBytes(jstr);
# endif
    ret = newSVpv(str, 0);
    SvUTF8_on(ret);
#else
    dSP;
    size_t length;
#if JS_VERSION >= 185
    const jschar *chars = JS_GetStringCharsZAndLength(cx, jstr, &length);
#else
    const jschar *chars = JS_GetStringChars(jstr);
    length = JS_GetStringLength(jstr);
#endif
    SV *esv = newSVpv((char *)chars, length * sizeof(jschar));

    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(PJS_STR_ENCODING, 0)));
    XPUSHs(sv_2mortal(esv));
    PUTBACK;
    call_pv("Encode::decode", G_SCALAR);
    SPAGAIN;
    ret = newSVsv(POPs);
    PUTBACK;
    FREETMPS; LEAVE;
    // sv_utf8_downgrade(ret, 1); Its safe, but pays the cost? 
#endif
    return ret;
}

/* Converts perl values to equivalent JS values */
JSBool
PJS_ReflectPerl2JS(
    pTHX_ 
    JSContext *cx,
    JSObject *pobj,
    SV *ref,
    jsval *rval
) {
    PJS_Context *pcx = PJS_GET_CONTEXT(cx);
    JSObject *newobj = NULL;

    if(++pcx->svconv % 2000 == 0) {
	JSErrorReporter older;
	ENTER; SAVETMPS; /* Scope for finalizers */
	older = JS_SetErrorReporter(cx, NULL);
	if(pcx->svconv > 10000) {
	    JS_GC(cx);
	    pcx->svconv = 0;
	} else JS_MaybeGC(cx);
	JS_SetErrorReporter(cx, older);
	FREETMPS; LEAVE;
    }
    if(SvROK(ref)) {
	MAGIC *mg;
	/* First check old jsvisitors */
	if((newobj = PJS_IsPerlVisitor(aTHX_ pcx, SvRV(ref)))) {
	    PJS_DEBUG("Old jsvisitor returns\n");
	    *rval = OBJECT_TO_JSVAL(newobj);
	    return JS_TRUE;
	}

	if(SvMAGICAL(SvRV(ref)) && (mg = mg_find(SvRV(ref), PERL_MAGIC_tied))
	   && mg->mg_obj && sv_derived_from(mg->mg_obj, PJS_BOXED_PACKAGE)) {
	    PJS_DEBUG1("A magical ref %s, shortcircuit!\n", SvPV_nolen((SV*)mg->mg_obj));
	    ref = mg->mg_obj;
	}

	if(sv_derived_from(ref, PJS_BOXED_PACKAGE)) {
	    SV **fref = av_fetch((AV *)SvRV(SvRV(ref)), 2, 0);
	    assert(sv_derived_from(*fref, PJS_RAW_JSVAL));
	    PJS_PSV2JSV(*rval, *fref);
	    return JS_TRUE;
	}

	if(sv_derived_from(ref, PJS_BOOLEAN)) {
	    *rval = SvTRUE(SvRV(ref)) ? JSVAL_TRUE : JSVAL_FALSE;
	    return JS_TRUE;
	}
	
	if(sv_isobject(ref)) {
	    newobj = PJS_NewPerlObject(aTHX_ cx, pobj, ref); 
	    if(newobj) {
		*rval = OBJECT_TO_JSVAL(newobj);
		return JS_TRUE;
	    }
	    return JS_FALSE;
	}
    }

    SvGETMAGIC(ref);

    if(!SvOK(ref)) /* undef */
        *rval = JSVAL_VOID;
    else if(SvIOK(ref) || SvIOKp(ref)) {
        if(SvIV(ref) <= JSVAL_INT_MAX)
            *rval = INT_TO_JSVAL(SvIV(ref));
	else
#if JS_VERSION < 185
	    JS_NewDoubleValue(cx, (jsdouble) SvIV(ref), rval);
#else
	    *rval = DOUBLE_TO_JSVAL((jsdouble) SvIV(ref));
#endif
    }
    else if(SvNOK(ref)) 
#if JS_VERSION < 185
        JS_NewDoubleValue(cx, SvNV(ref), rval);
#else
	*rval = DOUBLE_TO_JSVAL((jsdouble) SvNV(ref));
#endif
    else if(SvPOK(ref) || SvPOKp(ref)) {
        STRLEN len;
        char *str;
	SV *temp=NULL;
	if(SvREADONLY(ref)) {
	    temp = newSVsv(ref);
	    str = PJS_SvPV(temp, len);
	} else str = PJS_SvPV(ref, len);
	JSString *jstr = ((int)len >= 0)
	    ? JS_NewStringCopyN(cx, str, len)
	    : JS_NewUCStringCopyN(cx, (jschar *)str, -(int)len);
	sv_free(temp);
	if(!jstr) return JS_FALSE;
        *rval = STRING_TO_JSVAL(jstr);
    }
    else if(SvROK(ref)) { /* Plain reference */
        I32 type = SvTYPE(SvRV(ref));

        if(type == SVt_PVHV)
	    newobj = PJS_NewPerlHash(aTHX_ cx, pobj, ref);
	else if(type == SVt_PVAV)
	    newobj = PJS_NewPerlArray(aTHX_ cx, pobj, ref);
        else if(type == SVt_PVCV)
            newobj = PJS_NewPerlSub(aTHX_ cx, pobj, ref);            
	else
	    newobj = PJS_NewPerlScalar(aTHX_ cx, pobj, ref);
	if(!newobj) return JS_FALSE;
	*rval = OBJECT_TO_JSVAL(newobj);
    }
    else {
        warn("I have no idea what perl send us (it's of type %i), I'll pretend it's undef", SvTYPE(ref));
        *rval = JSVAL_VOID;
    }

    return JS_TRUE;
}

SV *
PrimJSVALToSV(
    pTHX_
    JSContext *cx,
    jsval v
) {
    SV *sv = NULL;
    if(JSVAL_IS_NULL(v) || JSVAL_IS_VOID(v))
	sv = newSV(0);
    else if(JSVAL_IS_BOOLEAN(v)) {
	sv = newSV(0);
	sv_setref_iv(sv, PJS_BOOLEAN, (IV)JSVAL_TO_BOOLEAN(v));
    }
    else if(JSVAL_IS_INT(v)) 
	sv = newSViv((IV)JSVAL_TO_INT(v));
    else if(JSVAL_IS_DOUBLE(v))
#if JS_VERSION < 185
	sv = newSVnv((NV) *JSVAL_TO_DOUBLE(v));
#else
	sv = newSVnv((NV) JSVAL_TO_DOUBLE(v));
#endif
    else if(JSVAL_IS_STRING(v)) 
	sv = PJS_JSString2SV(aTHX_ cx, JSVAL_TO_STRING(v));
    else croak("PJS_Assert: Unknown primitive type: %d", JS_TypeOfValue(cx, v));
    
    return sv;
}

SV* PJS_GetPassport(
    pTHX_
    JSContext *cx,
    JSObject *thing
) {
    jsval temp;
    SV *box;
    SV *tref;
    JSObject *inboxed;
    if(!JS_LookupPropertyWithFlags(cx, thing, PJS_PASSPORT_PROP, 0, &temp)
       || JSVAL_IS_VOID(temp) || JSVAL_IS_NULL(temp))
	croak("Can't get passport");
    box = (SV *)JS_GetPrivate(cx, JSVAL_TO_OBJECT(temp));
    tref = *av_fetch((AV *)SvRV(box), 0, 0);
    inboxed = INT2PTR(JSObject *, SvIV((SV *)SvRV(tref)));
    assert(inboxed == thing);
    return box;
}

/* Wrap a JS value to export into perl
 * Returns a new SV, REFCNT_dec is caller's responsability
 */
JSBool
PJS_ReflectJS2Perl(
    pTHX_
    JSContext *cx,
    jsval value,
    SV** sv,
    int full
) {
    if(JSVAL_IS_PRIMITIVE(value)) {
	*sv = PrimJSVALToSV(aTHX_ cx, value);
	if(*sv) return JS_TRUE;
    }
    else if(JSVAL_IS_OBJECT(value)) {
	PJS_Context *pcx = PJS_GET_CONTEXT(cx);
	JSObject *object = JSVAL_TO_OBJECT(value);
	JSClass *clasp = PJS_GET_CLASS(cx, object);
	const char *classname = clasp->name;
	JSObject *passport;
	SV *wrapper;
	SV *box;
	char hkey[32];
	jsval temp = JSVAL_VOID;

	snprintf(hkey, 32, "%p", (void *)object);
	PJS_DEBUG2("Wrapping a %s(%s)\n", classname, hkey);

	if(PJS_getFlag(pcx, "ConvertRegExp") && strEQ(classname, "RegExp")) {
	    jsval src;
	    char *str;
#if JS_VERSION >= 185
	    JSAutoByteString bytes;
#endif

	    if(JS_CallFunctionName(cx, object, "toSource", 0, NULL, &src) &&
#if JS_VERSION < 185
	       (str = JS_GetStringBytes(JS_ValueToString(cx, src)))
#else
	       (str = bytes.encode(cx, JS_ValueToString(cx, src)))
#endif
	    )

	    {
		dSP;
		SV *tmp = newSVpvf("qr%s", str);
		eval_sv(tmp, G_SCALAR);
		sv_free(tmp); // Don't leak
		SPAGAIN;
		tmp = POPs;
		PUTBACK;
		if(!SvTRUE(ERRSV)) {
		    *sv = SvREFCNT_inc_simple_NN(tmp);
		    return JS_TRUE;
		}
	    }
	    return JS_FALSE;
	}

	if(IS_PERL_CLASS(clasp)) {
	    /* IS_PERL_CLASS means actual perl object is there */
	    SV *priv = (SV *)JS_GetPrivate(cx, object);
	    if(priv && SvOK(priv) && SvROK(priv)) {
		*sv = SvREFCNT_inc_simple_NN(priv);
		return JS_TRUE;
	    }
	    croak("A private %s?!\n", classname);
	    return JS_FALSE;
	}

	/* Common JSObject case */

	/* Check registered perl visitors */
	JSObject *pvis = pcx->pvisitors;
	assert(pvis);
	JS_LookupProperty(cx, pvis, hkey, &temp);

	if(temp != JSVAL_VOID) {
	    /* Already registered, so exits a reference in perl space
	     * _must_ hold a PASSPORT */
	    assert(JSVAL_TO_OBJECT(temp) == object);
	    box = PJS_GetPassport(aTHX_ cx, object);
	    SvREFCNT_inc_void_NN(box); /* In perl should be one more */
	    PJS_DEBUG1("Cached!: %s\n", hkey);
	} else {
	    /* Check if with a PASSPORT */
	    JS_LookupPropertyWithFlags(cx, object, PJS_PASSPORT_PROP, 0, &temp);
	    if(JSVAL_IS_OBJECT(temp) && (passport = JSVAL_TO_OBJECT(temp)) &&
	       PJS_GET_CLASS(cx, passport) == &passport_class &&
	       JS_GetReservedSlot(cx, passport, 0, &temp) &&
	       object == (JSObject *)JSVAL_TO_PRIVATE(temp)
	    ) { /* Yes, reentering perl */
		box = (SV *)JS_GetPrivate(cx, passport);
		/* Here we don't increment refcount, the ownership in passport is 
		 * transferred to perl land.
		 */
		PJS_DEBUG1("Reenter: %s\n", hkey);
	    }
	    else { /* No, first time, must wrap the object */
		SV *boxref;
		const char *package;
		SV *robj = newSV(0);
		SV *rjsv = newSV(0);

		if (JS_ObjectIsFunction(cx, object))
		    package = PJS_FUNCTION_PACKAGE;
		else if(JS_IsArrayObject(cx, object))
		    package = PJS_ARRAY_PACKAGE;
		else if(strEQ(classname, PJS_PACKAGE_CLASS_NAME))
		    package = PJS_STASH_PACKAGE;
#if JS_HAS_XML_SUPPORT
		else if(strEQ(classname, "XML"))
		    package = PJS_XMLOBJ_PACKAGE;
#endif
		else if(strEQ(classname, "Error"))
		    package = PJS_ERROR_PACKAGE;
		else {
		    SV **sv = hv_fetch(get_hv(NAMESPACE"ClassMap", 1), classname, 
			               strlen(classname), 0);
		    if(sv) package = SvPV_nolen(*sv);
		    else package = PJS_OBJECT_PACKAGE;
		}

		sv_setref_pv(robj, PJS_RAW_OBJECT, (void*)object);
		PJS_JSV2PSV(rjsv, value);
		boxref = PJS_CallPerlMethod(aTHX_ cx,
		    "__new",
		    sv_2mortal(newSVpv(package, 0)),	 // package
		    sv_2mortal(robj),			 // content
		    sv_2mortal(rjsv),			 // jsval
		    NULL
		);

		if(!boxref) return JS_FALSE;
		if(!SvOK(boxref) || !sv_derived_from(boxref, PJS_BOXED_PACKAGE))
		    croak("PJS_Assert: Contructor must return a "NAMESPACE"Boxed");

		/* Create a new PASSPORT */
		passport = JS_NewObject(cx, &passport_class, NULL, object);

		if(!passport ||
		   !JS_DefineProperty(cx, object, PJS_PASSPORT_PROP,
		                      OBJECT_TO_JSVAL(passport),
		                      NULL, NULL, JSPROP_READONLY | JSPROP_PERMANENT))
		{
		    warn("Can't create passport\n");
		    return JS_FALSE;
		}
		box = SvRV(boxref);
		/* boxref is mortal, so we need to increment its rc, at end of
		 * scope, PASSPORT owns created box */
		JS_SetPrivate(cx, passport, (void *)SvREFCNT_inc_simple_NN(box));
		JS_SetReservedSlot(cx, passport, 0, PRIVATE_TO_JSVAL(object));
		PJS_DEBUG2("New boxed: %s brc: %d\n", hkey, SvREFCNT(box));
	    }

	    /* Root object adding it to pvisitors list, will be unrooted by
	     * jsc_free_root at Boxed DESTROY time
	     */
	    JS_DefineProperty(cx, pvis, hkey, value, NULL, NULL, 0);
	}
	/* Here the RC of box in PASSPORT reflects wrapper's ownership */

	if(full && PJS_getFlag(pcx, "AutoTie") &&
	   (strEQ(classname, "Object") || strEQ(classname, "Array"))
	) {
	    /* Return tied */
	    AV *avbox = (AV *)SvRV(box);
	    SV **last;
	    SV *tied;
	    SV *tier;
	    if(strEQ(classname, "Array")) {
		last = av_fetch(avbox, 6, 1);
		if(last && SvOK(*last) && SvROK(*last)) { // Cached
		    *sv = newSVsv(*last);
		    sv_free(box); /* Hard copy 'sv' owns the reference */
		    return JS_TRUE;
		}
		tied = (SV *)newAV();
	    } else { // Object
		last = av_fetch(avbox, 5, 1);
		if(last && SvOK(*last) && SvROK(*last)) { // Cached
		    *sv = newSVsv(*last);
		    sv_free(box); /* Hard copy 'sv' owns the reference */
		    return JS_TRUE;
		}
		tied = (SV *)newHV();
	    }
	    /* hv_magic below own a reference to box, we use an explicit path, 
	     * to make clear that to perl land only one reference is given
	     */
	    tier = newRV_inc(box);
	    hv_magic((HV *)tied, (GV *)tier, PERL_MAGIC_tied);
	    sv_free(tier);
	    wrapper = newRV_noinc(tied); /* Don't leak the hidden tied variable */
	    /* Save in cache a weaken copy, the cache itself dosn't hold a reference */
	    sv_setsv(*last, wrapper);
	    sv_rvweaken(*last);
	    PJS_DEBUG1("Return tied for %s\n", SvPV_nolen(tier));
	}
	else {    
	    wrapper = newRV_noinc(box); /* Transfer ownership to wrapper */
#if PERL_VERSION < 9
	    sv_bless(wrapper, SvSTASH(box)); 
#endif
	}
	*sv = wrapper;
	return JS_TRUE;
    }
    return JS_FALSE;
}
