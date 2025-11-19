#ifndef __peppertypes_h__
#define __peppertypes_h__

/* ---- STDINT HANDLING ---- */

#ifdef WIN32
#if defined( _MSC_VER ) && ( _MSC_VER >= 1600 )

/* beginning with VC2010 this is also provided */
#include <stdint.h>

#else /* defined( _MFC_VER ) && ( _MFC_VER >= 1700 ) */

#ifndef int64_t
typedef __int64 int64_t;
#endif /* int64_t */

#endif /* defined( _MFC_VER ) && ( _MFC_VER >= 1700 ) */

#else /* WIN32 */

/* This is not Windows */
#include <stdint.h>

#endif /* WIN32 */

/* ---- CALLING CONVENTION ---- */
#ifdef WIN32

#ifdef PEPPERC_DLL_EXPORTS

/*dh internal use only (build pepper) -> export these symbols */
#define PEPPERC_API __declspec( dllexport ) __stdcall

#else

/*dh use pepper -> import these symbols */
#define PEPPERC_API __declspec( dllimport ) __stdcall

#endif /* PEPPER_DLL_EXPORTS */

/* define the calling convention */
#define CALLING_CONVENTION __stdcall

#else /* WIN32 */

/*dh this is not windows */
#define PEPPERC_API __attribute__((visibility("default")))

/* define the calling convention */
#define CALLING_CONVENTION

#endif /* WIN32 */

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

/* define NULL if needed */
#ifndef NULL
#define NULL ( 0 )
#endif /* NULL */

/* empty definitions to mark function parameter direction */
#define _IN____
#define ___OUT_

/* the data type for handles */
typedef void* PEPHandle;

/* some pepper internal bool representation */
typedef int64_t PEPBool;

/* bool value types */
#define pepFalse ( 0 )
#define pepTrue ( !pepFalse )

/* the invalid handle value */
static const PEPHandle pepInvalidHandle = ( (PEPHandle)-1 );

/* error checking definitions */
#define PEPPER_FUNCTION_SUCCESS( __X ) ( __X >= pepFunctionResult_Success )
#define PEPPER_FUNCTION_FAILURE( __X ) ( !PEPPER_FUNCTION_SUCCESS( __X ) )

#ifdef __cplusplus
};     /* extern "C" */
#endif /* __cplusplus */

#endif /* __peppertypes_h__ */
