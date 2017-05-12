/* A C-program for TT800 : July 8th 1996 Version */
/* by M. Matsumoto, email: matumoto@math.keio.ac.jp */
/* genrand() generate one pseudorandom number with double precision */
/* which is uniformly distributed on [0,1]-interval */
/* for each call.  One may choose any initial 25 seeds */
/* except all zeros. */

/* See: ACM Transactions on Modelling and Computer Simulation, */
/* Vol. 4, No. 3, 1994, pages 254-266. */

/* we need 32 bits ore more for these numbers. 64 bits do not hurt. */

#include "EXTERN.h"
#include "perl.h"
#include "tt800.h"

struct tt800_state tt800_initial_state = {
        {                                       /* initial 25 seeds, */
        0x95f24dab, 0x0b685215, 0xe76ccae7, 0xaf3ec239, 0x715fad23,
        0x24a590ad, 0x69e4b5ef, 0xbf456141, 0x96bc1b7b, 0xa7bdf825,
        0xc1de75b7, 0x8858a9c9, 0x2da87693, 0xb657f9dd, 0xffdc8a9f,
        0x8121da71, 0x8b823ecb, 0x885d05f5, 0x4e20cd47, 0x5a9ad5d9,
        0x512c0c03, 0xea857ccd, 0x4cc1d30f, 0x8891a8a1, 0xa6b7aadb
        },
        0                               /* initial k */
        };


static unsigned int mag01[2]=
        {                       /* this is magic vector `a', don't change */
        0x0, 0x8ebfd028
        };


/*
 * tt800_get_next_int: Return next TT800 number (unscaled)
 *
 * Input:
 *      g:  Pointer to a struct tt800_state.
 *
 */
U32 tt800_get_next_int(TT800 g)
{
U32 y;

if (g->k == TT800_N) /* generate TT800_N words at one time */
	{ 
	int kk;

	for (kk=0; kk < TT800_N - TT800_M; kk++) 
		{
		g->x[kk] = 	g->x[kk+TT800_M] ^ 
				(g->x[kk] >> 1) ^ mag01[g->x[kk] & 1];
		}

	for (; kk<TT800_N;kk++) 
		{
		g->x[kk] = 	g->x[kk+(TT800_M-TT800_N)] ^
				(g->x[kk] >> 1) ^ mag01[g->x[kk] & 1];
		}
	g->k=0;
	}

y = g->x[g->k];
y ^= (y << 7) & 0x2b5b2500; /* s and b, magic vectors */
y ^= (y << 15) & 0xdb8b0000; /* t and c, magic vectors */
/* 
   the following line was added by Makoto Matsumoto in the 1996 version
   to improve lower bit's corellation.
   Delete this line to o use the code published in 1994.
*/

g->k++;

y ^= (y >> 16); /* added to the 1994 version */
return(y);
}

