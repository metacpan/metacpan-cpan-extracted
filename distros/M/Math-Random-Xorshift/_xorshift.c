#include "xorshift.h"

bool xorshift_srand(xorshift_t *prng,
                    uint32_t x, uint32_t y, uint32_t z, uint32_t w) {
  if (x == 0 && y == 0 && z == 0 && w == 0) { return FALSE; }
  prng->x = x;
  prng->y = y;
  prng->z = z;
  prng->w = w;
  return TRUE;
}

uint32_t xorshift_irand(xorshift_t *prng) {
  const uint32_t a = 23, b = 24, c = 3;
  uint32_t tmp = prng->x ^ (prng->x << a);
  prng->x = prng->y;
  prng->y = prng->z;
  prng->z = prng->w;
  prng->w = (prng->w ^ (prng->w >> c)) ^ (tmp ^ (tmp >> b));
  return UINT32_MAX - prng->w;
}

double xorshift_rand(xorshift_t *prng, double upper_limit) {
  return upper_limit * ((double)xorshift_irand(prng) / UINT32_MAX);
}
