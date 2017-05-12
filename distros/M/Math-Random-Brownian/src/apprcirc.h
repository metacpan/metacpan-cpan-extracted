/*  Copyright Ton Dieker                                                    */
/*  Centre of Mathematics and Computer Science (CWI) Amsterdam              */
/*  April 2002                                                              */

/*  ton@cwi.nl                                                              */
/* Modified to remove the dependence on meschach by Walter Szeliga          */
/* Mar 2005                                                                 */

#include <math.h>
#include "ranlib.h"
#include "spectrum.h"

extern void apprcirc(long *n, double *H, double *L, int *cum, 
		     long *seed1, long *seed2, double *output);
