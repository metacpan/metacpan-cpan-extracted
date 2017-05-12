/*  This program simulates fractional Gaussian noise or fractional          */
/*  Brownian motion using the Wood and Chan algorithm.                      */
/*  The C-packages Ranlib and Meschach are used, both available             */
/*  via Netlib (http://www.netlib.org).                                     */

/*  References:                                                             */
/*  1) R.B. Davies and D.S. Harte (1987),                                   */
/*     Tests for Hurst effect,                                              */
/*     Biometrika, Vol. 74, pp. 95--102.                                    */
/*  2) C.R. Dietrich and G.N. Newsam (1997),                                */
/*     Fast and exact simulation of stationary Gaussian processes through   */
/*     circulant embedding of the covariance matrix,                        */
/*     SIAM Journal Sci. Comput., Vol. 18, pp. 1088--1107.                  */
/*  3) A. Wood and G. Chan (1994),                                          */
/*     Simulation of Stationary Gaussian Processes in [0,1]^d,              */
/*     Journal of Comp. and Graphical Statistics, Vol. 3, pp. 409--432.     */

/*  Copyright Ton Dieker                                                    */
/*  Centre of Mathematics and Computer Science (CWI) Amsterdam              */
/*  April 2002                                                              */

/*  ton@cwi.nl                                                              */
/*  Adapted to work without meschach by Walter Szeliga Mar 05               */


#include "circulant.h"
#include "fft.h"

/* the autocovariance function of fractional Gaussian noise */
extern double covariance(long i, double H);


complex *eigenvalues(double n, double H) {
  /* computes the eigenvalues of the circulant matrix that embeds the */
  /* covariance matrix                                                */

  complex *c; 
  long i, size = pow(2,n+1);
  c = malloc(size*sizeof(complex));

  for (i=0; i<size; i++) 
  {
   c[i].im = 0;
   if (i<=pow(2,n)) 
    c[i].re = covariance(i, H);
   else
    c[i].re = c[size-i].re;
  }

  fft(size,c,1,1.0);

  for (i=0; i<size; i++) {
    if (c[i].re <= 0) {
      printf("The program should be modified to deal with this ");
      printf("covariance function.\n");
      printf("See A. Wood and G. Chan (1994),\n");
      printf("Simulation of Stationary Gaussian Processes in [0,1]^d,\n");
      printf("Journal of Computational and Graphical ");
      printf("Statistics, Vol. 3, pp. 409-432\n");
      exit(0);
    }      
  }

  return c;
}


void computeSandT(long m, complex *ev, complex *SandT) {
  /* simulates two auxiliary vectors that serve as input */
  /* in the FFT algorithm                                */
  long i;

  SandT[0].re = sqrt(ev[0].re)*snorm()/sqrt(m);
  SandT[0].im = 0;
  SandT[m/2].re = sqrt(ev[m/2].re)*snorm()/sqrt(m);
  SandT[m/2].im = 0;
  
  for (i=1; i<m/2; i++) {
    SandT[i].re = sqrt(ev[i].re)*snorm()/sqrt(2*m);
    SandT[i].im = sqrt(ev[i].re)*snorm()/sqrt(2*m); 
    SandT[m-i].re = SandT[i].re;
    SandT[m-i].im = -SandT[i].im;
  }
}


void circulant(long *n, double *H, double *L, int *cum, 
	       long *seed1, long *seed2, double *output) {
  /* function that generates a fractional Brownian motion or fractional  */
  /* Gaussian noise sample.                                              */
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
  int *ifac; 
  complex *ev;
  complex *SandT;
  double *wsave;
  long i, generator;
  double scaling;

  /* set random generator and seeds */
  snorm(); 
  generator = 1;
  gscgn(1, &generator);
  setall(*seed1,*seed2);

  /* compute the eigenvalues of the circulant matrix */
  ev = eigenvalues(*n, *H);

  /* compute the input vectors for the FFT algorithm */
  SandT  = malloc(pow(2,*n+1)*sizeof(complex));
  computeSandT(pow(2,*n+1), ev, SandT);

  /* real part of Fourier transform of S + iT gives sample path */
  fft(pow(2,*n+1),SandT,1,1.0); 
 
  /* rescale to obtain a sample of size 2^(*n) on [0,L] */
  realloc(SandT,pow(2,*n));
  scaling = pow(*L/pow(2,*n),*H);
  for(i=0; i<pow(2,*n); i++) 
  {
   output[i] = scaling*(SandT[i].re);
   if (*cum && i>0) 
   {
    output[i] += output[i-1];
   }
  }
  
  /* store the new random seeds and free memory */
  getsd(seed1,seed2);

  free(ev);
  free(SandT);
}
