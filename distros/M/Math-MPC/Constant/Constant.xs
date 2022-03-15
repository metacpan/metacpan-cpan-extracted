#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


/* Provide a duplicate of Math::MPC::_has_pv_nv_bug. *
 * This allows MPC.pm to determine the value of      *
 * the constant MPC_PV_NV_BUG at compile time.       */

int _has_pv_nv_bug(void) {
#if defined(MPC_PV_NV_BUG)
     return 1;
#else
     return 0;
#endif
}


MODULE = Math::MPC::Constant  PACKAGE = Math::MPC::Constant

PROTOTYPES: DISABLE


int
_has_pv_nv_bug ()


