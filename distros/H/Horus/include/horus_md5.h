#ifndef HORUS_MD5_H
#define HORUS_MD5_H

/*
 * horus_md5.h - Minimal embedded MD5 implementation (RFC 1321)
 *
 * Self-contained, no external dependencies. All functions static
 * to avoid symbol conflicts with system MD5.
 */

#include <string.h>
#include <stdint.h>

typedef struct {
    uint32_t state[4];
    uint64_t count;
    unsigned char buffer[64];
} horus_md5_ctx;

#define HORUS_MD5_F(x, y, z) (((x) & (y)) | ((~(x)) & (z)))
#define HORUS_MD5_G(x, y, z) (((x) & (z)) | ((y) & (~(z))))
#define HORUS_MD5_HH(x, y, z) ((x) ^ (y) ^ (z))
#define HORUS_MD5_I(x, y, z) ((y) ^ ((x) | (~(z))))
#define HORUS_MD5_ROTL(x, n) (((x) << (n)) | ((x) >> (32 - (n))))

#define HORUS_MD5_STEP(f, a, b, c, d, x, t, s) \
    (a) += f((b), (c), (d)) + (x) + (t); \
    (a) = HORUS_MD5_ROTL((a), (s)); \
    (a) += (b)

static inline uint32_t horus_md5_decode32(const unsigned char *p) {
    return (uint32_t)p[0] | ((uint32_t)p[1] << 8)
         | ((uint32_t)p[2] << 16) | ((uint32_t)p[3] << 24);
}

