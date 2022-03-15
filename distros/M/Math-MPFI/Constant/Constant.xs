#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


/* Provide a duplicate of Math::MPFI::_has_pv_nv_bug. *
 * This allows MPFI.pm to determine the value of      *
 * the constant MPFI_PV_NV_BUG at compile time.       */

int _has_pv_nv_bug(void) {
#if defined(MPFI_PV_NV_BUG)
     return 1;
#else
     return 0;
#endif
}


MODULE = Math::MPFI::Constant  PACKAGE = Math::MPFI::Constant

PROTOTYPES: DISABLE


int
_has_pv_nv_bug ()


