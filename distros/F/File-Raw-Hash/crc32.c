/*
 * crc32.c - IEEE 802.3 reflected CRC-32 implementation.
 *
 * Table-driven, computed lazily on first use. Table holds 256 entries
 * = 1 KiB of static data. Polynomial 0xEDB88320.
 */

#include "crc32.h"

static uint32_t crc32_table[256];
static int      crc32_table_built = 0;

static void
crc32_build_table(void)
{
    uint32_t c;
    int i, j;
    for (i = 0; i < 256; i++) {
        c = (uint32_t)i;
        for (j = 0; j < 8; j++) {
            c = (c & 1u) ? (0xEDB88320u ^ (c >> 1)) : (c >> 1);
        }
        crc32_table[i] = c;
    }
    crc32_table_built = 1;
}

void
crc32_init(crc32_ctx_t *ctx)
{
    if (!crc32_table_built) crc32_build_table();
    ctx->state = 0xFFFFFFFFu;
}

void
crc32_update(crc32_ctx_t *ctx, const void *data, size_t len)
{
    const unsigned char *p = (const unsigned char *)data;
    uint32_t c = ctx->state;
    size_t i;
    for (i = 0; i < len; i++) {
        c = crc32_table[(c ^ p[i]) & 0xFFu] ^ (c >> 8);
    }
    ctx->state = c;
}

void
crc32_final(crc32_ctx_t *ctx, unsigned char out[CRC32_DIGEST_SIZE])
{
    uint32_t c = ctx->state ^ 0xFFFFFFFFu;
    /* Big-endian output: matches the conventional "0xCBF43926" reading
     * for the "123456789" test vector. */
    out[0] = (unsigned char)((c >> 24) & 0xFFu);
    out[1] = (unsigned char)((c >> 16) & 0xFFu);
    out[2] = (unsigned char)((c >>  8) & 0xFFu);
    out[3] = (unsigned char)( c        & 0xFFu);
}
