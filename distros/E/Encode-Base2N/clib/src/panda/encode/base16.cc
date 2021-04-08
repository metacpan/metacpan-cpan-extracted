#include <panda/encode/base16.h>

namespace panda { namespace encode {

static const int XX = 255; /* illegal char */

static const char basis16[]   = "0123456789abcdef";
static const char basis16up[] = "0123456789ABCDEF";
static const unsigned char index16[256] = {
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
     0, 1, 2, 3,  4, 5, 6, 7,  8, 9,XX,XX, XX,XX,XX,XX,
    XX,10,11,12, 13,14,15,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,10,11,12, 13,14,15,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX
};

size_t encode_base16 (const string_view source, char* dest, bool upper) {
    const char* basis = upper ? basis16up : basis16;
    unsigned const char* str = (unsigned const char*)source.data();
    unsigned const char* const end = str + source.length();
    char* ptr = dest;

    for (; str != end; ++str) {
        unsigned char c = *str;
        *ptr++ = basis[c / 16];
        *ptr++ = basis[c % 16];
    }

    return ptr - dest;
}

size_t decode_base16 (const string_view source, char* dest) {
    unsigned const char* str = (unsigned const char*)source.data();
    unsigned const char* const end = str + source.length();
    char* ptr = dest;

    while (str + 1 < end) {
        *ptr++ = index16[*str] * 16 + index16[str[1]];
        str += 2;
    }

    return ptr - dest;
}

}}
