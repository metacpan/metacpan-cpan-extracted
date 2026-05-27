/* src/simd/mds_simd_scalar.c — reference implementation.
 *
 * Defines the semantics; every other backend must produce identical
 * output for identical input. AVX2/SSE2/NEON backends may delegate
 * here for operations they have not specialised.
 */
#include "mds_simd.h"
#include "mds_classifier_lut.h"
#include <string.h>

/* Bytes that "start something" in CommonMark/GFM. Kept in sync with
 * src/mds_block.c (block recognisers) and src/mds_inline.c (inline).
 * The set of structural bytes is defined by mds_classifier_truth() in
 * mds_classifier_lut.h — the scalar path uses that exact same lookup
 * so the SIMD backends can be fuzz-checked against it. */

static void classify_structural_scalar(const char* in, size_t len,
                                       uint64_t* out_bitmap)
{
    const uint8_t* p = (const uint8_t*)in;
    for (size_t i = 0; i < len; i++) {
        uint8_t b = p[i];
        uint8_t m = (uint8_t)(MDS_CLASSIFIER_LO[b & 0xF] &
                              MDS_CLASSIFIER_HI[b >> 4]);
        if (m) out_bitmap[i >> 6] |= (uint64_t)1 << (i & 63);
    }
}

/* Minimal-correctness UTF-8 validator. Spec: RFC 3629. Rejects
 * overlong sequences and surrogate halves. */
static int validate_utf8_scalar(const char* in, size_t len)
{
    const uint8_t* p = (const uint8_t*)in;
    const uint8_t* e = p + len;
    while (p < e) {
        uint8_t c = *p;
        if (c < 0x80) { p++; continue; }
        unsigned need;
        uint32_t cp;
        uint32_t lo, hi;
        if      ((c & 0xE0) == 0xC0) { need = 1; cp = c & 0x1F; lo = 0x80;    hi = 0x7FF; }
        else if ((c & 0xF0) == 0xE0) { need = 2; cp = c & 0x0F; lo = 0x800;   hi = 0xFFFF; }
        else if ((c & 0xF8) == 0xF0) { need = 3; cp = c & 0x07; lo = 0x10000; hi = 0x10FFFF; }
        else return 0;
        if (p + 1 + need > e) return 0;
        for (unsigned i = 0; i < need; i++) {
            uint8_t cc = p[1 + i];
            if ((cc & 0xC0) != 0x80) return 0;
            cp = (cp << 6) | (cc & 0x3F);
        }
        if (cp < lo || cp > hi)            return 0;
        if (cp >= 0xD800 && cp <= 0xDFFF)  return 0;
        p += 1 + need;
    }
    return 1;
}

static size_t find_newlines_scalar(const char* in, size_t len,
                                   uint32_t* out_offsets, size_t cap)
{
    const char* p   = in;
    const char* end = in + len;
    size_t k = 0;
    while (p < end) {
        const char* nl = (const char*)memchr(p, '\n', (size_t)(end - p));
        if (!nl) break;
        if (k >= cap) return (size_t)-1;          /* overflow sentinel */
        out_offsets[k++] = (uint32_t)(nl - in);
        p = nl + 1;
    }
    return k;
}

static const char* next_structural_scalar(const char* p, const char* end)
{
    const uint8_t* q = (const uint8_t*)p;
    const uint8_t* e = (const uint8_t*)end;
    while (q < e) {
        uint8_t b = *q;
        if (MDS_CLASSIFIER_LO[b & 0xF] & MDS_CLASSIFIER_HI[b >> 4]) break;
        q++;
    }
    return (const char*)q;
}

/* Bitmap-aware variant: ctzll walk over uint64_t words.  O(set-bits). */
static const char* next_structural_bm_scalar(const char* base, size_t bm_len,
                                             const uint64_t* bm, size_t p_off)
{
    if (p_off >= bm_len) return base + bm_len;
    size_t word  = p_off >> 6;
    size_t off   = p_off & 63u;
    /* First (possibly partial) word: mask out bits before p_off. */
    uint64_t w = bm[word] & (~(uint64_t)0 << off);
    if (w) {
        size_t bit = (size_t)__builtin_ctzll(w);
        size_t cand = (word << 6) + bit;
        return base + (cand < bm_len ? cand : bm_len);
    }
    /* Full words after. */
    size_t nwords = (bm_len + 63) >> 6;
    for (size_t i = word + 1; i < nwords; i++) {
        uint64_t v = bm[i];
        if (v) {
            size_t bit = (size_t)__builtin_ctzll(v);
            size_t cand = (i << 6) + bit;
            return base + (cand < bm_len ? cand : bm_len);
        }
    }
    return base + bm_len;
}

static const mds_simd_ops k_ops_scalar = {
    classify_structural_scalar,
    validate_utf8_scalar,
    find_newlines_scalar,
    next_structural_bm_scalar,
    next_structural_scalar,
};

const mds_simd_ops* mds_simd_ops_scalar(void) { return &k_ops_scalar; }
