#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "_haval.c"

typedef struct haval {
    haval_state state;
}* Digest__Haval256;

MODULE = Digest::Haval256		PACKAGE = Digest::Haval256
PROTOTYPES: DISABLE

Digest::Haval256
new(...)
    CODE:
    {
        Newz(0, RETVAL, 1, struct haval);
        haval_start(&RETVAL->state);
    }

    OUTPUT:
        RETVAL

int
hashsize(...)
    CODE:
        RETVAL = 256;
    OUTPUT:
        RETVAL

int
rounds(...)
    CODE:
        RETVAL = 5;
    OUTPUT:
        RETVAL

void
reset(self)
    Digest::Haval256 self
    CODE:
        haval_start(&self->state);
        
void
add(self, ...)
    Digest::Haval256 self
    CODE:
    {
        STRLEN len;
        unsigned char* data;
        unsigned int i;

        for (i = 1; i < items; i++) {
            data = (unsigned char*)(SvPV(ST(i), len));
            haval_hash(&self->state, data, len);
        }
    }

SV*
digest(self)
    Digest::Haval256 self
    CODE:
    {
        RETVAL = newSVpv("", 32);
        haval_end(&self->state, SvPV_nolen(RETVAL));
    }

    OUTPUT:
        RETVAL

void
DESTROY(self)
    Digest::Haval256 self
    CODE:
        Safefree(self);

