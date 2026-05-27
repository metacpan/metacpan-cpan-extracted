/* src/simd/mds_simd_sse2.c — SSE2/SSSE3 classifier.
 *
 * Built when -DMDS_HAVE_SSE2 is set. Uses _mm_shuffle_epi8 (SSSE3) on
 * 16-byte chunks. SSSE3 is part of every x86_64 CPU since 2007, so we
 * treat it as a hard baseline for the "SSE2" backend.
 *
 * On the rare x86_64 host without SSSE3, the AVX2 build won't be
 * selected either, and the runtime dispatcher falls back to scalar.
 */
#include "mds_simd.h"
#include "mds_classifier_lut.h"

#ifdef MDS_HAVE_SSE2

#include <tmmintrin.h>      /* SSSE3 for _mm_shuffle_epi8 */
#include <emmintrin.h>

#if defined(__GNUC__) || defined(__clang__)
#  define MDS_SSSE3_FN __attribute__((target("ssse3")))
#else
#  define MDS_SSSE3_FN
#endif

MDS_SSSE3_FN static void classify_structural_sse2(const char* in, size_t len,
                                                   uint64_t* out)
{
    __m128i lo_tbl = _mm_loadu_si128((const __m128i*)MDS_CLASSIFIER_LO);
    __m128i hi_tbl = _mm_loadu_si128((const __m128i*)MDS_CLASSIFIER_HI);
    __m128i mask_lo = _mm_set1_epi8(0x0F);
    __m128i zero    = _mm_setzero_si128();

    size_t i = 0;
    while (i + 16 <= len) {
        __m128i v   = _mm_loadu_si128((const __m128i*)(in + i));
        __m128i lo  = _mm_and_si128(v, mask_lo);
        __m128i hi  = _mm_and_si128(_mm_srli_epi16(v, 4), mask_lo);
        __m128i la  = _mm_shuffle_epi8(lo_tbl, lo);
        __m128i ha  = _mm_shuffle_epi8(hi_tbl, hi);
        __m128i m   = _mm_and_si128(la, ha);
        __m128i nz  = _mm_cmpgt_epi8(m, zero);
        uint32_t bits = (uint32_t)(uint16_t)_mm_movemask_epi8(nz);

        size_t word = i >> 6;
        size_t off  = i & 63u;
        out[word] |= (uint64_t)bits << off;
        i += 16;
    }
    for (; i < len; i++) {
        uint8_t b = (uint8_t)in[i];
        if (MDS_CLASSIFIER_LO[b & 0xF] & MDS_CLASSIFIER_HI[b >> 4])
            out[i >> 6] |= (uint64_t)1 << (i & 63);
    }
}

static const mds_simd_ops* s_scalar(void) { return mds_simd_ops_scalar(); }

MDS_SSSE3_FN static int validate_utf8_sse2(const char* in, size_t len)
{
    const unsigned char* p   = (const unsigned char*)in;
    const unsigned char* end = p + len;

    while ((size_t)(end - p) >= 16) {
        __m128i v = _mm_loadu_si128((const __m128i*)p);
        int mask  = _mm_movemask_epi8(v);
        if (mask == 0) { p += 16; continue; }

        const unsigned char* tail = p + 16;
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

MDS_SSSE3_FN static size_t find_newlines_sse2(const char* in, size_t len,
                                              uint32_t* out, size_t cap)
{
    const char* p   = in;
    const char* end = in + len;
    __m128i needle  = _mm_set1_epi8('\n');
    size_t k = 0;

    while ((size_t)(end - p) >= 16) {
        __m128i v   = _mm_loadu_si128((const __m128i*)p);
        __m128i cmp = _mm_cmpeq_epi8(v, needle);
        unsigned m  = (unsigned)(uint16_t)_mm_movemask_epi8(cmp);
        if (m) {
            uint32_t base = (uint32_t)(p - in);
            do {
                unsigned bit = (unsigned)__builtin_ctz(m);
                if (k >= cap) return (size_t)-1;
                out[k++] = base + bit;
                m &= m - 1;
            } while (m);
        }
        p += 16;
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

MDS_SSSE3_FN static const char* next_structural_sse2(const char* p,
                                                     const char* end)
{ return s_scalar()->next_structural(p, end); }

MDS_SSSE3_FN static const char* next_structural_bm_sse2(const char* base,
                                                         size_t bm_len,
                                                         const uint64_t* bm,
                                                         size_t p_off)
{ return s_scalar()->next_structural_bm(base, bm_len, bm, p_off); }

static const mds_simd_ops k_ops_sse2 = {
    classify_structural_sse2,
    validate_utf8_sse2,
    find_newlines_sse2,
    next_structural_bm_sse2,
    next_structural_sse2,
};

const mds_simd_ops* mds_simd_ops_sse2(void) { return &k_ops_sse2; }

#endif /* MDS_HAVE_SSE2 */
