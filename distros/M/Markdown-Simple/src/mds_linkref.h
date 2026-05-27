/* mds_linkref.h — link reference definition table (CommonMark §4.7).
 * Open-addressing, arena-backed. Block scanner populates; inline parser consumes.
 */
#ifndef MDS_LINKREF_H
#define MDS_LINKREF_H

#include <stddef.h>
#include "mds_arena.h"

typedef struct {
    const char* key;   size_t klen;   /* normalised label */
    const char* url;   size_t ulen;
    const char* title; size_t tlen;
} mds_linkref;

struct mds_linkref_tab {
    mds_linkref* entries;
    size_t       len;
    size_t       cap;
    mds_arena*   arena;   /* for value strings */
};

void   mds_linkref_init(struct mds_linkref_tab* t, mds_arena* a);
/* Insert if key not present. Returns 1 if inserted, 0 if duplicate. */
int    mds_linkref_add(struct mds_linkref_tab* t,
                       const char* label, size_t llen,
                       const char* url,   size_t ulen,
                       const char* title, size_t tlen);
const mds_linkref* mds_linkref_get(const struct mds_linkref_tab* t,
                                   const char* label, size_t llen);

#endif
