#include <xsheader.h>
#include <panda/encode/base2n.h>

using namespace panda::encode;
using panda::string_view;

MODULE = Encode::Base2N                PACKAGE = Encode::Base2N
PROTOTYPES: DISABLE

SV* encode_base64 (string_view input) : ALIAS(encode_base64url=1, encode_base64pad=2) {
    RETVAL = newSV(encode_base64_getlen(input.length()) + 1);
    SvPOK_on(RETVAL); 
    size_t rlen = encode_base64(input, SvPVX(RETVAL), ix == 1 ? true : false, ix == 2 ? true : false);
    SvPVX(RETVAL)[rlen] = 0;
    SvCUR_set(RETVAL, rlen);
}

SV* decode_base64 (string_view input) {
    RETVAL = newSV(decode_base64_getlen(input.length()) + 1);
    SvPOK_on(RETVAL);
    size_t rlen = decode_base64(input, SvPVX(RETVAL));
    SvPVX(RETVAL)[rlen] = 0;
    SvCUR_set(RETVAL, rlen);
}
    
SV* encode_base32 (string_view input) : ALIAS(encode_base32low=1) {
    RETVAL = newSV(encode_base32_getlen(input.length()) + 1);
    SvPOK_on(RETVAL);
    size_t rlen = encode_base32(input, SvPVX(RETVAL), ix == 1 ? false : true);
    SvPVX(RETVAL)[rlen] = 0;
    SvCUR_set(RETVAL, rlen);
}    
    
SV* decode_base32 (string_view input) {
    RETVAL = newSV(decode_base32_getlen(input.length()) + 1);
    SvPOK_on(RETVAL);
    size_t rlen = decode_base32(input, SvPVX(RETVAL));
    SvPVX(RETVAL)[rlen] = 0;
    SvCUR_set(RETVAL, rlen);
}
    
SV* encode_base16 (string_view input) : ALIAS(encode_base16low=1) {
    RETVAL = newSV(encode_base16_getlen(input.length()) + 1);
    SvPOK_on(RETVAL);
    size_t rlen = encode_base16(input, SvPVX(RETVAL), ix == 1 ? false : true);
    SvPVX(RETVAL)[rlen] = 0;
    SvCUR_set(RETVAL, rlen);
}    
    
SV* decode_base16 (string_view input) {
    RETVAL = newSV(decode_base16_getlen(input.length()) + 1);
    SvPOK_on(RETVAL);
    size_t rlen = decode_base16(input, SvPVX(RETVAL));
    SvPVX(RETVAL)[rlen] = 0;
    SvCUR_set(RETVAL, rlen);
}
