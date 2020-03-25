#pragma once
#include <cstddef>
#include <panda/string.h>
#include <panda/basic_string.h>

namespace panda { namespace encode {

using std::size_t;

inline size_t encode_base32_getlen (size_t source_len) { return (source_len + 4) / 5 * 8; }
inline size_t decode_base32_getlen (size_t source_len) { return source_len * 5 / 8; }

size_t encode_base32 (const string_view source, char* dest, bool upper = false);
size_t decode_base32 (const string_view source, char* dest);

inline string encode_base32 (const string_view source, bool upper = false) {
    string ret;
    char* buf = ret.reserve(encode_base32_getlen(source.length()));
    auto len = encode_base32(source, buf, upper);
    ret.length(len);
    return ret;
}

inline string decode_base32 (const string_view source) {
    string ret;
    char* buf = ret.reserve(decode_base32_getlen(source.length()));
    auto len = decode_base32(source, buf);
    ret.length(len);
    return ret;
}

}}
