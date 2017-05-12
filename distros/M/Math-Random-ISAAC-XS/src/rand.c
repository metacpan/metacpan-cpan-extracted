/* rand.c: The ISAAC Pseudo-Random Number Generator
 *
 * This is the original ISAAC reference implementation, written by Bob Jenkins
 * and released into the public domain. The original code by Bob Jenkins was
 * retrieved from: http://burtleburtle.net/bob/rand/isaacafa.html
 *
 * Original filename was rand.c and carried this changelog:
 *  960327: Creation (addition of randinit, really)
 *  970719: use context, not global variables, for internal state
 *  980324: make a portable version
 *  010626: Note this is public domain
 *
 * Jonathan Yu <jawnsy@cpan.org> made some mostly cosmetic changes and
 * prepared the file for life as a CPAN XS module.
 *
 * This package and its contents are released by the author into the
 * Public Domain, to the full extent permissible by law. For additional
 * information, please see the included `LICENSE' file.
 */

#include "standard.h"
#include "rand.h"

#ifdef USE_PORTABLE
#define cut(a)     ((a) & 0xffffffff) /* Cut the integer down to 32bits */
#else
#define cut(a)     (a) /* A no-op */
#endif

#define ind(mm,x)  ((mm)[(x>>2)&(RANDSIZ-1)])
/* the call to cut() is a macro defined in standard.h */
#define rngstep(mix,a,b,mm,m,m2,r,x) \
{ \
  x = *m;  \
  a = cut((a^(mix)) + *(m2++)); \
  *(m++) = y = cut(ind(mm,x) + a + b); \
  *(r++) = b = cut(ind(mm,y>>RANDSIZL) + x); \
}
#define mix(a,b,c,d,e,f,g,h) \
{ \
  a^=b<<11; d+=a; b+=c; \
  b^=c>>2;  e+=b; c+=d; \
  c^=d<<8;  f+=c; d+=e; \
  d^=e>>16; g+=d; e+=f; \
  e^=f<<10; h+=e; f+=g; \
  f^=g>>4;  a+=f; g+=h; \
  g^=h<<8;  b+=g; h+=a; \
  h^=a>>9;  c+=h; a+=b; \
}
#define shuffle(a, b, mm, m, m2, r, x) \
{ \
  rngstep(a<<13, a, b, mm, m, m2, r, x); \
  rngstep(a>>6 , a, b, mm, m, m2, r, x); \
  rngstep(a<<2 , a, b, mm, m, m2, r, x); \
  rngstep(a>>16, a, b, mm, m, m2, r, x); \
}

static void isaac(randctx *ctx)
{
  /* Keep these in CPU registers if possible, for speed */
  register ub4 a, b, x, y;
  register ub4 *m, *mm, *m2, *r, *mend;

  mm = ctx->randmem;
  r = ctx->randrsl;
  a = ctx->randa;
  b = cut(ctx->randb + (++ctx->randc));

  m = mm;
  mend = m2 = m + (RANDSIZ / 2);
  while (m < mend) {
    shuffle(a, b, mm, m, m2, r, x);
  }

  m2 = mm;
  while (m2 < mend) {
    shuffle(a, b, mm, m, m2, r, x);
  }

  ctx->randb = b;
  ctx->randa = a;
}

/* using randrsl[0..RANDSIZ-1] as the seed */
void randinit(randctx *ctx)
{
  ub4 a, b, c, d, e, f, g, h;
  ub4 *m, *r;
  int i; /* for loop incrementing variable */

  m = ctx->randmem;
  r = ctx->randrsl;

  ctx->randa = ctx->randb = ctx->randc = (ub4)0;

  /* Initialize a to h with the golden ratio */
  a=b=c=d=e=f=g=h = 0x9e3779b9;

  /* scramble it */
  for (i = 0; i < 4; i++) {
    mix(a,b,c,d,e,f,g,h);
  }

  /* initialize using the contents of r[] as the seed */
  for (i = 0; i < RANDSIZ; i += 8) {
    a += r[i  ];
    b += r[i+1];
    c += r[i+2];
    d += r[i+3];
    e += r[i+4];
    f += r[i+5];
    g += r[i+6];
    h += r[i+7];

    mix(a,b,c,d,e,f,g,h);

    m[i  ] = a;
    m[i+1] = b;
    m[i+2] = c;
    m[i+3] = d;
    m[i+4] = e;
    m[i+5] = f;
    m[i+6] = g;
    m[i+7] = h;
  }

  /* do a second pass to make all of the seed affect all of m */
  for (i = 0; i < RANDSIZ; i += 8) {
    a += m[i  ];
    b += m[i+1];
    c += m[i+2];
    d += m[i+3];
    e += m[i+4];
    f += m[i+5];
    g += m[i+6];
    h += m[i+7];

    mix(a,b,c,d,e,f,g,h);

    m[i  ] = a;
    m[i+1] = b;
    m[i+2] = c;
    m[i+3] = d;
    m[i+4] = e;
    m[i+5] = f;
    m[i+6] = g;
    m[i+7] = h;
  }

  isaac(ctx);              /* fill in the first set of results */
  ctx->randcnt = RANDSIZ;  /* prepare to use the first set of results */
}

/* This function was added by Jonathan Yu to return the next integer (taking
 * the code out of a macro and putting it into a function instead
 */
ub4 randInt(randctx *ctx)
{
  /* If we run out of numbers, reset the sequence */
  if (ctx->randcnt-- == 0) {
    isaac(ctx);
    ctx->randcnt = RANDSIZ - 1;
  }
  return ctx->randrsl[ctx->randcnt];
}
