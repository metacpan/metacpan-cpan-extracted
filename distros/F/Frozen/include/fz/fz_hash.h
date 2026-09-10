#ifndef FZ_HASH_H
#define FZ_HASH_H

#include "fz/fz_compat.h"

#define FZ_M1 0xff51afd7ed558ccdULL
#define FZ_M2 0xc4ceb9fe1a85ec53ULL
#define FZ_M3 0x9e3779b97f4a7c15ULL

static uint64_t fz_hash(const char *s, size_t len, uint32_t seed) {
    const unsigned char *p = (const unsigned char *)s;
    uint64_t h = FZ_M3 ^ ((uint64_t)seed * FZ_M1) ^ (uint64_t)len;
    size_t i = 0;

    while (len - i >= 8) {
        uint64_t k;
        memcpy(&k, p + i, 8);
        k *= FZ_M1;
        k ^= k >> 33;
        h ^= k;
        h *= FZ_M2;
        i += 8;
    }
    if (i < len) {
        uint64_t k = 0;
        memcpy(&k, p + i, len - i);
        k *= FZ_M1;
        k ^= k >> 33;
        h ^= k;
        h *= FZ_M2;
    }

    h ^= h >> 33;
    h *= FZ_M1;
    h ^= h >> 29;
    return h;
}

static uint64_t fz_remix(uint64_t h) {
    h *= FZ_M3;
    h ^= h >> 31;
    return h;
}

static uint32_t fz_mix32(uint32_t x) {
    x ^= x >> 16;
    x *= 0x7feb352dU;
    x ^= x >> 15;
    x *= 0x846ca68bU;
    x ^= x >> 16;
    return x;
}

#endif
