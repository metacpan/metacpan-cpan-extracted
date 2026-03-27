#ifndef HORUS_ENCODE_H
#define HORUS_ENCODE_H

/*
 * horus_encode.h - High-performance encoding: hex, Base64, Base32, Crockford
 *
 * Hex uses a uint16_t lookup table: one table lookup per byte produces
 * two hex characters. ~4x faster than sprintf("%02x").
 */

#include <stdint.h>
#include <string.h>

/* ── Hex lookup tables (compile-time initialised) ───────────────── */

#define HEX_PAIR(hi, lo)  (uint16_t)( ((uint16_t)(lo) << 8) | (uint16_t)(hi) )

/* Helper macro to generate 16 entries for a given high nibble */
#define HEX_ROW(h, H) \
    HEX_PAIR(h,'0'), HEX_PAIR(h,'1'), HEX_PAIR(h,'2'), HEX_PAIR(h,'3'), \
    HEX_PAIR(h,'4'), HEX_PAIR(h,'5'), HEX_PAIR(h,'6'), HEX_PAIR(h,'7'), \
    HEX_PAIR(h,'8'), HEX_PAIR(h,'9'), HEX_PAIR(h,'a'), HEX_PAIR(h,'b'), \
    HEX_PAIR(h,'c'), HEX_PAIR(h,'d'), HEX_PAIR(h,'e'), HEX_PAIR(h,'f')

#define HEX_ROW_UPPER(h, H) \
    HEX_PAIR(h,'0'), HEX_PAIR(h,'1'), HEX_PAIR(h,'2'), HEX_PAIR(h,'3'), \
    HEX_PAIR(h,'4'), HEX_PAIR(h,'5'), HEX_PAIR(h,'6'), HEX_PAIR(h,'7'), \
    HEX_PAIR(h,'8'), HEX_PAIR(h,'9'), HEX_PAIR(h,'A'), HEX_PAIR(h,'B'), \
    HEX_PAIR(h,'C'), HEX_PAIR(h,'D'), HEX_PAIR(h,'E'), HEX_PAIR(h,'F')

static const uint16_t horus_hex_lut[256] = {
    HEX_ROW('0', '0'), HEX_ROW('1', '1'), HEX_ROW('2', '2'), HEX_ROW('3', '3'),
    HEX_ROW('4', '4'), HEX_ROW('5', '5'), HEX_ROW('6', '6'), HEX_ROW('7', '7'),
    HEX_ROW('8', '8'), HEX_ROW('9', '9'), HEX_ROW('a', 'a'), HEX_ROW('b', 'b'),
    HEX_ROW('c', 'c'), HEX_ROW('d', 'd'), HEX_ROW('e', 'e'), HEX_ROW('f', 'f')
};

static const uint16_t horus_hex_lut_upper[256] = {
    HEX_ROW_UPPER('0', '0'), HEX_ROW_UPPER('1', '1'), HEX_ROW_UPPER('2', '2'), HEX_ROW_UPPER('3', '3'),
    HEX_ROW_UPPER('4', '4'), HEX_ROW_UPPER('5', '5'), HEX_ROW_UPPER('6', '6'), HEX_ROW_UPPER('7', '7'),
    HEX_ROW_UPPER('8', '8'), HEX_ROW_UPPER('9', '9'), HEX_ROW_UPPER('A', 'A'), HEX_ROW_UPPER('B', 'B'),
    HEX_ROW_UPPER('C', 'C'), HEX_ROW_UPPER('D', 'D'), HEX_ROW_UPPER('E', 'E'), HEX_ROW_UPPER('F', 'F')
};

/* Write two hex chars for one byte */
static inline void horus_hex_byte(char *dst, unsigned char b, const uint16_t *lut) {
    memcpy(dst, &lut[b], 2);
}

/* Encode 16 bytes to 32 hex chars */
static inline void horus_hex_encode(char *dst, const unsigned char *src, const uint16_t *lut) {
    int i;
    for (i = 0; i < 16; i++) {
        horus_hex_byte(dst + i * 2, src[i], lut);
    }
}

/* ── Hex decode ─────────────────────────────────────────────────── */

