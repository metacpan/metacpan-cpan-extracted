/* mds_compiler.h \u2014 branch / attribute portability macros.
 *
 * Pulled out into its own header so SIMD TUs (which already use
 * __attribute__((target(...))) ) and the scalar core agree on the
 * spelling, and so the macros become no-ops on compilers that don't
 * understand the GCC/Clang extensions.
 */
#ifndef MDS_COMPILER_H
#define MDS_COMPILER_H

/* `inline` was added in C99. Under -std=c89 / -ansi the bare keyword is
 * rejected even though GCC/Clang have always supported `__inline__` as
 * an extension. Map it transparently so we don't have to litter the
 * source with MDS_INLINE macros. */
#if (defined(__GNUC__) || defined(__clang__)) && \
    (!defined(__STDC_VERSION__) || __STDC_VERSION__ < 199901L) && \
    !defined(__cplusplus) && !defined(inline)
#  define inline __inline__
#endif

/* hot/cold are GCC 4.3, later than the rest of what this block assumes, so
 * they get their own gate: gcc 4.2 warns "attribute directive ignored" once
 * per marked function, which is eight lines of noise per build on hosts like
 * FreeBSD 9. Clang answers through __has_attribute. */
#if defined(__has_attribute)
#  if __has_attribute(hot)
#    define MDS_HAVE_HOT_COLD 1
#  endif
#elif defined(__GNUC__) && (__GNUC__ > 4 || (__GNUC__ == 4 && __GNUC_MINOR__ >= 3))
#  define MDS_HAVE_HOT_COLD 1
#endif

#if defined(__GNUC__) || defined(__clang__)
#  define MDS_LIKELY(x)   __builtin_expect(!!(x), 1)
#  define MDS_UNLIKELY(x) __builtin_expect(!!(x), 0)
#  ifdef MDS_HAVE_HOT_COLD
#    define MDS_HOT       __attribute__((hot))
#    define MDS_COLD      __attribute__((cold))
#  else
#    define MDS_HOT
#    define MDS_COLD
#  endif
#  define MDS_NOINLINE    __attribute__((noinline))
   /* Use __inline__ (always available) rather than `inline` so we compile
    * under strict -std=c89 / -ansi without dropping the always_inline hint. */
#  define MDS_ALWAYS_INLINE __attribute__((always_inline)) __inline__
#elif defined(__STDC_VERSION__) && __STDC_VERSION__ >= 199901L
#  define MDS_LIKELY(x)   (x)
#  define MDS_UNLIKELY(x) (x)
#  define MDS_HOT
#  define MDS_COLD
#  define MDS_NOINLINE
#  define MDS_ALWAYS_INLINE inline
#else
#  define MDS_LIKELY(x)   (x)
#  define MDS_UNLIKELY(x) (x)
#  define MDS_HOT
#  define MDS_COLD
#  define MDS_NOINLINE
#  define MDS_ALWAYS_INLINE /* no inline keyword in C89 */
#endif

#endif
