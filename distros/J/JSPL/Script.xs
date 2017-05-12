#include "JS.h"

#undef SHADOW /* perl.h includes shadow.h, clash with jsatom.h  */

MODULE = JSPL::Script     PACKAGE = JSPL::Script
PROTOTYPES: DISABLE

jsval
jss_execute(pcx, scope, obj)
    JSPL::Context pcx;
    JSObject *scope = NO_INIT;
    JSObject* obj;
    PREINIT:
	JSContext *cx;
    CODE:
	cx = PJS_getJScx(pcx);
	scope = PJS_GetScope(aTHX_ cx, ST(1));

	if(!JS_ExecuteScript(cx, scope, PJS_O2S(cx,obj), &RETVAL)) {
	    PJS_report_exception(aTHX_ pcx);
	    XSRETURN_UNDEF;
	}
    OUTPUT:
	RETVAL

SV *
jss_compile(pcx, scope, source, name = "")
    JSPL::Context pcx;
    JSObject *scope = NO_INIT;
    SV *source;
    const char *name;
    PREINIT:
	JSContext *cx;
        PJS_Script *script;
	JSObject *newobj;
    CODE:
	cx = PJS_getJScx(pcx);
	scope = PJS_GetScope(aTHX_ cx, ST(1));

	if(!(script = PJS_MakeScript(aTHX_ cx, scope, source, name)) ||
	   !(newobj = PJS_S2O(cx, script)) ||
	   !PJS_ReflectJS2Perl(aTHX_ cx, OBJECT_TO_JSVAL(newobj), &RETVAL, 0)
	) {
	    PJS_report_exception(aTHX_ pcx);
	    XSRETURN_UNDEF;
	}
    OUTPUT:
	RETVAL

#if JS_VERSION < 185

#include "jsscript.h"

SV *
jss_prolog(pcx, obj)
    JSPL::Context pcx;
    JSObject *obj;
    PREINIT:
	JSContext *cx;
	JSScript *script;
	char *prolog;
    CODE:
	cx = PJS_getJScx(pcx);
	script = (JSScript *)JS_GetPrivate(cx, obj);
	prolog = (char *)script->code;
	RETVAL = sv_setref_pvn(newSV(0), NULL, prolog,
	    (char *)script->main - prolog);
    OUTPUT:
	RETVAL

SV *
jss_main(pcx, obj)
    JSPL::Context pcx;
    JSObject *obj;
    PREINIT:
	JSContext *cx;
	JSScript *script;
	char *mainbc;
    CODE:
	cx = PJS_getJScx(pcx);
	script = (JSScript *)JS_GetPrivate(cx, obj);
	mainbc = (char *)script->main;
	RETVAL = sv_setref_pvn(newSV(0), NULL, mainbc,
	    script->length - (mainbc - (char *)script->code));
    OUTPUT:
	RETVAL

SV *
jss_getatom(pcx, obj, index)
    JSPL::Context pcx;
    JSObject *obj;
    U16 index;
    PREINIT:
	JSContext *cx;
	JSScript *script;
    CODE:
	cx = PJS_getJScx(pcx);
	script = (JSScript *)JS_GetPrivate(cx, obj);

	RETVAL = newSVpv(JS_GetStringBytes(
			  JS_ValueToString(cx, ATOM_KEY(script->atomMap.vector[index]))
			), 0);
    OUTPUT:
	RETVAL

SV *
jss_getobject(pcx, obj, index)
    JSPL::Context pcx;
    JSObject *obj;
    U16 index;
    PREINIT:
	JSContext *cx;
	JSScript *script;
    CODE:
	cx = PJS_getJScx(pcx);
	script = (JSScript *)JS_GetPrivate(cx, obj);
	RETVAL = &PL_sv_undef;
#if JS_VERSION < 180
	PERL_UNUSED_VAR(index); /* -W */
	croak("Not available in this SM");
#else
	if(script->objectsOffset) {
	    JSObjectArray *objarr =
		(JSObjectArray *)((uint8 *)script + script->objectsOffset);
	    if(index < objarr->length)
		RETVAL = sv_setref_pv(newSV(0), PJS_RAW_OBJECT,
		 	              (void *)objarr->vector[index]);
	}
#endif
    OUTPUT:
	RETVAL

#endif
