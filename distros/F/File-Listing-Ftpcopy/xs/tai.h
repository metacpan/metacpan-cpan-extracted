/* Reimplementation of Daniel J. Bernsteins tai library.
 * (C) 2001 Uwe Ohse, <uwe@ohse.de>.
 *   Report any bugs to <uwe@ohse.de>.
 * Placed in the public domain.
 */
#ifndef TAI_H
#define TAI_H

#include "uint64.h"

struct tai {
  uint64 x;
} ;

extern void tai_add(struct tai *to,const struct tai *src1,
  const struct tai *src3);
extern void tai_sub(struct tai *,const struct tai *,const struct tai *);
extern void tai_now(struct tai *to);
extern void tai_uint(struct tai *,unsigned int);
/* #define tai_uint(a,b) do { a->x=b; } while(0) */

#define TAI_PACK 8
extern void tai_pack(char *,const struct tai *);
extern void tai_unpack(const char *,struct tai *);

#define tai_unix(t,u) ((void) ((t)->x = 4611686018427387914ULL + (uint64) (u)))

#define tai_approx(t) ((double) ((t)->x))

#define tai_less(t,u) ((t)->x < (u)->x)

#endif
