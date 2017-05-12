/* Creation date: 2008-04-05T03:57:11Z
 * Authors: Don
 */

/* $Header: /repository/projects/libjsonevt/int_defs.h,v 1.2 2008-04-17 04:15:29 don Exp $ */

#ifndef INT_DEFS_H
#define INT_DEFS_H

#include <jsonevt_config.h>

#ifdef JSONEVT_DEF_HAVE_INTTYPES_H
#include <inttypes.h>
#endif
#ifdef JSONEVT_DEF_HAVE_STDINT_H
#include <stdint.h>
#endif

/*
#ifdef _MSC_VER
typedef unsigned __int8   uint8_t;
typedef unsigned __int32  uint32_t;
#else

#if 0
#ifdef __FreeBSD__
#include <inttypes.h>
#else
#include <stdint.h>
#endif
#endif

#endif
*/

#endif /* INT_DEFS_H */

