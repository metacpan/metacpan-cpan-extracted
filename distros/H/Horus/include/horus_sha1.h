#ifndef HORUS_SHA1_H
#define HORUS_SHA1_H

/*
 * horus_sha1.h - Minimal embedded SHA-1 implementation (RFC 3174)
 *
 * Self-contained, no external dependencies. All functions static
 * to avoid symbol conflicts with system SHA1.
 */

#include <string.h>
#include <stdint.h>

typedef struct {
    uint32_t state[5];
    uint64_t count;
    unsigned char buffer[64];
} horus_sha1_ctx;

#define HORUS_SHA1_ROTL(x, n) (((x) << (n)) | ((x) >> (32 - (n))))

static inline uint32_t horus_sha1_decode32be(const unsigned char *p) {
    return ((uint32_t)p[0] << 24) | ((uint32_t)p[1] << 16)
         | ((uint32_t)p[2] << 8)  | (uint32_t)p[3];
}

static void horus_sha1_transform(uint32_t state[5], const unsigned char block[64]) {
    uint32_t W[80];
    uint32_t a, b, c, d, e;
    int t;

    for (t = 0; t < 16; t++)
        W[t] = horus_sha1_decode32be(block + t * 4);
    for (t = 16; t < 80; t++)
        W[t] = HORUS_SHA1_ROTL(W[t-3] ^ W[t-8] ^ W[t-14] ^ W[t-16], 1);

    a = state[0]; b = state[1]; c = state[2]; d = state[3]; e = state[4];

    for (t = 0; t < 20; t++) {
        uint32_t tmp = HORUS_SHA1_ROTL(a, 5) + ((b & c) | ((~b) & d))
                     + e + W[t] + 0x5A827999;
        e = d; d = c; c = HORUS_SHA1_ROTL(b, 30); b = a; a = tmp;
    }
    for (t = 20; t < 40; t++) {
        uint32_t tmp = HORUS_SHA1_ROTL(a, 5) + (b ^ c ^ d)
                     + e + W[t] + 0x6ED9EBA1;
        e = d; d = c; c = HORUS_SHA1_ROTL(b, 30); b = a; a = tmp;
    }
    for (t = 40; t < 60; t++) {
        uint32_t tmp = HORUS_SHA1_ROTL(a, 5) + ((b & c) | (b & d) | (c & d))
                     + e + W[t] + 0x8F1BBCDC;
        e = d; d = c; c = HORUS_SHA1_ROTL(b, 30); b = a; a = tmp;
    }
    for (t = 60; t < 80; t++) {
        uint32_t tmp = HORUS_SHA1_ROTL(a, 5) + (b ^ c ^ d)
                     + e + W[t] + 0xCA62C1D6;
        e = d; d = c; c = HORUS_SHA1_ROTL(b, 30); b = a; a = tmp;
    }

    state[0] += a;
    state[1] += b;
    state[2] += c;
    state[3] += d;
    state[4] += e;
}

static inline void horus_sha1_init(horus_sha1_ctx *ctx) {
    ctx->count = 0;
    ctx->state[0] = 0x67452301;
    ctx->state[1] = 0xEFCDAB89;
    ctx->state[2] = 0x98BADCFE;
    ctx->state[3] = 0x10325476;
    ctx->state[4] = 0xC3D2E1F0;
}

static inline void horus_sha1_update(horus_sha1_ctx *ctx,
                                      const unsigned char *data, size_t len) {
    size_t index = (size_t)(ctx->count & 0x3F);
    ctx->count += len;

    if (index) {
        size_t part_len = 64 - index;
        if (len >= part_len) {
            memcpy(ctx->buffer + index, data, part_len);
            horus_sha1_transform(ctx->state, ctx->buffer);
            data += part_len;
            len -= part_len;
        } else {
            memcpy(ctx->buffer + index, data, len);
            return;
        }
    }

    while (len >= 64) {
        horus_sha1_transform(ctx->state, data);
        data += 64;
        len -= 64;
    }

    if (len)
        memcpy(ctx->buffer, data, len);
}

static inline void horus_sha1_final(unsigned char digest[20], horus_sha1_ctx *ctx) {
    unsigned char padding[64];
    unsigned char bits[8];
    uint64_t bit_count = ctx->count << 3;
    size_t index;
    int i;

    memset(padding, 0, sizeof(padding));
    padding[0] = 0x80;

    /* Encode bit count as big-endian */
    for (i = 0; i < 8; i++)
        bits[7 - i] = (unsigned char)(bit_count >> (i * 8));

    /* Pad to 56 mod 64 */
    index = (size_t)(ctx->count & 0x3F);
    horus_sha1_update(ctx, padding, (index < 56) ? (56 - index) : (120 - index));

    /* Append length */
    horus_sha1_update(ctx, bits, 8);

    /* Encode state as big-endian */
    for (i = 0; i < 5; i++) {
        digest[i*4 + 0] = (unsigned char)(ctx->state[i] >> 24);
        digest[i*4 + 1] = (unsigned char)(ctx->state[i] >> 16);
        digest[i*4 + 2] = (unsigned char)(ctx->state[i] >> 8);
        digest[i*4 + 3] = (unsigned char)(ctx->state[i]);
    }
}

/* Convenience: hash data in one shot */
static inline void horus_sha1(unsigned char digest[20],
                               const unsigned char *data, size_t len) {
    horus_sha1_ctx ctx;
    horus_sha1_init(&ctx);
    horus_sha1_update(&ctx, data, len);
    horus_sha1_final(digest, &ctx);
}

#endif /* HORUS_SHA1_H */
