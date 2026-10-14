#ifndef HAMT_COMPAT_H
#define HAMT_COMPAT_H

/* No perl type and no perl header: the core that includes this also builds
 * into a plain C harness. */

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

/* Under PERL_IMPLICIT_SYS, XSUB.h turns these into macros that need an
 * interpreter in scope. The core has none, so it gets the C library's back.
 * Nothing allocated here is ever handed to perl to free, or the reverse. */
#ifdef malloc
#  undef malloc
#endif
#ifdef realloc
#  undef realloc
#endif
#ifdef free
#  undef free
#endif
#ifdef abort
#  undef abort
#endif

/* Bits set in a 32-bit word. Not called popcount32: NetBSD's libc declares
 * that name, and popcount64, in <strings.h>. The builtin is used where the
 * compiler has one and needs no flag to offer it; without -mpopcnt it is a
 * call into the compiler's runtime, which is still correct everywhere. */
#if defined(__GNUC__) || defined(__clang__)
#  define hamt_popcnt32(x) ((uint32_t)__builtin_popcount((unsigned int)(x)))
#else
static uint32_t hamt_popcnt32(uint32_t x) {
    x = x - ((x >> 1) & 0x55555555U);
    x = (x & 0x33333333U) + ((x >> 2) & 0x33333333U);
    x = (x + (x >> 4)) & 0x0f0f0f0fU;
    return (x * 0x01010101U) >> 24;
}
#endif

#endif
