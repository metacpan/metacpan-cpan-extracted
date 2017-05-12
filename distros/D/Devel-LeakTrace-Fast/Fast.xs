#include "common.h"
#include "tools.h"

MODULE = Devel::LeakTrace::Fast PACKAGE = Devel::LeakTrace::Fast

PROTOTYPES: ENABLE

void
_hook_runops()
PPCODE:
{
    tools_hook_runops();
}

void
_reset_counters()
PPCODE:
{
    tools_reset_counters();
}

void
_show_used()
CODE:
{
    tools_show_used();
}
