#ifndef HAMT_HASH_H
#define HAMT_HASH_H

/* The hash a key's position in the trie is read from: 64 bits over the key's
 * bytes, with a per-process seed.
 *
 * Seeded because a map will be keyed by somebody else's data sooner or
 * later, and with a fixed hash a client can choose keys that all share one
 * path. This is not a cryptographic hash and the seed is not a secret worth
 * much; it is enough that the layout cannot be computed from outside.
 *
 * The body is Frozen's fz_hash with a 64-bit seed. It reads the key eight
 * bytes at a time in host order, so the same key hashes differently on a
 * machine of the other endianness - which is fine, because nothing built
 * from it ever leaves the process. */

#define HAMT_M1 0xff51afd7ed558ccdULL
#define HAMT_M2 0xc4ceb9fe1a85ec53ULL
#define HAMT_M3 0x9e3779b97f4a7c15ULL

/* Set once when the library loads. The mask is all ones outside the tests,
 * which narrow it to force keys onto shared paths and into collision nodes. */
static uint64_t hamt_seed      = 0;
static uint64_t hamt_hash_mask = ~(uint64_t)0;

/* `utf8` is part of the key: the caller has already downgraded every key
 * that can be, so two keys with equal bytes and different flags are
 * different strings. Folding the flag in keeps them off each other's path
 * instead of leaving them to a full comparison at the end of it. */
static uint64_t hamt_hash(const char *s, size_t len, int utf8) {
    const unsigned char *p = (const unsigned char *)s;
    uint64_t h = HAMT_M3 ^ (hamt_seed * HAMT_M1) ^ (uint64_t)len;
    size_t i = 0;

    if (utf8) h ^= HAMT_M2;

    while (len - i >= 8) {
        uint64_t k;
        memcpy(&k, p + i, 8);
        k *= HAMT_M1;
        k ^= k >> 33;
        h ^= k;
        h *= HAMT_M2;
        i += 8;
    }
    if (i < len) {
        /* Byte by byte: a copy of a length not known until run time is a
         * call into the C library, and most keys are all tail. */
        uint64_t k = 0;
        size_t j, r = len - i;
        for (j = 0; j < r; j++) k |= (uint64_t)p[i + j] << (8 * j);
        k *= HAMT_M1;
        k ^= k >> 33;
        h ^= k;
        h *= HAMT_M2;
    }

    h ^= h >> 33;
    h *= HAMT_M1;
    h ^= h >> 29;
    return h & hamt_hash_mask;
}

/* Keep the low `bits` bits of every hash from here on. 64 or more restores
 * the whole of it. A container built under one setting must not be read
 * under another. */
static void hamt_hash_set_bits(unsigned bits) {
    hamt_hash_mask = bits >= 64 ? ~(uint64_t)0 : (((uint64_t)1 << bits) - 1);
}

#endif
