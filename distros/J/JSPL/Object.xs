#include "JS.h"

PJS_GTYPEDEF(JSObject, RawObj);

MODULE = JSPL::RawObj	PACKAGE = JSPL::RawObj PREFIX = rop_
PROTOTYPES: DISABLE

const char *
get_class_name(object, pcx)
    JSPL::Context pcx;
    JSPL::RawObj object;
    CODE:
	RETVAL = PJS_GET_CLASS(PJS_getJScx(pcx), object)->name;
    OUTPUT:
	RETVAL

void 
rop_seal_object(object, pcx, deep = 0)
    JSPL::Context pcx;
    JSPL::RawObj	object;
    U32	    deep;
    CODE:
#if JS_VERSION < 185
	JS_SealObject(PJS_getJScx(pcx), object, (JSBool)deep);
#else
	deep ? JS_DeepFreezeObject(PJS_getJScx(pcx), object)
	     : JS_FreezeObject(PJS_getJScx(pcx), object);
#endif

#define PJS_EL_MODE_FLAG	2

int
rop_set_prop(dest, pcx, name, val)
    JSPL::RawObj  dest;
    JSPL::Context pcx;
    SV *name = SvREADONLY($arg) ? sv_mortalcopy($arg) : $arg;
    SV *val;
    ALIAS:
	set_elem = 2
    PREINIT:
	JSBool ok = JS_FALSE;
	jsval rval;
	JSContext *cx;
    CODE:
	cx = PJS_getJScx(pcx);

	ok = PJS_ReflectPerl2JS(aTHX_ cx, NULL, val, &rval);

	if(ok) {
	    if(ix & PJS_EL_MODE_FLAG)
		ok = JS_SetElement(cx, dest, SvIV(name), &rval);
	    else {
		STRLEN len;
		char *str = PJS_SvPV(name, len);
		if((int)len >= 0) ok = JS_SetProperty(cx, dest, str, &rval);
		else ok = JS_SetUCProperty(cx, dest, (jschar *)str, -(int)len, &rval);
	    }
        }

	if(!ok && PJS_report_exception(aTHX_ pcx))
	    XSRETURN_UNDEF;
	RETVAL = 1;
    OUTPUT:
	RETVAL

jsval
rop_get_prop(source, pcx, property)
    JSPL::RawObj  source;
    JSPL::Context pcx;
    SV *property = SvREADONLY($arg) ? sv_mortalcopy($arg) : $arg;
    ALIAS:
	get_elem = 2
    PREINIT:
	JSBool ok = JS_FALSE;
	JSContext *cx;
    CODE:
	cx = PJS_getJScx(pcx);

	if(ix & PJS_EL_MODE_FLAG)
	    ok = JS_GetElement(cx, source, SvIV(property), &RETVAL);
	else {
	    STRLEN len;
	    char *name = PJS_SvPV(property, len);
#if JS_HAS_XML_SUPPORT
	    if(strEQ(PJS_GET_CLASS(cx, source)->name, "XML") && (int)len > 0) {
		/* TODO: if len < 0, name is UC2 encoded, so we need a JS_GetUCMethod */
		JSObject *other;
		ok = JS_GetMethod(cx, source, name, &other, &RETVAL);
		// Don't report if method fails
		if(!ok) JS_ClearPendingException(cx);
	    }
#endif
	    if(!ok) {
		if((int)len >= 0) ok = JS_GetProperty(cx, source, name, &RETVAL);
		else ok = JS_GetUCProperty(cx, source, (jschar *)name, -(int)len,
		                           &RETVAL);
	    }
	}
	if(!ok && PJS_report_exception(aTHX_ pcx))
	    XSRETURN_UNDEF;
    OUTPUT:
	RETVAL

int
rop_delete_prop(dest, pcx, name)
    JSPL::RawObj  dest;
    JSPL::Context pcx;
    SV *name = SvREADONLY($arg) ? sv_mortalcopy($arg) : $arg;
    ALIAS:
	delete_elem = 2
    PREINIT:
	JSContext *cx;
	JSBool ok;
    CODE:
	cx = PJS_getJScx(pcx);

	if(ix & PJS_EL_MODE_FLAG)
	    ok = JS_DeleteElement(cx, dest, SvIV(name));
	else {
	    STRLEN len;
	    char *str = PJS_SvPV(name, len);
	    jsval tmp;
	    if((int)len >= 0)
		ok = JS_DeleteProperty2(cx, dest, str, &tmp);
	    else ok = JS_DeleteUCProperty2(cx, dest, (jschar *)str, -(int)len, &tmp);
	}
	if(!ok && PJS_report_exception(aTHX_ pcx))
	    XSRETURN_UNDEF;
	RETVAL = 1;
    OUTPUT:
	RETVAL

