/*
 * gz.c - zlib inflate/deflate wrappers driving a malloc-grown output
 * buffer. Both functions consume the entire input in one go (one-shot
 * codec, no streaming). Output buffer doubles when full; that bounds
 * realloc count to log2(out_size).
 */

#include "gz.h"

#include <stdlib.h>
#include <string.h>
#include <zlib.h>

#define GZ_DEFAULT_CHUNK   (128 * 1024)
#define GZ_DEFAULT_LEVEL   6
#define GZ_DEFAULT_MEM     8

void gz_options_init(gz_options_t *opts) {
    opts->level      = GZ_DEFAULT_LEVEL;
    opts->mode       = GZ_MODE_AUTO;
    opts->chunk_size = GZ_DEFAULT_CHUNK;
    opts->strategy   = Z_DEFAULT_STRATEGY;
    opts->mem_level  = GZ_DEFAULT_MEM;
}

static int wbits_for_mode(gz_mode_t mode, int encoding) {
    switch (mode) {
    case GZ_MODE_GZIP: return MAX_WBITS | 16;       /* 31 */
    case GZ_MODE_ZLIB: return MAX_WBITS;            /* 15 */
    case GZ_MODE_RAW:  return -MAX_WBITS;           /* -15 */
    case GZ_MODE_AUTO: return encoding ? -1 : (MAX_WBITS | 32); /* 47 decode */
    }
    return -1;
}

static gz_err_t map_z_err(int z) {
    switch (z) {
    case Z_OK:           return GZ_OK;
    case Z_STREAM_END:   return GZ_OK;
    case Z_NEED_DICT:    return GZ_ERR_NEED_DICT;
    case Z_DATA_ERROR:   return GZ_ERR_DATA;
    case Z_MEM_ERROR:    return GZ_ERR_MEM;
    case Z_BUF_ERROR:    return GZ_ERR_BUF;
    case Z_VERSION_ERROR:return GZ_ERR_VERSION;
    default:             return GZ_ERR_DATA;
    }
}

const char *gz_strerror(gz_err_t err) {
    switch (err) {
    case GZ_OK:             return "ok";
    case GZ_ERR_INIT:       return "zlib init failed";
    case GZ_ERR_DATA:       return "corrupt input stream";
    case GZ_ERR_NEED_DICT:  return "stream requires preset dictionary (unsupported)";
    case GZ_ERR_MEM:        return "out of memory";
    case GZ_ERR_BUF:        return "buffer error";
    case GZ_ERR_VERSION:    return "zlib version mismatch";
    case GZ_ERR_OPT:        return "invalid option";
    case GZ_ERR_TRUNCATED:  return "input ended before stream completion";
    }
    return "unknown error";
}

/* Grow `*buf` so it has at least `*cap >= used + need` bytes. Returns 0
 * on success, GZ_ERR_MEM on allocation failure (leaves *buf untouched
 * so caller can free what it has). */
static gz_err_t ensure_cap(unsigned char **buf, size_t *cap,
                           size_t used, size_t need) {
    size_t want;
    unsigned char *p;
    if (used + need <= *cap) return GZ_OK;
    want = *cap ? *cap : 4096;
    while (want < used + need) {
        size_t doubled = want * 2;
        if (doubled <= want) return GZ_ERR_MEM;  /* overflow */
        want = doubled;
    }
    p = (unsigned char *)realloc(*buf, want);
    if (!p) return GZ_ERR_MEM;
    *buf = p;
    *cap = want;
    return GZ_OK;
}

