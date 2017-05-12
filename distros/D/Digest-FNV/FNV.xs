#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "fnvlib/fnv.h"

#include "const-c.inc"

MODULE = Digest::FNV		PACKAGE = Digest::FNV		

INCLUDE: const-xs.inc


Fnv32_t
fnv32(a)
    SV *  a
CODE:
    RETVAL = fnv32(SvPV_nolen(a));
OUTPUT:
    RETVAL

Fnv32_t
fnv32a(a)
    SV *  a
CODE:
    RETVAL = fnv32a(SvPV_nolen(a));
OUTPUT:
    RETVAL

Fnv64_t *
fnv64_t(a)
    SV *  a
INIT:
    Fnv64_t *   tfnv;
PPCODE:
    tfnv = fnv64_t(SvPV_nolen(a));
    if (tfnv==0UL) {
        XPUSHs(sv_2mortal(newSVnv(-1)));
    }
    else {
        XPUSHs(sv_2mortal(newSVnv(tfnv->lower)));
        XPUSHs(sv_2mortal(newSVnv(tfnv->upper)));
    }

Fnv64_t *
fnv64a_t(a)
    SV *  a
INIT:
    Fnv64_t *   tfnv;
PPCODE:
    tfnv = fnv64a_t(SvPV_nolen(a));
    if (tfnv==0UL) {
        XPUSHs(sv_2mortal(newSVnv(-1)));
    }
    else {
        XPUSHs(sv_2mortal(newSVnv(tfnv->lower)));
        XPUSHs(sv_2mortal(newSVnv(tfnv->upper)));
    }

