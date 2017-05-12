/*!
    @header PJS_PerlSub.h
    @abstract Types and functions related the JS native class PerlSub
*/

#ifndef __PJS_PERLSUB_H__
#define __PJS_PERLSUB_H__

#ifdef __cplusplus
extern "C" {
#endif

PJS_EXTERN JSBool
perlsub_as_constructor(JSContext *cx, JSObject *obj, pjsid id, DEFSTRICT_ jsval *vp);

PJS_EXTERN JSObject *
PJS_NewPerlSub(pTHX_ JSContext *cx, JSObject *parent, SV *ref);
    	
/*! @function PJS_InitPerlSubClass
    @abstract Initiailizes the Perl sub class
    @param pcx The context to init the class in
	@param global The global object for the context
*/
PJS_EXTERN JSObject *
PJS_InitPerlSubClass(pTHX_ JSContext *cx, JSObject *global);
	
#ifdef __cplusplus
}
#endif

#endif
