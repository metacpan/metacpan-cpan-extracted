/* src/simd/mds_simd_dispatch.c — runtime backend selection.
 *
 * Selection order:
 *   1. If `mds_simd_force_scalar(1)` has been called, OR the env var
 *      MARKDOWN_SIMPLE_NO_SIMD is set to a truthy value, return scalar.
 *   2. On aarch64: return NEON (mandatory ISA extension).
 *   3. On x86_64: probe CPUID — AVX2 > SSE2 > scalar.
 *      (Stub builds without -DMDS_HAVE_* compile flags fall through.)
 *   4. Otherwise scalar.
 *
 * The selected ops table is cached in a static after first call.
 * `mds_simd_force_scalar()` invalidates the cache.
 */
#include "mds_simd.h"

#include <stdlib.h>
#include <string.h>

#if defined(__x86_64__) || defined(_M_X64) || defined(__i386__) || defined(_M_IX86)
#  define MDS_SIMD_X86 1
#  if defined(_MSC_VER)
#    include <intrin.h>
#  else
#    include <cpuid.h>
#  endif
#endif

static int s_force_scalar = 0;
static const mds_simd_ops* s_cached = 0;
static const char*         s_cached_name = "scalar";

static int env_no_simd(void)
{
    const char* v = getenv("MARKDOWN_SIMPLE_NO_SIMD");
    if (!v || !*v) return 0;
    if (v[0] == '0' && v[1] == '\0') return 0;
    return 1;
}

#ifdef MDS_SIMD_X86
static void cpuid_call(unsigned leaf, unsigned subleaf, unsigned regs[4])
{
#  if defined(_MSC_VER)
    int r[4];
    __cpuidex(r, (int)leaf, (int)subleaf);
    regs[0] = (unsigned)r[0]; regs[1] = (unsigned)r[1];
    regs[2] = (unsigned)r[2]; regs[3] = (unsigned)r[3];
#  else
    unsigned a, b, c, d;
    __cpuid_count(leaf, subleaf, a, b, c, d);
    regs[0] = a; regs[1] = b; regs[2] = c; regs[3] = d;
#  endif
}

static int x86_has_sse2(void)
{
    unsigned r[4];
    cpuid_call(1, 0, r);
    return (r[3] & (1u << 26)) != 0;     /* EDX bit 26 */
}

static int x86_has_avx2(void)
{
    unsigned r[4];
    cpuid_call(0, 0, r);
    if (r[0] < 7) return 0;
    cpuid_call(7, 0, r);
    return (r[1] & (1u << 5)) != 0;      /* EBX bit 5  */
}
#endif /* MDS_SIMD_X86 */

static void pick(void)
{
    if (s_force_scalar || env_no_simd()) {
        s_cached      = mds_simd_ops_scalar();
        s_cached_name = "scalar";
        return;
    }
#ifdef MDS_HAVE_NEON
    /* aarch64 always; on 32-bit ARM the build system gates this. */
    s_cached      = mds_simd_ops_neon();
    s_cached_name = "neon";
    return;
#endif
#ifdef MDS_SIMD_X86
#  ifdef MDS_HAVE_AVX2
    if (x86_has_avx2()) {
        s_cached      = mds_simd_ops_avx2();
        s_cached_name = "avx2";
        return;
    }
#  endif
#  ifdef MDS_HAVE_SSE2
    if (x86_has_sse2()) {
        s_cached      = mds_simd_ops_sse2();
        s_cached_name = "sse2";
        return;
    }
#  endif
#endif
    s_cached      = mds_simd_ops_scalar();
    s_cached_name = "scalar";
}

const mds_simd_ops* mds_simd_get(void)
{
    if (!s_cached) pick();
    return s_cached;
}

const char* mds_simd_backend(void)
{
    if (!s_cached) pick();
    return s_cached_name;
}

void mds_simd_force_scalar(int on)
{
    s_force_scalar = on ? 1 : 0;
    s_cached       = 0;       /* invalidate; next call to _get() re-picks */
    s_cached_name  = "scalar";
}
