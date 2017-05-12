/*!
    @header PJS_PerlScalar.h
    @abstract Types and functions related the JS native class PerlScalar
*/

#ifndef __PJS_PERLSCALAR_H__
#define __PJS_PERLSCALAR_H__

#ifdef __cplusplus
extern "C" {
#endif

PJS_EXTERN JSObject *
PJS_NewPerlScalar(pTHX_ JSContext *cx, JSObject *parent, SV *ref);
	
/*! @function PJS_InitPerlScalarClass
    @abstract Initiailizes the PerlScalar class
    @param pcx The context to init the class in
	@param global The global object for the context
*/
PJS_EXTERN JSObject *
PJS_InitPerlScalarClass(pTHX_ JSContext *cx, JSObject *global);
	
#ifdef __cplusplus
}
#endif

#endif
