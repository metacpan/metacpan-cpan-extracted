#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

MODULE = Hash::NoVivify		PACKAGE = Hash::NoVivify

PROTOTYPES: ENABLE

void
Exists(href, ...)
  SV* href

  CODE:
  int i;
  HV* h;
  U32 hash;
  SV* t;

  if (!SvOK(href) || 
      !SvROK(href) ||
      (SvTYPE(t = SvRV(href)) != SVt_PVHV)) {
    XSRETURN_NO;
  }

#	/* The idea is easy. For each element of the array, */
#	/* if that element exists as a key of the hashref,  */
#	/* set the hashref to that element. Otherwise, blow  */

#	/* Note that at the top, href is an SV* of the hashref */
  for (i = 1; i < items; i++) {
    
    if (SvOK(href) &&
	SvROK(href) &&
	SvPOK(ST(i)) &&
	hv_exists_ent(h = (HV*)SvRV(href), ST(i), 0)) {
      href = HeVAL(hv_fetch_ent(h, ST(i), FALSE, 0));
    } else {
      XSRETURN_NO;
    }
  }

  XSRETURN_YES;

#/*    I know that there's a better way to do this, rather than */
#/*    duplicating all code, but I don't know what it is right now. */
void
Defined(href, ...)
  SV* href

  CODE:
  int i;
  HV* h;
  U32 hash;
  SV* t;

  if (!SvOK(href) || 
      !SvROK(href) ||
      (SvTYPE(t = SvRV(href)) != SVt_PVHV)) {
    XSRETURN_NO;
  }

#	/* The idea is easy. For each element of the array, */
#	/* if that element exists as a key of the hashref,  */
#	/* set the hashref to that element. Otherwise, blow  */

#	/* Note that at the top, href is an SV* of the hashref */
  for (i = 1; i < items; i++) {
    
    if (SvOK(href) &&
	SvROK(href) &&
	SvPOK(ST(i)) &&
	hv_exists_ent(h = (HV*)SvRV(href), ST(i), 0)) {
      href = HeVAL(hv_fetch_ent(h, ST(i), FALSE, 0));
    } else {
      XSRETURN_NO;
    }
  }

#  /* href is the SV of the hashref */
  if (!SvOK(href))
    XSRETURN_NO;

  XSRETURN_YES;
  

