/*
 * sha2.c - SHA-256 and SHA-512 implementations per FIPS 180-4.
 */

#include "sha2.h"
#include <string.h>

/* ---------------- shared loaders / storers ---------------- */

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

static uint64_t
load64_be(const unsigned char *p)
{
    return  ((uint64_t)p[0] << 56)
        | ((uint64_t)p[1] << 48)
        | ((uint64_t)p[2] << 40)
        | ((uint64_t)p[3] << 32)
        | ((uint64_t)p[4] << 24)
        | ((uint64_t)p[5] << 16)
        | ((uint64_t)p[6] <<  8)
        |  (uint64_t)p[7];
}

static void
store64_be(unsigned char *p, uint64_t v)
{
    p[0] = (unsigned char)((v >> 56) & 0xFFu);
    p[1] = (unsigned char)((v >> 48) & 0xFFu);
    p[2] = (unsigned char)((v >> 40) & 0xFFu);
    p[3] = (unsigned char)((v >> 32) & 0xFFu);
    p[4] = (unsigned char)((v >> 24) & 0xFFu);
    p[5] = (unsigned char)((v >> 16) & 0xFFu);
    p[6] = (unsigned char)((v >>  8) & 0xFFu);
    p[7] = (unsigned char)( v        & 0xFFu);
}

/* ============================================================
 * SHA-256
 * ============================================================ */

#define ROR32(x, n) (((x) >> (n)) | ((x) << (32 - (n))))

#define CH32(x,y,z)  (((x) & (y)) ^ (~(x) & (z)))
#define MAJ32(x,y,z) (((x) & (y)) ^ ((x) & (z)) ^ ((y) & (z)))
#define BSIG0_32(x)  (ROR32(x, 2)  ^ ROR32(x,13) ^ ROR32(x,22))
#define BSIG1_32(x)  (ROR32(x, 6)  ^ ROR32(x,11) ^ ROR32(x,25))
#define SSIG0_32(x)  (ROR32(x, 7)  ^ ROR32(x,18) ^ ((x) >>  3))
#define SSIG1_32(x)  (ROR32(x,17)  ^ ROR32(x,19) ^ ((x) >> 10))

static const uint32_t SHA256_K[64] = {
    0x428a2f98u, 0x71374491u, 0xb5c0fbcfu, 0xe9b5dba5u,
    0x3956c25bu, 0x59f111f1u, 0x923f82a4u, 0xab1c5ed5u,
    0xd807aa98u, 0x12835b01u, 0x243185beu, 0x550c7dc3u,
    0x72be5d74u, 0x80deb1feu, 0x9bdc06a7u, 0xc19bf174u,
    0xe49b69c1u, 0xefbe4786u, 0x0fc19dc6u, 0x240ca1ccu,
    0x2de92c6fu, 0x4a7484aau, 0x5cb0a9dcu, 0x76f988dau,
    0x983e5152u, 0xa831c66du, 0xb00327c8u, 0xbf597fc7u,
    0xc6e00bf3u, 0xd5a79147u, 0x06ca6351u, 0x14292967u,
    0x27b70a85u, 0x2e1b2138u, 0x4d2c6dfcu, 0x53380d13u,
    0x650a7354u, 0x766a0abbu, 0x81c2c92eu, 0x92722c85u,
    0xa2bfe8a1u, 0xa81a664bu, 0xc24b8b70u, 0xc76c51a3u,
    0xd192e819u, 0xd6990624u, 0xf40e3585u, 0x106aa070u,
    0x19a4c116u, 0x1e376c08u, 0x2748774cu, 0x34b0bcb5u,
    0x391c0cb3u, 0x4ed8aa4au, 0x5b9cca4fu, 0x682e6ff3u,
    0x748f82eeu, 0x78a5636fu, 0x84c87814u, 0x8cc70208u,
    0x90befffau, 0xa4506cebu, 0xbef9a3f7u, 0xc67178f2u
};

