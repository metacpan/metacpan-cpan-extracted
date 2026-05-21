/*
 * blake3.c - BLAKE3 reference implementation, sequential, no SIMD.
 *
 * Implements the BLAKE3 hash function in hash mode with the default
 * 32-byte (256-bit) output. Streaming via the spec's tree-stack
 * algorithm: at any moment we hold one in-progress chunk plus up to
 * BLAKE3_MAX_DEPTH chaining values waiting to be combined with their
 * right siblings. Per-call memory is O(log N) over the input length.
 */

#include "blake3.h"
#include <string.h>

/* ---------------- constants ---------------- */

static const uint32_t IV[8] = {
    0x6A09E667u, 0xBB67AE85u, 0x3C6EF372u, 0xA54FF53Au,
    0x510E527Fu, 0x9B05688Cu, 0x1F83D9ABu, 0x5BE0CD19u
};

/* Domain-separation flags. */
#define CHUNK_START         0x01u
#define CHUNK_END           0x02u
#define PARENT              0x04u
#define ROOT                0x08u
/* KEYED_HASH / DERIVE_KEY_* unused in v0.01 (hash mode only). */

/* Message-word permutation applied between rounds (rounds 1..6). */
static const uint8_t MSG_PERM[16] = {
    2, 6, 3, 10, 7, 0, 4, 13, 1, 11, 12, 5, 9, 14, 15, 8
};

/* ---------------- bit/byte helpers ---------------- */

#define ROR32(x, n) (((x) >> (n)) | ((x) << (32 - (n))))

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

/* ---------------- compression ---------------- */

static void
g_mix(uint32_t state[16], int a, int b, int c, int d, uint32_t mx, uint32_t my)
{
    state[a] = state[a] + state[b] + mx;
    state[d] = ROR32(state[d] ^ state[a], 16);
    state[c] = state[c] + state[d];
    state[b] = ROR32(state[b] ^ state[c], 12);
    state[a] = state[a] + state[b] + my;
    state[d] = ROR32(state[d] ^ state[a], 8);
    state[c] = state[c] + state[d];
    state[b] = ROR32(state[b] ^ state[c], 7);
}

static void
round_fn(uint32_t state[16], const uint32_t m[16])
{
    /* Columns. */
    g_mix(state, 0, 4,  8, 12, m[0], m[1]);
    g_mix(state, 1, 5,  9, 13, m[2], m[3]);
    g_mix(state, 2, 6, 10, 14, m[4], m[5]);
    g_mix(state, 3, 7, 11, 15, m[6], m[7]);
    /* Diagonals. */
    g_mix(state, 0, 5, 10, 15, m[ 8], m[ 9]);
    g_mix(state, 1, 6, 11, 12, m[10], m[11]);
    g_mix(state, 2, 7,  8, 13, m[12], m[13]);
    g_mix(state, 3, 4,  9, 14, m[14], m[15]);
}

static void
permute(uint32_t m[16])
{
    uint32_t tmp[16];
    int i;
    for (i = 0; i < 16; i++) tmp[i] = m[MSG_PERM[i]];
    for (i = 0; i < 16; i++) m[i] = tmp[i];
}

/* compress: produces full 16-word output. Caller takes the first 8
 * words for a chaining value, or all 16 for a root-output block. */
static void
compress(const uint32_t chaining_value[8],
         const uint32_t block_words_in[16],
         uint64_t counter,
         uint32_t block_len,
         uint32_t flags,
         uint32_t out[16])
{
    uint32_t state[16];
    uint32_t block_words[16];
    int i;

    state[ 0] = chaining_value[0];
    state[ 1] = chaining_value[1];
    state[ 2] = chaining_value[2];
    state[ 3] = chaining_value[3];
    state[ 4] = chaining_value[4];
    state[ 5] = chaining_value[5];
    state[ 6] = chaining_value[6];
    state[ 7] = chaining_value[7];
    state[ 8] = IV[0];
    state[ 9] = IV[1];
    state[10] = IV[2];
    state[11] = IV[3];
    state[12] = (uint32_t)(counter & 0xFFFFFFFFull);
    state[13] = (uint32_t)((counter >> 32) & 0xFFFFFFFFull);
    state[14] = block_len;
    state[15] = flags;

    for (i = 0; i < 16; i++) block_words[i] = block_words_in[i];

    round_fn(state, block_words);             /* round 1 */
    permute(block_words);
    round_fn(state, block_words);             /* round 2 */
    permute(block_words);
    round_fn(state, block_words);             /* round 3 */
    permute(block_words);
    round_fn(state, block_words);             /* round 4 */
    permute(block_words);
    round_fn(state, block_words);             /* round 5 */
    permute(block_words);
    round_fn(state, block_words);             /* round 6 */
    permute(block_words);
    round_fn(state, block_words);             /* round 7 */

    /* XOR upper half into lower half, then upper into chaining value
     * - this is the "feedforward" the spec describes. The full 16-word
     * output is what the caller can consume. */
    for (i = 0; i < 8; i++) {
        state[i]     ^= state[i + 8];
        state[i + 8] ^= chaining_value[i];
    }

    for (i = 0; i < 16; i++) out[i] = state[i];
}

