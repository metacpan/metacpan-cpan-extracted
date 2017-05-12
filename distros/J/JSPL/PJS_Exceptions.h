/*!
    @header PJS_Exceptions.h
    @abstract Functions for dealing with exception handling
*/

#ifndef __PJS_EXCEPTIONS_H__
#define __PJS_EXCEPTIONS_H__

#ifdef __cplusplus
extern "C" {
#endif

PJS_EXTERN JSBool
PJS_report_exception(pTHX_ PJS_Context *);    

#ifdef __cplusplus
}
#endif

#endif

