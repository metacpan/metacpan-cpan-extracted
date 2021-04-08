#include "test.h"
#include <cctype>
#include <algorithm>

#define TEST(name) TEST_CASE("base32: " name, "[base32]")

static TestData data("aaaqeayeaudaocajbifqydiob4ibceqtcqkrmfyydenbwha5dypsaijcemsckjrhfausukzmfuxc6mbrgiztinjwg44dsor3hq6t4p2aifbegrcfizduqskkjnge2tspkbiveu2ukvlfowczljnvyxk6l5qgcytdmrswmz3infvgw3dnnzxxa4lson2hk5txpb4xu634pv7h7aebqkbyjbmgq6eitculrsgy5d4qsgjjhfevs2lzrgm2tooj3hu7ucq2fi5euwtkpkfjvkv2zlnov6yldmvtws23nn5yxg5lxpf5x274bqocypcmlrwhzde4vs6mzxhm7ugr2lj5jvow27mntww33to55x7a4hrohzhf43t6r2pk5pwo33xp6dy7f47u6x3pp6hz7l57z7p674");

TEST("encode lower-case") {
    CHECK(encode_base32(data.str) == data.encoded);
}

TEST("encode upper-case") {
    CHECK(encode_base32(data.str, true) == data.ENCODED);
}

TEST("decode lower-case") {
    CHECK(( decode_base32(encode_base32(data.str)) == data.str ));
}

TEST("decode upper-case") {
    CHECK(( decode_base32(encode_base32(data.str, true)) == data.str ));
}
