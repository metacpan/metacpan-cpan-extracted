/*							polrt.c
 *
 *	Wrapper to polrt.c
 *
 *
 *
 * SYNOPSIS:
 *
 * typedef struct
 *	{
 *	double r;
 *	double i;
 *	}cmplx;
 *
 * double xcof[], cof[], r[], i[];
 * int m;
 *
 * polrt_wrap( xcof, cof, m, r, i )
 *
 *
 *
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

/*
typedef struct
	{
	double r;
	double i;
	}cmplx;
*/

int polrt_wrap( xcof, cof, m, r, i )
double xcof[], cof[], r[], i[];
int m;
{
  extern int polrt( double xcof[], double cof[], int m, cmplx root[] );
  cmplx *root;
  int j, ret;
  root = (cmplx *) malloc( (m+1) * sizeof (cmplx) ); 
  for (j=0; j<=m; j++) {
    root[j].r = 0;
    root[j].i = 0;
  }
  ret = polrt( xcof, cof, m, root );
  for (j=0; j<=m; j++) {
    r[j] = root[j].r;
    i[j] = root[j].i;
  }
  free(root);
  return ret;
}
