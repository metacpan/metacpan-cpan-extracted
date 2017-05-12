/* DTrace.xs */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "runops.h"

/* *INDENT-OFF* */

MODULE = Devel::DTrace PACKAGE = Devel::DTrace
PROTOTYPES: ENABLE

void
_dtrace_hook_runops()
PPCODE:
{
    runops_hook();
}
