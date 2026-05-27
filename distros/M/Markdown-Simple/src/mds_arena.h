/* mds_arena.h — bump-pointer arena allocator.
 *
 * Pages of MDS_ARENA_PAGE bytes chained singly. Allocations larger than
 * MDS_ARENA_BIG go in their own dedicated page so we don't waste space.
 * No per-allocation free; reset() rewinds the head page, free() releases
 * every page.
 */
#ifndef MDS_ARENA_H
#define MDS_ARENA_H

#include <stddef.h>
#include <stdint.h>

#define MDS_ARENA_PAGE  (64u * 1024u)
#define MDS_ARENA_BIG   (MDS_ARENA_PAGE / 4u)
#define MDS_ARENA_ALIGN 16u

typedef struct mds_arena_page {
    struct mds_arena_page* next;
    size_t                 used;       /* bytes consumed in `data` */
    size_t                 cap;        /* capacity of `data` */
    /* data follows inline; flexible array member */
    unsigned char          data[1];
} mds_arena_page;

typedef struct mds_arena {
    mds_arena_page* head;              /* current page being filled */
    mds_arena_page* big;               /* singly-linked oversize pages */
    size_t          total_alloc;       /* lifetime byte count, for tests */
    /* Page profiling counters (cheap: only updated on
     * page allocation, not per byte). All counters are reset by
     * mds_arena_reset and mds_arena_free. */
    size_t          page_count;        /* head-list pages allocated */
    size_t          big_count;         /* oversize pages allocated */
    size_t          big_bytes;         /* sum of `aligned` for big allocs */
} mds_arena;

/* Snapshot of an arena's profile, taken just before reset/free.
 * head_used_last is the byte count consumed in the current head page
 * at snapshot time; head_cap_last is its capacity. Combined with
 * page_count this is enough to compute average page fill. */
typedef struct mds_arena_profile {
    size_t total_alloc;
    size_t page_count;
    size_t big_count;
    size_t big_bytes;
    size_t head_used_last;
    size_t head_cap_last;
} mds_arena_profile;

void  mds_arena_init(mds_arena* a);
void* mds_arena_alloc(mds_arena* a, size_t n);
void  mds_arena_reset(mds_arena* a);   /* rewind, keep first page */
void  mds_arena_free(mds_arena* a);    /* release everything */
void  mds_arena_snapshot(const mds_arena* a, mds_arena_profile* out);

#endif
