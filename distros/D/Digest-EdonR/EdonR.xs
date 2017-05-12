#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "src/edonr.c"

static int
hex_encode (char *dest, const unsigned char *src, int len) {
    static const char hex[] = "0123456789abcdef";
    char *p = dest;
    const unsigned char *s = src;
    for (; len--; s++) {
        *p++ = hex[s[0] >> 4];
        *p++ = hex[s[0] & 0x0f];
    }
    return (int)(p - dest);
}

static int
base64_encode (char *dest, const unsigned char *src, int len) {
    static const char b64[] =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    char *p = dest;
    const unsigned char *s = src;
    const unsigned char *end = src + len - 2;

    for (; s < end; s += 3) {
        *p++ = b64[s[0] >> 2];
        *p++ = b64[((s[0] & 3) << 4) + (s[1] >> 4)];
        *p++ = b64[((s[1] & 0xf) << 2) + (s[2] >> 6)];
        *p++ = b64[s[2] & 0x3f];
    }
    switch (len % 3) {
    case 1:
        *p++ = b64[s[0] >> 2];
        *p++ = b64[(s[0] & 3) << 4];
        break;
    case 2:
        *p++ = b64[s[0] >> 2];
        *p++ = b64[((s[0] & 3) << 4) + (s[1] >> 4)];
        *p++ = b64[((s[1] & 0xf) << 2)];
        break;
    }
    return (int)(p - dest);
}

static SV *
make_mortal_sv(pTHX_ const unsigned char *src, int bitlen, int enc) {
    char result[128];
    char *ret;
    int len = bitlen >> 3;

    switch (enc) {
    case 0:
        ret = (char *)src;
        break;
    case 1:
        len = hex_encode(result, src, len);
        ret = result;
        break;
    case 2:
        len = base64_encode(result, src, len);
        ret = result;
        break;
    }
    return sv_2mortal(newSVpv(ret, len));
}

typedef hashState *Digest__EdonR;

MODULE = Digest::EdonR    PACKAGE = Digest::EdonR

PROTOTYPES: ENABLE

void
edonr_224 (...)
ALIAS:
    edonr_224 = 0
    edonr_224_hex = 1
    edonr_224_base64 = 2
    edonr_256 = 3
    edonr_256_hex = 4
    edonr_256_base64 = 5
    edonr_384 = 6
    edonr_384_hex = 7
    edonr_384_base64 = 8
    edonr_512 = 9
    edonr_512_hex = 10
    edonr_512_base64 = 11
PREINIT:
    hashState ctx;
    int bitlen, i;
    unsigned char *data;
    STRLEN len;
    unsigned char result[64];
CODE:
    static const int ix2bits[] =
        {224, 224, 224, 256, 256, 256, 384, 384, 384, 512, 512, 512};
    bitlen = ix2bits[ix];
    if (Init(&ctx, bitlen) != SUCCESS)
        XSRETURN_UNDEF;
    for (i = 0; i < items; i++) {
        data = (unsigned char *)(SvPV(ST(i), len));
        if (Update(&ctx, data, len << 3) != SUCCESS)
            XSRETURN_UNDEF;
    }
    if (Final(&ctx, result) != SUCCESS)
        XSRETURN_UNDEF;
    ST(0) = make_mortal_sv(aTHX_ result, bitlen, ix % 3);
    XSRETURN(1);

Digest::EdonR
new (class, hashsize)
    SV *class
    int hashsize
CODE:
    Newx(RETVAL, 1, hashState);
    if (Init(RETVAL, hashsize) != SUCCESS)
        XSRETURN_UNDEF;
OUTPUT:
    RETVAL

Digest::EdonR
clone (self)
    Digest::EdonR self
CODE:
    Newx(RETVAL, 1, hashState);
    Copy(self, RETVAL, 1, hashState);
OUTPUT:
    RETVAL

void
reset (self)
    Digest::EdonR self
PPCODE:
    if (Init(self, self->hashbitlen) != SUCCESS)
        XSRETURN_UNDEF;
    XSRETURN(1);

int
hashsize(self)
    Digest::EdonR self
ALIAS:
    algorithm = 1
CODE:
    RETVAL = self->hashbitlen;
OUTPUT:
    RETVAL

void
add (self, ...)
    Digest::EdonR self
PREINIT:
    int i;
    unsigned char *data;
    STRLEN len;
PPCODE:
    for (i = 1; i < items; i++) {
        data = (unsigned char *)(SvPV(ST(i), len));
        if (Update(self, data, len << 3) != SUCCESS)
            XSRETURN_UNDEF;
    }
    XSRETURN(1);

void
_add_bits (self, msg, bitlen)
    Digest::EdonR self
    SV *msg
    int bitlen
PREINIT:
    int i;
    unsigned char *data;
    STRLEN len;
PPCODE:
    if (! bitlen)
        XSRETURN(1);
    data = (unsigned char *)(SvPV(msg, len));
    if (bitlen > len << 3)
        bitlen = len << 3;
    if (Update(self, data, bitlen) != SUCCESS)
        XSRETURN_UNDEF;
    XSRETURN(1);

void *
digest (self)
    Digest::EdonR self
ALIAS:
    digest = 0
    hexdigest = 1
    b64digest = 2
PREINIT:
    unsigned char result[64];
CODE:
    if (Final(self, result) != SUCCESS)
        XSRETURN_UNDEF;
    Init(self, self->hashbitlen);
    ST(0) = make_mortal_sv(aTHX_ result, self->hashbitlen, ix);
    XSRETURN(1);

void
DESTROY (self)
    Digest::EdonR self
CODE:
    Safefree(self);
