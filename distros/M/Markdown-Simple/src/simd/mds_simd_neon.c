/* src/simd/mds_simd_neon.c — NEON classifier.
 *
 * Built when -DMDS_HAVE_NEON is set (always true on aarch64). Uses the
 * two 16-byte LUTs from src/simd/mds_classifier_lut.h and `vqtbl1q_u8`
 * to classify 16 bytes per iteration. validate_utf8 / find_newlines /
 * next_structural delegate to the scalar reference.
 */
#include "mds_simd.h"
#include "mds_classifier_lut.h"

#ifdef MDS_HAVE_NEON

#include <arm_neon.h>
#include <string.h>

/* Extract a 16-bit "movemask" from a NEON byte vector whose lanes are
 * either 0x00 or some nonzero value. We first reduce to one-bit-per-
 * lane via vtstq_u8, then weight each lane by 1,2,4,...,128 (repeated)
 * and horizontally sum each half with vaddv_u8 (AArch64-only). */
static inline uint32_t neon_mask16(uint8x16_t v) {
    static const uint8_t k_weights[16] = {
        0x01,0x02,0x04,0x08,0x10,0x20,0x40,0x80,
        0x01,0x02,0x04,0x08,0x10,0x20,0x40,0x80
    };
    uint8x16_t w  = vld1q_u8(k_weights);
    uint8x16_t nz = vtstq_u8(v, v);           /* 0xFF where v != 0, else 0 */
    uint8x16_t t  = vandq_u8(nz, w);
    uint8_t lo = vaddv_u8(vget_low_u8(t));
    uint8_t hi = vaddv_u8(vget_high_u8(t));
    return (uint32_t)lo | ((uint32_t)hi << 8);
}

static void classify_structural_neon(const char* in, size_t len,
                                     uint64_t* out)
{
    uint8x16_t lo_tbl = vld1q_u8(MDS_CLASSIFIER_LO);
    uint8x16_t hi_tbl = vld1q_u8(MDS_CLASSIFIER_HI);
    uint8x16_t mask_lo = vdupq_n_u8(0x0F);

    size_t i = 0;
    while (i + 16 <= len) {
        uint8x16_t v   = vld1q_u8((const uint8_t*)(in + i));
        uint8x16_t lo  = vandq_u8(v, mask_lo);
        uint8x16_t hi  = vshrq_n_u8(v, 4);
        uint8x16_t la  = vqtbl1q_u8(lo_tbl, lo);
        uint8x16_t ha  = vqtbl1q_u8(hi_tbl, hi);
        uint8x16_t m   = vandq_u8(la, ha);
        uint32_t  bits = neon_mask16(m);

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

#ifdef s_scalar
#  undef s_scalar
#endif
static const mds_simd_ops* s_scalar_neon(void) { return mds_simd_ops_scalar(); }
#define s_scalar s_scalar_neon

/* ---- UTF-8 validation (ASCII fast-path + scalar tail per chunk) ------
 *
 * Process 32-byte chunks. If the chunk is pure ASCII (every byte's high
 * bit is zero) we skip it for free. Otherwise we delegate that chunk
 * (and any partial continuation it implies) to the scalar DFA, which is
 * already the canonical reference. The "step back to last leading byte"
 * trick keeps us correct across multi-byte sequences that straddle a
 * chunk boundary. */
static int validate_utf8_neon(const char* in, size_t len)
{
    const uint8_t* p   = (const uint8_t*)in;
    const uint8_t* end = p + len;

    /* Align loop to 32-byte stride for predictable behaviour. */
    while ((size_t)(end - p) >= 32) {
        uint8x16_t v0 = vld1q_u8(p);
        uint8x16_t v1 = vld1q_u8(p + 16);
        uint8x16_t hi = vorrq_u8(v0, v1);
        /* vmaxvq_u8 is AArch64; gives the largest byte in the vector.
         * If <0x80, every byte is pure ASCII. */
        if (vmaxvq_u8(hi) < 0x80) { p += 32; continue; }

        /* Non-ASCII present: rewind to the start of any in-flight
         * multi-byte sequence (continuation bytes are 10xxxxxx) so the
         * scalar DFA sees a coherent run. */
        const uint8_t* chunk_end = p + 32;
        if (chunk_end > end) chunk_end = end;
        const uint8_t* tail = chunk_end;
        /* Extend tail forward while next byte is a continuation, up to
         * a small bounded window (max UTF-8 sequence = 4 bytes). */
        int extend = 3;
        while (extend-- > 0 && tail < end && (*tail & 0xC0) == 0x80) tail++;

        if (!s_scalar()->validate_utf8((const char*)p, (size_t)(tail - p)))
            return 0;
        p = tail;
    }
    if (p < end) return s_scalar()->validate_utf8((const char*)p, (size_t)(end - p));
    return 1;
}

/* ---- Line scanner: vceqq_u8 + vshrn_n_u16 narrow trick --------------
 *
 * Daniel Lemire's "movemask on NEON" technique: comparing a 16-byte
 * register against a constant yields 0x00 / 0xFF lanes. Reinterpreting
 * as 16-bit and using `vshrn_n_u16` with shift 4 collapses pairs of
 * lanes to 4 bits each, producing a 64-bit value with 4 bits per input
 * byte. ctzll then locates set runs. */
static size_t find_newlines_neon(const char* in, size_t len,
                                 uint32_t* out, size_t cap)
{
    const uint8_t* p   = (const uint8_t*)in;
    const uint8_t* end = p + len;
    uint8x16_t needle = vdupq_n_u8('\n');
    size_t k = 0;

    while ((size_t)(end - p) >= 16) {
        uint8x16_t v   = vld1q_u8(p);
        uint8x16_t cmp = vceqq_u8(v, needle);
        /* Narrow each 16-bit pair to 8 bits (top nibble retained), then
         * reinterpret as a single uint64_t. Set lanes contribute 0xF
         * nibbles; unset lanes contribute 0. */
        uint8x8_t  narrow = vshrn_n_u16(vreinterpretq_u16_u8(cmp), 4);
        uint64_t   mask   = vget_lane_u64(vreinterpret_u64_u8(narrow), 0);
        if (mask) {
            uint32_t base = (uint32_t)(p - (const uint8_t*)in);
            /* Every set nibble = one newline. Use ctzll/4 to find byte
             * position, then clear that nibble and repeat. */
            do {
                unsigned bit  = (unsigned)__builtin_ctzll(mask);
                unsigned byte = bit >> 2;       /* 4 bits per input byte */
                if (k >= cap) return (size_t)-1;
                out[k++] = base + byte;
                /* Clear the whole nibble at this position. */
                mask &= ~((uint64_t)0xF << (byte << 2));
            } while (mask);
        }
        p += 16;
    }
    /* Scalar tail. */
    while (p < end) {
        if (*p == '\n') {
            if (k >= cap) return (size_t)-1;
            out[k++] = (uint32_t)(p - (const uint8_t*)in);
        }
        p++;
    }
    return k;
}

static const char* next_structural_neon(const char* p, const char* end)
{ return s_scalar()->next_structural(p, end); }

static const char* next_structural_bm_neon(const char* base, size_t bm_len,
                                            const uint64_t* bm, size_t p_off)
{ return s_scalar()->next_structural_bm(base, bm_len, bm, p_off); }

static const mds_simd_ops k_ops_neon = {
    classify_structural_neon,
    validate_utf8_neon,
    find_newlines_neon,
    next_structural_bm_neon,
    next_structural_neon,
};

const mds_simd_ops* mds_simd_ops_neon(void) { return &k_ops_neon; }

#endif /* MDS_HAVE_NEON */
