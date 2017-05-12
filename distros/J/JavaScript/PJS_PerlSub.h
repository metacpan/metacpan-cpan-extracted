/*!
    @header PJS_PerlSub.h
    @abstract Types and functions related the JS native class PerlSub
*/

#ifndef __PJS_PERLSUB_H__
#define __PJS_PERLSUB_H__

#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"

#include "JavaScript_Env.h"

#include "PJS_Types.h"
#include "PJS_Common.h"

struct PJS_PerlSub {
    SV *cv;
};

PJS_EXTERN JSObject *
PJS_NewPerlSubObject(JSContext *cx, JSObject *parent, SV *ref);
    	
/*! @function PJS_InitPerlSubClass
    @abstract Initiailizes the Perl sub class
    @param pcx The context to init the class in
	@param global The global object for the context
*/
PJS_EXTERN JSObject *
PJS_InitPerlSubClass(PJS_Context *pcx, JSObject *global);
	
#ifdef __cplusplus
}
#endif

#endif
