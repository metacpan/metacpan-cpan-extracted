/*							md_yn.c
 *
 *	Bessel function of second kind of integer order
 *
 *
 *
 * SYNOPSIS:
 *
 * double x, y, md_yn();
 * int n;
 *
 * y = md_yn( n, x );
 *
 *
 *
 * DESCRIPTION:
 *
 * Returns Bessel function of order n, where n is a
 * (possibly negative) integer.
 *
 * The function is evaluated by forward recurrence on
 * n, starting with values computed by the routines
 * md_y0() and md_y1().
 *
 * If n = 0 or 1 the routine for md_y0 or md_y1 is called
 * directly.
 *
 *
 *
 * ACCURACY:
 *
 *
 *                      Absolute error, except relative
 *                      when y > 1:
 * arithmetic   domain     # trials      peak         rms
 *    DEC       0, 30        2200       2.9e-16     5.3e-17
 *    IEEE      0, 30       30000       3.4e-15     4.3e-16
 *
 *
 * ERROR MESSAGES:
 *
 *   message         condition      value returned
 * md_yn singularity   x = 0              MAXNUM
 * md_yn overflow                         MAXNUM
 *
 * Spot checked against tables for x, n between 0 and 100.
 *
 */

/*
Cephes Math Library Release 2.8:  June, 2000
Copyright 1984, 1987, 2000 by Stephen L. Moshier
*/

#include "mconf.h"
#ifdef ANSIPROT
extern double md_y0 ( double );
extern double md_y1 ( double );
extern double md_log ( double );
#else
double md_y0(), md_y1(), md_log();
#endif
extern double MAXNUM, MAXLOG;

double md_yn( n, x )
int n;
double x;
{
double an, anm1, anm2, r;
int k, sign;

if( n < 0 )
	{
	n = -n;
	if( (n & 1) == 0 )	/* -1**n */
		sign = 1;
	else
		sign = -1;
	}
else
	sign = 1;


if( n == 0 )
	return( sign * md_y0(x) );
if( n == 1 )
	return( sign * md_y1(x) );

/* test for overflow */
if( x <= 0.0 )
	{
	mtherr( "md_yn", SING );
	return( -MAXNUM );
	}

/* forward recurrence on n */

anm2 = md_y0(x);
anm1 = md_y1(x);
k = 1;
r = 2 * k;
do
	{
	an = r * anm1 / x  -  anm2;
	anm2 = anm1;
	anm1 = an;
	r += 2.0;
	++k;
	}
while( k < n );


return( sign * an );
}
