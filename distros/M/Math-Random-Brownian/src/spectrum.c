/***************************************************************************
 * The code is taken from a file by
 *            Christian Schuler
 *            Research Institute for Open Communication Systems
 *            GMD FOKUS, Hardenbergplatz 2, D-10623 Berlin, Germany
 *            Phone : ++49 / (0)30 / 254 99 - 295
 *            email : schuler@fokus.gmd.de

Copyright (c) 1995 The Regents of the University of California.
All rights reserved.

This code is derived from software contributed to Berkeley by
Vern Paxson.

The United States Government has rights in this work pursuant
to contract no. DE-AC03-76SF00098 between the United States
Department of Energy and the University of California.

Redistribution and use in source and binary forms are permitted
provided that: (1) source distributions retain this entire
copyright notice and comment, and (2) distributions including
binaries display the following acknowledgement:  ``This product
includes software developed by the University of California,
Berkeley and its contributors'' in the documentation or other
materials provided with the distribution and in all advertising
materials mentioning features or use of this software.  Neither the
name of the University nor the names of its contributors may be
used to endorse or promote products derived from this software
without specific prior written permission.

THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE.

-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
This basically says "do whatever you please with this software except
remove this notice or take advantage of the University's (or the author's)
name".

In particular, you are free to redistribute the software, sell it,
modify it, etc., provided you abide by the terms above.

*
* description:
*   Generation of Fractional Gaussian Noise by the FFT-Algorithm proposed by
*   Vern Paxson, "Fast Approximation of Self-Similar Network Traffic",
*   Berkeley 1995
*   Info:
*   "http://town.hall.org/Archives/pub/ITA/html/contrib/fft-fgn.html"
*
***************************************************************************/

#include <math.h>
#include "spectrum.h"


void FGN_spectrum ( double *pow_spec, int n, double H) {
  /* Returns an approximation of the power spectrum for fractional      */
  /* Gaussian noise at the given frequencies lambda and the given Hurst */
  /* parameter H.                                                       */
  int i;
  double lambda,fact1,a,b,c,g;
  
  /* the result of lgamma will always be positive: */
  g = lgamma(2.0 * H + 1.0);

  fact1 = 2.0 * sin(M_PI * H) * exp(g);
  
  for(i=1; i<n+1; i++) {
    lambda = (M_PI * i) / n;
    a = fact1 * (1.0 - cos(lambda));
    b = pow(lambda,(-2.0 * H - 1.0));
    c = FGN_B_est_adj(lambda, H);
    pow_spec[i] = a * (b + c); 
  }
}


double FGN_B_est (double lambda, double H) {
  /* Returns the estimate for B(lambda,H). */
  int k;
  double d, dprime, sum1,sum2,result;
  double a[5],b[5]; /* index 0 never used ! */

  d = -2.0 * H - 1.0;
  dprime = -2.0 * H;

  for(k=1; k<5; k++) {
    a[k] = 2.0 * k * M_PI + lambda;
    b[k] = 2.0 * k * M_PI - lambda;
  }
	
  sum1 = 0.0;
  for(k=1; k<4; k++) {
    sum1 += pow(a[k],d);
    sum1 += pow(b[k],d);
  }
  sum2 = 0.0;
  for(k=3; k<5; k++) {
    sum2 += pow(a[k],dprime);
    sum2 += pow(b[k],dprime);
  }
  result = sum1 + (sum2 / (8.0 * M_PI * H));
  return(result);
}


double FGN_B_est_adj (double lambda, double H) {
  /* Returns the adjusted estimate for B(lambda,H). */
  return (1.0002 - 0.000134 * lambda) * 
         (FGN_B_est(lambda,H) - pow(2, -7.65*H - 7.4));
}
