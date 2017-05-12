#define MM_PRIVATE
#include "mm.h"
/*
 * Insert a chunk to the list of free chunks. Algorithm used is:
 * Insert in sorted manner to the list and merge with previous
 * and/or next chunk when possible to form larger chunks out of
 * smaller ones.
 */
static void mma_insert_chunk(MM *mm, mem_chunk *mcInsert)
{
    mem_chunk *mc;
    mem_chunk *mcPrev;
    mem_chunk *mcPrevPrev;
    mem_chunk *mcNext;

/*    if (!mm_core_lock((void *)mm, MM_LOCK_RW))
      return; */
    mc = &(mm->mp_freechunks);
    mcPrevPrev = mc;
    while (mc->mc_u.mc_next != NULL && (char *)(mc->mc_u.mc_next) < (char *)mcInsert) {
        mcPrevPrev = mc;
        mc = mc->mc_u.mc_next;
    }
    mcPrev = mc;
    mcNext = mc->mc_u.mc_next;
    if (mcPrev == mcInsert || mcNext == mcInsert) {
/*        mm_core_unlock((void *)mm); */
        ERR(MM_ERR_ALLOC, "chunk of memory already in free list");
        return;
    }
    if ((char *)mcPrev+(mcPrev->mc_size) == (char *)mcInsert &&
        (mcNext != NULL && (char *)mcInsert+(mcInsert->mc_size) == (char *)mcNext)) {
        /* merge with previous and next chunk */
        mcPrev->mc_size += mcInsert->mc_size + mcNext->mc_size;
        mcPrev->mc_u.mc_next = mcNext->mc_u.mc_next;
        mm->mp_freechunks.mc_usize -= 1;
    }
    else if ((char *)mcPrev+(mcPrev->mc_size) == (char *)mcInsert &&
             (char *)mcInsert+(mcInsert->mc_size) == ((char *)mm + mm->mp_offset)) {
        /* merge with previous and spare block (to increase spare area) */
        mcPrevPrev->mc_u.mc_next = mcPrev->mc_u.mc_next;
        mm->mp_offset -= (mcInsert->mc_size + mcPrev->mc_size);
        mm->mp_freechunks.mc_usize -= 1;
    }
    else if ((char *)mcPrev+(mcPrev->mc_size) == (char *)mcInsert) {
        /* merge with previous chunk */
        mcPrev->mc_size += mcInsert->mc_size;
    }
    else if (mcNext != NULL && (char *)mcInsert+(mcInsert->mc_size) == (char *)mcNext) {
        /* merge with next chunk */
        mcInsert->mc_size += mcNext->mc_size;
        mcInsert->mc_u.mc_next = mcNext->mc_u.mc_next;
        mcPrev->mc_u.mc_next = mcInsert;
    }
    else if ((char *)mcInsert+(mcInsert->mc_size) == ((char *)mm + mm->mp_offset)) {
        /* merge with spare block (to increase spare area) */
        mm->mp_offset -= mcInsert->mc_size;
    }
    else {
        /* no merging possible, so insert as new chunk */
        mcInsert->mc_u.mc_next = mcNext;
        mcPrev->mc_u.mc_next = mcInsert;
        mm->mp_freechunks.mc_usize += 1;
    }
/*    mm_core_unlock((void *)mm); */
    return;
}

/*
 * Retrieve a chunk from the list of free chunks.  Algorithm used
 * is: Search for minimal-sized chunk which is larger or equal
 * than the request size. But when the retrieved chunk is still a
 * lot larger than the requested size, split out the requested
 * size to not waste memory.
 */
