#include <stdio.h>
#include "pl_eventloop.h"
#include "c_eventloop.h"

int pl_register_eventloop(Duk* duk)
{
    // Register our event loop dispatcher, otherwise calls to
    // dispatch_function_in_event_loop will not work.
    eventloop_register(duk->ctx);
    return 0;
}

int pl_run_function_in_event_loop(Duk* duk, const char* func)
{
    duk_context* ctx = duk->ctx;
    duk_int_t rc = 0;

    // Start a zero timer which will call our function from the event loop.
    duk_push_sprintf(ctx, "setTimeout(function() { %s(); }, 0);", func);
    rc = duk_peval(ctx);
    if (rc != DUK_EXEC_SUCCESS) {
        croak("Could not eval JS event loop dispatcher for %s: %d - %s\n",
              func, rc, duk_safe_to_string(ctx, -1));
    }
    duk_pop(ctx); // pop result / error

    // Launch eventloop; this call only returns after the eventloop terminates.
    rc = duk_safe_call(ctx, eventloop_run, duk, 0 /*nargs*/, 1 /*nrets*/);
    if (rc != DUK_EXEC_SUCCESS) {
        croak("JS event loop run failed: %d - %s\n",
              rc, duk_safe_to_string(ctx, -1));
    }
    duk_pop(ctx);

    return 0;
}
