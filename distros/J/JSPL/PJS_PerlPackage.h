/*!
    @header PJS_PerlSub.h
    @abstract Types and functions related the JS native class PerlSub
*/

#ifndef __PJS_PERLPACKAGE_H__
#define __PJS_PERLPACKAGE_H__

#ifdef __cplusplus
extern "C" {
#endif

#define PJS_PACKAGE_CLASS_NAME   "Stash"

PJS_EXTERN JSObject *
PJS_NewPerlObject(pTHX_ JSContext *cx, JSObject *parent, SV *ref);
    	
PJS_EXTERN JSObject *
PJS_GetPackageObject(pTHX_ JSContext *cx, const char *package);

PJS_EXTERN char *
PJS_GetPackageName(pTHX_ JSContext *cx, JSObject *package);
	
#ifdef __cplusplus
}
#endif

#endif
