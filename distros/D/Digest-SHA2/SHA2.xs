#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "_sha2.c"

typedef struct sha2 {
    SHA256_CTX ctx256;
    SHA384_CTX ctx384;
    SHA512_CTX ctx512;
    int digestsize;
    int rounds;
}* Digest__SHA2;

MODULE = Digest::SHA2		PACKAGE = Digest::SHA2
PROTOTYPES: DISABLE

Digest::SHA2
new(class, hashlength=256)
    int hashlength;

    CODE:
    {
        switch (hashlength) {
            case 256:
            case 384:
            case 512:
                break;

            default:
                croak("\nAcceptable hash sizes are 256, 384, and 512 only\n");
                break;
        }

        Newz(0, RETVAL, 1, struct sha2);
        RETVAL->digestsize = hashlength;
        RETVAL->rounds = 1;

        switch (RETVAL->digestsize) {
            case 256:
                SHA256_Init(&RETVAL->ctx256);
                break;

            case 384:
                SHA384_Init(&RETVAL->ctx384);
                break;

            case 512:
                SHA512_Init(&RETVAL->ctx512);
                break;
        }
    }

    OUTPUT:
        RETVAL

Digest::SHA2
clone(self)
    Digest::SHA2 self;

    CODE:
    {
        Newz(0, RETVAL, 1, struct sha2);
        Copy(self, RETVAL, 1, struct sha2);
    }

    OUTPUT:
        RETVAL

int
hashsize(self)
    Digest::SHA2 self
    CODE:
        RETVAL = self->digestsize;

    OUTPUT:
        RETVAL

int
rounds(self)
    Digest::SHA2 self
    CODE:
        RETVAL = self->rounds;

    OUTPUT:
        RETVAL

void
reset(self)
    Digest::SHA2 self
    CODE:
    {
        switch (self->digestsize) {
            case 256:
                SHA256_Init(&self->ctx256);
                break;

            case 384:
                SHA384_Init(&self->ctx384);
                break;

            case 512:
                SHA512_Init(&self->ctx512);
                break;
        }
    }

void
add(self, ...)
    Digest::SHA2 self
    CODE:
    {
        STRLEN len;
        unsigned char* data;
        unsigned int i;

        for (i = 1; i < items; i++) {
            data = (unsigned char*)(SvPV(ST(i), len));

            switch (self->digestsize) {
                case 256:
                    SHA256_Update(&self->ctx256, data, len);
                    break;

                case 384:
                    SHA384_Update(&self->ctx384, data, len);
                    break;

                case 512:
                    SHA512_Update(&self->ctx512, data, len);
                    break;
            }
        }
    }

SV*
hexdigest(self)
    Digest::SHA2 self
    CODE:
    {
        RETVAL = newSVpv("", 64);  /* defaults to SHA-256 */

        switch (self->digestsize) {
            case 256:
                SHA256_End(&self->ctx256, SvPV_nolen(RETVAL));
                break;

            case 384:
                RETVAL = newSVpv("", 96);
                SHA384_End(&self->ctx384, SvPV_nolen(RETVAL));
                break;

            case 512:
                RETVAL = newSVpv("", 128);
                SHA512_End(&self->ctx512, SvPV_nolen(RETVAL));
                break;
        }
    }

    OUTPUT:
        RETVAL

void
DESTROY(self)
    Digest::SHA2 self
    CODE:
        Safefree(self);

