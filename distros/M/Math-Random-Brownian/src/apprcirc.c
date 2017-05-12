/*  This program simulates fractional Gaussian noise or fractional          */
/*  Brownian motion using the approximate circulant algorithm.              */
/*  The C-packages Ranlib and Meschach are used, both available             */
/*  via Netlib (http://www.netlib.org).                                     */

/*  Reference:                                                              */
/*  A.B. Dieker and M. Mandjes (2002),                                      */
/*  On spectral simulation of fractional Brownian motion,                   */
/*  submitted for publication.                                              */

/*  Copyright Ton Dieker                                                    */
/*  Centre of Mathematics and Computer Science (CWI) Amsterdam              */
/*  April 2002                                                              */

/*  ton@cwi.nl                                                              */
/* Modified to remove the dependence on meschach by Walter Szeliga          */
/* Mar 2005                                                                 */


#include "apprcirc.h"
#include "fft.h"

void apprcirc(long *n, double *Hurst, double *L, int *cum, long *seed1, 
              long *seed2, double *output) {
  /* function that generates a fractional Brownian motion or fractional  */
  /* Gaussian noise sample using the approximate circulant method.       */
  /* Input:  *n      determines the sample size N by N=2^(*n)            */
  /*         *Hurst  the Hurst parameter of the trace                    */
  /*         *L      the sample is generated on [0,L]                    */
  /*         *cum    = 0: fractional Gaussian noise is produced          */
  /*                 = 1: fractional Brownian motion is produced         */
  /*         *seed1  seed1 for the random generator                      */
  /*         *seed2  seed2 for the random generator                      */
  /* Output: *seed1  new seed1 of the random generator                   */
  /*         *seed2  new seed2 of the random generator                   */
  /*         *output the resulting sample is stored in this array        */
  long i, N, halfN, generator;
  double scaling, H;
  double *pow_spec;
  double aux;
  complex *a;
  
  halfN = pow(2,*n);
  H = *Hurst;
  N = 2*halfN;
  
  /* set random generator and seeds */
  snorm(); 
  generator = 1;
  gscgn(1, &generator);
  setall(*seed1,*seed2);
  
  /* allocate memory */
  pow_spec = (double*) malloc((halfN+1)*sizeof(double));
  
  /* approximate spectral density */
  FGN_spectrum(pow_spec,halfN,H);
 
  a = malloc(N*sizeof(complex)); 
  a[0].re = sqrt(2*(pow(N,2*H)-pow(N-1,2*H)))*snorm();
  a[0].im = 0.;
  a[halfN].re = sqrt(2*pow_spec[halfN])*snorm();
  a[halfN].im = 0.;
  for(i=1; i<halfN; i++) {
    aux = sqrt(pow_spec[i]);
    a[i].re = aux*snorm();
    a[i].im = aux*snorm();
  }
  for(i=halfN+1; i<N; i++) {
    a[i].re = a[N-i].re;
    a[i].im = -a[N-i].im;
  }
  
  /* real part of Fourier transform of a_re + i a_im gives sample path */
  fft(N,a,1,1.0);
  
  /* rescale to obtain a sample of size 2^(*n) on [0,L] */
  scaling = pow(*L/halfN,H)/sqrt(2*N);
  for(i=0;i<halfN;i++) {
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
