#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <blake3.h>

typedef struct digest_blake3 {
    unsigned int mode;
    UV hashsize;
    blake3_hasher state;
}  digest_blake3, *Digest__BLAKE3;

MODULE = Digest::BLAKE3          PACKAGE = Digest::BLAKE3

PROTOTYPES: DISABLE

Digest::BLAKE3
_new(class)
    SV *class
CODE:
    Newx(RETVAL, 1, digest_blake3);
    RETVAL->hashsize = BLAKE3_OUT_LEN;
OUTPUT:
    RETVAL

Digest::BLAKE3
clone(self)
    Digest::BLAKE3 self
CODE:
    Newx(RETVAL, 1, digest_blake3);
    *RETVAL = *self;
OUTPUT:
    RETVAL

void
DESTROY(self)
    Digest::BLAKE3 self
CODE:
    Safefree(self);

SV *
_init_hash(self)
    Digest::BLAKE3 self
CODE:
    self->mode = 0;
    blake3_hasher_init(&self->state);

SV *
_init_keyed_hash(self, key)
    Digest::BLAKE3 self
    SV *key
CODE:
    {
        unsigned char *keybytes;
        STRLEN keylen;

        keybytes = (unsigned char *)SvPVbyte(key, keylen);
        if (keylen!=BLAKE3_KEY_LEN)
            croak("Invalid key length");
        self->mode = 1;
        blake3_hasher_init_keyed(&self->state, keybytes);
    }

SV *
_init_derive_key(self, context)
    Digest::BLAKE3 self
    SV *context
CODE:
    {
        void *cont;
        STRLEN contlen;

        cont = SvPVbyte(context, contlen);
        self->mode = 2;
        blake3_hasher_init_derive_key_raw(&self->state, cont, contlen);
    }

SV *
reset(self)
    Digest::BLAKE3 self
CODE:
    blake3_hasher_reset(&self->state);

SV *
add(self, ...)
    Digest::BLAKE3 self
CODE:
    {
        IV i;

        for (i = 1; i<items; i++) {
            SV *arg;
            void *data;
            STRLEN size;

            arg = ST(i);
            data = SvPVbyte(arg, size);
            blake3_hasher_update(&self->state, data, size);
        }
    }

SV *
digest(self)
    Digest::BLAKE3 self
CODE:
    {
        UV hashsize;
        unsigned char *buf;

        hashsize = self->hashsize;
        RETVAL = newSV(hashsize);
        SvPOK_on(RETVAL);
        buf = (unsigned char *)SvPVbyte_nolen(RETVAL);
        blake3_hasher_finalize(&self->state, buf, hashsize);
        buf[hashsize]=0;
        SvCUR_set(RETVAL, hashsize);
        blake3_hasher_reset(&self->state);
    }
OUTPUT:
    RETVAL

IV
_mode(self)
    Digest::BLAKE3 self
CODE:
    RETVAL = self->mode;
OUTPUT:
    RETVAL

UV
hashsize(self, hashsize = NO_INIT)
    Digest::BLAKE3 self
    UV hashsize
CODE:
    RETVAL = self->hashsize<<3;
    if (items>=2) {
        if (hashsize & 7 || hashsize<=0)
            croak("Hash size must be a positive multiple of 8 bits");
        self->hashsize = hashsize>>3;
    }
OUTPUT:
    RETVAL

