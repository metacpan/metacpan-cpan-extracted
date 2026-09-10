#ifndef FZ_COMPAT_H
#define FZ_COMPAT_H

#if defined(_MSC_VER) && _MSC_VER < 1600
typedef unsigned char      uint8_t;
typedef unsigned short     uint16_t;
typedef unsigned int       uint32_t;
typedef signed   __int64   int64_t;
typedef unsigned __int64   uint64_t;
#else
#include <stdint.h>
#endif

#include <stddef.h>
#include <string.h>
#include <stdlib.h>

#ifndef PERL_UNUSED_CONTEXT
#  define PERL_UNUSED_CONTEXT ((void)0)
#endif

#ifndef PERL_UNUSED_ARG
#  define PERL_UNUSED_ARG(x) ((void)x)
#endif

#ifdef malloc
#  undef malloc
#endif
#ifdef realloc
#  undef realloc
#endif
#ifdef free
#  undef free
#endif

#endif
