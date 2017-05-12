/*!
    @header PJS_PerlArray.h
    @abstract Types and functions related the JS native class PerlArray
*/

#ifndef __PJS_PERLARRAY_H__
#define __PJS_PERLARRAY_H__

#ifdef __cplusplus
extern "C" {
#endif

PJS_EXTERN JSObject *
PJS_NewPerlArray(pTHX_ JSContext *cx, JSObject *parent, SV *ref);
	
/*! @function PJS_InitPerlArrayClass
    @abstract Initiailizes the Perl array class
    @param pcx The context to init the class in
	@param global The global object for the context
*/
PJS_EXTERN JSObject *
PJS_InitPerlArrayClass(pTHX_ JSContext *cx, JSObject *global);
	
#ifdef __cplusplus
}
#endif

#endif
