#ifndef XORSHIFT_H
#define XORSHIFT_H

#include "EXTERN.h"
#include "perl.h"

#if defined(_MSC_VER) && _MSC_VER < 1600
# define _UI32_MAX UINT32_MAX
  typedef unsigned __int32 uint32_t;
#else
# include <stdint.h>
#endif

typedef struct {
  uint32_t x, y, z, w;
} xorshift_t;

bool xorshift_srand(xorshift_t *prng,
                    uint32_t x, uint32_t y, uint32_t z, uint32_t w);
uint32_t xorshift_irand(xorshift_t *prng);
double xorshift_rand(xorshift_t *prng, double upper_limit);

#endif XORSHIFT_H
