#ifndef HAMT_ALLOC_H
#define HAMT_ALLOC_H

/* Every allocation the core makes goes through these two. The size is passed
 * to the free as well, so size-class freelists can sit behind the same pair
 * without a caller changing.
 *
 * HAMT_ALLOC returns NULL when there is no memory, and every caller hands
 * that upward with nothing leaked and its input untouched. */

#ifndef HAMT_ALLOC
#  define HAMT_ALLOC(cx, bytes)   malloc(bytes)
#endif

/* The XS defines the pair over the pool in hamt_pool.h, which is why the
 * size given to the free must be the size that was allocated. */
#ifndef HAMT_FREE
#  define HAMT_FREE(cx, p, bytes) free(p)
#endif

#endif
