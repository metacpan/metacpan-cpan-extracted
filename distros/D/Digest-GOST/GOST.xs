#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "src/gost.c"

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
make_mortal_sv(pTHX_ const unsigned char *src, int len, int enc) {
    char result[64];
    char *ret;

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

typedef gost_ctx *Digest__GOST;
typedef gost_ctx *Digest__GOST__CryptoPro;

MODULE = Digest::GOST    PACKAGE = Digest::GOST

PROTOTYPES: ENABLE

void
gost (...)
ALIAS:
    gost = 0
    gost_hex = 1
    gost_base64 = 2
PREINIT:
    gost_ctx ctx;
    int i;
    unsigned char *data;
    unsigned char result[32];
    STRLEN len;
CODE:
    rhash_gost_init(&ctx);
    for (i = 0; i < items; i++) {
        data = (unsigned char *)(SvPV(ST(i), len));
        rhash_gost_update(&ctx, data, len);
    }
    rhash_gost_final(&ctx, result);
    ST(0) = make_mortal_sv(aTHX_ result, 32, ix);
    XSRETURN(1);

Digest::GOST
new (class)
    SV *class
CODE:
    Newx(RETVAL, 1, gost_ctx);
    rhash_gost_init(RETVAL);
OUTPUT:
    RETVAL

Digest::GOST
clone (self)
    Digest::GOST self
CODE:
    Newx(RETVAL, 1, gost_ctx);
    Copy(self, RETVAL, 1, gost_ctx);
OUTPUT:
    RETVAL

void
reset (self)
    Digest::GOST self
PPCODE:
    rhash_gost_init(self);
    XSRETURN(1);

void
add (self, ...)
    Digest::GOST self
PREINIT:
    int i;
    unsigned char *data;
    STRLEN len;
PPCODE:
    for (i = 1; i < items; i++) {
        data = (unsigned char *)(SvPV(ST(i), len));
        rhash_gost_update(self, data, len);
    }
    XSRETURN(1);

void
digest (self)
    Digest::GOST self
ALIAS:
    digest = 0
    hexdigest = 1
    b64digest = 2
PREINIT:
    unsigned char result[32];
CODE:
    rhash_gost_final(self, result);
    rhash_gost_init(self);
    ST(0) = make_mortal_sv(aTHX_ result, 32, ix);
    XSRETURN(1);

void
DESTROY (self)
    Digest::GOST self
CODE:
    Safefree(self);

MODULE = Digest::GOST   PACKAGE = Digest::GOST::CryptoPro

void
gost (...)
ALIAS:
    gost = 0
    gost_hex = 1
    gost_base64 = 2
PREINIT:
    gost_ctx ctx;
    int i;
    unsigned char *data;
    unsigned char result[32];
    STRLEN len;
CODE:
    rhash_gost_cryptopro_init(&ctx);
    for (i = 0; i < items; i++) {
        data = (unsigned char *)(SvPV(ST(i), len));
        rhash_gost_update(&ctx, data, len);
    }
    rhash_gost_final(&ctx, result);
    ST(0) = make_mortal_sv(aTHX_ result, 32, ix);
    XSRETURN(1);

Digest::GOST::CryptoPro
new (class)
    SV *class
CODE:
    Newx(RETVAL, 1, gost_ctx);
    rhash_gost_cryptopro_init(RETVAL);
OUTPUT:
    RETVAL

void
reset (self)
    Digest::GOST::CryptoPro self
PPCODE:
    rhash_gost_cryptopro_init(self);
    XSRETURN(1);

void
digest (self)
    Digest::GOST::CryptoPro self
ALIAS:
    digest = 0
    hexdigest = 1
    b64digest = 2
PREINIT:
    unsigned char result[32];
CODE:
    rhash_gost_final(self, result);
    rhash_gost_cryptopro_init(self);
    ST(0) = make_mortal_sv(aTHX_ result, 32, ix);
    XSRETURN(1);
