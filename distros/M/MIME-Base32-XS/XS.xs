#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define XX      255
#define INVALID XX

static const char base_32[32] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";

static const unsigned char index_32[256] = {
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,26,27, 28,29,30,31, XX,XX,XX,XX, XX,XX,XX,XX,
    XX, 0, 1, 2, 3 , 4, 5, 6,  7, 8, 9,10, 11,12,13,14,
    15,16,17,18, 19,20,21,22, 23,24,25,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
    XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX, XX,XX,XX,XX,
};

MODULE = MIME::Base32::XS     PACKAGE = MIME::Base32::XS

SV *
encode_base32(SV *sv)
    PREINIT:
    STRLEN len;
    SSize_t size;
    unsigned char *input;
    unsigned char *output;
    unsigned long long x = 0;
    unsigned int i, z, n = 0;
    char ap[5] = {0, 6, 4, 3, 1};

    CODE:
    input = SvPV(sv, len);
    size = (SSize_t)len;
    len = (size * 2) + ap[size % 5];
    RETVAL = newSV(len ? len : 1);
    SvPOK_on(RETVAL);
    output = SvPVX(RETVAL);

    for (i = 0; i < size; i++) {
        for (z = 0; z < 5 && i < size; z++, i++) {
            x |= input[i];
            x <<= 8;
        }

        x <<= (7 - z) << 3;

        *output++ = base_32[x >> 59];
        *output++ = base_32[(x << 5) >> 59];
        *output++ = base_32[(x << 10) >> 59];
        *output++ = base_32[(x << 15) >> 59];
        *output++ = base_32[(x << 20) >> 59];
        *output++ = base_32[(x << 25) >> 59];
        *output++ = base_32[(x << 30) >> 59];
        *output++ = base_32[(x << 35) >> 59];

        --i;
        n += 8;
    }

    *output = '\0';

    for (i = ap[size % 5]; i; i--)
        *--output = '=';

    SvCUR_set(RETVAL, n);

    OUTPUT:
    RETVAL

SV *
decode_base32(SV *sv)
    PREINIT:
    STRLEN len;
    SSize_t size;
    unsigned char *input;
    char *output;
    unsigned long long x;
    unsigned int i, z, rtsize, v, n = 0;
    unsigned char pad;
    unsigned char t;
    char lkpad[7] = {0, 4, 0, 3, 2, 0, 1};

    CODE:
    input = SvPV(sv, len);
    size = (SSize_t)len;

    for (pad = 0, i = len-1; input[i] == '='; i--) {
        ++pad;
        --size;
    }

    len = (len * 3 / 4);
    RETVAL = newSV(len ? len : 1);
    SvPOK_on(RETVAL);
    output = SvPVX(RETVAL);

    for (i = 0; i < size; i++) {
        if (input[i] != '=') {
    	    for (x = 0, z = 0; z < 8 && i < size; z++, i++) {
                v = index_32[input[i]];
                if (v != INVALID) {
        		    for (t = 0; v != t; t++);
        		    x |= t;
        		    x <<= 5;
        		}
    	    }

    	    x <<= (19 + ((8 - z) * 5));
    	    *output++ = x >> 56;
    	    *output++ = (x << 8) >> 56;
    	    *output++ = (x << 16) >> 56;
    	    *output++ = (x << 24) >> 56;
    	    *output++ = (x << 32) >> 56;
    	    --i;
        }
    }

    n = (size >> 3) * 5 + lkpad[pad];

    output[n] = '\0';

    SvCUR_set(RETVAL, n);

    OUTPUT:
    RETVAL
