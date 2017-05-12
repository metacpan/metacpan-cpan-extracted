/*! \file pabidecl.h
    \brief calling conventions.

 * APICALL and BACKCALL can be something like __stdcall or __cdecl (compiler-specific).

 * APICALL set the calling convention for exported symbols.

 * BACKCALL set the calling convention for callback pointers.
 
 * By default, the code uses C standard (Cdecl) calling conventions.
 * One can override the calling conventions by defining their own
 * APICALL and BACKCALL macro.
*/

#ifndef _PABIDECL_H
#define _PABIDECL_H	1

#ifdef __cplusplus
#define TMPLPRO_EXTERN_C extern "C"
#else
#define TMPLPRO_EXTERN_C
#endif

#if defined( __WIN32__ ) || defined( _WIN32 ) || defined __CYGWIN__
# define TMPLPRO_HIDDEN_SYM
# if defined(HTMLTMPLPRO_STATIC)
#  define TMPLPRO_EXPORT_SYM
# else
#  if defined( htmltmplpro_EXPORTS ) || defined (DLL_EXPORT)
#   define TMPLPRO_EXPORT_SYM __declspec(dllexport)
#  else
#   define TMPLPRO_EXPORT_SYM __declspec(dllimport)
#  endif
# endif
#elif __GNUC__ >= 4
# define TMPLPRO_EXPORT_SYM __attribute__ ((visibility("default")))
# define TMPLPRO_HIDDEN_SYM __attribute__ ((visibility("hidden")))
#else
# define TMPLPRO_EXPORT_SYM
# define TMPLPRO_HIDDEN_SYM
#endif

#ifndef APICALL
#define APICALL
#endif
#ifndef BACKCALL
#define BACKCALL
#endif

#define TMPLPRO_API TMPLPRO_EXTERN_C TMPLPRO_EXPORT_SYM
#define API_IMPL TMPLPRO_EXPORT_SYM
#define TMPLPRO_LOCAL TMPLPRO_HIDDEN_SYM

#endif /* pabidecl.h */
