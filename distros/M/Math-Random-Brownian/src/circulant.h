/*  Copyright Ton Dieker                                                    */
/*  Centre of Mathematics and Computer Science (CWI) Amsterdam              */
/*  April 2002                                                              */

/*  ton@cwi.nl                                                              */
/* Edited to remove the dependence on meschach Mar 05 Walter Szeliga        */


#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include "ranlib.h"

extern void circulant(long *n, double *H, double *L, int *cum, 
		      long *seed1, long *seed2, double *output);
