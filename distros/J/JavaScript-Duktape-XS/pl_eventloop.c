#include <stdio.h>
#include "pl_eventloop.h"
#include "c_eventloop.h"

int pl_register_eventloop(Duk* duk)
{
    /* Register our event loop dispatcher */
    eventloop_register(duk->ctx);
    return 0;
}
