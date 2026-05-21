/*
 * gz.h - C wrappers around zlib's inflate / deflate.
 *
 * No Perl dependency in the codec layer; the XS shim translates between
 * Perl SVs and these calls. Both functions accept a caller-owned
 * `gz_options_t` and write their output into a freshly-allocated buffer
 * the caller is responsible for freeing.
 */

#ifndef GZ_H
#define GZ_H

#include <stddef.h>

/* Result codes. Negative on error so the XS layer can distinguish via
 * a single sign check. */
typedef enum {
    GZ_OK             =  0,
    GZ_ERR_INIT       = -1,  /* inflateInit2 / deflateInit2 failed       */
    GZ_ERR_DATA       = -2,  /* corrupt input stream                     */
    GZ_ERR_NEED_DICT  = -3,  /* preset dictionary required (unsupported) */
    GZ_ERR_MEM        = -4,  /* out of memory                            */
    GZ_ERR_BUF        = -5,  /* buffer error                             */
    GZ_ERR_VERSION    = -6,  /* zlib version mismatch                    */
    GZ_ERR_OPT        = -7,  /* invalid option in gz_options_t           */
    GZ_ERR_TRUNCATED  = -8   /* stream ended before Z_STREAM_END         */
} gz_err_t;

/* Encoded mode -> wbits mapping. The codec layer translates to zlib's
 * raw integer; the XS layer accepts the string forms. */
typedef enum {
    GZ_MODE_GZIP   = 0,  /* wbits = 31 (MAX_WBITS | 16): gzip wrap        */
    GZ_MODE_ZLIB   = 1,  /* wbits = 15 (MAX_WBITS): zlib wrap (RFC 1950)  */
    GZ_MODE_RAW    = 2,  /* wbits = -15: raw deflate (RFC 1951)           */
    GZ_MODE_AUTO   = 3   /* decode-only: wbits = 47 (MAX_WBITS | 32)      */
} gz_mode_t;

typedef struct {
    int       level;       /* 0..9, encode-only.                          */
    gz_mode_t mode;        /* see table above.                            */
    size_t    chunk_size;  /* output buffer growth chunk in bytes.        */
    int       strategy;    /* zlib Z_DEFAULT_STRATEGY / Z_FILTERED / ...  */
    int       mem_level;   /* 1..9, encode-only.                          */
} gz_options_t;

/* Default-initialise. mode = GZ_MODE_AUTO (a decode-friendly default;
 * encoders should set GZ_MODE_GZIP explicitly). */
void gz_options_init(gz_options_t *opts);

/* Inflate `in` (length `in_len`) to `*out`. Allocates `*out` via malloc;
 * caller frees on every return path. `*out_len` set to the produced
 * length, `*out_cap` to the allocation size.
 *
 * `mode = GZ_MODE_AUTO` lets zlib detect gzip vs zlib headers. */
gz_err_t gz_inflate(const unsigned char *in, size_t in_len,
                    const gz_options_t *opts,
                    unsigned char **out, size_t *out_cap, size_t *out_len);

/* Deflate `in` to `*out`. Same allocation contract as gz_inflate.
 * `mode = GZ_MODE_AUTO` is rejected (encoder needs an explicit format). */
gz_err_t gz_deflate(const unsigned char *in, size_t in_len,
                    const gz_options_t *opts,
                    unsigned char **out, size_t *out_cap, size_t *out_len);

/* Human-readable error string for a gz_err_t code. */
const char *gz_strerror(gz_err_t err);

#endif /* GZ_H */
