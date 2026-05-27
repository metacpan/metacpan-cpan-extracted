/* mds_footnote.h — GFM footnote definitions table (Tier E.1).
 *
 * Records `[^label]: body` definitions seen at column 0 during block
 * parsing. The body bytes are arena-copied so they survive the
 * paragraph buffer being reused. At document end the block scanner
 * synthesises FOOTNOTES_SECTION + FOOTNOTE_DEF events; the renderer
 * filters out unused defs by maintaining its own usage set built from
 * INL_FOOTNOTE_REF callbacks fired earlier in the same flush.
 */
#ifndef MDS_FOOTNOTE_H
#define MDS_FOOTNOTE_H

#include <stddef.h>
#include "mds_arena.h"

typedef struct {
    const char* label;     size_t llen;     /* raw label (case-preserved) */
    const char* key;       size_t klen;     /* normalised key for lookup */
    const char* body;      size_t blen;     /* def body bytes (inline scan input) */
} mds_footnote;

struct mds_footnote_tab {
    mds_footnote* entries;
    size_t        len;
    size_t        cap;
    mds_arena*    arena;
};

void   mds_footnote_init(struct mds_footnote_tab* t, mds_arena* a);
/* Insert if not present. Returns 1 if inserted, 0 if duplicate label. */
int    mds_footnote_add(struct mds_footnote_tab* t,
                        const char* label, size_t llen,
                        const char* body,  size_t blen);
const mds_footnote* mds_footnote_get(const struct mds_footnote_tab* t,
                                     const char* label, size_t llen);

#endif
