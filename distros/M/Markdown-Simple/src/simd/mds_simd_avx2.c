/* src/simd/mds_simd_avx2.c — AVX2 classifier.
 *
 * Processes 32 bytes per iteration. Each function carries
 * __attribute__((target("avx2,bmi2"))) so the TU compiles even when the
 * baseline does not enable AVX2. Runtime dispatch (CPUID in
 * mds_simd_dispatch.c) only routes calls here on capable CPUs.
 *
 * MSVC has no per-function target attribute; for MSVC, the build system
 * only adds this file when /arch:AVX2 is in effect.
 */
#include "mds_simd.h"
#include "mds_classifier_lut.h"

#ifdef MDS_HAVE_AVX2

#include <immintrin.h>

#if defined(__GNUC__) || defined(__clang__)
#  define MDS_AVX2_FN __attribute__((target("avx2,bmi2")))
#else
#  define MDS_AVX2_FN
#endif

MDS_AVX2_FN static void classify_structural_avx2(const char* in, size_t len,
                                                  uint64_t* out)
{
    /* Broadcast the 16-byte LUTs into both 128-bit lanes; _mm256_shuffle_epi8
     * is per-lane. */
    __m128i lo_tbl128 = _mm_loadu_si128((const __m128i*)MDS_CLASSIFIER_LO);
    __m128i hi_tbl128 = _mm_loadu_si128((const __m128i*)MDS_CLASSIFIER_HI);
    __m256i lo_tbl = _mm256_broadcastsi128_si256(lo_tbl128);
    __m256i hi_tbl = _mm256_broadcastsi128_si256(hi_tbl128);
    __m256i mask_lo = _mm256_set1_epi8(0x0F);
    __m256i zero    = _mm256_setzero_si256();

    size_t i = 0;
    while (i + 32 <= len) {
        __m256i v   = _mm256_loadu_si256((const __m256i*)(in + i));
        __m256i lo  = _mm256_and_si256(v, mask_lo);
        /* high nibble: srli_epi16 by 4 then mask 0x0F */
        __m256i hi  = _mm256_and_si256(_mm256_srli_epi16(v, 4), mask_lo);
        __m256i la  = _mm256_shuffle_epi8(lo_tbl, lo);
        __m256i ha  = _mm256_shuffle_epi8(hi_tbl, hi);
        __m256i m   = _mm256_and_si256(la, ha);
        /* Use cmpeq(m,0) then invert: cmpgt_epi8 is SIGNED, which would
         * misclassify bytes whose LUT product is 0x80 (e.g. '|' = 0x7C,
         * '~' = 0x7E) — they hit hi_tbl[7]=0x80 and would read as -128. */
        __m256i is_zero = _mm256_cmpeq_epi8(m, zero); /* 0xFF where m==0 */
        uint32_t bits = (uint32_t)(~_mm256_movemask_epi8(is_zero));

        size_t word = i >> 6;
        size_t off  = i & 63u;
        out[word] |= (uint64_t)bits << off;
        i += 32;
    }
    for (; i < len; i++) {
        uint8_t b = (uint8_t)in[i];
        if (MDS_CLASSIFIER_LO[b & 0xF] & MDS_CLASSIFIER_HI[b >> 4])
            out[i >> 6] |= (uint64_t)1 << (i & 63);
    }
}

#ifdef s_scalar
#  undef s_scalar
#endif
static const mds_simd_ops* s_scalar_avx2(void) { return mds_simd_ops_scalar(); }
#define s_scalar s_scalar_avx2

/* ASCII fast-path validator. Non-ASCII chunks delegate to scalar DFA
 * (after extending forward across any in-flight continuation bytes). */
MDS_AVX2_FN static int validate_utf8_avx2(const char* in, size_t len)
{
    const unsigned char* p   = (const unsigned char*)in;
    const unsigned char* end = p + len;

    while ((size_t)(end - p) >= 32) {
        __m256i v   = _mm256_loadu_si256((const __m256i*)p);
        /* movemask of v: bit i = (v[i] >> 7). If zero, all ASCII. */
        int mask    = _mm256_movemask_epi8(v);
        if (mask == 0) { p += 32; continue; }

        const unsigned char* tail = p + 32;
        if (tail > end) tail = end;
        int extend = 3;
        while (extend-- > 0 && tail < end && (*tail & 0xC0) == 0x80) tail++;
        if (!s_scalar()->validate_utf8((const char*)p, (size_t)(tail - p)))
            return 0;
        p = tail;
    }
    if (p < end) return s_scalar()->validate_utf8((const char*)p, (size_t)(end - p));
    return 1;
}

MDS_AVX2_FN static size_t find_newlines_avx2(const char* in, size_t len,
                                              uint32_t* out, size_t cap)
{
    const char* p   = in;
    const char* end = in + len;
    __m256i needle  = _mm256_set1_epi8('\n');
    size_t k = 0;

    while ((size_t)(end - p) >= 32) {
        __m256i v   = _mm256_loadu_si256((const __m256i*)p);
        __m256i cmp = _mm256_cmpeq_epi8(v, needle);
        uint32_t m  = (uint32_t)_mm256_movemask_epi8(cmp);
        if (m) {
            uint32_t base = (uint32_t)(p - in);
            do {
                unsigned bit = (unsigned)__builtin_ctz(m);
                if (k >= cap) return (size_t)-1;
                out[k++] = base + bit;
                m &= m - 1;                   /* clear lowest set bit */
            } while (m);
        }
        p += 32;
    }
    while (p < end) {
        if (*p == '\n') {
            if (k >= cap) return (size_t)-1;
            out[k++] = (uint32_t)(p - in);
        }
        p++;
    }
    return k;
}

MDS_AVX2_FN static const char* next_structural_avx2(const char* p,
                                                     const char* end)
{ return s_scalar()->next_structural(p, end); }

MDS_AVX2_FN static const char* next_structural_bm_avx2(const char* base,
                                                        size_t bm_len,
                                                        const uint64_t* bm,
                                                        size_t p_off)
{ return s_scalar()->next_structural_bm(base, bm_len, bm, p_off); }

static const mds_simd_ops k_ops_avx2 = {
    classify_structural_avx2,
    validate_utf8_avx2,
    find_newlines_avx2,
    next_structural_bm_avx2,
    next_structural_avx2,
};

const mds_simd_ops* mds_simd_ops_avx2(void) { return &k_ops_avx2; }

#endif /* MDS_HAVE_AVX2 */
