#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#define DECODE_BUF_SIZE 8192

// https://wiki.mobileread.com/wiki/PalmDOC#PalmDoc_byte_pair_compression
int
c_palmdoc_decode(
    const unsigned char* input, STRLEN inlen,
          unsigned char* output, STRLEN outlen,
    STRLEN* decoded
) {

    unsigned int b = 0;
    unsigned int ld = 0;
    unsigned int l, d = 0;
    STRLEN outp = 0;

    *decoded = 0;

    for (STRLEN i = 0; i < inlen;) {
        b = input[i++];
        // space + xor byte with 0x80
        if (b >= 0xc0) {
            if (outp >= outlen) {
                return -1;
            }
            output[outp++] = ' ';
            if (outp >= outlen) {
                return -1;
            }
            output[outp++] = b ^ 0x80;
        // length-distance pair: get next byte, strip 2 leading bits, split
        // byte into 11 bits of distance and 3 bits of length + 3
        } else if (b >= 0x80) {
            if (i + 1 >= inlen) {
                return -1;
            }
            ld = (b << 8) + input[i++];
            d = (ld >> 3) & 0x7ff;
            l = (ld & 0x0007) + 3;
            if (d > outp) {
                return -1;
            }
            if (l > outlen - outp - 1) {
                return -1;
            }
            while (l != 0) {
                output[outp] = output[outp - d];
                outp++;
                l--;
            }
        // literal copy
        } else if (b >= 0x09) {
            if (outp >= outlen) {
                return -1;
            }
            output[outp++] = b;
        // copy next 1-8 bytes
        } else if (b >= 0x01) {
            if (i + b > inlen) {
                return -1;
            }
            if (outp + b > outlen) {
                return -1;
            }
            while (b != 0) {
                output[outp++] = input[i++];
                b--;
            }
        // copy null byte
        } else {
            if (outp >= outlen) {
                return -1;
            }
            output[outp++] = '\0';
        }
    }

    assert(outp <= outlen);

    *decoded = outp;
    return 0;

}

MODULE = EBook::Ishmael		PACKAGE = EBook::Ishmael::Decode		

PROTOTYPES: DISABLE

SV*
xs_palmdoc_decode(encode)
        SV * encode
    INIT:
        STRLEN enclen;
        SV * outsv;
        unsigned char output[DECODE_BUF_SIZE];
        STRLEN declen;
        int s;
    CODE:
        enclen = sv_len_utf8(encode);
        s = c_palmdoc_decode(
            (unsigned char*) SvPVbyte_nolen(encode), enclen,
            output, DECODE_BUF_SIZE,
            &declen
        );
        assert(declen <= DECODE_BUF_SIZE);
        if (s != 0) {
            croak("Invalid LZ77-encoded PalmDOC data stream\n");
        }
        outsv = newSVpvn_flags(output, declen, 0);
        RETVAL = outsv;
    OUTPUT:
        RETVAL
