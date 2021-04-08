#pragma once
#include <catch2/catch.hpp>
#include <panda/encode/base2n.h>

using namespace panda;
using namespace panda::encode;

struct TestData {
    string str;
    string ENCODED;
    string encoded;

    TestData (string encoded) : encoded(encoded) {
        for (int i = 0; i < 256; ++i) str += (char)i;
        ENCODED = encoded;
        std::transform(ENCODED.begin(), ENCODED.end(), ENCODED.begin(), [](unsigned char c){ return std::toupper(c); });
    }
};
