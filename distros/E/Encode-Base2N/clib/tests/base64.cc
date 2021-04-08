#include "test.h"
#include <cctype>
#include <algorithm>

#define TEST(name) TEST_CASE("base64: " name, "[base64]")

static TestData data("AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8gISIjJCUmJygpKissLS4vMDEyMzQ1Njc4OTo7PD0+P0BBQkNERUZHSElKS0xNTk9QUVJTVFVWV1hZWltcXV5fYGFiY2RlZmdoaWprbG1ub3BxcnN0dXZ3eHl6e3x9fn+AgYKDhIWGh4iJiouMjY6PkJGSk5SVlpeYmZqbnJ2en6ChoqOkpaanqKmqq6ytrq+wsbKztLW2t7i5uru8vb6/wMHCw8TFxsfIycrLzM3Oz9DR0tPU1dbX2Nna29zd3t/g4eLj5OXm5+jp6uvs7e7v8PHy8/T19vf4+fr7/P3+/w");

TEST("encode") {
    CHECK(encode_base64(data.str) == data.encoded);
}

TEST("encode url-mode") {
    auto chk = data.encoded;
    for (auto c : chk) {
        if (c == '+') c = '-';
        else if (c == '/') c = '_';
    }
    CHECK(encode_base64(data.str, true) == chk);
}

TEST("encode with pad") {
    CHECK(encode_base64(data.str, false, true) == data.encoded + "==");
}

TEST("decode") {
    CHECK(( decode_base64(encode_base64(data.str)) == data.str ));
}

TEST("decode url-mode") {
    CHECK(( decode_base64(encode_base64(data.str, true)) == data.str ));
}

TEST("decode with pad") {
    CHECK(( decode_base64(encode_base64(data.str, false, true)) == data.str ));
}

TEST("utf8") {
    string str = "жопа нах";
    auto enc = encode_base64(str);
    CHECK(enc == "0LbQvtC/0LAg0L3QsNGF");
    CHECK(decode_base64(enc) == "жопа нах");
}

