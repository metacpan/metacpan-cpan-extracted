/*
 * md5.c - MD5 implementation per RFC 1321.
 *
 * Plain C99, no external deps. The 64 steps are written out with their
 * constants and shifts literal, as in the RFC's reference; blocks load
 * with one copy on little-endian hosts and byte by byte elsewhere.
 */

#include "md5.h"
#include <string.h>

#define ROL32(x, n) (((x) << (n)) | ((x) >> (32 - (n))))

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

/* The four round functions, in the forms that need fewest operations: F and
 * G as selects, H and I as written in RFC 1321. */
#define MD5_F(x, y, z) ((z) ^ ((x) & ((y) ^ (z))))
#define MD5_G(x, y, z) ((y) ^ ((z) & ((x) ^ (y))))
#define MD5_H(x, y, z) ((x) ^ (y) ^ (z))
#define MD5_I(x, y, z) ((y) ^ ((x) | ~(z)))

/* One step: the 64 are written out, so every constant, shift and message
 * index is literal and the four words rotate by name, not by copying. */
#define MD5_STEP(f, a, b, c, d, x, k, s) do {     \
    (a) += (x) + (uint32_t)(k);                    \
    (a) += f((b), (c), (d));                       \
    (a) = ROL32((a), (s)) + (b);                   \
} while (0)

/* G's two halves share no bit, so they are added, not ORed: the CPU can
 * start on (~d & c) before b is known. */
#define MD5_STEP_G(a, b, c, d, x, k, s) do {      \
    (a) += (x) + (uint32_t)(k) + (~(d) & (c));     \
    (a) += (d) & (b);                              \
    (a) = ROL32((a), (s)) + (b);                   \
} while (0)

