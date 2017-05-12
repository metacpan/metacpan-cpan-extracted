/*
 * A Unit Vector to 16-bit word conversion algorithm
 * based on the work of Rafael Baptista (rafael@oroboro.com)
 * - Accuracy improved by Oleg D. (punkfloyd@rocketmail.com)
 * - Adapted to perl XS by Cole Minor (coleminor@hush.ai)
 * 
 * Baptista, Raphael (2000-12-08). "Higher Accuracy Quantized Normals". GameDev.Net LLC.
 * http://www.gamedev.net/page/resources/_/technical/math-and-physics/higher-accuracy-quantized-normals-r1252]
 * Retrieved 2012-01-06.
 *
 */
#include "constants.h"
#include "convert.h"

#include "iltab.gen.c"

unitvec16_t unitvec16_pack(float *n) {
  float x, y, z, w;
  unitvec16_t p;
  unsigned xb, yb;

  p = 0;
  x = n[0];
  y = n[1];
  z = n[2];
  if (x < 0) {
    p |= XSIGN_MASK;
    x = -x;
  }
  if (y < 0) {
    p |= YSIGN_MASK;
    y = -y;
  }
  if (z < 0) {
    p |= ZSIGN_MASK;
    z = -z;
  }

  w = 126.0f / (x + y + z);
  xb = x * w;
  yb = y * w;

  if (xb >= 64) { 
    xb = 127 - xb; 
    yb = 127 - yb; 
  }

  p |= xb << 7;
  p |= yb;
  return p;
}

void unitvec16_unpack(unitvec16_t p, float *n) {
  unsigned xb, yb;
  float w;

  xb = (p & TOP_MASK) >> 7;
  yb = p & BOTTOM_MASK;

  if (xb + yb >= 127) { 
    xb = 127 - xb; 
    yb = 127 - yb; 
  }

  w = iltab[p & ~SIGN_MASK];
  n[0] = w * (float) xb;
  n[1] = w * (float) yb;
  n[2] = w * (float) (126 - xb - yb);

  if (p & XSIGN_MASK)
    n[0] = -n[0];
  if (p & YSIGN_MASK)
    n[1] = -n[1];
  if (p & ZSIGN_MASK)
    n[2] = -n[2];
}