static void
sha256_compress(sha256_ctx_t *ctx, const unsigned char *block)
{
    uint32_t W[64];
    uint32_t a = ctx->state[0], b = ctx->state[1], c = ctx->state[2],
             d = ctx->state[3], e = ctx->state[4], f = ctx->state[5],
             g = ctx->state[6], h = ctx->state[7];
    uint32_t T1, T2;
    int i;

    for (i = 0; i < 16; i++) W[i] = load32_be(block + i * 4);
    for (i = 16; i < 64; i++) {
        W[i] = SSIG1_32(W[i-2]) + W[i-7] + SSIG0_32(W[i-15]) + W[i-16];
    }

    for (i = 0; i < 64; i++) {
        T1 = h + BSIG1_32(e) + CH32(e, f, g) + SHA256_K[i] + W[i];
        T2 = BSIG0_32(a) + MAJ32(a, b, c);
        h = g;
        g = f;
        f = e;
        e = d + T1;
        d = c;
        c = b;
        b = a;
        a = T1 + T2;
    }

    ctx->state[0] += a;
    ctx->state[1] += b;
    ctx->state[2] += c;
    ctx->state[3] += d;
    ctx->state[4] += e;
    ctx->state[5] += f;
    ctx->state[6] += g;
    ctx->state[7] += h;
}

void
sha256_init(sha256_ctx_t *ctx)
{
    ctx->state[0] = 0x6a09e667u;
    ctx->state[1] = 0xbb67ae85u;
    ctx->state[2] = 0x3c6ef372u;
    ctx->state[3] = 0xa54ff53au;
    ctx->state[4] = 0x510e527fu;
    ctx->state[5] = 0x9b05688cu;
    ctx->state[6] = 0x1f83d9abu;
    ctx->state[7] = 0x5be0cd19u;
    ctx->bit_count = 0;
    ctx->buffered = 0;
}

void
sha256_update(sha256_ctx_t *ctx, const void *data, size_t len)
{
    const unsigned char *p = (const unsigned char *)data;
    size_t take;

    ctx->bit_count += (uint64_t)len << 3;

    if (ctx->buffered) {
        take = SHA256_BLOCK_SIZE - ctx->buffered;
        if (take > len) take = len;
        memcpy(ctx->buffer + ctx->buffered, p, take);
        ctx->buffered += take;
        p   += take;
        len -= take;
        if (ctx->buffered == SHA256_BLOCK_SIZE) {
            sha256_compress(ctx, ctx->buffer);
            ctx->buffered = 0;
        }
    }
    while (len >= SHA256_BLOCK_SIZE) {
        sha256_compress(ctx, p);
        p   += SHA256_BLOCK_SIZE;
        len -= SHA256_BLOCK_SIZE;
    }
    if (len) {
        memcpy(ctx->buffer, p, len);
        ctx->buffered = len;
    }
}

void
sha256_final(sha256_ctx_t *ctx, unsigned char out[SHA256_DIGEST_SIZE])
{
    unsigned char pad[SHA256_BLOCK_SIZE];
    unsigned char len_be[8];
    uint64_t bits = ctx->bit_count;
    size_t pad_len;
    int i;

    pad[0] = 0x80;
    for (i = 1; i < SHA256_BLOCK_SIZE; i++) pad[i] = 0;

    if (ctx->buffered < 56)
        pad_len = 56 - ctx->buffered;
    else
        pad_len = (SHA256_BLOCK_SIZE + 56) - ctx->buffered;

    sha256_update(ctx, pad, pad_len);

    for (i = 0; i < 8; i++) {
        len_be[i] = (unsigned char)((bits >> (56 - i * 8)) & 0xFFu);
    }
    sha256_update(ctx, len_be, 8);

    for (i = 0; i < 8; i++) store32_be(out + i * 4, ctx->state[i]);
}

/* ============================================================
 * SHA-512
 * ============================================================ */

#define ROR64(x, n) (((x) >> (n)) | ((x) << (64 - (n))))

