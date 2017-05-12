#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef DEBUGGING
#undef assert
#define assert(expr)                                                           \
  ((expr) ? (void)0 : croak("XS Assertion: %s failed (%s:%d)", #expr,          \
                            __FILE__, __LINE__))
#endif


#include "eca.h"
#include "helpers.c"
#include "eca.c"
#include "xs.c"

MODULE = Evo::Class::Attrs::XS				PACKAGE = Evo::Class::Attrs::XS PREFIX = attrs_

PROTOTYPES: DISABLE

SV * attrs__gen_attr(self, name, type, value, check, is_ro, inject, method)
  SV *self;
  char *name;
  int type;
  SV *value;
  SV *check;
  bool is_ro;
  SV *inject;
  bool method;

SV *attrs_gen_new(self)
  SV *self;

bool attrs_exists(self, name)
  SV *self;
  SV *name;

void slots(self)
  SV *self;
PPCODE:
  AV *av = sv2av(self);
  int i, last = av_top_index(av), size = last + 1;

  for (i = 0; i < size; i++) {
    SV **tmp = av_fetch(av, i, 0);
    if (!tmp) croak("Broken attr %d", i);
    mXPUSHs(psv_to_slotsv(*tmp));
  }

