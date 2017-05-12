#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = Devel::Refcount    PACKAGE = Devel::Refcount

int
refcount(ref)
  SV *ref

  CODE:
    if(!SvROK(ref)) {
      croak("ref is not a reference");
    }
    RETVAL = SvREFCNT(SvRV(ref));
  OUTPUT:
    RETVAL
