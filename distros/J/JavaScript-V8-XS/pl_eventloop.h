#ifndef PL_EVENTLOOP_H_
#define PL_EVENTLOOP_H_

#include "V8Context.h"

int eventloop_run(V8Context* ctx);

int pl_register_eventloop_functions(V8Context* ctx);

#endif
