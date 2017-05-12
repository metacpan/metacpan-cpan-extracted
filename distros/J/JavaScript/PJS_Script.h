/*!
    @header PJS_Script.h
    @abstract Types and functions related to script handling
*/

#ifndef __PJS_SCRIPT_H__
#define __PJS_SCRIPT_H__

#ifdef __cpluplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"

#include "PJS_Types.h"
#include "PJS_Common.h"

struct PJS_Script {
    PJS_Context *cx;
    JSScript *script;
};

#ifdef __cpluplus
}
#endif

#endif

