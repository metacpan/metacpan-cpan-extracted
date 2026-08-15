/* src/simd/mds_simd_dispatch.c — runtime backend selection.
 *
 * Selection order:
 *   1. If `mds_simd_force_scalar(1)` has been called, OR the env var
 *      MARKDOWN_SIMPLE_NO_SIMD is set to a truthy value, return scalar.
 *   2. On aarch64: return NEON (mandatory ISA extension).
 *   3. On x86_64: probe CPUID — AVX2 > SSE2/SSSE3 > scalar.
 *      (Stub builds without -DMDS_HAVE_* compile flags fall through,
 *      and never reach for CPUID at all.)
 *   4. Otherwise scalar.
 *
 * The selected ops table is cached in a static after first call.
 * `mds_simd_force_scalar()` invalidates the cache.
 */
#include "mds_simd.h"

#include <stdlib.h>
#include <string.h>

/* CPUID is only wanted when an x86 backend was actually compiled in - being
 * on x86 is not the same question. GCC has only shipped cpuid.h since 4.3
 * (and __cpuid_count since 4.4), so keying the include off the architecture
 * alone failed the whole build on FreeBSD 9, whose base cc is gcc 4.2.1,
 * where the Makefile.PL probes had already declined both backends and there
 * was nothing for CPUID to choose between. */
#if defined(__has_include)
#  if __has_include(<cpuid.h>)
#    define MDS_HAVE_CPUID_H 1
#  endif
#elif defined(__GNUC__) && (__GNUC__ > 4 || (__GNUC__ == 4 && __GNUC_MINOR__ >= 4))
#  define MDS_HAVE_CPUID_H 1
#endif

#if (defined(__x86_64__) || defined(_M_X64) || \
     defined(__i386__)   || defined(_M_IX86)) && \
    (defined(MDS_HAVE_SSE2) || defined(MDS_HAVE_AVX2))
#  if defined(_MSC_VER)
#    define MDS_SIMD_X86 1
#    include <intrin.h>
#  elif defined(MDS_HAVE_CPUID_H)
#    define MDS_SIMD_X86 1
#    include <cpuid.h>
#  endif
   /* No CPUID mechanism: the backend stays unselected and we run scalar,
    * which is the same answer this file gives on any non-x86 host. */
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

/* XCR0, to learn whether the OS actually restores the YMM half on a context
 * switch. Without this an AVX2-capable CPU under a kernel that never enabled
 * XSAVE executes vpand with a silently truncated register. Spelled as its
 * bytes because assemblers older than the instruction reject the mnemonic. */
static unsigned xcr0_low(void)
{
#  if defined(_MSC_VER)
    return (unsigned)_xgetbv(0);
#  else
    unsigned a, d;
    __asm__ __volatile__(".byte 0x0f, 0x01, 0xd0"
                         : "=a"(a), "=d"(d) : "c"(0));
    (void)d;
    return a;
#  endif
}

/* The "sse2" backend shuffles with pshufb, which is SSSE3, not SSE2: the
 * name is the build flag's, not the ISA level's. Checking only the SSE2 bit
 * selected it on an x86_64 CPU predating SSSE3 (K8, Prescott), where the
 * first classified chunk is an illegal instruction. Check what it runs. */
static int x86_has_ssse3(void)
{
    unsigned r[4];
    cpuid_call(1, 0, r);
    if (!(r[3] & (1u << 26))) return 0;  /* EDX bit 26: SSE2  */
    return (r[2] & (1u << 9)) != 0;      /* ECX bit  9: SSSE3 */
}

/* AVX2 needs three separate yeses: the CPU has AVX2 (and BMI2, which the
 * backend's target attribute lets the compiler emit), the OS has turned on
 * XSAVE, and XCR0 says the YMM state is among what it saves. */
static int x86_has_avx2(void)
{
    unsigned r[4];
    cpuid_call(1, 0, r);
    if (!(r[2] & (1u << 27))) return 0;  /* ECX bit 27: OSXSAVE */
    if (!(r[2] & (1u << 28))) return 0;  /* ECX bit 28: AVX     */
    if ((xcr0_low() & 0x6u) != 0x6u) return 0;   /* XMM | YMM saved */
    cpuid_call(0, 0, r);
    if (r[0] < 7) return 0;
    cpuid_call(7, 0, r);
    if (!(r[1] & (1u << 5))) return 0;   /* EBX bit 5: AVX2  */
    return (r[1] & (1u << 8)) != 0;      /* EBX bit 8: BMI2  */
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
    if (x86_has_ssse3()) {
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
