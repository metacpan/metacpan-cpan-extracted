#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <stdint.h>

/* This method is faster than the OpenEXR implementation (very often
 * used, eg. in Ogre), with the additional benefit of rounding, inspired
 * by James Tursa's half-precision code. */
static inline uint16_t _float_to_half(uint32_t x) {
  uint16_t bits = (x >> 16) & 0x8000;
  uint16_t m = (x >> 12) & 0x07ff;
  unsigned int e = (x >> 23) & 0xff;
  if (e < 103)
    return bits;
  if (e > 142) {
    bits |= 0x7c00u;
    bits |= e == 255 && (x & 0x007fffffu);
    return bits;
  }
  if (e < 113) {
    m |= 0x0800u;
    bits |= (m >> (114 - e)) + ((m >> (113 - e)) & 1);
    return bits;
  }
  bits |= ((e - 112) << 10) | (m >> 1);
  bits += m & 1;
  return bits;
}

static int const shifttable[32] = {
  23, 14, 22, 0, 0, 0, 21, 0, 0, 0, 0, 0, 0, 0, 20, 0,
  15, 0, 0, 0, 0, 0, 0, 16, 0, 0, 0, 17, 0, 18, 19, 0,
};
static uint32_t const shiftmagic = 0x07c4acddu;

/* This algorithm is similar to the OpenEXR implementation, except it
 * uses branchless code in the denormal path. This is slower than a
 * table version, but will be more friendly to the cache for occasional
 * uses. */
static inline uint32_t _half_to_float(uint16_t x) {
  uint32_t s = (x & 0x8000u) << 16;
  if ((x & 0x7fffu) == 0)
    return (uint32_t)x << 16;
  uint32_t e = x & 0x7c00u;
  uint32_t m = x & 0x03ffu;
  if (e == 0) {
    uint32_t v = m | (m >> 1);
    v |= v >> 2;
    v |= v >> 4;
    v |= v >> 8;
    e = shifttable[(v * shiftmagic) >> 27];
    return s | (((125 - e) << 23) + (m << e));
  }
  if (e == 0x7c00u) {
    if (m == 0)
      return s | 0x7f800000u;
    return s | 0x7fc00000u;
  }
  return s | (((e >> 10) + 112) << 23) | (m << 13);
}

union fbits {
  float f;
  uint32_t x;
};

MODULE = Games::EternalLands::Binary::Float16		PACKAGE = Games::EternalLands::Binary::Float16		

unsigned short
pack_float16(v)
    float v
  CODE:
    union fbits u;
    u.f = v;
    RETVAL = _float_to_half(u.x);
  OUTPUT:
    RETVAL

float
unpack_float16(v)
    unsigned short v
  CODE:
    union fbits u;
    u.x = _half_to_float(v);
    RETVAL = u.f;
  OUTPUT:
    RETVAL
