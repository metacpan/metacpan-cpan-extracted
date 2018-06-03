#ifndef PL_EVENTLOOP_H
#define PL_EVENTLOOP_H

#include "pl_duk.h"

int pl_register_eventloop(Duk* duk);
int pl_run_function_in_event_loop(Duk* duk, const char* func);

#endif
