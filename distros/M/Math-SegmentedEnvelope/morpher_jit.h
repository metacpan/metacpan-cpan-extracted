#ifndef MORPHER_JIT_H
#define MORPHER_JIT_H

#include <stddef.h>

typedef double (*jit_morpher_fn)(double);

enum {
    JIT_BACKEND_NONE = 0,
    JIT_BACKEND_TCC,
    JIT_BACKEND_X86
};

typedef struct {
    jit_morpher_fn fn;
    int backend;
    void *state;       /* backend-specific: TCCState* or mmap'd page */
    size_t state_size; /* for mmap backend */
} jit_morpher;

/* Compile a math expression with variable 't' into native code.
 * Tries TCC first, then hand-rolled x86-64 JIT, returns NULL on failure.
 * Caller must free with jit_morpher_free(). */
jit_morpher *jit_morpher_compile(const char *formula);

void jit_morpher_free(jit_morpher *jit);

/* Returns the name of the active JIT backend ("tcc", "x86", or "none") */
const char *jit_backend_name(const jit_morpher *jit);

#endif
