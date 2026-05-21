/*
 * hashx.h - Algorithm dispatch + multi-algo runner for File::Raw::Hash.
 *
 * Wraps the vendored codecs (sha2 / sha1 / md5 / crc32 / xxh64 / blake3)
 * behind a uniform name -> id -> compute pipeline. Optional HMAC mode
 * wraps any of the cryptographic algos with RFC 2104 keying. The XS
 * layer (Hash.xs) calls into here; this file knows nothing about Perl.
 *
 * Renamed from hash.h so the hashx.o object doesn't collide with Hash.o
 * (the XS unit) on case-insensitive filesystems.
 */

#ifndef FILE_RAW_HASHX_H
#define FILE_RAW_HASHX_H

#include <stddef.h>
#include "sha2.h"
#include "sha1.h"
#include "md5.h"
#include "crc32.h"
#include "xxh64.h"
#include "blake3.h"

/* Largest digest we produce (SHA-512). Any output buffer sized this
 * big is enough for every algo. */
#define HASH_MAX_DIGEST_SIZE 64

/* Largest underlying-hash block size we need for HMAC (SHA-512 has
 * B = 128). Other HMAC-able algos all use B = 64. */
#define HMAC_MAX_BLOCK_SIZE  128

typedef enum {
    HA_SHA256 = 0,
    HA_SHA512,
    HA_SHA1,
    HA_MD5,
    HA_CRC32,
    HA_XXH64,
    HA_BLAKE3,
    HA_COUNT
} hash_algo_id_t;

typedef enum {
    HF_HEX = 0,        /* lowercase, default */
    HF_HEX_UPPER,      /* uppercase */
    HF_BASE64,         /* RFC 4648 section 4, padded */
    HF_BASE64URL,      /* RFC 4648 section 5, no padding */
    HF_RAW             /* binary digest bytes */
} hash_format_t;

typedef struct {
    const char    *name;          /* canonical lowercase name */
    hash_algo_id_t id;
    size_t         digest_size;   /* in bytes */
    int            hmac_able;     /* 1 if RFC 2104 HMAC is defined for this algo */
    size_t         hmac_block_size; /* B from RFC 2104; 0 if !hmac_able */
} hash_algo_info_t;

/* Look up an algo by name (case-insensitive). Returns NULL on miss. */
const hash_algo_info_t *hash_algo_lookup(const char *name, size_t name_len);

/* Look up by id (asserts in range). Useful for dispatch tables. */
const hash_algo_info_t *hash_algo_by_id(hash_algo_id_t id);

/* Parse a format name. Returns -1 on miss; on success writes to *out. */
int hash_format_parse(const char *name, size_t name_len, hash_format_t *out);

/* One running digest. Lifetime: from runner_init through runner_finish.
 * Lives inside the runner. */
typedef struct {
    hash_algo_id_t id;
    int            hmac_mode;                 /* 0 plain, 1 HMAC-wrapped */
    size_t         hmac_block_size;           /* per-algo B for HMAC */
    unsigned char  hmac_opad_key[HMAC_MAX_BLOCK_SIZE];
    union {
        sha256_ctx_t sha256;
        sha512_ctx_t sha512;
        sha1_ctx_t   sha1;
        md5_ctx_t    md5;
        crc32_ctx_t  crc32;
        xxh64_ctx_t  xxh64;
        blake3_ctx_t blake3;
    } u;
} hash_one_t;

/* The runner: N algorithms updated in lockstep with the same byte
 * stream, plus a chosen output format applied at finish time. */
typedef struct {
    int            count;
    hash_one_t    *algos;       /* count entries */
    hash_format_t  format;
    uint64_t       xxh64_seed;  /* used when any algo == HA_XXH64 */
    /* Private: ownership for finish-time allocations. Don't touch from
     * outside hashx.c. */
    void          *_finish_results;
    void          *_finish_blob;
} hash_runner_t;

/* Initialise a runner with N algos. Each id must be < HA_COUNT. The
 * xxh64_seed argument is only consulted by HA_XXH64 entries; pass 0
 * for the default seed. Returns 0 on success, -1 on alloc failure.
 * The runner takes ownership of its own buffers; pair with
 * hash_runner_free. */
int hash_runner_init(hash_runner_t *r, const hash_algo_id_t *ids, int n,
                     hash_format_t format, uint64_t xxh64_seed);

/* Upgrade an already-initialised runner to HMAC mode using `key`.
 * Validates that every algo in the runner is hmac_able; returns -1
 * (and leaves the runner usable in plain mode) if any is not. The
 * key may be any length; the standard derives K' internally. */
int hash_runner_set_hmac(hash_runner_t *r,
                         const unsigned char *key, size_t key_len);

/* Feed bytes into every algo. */
void hash_runner_update(hash_runner_t *r, const void *data, size_t len);

/* Output of one finalised algorithm. `out` is a pointer into a buffer
 * the runner owns; valid until hash_runner_free. */
typedef struct {
    hash_algo_id_t id;
    const char    *name;       /* canonical algo name */
    char          *out;        /* formatted digest, NUL-terminated */
    size_t         out_len;    /* length of out (excl. NUL) */
} hash_result_t;

/* Finalise every algo. *results points to an internal array of count
 * entries on return; valid until hash_runner_free. Returns 0 on
 * success, -1 on alloc failure. */
int hash_runner_finish(hash_runner_t *r, const hash_result_t **results);

/* Free everything the runner allocated. Idempotent. */
void hash_runner_free(hash_runner_t *r);

/* Note: stdint.h is pulled in transitively via sha2.h (uint64_t). */
#include <stdint.h>

#endif /* FILE_RAW_HASHX_H */