gz_err_t gz_inflate(const unsigned char *in, size_t in_len,
                    const gz_options_t *opts,
                    unsigned char **out, size_t *out_cap, size_t *out_len) {
    z_stream z;
    int wbits;
    gz_err_t err = GZ_OK;
    int z_rc;
    size_t chunk;

    *out     = NULL;
    *out_cap = 0;
    *out_len = 0;

    chunk = (opts && opts->chunk_size) ? opts->chunk_size : GZ_DEFAULT_CHUNK;

    wbits = wbits_for_mode(opts ? opts->mode : GZ_MODE_AUTO, 0);
    if (wbits == -1) return GZ_ERR_OPT;

    memset(&z, 0, sizeof z);
    z.next_in  = (Bytef *)in;
    z.avail_in = (uInt)in_len;

    z_rc = inflateInit2(&z, wbits);
    if (z_rc != Z_OK) return GZ_ERR_INIT;

    /* Empty input: decompress to empty output. zlib will return
     * Z_BUF_ERROR if asked to inflate zero bytes; treat as a successful
     * empty round-trip when input was also empty. */
    if (in_len == 0) {
        inflateEnd(&z);
        *out = (unsigned char *)malloc(1);
        if (!*out) return GZ_ERR_MEM;
        *out_cap = 1;
        *out_len = 0;
        return GZ_OK;
    }

    for (;;) {
        err = ensure_cap(out, out_cap, *out_len, chunk);
        if (err != GZ_OK) goto fail;

        z.next_out  = *out + *out_len;
        z.avail_out = (uInt)chunk;

        z_rc = inflate(&z, Z_NO_FLUSH);

        *out_len += chunk - z.avail_out;

        if (z_rc == Z_STREAM_END) break;
        if (z_rc == Z_BUF_ERROR && z.avail_in == 0) {
            err = GZ_ERR_TRUNCATED;
            goto fail;
        }
        if (z_rc != Z_OK) {
            err = map_z_err(z_rc);
            goto fail;
        }
        /* Z_OK with avail_out == 0 means the chunk was full mid-stream;
         * loop and grow. avail_out > 0 with Z_OK means zlib produced
         * less than chunk and wants more input — but we fed it all the
         * input we have, so an avail_in == 0 case there means the
         * stream is truncated. */
        if (z.avail_in == 0 && z.avail_out > 0) {
            err = GZ_ERR_TRUNCATED;
            goto fail;
        }
    }

    inflateEnd(&z);
    return GZ_OK;

fail:
    inflateEnd(&z);
    free(*out);
    *out = NULL;
    *out_cap = 0;
    *out_len = 0;
    return err;
}

gz_err_t gz_deflate(const unsigned char *in, size_t in_len,
                    const gz_options_t *opts,
                    unsigned char **out, size_t *out_cap, size_t *out_len) {
    z_stream z;
    int wbits, level, mem_level, strategy;
    gz_err_t err = GZ_OK;
    int z_rc;
    size_t chunk;

    *out     = NULL;
    *out_cap = 0;
    *out_len = 0;

    if (!opts) return GZ_ERR_OPT;

    chunk     = opts->chunk_size ? opts->chunk_size : GZ_DEFAULT_CHUNK;
    level     = opts->level;
    mem_level = opts->mem_level;
    strategy  = opts->strategy;

    if (level < 0 || level > 9)         return GZ_ERR_OPT;
    if (mem_level < 1 || mem_level > 9) return GZ_ERR_OPT;
    if (opts->mode == GZ_MODE_AUTO)     return GZ_ERR_OPT;

    wbits = wbits_for_mode(opts->mode, 1);
    if (wbits == -1) return GZ_ERR_OPT;

    memset(&z, 0, sizeof z);
    z.next_in  = (Bytef *)in;
    z.avail_in = (uInt)in_len;

    z_rc = deflateInit2(&z, level, Z_DEFLATED, wbits, mem_level, strategy);
    if (z_rc != Z_OK) return GZ_ERR_INIT;

    for (;;) {
        err = ensure_cap(out, out_cap, *out_len, chunk);
        if (err != GZ_OK) goto fail;

        z.next_out  = *out + *out_len;
        z.avail_out = (uInt)chunk;

        z_rc = deflate(&z, Z_FINISH);

        *out_len += chunk - z.avail_out;

        if (z_rc == Z_STREAM_END) break;
        if (z_rc == Z_OK)         continue;     /* needs more output room */
        if (z_rc == Z_BUF_ERROR && z.avail_out == 0) continue;
        err = map_z_err(z_rc);
        goto fail;
    }

    deflateEnd(&z);
    return GZ_OK;

fail:
    deflateEnd(&z);
    free(*out);
    *out = NULL;
    *out_cap = 0;
    *out_len = 0;
    return err;
}
