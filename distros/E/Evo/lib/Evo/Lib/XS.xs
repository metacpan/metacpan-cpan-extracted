#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "xs.c"

MODULE = Evo::Lib::XS     PACKAGE = Evo::Lib::XS PREFIX = evo_lib_

PROTOTYPES: ENABLE

int evo_lib_try(...)
PROTOTYPE: &$;$
PPCODE:
  dTHX;
  PERL_UNUSED_VAR(targ);
  PERL_UNUSED_VAR(RETVAL);
  SP = evo_lib_try(ax, items, SP);
