/* mds_compiler.h \u2014 branch / attribute portability macros.
 *
 * Pulled out into its own header so SIMD TUs (which already use
 * __attribute__((target(...))) ) and the scalar core agree on the
 * spelling, and so the macros become no-ops on compilers that don't
 * understand the GCC/Clang extensions.
 */
#ifndef MDS_COMPILER_H
#define MDS_COMPILER_H

#if defined(__GNUC__) || defined(__clang__)
#  define MDS_LIKELY(x)   __builtin_expect(!!(x), 1)
#  define MDS_UNLIKELY(x) __builtin_expect(!!(x), 0)
#  define MDS_HOT         __attribute__((hot))
#  define MDS_COLD        __attribute__((cold))
#  define MDS_NOINLINE    __attribute__((noinline))
#  define MDS_ALWAYS_INLINE __attribute__((always_inline)) inline
#else
#  define MDS_LIKELY(x)   (x)
#  define MDS_UNLIKELY(x) (x)
#  define MDS_HOT
#  define MDS_COLD
#  define MDS_NOINLINE
#  define MDS_ALWAYS_INLINE inline
#endif

#endif
