/*!
    @header PJS_Exceptions.h
    @abstract Functions for dealing with exception handling
*/

#ifndef __PJS_EXCEPTIONS_H__
#define __PJS_EXCEPTIONS_H__

#ifdef __cplusplus
extern "C" {
#endif

#include "perl.h"

#include "JavaScript_Env.h"

#include "PJS_Context.h"

PJS_EXTERN void
PJS_report_exception(PJS_Context *);    

#ifdef __cplusplus
}
#endif

#endif

