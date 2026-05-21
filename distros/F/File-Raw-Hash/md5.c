/*
 * md5.c - MD5 implementation per RFC 1321.
 *
 * Plain C99, no external deps. Endian-agnostic (reads/writes go through
 * byte-by-byte loaders/storers). Round constants and shift amounts come
 * directly from the spec.
 */

#include "md5.h"
#include <string.h>

#define ROL32(x, n) (((x) << (n)) | ((x) >> (32 - (n))))

static const uint32_t MD5_K[64] = {
    0xd76aa478u, 0xe8c7b756u, 0x242070dbu, 0xc1bdceeeu,
    0xf57c0fafu, 0x4787c62au, 0xa8304613u, 0xfd469501u,
    0x698098d8u, 0x8b44f7afu, 0xffff5bb1u, 0x895cd7beu,
    0x6b901122u, 0xfd987193u, 0xa679438eu, 0x49b40821u,
    0xf61e2562u, 0xc040b340u, 0x265e5a51u, 0xe9b6c7aau,
    0xd62f105du, 0x02441453u, 0xd8a1e681u, 0xe7d3fbc8u,
    0x21e1cde6u, 0xc33707d6u, 0xf4d50d87u, 0x455a14edu,
    0xa9e3e905u, 0xfcefa3f8u, 0x676f02d9u, 0x8d2a4c8au,
    0xfffa3942u, 0x8771f681u, 0x6d9d6122u, 0xfde5380cu,
    0xa4beea44u, 0x4bdecfa9u, 0xf6bb4b60u, 0xbebfbc70u,
    0x289b7ec6u, 0xeaa127fau, 0xd4ef3085u, 0x04881d05u,
    0xd9d4d039u, 0xe6db99e5u, 0x1fa27cf8u, 0xc4ac5665u,
    0xf4292244u, 0x432aff97u, 0xab9423a7u, 0xfc93a039u,
    0x655b59c3u, 0x8f0ccc92u, 0xffeff47du, 0x85845dd1u,
    0x6fa87e4fu, 0xfe2ce6e0u, 0xa3014314u, 0x4e0811a1u,
    0xf7537e82u, 0xbd3af235u, 0x2ad7d2bbu, 0xeb86d391u
};

static const unsigned MD5_S[64] = {
    7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22,
    5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20,
    4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23,
    6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21
};

static uint32_t
load32_le(const unsigned char *p)
{
    return  (uint32_t)p[0]
        | ((uint32_t)p[1] <<  8)
        | ((uint32_t)p[2] << 16)
        | ((uint32_t)p[3] << 24);
}

static void
store32_le(unsigned char *p, uint32_t v)
{
    p[0] = (unsigned char)( v        & 0xFFu);
    p[1] = (unsigned char)((v >>  8) & 0xFFu);
    p[2] = (unsigned char)((v >> 16) & 0xFFu);
    p[3] = (unsigned char)((v >> 24) & 0xFFu);
}

static void
md5_compress(md5_ctx_t *ctx, const unsigned char *block)
{
    uint32_t M[16];
    uint32_t a = ctx->state[0], b = ctx->state[1],
             c = ctx->state[2], d = ctx->state[3];
    uint32_t f, g, t;
    int i;

    for (i = 0; i < 16; i++) M[i] = load32_le(block + i * 4);

    for (i = 0; i < 64; i++) {
        if (i < 16) {
            f = (b & c) | (~b & d);
            g = (uint32_t)i;
        } else if (i < 32) {
            f = (d & b) | (~d & c);
            g = (uint32_t)(5 * i + 1) & 15u;
        } else if (i < 48) {
            f = b ^ c ^ d;
            g = (uint32_t)(3 * i + 5) & 15u;
        } else {
            f = c ^ (b | ~d);
            g = (uint32_t)(7 * i) & 15u;
        }
        t = d;
        d = c;
        c = b;
        b = b + ROL32(a + f + MD5_K[i] + M[g], MD5_S[i]);
        a = t;
    }

    ctx->state[0] += a;
    ctx->state[1] += b;
    ctx->state[2] += c;
    ctx->state[3] += d;
}

void
md5_init(md5_ctx_t *ctx)
{
    ctx->state[0] = 0x67452301u;
    ctx->state[1] = 0xefcdab89u;
    ctx->state[2] = 0x98badcfeu;
    ctx->state[3] = 0x10325476u;
    ctx->bit_count = 0;
    ctx->buffered = 0;
}

void
md5_update(md5_ctx_t *ctx, const void *data, size_t len)
{
    const unsigned char *p = (const unsigned char *)data;
    size_t take;

    ctx->bit_count += (uint64_t)len << 3;

    if (ctx->buffered) {
        take = MD5_BLOCK_SIZE - ctx->buffered;
        if (take > len) take = len;
        memcpy(ctx->buffer + ctx->buffered, p, take);
        ctx->buffered += take;
        p   += take;
        len -= take;
        if (ctx->buffered == MD5_BLOCK_SIZE) {
            md5_compress(ctx, ctx->buffer);
            ctx->buffered = 0;
        }
    }
    while (len >= MD5_BLOCK_SIZE) {
        md5_compress(ctx, p);
        p   += MD5_BLOCK_SIZE;
        len -= MD5_BLOCK_SIZE;
    }
    if (len) {
        memcpy(ctx->buffer, p, len);
        ctx->buffered = len;
    }
}

void
md5_final(md5_ctx_t *ctx, unsigned char out[MD5_DIGEST_SIZE])
{
    /* Pad: append 0x80, zeros, then 64-bit little-endian length. */
    unsigned char pad[MD5_BLOCK_SIZE];
    unsigned char len_le[8];
    uint64_t bits = ctx->bit_count;
    size_t pad_len;
    int i;

    pad[0] = 0x80;
    for (i = 1; i < MD5_BLOCK_SIZE; i++) pad[i] = 0;

    /* Need to land at offset 56 mod 64 after writing pad. */
    if (ctx->buffered < 56)
        pad_len = 56 - ctx->buffered;
    else
        pad_len = (MD5_BLOCK_SIZE + 56) - ctx->buffered;

    md5_update(ctx, pad, pad_len);

    for (i = 0; i < 8; i++) {
        len_le[i] = (unsigned char)((bits >> (i * 8)) & 0xFFu);
    }
    md5_update(ctx, len_le, 8);

    /* bit_count was bumped twice by the padding update — that's fine,
     * it's only consumed once during the very pad we just wrote. */
    for (i = 0; i < 4; i++) store32_le(out + i * 4, ctx->state[i]);
}