#define CH64(x,y,z)  (((x) & (y)) ^ (~(x) & (z)))
#define MAJ64(x,y,z) (((x) & (y)) ^ ((x) & (z)) ^ ((y) & (z)))
#define BSIG0_64(x)  (ROR64(x,28) ^ ROR64(x,34) ^ ROR64(x,39))
#define BSIG1_64(x)  (ROR64(x,14) ^ ROR64(x,18) ^ ROR64(x,41))
#define SSIG0_64(x)  (ROR64(x, 1) ^ ROR64(x, 8) ^ ((x) >> 7))
#define SSIG1_64(x)  (ROR64(x,19) ^ ROR64(x,61) ^ ((x) >> 6))

static const uint64_t SHA512_K[80] = {
    0x428a2f98d728ae22ull, 0x7137449123ef65cdull,
    0xb5c0fbcfec4d3b2full, 0xe9b5dba58189dbbcull,
    0x3956c25bf348b538ull, 0x59f111f1b605d019ull,
    0x923f82a4af194f9bull, 0xab1c5ed5da6d8118ull,
    0xd807aa98a3030242ull, 0x12835b0145706fbeull,
    0x243185be4ee4b28cull, 0x550c7dc3d5ffb4e2ull,
    0x72be5d74f27b896full, 0x80deb1fe3b1696b1ull,
    0x9bdc06a725c71235ull, 0xc19bf174cf692694ull,
    0xe49b69c19ef14ad2ull, 0xefbe4786384f25e3ull,
    0x0fc19dc68b8cd5b5ull, 0x240ca1cc77ac9c65ull,
    0x2de92c6f592b0275ull, 0x4a7484aa6ea6e483ull,
    0x5cb0a9dcbd41fbd4ull, 0x76f988da831153b5ull,
    0x983e5152ee66dfabull, 0xa831c66d2db43210ull,
    0xb00327c898fb213full, 0xbf597fc7beef0ee4ull,
    0xc6e00bf33da88fc2ull, 0xd5a79147930aa725ull,
    0x06ca6351e003826full, 0x142929670a0e6e70ull,
    0x27b70a8546d22ffcull, 0x2e1b21385c26c926ull,
    0x4d2c6dfc5ac42aedull, 0x53380d139d95b3dfull,
    0x650a73548baf63deull, 0x766a0abb3c77b2a8ull,
    0x81c2c92e47edaee6ull, 0x92722c851482353bull,
    0xa2bfe8a14cf10364ull, 0xa81a664bbc423001ull,
    0xc24b8b70d0f89791ull, 0xc76c51a30654be30ull,
    0xd192e819d6ef5218ull, 0xd69906245565a910ull,
    0xf40e35855771202aull, 0x106aa07032bbd1b8ull,
    0x19a4c116b8d2d0c8ull, 0x1e376c085141ab53ull,
    0x2748774cdf8eeb99ull, 0x34b0bcb5e19b48a8ull,
    0x391c0cb3c5c95a63ull, 0x4ed8aa4ae3418acbull,
    0x5b9cca4f7763e373ull, 0x682e6ff3d6b2b8a3ull,
    0x748f82ee5defb2fcull, 0x78a5636f43172f60ull,
    0x84c87814a1f0ab72ull, 0x8cc702081a6439ecull,
    0x90befffa23631e28ull, 0xa4506cebde82bde9ull,
    0xbef9a3f7b2c67915ull, 0xc67178f2e372532bull,
    0xca273eceea26619cull, 0xd186b8c721c0c207ull,
    0xeada7dd6cde0eb1eull, 0xf57d4f7fee6ed178ull,
    0x06f067aa72176fbaull, 0x0a637dc5a2c898a6ull,
    0x113f9804bef90daeull, 0x1b710b35131c471bull,
    0x28db77f523047d84ull, 0x32caab7b40c72493ull,
    0x3c9ebe0a15c9bebcull, 0x431d67c49c100d4cull,
    0x4cc5d4becb3e42b6ull, 0x597f299cfc657e2aull,
    0x5fcb6fab3ad6faecull, 0x6c44198c4a475817ull
};

