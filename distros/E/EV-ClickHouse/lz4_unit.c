/* The bundled LZ4, built apart from perl.h (whose U64 and assert clash),
 * with every symbol hidden so another liblz4 in the process cannot clash.
 * System headers first: the pragma must not cover libc declarations. */
#include <limits.h>
#include <stdlib.h>
#include <string.h>
#include <stddef.h>
#include <stdint.h>
#include <assert.h>
#define LZ4_DISABLE_DEPRECATE_WARNINGS 1
#if defined(__GNUC__) && __GNUC__ >= 4
#  define LZ4LIB_VISIBILITY __attribute__ ((visibility ("hidden")))
#  pragma GCC visibility push(hidden)
#endif
#include "xs/lz4.c"
#if defined(__GNUC__) && __GNUC__ >= 4
#  pragma GCC visibility pop
#endif