/* Convert a 64-byte block to 16 little-endian words. */
static void
block_to_words(const unsigned char *block, uint32_t out[16])
{
    int i;
    for (i = 0; i < 16; i++) out[i] = load32_le(block + i * 4);
}

/* ---------------- chunk machinery ---------------- */

static uint32_t
chunk_start_flag(const blake3_chunk_state_t *cs)
{
    return cs->blocks_compressed == 0 ? CHUNK_START : 0;
}

static void
chunk_init(blake3_chunk_state_t *cs, const uint32_t key[8], uint64_t counter)
{
    int i;
    for (i = 0; i < 8; i++) cs->chaining_value[i] = key[i];
    cs->chunk_counter     = counter;
    cs->buffer_len        = 0;
    cs->blocks_compressed = 0;
    /* Zero the buffer so that a partial-or-empty last block is read as
     * zero-padded message words. Without this an empty input would
     * read stack garbage from the buffer in chunk_output_root. */
    memset(cs->buffer, 0, BLAKE3_BLOCK_SIZE);
}

static size_t
chunk_len(const blake3_chunk_state_t *cs)
{
    return (size_t)cs->blocks_compressed * BLAKE3_BLOCK_SIZE + cs->buffer_len;
}

static void
chunk_compress_buffer(blake3_chunk_state_t *cs, uint32_t flags)
{
    uint32_t block_words[16];
    uint32_t out[16];
    int i;

    block_to_words(cs->buffer, block_words);
    compress(cs->chaining_value, block_words, cs->chunk_counter,
             (uint32_t)cs->buffer_len,
             flags | chunk_start_flag(cs),
             out);
    for (i = 0; i < 8; i++) cs->chaining_value[i] = out[i];
    cs->blocks_compressed++;
    cs->buffer_len = 0;
    memset(cs->buffer, 0, BLAKE3_BLOCK_SIZE);
}

/* Append `len` bytes (len > 0). Caller must ensure chunk_len + len
 * <= BLAKE3_CHUNK_SIZE. */
static void
chunk_update(blake3_chunk_state_t *cs, const unsigned char *p, size_t len,
             uint32_t flags)
{
    /* Fill any partial block, compressing only when we know more bytes
     * (or a chunk boundary) will follow. We never compress the LAST
     * block of a chunk here - the caller does that with CHUNK_END. */
    while (len > 0) {
        size_t take;
        if (cs->buffer_len == BLAKE3_BLOCK_SIZE) {
            chunk_compress_buffer(cs, flags);
        }
        take = BLAKE3_BLOCK_SIZE - cs->buffer_len;
        if (take > len) take = len;
        memcpy(cs->buffer + cs->buffer_len, p, take);
        cs->buffer_len += (uint8_t)take;
        p   += take;
        len -= take;
    }
}

/* Finalise a chunk into an 8-word chaining value (used as a leaf in
 * the tree). Caller passes `is_root` to add the ROOT flag, in which
 * case `out16` (16 words) gets the full output for byte extraction. */
static void
chunk_output_cv(blake3_chunk_state_t *cs, uint32_t flags, uint32_t out_cv[8])
{
    uint32_t block_words[16];
    uint32_t out[16];
    int i;

    block_to_words(cs->buffer, block_words);
    compress(cs->chaining_value, block_words, cs->chunk_counter,
             (uint32_t)cs->buffer_len,
             flags | chunk_start_flag(cs) | CHUNK_END,
             out);
    for (i = 0; i < 8; i++) out_cv[i] = out[i];
}

/* As above but produces the full 16-word root output. */
static void
chunk_output_root(blake3_chunk_state_t *cs, uint32_t flags,
                  unsigned char out_bytes[BLAKE3_DIGEST_SIZE])
{
    uint32_t block_words[16];
    uint32_t out[16];
    int i;

    block_to_words(cs->buffer, block_words);
    compress(cs->chaining_value, block_words, cs->chunk_counter,
             (uint32_t)cs->buffer_len,
             flags | chunk_start_flag(cs) | CHUNK_END | ROOT,
             out);
    for (i = 0; i < 8; i++) store32_le(out_bytes + i * 4, out[i]);
}

/* ---------------- parent machinery ---------------- */

/* Combine left+right CVs into a single parent CV. */
static void
parent_cv(const uint32_t left[8], const uint32_t right[8],
          const uint32_t key[8], uint32_t flags, uint32_t out_cv[8])
{
    uint32_t block_words[16];
    uint32_t out[16];
    int i;
    for (i = 0; i < 8; i++) block_words[i]     = left[i];
    for (i = 0; i < 8; i++) block_words[i + 8] = right[i];

    compress(key, block_words, 0, BLAKE3_BLOCK_SIZE,
             flags | PARENT, out);
    for (i = 0; i < 8; i++) out_cv[i] = out[i];
}

