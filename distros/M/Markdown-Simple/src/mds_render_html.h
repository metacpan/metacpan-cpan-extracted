/* mds_render_html.h — SAX consumer that writes HTML to an mds_buf. */
#ifndef MDS_RENDER_HTML_H
#define MDS_RENDER_HTML_H

#include "mds_ir.h"
#include "mds_buf.h"

/* Populates *cb so it writes HTML into the supplied buffer.
 * `ud_storage` is opaque caller-provided state of size >= sizeof(void*)*4. */
void mds_render_html_install(mds_callbacks* cb, void** ud_out, mds_buf* buf,
                             unsigned flags);

/* Release the heap buffers the renderer grew during a parse: the alt-text
 * accumulator, the autolink coalescing buffer, the highlight accumulator and
 * the three parallel footnote tables. The state itself is caller-owned
 * storage (a stack blob in mds.c), so nothing frees these on its own, and
 * every one of them is realloc'd on demand rather than arena-allocated.
 *
 * Must be called on every exit path from a parse, including the early
 * malformed-UTF-8 return. Idempotent: it NULLs what it frees. */
void mds_render_html_cleanup(void* ud);

/* Tier E.1 — query the renderer's per-parse footnote usage table in
 * first-use order. Index `i` is 0-based. Returns 1 and populates the
 * out-params if an entry exists at that index, else 0. Used by the
 * block scanner to emit the footnotes section in first-reference
 * order (not source-definition order). */
int mds_render_html_used_footnote(void* ud, size_t i,
                                  const char** label_out,
                                  size_t* label_len_out);

#endif
