#ifndef HORUS_FORMAT_H
#define HORUS_FORMAT_H

/*
 * horus_format.h - Format 16-byte UUID binary into output strings
 *
 * All formatters write into a pre-sized buffer. Caller is responsible
 * for allocating enough space (use HORUS_FMT_*_LEN constants).
 */

#include "horus_encode.h"

/* Output lengths (excluding NUL terminator) */
#define HORUS_FMT_STR_LEN       36
#define HORUS_FMT_HEX_LEN       32
#define HORUS_FMT_BRACES_LEN    38
#define HORUS_FMT_URN_LEN       45
#define HORUS_FMT_BASE64_LEN    22
#define HORUS_FMT_BASE32_LEN    26
#define HORUS_FMT_CROCKFORD_LEN 26
#define HORUS_FMT_BINARY_LEN    16

/* Format enum */
typedef enum {
    HORUS_FMT_STR       = 0,  /* 550e8400-e29b-41d4-a716-446655440000 */
    HORUS_FMT_HEX       = 1,  /* 550e8400e29b41d4a716446655440000 */
    HORUS_FMT_BRACES    = 2,  /* {550e8400-e29b-41d4-a716-446655440000} */
    HORUS_FMT_URN       = 3,  /* urn:uuid:550e8400-e29b-41d4-a716-446655440000 */
    HORUS_FMT_BASE64    = 4,  /* 22-char base64, no padding */
    HORUS_FMT_BASE32    = 5,  /* 26-char RFC 4648 */
    HORUS_FMT_CROCKFORD = 6,  /* 26-char Crockford base32 */
    HORUS_FMT_BINARY    = 7,  /* raw 16 bytes */
    HORUS_FMT_UPPER_STR = 8,  /* uppercase hyphenated */
    HORUS_FMT_UPPER_HEX = 9   /* uppercase no hyphens */
} horus_format_t;

/* ── Hyphenated format (8-4-4-4-12) ────────────────────────────── */

static inline void horus_format_hyphenated(char *dst, const unsigned char *uuid,
                                            const uint16_t *lut) {
    /* bytes 0-3 */
    horus_hex_byte(dst + 0,  uuid[0], lut);
    horus_hex_byte(dst + 2,  uuid[1], lut);
    horus_hex_byte(dst + 4,  uuid[2], lut);
    horus_hex_byte(dst + 6,  uuid[3], lut);
    dst[8] = '-';
    /* bytes 4-5 */
    horus_hex_byte(dst + 9,  uuid[4], lut);
    horus_hex_byte(dst + 11, uuid[5], lut);
    dst[13] = '-';
    /* bytes 6-7 */
    horus_hex_byte(dst + 14, uuid[6], lut);
    horus_hex_byte(dst + 16, uuid[7], lut);
    dst[18] = '-';
    /* bytes 8-9 */
    horus_hex_byte(dst + 19, uuid[8], lut);
    horus_hex_byte(dst + 21, uuid[9], lut);
    dst[23] = '-';
    /* bytes 10-15 */
    horus_hex_byte(dst + 24, uuid[10], lut);
    horus_hex_byte(dst + 26, uuid[11], lut);
    horus_hex_byte(dst + 28, uuid[12], lut);
    horus_hex_byte(dst + 30, uuid[13], lut);
    horus_hex_byte(dst + 32, uuid[14], lut);
    horus_hex_byte(dst + 34, uuid[15], lut);
}

/* ── Master format dispatch ─────────────────────────────────────── */

/* Returns the output length for a given format (excluding NUL) */
static inline int horus_format_length(horus_format_t fmt) {
    switch (fmt) {
        case HORUS_FMT_STR:       return HORUS_FMT_STR_LEN;
        case HORUS_FMT_HEX:       return HORUS_FMT_HEX_LEN;
        case HORUS_FMT_BRACES:    return HORUS_FMT_BRACES_LEN;
        case HORUS_FMT_URN:       return HORUS_FMT_URN_LEN;
        case HORUS_FMT_BASE64:    return HORUS_FMT_BASE64_LEN;
        case HORUS_FMT_BASE32:    return HORUS_FMT_BASE32_LEN;
        case HORUS_FMT_CROCKFORD: return HORUS_FMT_CROCKFORD_LEN;
        case HORUS_FMT_BINARY:    return HORUS_FMT_BINARY_LEN;
        case HORUS_FMT_UPPER_STR: return HORUS_FMT_STR_LEN;
        case HORUS_FMT_UPPER_HEX: return HORUS_FMT_HEX_LEN;
        default:                  return HORUS_FMT_STR_LEN;
    }
}

/* Format a 16-byte UUID into the given buffer. Returns bytes written. */
static inline int horus_format_uuid(char *dst, const unsigned char *uuid,
                                     horus_format_t fmt) {
    switch (fmt) {
        case HORUS_FMT_STR:
            horus_format_hyphenated(dst, uuid, horus_hex_lut);
            return HORUS_FMT_STR_LEN;

        case HORUS_FMT_UPPER_STR:
            horus_format_hyphenated(dst, uuid, horus_hex_lut_upper);
            return HORUS_FMT_STR_LEN;

        case HORUS_FMT_HEX:
            horus_hex_encode(dst, uuid, horus_hex_lut);
            return HORUS_FMT_HEX_LEN;

        case HORUS_FMT_UPPER_HEX:
            horus_hex_encode(dst, uuid, horus_hex_lut_upper);
            return HORUS_FMT_HEX_LEN;

        case HORUS_FMT_BRACES:
            dst[0] = '{';
            horus_format_hyphenated(dst + 1, uuid, horus_hex_lut);
            dst[37] = '}';
            return HORUS_FMT_BRACES_LEN;

        case HORUS_FMT_URN:
            memcpy(dst, "urn:uuid:", 9);
            horus_format_hyphenated(dst + 9, uuid, horus_hex_lut);
            return HORUS_FMT_URN_LEN;

        case HORUS_FMT_BASE64:
            horus_base64_encode(dst, uuid);
            return HORUS_FMT_BASE64_LEN;

        case HORUS_FMT_BASE32:
            horus_base32_encode(dst, uuid);
            return HORUS_FMT_BASE32_LEN;

        case HORUS_FMT_CROCKFORD:
            horus_crockford_encode(dst, uuid);
            return HORUS_FMT_CROCKFORD_LEN;

        case HORUS_FMT_BINARY:
            memcpy(dst, uuid, 16);
            return HORUS_FMT_BINARY_LEN;

        default:
            horus_format_hyphenated(dst, uuid, horus_hex_lut);
            return HORUS_FMT_STR_LEN;
    }
}

#endif /* HORUS_FORMAT_H */
