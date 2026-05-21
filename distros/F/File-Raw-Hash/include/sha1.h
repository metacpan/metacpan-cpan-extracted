/*
 * sha1.h - SHA-1 (FIPS 180-4) for File::Raw::Hash.
 *
 * Self-contained, plain C99. Cryptographically deprecated; kept for
 * git/openssh/tls-legacy interop. Don't use for new security designs.
 */

#ifndef FILE_RAW_HASH_SHA1_H
#define FILE_RAW_HASH_SHA1_H

#include <stddef.h>
#include <stdint.h>

#define SHA1_DIGEST_SIZE 20
#define SHA1_BLOCK_SIZE  64

typedef struct {
    uint32_t state[5];
    uint64_t bit_count;
    unsigned char buffer[SHA1_BLOCK_SIZE];
    size_t buffered;
} sha1_ctx_t;

void sha1_init  (sha1_ctx_t *ctx);
void sha1_update(sha1_ctx_t *ctx, const void *data, size_t len);
void sha1_final (sha1_ctx_t *ctx, unsigned char out[SHA1_DIGEST_SIZE]);

#endif /* FILE_RAW_HASH_SHA1_H */
