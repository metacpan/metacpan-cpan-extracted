/*
 * CityHash v1.0.2 — minimal implementation of CityHash128.
 * Used for ClickHouse native protocol compression checksums.
 *
 * Based on CityHash by Geoff Pike and Jyrki Alakuijala (Google).
 * Original code: https://github.com/google/cityhash
 * Reference: https://github.com/ClickHouse/ClickHouse/tree/master/contrib/cityhash102
 * License: MIT
 *
 * IMPORTANT: This is CityHash v1.0.2 specifically. Later versions
 * changed the algorithm and produce different results.
 */

#ifndef CITYHASH_H
#define CITYHASH_H

#include <stdint.h>
#include <string.h>

typedef struct { uint64_t lo, hi; } ch_uint128_t;

static inline uint64_t ch_fetch64(const char *p) {
    uint64_t r;
    memcpy(&r, p, 8);
    return r;
}

static inline uint32_t ch_fetch32(const char *p) {
    uint32_t r;
    memcpy(&r, p, 4);
    return r;
}

static inline uint64_t ch_rotate(uint64_t val, int shift) {
    return shift == 0 ? val : (val >> shift) | (val << (64 - shift));
}

static inline uint64_t ch_shift_mix(uint64_t val) {
    return val ^ (val >> 47);
}

static const uint64_t ch_k0 = 0xc3a5c85c97cb3127ULL;
static const uint64_t ch_k1 = 0xb492b66fbe98f273ULL;
static const uint64_t ch_k2 = 0x9ae16a3b2f90404fULL;
static const uint64_t ch_k3 = 0xc949d7c7509e6557ULL;

static inline uint64_t ch_hash128to64(ch_uint128_t x) {
    const uint64_t kMul = 0x9ddfea08eb382d69ULL;
    uint64_t a = (x.lo ^ x.hi) * kMul;
    a ^= (a >> 47);
    uint64_t b = (x.hi ^ a) * kMul;
    b ^= (b >> 47);
    b *= kMul;
    return b;
}

static inline uint64_t ch_hash_len16(uint64_t u, uint64_t v) {
    ch_uint128_t x = { u, v };
    return ch_hash128to64(x);
}

static inline uint64_t ch_hash_len0to16(const char *s, size_t len) {
    if (len > 8) {
        uint64_t a = ch_fetch64(s);
        uint64_t b = ch_fetch64(s + len - 8);
        return ch_hash_len16(a, ch_rotate(b + len, (int)len)) ^ b;
    }
    if (len >= 4) {
        uint64_t a = ch_fetch32(s);
        return ch_hash_len16(len + (a << 3), ch_fetch32(s + len - 4));
    }
    if (len > 0) {
        uint8_t a = (uint8_t)s[0];
        uint8_t b = (uint8_t)s[len >> 1];
        uint8_t c = (uint8_t)s[len - 1];
        uint32_t y = (uint32_t)a + ((uint32_t)b << 8);
        uint32_t z = (uint32_t)len + ((uint32_t)c << 2);
        return ch_shift_mix(y * ch_k2 ^ z * ch_k3) * ch_k2;
    }
    return ch_k2;
}

static inline void ch_weak_hash_len32_with_seeds_vals(
    uint64_t w, uint64_t x, uint64_t y, uint64_t z,
    uint64_t a, uint64_t b,
    uint64_t *out_lo, uint64_t *out_hi) {
    a += w;
    b = ch_rotate(b + a + z, 21);
    uint64_t c = a;
    a += x;
    a += y;
    b += ch_rotate(a, 44);
    *out_lo = a + z;
    *out_hi = b + c;
}

static inline void ch_weak_hash_len32_with_seeds(
    const char *s, uint64_t a, uint64_t b,
    uint64_t *out_lo, uint64_t *out_hi) {
    ch_weak_hash_len32_with_seeds_vals(
        ch_fetch64(s), ch_fetch64(s + 8),
        ch_fetch64(s + 16), ch_fetch64(s + 24),
        a, b, out_lo, out_hi);
}