static void horus_md5_transform(uint32_t state[4], const unsigned char block[64]) {
    uint32_t a = state[0], b = state[1], c = state[2], d = state[3];
    uint32_t M[16];
    int i;

    for (i = 0; i < 16; i++)
        M[i] = horus_md5_decode32(block + i * 4);

    /* Round 1 */
    HORUS_MD5_STEP(HORUS_MD5_F, a, b, c, d, M[ 0], 0xd76aa478,  7);
    HORUS_MD5_STEP(HORUS_MD5_F, d, a, b, c, M[ 1], 0xe8c7b756, 12);
    HORUS_MD5_STEP(HORUS_MD5_F, c, d, a, b, M[ 2], 0x242070db, 17);
    HORUS_MD5_STEP(HORUS_MD5_F, b, c, d, a, M[ 3], 0xc1bdceee, 22);
    HORUS_MD5_STEP(HORUS_MD5_F, a, b, c, d, M[ 4], 0xf57c0faf,  7);
    HORUS_MD5_STEP(HORUS_MD5_F, d, a, b, c, M[ 5], 0x4787c62a, 12);
    HORUS_MD5_STEP(HORUS_MD5_F, c, d, a, b, M[ 6], 0xa8304613, 17);
    HORUS_MD5_STEP(HORUS_MD5_F, b, c, d, a, M[ 7], 0xfd469501, 22);
    HORUS_MD5_STEP(HORUS_MD5_F, a, b, c, d, M[ 8], 0x698098d8,  7);
    HORUS_MD5_STEP(HORUS_MD5_F, d, a, b, c, M[ 9], 0x8b44f7af, 12);
    HORUS_MD5_STEP(HORUS_MD5_F, c, d, a, b, M[10], 0xffff5bb1, 17);
    HORUS_MD5_STEP(HORUS_MD5_F, b, c, d, a, M[11], 0x895cd7be, 22);
    HORUS_MD5_STEP(HORUS_MD5_F, a, b, c, d, M[12], 0x6b901122,  7);
    HORUS_MD5_STEP(HORUS_MD5_F, d, a, b, c, M[13], 0xfd987193, 12);
    HORUS_MD5_STEP(HORUS_MD5_F, c, d, a, b, M[14], 0xa679438e, 17);
    HORUS_MD5_STEP(HORUS_MD5_F, b, c, d, a, M[15], 0x49b40821, 22);

    /* Round 2 */
    HORUS_MD5_STEP(HORUS_MD5_G, a, b, c, d, M[ 1], 0xf61e2562,  5);
    HORUS_MD5_STEP(HORUS_MD5_G, d, a, b, c, M[ 6], 0xc040b340,  9);
    HORUS_MD5_STEP(HORUS_MD5_G, c, d, a, b, M[11], 0x265e5a51, 14);
    HORUS_MD5_STEP(HORUS_MD5_G, b, c, d, a, M[ 0], 0xe9b6c7aa, 20);
    HORUS_MD5_STEP(HORUS_MD5_G, a, b, c, d, M[ 5], 0xd62f105d,  5);
    HORUS_MD5_STEP(HORUS_MD5_G, d, a, b, c, M[10], 0x02441453,  9);
    HORUS_MD5_STEP(HORUS_MD5_G, c, d, a, b, M[15], 0xd8a1e681, 14);
    HORUS_MD5_STEP(HORUS_MD5_G, b, c, d, a, M[ 4], 0xe7d3fbc8, 20);
    HORUS_MD5_STEP(HORUS_MD5_G, a, b, c, d, M[ 9], 0x21e1cde6,  5);
    HORUS_MD5_STEP(HORUS_MD5_G, d, a, b, c, M[14], 0xc33707d6,  9);
    HORUS_MD5_STEP(HORUS_MD5_G, c, d, a, b, M[ 3], 0xf4d50d87, 14);
    HORUS_MD5_STEP(HORUS_MD5_G, b, c, d, a, M[ 8], 0x455a14ed, 20);
    HORUS_MD5_STEP(HORUS_MD5_G, a, b, c, d, M[13], 0xa9e3e905,  5);
    HORUS_MD5_STEP(HORUS_MD5_G, d, a, b, c, M[ 2], 0xfcefa3f8,  9);
    HORUS_MD5_STEP(HORUS_MD5_G, c, d, a, b, M[ 7], 0x676f02d9, 14);
    HORUS_MD5_STEP(HORUS_MD5_G, b, c, d, a, M[12], 0x8d2a4c8a, 20);

    /* Round 3 */
    HORUS_MD5_STEP(HORUS_MD5_HH, a, b, c, d, M[ 5], 0xfffa3942,  4);
    HORUS_MD5_STEP(HORUS_MD5_HH, d, a, b, c, M[ 8], 0x8771f681, 11);
    HORUS_MD5_STEP(HORUS_MD5_HH, c, d, a, b, M[11], 0x6d9d6122, 16);
    HORUS_MD5_STEP(HORUS_MD5_HH, b, c, d, a, M[14], 0xfde5380c, 23);
    HORUS_MD5_STEP(HORUS_MD5_HH, a, b, c, d, M[ 1], 0xa4beea44,  4);
    HORUS_MD5_STEP(HORUS_MD5_HH, d, a, b, c, M[ 4], 0x4bdecfa9, 11);
    HORUS_MD5_STEP(HORUS_MD5_HH, c, d, a, b, M[ 7], 0xf6bb4b60, 16);
    HORUS_MD5_STEP(HORUS_MD5_HH, b, c, d, a, M[10], 0xbebfbc70, 23);
    HORUS_MD5_STEP(HORUS_MD5_HH, a, b, c, d, M[13], 0x289b7ec6,  4);
    HORUS_MD5_STEP(HORUS_MD5_HH, d, a, b, c, M[ 0], 0xeaa127fa, 11);
    HORUS_MD5_STEP(HORUS_MD5_HH, c, d, a, b, M[ 3], 0xd4ef3085, 16);
    HORUS_MD5_STEP(HORUS_MD5_HH, b, c, d, a, M[ 6], 0x04881d05, 23);
    HORUS_MD5_STEP(HORUS_MD5_HH, a, b, c, d, M[ 9], 0xd9d4d039,  4);
    HORUS_MD5_STEP(HORUS_MD5_HH, d, a, b, c, M[12], 0xe6db99e5, 11);
    HORUS_MD5_STEP(HORUS_MD5_HH, c, d, a, b, M[15], 0x1fa27cf8, 16);
    HORUS_MD5_STEP(HORUS_MD5_HH, b, c, d, a, M[ 2], 0xc4ac5665, 23);

    /* Round 4 */
    HORUS_MD5_STEP(HORUS_MD5_I, a, b, c, d, M[ 0], 0xf4292244,  6);
    HORUS_MD5_STEP(HORUS_MD5_I, d, a, b, c, M[ 7], 0x432aff97, 10);
    HORUS_MD5_STEP(HORUS_MD5_I, c, d, a, b, M[14], 0xab9423a7, 15);
    HORUS_MD5_STEP(HORUS_MD5_I, b, c, d, a, M[ 5], 0xfc93a039, 21);
    HORUS_MD5_STEP(HORUS_MD5_I, a, b, c, d, M[12], 0x655b59c3,  6);
    HORUS_MD5_STEP(HORUS_MD5_I, d, a, b, c, M[ 3], 0x8f0ccc92, 10);
    HORUS_MD5_STEP(HORUS_MD5_I, c, d, a, b, M[10], 0xffeff47d, 15);
    HORUS_MD5_STEP(HORUS_MD5_I, b, c, d, a, M[ 1], 0x85845dd1, 21);
    HORUS_MD5_STEP(HORUS_MD5_I, a, b, c, d, M[ 8], 0x6fa87e4f,  6);
    HORUS_MD5_STEP(HORUS_MD5_I, d, a, b, c, M[15], 0xfe2ce6e0, 10);
    HORUS_MD5_STEP(HORUS_MD5_I, c, d, a, b, M[ 6], 0xa3014314, 15);
    HORUS_MD5_STEP(HORUS_MD5_I, b, c, d, a, M[13], 0x4e0811a1, 21);
    HORUS_MD5_STEP(HORUS_MD5_I, a, b, c, d, M[ 4], 0xf7537e82,  6);
    HORUS_MD5_STEP(HORUS_MD5_I, d, a, b, c, M[11], 0xbd3af235, 10);
    HORUS_MD5_STEP(HORUS_MD5_I, c, d, a, b, M[ 2], 0x2ad7d2bb, 15);
    HORUS_MD5_STEP(HORUS_MD5_I, b, c, d, a, M[ 9], 0xeb86d391, 21);

    state[0] += a;
    state[1] += b;
    state[2] += c;
    state[3] += d;
}

