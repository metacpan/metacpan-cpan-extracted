/*  This program simulates fractional Gaussian noise or fractional          */
/*  Brownian motion using the Paxson algorithm.                             */
/*  The C-packages Ranlib and Meschach are used, both available             */
/*  via Netlib (http://www.netlib.org).                                     */

/*  References:                                                             */
/*  1) V. Paxson (1997),                                                    */
/*     Fast, approximate synthesis of fractional Gaussian noise for         */
/*     generating self-similar network traffic,                             */
/*     Computer Communication Review, Vol. 27, pp. 5-18.                    */
/*  2) A.B. Dieker and M. Mandjes (2002),                                   */
/*     On spectral simulation of fractional Brownian motion,                */
/*     submitted for publication.                                           */

/*  Copyright Ton Dieker                                                    */
/*  Centre of Mathematics and Computer Science (CWI) Amsterdam              */
/*  April 2002                                                              */

/*  ton@cwi.nl                                                              */
/* Modified to remove the dependence on meschach by Walter Szeliga          */
/* Mar 2005                                                                 */

#include "paxson.h"
#include "fft.h"


void paxson(long *num, double *H, double *L, int *cum, long *seed1, 
            long *seed2, double *output) {
  /* function that generates a fractional Brownian motion or fractional  */
  /* Gaussian noise sample using the approximate Paxson method.          */
  /* Input:  *num    determines the sample size N by N=2^(*num)          */
  /*         *H      the Hurst parameter of the trace                    */
  /*         *L      the sample is generated on [0,L]                    */
  /*         *cum    = 0: fractional Gaussian noise is produced          */
  /*                 = 1: fractional Brownian motion is produced         */
  /*         *seed1  seed1 for the random generator                      */
  /*         *seed2  seed2 for the random generator                      */
  /* Output: *seed1  new seed1 of the random generator                   */
  /*         *seed2  new seed2 of the random generator                   */
  /*         *output the resulting sample is stored in this array        */
  long i, n, halfn, generator;
  double scaling;
  double *pow_spec;
  double aux;
  complex *a;
  
  n = pow(2,*num);
  halfn = n/2;
  
  /* set random generator and seeds */
  snorm(); 
  generator = 1;
  gscgn(1, &generator);
  setall(*seed1,*seed2);
  
  /* allocate memory */
  pow_spec = (double*) malloc( (halfn+1) * sizeof(double));
  
  /* approximate spectral density */
  FGN_spectrum(pow_spec,halfn,*H);
  
  /* real part of Fourier transform of a_re + i a_im gives sample path */
  a = malloc(n*sizeof(complex));
  a[0].re = 0.;
  a[0].im = 0.;
  for(i=1; i<=halfn; i++) {
    aux = sqrt(pow_spec[i]);
    a[i].re = aux*snorm();
    a[i].im = aux*snorm();
  }
  for(i=halfn+1; i<n; i++) {
    a[i].re = a[n-i].re;
    a[i].im = -a[n-i].im;
  }
  
  /* real part of Fourier transform of a_re + i a_im gives sample path */
  fft(n,a,1,1.0);
  
  /* rescale to obtain a sample of size 2^(*n) on [0,L] */  
  scaling = pow(*L/n,*H)/sqrt(2*n);
  for(i=0; i<n; i++) {
    output[i] = scaling*(a[i].re);
    if (*cum && i>0) {
      output[i] += output[i-1];
    }
  }
  
  /* store the new random seeds and free memory */
  getsd(seed1,seed2);
  
  free(pow_spec);
  free(a);
}
 
