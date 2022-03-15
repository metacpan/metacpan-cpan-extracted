#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


/* Provide a duplicate of Math::Float128::_has_pv_nv_bug. *
 * This allows Float128.pm to determine the value of      *
 * the constant F128_PV_NV_BUG at compile time.           */

int _has_pv_nv_bug(void) {
#if defined(F128_PV_NV_BUG)
     return 1;
#else
     return 0;
#endif
}


MODULE = Math::Float128::Constant  PACKAGE = Math::Float128::Constant

PROTOTYPES: DISABLE


int
_has_pv_nv_bug ()


