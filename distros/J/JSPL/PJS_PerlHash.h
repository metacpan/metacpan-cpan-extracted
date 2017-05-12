/*!
    @header PJS_PerlHash.h
    @abstract Types and functions related the JS native class PerlHash
*/

#ifndef __PJS_PERLHASH_H__
#define __PJS_PERLHASH_H__

#ifdef __cplusplus
extern "C" {
#endif

PJS_EXTERN JSObject *
PJS_NewPerlHash(pTHX_ JSContext *cx, JSObject *parent, SV *ref);
	
/*! @function PJS_InitPerlHashClass
    @abstract Initiailizes the Perl hash class
    @param pcx The context to init the class in
	@param global The global object for the context
*/
PJS_EXTERN JSObject *
PJS_InitPerlHashClass(pTHX_ JSContext *cx, JSObject *global);
	
#ifdef __cplusplus
}
#endif

#endif
