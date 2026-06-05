#include "mds_arena.h"
#include <stdlib.h>
#include <string.h>

static mds_arena_page* page_new(size_t cap) {
    mds_arena_page* p = (mds_arena_page*)malloc(sizeof(mds_arena_page) + cap);
    if (!p) return NULL;
    p->next = NULL;
    p->used = 0;
    p->cap  = cap;
    return p;
}

void mds_arena_init(mds_arena* a) {
    a->head = NULL;
    a->big  = NULL;
    a->total_alloc = 0;
    a->page_count  = 0;
    a->big_count   = 0;
    a->big_bytes   = 0;
}

void* mds_arena_alloc(mds_arena* a, size_t n) {
    /* round up to alignment */
    size_t aligned = (n + (MDS_ARENA_ALIGN - 1)) & ~(size_t)(MDS_ARENA_ALIGN - 1);
    void* out;
    a->total_alloc += aligned;

    if (aligned > MDS_ARENA_BIG) {
        /* oversize: dedicated page, prepended to `big` list */
        mds_arena_page* p = page_new(aligned + MDS_ARENA_ALIGN);
        uintptr_t base;
        size_t pad;
        if (!p) return NULL;
        /* align the start of `data` */
        base = (uintptr_t)p->data;
        pad = (MDS_ARENA_ALIGN - (base & (MDS_ARENA_ALIGN - 1))) & (MDS_ARENA_ALIGN - 1);
        p->used = pad + aligned;
        p->next = a->big;
        a->big  = p;
        a->big_count++;
        a->big_bytes += aligned;
        return p->data + pad;
    }

    if (!a->head || a->head->used + aligned > a->head->cap) {
        mds_arena_page* p = page_new(MDS_ARENA_PAGE);
        uintptr_t base;
        size_t pad;
        if (!p) return NULL;
        /* prime `used` so the first returned pointer is aligned */
        base = (uintptr_t)p->data;
        pad = (MDS_ARENA_ALIGN - (base & (MDS_ARENA_ALIGN - 1))) & (MDS_ARENA_ALIGN - 1);
        p->used = pad;
        p->next = a->head;
        a->head = p;
        a->page_count++;
    }
    out = a->head->data + a->head->used;
    a->head->used += aligned;
    return out;
}

void mds_arena_reset(mds_arena* a) {
    mds_arena_page* b;
    /* free everything except the head page (kept warm); reset head usage */
    if (a->head) {
        mds_arena_page* p = a->head->next;
        uintptr_t base;
        size_t pad;
        while (p) { mds_arena_page* n = p->next; free(p); p = n; }
        a->head->next = NULL;
        /* re-prime to alignment padding so next alloc returns aligned ptr */
        base = (uintptr_t)a->head->data;
        pad = (MDS_ARENA_ALIGN - (base & (MDS_ARENA_ALIGN - 1))) & (MDS_ARENA_ALIGN - 1);
        a->head->used = pad;
    }
    b = a->big;
    while (b) { mds_arena_page* n = b->next; free(b); b = n; }
    a->big = NULL;
    a->total_alloc = 0;
    /* keep `page_count` reflecting the warm page that remains. */
    a->page_count = a->head ? 1 : 0;
    a->big_count  = 0;
    a->big_bytes  = 0;
}

void mds_arena_free(mds_arena* a) {
    mds_arena_page* p = a->head;
    while (p) { mds_arena_page* n = p->next; free(p); p = n; }
    p = a->big;
    while (p) { mds_arena_page* n = p->next; free(p); p = n; }
    a->head = a->big = NULL;
    a->total_alloc = 0;
    a->page_count = 0;
    a->big_count  = 0;
    a->big_bytes  = 0;
}

void mds_arena_snapshot(const mds_arena* a, mds_arena_profile* out) {
    out->total_alloc    = a->total_alloc;
    out->page_count     = a->page_count;
    out->big_count      = a->big_count;
    out->big_bytes      = a->big_bytes;
    out->head_used_last = a->head ? a->head->used : 0;
    out->head_cap_last  = a->head ? a->head->cap  : 0;
}
