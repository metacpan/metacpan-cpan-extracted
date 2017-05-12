#ifndef GEOHEX3_POW_H
#define GEOHEX3_POW_H

#include "geohex3/macro.h"
#include <math.h>
#include <stdint.h>

static inline uint64_t geohex_pow3(uint8_t y) {
  if (y > 18) {
    return (uint64_t)powl(3.0L, (long double)y);
  }
  else {
    // for performance :)
    static const uint64_t GEOHEX3_CALCED_POW3[] = {
      GEOHEX3_MACRO_POW(3ULL,  0),
      GEOHEX3_MACRO_POW(3ULL,  1),
      GEOHEX3_MACRO_POW(3ULL,  2),
      GEOHEX3_MACRO_POW(3ULL,  3),
      GEOHEX3_MACRO_POW(3ULL,  4),
      GEOHEX3_MACRO_POW(3ULL,  5),
      GEOHEX3_MACRO_POW(3ULL,  6),
      GEOHEX3_MACRO_POW(3ULL,  7),
      GEOHEX3_MACRO_POW(3ULL,  8),
      GEOHEX3_MACRO_POW(3ULL,  9),
      GEOHEX3_MACRO_POW(3ULL, 10),
      GEOHEX3_MACRO_POW(3ULL, 11),
      GEOHEX3_MACRO_POW(3ULL, 12),
      GEOHEX3_MACRO_POW(3ULL, 13),
      GEOHEX3_MACRO_POW(3ULL, 14),
      GEOHEX3_MACRO_POW(3ULL, 15),
      GEOHEX3_MACRO_POW(3ULL, 16),
      GEOHEX3_MACRO_POW(3ULL, 17),
      GEOHEX3_MACRO_POW(3ULL, 18)
    };
    return GEOHEX3_CALCED_POW3[y];
  }
}

static inline uint64_t geohex_pow10(uint8_t y) {
  if (y > 17) {
    return (uint64_t)powl(10.0L, (long double)y);
  }
  else {
    // for performance :)
    static const uint64_t GEOHEX3_CALCED_POW10[] = {
      GEOHEX3_MACRO_POW(10ULL,  0),
      GEOHEX3_MACRO_POW(10ULL,  1),
      GEOHEX3_MACRO_POW(10ULL,  2),
      GEOHEX3_MACRO_POW(10ULL,  3),
      GEOHEX3_MACRO_POW(10ULL,  4),
      GEOHEX3_MACRO_POW(10ULL,  5),
      GEOHEX3_MACRO_POW(10ULL,  6),
      GEOHEX3_MACRO_POW(10ULL,  7),
      GEOHEX3_MACRO_POW(10ULL,  8),
      GEOHEX3_MACRO_POW(10ULL,  9),
      GEOHEX3_MACRO_POW(10ULL, 10),
      GEOHEX3_MACRO_POW(10ULL, 11),
      GEOHEX3_MACRO_POW(10ULL, 12),
      GEOHEX3_MACRO_POW(10ULL, 13),
      GEOHEX3_MACRO_POW(10ULL, 14),
      GEOHEX3_MACRO_POW(10ULL, 15),
      GEOHEX3_MACRO_POW(10ULL, 16),
      GEOHEX3_MACRO_POW(10ULL, 17)
    };
    return GEOHEX3_CALCED_POW10[y];
  }
}

#endif
