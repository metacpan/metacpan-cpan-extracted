#ifndef PL_SANDBOX_H
#define PL_SANDBOX_H

#include "pl_duk.h"

void* pl_sandbox_alloc(void* udata, duk_size_t size);
void* pl_sandbox_realloc(void* udata, void* ptr, duk_size_t size);
void pl_sandbox_free(void* udata, void* ptr);

int pl_exec_timeout(void *udata);

#endif
