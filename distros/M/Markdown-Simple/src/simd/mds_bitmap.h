/* src/simd/mds_bitmap.h — bitmap helpers used by the SIMD classifier
 * and the structural-byte cursor.
 *
 * The bitmap is stored as an array of uint64_t words; bit i is at
 * word i/64, position i%64 (LSB-first). Operations are inline and
 * compile to a couple of instructions on every target.
 */
#ifndef MDS_BITMAP_H
#define MDS_BITMAP_H

#include <stddef.h>
#include <stdint.h>

/* ceil(n_bits / 64) — size in words of a bitmap covering n_bits bits. */
static inline size_t mds_bm_words(size_t n_bits) {
    return (n_bits + 63u) >> 6;
}

/* Find the next set bit at or after `from`. Returns the bit index, or
 * (size_t)-1 if none in [from, n_bits). */
static inline size_t mds_bm_next_set(const uint64_t* bm, size_t n_bits,
                                     size_t from)
{
    if (from >= n_bits) return (size_t)-1;
    size_t w = from >> 6;
    size_t off = from & 63u;
    uint64_t v = bm[w] & (~(uint64_t)0 << off);
    while (1) {
        if (v) {
#if defined(__GNUC__) || defined(__clang__)
            size_t bit = (size_t)__builtin_ctzll(v);
#else
            size_t bit = 0;
            while ((v & 1ull) == 0) { v >>= 1; bit++; }
#endif
            size_t idx = (w << 6) | bit;
            return (idx < n_bits) ? idx : (size_t)-1;
        }
        w++;
        if ((w << 6) >= n_bits) return (size_t)-1;
        v = bm[w];
    }
}

/* Number of set bits in [from, to). Bounds-checked against n_bits. */
static inline size_t mds_bm_popcount(const uint64_t* bm, size_t n_bits,
                                     size_t from, size_t to)
{
    if (to > n_bits) to = n_bits;
    if (from >= to)  return 0;
    size_t w0 = from >> 6;
    size_t w1 = (to - 1) >> 6;
    uint64_t lo_mask = ~(uint64_t)0 << (from & 63u);
    uint64_t hi_mask = (to & 63u) ? (((uint64_t)1 << (to & 63u)) - 1)
                                  : ~(uint64_t)0;
    size_t pc = 0;
    if (w0 == w1) {
#if defined(__GNUC__) || defined(__clang__)
        return (size_t)__builtin_popcountll(bm[w0] & lo_mask & hi_mask);
#else
        uint64_t v = bm[w0] & lo_mask & hi_mask;
        while (v) { pc += (size_t)(v & 1); v >>= 1; }
        return pc;
#endif
    }
#if defined(__GNUC__) || defined(__clang__)
    pc += (size_t)__builtin_popcountll(bm[w0] & lo_mask);
    for (size_t w = w0 + 1; w < w1; w++)
        pc += (size_t)__builtin_popcountll(bm[w]);
    pc += (size_t)__builtin_popcountll(bm[w1] & hi_mask);
#else
    {
        uint64_t v;
        v = bm[w0] & lo_mask; while (v) { pc += (size_t)(v & 1); v >>= 1; }
        for (size_t w = w0 + 1; w < w1; w++) {
            v = bm[w]; while (v) { pc += (size_t)(v & 1); v >>= 1; }
        }
        v = bm[w1] & hi_mask; while (v) { pc += (size_t)(v & 1); v >>= 1; }
    }
#endif
    return pc;
}

#endif /* MDS_BITMAP_H */