static mem_chunk *mma_retrieve_chunk(MM *mm, size_t size)
{
    mem_chunk *mc;
    mem_chunk **pmcMin;
    mem_chunk *mcRes;
    size_t sMin;
    size_t s;

    if (size == 0)
        return NULL;
    if (mm->mp_freechunks.mc_usize == 0)
        return NULL;
/*    if (!mm_core_lock((void *)mm, MM_LOCK_RW))
        return NULL; */

    /* find best-fitting chunk */
    pmcMin = NULL;
    sMin = mm->mp_size; /* initialize with maximum possible */
    mc = &(mm->mp_freechunks);
    while (mc->mc_u.mc_next != NULL) {
        s = mc->mc_u.mc_next->mc_size;
        if (s >= size && s < sMin) {
            pmcMin = &(mc->mc_u.mc_next);
            sMin = s;
            if (s == size)
                break;
        }
        mc = mc->mc_u.mc_next;
    }

    /* create result chunk */
    if (pmcMin == NULL)
        mcRes = NULL;
    else {
        mcRes = *pmcMin;
        /*** next line causes discrepancies in mm_available ***/
        if (mcRes->mc_size >= (size + min_of(2*size,128))) {
            /* split out in part */
            s = mcRes->mc_size - size;
            mcRes->mc_size = size;
            /* add back remaining chunk part as new chunk */
            mc = (mem_chunk *)((char *)mcRes + size);
            mc->mc_size = s;
            mc->mc_u.mc_next = mcRes->mc_u.mc_next;
            *pmcMin = mc;
        }
        else {
            /* split out as a whole */
            *pmcMin = mcRes->mc_u.mc_next;
            mm->mp_freechunks.mc_usize--;
        }
    }

/*    mm_core_unlock((void *)mm); */
    return mcRes;
}

/*
 * Allocate a chunk of memory
 */
void *mma_malloc(MM *mm, size_t usize)
{
    mem_chunk *mc;
    size_t size;
    void *vp;

    if (mm == NULL || usize == 0)
        return NULL;
    size = mm_core_align2word(SIZEOF_mem_chunk+usize);
    if ((mc = mma_retrieve_chunk(mm, size)) != NULL) {
        mc->mc_usize = usize;
        return &(mc->mc_u.mc_base.mw_cp);
    }
/*    if (!mm_core_lock((void *)mm, MM_LOCK_RW))
        return NULL; */
    if ((mm->mp_size - mm->mp_offset) < size) {
/*        mm_core_unlock((void *)mm); */
        ERR(MM_ERR_ALLOC, "out of memory");
        errno = ENOMEM;
        return NULL;
    }
    mc = (mem_chunk *)((char *)mm + mm->mp_offset);
    mc->mc_size  = size;
    mc->mc_usize = usize;
    vp = (void *)&(mc->mc_u.mc_base.mw_cp);
    mm->mp_offset += size;
/*    mm_core_unlock((void *)mm); */
    return vp;
}

/*
 * Free a chunk of memory
 */
void mma_free(MM *mm, void *ptr)
{
    mem_chunk *mc;

    if (mm == NULL || ptr == NULL)
        return;
    mc = (mem_chunk *)((char *)ptr - SIZEOF_mem_chunk);
    mma_insert_chunk(mm, mc);
    return;
}

/*
 * Allocate and initialize a chunk of memory
 */
void *mma_calloc(MM *mm, size_t number, size_t usize)
{
    void *vp;

    if (mm == NULL || number*usize == 0)
        return NULL;
    if ((vp = mma_malloc(mm, number*usize)) == NULL)
        return NULL;
    memset(vp, 0, number*usize);
    return vp;
}

/*
 * Return whether an existing memory chunk has the same allocation
 *  as a requested new size, and if so return 1 and store the new size
 */
int mma_sizeok (void *ptr, const size_t usize) {
    mem_chunk *mc;

    if (ptr == NULL) return 0;
    mc = (mem_chunk *)((char *)ptr - SIZEOF_mem_chunk);

    if (usize >  mc->mc_size - SIZEOF_mem_chunk
     || usize <= mc->mc_size - SIZEOF_mem_chunk - sizeof(union mem_chunk_mc_u)) return 0;

    mc->mc_usize = usize;
    return 1;
}

/*
 * Return allocation block size and allocation base size
   inline is removed if necessary by Makefile.PL */

inline int mma_alloc_mask(void) {return sizeof(union mem_chunk_mc_u)-1;}
inline int mma_alloc_base(void) {return SIZEOF_mem_chunk;}
