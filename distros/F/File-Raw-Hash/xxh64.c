/*
 * xxh64.c - XXH64 implementation per the xxHash specification.
 *
 * Big-endian/little-endian agnostic via byte-by-byte loaders. The
 * algorithm itself is little-endian for input lanes; we read each
 * lane bytewise, never type-pun.
 */

#include "xxh64.h"
#include <string.h>

#define ROL64(x, n) (((x) << (n)) | ((x) >> (64 - (n))))

#define PRIME64_1  0x9E3779B185EBCA87ULL
#define PRIME64_2  0xC2B2AE3D27D4EB4FULL
#define PRIME64_3  0x165667B19E3779F9ULL
#define PRIME64_4  0x85EBCA77C2B2AE63ULL
#define PRIME64_5  0x27D4EB2F165667C5ULL

static uint64_t
load64_le(const unsigned char *p)
{
    return  (uint64_t)p[0]
        | ((uint64_t)p[1] <<  8)
        | ((uint64_t)p[2] << 16)
        | ((uint64_t)p[3] << 24)
        | ((uint64_t)p[4] << 32)
        | ((uint64_t)p[5] << 40)
        | ((uint64_t)p[6] << 48)
        | ((uint64_t)p[7] << 56);
}

static uint32_t
load32_le(const unsigned char *p)
{
    return  (uint32_t)p[0]
        | ((uint32_t)p[1] <<  8)
        | ((uint32_t)p[2] << 16)
        | ((uint32_t)p[3] << 24);
}

static uint64_t
xxh64_round(uint64_t acc, uint64_t input)
{
    acc += input * PRIME64_2;
    acc  = ROL64(acc, 31);
    acc *= PRIME64_1;
    return acc;
}

static uint64_t
xxh64_merge_round(uint64_t acc, uint64_t val)
{
    val = xxh64_round(0, val);
    acc ^= val;
    acc  = acc * PRIME64_1 + PRIME64_4;
    return acc;
}

void
xxh64_init(xxh64_ctx_t *ctx, uint64_t seed)
{
    ctx->v[0] = seed + PRIME64_1 + PRIME64_2;
    ctx->v[1] = seed + PRIME64_2;
    ctx->v[2] = seed + 0;
    ctx->v[3] = seed - PRIME64_1;
    ctx->total_len = 0;
    ctx->seed = seed;
    ctx->large_path_seen = 0;
    ctx->buffered = 0;
}

static void
xxh64_consume_stripe(xxh64_ctx_t *ctx, const unsigned char *p)
{
    ctx->v[0] = xxh64_round(ctx->v[0], load64_le(p     ));
    ctx->v[1] = xxh64_round(ctx->v[1], load64_le(p +  8));
    ctx->v[2] = xxh64_round(ctx->v[2], load64_le(p + 16));
    ctx->v[3] = xxh64_round(ctx->v[3], load64_le(p + 24));
    ctx->large_path_seen = 1;
}

void
xxh64_update(xxh64_ctx_t *ctx, const void *data, size_t len)
{
    const unsigned char *p = (const unsigned char *)data;
    size_t take;

    ctx->total_len += len;

    /* Drain the partial-stripe buffer if it can complete a stripe. */
    if (ctx->buffered) {
        take = XXH64_BLOCK_SIZE - ctx->buffered;
        if (take > len) take = len;
        memcpy(ctx->buffer + ctx->buffered, p, take);
        ctx->buffered += take;
        p   += take;
        len -= take;
        if (ctx->buffered == XXH64_BLOCK_SIZE) {
            xxh64_consume_stripe(ctx, ctx->buffer);
            ctx->buffered = 0;
        }
    }

    while (len >= XXH64_BLOCK_SIZE) {
        xxh64_consume_stripe(ctx, p);
        p   += XXH64_BLOCK_SIZE;
        len -= XXH64_BLOCK_SIZE;
    }

    if (len) {
        memcpy(ctx->buffer, p, len);
        ctx->buffered = len;
    }
}

void
xxh64_final(xxh64_ctx_t *ctx, unsigned char out[XXH64_DIGEST_SIZE])
{
    uint64_t h;
    const unsigned char *p = ctx->buffer;
    size_t remaining = ctx->buffered;
    int i;

    if (ctx->large_path_seen) {
        h = ROL64(ctx->v[0], 1) + ROL64(ctx->v[1], 7)
          + ROL64(ctx->v[2], 12) + ROL64(ctx->v[3], 18);
        h = xxh64_merge_round(h, ctx->v[0]);
        h = xxh64_merge_round(h, ctx->v[1]);
        h = xxh64_merge_round(h, ctx->v[2]);
        h = xxh64_merge_round(h, ctx->v[3]);
    } else {
        h = ctx->seed + PRIME64_5;
    }

    h += ctx->total_len;

    /* Process remaining bytes: 8-byte, then 4-byte, then 1-byte
     * chunks per the spec's mix table. */
    while (remaining >= 8) {
        uint64_t k = load64_le(p);
        k  = xxh64_round(0, k);
        h ^= k;
        h  = ROL64(h, 27) * PRIME64_1 + PRIME64_4;
        p += 8;
        remaining -= 8;
    }
    if (remaining >= 4) {
        uint64_t k = (uint64_t)load32_le(p);
        h ^= k * PRIME64_1;
        h  = ROL64(h, 23) * PRIME64_2 + PRIME64_3;
        p += 4;
        remaining -= 4;
    }
    while (remaining > 0) {
        h ^= (uint64_t)(*p) * PRIME64_5;
        h  = ROL64(h, 11) * PRIME64_1;
        p++;
        remaining--;
    }

    /* Avalanche. */
    h ^= h >> 33;
    h *= PRIME64_2;
    h ^= h >> 29;
    h *= PRIME64_3;
    h ^= h >> 32;

    /* Big-endian output: matches conventional hex display
     * (xxhsum -H64). */
    for (i = 0; i < 8; i++) {
        out[i] = (unsigned char)((h >> (56 - i * 8)) & 0xFFu);
    }
}
