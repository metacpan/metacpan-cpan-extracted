/*
 * hashx.c - Algorithm dispatch + multi-algo runner.
 *
 * Renamed from hash.c so the resulting hashx.o doesn't collide with
 * Hash.o (the XS unit) on case-insensitive filesystems.
 */

#include "hashx.h"
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

/* ---------------- algorithm registry ---------------- */

static const hash_algo_info_t HASH_ALGOS[HA_COUNT] = {
    { "sha256", HA_SHA256, SHA256_DIGEST_SIZE, 1, SHA256_BLOCK_SIZE },
    { "sha512", HA_SHA512, SHA512_DIGEST_SIZE, 1, SHA512_BLOCK_SIZE },
    { "sha1",   HA_SHA1,   SHA1_DIGEST_SIZE,   1, SHA1_BLOCK_SIZE   },
    { "md5",    HA_MD5,    MD5_DIGEST_SIZE,    1, MD5_BLOCK_SIZE    },
    { "crc32",  HA_CRC32,  CRC32_DIGEST_SIZE,  0, 0                 },
    /* xxh64 has its own seed mechanism; HMAC is not defined for it. */
    { "xxh64",  HA_XXH64,  XXH64_DIGEST_SIZE,  0, 0                 },
    /* BLAKE3 has built-in keyed-hash mode (not HMAC). v0.01 exposes
     * unkeyed mode only; HMAC-BLAKE3 is intentionally rejected. */
    { "blake3", HA_BLAKE3, BLAKE3_DIGEST_SIZE, 0, 0                 }
};

const hash_algo_info_t *
hash_algo_lookup(const char *name, size_t name_len)
{
    /* 32 covers every alias we accept (sha-256, blake3-keyed, etc.). */
    char nm[32];
    size_t k, j = 0;
    int i;

    if (name_len == 0 || name_len >= sizeof nm) return NULL;

    /* Lowercase + strip dashes/underscores so "SHA-256" / "sha_256"
     * resolve the same as "sha256". */
    for (k = 0; k < name_len; k++) {
        unsigned char c = (unsigned char)name[k];
        if (c == '-' || c == '_') continue;
        nm[j++] = (char)tolower(c);
    }
    nm[j] = '\0';

    for (i = 0; i < HA_COUNT; i++) {
        if (strcmp(nm, HASH_ALGOS[i].name) == 0)
            return &HASH_ALGOS[i];
    }
    return NULL;
}

const hash_algo_info_t *
hash_algo_by_id(hash_algo_id_t id)
{
    if ((int)id < 0 || (int)id >= HA_COUNT) return NULL;
    return &HASH_ALGOS[id];
}

/* ---------------- format parser ---------------- */

int
hash_format_parse(const char *name, size_t name_len, hash_format_t *out)
{
    /* "hex" lower vs "HEX" upper is case-sensitive (the case is the
     * signal). Other names match case-insensitively. */
    if (name_len == 3 && memcmp(name, "hex", 3) == 0) {
        *out = HF_HEX; return 0;
    }
    if (name_len == 3 && memcmp(name, "HEX", 3) == 0) {
        *out = HF_HEX_UPPER; return 0;
    }
    if (name_len == 6 && (memcmp(name, "base64", 6) == 0
                       || memcmp(name, "BASE64", 6) == 0)) {
        *out = HF_BASE64; return 0;
    }
    if (name_len == 9 && (memcmp(name, "base64url", 9) == 0
                       || memcmp(name, "BASE64URL", 9) == 0)) {
        *out = HF_BASE64URL; return 0;
    }
    if (name_len == 3 && (memcmp(name, "raw", 3) == 0
                       || memcmp(name, "RAW", 3) == 0)) {
        *out = HF_RAW; return 0;
    }
    return -1;
}

/* ---------------- formatting helpers ---------------- */

static void
to_hex(const unsigned char *in, size_t n, char *out, int upper)
{
    static const char *lo = "0123456789abcdef";
    static const char *hi = "0123456789ABCDEF";
    const char *t = upper ? hi : lo;
    size_t i;
    for (i = 0; i < n; i++) {
        out[i*2]   = t[(in[i] >> 4) & 0xF];
        out[i*2+1] = t[ in[i]       & 0xF];
    }
    out[n*2] = '\0';
}

static size_t
to_base64(const unsigned char *in, size_t n, char *out, int urlsafe)
{
    static const char std[] =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    static const char url[] =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";
    const char *a = urlsafe ? url : std;
    size_t i = 0, o = 0;
    while (i + 3 <= n) {
        unsigned t = ((unsigned)in[i]   << 16)
                   | ((unsigned)in[i+1] <<  8)
                   |  (unsigned)in[i+2];
        out[o++] = a[(t >> 18) & 0x3F];
        out[o++] = a[(t >> 12) & 0x3F];
        out[o++] = a[(t >>  6) & 0x3F];
        out[o++] = a[ t        & 0x3F];
        i += 3;
    }
    if (i < n) {
        unsigned t = (unsigned)in[i] << 16;
        if (i + 1 < n) t |= (unsigned)in[i+1] << 8;
        out[o++] = a[(t >> 18) & 0x3F];
        out[o++] = a[(t >> 12) & 0x3F];
        if (i + 1 < n) {
            out[o++] = a[(t >> 6) & 0x3F];
            if (!urlsafe) out[o++] = '=';
        } else if (!urlsafe) {
            out[o++] = '=';
            out[o++] = '=';
        }
    }
    out[o] = '\0';
    return o;
}

