/* mds_render_html.h — SAX consumer that writes HTML to an mds_buf. */
#ifndef MDS_RENDER_HTML_H
#define MDS_RENDER_HTML_H

#include "mds_ir.h"
#include "mds_buf.h"

/* Populates *cb so it writes HTML into the supplied buffer.
 * `ud_storage` is opaque caller-provided state of size >= sizeof(void*)*4. */
void mds_render_html_install(mds_callbacks* cb, void** ud_out, mds_buf* buf,
                             unsigned flags);

/* Tier E.1 — query the renderer's per-parse footnote usage table in
 * first-use order. Index `i` is 0-based. Returns 1 and populates the
 * out-params if an entry exists at that index, else 0. Used by the
 * block scanner to emit the footnotes section in first-reference
 * order (not source-definition order). */
int mds_render_html_used_footnote(void* ud, size_t i,
                                  const char** label_out,
                                  size_t* label_len_out);

#endif
