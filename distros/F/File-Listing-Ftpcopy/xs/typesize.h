/*
 * Copyright (C) 1999,2000,2001 Uwe Ohse <uwe@ohse.de>
 * 
 * placed in the public domain.
 * 
 *
 * @(#) $Id: typesize.h 1.6 01/09/06 07:28:04+00:00 uwe@fjoras.ohse.de $
 */
#ifndef TYPESIZE_H
#define TYPESIZE_H

#ifndef HAVE_CONFIG_H
#include "auto-typesize.h"
#endif

/* Note: i'm not very happy about this.
 * But some compilers define a int16_t, others dont. 
 */

#ifndef SIZEOF_SHORT
/* no #error, pre ansi compiler tend to warn .. */
error SIZEOF_SHORT not defined, did you include the macros in config.h and acconfig.h?
#endif

/* int16 */
#if SIZEOF_SHORT >= 2 
typedef short uo_int16_t;
#else
typedef int uo_int16_t;
#endif

/* uo_int16 */
#if SIZEOF_UNSIGNED_SHORT >= 2 
typedef unsigned short uo_uint16_t;
#else
typedef unsigned int uo_uint16_t;
#endif

/* int32 */
#if SIZEOF_SHORT >= 4 
typedef short uo_int32_t;
#else 
# if SIZEOF_INT >= 4 
typedef int uo_int32_t;
# else
#  if SIZEOF_LONG >= 4 
typedef long uo_int32_t;
#  else
#   if SIZEOF_LONG_LONG >= 4 
typedef long long uo_int32_t;
#   else
error no 32bit integer available
#   endif
#  endif
# endif
#endif

/* uo_int32 */
#if SIZEOF_UNSIGNED_SHORT >= 4 
typedef unsigned short uo_uint32_t;
#else 
# if SIZEOF_UNSIGNED_INT >= 4 
typedef unsigned int uo_uint32_t;
# else
#  if SIZEOF_UNSIGNED_LONG >= 4 
typedef unsigned long uo_uint32_t;
#  else
#   if SIZEOF_UNSIGNED_LONG_LONG >= 4 
typedef unsigned long long uo_uint32_t;
#   else
error no 32bit unsigned integer available
#   endif
#  endif
# endif
#endif

#ifdef __GNUC__
#define TYPESIZE_QUIET __extension__
#else
#define TYPESIZE_QUIET
#endif

/* int64 */
#define HAVE_INT64
#if SIZEOF_INT >= 8 
typedef int uo_int64_t;
#else
# if SIZEOF_LONG >= 8
typedef long uo_int64_t;
# else
#  if SIZEOF_LONG_LONG >= 8
TYPESIZE_QUIET typedef long long uo_int64_t;
#  else
#   undef HAVE_INT64
#  endif
# endif
#endif


/* uo_uint64 */
#define HAVE_UINT64
#if SIZEOF_UNSIGNED_INT >= 8 
typedef unsigned int uo_uint64_t;
#else
# if SIZEOF_UNSIGNED_LONG >= 8 
typedef unsigned long uo_uint64_t;
# else
#  if SIZEOF_UNSIGNED_LONG_LONG >= 8 
TYPESIZE_QUIET typedef unsigned long long uo_uint64_t;
#  else
#   undef HAVE_INT64
#  endif
# endif
#endif

#endif