static size_t
formatted_len(size_t digest_bytes, hash_format_t fmt)
{
    switch (fmt) {
        case HF_HEX:
        case HF_HEX_UPPER:
            return digest_bytes * 2;
        case HF_BASE64:
            return ((digest_bytes + 2) / 3) * 4;          /* padded */
        case HF_BASE64URL: {
            size_t full = digest_bytes / 3;
            size_t tail = digest_bytes % 3;
            return full * 4 + (tail == 0 ? 0 : tail + 1); /* unpadded */
        }
        case HF_RAW:
            return digest_bytes;
    }
    return digest_bytes * 2;
}

/* ---------------- runner ---------------- */

/* Per-algo init helper. Used both by hash_runner_init and during the
 * HMAC outer pass at finish time. */
static void
algo_init(hash_one_t *a, uint64_t xxh64_seed)
{
    switch (a->id) {
        case HA_SHA256: sha256_init(&a->u.sha256); break;
        case HA_SHA512: sha512_init(&a->u.sha512); break;
        case HA_SHA1:   sha1_init  (&a->u.sha1);   break;
        case HA_MD5:    md5_init   (&a->u.md5);    break;
        case HA_CRC32:  crc32_init (&a->u.crc32);  break;
        case HA_XXH64:  xxh64_init (&a->u.xxh64, xxh64_seed); break;
        case HA_BLAKE3: blake3_init(&a->u.blake3); break;
        case HA_COUNT:  break;
    }
}

static void
algo_update(hash_one_t *a, const void *data, size_t len)
{
    switch (a->id) {
        case HA_SHA256: sha256_update(&a->u.sha256, data, len); break;
        case HA_SHA512: sha512_update(&a->u.sha512, data, len); break;
        case HA_SHA1:   sha1_update  (&a->u.sha1,   data, len); break;
        case HA_MD5:    md5_update   (&a->u.md5,    data, len); break;
        case HA_CRC32:  crc32_update (&a->u.crc32,  data, len); break;
        case HA_XXH64:  xxh64_update (&a->u.xxh64,  data, len); break;
        case HA_BLAKE3: blake3_update(&a->u.blake3, data, len); break;
        case HA_COUNT:  break;
    }
}

static void
algo_final(hash_one_t *a, unsigned char *digest)
{
    switch (a->id) {
        case HA_SHA256: sha256_final(&a->u.sha256, digest); break;
        case HA_SHA512: sha512_final(&a->u.sha512, digest); break;
        case HA_SHA1:   sha1_final  (&a->u.sha1,   digest); break;
        case HA_MD5:    md5_final   (&a->u.md5,    digest); break;
        case HA_CRC32:  crc32_final (&a->u.crc32,  digest); break;
        case HA_XXH64:  xxh64_final (&a->u.xxh64,  digest); break;
        case HA_BLAKE3: blake3_final(&a->u.blake3, digest); break;
        case HA_COUNT:  break;
    }
}

int
hash_runner_init(hash_runner_t *r, const hash_algo_id_t *ids, int n,
                 hash_format_t format, uint64_t xxh64_seed)
{
    int i;
    if (!r || n < 1) return -1;
    r->count           = n;
    r->format          = format;
    r->xxh64_seed      = xxh64_seed;
    r->_finish_results = NULL;
    r->_finish_blob    = NULL;
    r->algos           = (hash_one_t *)calloc((size_t)n, sizeof *r->algos);
    if (!r->algos) return -1;

    for (i = 0; i < n; i++) {
        hash_algo_id_t id = ids[i];
        if ((int)id < 0 || (int)id >= HA_COUNT) {
            free(r->algos);
            r->algos = NULL;
            r->count = 0;
            return -1;
        }
        r->algos[i].id        = id;
        r->algos[i].hmac_mode = 0;
        algo_init(&r->algos[i], xxh64_seed);
    }
    return 0;
}

