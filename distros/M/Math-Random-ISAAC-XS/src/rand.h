/* rand.h: ISAAC interface prototypes and macros
 *
 * This package and its contents are released by the author into the
 * Public Domain, to the full extent permissible by law. For additional
 * information, please see the included `LICENSE' file.
 */

#ifndef RAND_H
#define RAND_H 1

#include "standard.h"

#define RANDSIZL  (8)  /* 8 for crypto, 4 for simulations */
#define RANDSIZ   (1 << RANDSIZL)

/* context of random number generator */
struct randctx {
  ub4 randcnt;
  ub4 randrsl[RANDSIZ];
  ub4 randmem[RANDSIZ];
  ub4 randa;
  ub4 randb;
  ub4 randc;
};
typedef  struct randctx  randctx;

/* Initialize using randrsl[0..RANDSIZ-1] as the seed */
void randinit(randctx *);
static void isaac(randctx *);
ub4 randInt(randctx *);

/* Call rand(randctx *r) to get a single 32-bit random value
 * The code from this macro was moved to the ISAAC.xs file
#define rand(r) \
  (!(r)->randcnt-- ? \
    (isaac(r), (r)->randcnt=RANDSIZ-1, (r)->randrsl[(r)->randcnt]) : \
    (r)->randrsl[(r)->randcnt])
 */

#endif /* RAND_H */