/* As above, root version producing the 32-byte output. */
static void
parent_output_root(const uint32_t left[8], const uint32_t right[8],
                   const uint32_t key[8], uint32_t flags,
                   unsigned char out_bytes[BLAKE3_DIGEST_SIZE])
{
    uint32_t block_words[16];
    uint32_t out[16];
    int i;
    for (i = 0; i < 8; i++) block_words[i]     = left[i];
    for (i = 0; i < 8; i++) block_words[i + 8] = right[i];

    compress(key, block_words, 0, BLAKE3_BLOCK_SIZE,
             flags | PARENT | ROOT, out);
    for (i = 0; i < 8; i++) store32_le(out_bytes + i * 4, out[i]);
}

/* ---------------- public API ---------------- */

void
blake3_init(blake3_ctx_t *ctx)
{
    int i;
    for (i = 0; i < 8; i++) ctx->key_words[i] = IV[i];
    ctx->flags = 0;                         /* hash mode */
    ctx->cv_stack_len = 0;
    chunk_init(&ctx->chunk, ctx->key_words, 0);
}

/* Push a CV onto the stack and collapse pairs of equal-level CVs into
 * parents. The trick: every time we add chunk N+1 to the tree, we
 * collapse pairs starting at the level matching the count of trailing
 * zeros in N+1. We track the chunk index implicitly via the stack
 * length; the "merge if total chunks is even at this level" check is
 * encoded by counting trailing zeros in the post-add chunk count. */
static void
push_chunk_cv(blake3_ctx_t *ctx, uint32_t new_cv[8], uint64_t total_chunks)
{
    /* `total_chunks` is the number of chunks ALREADY added (so the new
     * one being pushed is chunk index `total_chunks`, and after push
     * we'll have total_chunks+1 chunks total). The standard collapses
     * stack pairs while the count of completed chunks is even at the
     * relevant level - equivalently while the LSB-going-up bits of
     * total_chunks (post-increment) match. */
    uint64_t post = total_chunks; /* chunks completed so far before push */
    uint32_t cv[8];
    int i;
    for (i = 0; i < 8; i++) cv[i] = new_cv[i];

    /* Merge while the bit at the current level of post is set; that
     * indicates an unpaired CV at that level. */
    while (post & 1) {
        uint32_t left[8];
        ctx->cv_stack_len--;
        for (i = 0; i < 8; i++) left[i] = ctx->cv_stack[ctx->cv_stack_len][i];
        parent_cv(left, cv, ctx->key_words, ctx->flags, cv);
        post >>= 1;
    }
    for (i = 0; i < 8; i++) ctx->cv_stack[ctx->cv_stack_len][i] = cv[i];
    ctx->cv_stack_len++;
}

void
blake3_update(blake3_ctx_t *ctx, const void *data, size_t len)
{
    const unsigned char *p = (const unsigned char *)data;

    while (len > 0) {
        size_t want;
        size_t cur = chunk_len(&ctx->chunk);

        /* If the current chunk is full, finalise it as a leaf and
         * rotate to a fresh chunk. */
        if (cur == BLAKE3_CHUNK_SIZE) {
            uint32_t leaf_cv[8];
            uint64_t this_idx = ctx->chunk.chunk_counter;
            chunk_output_cv(&ctx->chunk, ctx->flags, leaf_cv);
            push_chunk_cv(ctx, leaf_cv, this_idx);
            chunk_init(&ctx->chunk, ctx->key_words, this_idx + 1);
            cur = 0;
        }

        want = BLAKE3_CHUNK_SIZE - cur;
        if (want > len) want = len;
        chunk_update(&ctx->chunk, p, want, ctx->flags);
        p   += want;
        len -= want;
    }
}

void
blake3_final(blake3_ctx_t *ctx, unsigned char out[BLAKE3_DIGEST_SIZE])
{
    int i;

    /* If we never compressed any leaf into the stack, this is a
     * single-chunk hash: the chunk itself is the root. */
    if (ctx->cv_stack_len == 0) {
        chunk_output_root(&ctx->chunk, ctx->flags, out);
        return;
    }

    /* Otherwise we collapse the stack from the bottom up. The chunk
     * we hold becomes the rightmost leaf at the bottom level; combine
     * it with whatever sits at the top of the stack until we reach the
     * single root parent that needs ROOT-flag output. */
    {
        uint32_t cv[8];
        chunk_output_cv(&ctx->chunk, ctx->flags, cv);

        /* Walk the stack: every entry must be combined as the LEFT
         * sibling of `cv`. When only one stack entry remains, the
         * combination is the ROOT and produces output bytes. */
        while (ctx->cv_stack_len > 1) {
            uint32_t left[8];
            ctx->cv_stack_len--;
            for (i = 0; i < 8; i++) left[i] = ctx->cv_stack[ctx->cv_stack_len][i];
            parent_cv(left, cv, ctx->key_words, ctx->flags, cv);
        }
        /* Final root parent. */
        {
            uint32_t left[8];
            ctx->cv_stack_len--;
            for (i = 0; i < 8; i++) left[i] = ctx->cv_stack[ctx->cv_stack_len][i];
            parent_output_root(left, cv, ctx->key_words, ctx->flags, out);
        }
    }
}
