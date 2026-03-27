#ifndef HORUS_PARSE_H
#define HORUS_PARSE_H

/*
 * horus_parse.h - Universal UUID parser: any format string -> 16-byte binary
 *
 * Auto-detects format from input length and content.
 */

#include <string.h>

/* Return values */
#define HORUS_PARSE_OK    1
#define HORUS_PARSE_ERROR 0

/*
 * Parse a UUID string of any supported format into a 16-byte binary buffer.
 * Returns HORUS_PARSE_OK on success, HORUS_PARSE_ERROR on failure.
 */
static inline int horus_parse_uuid(unsigned char *out,
                                    const char *input, size_t len) {
    /* Raw binary: 16 bytes */
    if (len == 16) {
        memcpy(out, input, 16);
        return HORUS_PARSE_OK;
    }

    /* Base64: 22 chars */
    if (len == 22) {
        int n = horus_base64_decode(out, input, 22);
        return (n >= 16) ? HORUS_PARSE_OK : HORUS_PARSE_ERROR;
    }

    /* Base32: 26 chars */
    if (len == 26) {
        /* Detect Crockford vs RFC 4648 by checking for Crockford-only chars
         * Crockford uses 0-9A-Z minus I,L,O,U
         * RFC 4648 uses A-Z2-7
         * If we see any of 0,1,8,9 it's Crockford; if we see any of a-z
         * we try both with standard first */
        int has_digit_019 = 0;
        int i;
        for (i = 0; i < 26; i++) {
            char c = input[i];
            if (c == '8' || c == '9' || c == '0' || c == '1') {
                has_digit_019 = 1;
                break;
            }
        }
        if (has_digit_019) {
            int n = horus_crockford_decode(out, input, 26);
            return (n >= 16) ? HORUS_PARSE_OK : HORUS_PARSE_ERROR;
        } else {
            int n = horus_base32_decode(out, input, 26);
            return (n >= 16) ? HORUS_PARSE_OK : HORUS_PARSE_ERROR;
        }
    }

    /* No hyphens hex: 32 chars */
    if (len == 32) {
        return horus_hex_decode(out, input, 32) ? HORUS_PARSE_OK : HORUS_PARSE_ERROR;
    }

    /* Standard hyphenated: 36 chars (8-4-4-4-12) */
    if (len == 36 && input[8] == '-' && input[13] == '-'
                  && input[18] == '-' && input[23] == '-') {
        char hex[32];
        memcpy(hex,      input,      8);  /* time_low */
        memcpy(hex + 8,  input + 9,  4);  /* time_mid */
        memcpy(hex + 12, input + 14, 4);  /* time_hi */
        memcpy(hex + 16, input + 19, 4);  /* clock_seq */
        memcpy(hex + 20, input + 24, 12); /* node */
        return horus_hex_decode(out, hex, 32) ? HORUS_PARSE_OK : HORUS_PARSE_ERROR;
    }

    /* Braces: 38 chars {8-4-4-4-12} */
    if (len == 38 && input[0] == '{' && input[37] == '}') {
        return horus_parse_uuid(out, input + 1, 36);
    }

    /* URN: 45 chars urn:uuid:8-4-4-4-12 */
    if (len >= 45 && memcmp(input, "urn:uuid:", 9) == 0) {
        return horus_parse_uuid(out, input + 9, len - 9);
    }

    return HORUS_PARSE_ERROR;
}

#endif /* HORUS_PARSE_H */
