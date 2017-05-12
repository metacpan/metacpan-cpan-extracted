/*							simpsn.c	*/
/* simpsn_wrap.c
 * wrapper for simpsn.c
 */

#include "mconf.h"
#include <stdio.h>
#ifdef ANSIPROT
extern void * malloc ( long );
extern void free ( void * );
#else
void * malloc();
void free ();
#endif

extern double simpsn( double f[], double h);
double simpsn_wrap( f, n, h )
double f[];	/* tabulated function */
int n;
double h;
{
  double ans=0.0, *g;
  int j, k;
  g = (double *) malloc( 9 * sizeof (double) );
  for (j=0; j<n/8; j++) {
    g[0] = f[j*8];
    for (k=1; k<=8; k++) g[k] = f[k+j*8];
    ans += simpsn(g, h);
  }
  free(g);
  return ans;
}
