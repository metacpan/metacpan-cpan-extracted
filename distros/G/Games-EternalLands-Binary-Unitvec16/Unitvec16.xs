#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "convert.h"

MODULE = Games::EternalLands::Binary::Unitvec16    PACKAGE = Games::EternalLands::Binary::Unitvec16    

unsigned short
_pack_unitvec16(v)
    SV * v
  INIT:
    float n[3];
    int i;
  CODE:
    for (i = 0; i < 3; ++i)
      n[i] = SvNV(*av_fetch((AV *)SvRV(v), i, 0));
    RETVAL = unitvec16_pack(n);
  OUTPUT:
    RETVAL

SV *
_unpack_unitvec16(s)
    unsigned short s
  INIT:
    float n[3];
    int i;
    AV * r;
  CODE:
    r = newAV();
    unitvec16_unpack(s, n);
    for (i = 0; i < 3; ++i) {
      av_push(r, newSVnv(n[i]));
    }
    RETVAL = newRV_noinc((SV *)r);
  OUTPUT:
    RETVAL

