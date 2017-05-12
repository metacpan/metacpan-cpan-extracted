/* mma_alloc.h: included in MMA.xs to provide prototypes for mma_alloc.c */

#ifndef _MMA_ALLOC_H_
#define _MMA_ALLOC_H_

void *mma_calloc(MM *, size_t, size_t);
void *mma_malloc(MM *, size_t);
void  mma_free  (MM *, void *);
int   mma_sizeok (void *ptr, const size_t usize);

/* inline is removed if necessary by Makefile.PL */
inline int mma_alloc_mask(void);
inline int mma_alloc_base(void);
#endif /* _MMA_ALLOC_H_ */
