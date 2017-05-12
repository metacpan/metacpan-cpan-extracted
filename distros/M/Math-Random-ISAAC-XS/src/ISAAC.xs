/* ISAAC.xs: Perl interface to the ISAAC Pseudo-Random Number Generator
 *
 * This is a Perl XS interface to the original ISAAC reference implementation,
 * written by Bob Jenkins and released into the public domain circa 1996.
 * See `LICENSE' for details.
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "rand.h"
#include "standard.h"

typedef randctx * Math__Random__ISAAC__XS;

MODULE = Math::Random::ISAAC::XS    PACKAGE = Math::Random::ISAAC::XS

PROTOTYPES: DISABLE

Math::Random::ISAAC::XS
new(...)
  PREINIT:
    int idx;
    randctx *self;
  INIT:
    Newx(self, 1, randctx); /* allocate 1 randctx instance */
    self->randa = self->randb = self->randc = (ub4)0;
  CODE:
    /* Loop through each argument and copy it into randrsl. Copy items from
     * our parameter list first, and then zero-pad thereafter.
     */
    for (idx = 0; idx < RANDSIZ; idx++)
    {
      /* items must be at least 2, or our parameter list is empty */
      if (!(items > 1))
        break;

      /* note: the list begins at ST(1) */
      self->randrsl[idx] = (ub4)SvUV(ST(idx+1));
      items--;
    }

    /* Zero-pad the array, if necessary */
    for (; idx < RANDSIZ; idx++)
    {
      self->randrsl[idx] = (ub4)0;
    }

    randinit(self); /* Initialize using our seed */
    RETVAL = self;
  OUTPUT:
    RETVAL

UV
irand(self)
  Math::Random::ISAAC::XS self
  CODE:
    RETVAL = (UV)randInt(self);
  OUTPUT:
    RETVAL

double
rand(self)
  Math::Random::ISAAC::XS self
  CODE:
    RETVAL = (double)randInt(self) / UINT32_MAX;
  OUTPUT:
    RETVAL

void
DESTROY(self)
  Math::Random::ISAAC::XS self
  CODE:
    Safefree(self);
