#include <panda/encode/base64.h>
#include <cstdint>

namespace panda { namespace encode {

using std::int64_t;

static const int EQ = 254; /* padding */
static const int XX = 255; /* illegal char */
static const int INVALID = XX;

static const char basis64[]    = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
static const char basis64url[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";
static const unsigned char index64[256] = {
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,62, XX,62,XX,63,
    52,53,54,55, 56,57,58,59, 60,61,XX,XX, XX,EQ,XX,XX,
    XX, 0, 1, 2,  3, 4, 5, 6,  7, 8, 9,10, 11,12,13,14,
    15,16,17,18, 19,20,21,22, 23,24,25,XX, XX,XX,XX,63,
    XX,26,27,28, 29,30,31,32, 33,34,35,36, 37,38,39,40,
    41,42,43,44, 45,46,47,48, 49,50,51,XX, XX,XX,XX,XX,

    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
};

size_t encode_base64 (const string_view source, char* dest, bool url_mode, bool use_pad) {
    char* ptr = dest;
    const char* basis = url_mode ? basis64url : basis64;
    const char* str = source.data();

    for (int64_t len = source.length(); len > 0; len -= 3) {
        unsigned char c1 = *str++;
        unsigned char c2 = len > 1 ? *str++ : '\0';
        *ptr++ = basis[c1>>2];
        *ptr++ = basis[((c1 & 0x3)<< 4) | ((c2 & 0xF0) >> 4)];
        if (len > 2) {
            unsigned char c3 = *str++;
            *ptr++ = basis[((c2 & 0xF) << 2) | ((c3 & 0xC0) >>6)];
            *ptr++ = basis[c3 & 0x3F];
        } else if (len == 2) {
            *ptr++ = basis[(c2 & 0xF) << 2];
            if (use_pad) *ptr++ = '=';
        } else if (use_pad) {
            *ptr++ = '=';
            *ptr++ = '=';
        }
    }
    return ptr - dest;
}

size_t decode_base64 (const string_view source, char* dest) {
    const unsigned char* str = (const unsigned char*)source.data();
    const unsigned char* const end = str + source.length();
    char* ptr = dest;

    while (str < end) {
        unsigned char c[4];
        int i = 0;
        do {
            unsigned char uc = index64[*str++];
            if (uc != INVALID) c[i++] = uc;
            if (str == end) {
                if (i < 4) {
                    if (i < 2) goto thats_it;
                    if (i == 2) c[2] = EQ;
                    c[3] = EQ;
                }
                break;
            }
        } while (i < 4);

        if (c[0] == EQ || c[1] == EQ) break;
        *ptr++ = (c[0] << 2) | ((c[1] & 0x30) >> 4);
        if (c[2] == EQ) break;
        *ptr++ = ((c[1] & 0x0F) << 4) | ((c[2] & 0x3C) >> 2);
        if (c[3] == EQ) break;
        *ptr++ = ((c[2] & 0x03) << 6) | c[3];
    }

    thats_it:
    return ptr - dest;
}

}}
