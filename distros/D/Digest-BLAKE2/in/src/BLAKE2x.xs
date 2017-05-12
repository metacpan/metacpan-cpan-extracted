/* vim: set expandtab ts=4 sw=4 nowrap ft=xs ff=unix : */
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#undef ALIGN
#undef LIKELY
#include "../blake2/sse/blake2x.c"
#include "modp_b16.h"
#include "modp_b64.h"
#include "modp_b64w.h"
#include "modp_b85.h"

#define BLAKE2x

enum encode_type {
    encode_type_raw,
    encode_type_hex,
    encode_type_base64,
    encode_type_base64url,
    encode_type_ascii85
};

inline static SV *
encode_string(pTHX_ const char *src, enum encode_type type) {
    int encoded_len;

    switch (type) {
    case encode_type_raw:
    default:
        return sv_2mortal(newSVpv(src, BLAKE2x_OUTBYTES));
        break;
    case encode_type_hex:
        {
            char buffer[modp_b16_encode_len(BLAKE2x_OUTBYTES)];
            encoded_len = modp_b16_encode(buffer, src, BLAKE2x_OUTBYTES);
            return sv_2mortal(newSVpv(buffer, encoded_len));
        }
        break;
    case encode_type_base64:
        {
            char buffer[modp_b64_encode_len(BLAKE2x_OUTBYTES)];
            encoded_len = modp_b64_encode(buffer, src, BLAKE2x_OUTBYTES);
#if (defined BLAKE2s) || (defined BLAKE2sp)
            /* remove trailing padding 1 characters */
            return sv_2mortal(newSVpv(buffer, encoded_len - 1));
#elif (defined BLAKE2b) || (defined BLAKE2bp)
            /* remove trailing padding 2 characters */
            return sv_2mortal(newSVpv(buffer, encoded_len - 2));
#endif
        }
        break;
    case encode_type_base64url:
        {
            char buffer[modp_b64w_encode_len(BLAKE2x_OUTBYTES)];
            encoded_len = modp_b64w_encode(buffer, src, BLAKE2x_OUTBYTES);
#if (defined BLAKE2s) || (defined BLAKE2sp)
            /* remove trailing padding 1 characters */
            return sv_2mortal(newSVpv(buffer, encoded_len - 1));
#elif (defined BLAKE2b) || (defined BLAKE2bp)
            /* remove trailing padding 2 characters */
            return sv_2mortal(newSVpv(buffer, encoded_len - 2));
#endif
        }
        break;
    case encode_type_ascii85:
        {
            char buffer[modp_b85_encode_len(BLAKE2x_OUTBYTES)];
            encoded_len = modp_b85_encode(buffer, src, BLAKE2x_OUTBYTES);
            return sv_2mortal(newSVpv(buffer, encoded_len));
        }
        break;
    }
}

typedef blake2x_state *Digest__BLAKE2x;

MODULE = Digest::BLAKE2x PACKAGE = Digest::BLAKE2x

Digest::BLAKE2x
new (class)
    SV *class
CODE:
    Newx(RETVAL, 1, blake2x_state);
    if (blake2x_init(RETVAL, BLAKE2x_OUTBYTES)) {
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

Digest::BLAKE2x
clone (self)
    Digest::BLAKE2x self
CODE:
    Newx(RETVAL, 1, blake2x_state);
    Copy(self, RETVAL, 1, blake2x_state);
OUTPUT:
    RETVAL

void
add (self, ...)
    Digest::BLAKE2x self
PREINIT:
    int i;
    uint8_t *in;
    STRLEN inlen;
PPCODE:
    for (i = 1; i < items; i++) {
        in = (uint8_t *)(SvPV(ST(i), inlen));
        blake2x_update(self, in, inlen);
    }
    XSRETURN(1);

void
digest (self)
    Digest::BLAKE2x self
PREINIT:
    uint8_t out[BLAKE2x_OUTBYTES];
CODE:
    blake2x_final(self, out, BLAKE2x_OUTBYTES);
    ST(0) = sv_2mortal(newSVpv((const char *)out, BLAKE2x_OUTBYTES));
    XSRETURN(1);

void
DESTROY (self)
    Digest::BLAKE2x self
CODE:
    Safefree(self);

void
blake2x (...)
ALIAS:
    blake2x = encode_type_raw
    blake2x_hex = encode_type_hex
    blake2x_base64 = encode_type_base64
    blake2x_base64url = encode_type_base64url
    blake2x_ascii85 = encode_type_ascii85
PREINIT:
    int i;
    uint8_t *in;
    STRLEN inlen;
    blake2x_state *state;
    uint8_t out[BLAKE2x_OUTBYTES];
CODE:
    Newx(state, 1, blake2x_state);
    if (blake2x_init(state, BLAKE2x_OUTBYTES)) {
        XSRETURN_UNDEF;
    }
    for (i = 0; i < items; i++) {
        in = (uint8_t *)(SvPV(ST(i), inlen));
        blake2x_update(state, in, inlen);
    }
    blake2x_final(state, out, BLAKE2x_OUTBYTES);
    Safefree(state);
    ST(0) = encode_string(aTHX_ (char *)out, ix);
    XSRETURN(1);
