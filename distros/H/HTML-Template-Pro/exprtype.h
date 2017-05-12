/*! \file exprtype.h
    \brief description of EXPR variable type.
    
    EXPR variable type is passed to and from user-supplied functions.

    \author Igor Vlasenko <vlasenko@imath.kiev.ua>
    \warning This header file should never be included directly.
    Include <tmplpro.h> instead.
*/

#ifndef _EXPRTYPE_H
#define _EXPRTYPE_H	1

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#if HAVE_INTTYPES_H
#  include <inttypes.h>
#else
#  if HAVE_STDINT_H
#    include <stdint.h>
#  endif
#endif

#define EXPR_TYPE_INT 'i'
#define EXPR_TYPE_DBL 'd'
#define EXPR_TYPE_PSTR 'p'
/* NULL is for interface only, internally NULL pstring is used. */
#define EXPR_TYPE_NULL '\0'
/* UPSTR is for internal use only. it is never passed to user functions. */
#define EXPR_TYPE_UPSTR 'u'

#if defined INT64_MAX || defined int64_t
  typedef int64_t EXPR_int64;
#elif defined SIZEOF_LONG_LONG && SIZEOF_LONG_LONG == 8
  typedef long long int EXPR_int64;
#elif defined INT64_NAME
  typedef  INT64_NAME EXPR_int64;
#else
  typedef long int EXPR_int64;
#endif 

#if defined PRId64
#  define EXPR_PRId64 PRId64
#elif defined SIZEOF_LONG_LONG && SIZEOF_LONG_LONG == 8
#  define EXPR_PRId64 "lld"
#elif defined _MSC_VER
#  define EXPR_PRId64 "I64d"
#else 
#  define EXPR_PRId64 "ld"
#endif 

struct exprval;

#endif /* exprtype.h */

/*
 *  Local Variables:
 *  mode: c
 *  End:
 */
