#pragma once
#include <cstddef>
#include <panda/string.h>

namespace panda { namespace encode {

using std::size_t;

inline size_t encode_base16_getlen (size_t source_len) { return source_len*2; }
inline size_t decode_base16_getlen (size_t source_len) { return source_len/2; }

size_t encode_base16 (const string_view source, char* dest, bool upper = false);
size_t decode_base16 (const string_view source, char* dest);

inline string encode_base16 (const string_view source, bool upper = false) {
    string ret;
    char* buf = ret.reserve(encode_base16_getlen(source.length()));
    auto len = encode_base16(source, buf, upper);
    ret.length(len);
    return ret;
}

inline string decode_base16 (const string_view source) {
    string ret;
    char* buf = ret.reserve(decode_base16_getlen(source.length()));
    auto len = decode_base16(source, buf);
    ret.length(len);
    return ret;
}

}}