#undef PJS_EX_MODE_FLAG
#undef PJS_EL_MODE_FLAG

JSPL::RawObj
rop_firstkey(object, pcx)
    JSPL::RawObj  object;
    JSPL::Context pcx;
    PREINIT:
	JSContext *cx;
	char hkey[32];
    CODE:
	cx = PJS_getJScx(pcx);

	RETVAL = JS_NewPropertyIterator(cx, object);

	/* Root Iterator */
	snprintf(hkey, 32, "%p", (void *)RETVAL);
	JS_DefineProperty(cx, pcx->pvisitors, hkey,
	    OBJECT_TO_JSVAL(RETVAL), NULL, NULL, 0);
    OUTPUT:
	RETVAL
	
jsval
rop_nextkey(iterator, pcx)
    JSPL::RawObj  iterator;
    JSPL::Context pcx;
    PREINIT:
	JSContext *cx;
	jsid idp;
    CODE:
	cx = PJS_getJScx(pcx);

	if(!JS_NextProperty(cx, iterator, &idp))
	    croak("NextProperty fail!");

	if(PJSID_IS(VOID,idp)) {
	    /* End of properties, unroot iterator */
	    char hkey[32];
	    snprintf(hkey, 32, "%p", (void *)iterator);
	    JS_DeleteProperty(cx, pcx->pvisitors, hkey);
            XSRETURN_UNDEF;
	}
	if(!JS_IdToValue(cx, idp, &RETVAL))
	    croak("Can't convert id to value");
    OUTPUT:
	RETVAL

SV *
rop_length(source, pcx)
    JSPL::RawObj  source;
    JSPL::Context pcx;
    PREINIT:
	JSContext *cx;
	jsuint len;
    CODE:
	cx = PJS_getJScx(pcx);
#ifdef JS_NEED_ARRAYLENGTH
	if(JS_GetArrayLength(cx, source, &len)) {
	    RETVAL = newSViv(len);
	} else {
	    JS_ClearPendingException(cx);
	    RETVAL = &PL_sv_undef;
	}
#else
	RETVAL = JS_HasArrayLength(cx, source, &len) ? newSViv(len) : &PL_sv_undef;
#endif
    OUTPUT:
	RETVAL

SV *
rop_tie(thing, pcx, isarr)
    JSPL::RawObj  thing;
    JSPL::Context pcx;
    I32 isarr;
    PREINIT:
	SV *box;
	SV *tied = NULL;
	SV *tier;
	AV *avbox;
	SV **last;
    CODE:
	box = PJS_GetPassport(aTHX_ PJS_getJScx(pcx), thing);
	avbox = (AV *)SvRV(box);
	last = av_fetch(avbox, 5+isarr, 1);
	if(last && SvOK(*last) && SvROK(*last)) {
	    RETVAL = newSVsv(*last);
	    PJS_DEBUG1("Tied cached:%s\n", SvPV_nolen(RETVAL));
	} else {
	    tied = isarr ? (SV *)newAV() : (SV *)newHV();
	    tier = newRV_inc(box);
	    hv_magic((HV *)tied, (GV *)tier, PERL_MAGIC_tied);
	    sv_free(tier);
	    RETVAL = newRV_noinc(tied);
	    sv_setsv(*last, RETVAL);
	    sv_rvweaken(*last);
	    PJS_DEBUG1("Return extra tied for %s\n", SvPV_nolen(tier));
	}
    OUTPUT:
	RETVAL

void
rop_free_root(thing, pcx)
    JSPL::RawObj  thing;
    JSPL::Context pcx;
    PREINIT:
	char hkey[32];
	SV *box;
    CODE:
	snprintf(hkey, 32, "%p", (void *)thing);
	box = PJS_GetPassport(aTHX_ PJS_getJScx(pcx), thing);
	PJS_DEBUG2("Freing %s brc: %d\n", hkey, (int)SvREFCNT(box));
	/* Invalidate CODEREF cache, its maybe holding a reference */
	av_store((AV *)SvRV(box), 7, &PL_sv_undef);
	/* Avoid destructing box a little, will be freed in passport_finalize.
	 * This transfers ownership to the passport, because there isn't more
	 * references in perl land to the Boxed.
	 */
	if(!PL_dirty) (void)SvREFCNT_inc_simple_NN(box); 
	JS_DeleteProperty(PJS_getJScx(pcx), pcx->pvisitors, hkey);
	PJS_GC(PJS_getJScx(pcx));
