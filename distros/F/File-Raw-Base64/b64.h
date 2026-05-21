/*
 * b64.h - Base64 codec core for File::Raw::Base64.
 *
 * Plain C99, no Perl dependency. The XS layer (Base64.xs) populates a
 * b64_options_t from the per-call options HV and calls one of these
 * two functions on the input bytes.
 */

#ifndef B64_H
#define B64_H

#include <stddef.h>

typedef struct {
    /* Standard alphabet (0) or URL-safe (1). */
    int urlsafe;
    /* Encode: 0 = no wrap, N>0 = insert eol after every N output chars.
     * Decode: ignored. */
    int wrap;
    /* Encode: 1 = pad with '=' (RFC 4648 default). 0 = strip trailing
     * padding. Decode: always tolerant (missing padding accepted). */
    int padding;
    /* PEM mode. Encode: wrap output in "-----BEGIN $label-----" /
     * "-----END $label-----" lines. Decode: strip the envelope before
     * decoding. */
    int pem;
    /* Encode-only: label used for PEM headers when pem == 1.
     * NUL-terminated; must outlive the call. */
    const char *pem_label;
    /* Encode: line terminator when wrap > 0 or pem == 1. NUL-terminated.
     * One or two bytes ("\n" or "\r\n"). */
    const char *eol;
    /* Decode: 1 = reject any byte outside the active alphabet.
     * 0 (default) = silently skip whitespace and stray non-alphabet
     * bytes, matching MIME::Base64. */
    int strict;
} b64_options_t;

/* Error codes. Negative => failure; the XS layer maps these to croak()
 * messages with the offending byte offset where applicable. */
typedef enum {
    B64_OK              =  0,
    B64_ERR_NOMEM       = -1,
    B64_ERR_BAD_BYTE    = -2,  /* strict mode: non-alphabet byte */
    B64_ERR_TRUNCATED   = -3,  /* input ended mid-quartet */
    B64_ERR_PEM_NO_BEGIN = -4,
    B64_ERR_PEM_NO_END   = -5,
    B64_ERR_PEM_LABEL    = -6  /* BEGIN/END labels disagree */
} b64_err_t;

/* Initialise an options struct with sane defaults
 * (alphabet=standard, wrap=0, padding=1, pem=0, label="DATA",
 *  eol="\n", strict=0). */
void b64_options_init(b64_options_t *opts);

/* Encode `in_len` bytes from `in` to base64 text. Result is appended
 * to `*out`/`*out_cap`/`*out_len`: caller passes pointers to a writable
 * buffer pointer, capacity, and length; the function realloc()s as
 * needed and updates them. On entry *out_len is added to (encode is
 * happy to append). On failure *out / *out_cap may have been realloc'd
 * but *out_len is unchanged.
 *
 * Returns 0 on success, negative b64_err_t on failure. err_offset (if
 * non-NULL) is set to the byte offset within `in` where the error was
 * detected (always 0 for encode). */
int b64_encode(const unsigned char *in, size_t in_len,
               const b64_options_t *opts,
               char **out, size_t *out_cap, size_t *out_len,
               size_t *err_offset);

/* Decode base64 text from `in` to bytes. Same out-buffer convention as
 * encode. */
int b64_decode(const char *in, size_t in_len,
               const b64_options_t *opts,
               unsigned char **out, size_t *out_cap, size_t *out_len,
               size_t *err_offset);

/* Get a human-readable description for an error code. */
const char *b64_strerror(int err);

#endif /* B64_H */
