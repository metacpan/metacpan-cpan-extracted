/*
 * xxh64.h - XXH64 (xxHash 64-bit) for File::Raw::Hash.
 *
 * Non-cryptographic hash by Yann Collet. Spec:
 *   https://github.com/Cyan4973/xxHash/blob/dev/doc/xxhash_spec.md
 *
 * Used for fast content fingerprinting / dedup. Not for security.
 * Optional 64-bit seed; default seed is 0.
 */

#ifndef FILE_RAW_HASH_XXH64_H
#define FILE_RAW_HASH_XXH64_H

#include <stddef.h>
#include <stdint.h>

#define XXH64_DIGEST_SIZE 8
#define XXH64_BLOCK_SIZE  32      /* internal stripe size */

typedef struct {
    uint64_t v[4];                /* four lanes */
    uint64_t total_len;           /* bytes processed across all updates */
    uint64_t seed;                /* the seed in use */
    int      large_path_seen;     /* once we've processed any 32-byte stripe */
    unsigned char buffer[XXH64_BLOCK_SIZE];
    size_t buffered;
} xxh64_ctx_t;

/* Initialise with a 64-bit seed (0 is a sane default). */
void xxh64_init  (xxh64_ctx_t *ctx, uint64_t seed);
void xxh64_update(xxh64_ctx_t *ctx, const void *data, size_t len);
void xxh64_final (xxh64_ctx_t *ctx, unsigned char out[XXH64_DIGEST_SIZE]);

#endif /* FILE_RAW_HASH_XXH64_H */
