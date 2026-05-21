/*
 * sha2.h - SHA-256 and SHA-512 (FIPS 180-4) for File::Raw::Hash.
 *
 * Self-contained, plain C99. Both algorithms in one TU because they
 * share structure and the constant tables are the only material code
 * difference.
 */

#ifndef FILE_RAW_HASH_SHA2_H
#define FILE_RAW_HASH_SHA2_H

#include <stddef.h>
#include <stdint.h>

#define SHA256_DIGEST_SIZE 32
#define SHA256_BLOCK_SIZE  64
#define SHA512_DIGEST_SIZE 64
#define SHA512_BLOCK_SIZE  128

typedef struct {
    uint32_t state[8];
    uint64_t bit_count;
    unsigned char buffer[SHA256_BLOCK_SIZE];
    size_t buffered;
} sha256_ctx_t;

typedef struct {
    uint64_t state[8];
    /* SHA-512 spec uses a 128-bit length counter. We store low 64 bits
     * here and high 64 bits in `bit_count_high`. Real-world inputs
     * shorter than 2^64 bits never wrap, but we wire the high word
     * faithfully. */
    uint64_t bit_count_low;
    uint64_t bit_count_high;
    unsigned char buffer[SHA512_BLOCK_SIZE];
    size_t buffered;
} sha512_ctx_t;

void sha256_init  (sha256_ctx_t *ctx);
void sha256_update(sha256_ctx_t *ctx, const void *data, size_t len);
void sha256_final (sha256_ctx_t *ctx, unsigned char out[SHA256_DIGEST_SIZE]);

void sha512_init  (sha512_ctx_t *ctx);
void sha512_update(sha512_ctx_t *ctx, const void *data, size_t len);
void sha512_final (sha512_ctx_t *ctx, unsigned char out[SHA512_DIGEST_SIZE]);

#endif /* FILE_RAW_HASH_SHA2_H */
