#pragma once
#include <cstddef>
#include <panda/string.h>
#include <panda/basic_string.h>

namespace panda { namespace encode {

using std::size_t;

inline size_t encode_base64_getlen (size_t source_len) { return (source_len + 2) / 3 * 4; }
inline size_t decode_base64_getlen (size_t source_len) { return source_len * 3 / 4; }

size_t encode_base64 (const string_view source, char* dest, bool url_mode = false, bool use_pad = false);
size_t decode_base64 (const string_view source, char* dest);

inline string encode_base64 (const string_view source, bool url_mode = false, bool use_pad = false) {
    string ret;
    char* buf = ret.reserve(encode_base64_getlen(source.length()));
    auto len = encode_base64(source, buf, url_mode, use_pad);
    ret.length(len);
    return ret;
}

inline string decode_base64 (const string_view source) {
    string ret;
    char* buf = ret.reserve(decode_base64_getlen(source.length()));
    auto len = decode_base64(source, buf);
    ret.length(len);
    return ret;
}

}}
