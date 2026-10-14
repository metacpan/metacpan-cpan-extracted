#ifndef HAMT_POOL_H
#define HAMT_POOL_H

/* Freed blocks kept by size, so the next allocation of that size is a pop
 * and not a trip to the C library. An update frees about as many small
 * blocks as it allocates, of the same few sizes, which is the case this is
 * for.
 *
 * Sizes are rounded up to a multiple of sixteen bytes and each multiple has
 * a list, linked through the first word of every free block. A list holds a
 * fixed number of blocks at most, so a large structure being freed goes back
 * to the C library and is not pinned here. A block too large for any list is
 * allocated and freed directly.
 *
 * A pool is used by one thread. Nothing here locks.
 *
 * The caller must free a block with the size it allocated it with: that is
 * how the block finds its list. */

#ifndef HAMT_POOL_RAW_ALLOC
#  define HAMT_POOL_RAW_ALLOC(bytes)   malloc(bytes)
#  define HAMT_POOL_RAW_FREE(p, bytes) free(p)
#endif

#define HAMT_POOL_GRAIN   16
#define HAMT_POOL_CLASSES 20      /* lists for 16, 32, ... 304 bytes */
#ifndef HAMT_POOL_KEEP
#  define HAMT_POOL_KEEP  128     /* blocks a list holds at most */
#endif

typedef struct hamt_pool {
    int      open;
    uint32_t n[HAMT_POOL_CLASSES];
    void    *head[HAMT_POOL_CLASSES];
} hamt_pool;

#define HAMT_POOL_CLASS(bytes) (((size_t)(bytes) + HAMT_POOL_GRAIN - 1) / HAMT_POOL_GRAIN)

static void hamt_pool_open(hamt_pool *pl) {
    memset(pl, 0, sizeof(*pl));
    pl->open = 1;
}

/* `pl` may be NULL, for a caller that has no pool to use: the block is then
 * allocated as a pooled one would be, so it may be freed into any pool. */
static void *hamt_pool_alloc(hamt_pool *pl, size_t bytes) {
    size_t c = HAMT_POOL_CLASS(bytes);

    if (c == 0 || c >= HAMT_POOL_CLASSES) return HAMT_POOL_RAW_ALLOC(bytes);
    if (pl && pl->head[c]) {
        void *p = pl->head[c];
        memcpy(&pl->head[c], p, sizeof(void *));
        pl->n[c]--;
        return p;
    }
    return HAMT_POOL_RAW_ALLOC(c * HAMT_POOL_GRAIN);
}

static void hamt_pool_free(hamt_pool *pl, void *p, size_t bytes) {
    size_t c = HAMT_POOL_CLASS(bytes);

    if (c == 0 || c >= HAMT_POOL_CLASSES) { HAMT_POOL_RAW_FREE(p, bytes); return; }
    if (pl && pl->open && pl->n[c] < HAMT_POOL_KEEP) {
        memcpy(p, &pl->head[c], sizeof(void *));
        pl->head[c] = p;
        pl->n[c]++;
        return;
    }
    HAMT_POOL_RAW_FREE(p, c * HAMT_POOL_GRAIN);
}

/* Give everything back and keep nothing from here on. Blocks handed out
 * before this are still freed through hamt_pool_free. */
static void hamt_pool_close(hamt_pool *pl) {
    size_t c;
    pl->open = 0;
    for (c = 0; c < HAMT_POOL_CLASSES; c++) {
        while (pl->head[c]) {
            void *p = pl->head[c];
            memcpy(&pl->head[c], p, sizeof(void *));
            HAMT_POOL_RAW_FREE(p, c * HAMT_POOL_GRAIN);
        }
        pl->n[c] = 0;
    }
}

/* Blocks waiting in the lists. */
static size_t hamt_pool_held(const hamt_pool *pl) {
    size_t c, n = 0;
    for (c = 0; c < HAMT_POOL_CLASSES; c++) n += pl->n[c];
    return n;
}

#endif
