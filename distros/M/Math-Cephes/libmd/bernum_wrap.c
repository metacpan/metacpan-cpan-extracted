/* This program computes the Bernoulli numbers.
 * See radd.c for rational arithmetic.
 */

typedef struct{
	double n;
	double d;
	}fract;

#define PD 30
/*
fract x[PD+1] = {0.0};
fract p[PD+1] = {0.0};
*/
#include "mconf.h"
#ifdef ANSIPROT
extern double md_fabs ( double );
extern double md_log10 ( double );
#else
double md_fabs(), md_log10();
#endif
extern double MACHEP;

void bernum_wrap(num, den)
  double num[PD-2], den[PD-2];

{
  int nx, np;
  int i, k, n;
  fract s, t;
  extern void radd ( fract *, fract *, fract *);
  extern void rsub ( fract *, fract *, fract *);
  extern void rmul ( fract *, fract *, fract *);
  extern void rdiv ( fract *, fract *, fract *);
  fract x[PD+1], p[PD+1];


  for(i=0; i<=PD; i++ )
    {
      x[i].n = 0.0;
      x[i].d = 1.0;
      p[i].n = 0.0;
      p[i].d = 1.0;
    }
  p[0].n = 1.0;
  p[0].d = 1.0;
  p[1].n = 1.0;
  p[1].d = 1.0;
  np = 1;
  x[0].n = 1.0;
  x[0].d = 1.0;
  
  for( n=1; n<PD-2; n++ )
    {
      
      /* Create line of Pascal's triangle */
      /* multiply p = u * p */
      for( k=0; k<=np; k++ )
	{
	  radd( &p[np-k+1], &p[np-k], &p[np-k+1] );
	}
      np += 1;
      
      /* B0 + nC1 B1 + ... + nCn-1 Bn-1 = 0 */
      s.n = 0.0;
      s.d = 1.0;
 
      for( i=0; i<n; i++ )
	{
	  rmul( &p[i], &x[i], &t );
	  radd( &s, &t, &s );
	}
      
      
      rdiv( &p[n], &s, &x[n] );	/* x[n] = -s/p[n] */
      x[n].n = -x[n].n;
      nx += 1;
      // printf( "%2d %.15e / %.15e\n", n, x[n].n, x[n].d );
      num[n] = x[n].n;
      den[n] = x[n].d;
    }
  
  
}

