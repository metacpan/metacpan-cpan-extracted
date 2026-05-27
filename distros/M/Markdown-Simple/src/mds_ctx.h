/* mds_ctx.h — per-parse state passed through the scanner.
 * Owns the arena and a (future) link-ref hash table. */
#ifndef MDS_CTX_H
#define MDS_CTX_H

#include <stddef.h>
#include <stdint.h>
#include "mds_arena.h"
#include "mds_compiler.h"
#include "mds_ir.h"

/* Forward decl for the link-ref table. */
typedef struct mds_linkref_tab mds_linkref_tab;
/* Forward decl for GFM footnote table (Tier E.1). */
typedef struct mds_footnote_tab mds_footnote_tab;

/* Field order is tuned so the hot path (scanner +
 * callback dispatch) lives in the first two cache lines:
 *   line 0 (0..63):  input, len, line_offsets, n_lines, ud,
 *                    cb.enter_block + cb.leave_block
 *   line 1 (64..127): cb.{enter_inline,leave_inline,text,raw},
 *                     scratch, flags, line_idx_overflow, refs
 *   line 2+ (cold):  arena (64 B; only touched by the allocator)
 * Reordering matters because cb.text/raw + ud are hit per text run,
 * input/len/line_offsets are read in scan_line, and the arena is only
 * walked on a slow-path miss. */
typedef struct mds_ctx {
    /* --- hot: scanner / per-text-run --- */
    const char*       input;
    size_t            len;
    const uint32_t*   line_offsets;
    size_t            n_lines;
    void*             ud;
    mds_callbacks     cb;

    /* --- warm: borrowed scratch and per-parse misc --- */
    void*             scratch;
    unsigned          flags;
    int               line_idx_overflow;
    mds_linkref_tab*  refs;
    mds_footnote_tab* footnotes;     /* Tier E.1, lazy alloc */

    /* --- cold: only touched by the allocator path --- */
    mds_arena         arena;
} mds_ctx;

#endif
