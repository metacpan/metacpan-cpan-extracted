#include <panda/encode/base32.h>

namespace panda { namespace encode {

static const int XX = 255; /* illegal char */

#define REV32(x) index32[(int)(x)]

static const char basis32[]   = "abcdefghijklmnopqrstuvwxyz234567";
static const char basis32up[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";
static const unsigned char index32[256] = {
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,26,27, 28,29,30,31, XX,XX,XX,XX, XX,XX,XX,XX,
    XX, 0, 1, 2,  3, 4, 5, 6,  7, 8, 9,10, 11,12,13,14,
    15,16,17,18, 19,20,21,22, 23,24,25,XX, XX,XX,XX,XX,
    XX, 0, 1, 2,  3, 4, 5, 6,  7, 8, 9,10, 11,12,13,14,
    15,16,17,18, 19,20,21,22, 23,24,25,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX
};

size_t encode_base32 (const string_view source, char* dest, bool upper) {
    const char* const basis = upper ? basis32up : basis32;
    const unsigned char* str = (unsigned char*)source.data();
    const unsigned char* const end = str + source.length();
    char* ptr = dest;

    while (1) {
        if (str == end) break;
        *ptr++ = basis[(*str & 0xf8) >> 3];

        if (str == end) {
            ptr--; /* previous char is useless */
            break;
        }
        *ptr++ = basis[((*str & 0x07) << 2) | ((str + 1 != end) ? ((*(str+1) & 0xc0) >> 6) : 0)];
        str++; /* 0 complete, iin=1 */

        if (str == end) break;
        *ptr++ = basis[(*str & 0x3e) >> 1];

        if (str == end) {
            ptr--; /* previous char is useless */
            break;
        }
        *ptr++ = basis[((*str & 0x01) << 4) | ((str + 1 != end) ? ((*(str+1) & 0xf0) >> 4) : 0)];
        str++; /* 1 complete, iin=2 */

        if (str == end) break;
        *ptr++ = basis[((*str & 0x0f) << 1) | ((str + 1 != end) ? ((*(str+1) & 0x80) >> 7) : 0)];
        str++; /* 2 complete, iin=3 */

        if (str == end) break;
        *ptr++ = basis[(*str & 0x7c) >> 2];

        if (str == end) {
            ptr--; /* previous char is useless */
            break;
        }
        *ptr++ = basis[((*str & 0x03) << 3) | ((str + 1 != end) ? ((*(str+1) & 0xe0) >> 5) : 0)];
        str++; /* 3 complete, iin=4 */

        if (str == end) break;
        *ptr++ = basis[*str & 0x1f];
        str++; /* 4 complete, iin=5 */
    }

    return ptr - dest;
}

size_t decode_base32 (const string_view source, char* dest) {
    const char* str = source.data();
    const char* const end = str + source.length();
    unsigned char* ptr = (unsigned char*)dest;

    while (1) {
        if (str+1 >= end || *str == 0 || str[1] == 0) break;
        *ptr++ = ((REV32(*str) & 0x1f) << 3) | ((REV32(str[1]) & 0x1c) >> 2);
        ++str;

        if (str+2 >= end || str[1] == 0 || str[2] == 0) break;
        *ptr++ = ((REV32(*str) & 0x03) << 6) | ((REV32(str[1]) & 0x1f) << 1) | ((REV32(str[2]) & 0x10) >> 4);
        str += 2;

        if (str+1 == end || str[1] == 0) break;
        *ptr++ = ((REV32(*str) & 0x0f) << 4) | ((REV32(str[1]) & 0x1e) >> 1);
        ++str;

        if (str+2 >= end || str[1] == 0 || str[2] == 0) break;
        *ptr++ = ((REV32(*str) & 0x01) << 7) | ((REV32(str[1]) & 0x1f) << 2) | ((REV32(str[2]) & 0x18) >> 3);
        str += 2;

        if (str+1 == end || str[1] == 0) break;
        *ptr++ = ((REV32(*str) & 0x07) << 5) | ((REV32(str[1]) & 0x1f));
        str += 2;
    }

    return (char*)ptr - dest;
}

}}