static const unsigned char horus_hex_val[256] = {
    ['0'] = 0,  ['1'] = 1,  ['2'] = 2,  ['3'] = 3,
    ['4'] = 4,  ['5'] = 5,  ['6'] = 6,  ['7'] = 7,
    ['8'] = 8,  ['9'] = 9,
    ['a'] = 10, ['b'] = 11, ['c'] = 12, ['d'] = 13, ['e'] = 14, ['f'] = 15,
    ['A'] = 10, ['B'] = 11, ['C'] = 12, ['D'] = 13, ['E'] = 14, ['F'] = 15,
};

static inline int horus_is_hex(char c) {
    return (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F');
}

static inline int horus_hex_decode(unsigned char *dst, const char *src, int nhex) {
    int i;
    for (i = 0; i < nhex; i += 2) {
        if (!horus_is_hex(src[i]) || !horus_is_hex(src[i+1]))
            return 0;
        dst[i/2] = (horus_hex_val[(unsigned char)src[i]] << 4)
                  | horus_hex_val[(unsigned char)src[i+1]];
    }
    return 1;
}

/* ── Base64 encoding (no padding, 22 chars for 16 bytes) ────────── */

static const char horus_b64_alphabet[] =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

static inline void horus_base64_encode(char *dst, const unsigned char *src) {
    int i, j = 0;
    /* Process 3 bytes at a time -> 4 base64 chars */
    for (i = 0; i + 2 < 16; i += 3) {
        unsigned int v = ((unsigned int)src[i] << 16)
                       | ((unsigned int)src[i+1] << 8)
                       | (unsigned int)src[i+2];
        dst[j++] = horus_b64_alphabet[(v >> 18) & 0x3F];
        dst[j++] = horus_b64_alphabet[(v >> 12) & 0x3F];
        dst[j++] = horus_b64_alphabet[(v >> 6)  & 0x3F];
        dst[j++] = horus_b64_alphabet[v & 0x3F];
    }
    /* Last byte (16 % 3 = 1 remaining byte) */
    {
        unsigned int v = (unsigned int)src[15] << 16;
        dst[j++] = horus_b64_alphabet[(v >> 18) & 0x3F];
        dst[j++] = horus_b64_alphabet[(v >> 12) & 0x3F];
    }
    /* j == 22 */
}

/* ── Base64 decoding ────────────────────────────────────────────── */

static const unsigned char horus_b64_decode_table[256] = {
    ['A'] = 0,  ['B'] = 1,  ['C'] = 2,  ['D'] = 3,  ['E'] = 4,  ['F'] = 5,
    ['G'] = 6,  ['H'] = 7,  ['I'] = 8,  ['J'] = 9,  ['K'] = 10, ['L'] = 11,
    ['M'] = 12, ['N'] = 13, ['O'] = 14, ['P'] = 15, ['Q'] = 16, ['R'] = 17,
    ['S'] = 18, ['T'] = 19, ['U'] = 20, ['V'] = 21, ['W'] = 22, ['X'] = 23,
    ['Y'] = 24, ['Z'] = 25,
    ['a'] = 26, ['b'] = 27, ['c'] = 28, ['d'] = 29, ['e'] = 30, ['f'] = 31,
    ['g'] = 32, ['h'] = 33, ['i'] = 34, ['j'] = 35, ['k'] = 36, ['l'] = 37,
    ['m'] = 38, ['n'] = 39, ['o'] = 40, ['p'] = 41, ['q'] = 42, ['r'] = 43,
    ['s'] = 44, ['t'] = 45, ['u'] = 46, ['v'] = 47, ['w'] = 48, ['x'] = 49,
    ['y'] = 50, ['z'] = 51,
    ['0'] = 52, ['1'] = 53, ['2'] = 54, ['3'] = 55, ['4'] = 56, ['5'] = 57,
    ['6'] = 58, ['7'] = 59, ['8'] = 60, ['9'] = 61, ['+'] = 62, ['/'] = 63,
};

static inline int horus_base64_decode(unsigned char *dst, const char *src, int len) {
    int i, j = 0;
    /* Process 4 chars at a time -> 3 bytes */
    for (i = 0; i + 3 < len; i += 4) {
        unsigned int v = ((unsigned int)horus_b64_decode_table[(unsigned char)src[i]] << 18)
                       | ((unsigned int)horus_b64_decode_table[(unsigned char)src[i+1]] << 12)
                       | ((unsigned int)horus_b64_decode_table[(unsigned char)src[i+2]] << 6)
                       | (unsigned int)horus_b64_decode_table[(unsigned char)src[i+3]];
        dst[j++] = (unsigned char)(v >> 16);
        dst[j++] = (unsigned char)(v >> 8);
        dst[j++] = (unsigned char)(v);
    }
    /* Last 2 chars -> 1 byte (22 chars: 5 groups of 4 + 2 remaining) */
    if (i + 1 < len) {
        unsigned int v = ((unsigned int)horus_b64_decode_table[(unsigned char)src[i]] << 18)
                       | ((unsigned int)horus_b64_decode_table[(unsigned char)src[i+1]] << 12);
        dst[j++] = (unsigned char)(v >> 16);
    }
    return j;
}

/* ── Base32 encoding (RFC 4648, 26 chars for 16 bytes) ──────────── */

static const char horus_b32_alphabet[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";

static inline void horus_base32_encode(char *dst, const unsigned char *src) {
    /* 16 bytes = 128 bits. 128 / 5 = 25 full groups + 3 bits.
     * With padding that's 26 chars (last char encodes 3 bits, padded). */
    int i, bit_pos = 0, byte_pos = 0, j = 0;
    for (i = 0; i < 26; i++) {
        int val = 0;
        int bits_needed = 5;
        int bits_have = 0;

        while (bits_have < bits_needed && byte_pos < 16) {
            int bits_left_in_byte = 8 - bit_pos;
            int bits_to_take = bits_needed - bits_have;
            if (bits_to_take > bits_left_in_byte)
                bits_to_take = bits_left_in_byte;

            val = (val << bits_to_take) | ((src[byte_pos] >> (bits_left_in_byte - bits_to_take)) & ((1 << bits_to_take) - 1));
            bits_have += bits_to_take;
            bit_pos += bits_to_take;
            if (bit_pos >= 8) {
                bit_pos = 0;
                byte_pos++;
            }
        }
        /* Pad remaining bits with zero if we ran out of data */
        if (bits_have < bits_needed) {
            val <<= (bits_needed - bits_have);
        }
        dst[j++] = horus_b32_alphabet[val & 0x1F];
    }
}

/* ── Base32 decoding ────────────────────────────────────────────── */

static const unsigned char horus_b32_decode_table[256] = {
    ['A'] = 0,  ['B'] = 1,  ['C'] = 2,  ['D'] = 3,  ['E'] = 4,
    ['F'] = 5,  ['G'] = 6,  ['H'] = 7,  ['I'] = 8,  ['J'] = 9,
    ['K'] = 10, ['L'] = 11, ['M'] = 12, ['N'] = 13, ['O'] = 14,
    ['P'] = 15, ['Q'] = 16, ['R'] = 17, ['S'] = 18, ['T'] = 19,
    ['U'] = 20, ['V'] = 21, ['W'] = 22, ['X'] = 23, ['Y'] = 24,
    ['Z'] = 25,
    ['2'] = 26, ['3'] = 27, ['4'] = 28, ['5'] = 29, ['6'] = 30, ['7'] = 31,
    /* lowercase aliases */
    ['a'] = 0,  ['b'] = 1,  ['c'] = 2,  ['d'] = 3,  ['e'] = 4,
    ['f'] = 5,  ['g'] = 6,  ['h'] = 7,  ['i'] = 8,  ['j'] = 9,
    ['k'] = 10, ['l'] = 11, ['m'] = 12, ['n'] = 13, ['o'] = 14,
    ['p'] = 15, ['q'] = 16, ['r'] = 17, ['s'] = 18, ['t'] = 19,
    ['u'] = 20, ['v'] = 21, ['w'] = 22, ['x'] = 23, ['y'] = 24,
    ['z'] = 25,
};

static inline int horus_base32_decode(unsigned char *dst, const char *src, int len) {
    int i, bit_pos = 0, byte_pos = 0;
    memset(dst, 0, 16);
    for (i = 0; i < len && byte_pos < 16; i++) {
        unsigned char val = horus_b32_decode_table[(unsigned char)src[i]];
        int bits_left = 5;
        while (bits_left > 0 && byte_pos < 16) {
            int space = 8 - bit_pos;
            if (bits_left >= space) {
                dst[byte_pos] |= (val >> (bits_left - space)) & ((1 << space) - 1);
                bits_left -= space;
                bit_pos = 0;
                byte_pos++;
            } else {
                dst[byte_pos] |= (val & ((1 << bits_left) - 1)) << (space - bits_left);
                bit_pos += bits_left;
                bits_left = 0;
            }
        }
    }
    return byte_pos;
}

/* ── Crockford Base32 encoding (26 chars for 16 bytes) ──────────── */

static const char horus_crockford_alphabet[] = "0123456789ABCDEFGHJKMNPQRSTVWXYZ";

static inline void horus_crockford_encode(char *dst, const unsigned char *src) {
    int i, bit_pos = 0, byte_pos = 0, j = 0;
    for (i = 0; i < 26; i++) {
        int val = 0;
        int bits_needed = 5;
        int bits_have = 0;

        while (bits_have < bits_needed && byte_pos < 16) {
            int bits_left_in_byte = 8 - bit_pos;
            int bits_to_take = bits_needed - bits_have;
            if (bits_to_take > bits_left_in_byte)
                bits_to_take = bits_left_in_byte;

            val = (val << bits_to_take) | ((src[byte_pos] >> (bits_left_in_byte - bits_to_take)) & ((1 << bits_to_take) - 1));
            bits_have += bits_to_take;
            bit_pos += bits_to_take;
            if (bit_pos >= 8) {
                bit_pos = 0;
                byte_pos++;
            }
        }
        if (bits_have < bits_needed) {
            val <<= (bits_needed - bits_have);
        }
        dst[j++] = horus_crockford_alphabet[val & 0x1F];
    }
}

/* ── Crockford Base32 decoding ──────────────────────────────────── */

static const unsigned char horus_crockford_decode_table[256] = {
    ['0'] = 0,  ['O'] = 0,  ['o'] = 0,
    ['1'] = 1,  ['I'] = 1,  ['i'] = 1,  ['L'] = 1,  ['l'] = 1,
    ['2'] = 2,  ['3'] = 3,  ['4'] = 4,  ['5'] = 5,  ['6'] = 6,
    ['7'] = 7,  ['8'] = 8,  ['9'] = 9,
    ['A'] = 10, ['a'] = 10,
    ['B'] = 11, ['b'] = 11,
    ['C'] = 12, ['c'] = 12,
    ['D'] = 13, ['d'] = 13,
    ['E'] = 14, ['e'] = 14,
    ['F'] = 15, ['f'] = 15,
    ['G'] = 16, ['g'] = 16,
    ['H'] = 17, ['h'] = 17,
    ['J'] = 18, ['j'] = 18,
    ['K'] = 19, ['k'] = 19,
    ['M'] = 20, ['m'] = 20,
    ['N'] = 21, ['n'] = 21,
    ['P'] = 22, ['p'] = 22,
    ['Q'] = 23, ['q'] = 23,
    ['R'] = 24, ['r'] = 24,
    ['S'] = 25, ['s'] = 25,
    ['T'] = 26, ['t'] = 26,
    ['V'] = 27, ['v'] = 27,
    ['W'] = 28, ['w'] = 28,
    ['X'] = 29, ['x'] = 29,
    ['Y'] = 30, ['y'] = 30,
    ['Z'] = 31, ['z'] = 31,
};

static inline int horus_crockford_decode(unsigned char *dst, const char *src, int len) {
    int i, bit_pos = 0, byte_pos = 0;
    memset(dst, 0, 16);
    for (i = 0; i < len && byte_pos < 16; i++) {
        unsigned char val = horus_crockford_decode_table[(unsigned char)src[i]];
        int bits_left = 5;
        while (bits_left > 0 && byte_pos < 16) {
            int space = 8 - bit_pos;
            if (bits_left >= space) {
                dst[byte_pos] |= (val >> (bits_left - space)) & ((1 << space) - 1);
                bits_left -= space;
                bit_pos = 0;
                byte_pos++;
            } else {
                dst[byte_pos] |= (val & ((1 << bits_left) - 1)) << (space - bits_left);
                bit_pos += bits_left;
                bits_left = 0;
            }
        }
    }
    return byte_pos;
}

#endif /* HORUS_ENCODE_H */
