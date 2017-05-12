#ifndef mh_bitfield_h_
#define mh_bitfield_h_

#include <stdint.h>
#include <math.h>

typedef uint32_t* mh_bitfield_t;

#define MH_BITFIELD_MALLOC(nbits) (mh_bitfield_t)malloc(sizeof(uint32_t) * (unsigned int)ceilf((float)nbits/32))
#define MH_BITFIELD_CALLOC(nbits) (mh_bitfield_t)calloc((unsigned int)ceilf((float)nbits/32), sizeof(uint32_t))
#define MH_BITFIELD_FREE(bf) free(bf)
#define MH_BITFIELD_COPY(dest, src, nbits) \
  memcpy((dest), (src), (unsigned int)ceilf((float)nbits/32) * sizeof(uint32_t));

/* internal */
#define MH_BITFIELD_INTPOS(bf,pos) (bf[ (unsigned int)((unsigned int)(pos)/32) ])
#define MH_BITFIELD_BITPOS(pos) (1<<((unsigned int)(pos) % 32))

#define MH_BITFIELD_SET(bf, pos)    MH_BITFIELD_INTPOS(bf,pos) |= MH_BITFIELD_BITPOS(pos)
#define MH_BITFIELD_UNSET(bf, pos)  MH_BITFIELD_INTPOS(bf,pos) &= MH_BITFIELD_BITPOS(pos)
#define MH_BITFIELD_TOGGLE(bf, pos) MH_BITFIELD_INTPOS(bf,pos) ^= MH_BITFIELD_BITPOS(pos)
#define MH_BITFIELD_GET(bf, pos)    MH_BITFIELD_INTPOS(bf,pos) &  MH_BITFIELD_BITPOS(pos)

#endif
