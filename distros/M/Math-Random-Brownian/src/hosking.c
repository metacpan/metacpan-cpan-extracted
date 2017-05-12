/*  This program simulates fractional Gaussian noise or fractional          */
/*  Brownian motion using the Hosking method.                               */
/*  The C-package Ranlib is used, available via Netlib                      */
/*  (http://www.netlib.org).                                                */

/*  Reference:                                                              */
/*  J.R.M. Hosking (1984),                                                  */
/*  Modeling persistence in hydrological time series using fractional       */
/*  brownian differencing,                                                  */
/*  Water Resources Research, Vol. 20, pp. 1898--1908.                      */

/*  Copyright Ton Dieker                                                    */
/*  Centre of Mathematics and Computer Science (CWI) Amsterdam              */
/*  April 2002                                                              */

/*  ton@cwi.nl                                                              */


#include "hosking.h"

/* the autocovariance function of fractional Gaussian noise */ 
extern double covariance(long i, double H);


void hosking(long *n, double *H, double *L, int *cum, 
	     long *seed1, long *seed2, double *output) {
  /* function that generates a fractional Brownian motion or fractional  */
  /* Gaussian noise sample using the Hosking method.                     */
  /* Input:  *n      determines the sample size N by N=2^(*n)            */
  /*         *H      the Hurst parameter of the trace                    */
  /*         *L      the sample is generated on [0,L]                    */
  /*         *cum    = 0: fractional Gaussian noise is produced          */
  /*                 = 1: fractional Brownian motion is produced         */
  /*         *seed1  seed1 for the random generator                      */
  /*         *seed2  seed2 for the random generator                      */
  /* Output: *seed1  new seed1 of the random generator                   */
  /*         *seed2  new seed2 of the random generator                   */
  /*         *output the resulting sample is stored in this array        */
  long i, j, generator, m = pow(2,*n);
  double *phi = (double *) calloc(m, sizeof(double));
  double *psi = (double *) calloc(m, sizeof(double));
  double *cov = (double *) calloc(m, sizeof(double));
  double v, scaling;
   
  /* set random generator and seeds */
  snorm(); 
  generator = 1;
  gscgn(1, &generator);
  setall(*seed1,*seed2);
  
  /* initialization */
  output[0] = snorm();
  v = 1;
  phi[0] = 0;
  for (i=0; i<m; i++)
    cov[i] = covariance(i, *H);

  /* simulation */
  for(i=1; i<m; i++) {
    phi[i-1] = cov[i];
    for (j=0; j<i-1; j++) {
      psi[j] = phi[j];
      phi[i-1] -= psi[j]*cov[i-j-1];
    }
    phi[i-1] /= v;
    for (j=0; j<i-1; j++) {
      phi[j] = psi[j] - phi[i-1]*psi[i-j-2];
    }
    v *= (1-phi[i-1]*phi[i-1]);
    
    output[i] = 0;
    for (j=0; j<i; j++) {
      output[i] += phi[j]*output[i-j-1];
    }
    output[i] += sqrt(v)*snorm();
  }

  /* rescale to obtain a sample of size 2^(*n) on [0,L] */
  scaling = pow(*L/m,*H);
  for(i=0;i<m;i++) {
    output[i] = scaling*(output[i]);
    if (*cum && i>0) {
      output[i] += output[i-1];
    }
  }

  /* store the new random seeds and free memory */
  getsd(seed1,seed2);

  free(phi);
  free(psi);
  free(cov);
}
