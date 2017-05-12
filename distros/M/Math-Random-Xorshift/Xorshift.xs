#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <stdlib.h>
#include <time.h>
#include "xorshift.h"

static xorshift_t *xorshift_new(uint32_t x, uint32_t y, uint32_t z, uint32_t w) {
  xorshift_t *prng = malloc(sizeof(xorshift_t));
  xorshift_srand(prng, x, y, z, w);
  return prng;
}

static void *xorshift_DESTROY(xorshift_t *prng) { free(prng); }

static bool xorshift_seeds_ok(uint32_t x, uint32_t y, uint32_t z, uint32_t w) {
  return x != 0 || y != 0 || z != 0 || w != 0;
}

/* Thread support */
#define MY_CXT_KEY "Math::Random::Xorshift::_guts" XS_VERSION

typedef struct {
  xorshift_t prng;
} my_cxt_t;

START_MY_CXT

MODULE = Math::Random::Xorshift  PACKAGE = Math::Random::Xorshift  PREFIX = xorshift_

PROTOTYPES: ENABLE

BOOT:
{
  MY_CXT_INIT;

  MY_CXT.prng.x = (uint32_t)time(NULL);
  MY_CXT.prng.y = MY_CXT.prng.x * 69069;
  MY_CXT.prng.z = MY_CXT.prng.y * 69069;
  MY_CXT.prng.w = MY_CXT.prng.z * 69069;
}

# According to perlxs, default parameter values must be a number, a string
# literal or NO_INIT. So strictly speaking, this declaration is illegal, but
# works.
xorshift_t *
xorshift_new(klass, x = (U32)time(NULL), y = x * 69069, z = y * 69069, w = z * 69069)
  const char *klass;
  U32 x;
  U32 y;
  U32 z;
  U32 w;
INIT:
  if (!xorshift_seeds_ok(x, y, z, w)) {
    Perl_croak(aTHX_ "At least one seed must be non-zero");
  }
CODE:
  RETVAL = xorshift_new(x, y, z, w);
OUTPUT:
  RETVAL

bool
xorshift_srand(x = (U32)time(NULL), y = x * 69069, z = y * 69069, w = z * 69069)
  U32 x;
  U32 y;
  U32 z;
  U32 w;
PROTOTYPE: ;$$$$
PREINIT:
  dMY_CXT;
INIT:
  if (!xorshift_seeds_ok(x, y, z, w)) {
    Perl_croak(aTHX_ "At least one seed must be non-zero");
  }
CODE:
  RETVAL = xorshift_srand(&MY_CXT.prng, x, y, z, w);
OUTPUT:
  RETVAL

U32
xorshift_irand()
PROTOTYPE: 
PREINIT:
  dMY_CXT;
CODE:
  RETVAL = xorshift_irand(&MY_CXT.prng);
OUTPUT:
  RETVAL

double
xorshift_rand(upper_limit = 1.0)
  double upper_limit;
PROTOTYPE: ;$
PREINIT:
  dMY_CXT;
CODE:
  RETVAL = xorshift_rand(&MY_CXT.prng, upper_limit);
OUTPUT:
  RETVAL

MODULE = Math::Random::Xorshift  PACKAGE = Math::Random::Xorshift::_ptr  PREFIX = xorshift_

bool
xorshift_srand(prng, x = (U32)time(NULL), y = x * 69069, z = y * 69069, w = z * 69069)
  xorshift_t *prng;
  U32 x;
  U32 y;
  U32 z;
  U32 w;
INIT:
  if (!xorshift_seeds_ok(x, y, z, w)) {
    Perl_croak(aTHX_ "At least one seed must be non-zero");
  }

U32
xorshift_irand(prng)
  xorshift_t *prng;

double
xorshift_rand(prng, upper_limit = 1.0)
  xorshift_t *prng;
  double upper_limit;

void
xorshift_DESTROY(prng)
  xorshift_t *prng;
