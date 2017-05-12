/*!
    @header PJS_PerlHash.h
    @abstract Types and functions related the JS native class PerlHash
*/

#ifndef __PJS_PERLHASH_H__
#define __PJS_PERLHASH_H__

#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"

#include "JavaScript_Env.h"

#include "PJS_Types.h"
#include "PJS_Common.h"

/*! @struct     PJS_PerlHash
    @abstract   This type maps Perl subroutines to JavaScript functions by name
    @discussion A linked list of these structures are maintained by each context.
                In the future this should change to a HV *.
*/
struct PJS_PerlHash {
	HV *hv;
};

PJS_EXTERN PJS_PerlHash *
PJS_NewPerlHash();
	
/*! @function PJS_InitPerlHashClass
    @abstract Initiailizes the Perl hash class
    @param pcx The context to init the class in
	@param global The global object for the context
*/
PJS_EXTERN JSObject *
PJS_InitPerlHashClass(PJS_Context *pcx, JSObject *global);
	
#ifdef __cplusplus
}
#endif

#endif
