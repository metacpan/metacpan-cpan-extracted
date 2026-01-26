#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

static bool
THX_keys_disjoint(pTHX_ HV *x, HV *y) {
  HE *he;

  if (HvTOTALKEYS(x) > HvTOTALKEYS(y)) {
    HV *tmp = x;
    x = y;
    y = tmp;
  }

  hv_iterinit(x);
  while ((he = hv_iternext(x))) {
    if (hv_exists_ent(y, hv_iterkeysv(he), HeHASH(he)))
      return FALSE;
  }
  return TRUE;
}

static bool
THX_keys_equal(pTHX_ HV *x, HV *y) {
  HE *he;

  if (HvTOTALKEYS(x) != HvTOTALKEYS(y))
    return FALSE;

  hv_iterinit(x);
  while ((he = hv_iternext(x))) {
    if (!hv_exists_ent(y, hv_iterkeysv(he), HeHASH(he)))
      return FALSE;
  }
  return TRUE;
}

static bool
THX_keys_subset(pTHX_ HV *x, HV *y) {
  HE *he;

  if (HvTOTALKEYS(x) > HvTOTALKEYS(y))
    return FALSE;

  hv_iterinit(x);
  while ((he = hv_iternext(x))) {
    if (!hv_exists_ent(y, hv_iterkeysv(he), HeHASH(he)))
      return FALSE;
  }
  return TRUE;
}

static bool
THX_keys_proper_subset(pTHX_ HV *x, HV *y) {
  HE *he;

  if (HvTOTALKEYS(x) >= HvTOTALKEYS(y))
    return FALSE;

  hv_iterinit(x);
  while ((he = hv_iternext(x))) {
    if (!hv_exists_ent(y, hv_iterkeysv(he), HeHASH(he)))
      return FALSE;
  }
  return TRUE;
}

MODULE = Hash::Util::Set::XS   PACKAGE = Hash::Util::Set::XS

PROTOTYPES: ENABLE

void
keys_union(x, y)
  HV *x
  HV *y
PROTOTYPE: \%\%
PREINIT:
  HV *seen;
  HE *he;
PPCODE:
  sv_2mortal((SV *)(seen = newHV()));

  hv_iterinit(x);
  while ((he = hv_iternext(x))) {
    (void)hv_store_ent(seen, hv_iterkeysv(he), &PL_sv_undef, HeHASH(he));
  }

  hv_iterinit(y);
  while ((he = hv_iternext(y))) {
    (void)hv_store_ent(seen, hv_iterkeysv(he), &PL_sv_undef, HeHASH(he));
  }

  hv_iterinit(seen);
  EXTEND(SP, HvTOTALKEYS(seen));
  while ((he = hv_iternext(seen))) {
    PUSHs(sv_2mortal(newSVsv(hv_iterkeysv(he))));
  }

void
keys_intersection(x, y)
  HV *x
  HV *y
PROTOTYPE: \%\%
PREINIT:
  HE *he;
PPCODE:
  if (HvTOTALKEYS(x) > HvTOTALKEYS(y)) {
    HV *tmp = x;
    x = y;
    y = tmp;
  }

  hv_iterinit(x);
  while ((he = hv_iternext(x))) {
    if (hv_exists_ent(y, hv_iterkeysv(he), HeHASH(he)))
      PUSHs(sv_2mortal(newSVsv(hv_iterkeysv(he))));
  }

void
keys_difference(x, y)
  HV *x
  HV *y
PROTOTYPE: \%\%
PREINIT:
  HE *he;
PPCODE:
  hv_iterinit(x);
  while ((he = hv_iternext(x))) {
    if (!hv_exists_ent(y, hv_iterkeysv(he), HeHASH(he)))
      XPUSHs(sv_2mortal(newSVsv(hv_iterkeysv(he))));
  }

void
keys_symmetric_difference(x, y)
  HV *x
  HV *y
PROTOTYPE: \%\%
PREINIT:
  HE *he;
PPCODE:
  hv_iterinit(x);
  while ((he = hv_iternext(x))) {
    if (!hv_exists_ent(y, hv_iterkeysv(he), HeHASH(he)))
      XPUSHs(sv_2mortal(newSVsv(hv_iterkeysv(he))));
  }

  hv_iterinit(y);
  while ((he = hv_iternext(y))) {
    if (!hv_exists_ent(x, hv_iterkeysv(he), HeHASH(he)))
      XPUSHs(sv_2mortal(newSVsv(hv_iterkeysv(he))));
  }

bool
keys_disjoint(x, y)
  HV *x
  HV *y
PROTOTYPE: \%\%
CODE:
  RETVAL = THX_keys_disjoint(aTHX_ x, y);
OUTPUT:
  RETVAL

bool
keys_equal(x, y)
  HV *x
  HV *y
PROTOTYPE: \%\%
CODE:
  RETVAL = THX_keys_equal(aTHX_ x, y);
OUTPUT:
  RETVAL

bool
keys_subset(x, y)
  HV *x
  HV *y
PROTOTYPE: \%\%
CODE:
  RETVAL = THX_keys_subset(aTHX_ x, y);
OUTPUT:
  RETVAL
    
bool
keys_proper_subset(x, y)
  HV *x
  HV *y
PROTOTYPE: \%\%
CODE:
  RETVAL = THX_keys_proper_subset(aTHX_ x, y);
OUTPUT:
  RETVAL

bool
keys_superset(x, y)
  HV *x
  HV *y
PROTOTYPE: \%\%
CODE:
  RETVAL = THX_keys_subset(aTHX_ y, x);
OUTPUT:
  RETVAL

bool
keys_proper_superset(x, y)
  HV *x
  HV *y
PROTOTYPE: \%\%
CODE:
  RETVAL = THX_keys_proper_subset(aTHX_ y, x);
OUTPUT:
  RETVAL

bool
keys_any(x, ...)
  HV *x
PROTOTYPE: \%@
PREINIT:
  I32 i;
CODE:
  RETVAL = FALSE;
  for (i = 1; i < items; i++) {
    if (hv_exists_ent(x, ST(i), 0)) {
      RETVAL = TRUE;
      break;
    }
  }
OUTPUT:
  RETVAL

bool
keys_all(x, ...)
  HV *x
PROTOTYPE: \%@
PREINIT:
  I32 i;
CODE:
  RETVAL = TRUE;
  for (i = 1; i < items; i++) {
    if (!hv_exists_ent(x, ST(i), 0)) {
      RETVAL = FALSE;
      break;
    }
  }
OUTPUT:
  RETVAL

bool
keys_none(x, ...)
  HV *x
PROTOTYPE: \%@
PREINIT:
  I32 i;
CODE:
  RETVAL = TRUE;
  for (i = 1; i < items; i++) {
    if (hv_exists_ent(x, ST(i), 0)) {
      RETVAL = FALSE;
      break;
    }
  }
OUTPUT:
  RETVAL
