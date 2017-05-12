/*	Fft.c
	
	1-d fast Fourier transform subroutine.
	From Claerbout (1985) p. 70.

	Usage:		int lx;
			float signi, scale;
			struct complex cx[];

			fft(lx, cx, signi, scale);

	Compile:	cc prog.c fft.c -fswitch -lm -o prog.c

	Arguments:	lx	number of elements of vector to transform
				MUST BE A POWER OF 2
			cx	pointer to vector of complex structures
			signi	sign of transform- +1 forward to Fourier domain
						   -1 inverse to real domain
			scale	scale factor to apply to data before tranform
									*/

/* Header info has been moved to fft.h, struct complex is now a typedef */
/* and other slight changes have been made. -- Walter Szeliga Mar 05    */

/* Include the usual header files */
#include <stdio.h>
#include <math.h>
#include "fft.h"

/* Define complex multiplication and its conjugate */
#define  rmul(x,y)      (x.re * y.re - x.im * y.im)
#define  imul(x,y)      (x.im * y.re + x.re * y.im)
#define rcmul(x,y)      (x.re * y.re + x.im * y.im)
#define icmul(x,y)      (x.im * y.re - x.re * y.im)

/* Body of subroutine */
int
fft(int lx,complex *cx,float signi,float  sc)
	{
	/* Declare all local variables */
	int i, j, k, m, istep;
	float arg;
	complex cw, ct;

	j = 0;
	k = 1;
	/* Left out for compatibility with colmft.c
	sc = (float)(sqrt(1.0/(double)(lx)));
	*/
	for(i=0; i<lx; i++)
		{
		if (i <= j)
			{
			ct.re = sc * cx[j].re;
			ct.im = sc * cx[j].im;
			cx[j].re = sc * cx[i].re;
			cx[j].im = sc * cx[i].im;
			cx[i].re = ct.re;
			cx[i].im = ct.im;
			}
		m = lx/2;
		while (j > m-1)
			{
			j = j - m;
			m = m/2;
			if (m < 1)
				break;
			}
		j = j + m;
		}
	do
		{
		istep = 2*k;
		for (m=0; m<k; m++)
			{
			arg = 3.14159265*signi*m/k;
			cw.re = (float)(cos((double)(arg)));
			cw.im = (float)(sin((double)(arg)));
			for (i=m; i<lx; i+=istep)
				{
				ct.re = rmul(cw, cx[i+k]);
				ct.im = imul(cw, cx[i+k]);
				cx[i+k].re = cx[i].re - ct.re;
				cx[i+k].im = cx[i].im - ct.im;
				cx[i].re = cx[i].re + ct.re;
				cx[i].im = cx[i].im + ct.im;
				}
			}
		k = istep;
		}
		while (k < lx);
	return(0);
	}
