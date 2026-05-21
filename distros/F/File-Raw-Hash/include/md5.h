/*
 * md5.h - MD5 (RFC 1321) for File::Raw::Hash.
 *
 * Self-contained, plain C99. The algorithm is broken for cryptographic
 * use, but ubiquitous as a content fingerprint and required for
 * compatibility with upstream tooling. Don't use for security.
 */

#ifndef FILE_RAW_HASH_MD5_H
#define FILE_RAW_HASH_MD5_H

#include <stddef.h>
#include <stdint.h>

#define MD5_DIGEST_SIZE 16
#define MD5_BLOCK_SIZE  64

typedef struct {
    uint32_t state[4];          /* A, B, C, D */
    uint64_t bit_count;         /* total bits processed */
    unsigned char buffer[MD5_BLOCK_SIZE];
    size_t buffered;
} md5_ctx_t;

void md5_init  (md5_ctx_t *ctx);
void md5_update(md5_ctx_t *ctx, const void *data, size_t len);
void md5_final (md5_ctx_t *ctx, unsigned char out[MD5_DIGEST_SIZE]);

#endif /* FILE_RAW_HASH_MD5_H */
