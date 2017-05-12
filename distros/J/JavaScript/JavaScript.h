/*!
    @header JavaScript.pm
    @abstract This module provides an interface between SpiderMonkey and perl.
        
    @copyright Claes Jakobsson 2001-2007
*/

#ifndef __JAVASCRIPT_H__
#define __JAVASCRIPT_H__

#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "JavaScript_Env.h"

#include "PJS_Call.h"
#include "PJS_Types.h"
#include "PJS_Runtime.h"
#include "PJS_Context.h"
#include "PJS_Class.h"
#include "PJS_Function.h"
#include "PJS_Property.h"
#include "PJS_Script.h"
#include "PJS_TypeConversion.h"
#include "PJS_Common.h"
#include "PJS_PerlArray.h"
#include "PJS_PerlHash.h"
#include "PJS_PerlSub.h"

#ifdef __cplusplus
}
#endif

#endif
