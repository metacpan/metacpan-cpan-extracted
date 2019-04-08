#include <stdio.h>
#include <stdlib.h>
#include "pl_util.h"
#include "pl_sandbox.h"
#include "ppport.h"

#define SANDBOX_DEBUG_MEMORY   0
#define SANDBOX_DEBUG_RUNTIME  0

#if defined(SANDBOX_DEBUG_MEMORY) && SANDBOX_DEBUG_MEMORY > 0
#define SANDBOX_DUMP_MEMORY(duk) do { sandbox_dump_memstate(duk); } while (0)
#else
#define SANDBOX_DUMP_MEMORY(duk) do {} while (0)
#endif

#if defined(SANDBOX_DEBUG_RUNTIME) && SANDBOX_DEBUG_RUNTIME > 0
#define SANDBOX_DUMP_RUNTIME(duk) do { sandbox_dump_timestate(duk); } while (0)
#else
#define SANDBOX_DUMP_RUNTIME(duk) do {} while (0)
#endif

/*
 * Memory allocator which backs to standard library memory functions but keeps
 * a small header to track current allocation size.
 */

typedef struct {
    /*
     * The double value in the union is there to ensure alignment is good for
     * IEEE doubles too.  In many 32-bit environments 4 bytes would be
     * sufficiently aligned and the double value is unnecessary.
     */
    union {
        size_t sz;
        double d;
    } u;
} alloc_hdr;

static void sandbox_error(size_t size, const char* func)
{
    dTHX;
    PerlIO_printf(PerlIO_stderr(), "duktape sandbox maximum allocation size reached, %ld requested in %s\n",
                  (long) size, func);
}

#if defined(SANDBOX_DEBUG_MEMORY) && SANDBOX_DEBUG_MEMORY > 0
static void sandbox_dump_memstate(Duk* duk)
{
    dTHX;
    PerlIO_printf(PerlIO_stderr(), "duktape total allocated: %ld\n",
                  (long) duk->total_allocated_bytes);
}
#endif

#if defined(SANDBOX_DEBUG_RUNTIME) && SANDBOX_DEBUG_RUNTIME > 0
static void sandbox_dump_timestate(Duk* duk)
{
    dTHX;
    PerlIO_printf(PerlIO_stderr(), "duktape timeout has happened, limit is %f us\n",
                  duk->max_timeout_us);
}
#endif

void* pl_sandbox_alloc(void* udata, duk_size_t size)
{
    alloc_hdr* hdr;

    Duk* duk = (Duk*) udata;

    if (size == 0) {
        return NULL;
    }

    if (duk->max_allocated_bytes > 0 &&
        duk->total_allocated_bytes + size > duk->max_allocated_bytes) {
        sandbox_error(size, "pl_sandbox_alloc");
        return NULL;
    }

    hdr = (alloc_hdr*) malloc(size + sizeof(alloc_hdr));
    if (!hdr) {
        return NULL;
    }
    hdr->u.sz = size;
    duk->total_allocated_bytes += size;
    SANDBOX_DUMP_MEMORY(duk);
    return (void*) (hdr + 1);
}

void* pl_sandbox_realloc(void* udata, void* ptr, duk_size_t size)
{
    alloc_hdr* hdr;
    size_t old_size;
    void* t;

    Duk* duk = (Duk*) udata;

    if (ptr) {
        hdr = (alloc_hdr*) (((char*) ptr) - sizeof(alloc_hdr));
        old_size = hdr->u.sz;

        if (size == 0) {
            duk->total_allocated_bytes -= old_size;
            free((void*) hdr);
            SANDBOX_DUMP_MEMORY(duk);
            return NULL;
        } else {
            if (duk->max_allocated_bytes > 0 &&
                duk->total_allocated_bytes - old_size + size > duk->max_allocated_bytes) {
                sandbox_error(size, "pl_sandbox_realloc");
                return NULL;
            }

            t = realloc((void*) hdr, size + sizeof(alloc_hdr));
            if (!t) {
                return NULL;
            }
            hdr = (alloc_hdr*) t;
            duk->total_allocated_bytes -= old_size;
            duk->total_allocated_bytes += size;
            hdr->u.sz = size;
            SANDBOX_DUMP_MEMORY(duk);
            return (void*) (hdr + 1);
        }
    } else if (size == 0) {
        return NULL;
    } else {
        if (duk->max_allocated_bytes > 0 &&
            duk->total_allocated_bytes + size > duk->max_allocated_bytes) {
            sandbox_error(size, "pl_sandbox_realloc");
            return NULL;
        }

        hdr = (alloc_hdr*) malloc(size + sizeof(alloc_hdr));
        if (!hdr) {
            return NULL;
        }
        hdr->u.sz = size;
        duk->total_allocated_bytes += size;
        SANDBOX_DUMP_MEMORY(duk);
        return (void*) (hdr + 1);
    }
}

void pl_sandbox_free(void* udata, void* ptr)
{
    alloc_hdr* hdr;

    Duk* duk = (Duk*) udata;

    if (!ptr) {
        return;
    }
    hdr = (alloc_hdr*) (((char*) ptr) - sizeof(alloc_hdr));
    duk->total_allocated_bytes -= hdr->u.sz;
    free((void*) hdr);
    SANDBOX_DUMP_MEMORY(duk);
}

int pl_exec_timeout(void *udata)
{
    Duk* duk = (Duk*) udata;
    double elapsed_us = 0;
    if (duk->max_timeout_us <= 0) {
        return 0;
    }

    elapsed_us = now_us() - duk->eval_start_us;
    if (elapsed_us <= duk->max_timeout_us) {
        return 0;
    }

    SANDBOX_DUMP_RUNTIME(duk);
    return 1;
}