static void
sha512_compress(sha512_ctx_t *ctx, const unsigned char *block)
{
    uint64_t W[80];
    uint64_t a = ctx->state[0], b = ctx->state[1], c = ctx->state[2],
             d = ctx->state[3], e = ctx->state[4], f = ctx->state[5],
             g = ctx->state[6], h = ctx->state[7];
    uint64_t T1, T2;
    int i;

    for (i = 0; i < 16; i++) W[i] = load64_be(block + i * 8);
    for (i = 16; i < 80; i++) {
        W[i] = SSIG1_64(W[i-2]) + W[i-7] + SSIG0_64(W[i-15]) + W[i-16];
    }

    for (i = 0; i < 80; i++) {
        T1 = h + BSIG1_64(e) + CH64(e, f, g) + SHA512_K[i] + W[i];
        T2 = BSIG0_64(a) + MAJ64(a, b, c);
        h = g;
        g = f;
        f = e;
        e = d + T1;
        d = c;
        c = b;
        b = a;
        a = T1 + T2;
    }

    ctx->state[0] += a;
    ctx->state[1] += b;
    ctx->state[2] += c;
    ctx->state[3] += d;
    ctx->state[4] += e;
    ctx->state[5] += f;
    ctx->state[6] += g;
    ctx->state[7] += h;
}

void
sha512_init(sha512_ctx_t *ctx)
{
    ctx->state[0] = 0x6a09e667f3bcc908ull;
    ctx->state[1] = 0xbb67ae8584caa73bull;
    ctx->state[2] = 0x3c6ef372fe94f82bull;
    ctx->state[3] = 0xa54ff53a5f1d36f1ull;
    ctx->state[4] = 0x510e527fade682d1ull;
    ctx->state[5] = 0x9b05688c2b3e6c1full;
    ctx->state[6] = 0x1f83d9abfb41bd6bull;
    ctx->state[7] = 0x5be0cd19137e2179ull;
    ctx->bit_count_low = 0;
    ctx->bit_count_high = 0;
    ctx->buffered = 0;
}

void
sha512_update(sha512_ctx_t *ctx, const void *data, size_t len)
{
    const unsigned char *p = (const unsigned char *)data;
    uint64_t add_bits = (uint64_t)len << 3;
    uint64_t prev_low;
    size_t take;

    prev_low = ctx->bit_count_low;
    ctx->bit_count_low += add_bits;
    if (ctx->bit_count_low < prev_low) ctx->bit_count_high++;
    /* len >> 61 contributes to high if huge — not realistically
     * triggered, but handle for spec fidelity. */
    ctx->bit_count_high += (uint64_t)len >> 61;

    if (ctx->buffered) {
        take = SHA512_BLOCK_SIZE - ctx->buffered;
        if (take > len) take = len;
        memcpy(ctx->buffer + ctx->buffered, p, take);
        ctx->buffered += take;
        p   += take;
        len -= take;
        if (ctx->buffered == SHA512_BLOCK_SIZE) {
            sha512_compress(ctx, ctx->buffer);
            ctx->buffered = 0;
        }
    }
    while (len >= SHA512_BLOCK_SIZE) {
        sha512_compress(ctx, p);
        p   += SHA512_BLOCK_SIZE;
        len -= SHA512_BLOCK_SIZE;
    }
    if (len) {
        memcpy(ctx->buffer, p, len);
        ctx->buffered = len;
    }
}

void
sha512_final(sha512_ctx_t *ctx, unsigned char out[SHA512_DIGEST_SIZE])
{
    unsigned char pad[SHA512_BLOCK_SIZE];
    unsigned char len_be[16];
    uint64_t bits_low = ctx->bit_count_low;
    uint64_t bits_high = ctx->bit_count_high;
    size_t pad_len;
    int i;

    pad[0] = 0x80;
    for (i = 1; i < SHA512_BLOCK_SIZE; i++) pad[i] = 0;

    /* SHA-512 reserves the last 16 bytes for the 128-bit length. */
    if (ctx->buffered < 112)
        pad_len = 112 - ctx->buffered;
    else
        pad_len = (SHA512_BLOCK_SIZE + 112) - ctx->buffered;

    sha512_update(ctx, pad, pad_len);

    store64_be(len_be,     bits_high);
    store64_be(len_be + 8, bits_low);
    sha512_update(ctx, len_be, 16);

    for (i = 0; i < 8; i++) store64_be(out + i * 8, ctx->state[i]);
}
