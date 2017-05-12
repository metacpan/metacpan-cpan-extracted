/*  Copyright Ton Dieker                                                    */
/*  Centre of Mathematics and Computer Science (CWI) Amsterdam              */
/*  April 2002                                                              */

/*  ton@cwi.nl                                                              */


#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include "ranlib.h"

extern void hosking(long *n, double *H, double *L, int *cum, 
		    long *seed1, long *seed2, double *output);

extern void circulant(long *n, double *H, double *L, int *cum, 
		      long *seed1, long *seed2, double *output);

extern void apprcirc(long *n, double *H, double *L, int *cum, 
		      long *seed1, long *seed2, double *output);

extern void paxson(long *n, double *H, double *L, int *cum, 
		      long *seed1, long *seed2, double *output);

