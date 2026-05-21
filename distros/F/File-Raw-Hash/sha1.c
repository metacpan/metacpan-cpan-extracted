/*
 * sha1.c - SHA-1 implementation per FIPS 180-4.
 */

#include "sha1.h"
#include <string.h>

#define ROL32(x, n) (((x) << (n)) | ((x) >> (32 - (n))))

static uint32_t
load32_be(const unsigned char *p)
{
    return  ((uint32_t)p[0] << 24)
        | ((uint32_t)p[1] << 16)
        | ((uint32_t)p[2] <<  8)
        |  (uint32_t)p[3];
}

static void
store32_be(unsigned char *p, uint32_t v)
{
    p[0] = (unsigned char)((v >> 24) & 0xFFu);
    p[1] = (unsigned char)((v >> 16) & 0xFFu);
    p[2] = (unsigned char)((v >>  8) & 0xFFu);
    p[3] = (unsigned char)( v        & 0xFFu);
}

static void
sha1_compress(sha1_ctx_t *ctx, const unsigned char *block)
{
    uint32_t W[80];
    uint32_t a = ctx->state[0], b = ctx->state[1], c = ctx->state[2],
             d = ctx->state[3], e = ctx->state[4];
    uint32_t f, k, t;
    int i;

    for (i = 0; i < 16; i++) W[i] = load32_be(block + i * 4);
    for (i = 16; i < 80; i++) {
        W[i] = ROL32(W[i-3] ^ W[i-8] ^ W[i-14] ^ W[i-16], 1);
    }

    for (i = 0; i < 80; i++) {
        if (i < 20) {
            f = (b & c) | (~b & d);
            k = 0x5A827999u;
        } else if (i < 40) {
            f = b ^ c ^ d;
            k = 0x6ED9EBA1u;
        } else if (i < 60) {
            f = (b & c) | (b & d) | (c & d);
            k = 0x8F1BBCDCu;
        } else {
            f = b ^ c ^ d;
            k = 0xCA62C1D6u;
        }
        t = ROL32(a, 5) + f + e + k + W[i];
        e = d;
        d = c;
        c = ROL32(b, 30);
        b = a;
        a = t;
    }

    ctx->state[0] += a;
    ctx->state[1] += b;
    ctx->state[2] += c;
    ctx->state[3] += d;
    ctx->state[4] += e;
}

void
sha1_init(sha1_ctx_t *ctx)
{
    ctx->state[0] = 0x67452301u;
    ctx->state[1] = 0xEFCDAB89u;
    ctx->state[2] = 0x98BADCFEu;
    ctx->state[3] = 0x10325476u;
    ctx->state[4] = 0xC3D2E1F0u;
    ctx->bit_count = 0;
    ctx->buffered = 0;
}

void
sha1_update(sha1_ctx_t *ctx, const void *data, size_t len)
{
    const unsigned char *p = (const unsigned char *)data;
    size_t take;

    ctx->bit_count += (uint64_t)len << 3;

    if (ctx->buffered) {
        take = SHA1_BLOCK_SIZE - ctx->buffered;
        if (take > len) take = len;
        memcpy(ctx->buffer + ctx->buffered, p, take);
        ctx->buffered += take;
        p   += take;
        len -= take;
        if (ctx->buffered == SHA1_BLOCK_SIZE) {
            sha1_compress(ctx, ctx->buffer);
            ctx->buffered = 0;
        }
    }
    while (len >= SHA1_BLOCK_SIZE) {
        sha1_compress(ctx, p);
        p   += SHA1_BLOCK_SIZE;
        len -= SHA1_BLOCK_SIZE;
    }
    if (len) {
        memcpy(ctx->buffer, p, len);
        ctx->buffered = len;
    }
}

void
sha1_final(sha1_ctx_t *ctx, unsigned char out[SHA1_DIGEST_SIZE])
{
    unsigned char pad[SHA1_BLOCK_SIZE];
    unsigned char len_be[8];
    uint64_t bits = ctx->bit_count;
    size_t pad_len;
    int i;

    pad[0] = 0x80;
    for (i = 1; i < SHA1_BLOCK_SIZE; i++) pad[i] = 0;

    if (ctx->buffered < 56)
        pad_len = 56 - ctx->buffered;
    else
        pad_len = (SHA1_BLOCK_SIZE + 56) - ctx->buffered;

    sha1_update(ctx, pad, pad_len);

    for (i = 0; i < 8; i++) {
        len_be[i] = (unsigned char)((bits >> (56 - i * 8)) & 0xFFu);
    }
    sha1_update(ctx, len_be, 8);

    for (i = 0; i < 5; i++) store32_be(out + i * 4, ctx->state[i]);
}