static ch_uint128_t ch_city_murmur(const char *s, size_t len, ch_uint128_t seed) {
    uint64_t a = seed.lo;
    uint64_t b = seed.hi;
    uint64_t c = 0;
    uint64_t d = 0;

    if (len <= 16) {
        a = ch_shift_mix(a * ch_k1) * ch_k1;
        c = b * ch_k1 + ch_hash_len0to16(s, len);
        d = ch_shift_mix(a + (len >= 8 ? ch_fetch64(s) : c));
    } else {
        c = ch_hash_len16(ch_fetch64(s + len - 8) + ch_k1, a);
        d = ch_hash_len16(b + len, c + ch_fetch64(s + len - 16));
        a += d;
        do {
            a ^= ch_shift_mix(ch_fetch64(s) * ch_k1) * ch_k1;
            a *= ch_k1;
            b ^= a;
            c ^= ch_shift_mix(ch_fetch64(s + 8) * ch_k1) * ch_k1;
            c *= ch_k1;
            d ^= c;
            s += 16;
            len -= 16;
        } while (len > 16);
    }
    a = ch_hash_len16(a, c);
    b = ch_hash_len16(d, b);

    ch_uint128_t r = { a ^ b, ch_hash_len16(b, a) };
    return r;
}

static ch_uint128_t ch_city_hash128_with_seed(const char *s, size_t len, ch_uint128_t seed) {
    if (len < 128) return ch_city_murmur(s, len, seed);

    uint64_t x = seed.lo;
    uint64_t y = seed.hi;
    uint64_t z = (uint64_t)len * ch_k1;
    uint64_t vlo, vhi, wlo, whi;
    vlo = ch_rotate(y ^ ch_k1, 49) * ch_k1 + ch_fetch64(s);
    vhi = ch_rotate(vlo, 42) * ch_k1 + ch_fetch64(s + 8);
    wlo = ch_rotate(y + z, 35) * ch_k1 + x;
    whi = ch_rotate(x + ch_fetch64(s + 88), 53) * ch_k1;

    do {
        x = ch_rotate(x + y + vlo + ch_fetch64(s + 16), 37) * ch_k1;
        y = ch_rotate(y + vhi + ch_fetch64(s + 48), 42) * ch_k1;
        x ^= whi;
        y ^= vlo;
        z = ch_rotate(z ^ wlo, 33);
        ch_weak_hash_len32_with_seeds(s, vhi * ch_k1, x + wlo, &vlo, &vhi);
        ch_weak_hash_len32_with_seeds(s + 32, z + whi, y, &wlo, &whi);
        {   uint64_t tmp = z; z = x; x = tmp; }
        s += 64;

        x = ch_rotate(x + y + vlo + ch_fetch64(s + 16), 37) * ch_k1;
        y = ch_rotate(y + vhi + ch_fetch64(s + 48), 42) * ch_k1;
        x ^= whi;
        y ^= vlo;
        z = ch_rotate(z ^ wlo, 33);
        ch_weak_hash_len32_with_seeds(s, vhi * ch_k1, x + wlo, &vlo, &vhi);
        ch_weak_hash_len32_with_seeds(s + 32, z + whi, y, &wlo, &whi);
        {   uint64_t tmp = z; z = x; x = tmp; }
        s += 64;

        len -= 128;
    } while (len >= 128);

    y += ch_rotate(wlo, 37) * ch_k0 + z;
    x += ch_rotate(vlo + z, 49) * ch_k0;

    size_t tail_done;
    for (tail_done = 0; tail_done < len; ) {
        tail_done += 32;
        y = ch_rotate(y - x, 42) * ch_k0 + vhi;
        wlo += ch_fetch64(s + len - tail_done + 16);
        x = ch_rotate(x, 49) * ch_k0 + wlo;
        wlo += vlo;
        ch_weak_hash_len32_with_seeds(s + len - tail_done, vlo, vhi, &vlo, &vhi);
    }

    x = ch_hash_len16(x, vlo);
    y = ch_hash_len16(y, wlo);

    ch_uint128_t r = {
        ch_hash_len16(x + vhi, whi) + y,
        ch_hash_len16(x + whi, y + vhi)
    };
    return r;
}

static ch_uint128_t ch_city_hash128(const char *s, size_t len) {
    if (len >= 16) {
        ch_uint128_t seed = { ch_fetch64(s) ^ ch_k3, ch_fetch64(s + 8) };
        return ch_city_hash128_with_seed(s + 16, len - 16, seed);
    }
    if (len >= 8) {
        ch_uint128_t seed = { ch_fetch64(s) ^ ((uint64_t)len * ch_k0), ch_fetch64(s + len - 8) ^ ch_k1 };
        return ch_city_hash128_with_seed(NULL, 0, seed);
    }
    ch_uint128_t seed = { ch_k0, ch_k1 };
    return ch_city_hash128_with_seed(s, len, seed);
}

#endif /* CITYHASH_H */
