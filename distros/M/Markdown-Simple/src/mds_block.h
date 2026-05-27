#ifndef MDS_BLOCK_H
#define MDS_BLOCK_H
#include <stddef.h>
#include "mds_ctx.h"

/* Reusable scratch buffers for the block scanner.
 * The block scanner used to malloc/realloc these on every parse and
 * free() them at end. With a persistent mds_session the
 * caller can hold one of these structs across many renders so that
 * realloc traffic is amortised. ctx->scratch borrows it (non-owning);
 * mds_block_scan resets the lengths at start and end but leaves the
 * capacities and pointers intact. Initialise to zero, then call
 * mds_block_scratch_free when done. */
typedef struct mds_block_scratch {
    char*   para;        size_t para_cap;
    char*   code_body;   size_t code_cap;
    char*   html_body;   size_t html_cap;
    void*   evbuf;       size_t ev_cap;     /* opaque: ev_rec* internally */
    char*   bytepool;    size_t bp_cap;
} mds_block_scratch;

void mds_block_scratch_free(mds_block_scratch* s);

void mds_block_scan(mds_ctx* ctx);
#endif