int
hash_runner_set_hmac(hash_runner_t *r,
                     const unsigned char *key, size_t key_len)
{
    int i;
    unsigned char k_prime[HMAC_MAX_BLOCK_SIZE];
    unsigned char ipad_key[HMAC_MAX_BLOCK_SIZE];
    if (!r || !r->algos) return -1;

    /* Pre-flight: every algo in the runner must be HMAC-able. */
    for (i = 0; i < r->count; i++) {
        const hash_algo_info_t *info = hash_algo_by_id(r->algos[i].id);
        if (!info->hmac_able) return -1;
    }

    for (i = 0; i < r->count; i++) {
        hash_one_t *a = &r->algos[i];
        const hash_algo_info_t *info = hash_algo_by_id(a->id);
        size_t B = info->hmac_block_size;
        size_t j;

        /* Derive K': hash the key down if it's longer than B,
         * then zero-pad to B. */
        if (key_len > B) {
            /* Run the algo over the key into k_prime. We use a fresh
             * temporary context to avoid disturbing a->u (which is
             * about to be re-initialised for the inner pass). */
            hash_one_t tmp;
            unsigned char digest[HASH_MAX_DIGEST_SIZE];
            tmp.id = a->id;
            algo_init(&tmp, r->xxh64_seed);
            algo_update(&tmp, key, key_len);
            algo_final(&tmp, digest);
            memcpy(k_prime, digest, info->digest_size);
            for (j = info->digest_size; j < B; j++) k_prime[j] = 0;
        } else {
            memcpy(k_prime, key, key_len);
            for (j = key_len; j < B; j++) k_prime[j] = 0;
        }

        /* ipad and opad keys. */
        for (j = 0; j < B; j++) {
            ipad_key[j]       = k_prime[j] ^ 0x36;
            a->hmac_opad_key[j] = k_prime[j] ^ 0x5c;
        }
        a->hmac_block_size = B;
        a->hmac_mode       = 1;

        /* Re-init inner ctx (still in the same union slot) and feed
         * the ipad key. The actual user data will follow via
         * hash_runner_update. */
        algo_init(a, r->xxh64_seed);
        algo_update(a, ipad_key, B);
    }
    return 0;
}

void
hash_runner_update(hash_runner_t *r, const void *data, size_t len)
{
    int i;
    if (!r || !r->algos || len == 0) return;
    for (i = 0; i < r->count; i++) {
        algo_update(&r->algos[i], data, len);
    }
}

int
hash_runner_finish(hash_runner_t *r, const hash_result_t **out)
{
    int i;
    size_t total_bytes = 0;
    char *cursor;
    hash_result_t *res;
    char          *blob;
    unsigned char  digest[HASH_MAX_DIGEST_SIZE];

    if (!r || !r->algos) return -1;

    /* Free any prior finish result so a second call doesn't leak. */
    free(r->_finish_results);
    free(r->_finish_blob);
    r->_finish_results = NULL;
    r->_finish_blob    = NULL;

    for (i = 0; i < r->count; i++) {
        const hash_algo_info_t *info = hash_algo_by_id(r->algos[i].id);
        total_bytes += formatted_len(info->digest_size, r->format) + 1;
    }

    res = (hash_result_t *)calloc((size_t)r->count, sizeof *res);
    if (!res) return -1;
    blob = (char *)malloc(total_bytes ? total_bytes : 1);
    if (!blob) { free(res); return -1; }

    cursor = blob;
    for (i = 0; i < r->count; i++) {
        hash_one_t *a = &r->algos[i];
        const hash_algo_info_t *info = hash_algo_by_id(a->id);
        size_t flen;

        algo_final(a, digest);

        /* HMAC outer pass: hash(opad_key || inner_digest) replaces
         * digest with the keyed MAC. */
        if (a->hmac_mode) {
            unsigned char outer[HASH_MAX_DIGEST_SIZE];
            algo_init(a, r->xxh64_seed);
            algo_update(a, a->hmac_opad_key, a->hmac_block_size);
            algo_update(a, digest, info->digest_size);
            algo_final(a, outer);
            memcpy(digest, outer, info->digest_size);
        }

        flen = formatted_len(info->digest_size, r->format);
        switch (r->format) {
            case HF_HEX:
                to_hex(digest, info->digest_size, cursor, 0);
                break;
            case HF_HEX_UPPER:
                to_hex(digest, info->digest_size, cursor, 1);
                break;
            case HF_BASE64:
                (void)to_base64(digest, info->digest_size, cursor, 0);
                break;
            case HF_BASE64URL:
                (void)to_base64(digest, info->digest_size, cursor, 1);
                break;
            case HF_RAW:
                memcpy(cursor, digest, info->digest_size);
                cursor[info->digest_size] = '\0';
                break;
        }

        res[i].id      = a->id;
        res[i].name    = info->name;
        res[i].out     = cursor;
        res[i].out_len = flen;

        cursor += flen + 1;
    }

    r->_finish_results = res;
    r->_finish_blob    = blob;
    *out = res;
    return 0;
}

void
hash_runner_free(hash_runner_t *r)
{
    if (!r) return;
    free(r->_finish_results);
    free(r->_finish_blob);
    r->_finish_results = NULL;
    r->_finish_blob    = NULL;
    free(r->algos);
    r->algos = NULL;
    r->count = 0;
}
