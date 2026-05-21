/*
 * crc32.h - IEEE 802.3 (reflected) CRC-32 for File::Raw::Hash.
 *
 * Polynomial 0xEDB88320 (reflected form of 0x04C11DB7). Same CRC used
 * by zlib, gzip, PNG, Ethernet. Self-contained, table-driven, plain C99.
 */

#ifndef FILE_RAW_HASH_CRC32_H
#define FILE_RAW_HASH_CRC32_H

#include <stddef.h>
#include <stdint.h>

#define CRC32_DIGEST_SIZE 4

typedef struct {
    uint32_t state;
} crc32_ctx_t;

void crc32_init  (crc32_ctx_t *ctx);
void crc32_update(crc32_ctx_t *ctx, const void *data, size_t len);
void crc32_final (crc32_ctx_t *ctx, unsigned char out[CRC32_DIGEST_SIZE]);

#endif /* FILE_RAW_HASH_CRC32_H */
