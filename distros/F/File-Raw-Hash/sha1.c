/*
 * sha1.c - SHA-1 implementation per FIPS 180-4.
 */

#include "sha1.h"
#include "sha_hw.h"
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

/* The four round types. The 80 rounds are written out (generated, then
 * pasted) with the five words renamed from round to round, and the message
 * schedule kept in a sixteen-word window. */
#define SHA1_STEP(f, k, a, b, c, d, e, w) do {        \
    (e) += ROL32((a), 5) + f((b), (c), (d)) + (k) + (w); \
    (b) = ROL32((b), 30);                                \
} while (0)
#define SHA1_F1(b, c, d) ((d) ^ ((b) & ((c) ^ (d))))
#define SHA1_F2(b, c, d) ((b) ^ (c) ^ (d))
#define SHA1_F3(b, c, d) (((b) & (c)) | ((d) & ((b) | (c))))
#define SHA1_R1(a, b, c, d, e, w) SHA1_STEP(SHA1_F1, 0x5A827999u, a, b, c, d, e, w)
#define SHA1_R2(a, b, c, d, e, w) SHA1_STEP(SHA1_F2, 0x6ED9EBA1u, a, b, c, d, e, w)
#define SHA1_R3(a, b, c, d, e, w) SHA1_STEP(SHA1_F3, 0x8F1BBCDCu, a, b, c, d, e, w)
#define SHA1_R4(a, b, c, d, e, w) SHA1_STEP(SHA1_F2, 0xCA62C1D6u, a, b, c, d, e, w)

