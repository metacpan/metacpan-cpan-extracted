#ifndef PL_NATIVE_H_
#define PL_NATIVE_H_

#include "V8Context.h"

int pl_register_native_functions(V8Context* ctx, Local<ObjectTemplate>& object_template);

#endif
