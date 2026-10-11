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

/* HeUTF8, mPUSHs and mXPUSHs arrived in 5.10.1, and MIN_PERL_VERSION is 5.010:
 * an OmniOS smoker's 5.10.0 refused to compile fz_build.h and read.xs for want
 * of the first two. These are ppport.h's definitions; this header follows
 * perl.h in Frozen.xs, so each is defined only where perl has not. */
#ifndef HeUTF8
#  define HeUTF8(he) ((HeKLEN(he) == HEf_SVKEY) \
                      ? SvUTF8(HeKEY_sv(he)) : (U32)HeKUTF8(he))
#endif
#ifndef mPUSHs
#  define mPUSHs(s) PUSHs(sv_2mortal(s))
#endif
#ifndef mXPUSHs
#  define mXPUSHs(s) XPUSHs(sv_2mortal(s))
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
