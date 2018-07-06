#ifndef PL_EVENTLOOP_H_
#define PL_EVENTLOOP_H_

#include "V8Context.h"

int pl_register_eventloop_functions(V8Context* ctx);
SV* pl_run_function_in_event_loop(pTHX_ V8Context* ctx, const char* func);

#endif
