#ifndef PL_CONSOLE_H_
#define PL_CONSOLE_H_

#include "V8Context.h"

int pl_register_console_functions(V8Context* ctx);
int pl_show_error(V8Context* ctx, const char* fmt, ...);

#endif
