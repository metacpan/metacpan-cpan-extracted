/*
  Copyright (c) 1995-1998 Nick Ing-Simmons. All rights reserved.
  This program is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.
*/

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#include <patchlevel.h>
#include <stdlib.h>

typedef unsigned short *seed_t;

static unsigned short default_seed[3] = {0,0,0};

void
SeedtoSV(SV *sv, seed_t seed)
{
 sv_setpvn(sv,(char *)seed,3*sizeof(unsigned short));
}

seed_t
SVtoSeed(SV *sv)
{
 if (!SvPOK(sv) || SvCUR(sv) != 3*sizeof(unsigned short) )
  {
   if (SvPOK(sv) && SvCUR(sv) > 3*sizeof(unsigned short))
    {          
     STRLEN len;
     char *s = SvPV(sv,len);
     U32 hash;
     PERL_HASH(hash, s,len);
     sv_setiv(sv,hash);
    }
   if (!SvPOK(sv))
    {
     IV val = 0;
     if (SvIOK(sv))
      val = SvIV(sv);
     sv_setpvn(sv,(char *) &val, sizeof(val));
    }
   if (SvCUR(sv) < 3*sizeof(unsigned short))
    {
     SvGROW(sv,3*sizeof(unsigned short));
     while (SvCUR(sv) < 3*sizeof(unsigned short))
      {
       SvPVX(sv)[SvCUR(sv)] = 0xFF;
       SvCUR(sv) = SvCUR(sv)+1;
      }
    }
  }
 return (seed_t) SvPVX(sv);
} 

MODULE = Math::Rand48	PACKAGE = Math::Rand48
          
double
drand48()

double
erand48(seed)
seed_t	seed

IV
lrand48()

IV
nrand48(seed)
seed_t	seed

IV
mrand48()

IV
jrand48(seed)
seed_t	seed   

seed_t
seed48(seed = NULL)
seed_t	seed
CODE:
 {
  if (seed != NULL)
   RETVAL = seed48(seed);
  else
   {
    RETVAL = seed48(default_seed);
    seed48(RETVAL);
   }
 }
OUTPUT:
 RETVAL   

