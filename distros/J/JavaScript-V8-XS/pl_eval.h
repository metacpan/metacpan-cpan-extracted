#ifndef PL_EVAL_H
#define PL_EVAL_H

#include <v8.h>
#include "pl_config.h"
#include "ppport.h"

using namespace v8;
class V8Context;

SV* pl_eval(pTHX_ V8Context* ctx, const char* code, const char* file = 0);
int pl_run_function(V8Context* ctx, Persistent<Function>& func);

#endif
