/* Filename: Rand/MersenneTwister.xs
 * Author:   George Schlossnagle <george@omniti.com>
 *           Theo Schlossnagle <jesus@omniti.com>
 * Created:  3rd October 2002
 * Version:  1.0.1
 *
 * Copyright (c) 2002 OmniTI Computer Consulting, Inc. All rights reserved.
 *   This program is free software; you can redistribute it and/or
 *   modify it under the same terms as Perl itself.
 *
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define GENERATOR generator *

#ifndef PERL_VERSION
#include "patchlevel.h"
#define PERL_REVISION   5
#define PERL_VERSION    PATCHLEVEL
#define PERL_SUBVERSION SUBVERSION
#endif

#if PERL_REVISION == 5 && (PERL_VERSION < 4 || (PERL_VERSION == 4 && PERL_SUBVERSION <= 75 ))

#    define PL_sv_undef         sv_undef
#    define PL_na               na
#    define PL_curcop           curcop
#    define PL_compiling        compiling

#endif

SV *sv_NULL ;

#include <time.h>
#include <sys/types.h>
#include <unistd.h>


#define omniti_uint32 unsigned int

#define MT_N (624)
#define N             MT_N                 /* length of state vector */
#define M             (397)                /* a period parameter */
#define K             (0x9908B0DFU)        /* a magic constant */
#define hiBit(u)      ((u) & 0x80000000U)  /* mask all but highest   bit of u */
#define loBit(u)      ((u) & 0x00000001U)  /* mask all but lowest    bit of u */
#define loBits(u)     ((u) & 0x7FFFFFFFU)  /* mask     the highest   bit of u */
#define mixBits(u, v) (hiBit(u)|loBits(v)) /* move hi bit of u to hi bit of v */


typedef struct _generator {
    omniti_uint32 state[MT_N+1];   /* state vector + 1 extra to not violate ANSI C */
    omniti_uint32 *next;    /* next random value is computed from here */
    int left;  /* can *next++ this many times before reloading */
} generator;

static generator *mt_init()
{
    generator *gen;
    gen = (generator *)malloc(sizeof(generator));
    gen->next = NULL;
    gen->left = -1;
    return gen;
}

static void mt_free(generator *gen) {
  if(gen)
    free(gen);
}

static void mt_seed(generator *gen, omniti_uint32 seed) 
{
    omniti_uint32 x = (seed | 1U) &  0xFFFFFFFFU;
    omniti_uint32 *s = gen->state;
    int j;

    for(gen->left = 0, *s++ = x, j = N; --j;
       *s++ = (x *= 69069U) & 0xFFFFFFFFU);
}

static omniti_uint32 mt_reload(generator *gen)
{
    omniti_uint32 *p0 = gen->state;
    omniti_uint32 *p2 = gen->state + 2;
    omniti_uint32 *pM = gen->state + M;
    omniti_uint32 s0, s1;
    int j;

    if(gen->left < -1) {
        mt_seed(gen, 4357U);
    }
    gen->left = N -1, gen->next = gen->state + 1;

    for (s0 = gen->state[0], s1 = gen->state[1], j = N - M +1; --j; s0 = s1, s1 = *p2++) 
        *p0++ = *pM++ ^ (mixBits(s0, s1) >> 1) ^ (loBit(s1) ? K : 0U);

    for (pM = gen->state, j = M; --j; s0 = s1, s1 = *p2++)
        *p0++ = *pM++ ^ (mixBits(s0, s1) >> 1) ^ (loBit(s1) ? K : 0U);

    s1 = gen->state[0], *p0 = *pM ^ (mixBits(s0, s1) >> 1) ^ (loBit(s1) ? K : 0U);
    s1 ^= (s1 >> 11);
    s1 ^= (s1 <<  7) & 0x9D2C5680U;
    s1 ^= (s1 << 15) & 0xEFC60000U;

    return s1 ^ (s1 >> 18);
}    


static omniti_uint32 mt_rand(generator *gen)
{
    omniti_uint32 y;

    if(--(gen->left) < 0) {
        return mt_reload(gen);
    }
    y = *(gen->next)++;
    y ^= (y >> 11);
    y ^= (y << 7) & 0x9D2C5680U;
    y ^= (y << 15) & 0xEFC60000U;

    return y ^ (y >> 18);
}

#define GENERATE_SEED() ((long) (time(0) * getpid() * 1000000))


static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static SV *
constant(name, arg)
char *name;
int arg;
{
    errno = ENOENT;
    return 0;
}

MODULE = Rand::MersenneTwister	PACKAGE = Rand::MersenneTwister	PREFIX = MT_

REQUIRE:	1.9505
PROTOTYPES:	DISABLE

BOOT:
	sv_NULL = newSVpv("", 0) ;

SV *
constant(name,arg)
        char *          name
        int             arg

GENERATOR
MT_mt_init()
        PREINIT:
        GENERATOR gen;
	CODE:
	  gen = mt_init();
          RETVAL = gen;
	OUTPUT:
	  RETVAL

SV *
MT_mt_free(gen)
        GENERATOR gen
        CODE:
          mt_free(gen);
          RETVAL = &PL_sv_yes;
        OUTPUT:
          RETVAL

void
MT_mt_seed(gen, seed)
        GENERATOR gen
        SV * seed
        PREINIT:
          int seedval;
        CODE:
        {
          seedval = SvIV(seed);
	  mt_seed(gen, seedval);
	}
        OUTPUT:

SV *
MT_mt_rand(gen, max=&PL_sv_undef)
        GENERATOR gen
	SV * max
	PREINIT:
	omniti_uint32 v;
	double d;
        CODE:
	  if(max != &PL_sv_undef) {
	    d = SvNV(max);
	  } else {
	    d = 1.0;
	  }
	  v = mt_rand(gen);
	  d *= (double)v/(double)(UINT_MAX+1.0);
	  RETVAL = newSVnv(d);
        OUTPUT:
          RETVAL