static inline void horus_md5_init(horus_md5_ctx *ctx) {
    ctx->count = 0;
    ctx->state[0] = 0x67452301;
    ctx->state[1] = 0xefcdab89;
    ctx->state[2] = 0x98badcfe;
    ctx->state[3] = 0x10325476;
}

static inline void horus_md5_update(horus_md5_ctx *ctx,
                                     const unsigned char *data, size_t len) {
    size_t index = (size_t)(ctx->count & 0x3F);
    ctx->count += len;

    if (index) {
        size_t part_len = 64 - index;
        if (len >= part_len) {
            memcpy(ctx->buffer + index, data, part_len);
            horus_md5_transform(ctx->state, ctx->buffer);
            data += part_len;
            len -= part_len;
        } else {
            memcpy(ctx->buffer + index, data, len);
            return;
        }
    }

    while (len >= 64) {
        horus_md5_transform(ctx->state, data);
        data += 64;
        len -= 64;
    }

    if (len)
        memcpy(ctx->buffer, data, len);
}

static inline void horus_md5_final(unsigned char digest[16], horus_md5_ctx *ctx) {
    static const unsigned char padding[64] = { 0x80 };
    unsigned char bits[8];
    uint64_t bit_count = ctx->count << 3;
    size_t index;
    int i;

    /* Encode bit count as little-endian */
    for (i = 0; i < 8; i++)
        bits[i] = (unsigned char)(bit_count >> (i * 8));

    /* Pad to 56 mod 64 */
    index = (size_t)(ctx->count & 0x3F);
    horus_md5_update(ctx, padding, (index < 56) ? (56 - index) : (120 - index));

    /* Append length */
    horus_md5_update(ctx, bits, 8);

    /* Encode state as little-endian */
    for (i = 0; i < 4; i++) {
        digest[i*4 + 0] = (unsigned char)(ctx->state[i]);
        digest[i*4 + 1] = (unsigned char)(ctx->state[i] >> 8);
        digest[i*4 + 2] = (unsigned char)(ctx->state[i] >> 16);
        digest[i*4 + 3] = (unsigned char)(ctx->state[i] >> 24);
    }
}

/* Convenience: hash data in one shot */
static inline void horus_md5(unsigned char digest[16],
                              const unsigned char *data, size_t len) {
    horus_md5_ctx ctx;
    horus_md5_init(&ctx);
    horus_md5_update(&ctx, data, len);
    horus_md5_final(digest, &ctx);
}

#endif /* HORUS_MD5_H */