static void
md5_compress(md5_ctx_t *ctx, const unsigned char *block)
{
    uint32_t M[16];
    uint32_t a = ctx->state[0], b = ctx->state[1],
             c = ctx->state[2], d = ctx->state[3];

#if defined(__BYTE_ORDER__) && defined(__ORDER_LITTLE_ENDIAN__) \
    && __BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__
    memcpy(M, block, sizeof M);
#else
    {
        int i;
        for (i = 0; i < 16; i++) M[i] = load32_le(block + i * 4);
    }
#endif

    MD5_STEP(MD5_F, a, b, c, d, M[ 0], 0xd76aa478,  7);
    MD5_STEP(MD5_F, d, a, b, c, M[ 1], 0xe8c7b756, 12);
    MD5_STEP(MD5_F, c, d, a, b, M[ 2], 0x242070db, 17);
    MD5_STEP(MD5_F, b, c, d, a, M[ 3], 0xc1bdceee, 22);
    MD5_STEP(MD5_F, a, b, c, d, M[ 4], 0xf57c0faf,  7);
    MD5_STEP(MD5_F, d, a, b, c, M[ 5], 0x4787c62a, 12);
    MD5_STEP(MD5_F, c, d, a, b, M[ 6], 0xa8304613, 17);
    MD5_STEP(MD5_F, b, c, d, a, M[ 7], 0xfd469501, 22);
    MD5_STEP(MD5_F, a, b, c, d, M[ 8], 0x698098d8,  7);
    MD5_STEP(MD5_F, d, a, b, c, M[ 9], 0x8b44f7af, 12);
    MD5_STEP(MD5_F, c, d, a, b, M[10], 0xffff5bb1, 17);
    MD5_STEP(MD5_F, b, c, d, a, M[11], 0x895cd7be, 22);
    MD5_STEP(MD5_F, a, b, c, d, M[12], 0x6b901122,  7);
    MD5_STEP(MD5_F, d, a, b, c, M[13], 0xfd987193, 12);
    MD5_STEP(MD5_F, c, d, a, b, M[14], 0xa679438e, 17);
    MD5_STEP(MD5_F, b, c, d, a, M[15], 0x49b40821, 22);

    MD5_STEP_G(a, b, c, d, M[ 1], 0xf61e2562,  5);
    MD5_STEP_G(d, a, b, c, M[ 6], 0xc040b340,  9);
    MD5_STEP_G(c, d, a, b, M[11], 0x265e5a51, 14);
    MD5_STEP_G(b, c, d, a, M[ 0], 0xe9b6c7aa, 20);
    MD5_STEP_G(a, b, c, d, M[ 5], 0xd62f105d,  5);
    MD5_STEP_G(d, a, b, c, M[10], 0x02441453,  9);
    MD5_STEP_G(c, d, a, b, M[15], 0xd8a1e681, 14);
    MD5_STEP_G(b, c, d, a, M[ 4], 0xe7d3fbc8, 20);
    MD5_STEP_G(a, b, c, d, M[ 9], 0x21e1cde6,  5);
    MD5_STEP_G(d, a, b, c, M[14], 0xc33707d6,  9);
    MD5_STEP_G(c, d, a, b, M[ 3], 0xf4d50d87, 14);
    MD5_STEP_G(b, c, d, a, M[ 8], 0x455a14ed, 20);
    MD5_STEP_G(a, b, c, d, M[13], 0xa9e3e905,  5);
    MD5_STEP_G(d, a, b, c, M[ 2], 0xfcefa3f8,  9);
    MD5_STEP_G(c, d, a, b, M[ 7], 0x676f02d9, 14);
    MD5_STEP_G(b, c, d, a, M[12], 0x8d2a4c8a, 20);

    MD5_STEP(MD5_H, a, b, c, d, M[ 5], 0xfffa3942,  4);
    MD5_STEP(MD5_H, d, a, b, c, M[ 8], 0x8771f681, 11);
    MD5_STEP(MD5_H, c, d, a, b, M[11], 0x6d9d6122, 16);
    MD5_STEP(MD5_H, b, c, d, a, M[14], 0xfde5380c, 23);
    MD5_STEP(MD5_H, a, b, c, d, M[ 1], 0xa4beea44,  4);
    MD5_STEP(MD5_H, d, a, b, c, M[ 4], 0x4bdecfa9, 11);
    MD5_STEP(MD5_H, c, d, a, b, M[ 7], 0xf6bb4b60, 16);
    MD5_STEP(MD5_H, b, c, d, a, M[10], 0xbebfbc70, 23);
    MD5_STEP(MD5_H, a, b, c, d, M[13], 0x289b7ec6,  4);
    MD5_STEP(MD5_H, d, a, b, c, M[ 0], 0xeaa127fa, 11);
    MD5_STEP(MD5_H, c, d, a, b, M[ 3], 0xd4ef3085, 16);
    MD5_STEP(MD5_H, b, c, d, a, M[ 6], 0x04881d05, 23);
    MD5_STEP(MD5_H, a, b, c, d, M[ 9], 0xd9d4d039,  4);
    MD5_STEP(MD5_H, d, a, b, c, M[12], 0xe6db99e5, 11);
    MD5_STEP(MD5_H, c, d, a, b, M[15], 0x1fa27cf8, 16);
    MD5_STEP(MD5_H, b, c, d, a, M[ 2], 0xc4ac5665, 23);

    MD5_STEP(MD5_I, a, b, c, d, M[ 0], 0xf4292244,  6);
    MD5_STEP(MD5_I, d, a, b, c, M[ 7], 0x432aff97, 10);
    MD5_STEP(MD5_I, c, d, a, b, M[14], 0xab9423a7, 15);
    MD5_STEP(MD5_I, b, c, d, a, M[ 5], 0xfc93a039, 21);
    MD5_STEP(MD5_I, a, b, c, d, M[12], 0x655b59c3,  6);
    MD5_STEP(MD5_I, d, a, b, c, M[ 3], 0x8f0ccc92, 10);
    MD5_STEP(MD5_I, c, d, a, b, M[10], 0xffeff47d, 15);
    MD5_STEP(MD5_I, b, c, d, a, M[ 1], 0x85845dd1, 21);
    MD5_STEP(MD5_I, a, b, c, d, M[ 8], 0x6fa87e4f,  6);
    MD5_STEP(MD5_I, d, a, b, c, M[15], 0xfe2ce6e0, 10);
    MD5_STEP(MD5_I, c, d, a, b, M[ 6], 0xa3014314, 15);
    MD5_STEP(MD5_I, b, c, d, a, M[13], 0x4e0811a1, 21);
    MD5_STEP(MD5_I, a, b, c, d, M[ 4], 0xf7537e82,  6);
    MD5_STEP(MD5_I, d, a, b, c, M[11], 0xbd3af235, 10);
    MD5_STEP(MD5_I, c, d, a, b, M[ 2], 0x2ad7d2bb, 15);
    MD5_STEP(MD5_I, b, c, d, a, M[ 9], 0xeb86d391, 21);

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
