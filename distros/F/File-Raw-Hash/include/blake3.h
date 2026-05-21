/*
 * blake3.h - BLAKE3 (32-byte default output) for File::Raw::Hash.
 *
 * Sequential, single-threaded reference. No SIMD. Spec:
 *   https://github.com/BLAKE3-team/BLAKE3-specs
 *
 * v0.01: hash mode only (no keyed-hash, no derive-key, no XOF beyond
 * the default 32-byte output). Streaming via a chunk stack for
 * O(log N) memory.
 */

#ifndef FILE_RAW_HASH_BLAKE3_H
#define FILE_RAW_HASH_BLAKE3_H

#include <stddef.h>
#include <stdint.h>

#define BLAKE3_DIGEST_SIZE  32
#define BLAKE3_BLOCK_SIZE   64
#define BLAKE3_CHUNK_SIZE   1024
#define BLAKE3_MAX_DEPTH    54   /* log2(2^64 / 1024) headroom */

/* Per-chunk state: accumulates up to 1024 bytes through up to 16
 * 64-byte block compressions, carrying the chaining value forward. */
typedef struct {
    uint32_t chaining_value[8];  /* CV after the most recent block */
    uint64_t chunk_counter;      /* index of this chunk in the input */
    unsigned char buffer[BLAKE3_BLOCK_SIZE];
    uint8_t  buffer_len;         /* 0..63: bytes pending in buffer */
    uint8_t  blocks_compressed;  /* 0..16 within this chunk */
} blake3_chunk_state_t;

/* Streaming context. Chunks complete -> stack of CVs grows; pairs of
 * same-level CVs collapse into parents lazily via input_total. */
typedef struct {
    blake3_chunk_state_t chunk;
    uint8_t cv_stack_len;
    uint32_t cv_stack[BLAKE3_MAX_DEPTH][8];
    /* Snapshots taken at the start of every chunk so we can rewind one
     * chunk in `final` to set CHUNK_END+ROOT flags correctly when only
     * a single chunk has been seen. Saved cheaply each chunk start. */
    uint32_t key_words[8];       /* IV for hash mode; per-call key for keyed mode (unused v0.01) */
    uint8_t  flags;              /* domain-separation flags carried in compress (0 for hash mode) */
} blake3_ctx_t;

void blake3_init  (blake3_ctx_t *ctx);
void blake3_update(blake3_ctx_t *ctx, const void *data, size_t len);
void blake3_final (blake3_ctx_t *ctx, unsigned char out[BLAKE3_DIGEST_SIZE]);

#endif /* FILE_RAW_HASH_BLAKE3_H */