static void
sha1_compress(uint32_t *state, const unsigned char *block)
{
    uint32_t W[16];
    uint32_t a = state[0], b = state[1], c = state[2],
             d = state[3], e = state[4];

    W[ 0] = load32_be(block +  0);
    SHA1_R1(a, b, c, d, e, W[ 0]);
    W[ 1] = load32_be(block +  4);
    SHA1_R1(e, a, b, c, d, W[ 1]);
    W[ 2] = load32_be(block +  8);
    SHA1_R1(d, e, a, b, c, W[ 2]);
    W[ 3] = load32_be(block + 12);
    SHA1_R1(c, d, e, a, b, W[ 3]);
    W[ 4] = load32_be(block + 16);
    SHA1_R1(b, c, d, e, a, W[ 4]);
    W[ 5] = load32_be(block + 20);
    SHA1_R1(a, b, c, d, e, W[ 5]);
    W[ 6] = load32_be(block + 24);
    SHA1_R1(e, a, b, c, d, W[ 6]);
    W[ 7] = load32_be(block + 28);
    SHA1_R1(d, e, a, b, c, W[ 7]);
    W[ 8] = load32_be(block + 32);
    SHA1_R1(c, d, e, a, b, W[ 8]);
    W[ 9] = load32_be(block + 36);
    SHA1_R1(b, c, d, e, a, W[ 9]);
    W[10] = load32_be(block + 40);
    SHA1_R1(a, b, c, d, e, W[10]);
    W[11] = load32_be(block + 44);
    SHA1_R1(e, a, b, c, d, W[11]);
    W[12] = load32_be(block + 48);
    SHA1_R1(d, e, a, b, c, W[12]);
    W[13] = load32_be(block + 52);
    SHA1_R1(c, d, e, a, b, W[13]);
    W[14] = load32_be(block + 56);
    SHA1_R1(b, c, d, e, a, W[14]);
    W[15] = load32_be(block + 60);
    SHA1_R1(a, b, c, d, e, W[15]);
    W[ 0] = ROL32(W[13] ^ W[ 8] ^ W[ 2] ^ W[ 0], 1);
    SHA1_R1(e, a, b, c, d, W[ 0]);
    W[ 1] = ROL32(W[14] ^ W[ 9] ^ W[ 3] ^ W[ 1], 1);
    SHA1_R1(d, e, a, b, c, W[ 1]);
    W[ 2] = ROL32(W[15] ^ W[10] ^ W[ 4] ^ W[ 2], 1);
    SHA1_R1(c, d, e, a, b, W[ 2]);
    W[ 3] = ROL32(W[ 0] ^ W[11] ^ W[ 5] ^ W[ 3], 1);
    SHA1_R1(b, c, d, e, a, W[ 3]);
    W[ 4] = ROL32(W[ 1] ^ W[12] ^ W[ 6] ^ W[ 4], 1);
    SHA1_R2(a, b, c, d, e, W[ 4]);
    W[ 5] = ROL32(W[ 2] ^ W[13] ^ W[ 7] ^ W[ 5], 1);
    SHA1_R2(e, a, b, c, d, W[ 5]);
    W[ 6] = ROL32(W[ 3] ^ W[14] ^ W[ 8] ^ W[ 6], 1);
    SHA1_R2(d, e, a, b, c, W[ 6]);
    W[ 7] = ROL32(W[ 4] ^ W[15] ^ W[ 9] ^ W[ 7], 1);
    SHA1_R2(c, d, e, a, b, W[ 7]);
    W[ 8] = ROL32(W[ 5] ^ W[ 0] ^ W[10] ^ W[ 8], 1);
    SHA1_R2(b, c, d, e, a, W[ 8]);
    W[ 9] = ROL32(W[ 6] ^ W[ 1] ^ W[11] ^ W[ 9], 1);
    SHA1_R2(a, b, c, d, e, W[ 9]);
    W[10] = ROL32(W[ 7] ^ W[ 2] ^ W[12] ^ W[10], 1);
    SHA1_R2(e, a, b, c, d, W[10]);
    W[11] = ROL32(W[ 8] ^ W[ 3] ^ W[13] ^ W[11], 1);
    SHA1_R2(d, e, a, b, c, W[11]);
    W[12] = ROL32(W[ 9] ^ W[ 4] ^ W[14] ^ W[12], 1);
    SHA1_R2(c, d, e, a, b, W[12]);
    W[13] = ROL32(W[10] ^ W[ 5] ^ W[15] ^ W[13], 1);
    SHA1_R2(b, c, d, e, a, W[13]);
    W[14] = ROL32(W[11] ^ W[ 6] ^ W[ 0] ^ W[14], 1);
    SHA1_R2(a, b, c, d, e, W[14]);
    W[15] = ROL32(W[12] ^ W[ 7] ^ W[ 1] ^ W[15], 1);
    SHA1_R2(e, a, b, c, d, W[15]);
    W[ 0] = ROL32(W[13] ^ W[ 8] ^ W[ 2] ^ W[ 0], 1);
    SHA1_R2(d, e, a, b, c, W[ 0]);
    W[ 1] = ROL32(W[14] ^ W[ 9] ^ W[ 3] ^ W[ 1], 1);
    SHA1_R2(c, d, e, a, b, W[ 1]);
    W[ 2] = ROL32(W[15] ^ W[10] ^ W[ 4] ^ W[ 2], 1);
    SHA1_R2(b, c, d, e, a, W[ 2]);
    W[ 3] = ROL32(W[ 0] ^ W[11] ^ W[ 5] ^ W[ 3], 1);
    SHA1_R2(a, b, c, d, e, W[ 3]);
    W[ 4] = ROL32(W[ 1] ^ W[12] ^ W[ 6] ^ W[ 4], 1);
    SHA1_R2(e, a, b, c, d, W[ 4]);
    W[ 5] = ROL32(W[ 2] ^ W[13] ^ W[ 7] ^ W[ 5], 1);
    SHA1_R2(d, e, a, b, c, W[ 5]);
    W[ 6] = ROL32(W[ 3] ^ W[14] ^ W[ 8] ^ W[ 6], 1);
    SHA1_R2(c, d, e, a, b, W[ 6]);
    W[ 7] = ROL32(W[ 4] ^ W[15] ^ W[ 9] ^ W[ 7], 1);
    SHA1_R2(b, c, d, e, a, W[ 7]);
    W[ 8] = ROL32(W[ 5] ^ W[ 0] ^ W[10] ^ W[ 8], 1);
    SHA1_R3(a, b, c, d, e, W[ 8]);
    W[ 9] = ROL32(W[ 6] ^ W[ 1] ^ W[11] ^ W[ 9], 1);
    SHA1_R3(e, a, b, c, d, W[ 9]);
    W[10] = ROL32(W[ 7] ^ W[ 2] ^ W[12] ^ W[10], 1);
    SHA1_R3(d, e, a, b, c, W[10]);
    W[11] = ROL32(W[ 8] ^ W[ 3] ^ W[13] ^ W[11], 1);
    SHA1_R3(c, d, e, a, b, W[11]);
    W[12] = ROL32(W[ 9] ^ W[ 4] ^ W[14] ^ W[12], 1);
    SHA1_R3(b, c, d, e, a, W[12]);
    W[13] = ROL32(W[10] ^ W[ 5] ^ W[15] ^ W[13], 1);
    SHA1_R3(a, b, c, d, e, W[13]);
    W[14] = ROL32(W[11] ^ W[ 6] ^ W[ 0] ^ W[14], 1);
    SHA1_R3(e, a, b, c, d, W[14]);
    W[15] = ROL32(W[12] ^ W[ 7] ^ W[ 1] ^ W[15], 1);
    SHA1_R3(d, e, a, b, c, W[15]);
    W[ 0] = ROL32(W[13] ^ W[ 8] ^ W[ 2] ^ W[ 0], 1);
    SHA1_R3(c, d, e, a, b, W[ 0]);
    W[ 1] = ROL32(W[14] ^ W[ 9] ^ W[ 3] ^ W[ 1], 1);
    SHA1_R3(b, c, d, e, a, W[ 1]);
    W[ 2] = ROL32(W[15] ^ W[10] ^ W[ 4] ^ W[ 2], 1);
    SHA1_R3(a, b, c, d, e, W[ 2]);
    W[ 3] = ROL32(W[ 0] ^ W[11] ^ W[ 5] ^ W[ 3], 1);
    SHA1_R3(e, a, b, c, d, W[ 3]);
    W[ 4] = ROL32(W[ 1] ^ W[12] ^ W[ 6] ^ W[ 4], 1);
    SHA1_R3(d, e, a, b, c, W[ 4]);
    W[ 5] = ROL32(W[ 2] ^ W[13] ^ W[ 7] ^ W[ 5], 1);
    SHA1_R3(c, d, e, a, b, W[ 5]);
    W[ 6] = ROL32(W[ 3] ^ W[14] ^ W[ 8] ^ W[ 6], 1);
    SHA1_R3(b, c, d, e, a, W[ 6]);
    W[ 7] = ROL32(W[ 4] ^ W[15] ^ W[ 9] ^ W[ 7], 1);
    SHA1_R3(a, b, c, d, e, W[ 7]);
    W[ 8] = ROL32(W[ 5] ^ W[ 0] ^ W[10] ^ W[ 8], 1);
    SHA1_R3(e, a, b, c, d, W[ 8]);
    W[ 9] = ROL32(W[ 6] ^ W[ 1] ^ W[11] ^ W[ 9], 1);
    SHA1_R3(d, e, a, b, c, W[ 9]);
    W[10] = ROL32(W[ 7] ^ W[ 2] ^ W[12] ^ W[10], 1);
    SHA1_R3(c, d, e, a, b, W[10]);
    W[11] = ROL32(W[ 8] ^ W[ 3] ^ W[13] ^ W[11], 1);
    SHA1_R3(b, c, d, e, a, W[11]);
    W[12] = ROL32(W[ 9] ^ W[ 4] ^ W[14] ^ W[12], 1);
    SHA1_R4(a, b, c, d, e, W[12]);
    W[13] = ROL32(W[10] ^ W[ 5] ^ W[15] ^ W[13], 1);
    SHA1_R4(e, a, b, c, d, W[13]);
    W[14] = ROL32(W[11] ^ W[ 6] ^ W[ 0] ^ W[14], 1);
    SHA1_R4(d, e, a, b, c, W[14]);
    W[15] = ROL32(W[12] ^ W[ 7] ^ W[ 1] ^ W[15], 1);
    SHA1_R4(c, d, e, a, b, W[15]);
    W[ 0] = ROL32(W[13] ^ W[ 8] ^ W[ 2] ^ W[ 0], 1);
    SHA1_R4(b, c, d, e, a, W[ 0]);
    W[ 1] = ROL32(W[14] ^ W[ 9] ^ W[ 3] ^ W[ 1], 1);
    SHA1_R4(a, b, c, d, e, W[ 1]);
    W[ 2] = ROL32(W[15] ^ W[10] ^ W[ 4] ^ W[ 2], 1);
    SHA1_R4(e, a, b, c, d, W[ 2]);
    W[ 3] = ROL32(W[ 0] ^ W[11] ^ W[ 5] ^ W[ 3], 1);
    SHA1_R4(d, e, a, b, c, W[ 3]);
    W[ 4] = ROL32(W[ 1] ^ W[12] ^ W[ 6] ^ W[ 4], 1);
    SHA1_R4(c, d, e, a, b, W[ 4]);
    W[ 5] = ROL32(W[ 2] ^ W[13] ^ W[ 7] ^ W[ 5], 1);
    SHA1_R4(b, c, d, e, a, W[ 5]);
    W[ 6] = ROL32(W[ 3] ^ W[14] ^ W[ 8] ^ W[ 6], 1);
    SHA1_R4(a, b, c, d, e, W[ 6]);
    W[ 7] = ROL32(W[ 4] ^ W[15] ^ W[ 9] ^ W[ 7], 1);
    SHA1_R4(e, a, b, c, d, W[ 7]);
    W[ 8] = ROL32(W[ 5] ^ W[ 0] ^ W[10] ^ W[ 8], 1);
    SHA1_R4(d, e, a, b, c, W[ 8]);
    W[ 9] = ROL32(W[ 6] ^ W[ 1] ^ W[11] ^ W[ 9], 1);
    SHA1_R4(c, d, e, a, b, W[ 9]);
    W[10] = ROL32(W[ 7] ^ W[ 2] ^ W[12] ^ W[10], 1);
    SHA1_R4(b, c, d, e, a, W[10]);
    W[11] = ROL32(W[ 8] ^ W[ 3] ^ W[13] ^ W[11], 1);
    SHA1_R4(a, b, c, d, e, W[11]);
    W[12] = ROL32(W[ 9] ^ W[ 4] ^ W[14] ^ W[12], 1);
    SHA1_R4(e, a, b, c, d, W[12]);
    W[13] = ROL32(W[10] ^ W[ 5] ^ W[15] ^ W[13], 1);
    SHA1_R4(d, e, a, b, c, W[13]);
    W[14] = ROL32(W[11] ^ W[ 6] ^ W[ 0] ^ W[14], 1);
    SHA1_R4(c, d, e, a, b, W[14]);
    W[15] = ROL32(W[12] ^ W[ 7] ^ W[ 1] ^ W[15], 1);
    SHA1_R4(b, c, d, e, a, W[15]);

    state[0] += a;
    state[1] += b;
    state[2] += c;
    state[3] += d;
    state[4] += e;
}

/* Whole blocks, one at a time, through the C above. */
static void
sha1_blocks_portable(uint32_t *state, const unsigned char *p, size_t n)
{
    while (n--) {
        sha1_compress(state, p);
        p += SHA1_BLOCK_SIZE;
    }
}

/* The path in use: the C above until sha1_select() finds the CPU's SHA
 * instructions (File::Raw::Hash's BOOT calls it once). */
static frh_blocks32_fn sha1_blocks = sha1_blocks_portable;
static const char *sha1_impl = "portable";

void
sha1_select(int portable)
{
    frh_blocks32_fn f = portable ? NULL : frh_hw_sha1_blocks();
    sha1_blocks = f ? f : sha1_blocks_portable;
    sha1_impl   = f ? frh_hw_name() : "portable";
}

const char *
sha1_implementation(void)
{
    return sha1_impl;
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
            sha1_blocks(ctx->state, ctx->buffer, 1);
            ctx->buffered = 0;
        }
    }
    if (len >= SHA1_BLOCK_SIZE) {
        size_t n = len / SHA1_BLOCK_SIZE;
        sha1_blocks(ctx->state, p, n);
        p   += n * SHA1_BLOCK_SIZE;
        len -= n * SHA1_BLOCK_SIZE;
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
