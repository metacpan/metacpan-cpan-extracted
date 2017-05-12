/*							md_clog.c
 *
 *	Complex natural logarithm
 *
 *
 *
 * SYNOPSIS:
 *
 * void md_clog();
 * cmplx z, w;
 *
 * md_clog( &z, &w );
 *
 *
 *
 * DESCRIPTION:
 *
 * Returns complex logarithm to the base e (2.718...) of
 * the complex argument x.
 *
 * If z = x + iy, r = sqrt( x**2 + y**2 ),
 * then
 *       w = md_log(r) + i arctan(y/x).
 * 
 * The arctangent ranges from -PI to +PI.
 *
 *
 * ACCURACY:
 *
 *                      Relative error:
 * arithmetic   domain     # trials      peak         rms
 *    DEC       -10,+10      7000       8.5e-17     1.9e-17
 *    IEEE      -10,+10     30000       5.0e-15     1.1e-16
 *
 * Larger relative error can be observed for z near 1 +i0.
 * In IEEE arithmetic the peak absolute error is 5.2e-16, rms
 * absolute error 1.0e-16.
 */

/*
Cephes Math Library Release 2.8:  June, 2000
Copyright 1984, 1995, 2000 by Stephen L. Moshier
*/
#include "mconf.h"
#ifdef ANSIPROT
static void cchsh ( double x, double *c, double *s );
static double redupi ( double x );
static double ctans ( cmplx *z );
/* These are supposed to be in some standard place. */
double md_fabs (double);
double sqrt (double);
double md_pow (double, double);
double md_log (double);
double md_exp (double);
double md_atan2 (double, double);
double md_cosh (double);
double md_sinh (double);
double md_asin (double);
double md_sin (double);
double md_cos (double);
double md_cabs (cmplx *);
void cadd ( cmplx *, cmplx *, cmplx * );
void cmul ( cmplx *, cmplx *, cmplx * );
void md_csqrt ( cmplx *, cmplx * );
static void cchsh ( double, double *, double * );
static double redupi ( double );
static double ctans ( cmplx * );
void md_clog ( cmplx *, cmplx * );
void md_casin ( cmplx *, cmplx * );
void md_cacos ( cmplx *, cmplx * );
void md_catan ( cmplx *, cmplx * );
#else
static void cchsh();
static double redupi();
static double ctans();
double md_cabs(), md_fabs(), sqrt(), md_pow();
double md_log(), md_exp(), md_atan2(), md_cosh(), md_sinh();
double md_asin(), md_sin(), md_cos();
void cadd(), cmul(), md_csqrt();
void md_clog(), md_casin(), md_cacos(), md_catan();
#endif


extern double MAXNUM, MACHEP, PI, PIO2;

void md_clog( z, w )
register cmplx *z, *w;
{
double p, rr;

/*rr = sqrt( z->r * z->r  +  z->i * z->i );*/
rr = md_cabs(z);
p = md_log(rr);
#if ANSIC
rr = md_atan2( z->i, z->r );
#else
rr = md_atan2( z->r, z->i );
if( rr > PI )
	rr -= PI + PI;
#endif
w->i = rr;
w->r = p;
}
/*							md_cexp()
 *
 *	Complex exponential function
 *
 *
 *
 * SYNOPSIS:
 *
 * void md_cexp();
 * cmplx z, w;
 *
 * md_cexp( &z, &w );
 *
 *
 *
 * DESCRIPTION:
 *
 * Returns the exponential of the complex argument z
 * into the complex result w.
 *
 * If
 *     z = x + iy,
 *     r = md_exp(x),
 *
 * then
 *
 *     w = r md_cos y + i r md_sin y.
 *
 *
 * ACCURACY:
 *
 *                      Relative error:
 * arithmetic   domain     # trials      peak         rms
 *    DEC       -10,+10      8700       3.7e-17     1.1e-17
 *    IEEE      -10,+10     30000       3.0e-16     8.7e-17
 *
 */

void md_cexp( z, w )
register cmplx *z, *w;
{
double r;

r = md_exp( z->r );
w->r = r * md_cos( z->i );
w->i = r * md_sin( z->i );
}
/*							md_csin()
 *
 *	Complex circular sine
 *
 *
 *
 * SYNOPSIS:
 *
 * void md_csin();
 * cmplx z, w;
 *
 * md_csin( &z, &w );
 *
 *
 *
 * DESCRIPTION:
 *
 * If
 *     z = x + iy,
 *
 * then
 *
 *     w = md_sin x  md_cosh y  +  i md_cos x md_sinh y.
 *
 *
 *
 * ACCURACY:
 *
 *                      Relative error:
 * arithmetic   domain     # trials      peak         rms
 *    DEC       -10,+10      8400       5.3e-17     1.3e-17
 *    IEEE      -10,+10     30000       3.8e-16     1.0e-16
 * Also tested by md_csin(md_casin(z)) = z.
 *
 */

void md_csin( z, w )
register cmplx *z, *w;
{
double ch, sh;

cchsh( z->i, &ch, &sh );
w->r = md_sin( z->r ) * ch;
w->i = md_cos( z->r ) * sh;
}



/* calculate md_cosh and md_sinh */

static void cchsh( x, c, s )
double x, *c, *s;
{
double e, ei;

if( md_fabs(x) <= 0.5 )
	{
	*c = md_cosh(x);
	*s = md_sinh(x);
	}
else
	{
	e = md_exp(x);
	ei = 0.5/e;
	e = 0.5 * e;
	*s = e - ei;
	*c = e + ei;
	}
}

/*							md_ccos()
 *
 *	Complex circular cosine
 *
 *
 *
 * SYNOPSIS:
 *
 * void md_ccos();
 * cmplx z, w;
 *
 * md_ccos( &z, &w );
 *
 *
 *
 * DESCRIPTION:
 *
 * If
 *     z = x + iy,
 *
 * then
 *
 *     w = md_cos x  md_cosh y  -  i md_sin x md_sinh y.
 *
 *
 *
 * ACCURACY:
 *
 *                      Relative error:
 * arithmetic   domain     # trials      peak         rms
 *    DEC       -10,+10      8400       4.5e-17     1.3e-17
 *    IEEE      -10,+10     30000       3.8e-16     1.0e-16
 */

void md_ccos( z, w )
register cmplx *z, *w;
{
double ch, sh;

cchsh( z->i, &ch, &sh );
w->r = md_cos( z->r ) * ch;
w->i = -md_sin( z->r ) * sh;
}
/*							md_ctan()
 *
 *	Complex circular tangent
 *
 *
 *
 * SYNOPSIS:
 *
 * void md_ctan();
 * cmplx z, w;
 *
 * md_ctan( &z, &w );
 *
 *
 *
 * DESCRIPTION:
 *
 * If
 *     z = x + iy,
 *
 * then
 *
 *           md_sin 2x  +  i md_sinh 2y
 *     w  =  --------------------.
 *            md_cos 2x  +  md_cosh 2y
 *
 * On the real axis the denominator is zero at odd multiples
 * of PI/2.  The denominator is evaluated by its Taylor
 * series near these points.
 *
 *
 * ACCURACY:
 *
 *                      Relative error:
 * arithmetic   domain     # trials      peak         rms
 *    DEC       -10,+10      5200       7.1e-17     1.6e-17
 *    IEEE      -10,+10     30000       7.2e-16     1.2e-16
 * Also tested by md_ctan * ccot = 1 and md_catan(md_ctan(z))  =  z.
 */

void md_ctan( z, w )
register cmplx *z, *w;
{
double d;

d = md_cos( 2.0 * z->r ) + md_cosh( 2.0 * z->i );

if( md_fabs(d) < 0.25 )
	d = ctans(z);

if( d == 0.0 )
	{
	mtherr( "md_ctan", OVERFLOW );
	w->r = MAXNUM;
	w->i = MAXNUM;
	return;
	}

w->r = md_sin( 2.0 * z->r ) / d;
w->i = md_sinh( 2.0 * z->i ) / d;
}
/*							ccot()
 *
 *	Complex circular cotangent
 *
 *
 *
 * SYNOPSIS:
 *
 * void ccot();
 * cmplx z, w;
 *
 * ccot( &z, &w );
 *
 *
 *
 * DESCRIPTION:
 *
 * If
 *     z = x + iy,
 *
 * then
 *
 *           md_sin 2x  -  i md_sinh 2y
 *     w  =  --------------------.
 *            md_cosh 2y  -  md_cos 2x
 *
 * On the real axis, the denominator has zeros at even
 * multiples of PI/2.  Near these points it is evaluated
 * by a Taylor series.
 *
 *
 * ACCURACY:
 *
 *                      Relative error:
 * arithmetic   domain     # trials      peak         rms
 *    DEC       -10,+10      3000       6.5e-17     1.6e-17
 *    IEEE      -10,+10     30000       9.2e-16     1.2e-16
 * Also tested by md_ctan * ccot = 1 + i0.
 */

void ccot( z, w )
register cmplx *z, *w;
{
double d;

d = md_cosh(2.0 * z->i) - md_cos(2.0 * z->r);

if( md_fabs(d) < 0.25 )
	d = ctans(z);

if( d == 0.0 )
	{
	mtherr( "ccot", OVERFLOW );
	w->r = MAXNUM;
	w->i = MAXNUM;
	return;
	}

w->r = md_sin( 2.0 * z->r ) / d;
w->i = -md_sinh( 2.0 * z->i ) / d;
}

/* Program to subtract nearest integer multiple of PI */
/* extended precision value of PI: */
#ifdef UNK
static double DP1 = 3.14159265160560607910E0;
static double DP2 = 1.98418714791870343106E-9;
static double DP3 = 1.14423774522196636802E-17;
#endif

#ifdef DEC
static unsigned short P1[] = {0040511,0007732,0120000,0000000,};
static unsigned short P2[] = {0031010,0055060,0100000,0000000,};
static unsigned short P3[] = {0022123,0011431,0105056,0001560,};
#define DP1 *(double *)P1
#define DP2 *(double *)P2
#define DP3 *(double *)P3
#endif

#ifdef IBMPC
static unsigned short P1[] = {0x0000,0x5400,0x21fb,0x4009};
static unsigned short P2[] = {0x0000,0x1000,0x0b46,0x3e21};
static unsigned short P3[] = {0xc06e,0x3145,0x6263,0x3c6a};
#define DP1 *(double *)P1
#define DP2 *(double *)P2
#define DP3 *(double *)P3
#endif

#ifdef MIEEE
static unsigned short P1[] = {
0x4009,0x21fb,0x5400,0x0000
};
static unsigned short P2[] = {
0x3e21,0x0b46,0x1000,0x0000
};
static unsigned short P3[] = {
0x3c6a,0x6263,0x3145,0xc06e
};
#define DP1 *(double *)P1
#define DP2 *(double *)P2
#define DP3 *(double *)P3
#endif

static double redupi(x)
double x;
{
double t;
long i;

t = x/PI;
if( t >= 0.0 )
	t += 0.5;
else
	t -= 0.5;

i = t;	/* the multiple */
t = i;
t = ((x - t * DP1) - t * DP2) - t * DP3;
return(t);
}

/*  Taylor series expansion for md_cosh(2y) - md_cos(2x)	*/

static double ctans(z)
cmplx *z;
{
double f, x, x2, y, y2, rn, t;
double d;

x = md_fabs( 2.0 * z->r );
y = md_fabs( 2.0 * z->i );

x = redupi(x);

x = x * x;
y = y * y;
x2 = 1.0;
y2 = 1.0;
f = 1.0;
rn = 0.0;
d = 0.0;
do
	{
	rn += 1.0;
	f *= rn;
	rn += 1.0;
	f *= rn;
	x2 *= x;
	y2 *= y;
	t = y2 + x2;
	t /= f;
	d += t;

	rn += 1.0;
	f *= rn;
	rn += 1.0;
	f *= rn;
	x2 *= x;
	y2 *= y;
	t = y2 - x2;
	t /= f;
	d += t;
	}
while( md_fabs(t/d) > MACHEP );
return(d);
}
/*							md_casin()
 *
 *	Complex circular arc sine
 *
 *
 *
 * SYNOPSIS:
 *
 * void md_casin();
 * cmplx z, w;
 *
 * md_casin( &z, &w );
 *
 *
 *
 * DESCRIPTION:
 *
 * Inverse complex sine:
 *
 *                               2
 * w = -i md_clog( iz + md_csqrt( 1 - z ) ).
 *
 *
 * ACCURACY:
 *
 *                      Relative error:
 * arithmetic   domain     # trials      peak         rms
 *    DEC       -10,+10     10100       2.1e-15     3.4e-16
 *    IEEE      -10,+10     30000       2.2e-14     2.7e-15
 * Larger relative error can be observed for z near zero.
 * Also tested by md_csin(md_casin(z)) = z.
 */

void md_casin( z, w )
cmplx *z, *w;
{
static cmplx ca, ct, zz, z2;
double x, y;

x = z->r;
y = z->i;

if( y == 0.0 )
	{
	if( md_fabs(x) > 1.0 )
		{
		w->r = PIO2;
		w->i = 0.0;
		mtherr( "md_casin", DOMAIN );
		}
	else
		{
		w->r = md_asin(x);
		w->i = 0.0;
		}
	return;
	}

/* Power series expansion */
/*
b = md_cabs(z);
if( b < 0.125 )
{
z2.r = (x - y) * (x + y);
z2.i = 2.0 * x * y;

cn = 1.0;
n = 1.0;
ca.r = x;
ca.i = y;
sum.r = x;
sum.i = y;
do
	{
	ct.r = z2.r * ca.r  -  z2.i * ca.i;
	ct.i = z2.r * ca.i  +  z2.i * ca.r;
	ca.r = ct.r;
	ca.i = ct.i;

	cn *= n;
	n += 1.0;
	cn /= n;
	n += 1.0;
	b = cn/n;

	ct.r *= b;
	ct.i *= b;
	sum.r += ct.r;
	sum.i += ct.i;
	b = md_fabs(ct.r) + md_fabs(ct.i);
	}
while( b > MACHEP );
w->r = sum.r;
w->i = sum.i;
return;
}
*/


ca.r = x;
ca.i = y;

ct.r = -ca.i;	/* iz */
ct.i = ca.r;

	/* sqrt( 1 - z*z) */
/* cmul( &ca, &ca, &zz ) */
zz.r = (ca.r - ca.i) * (ca.r + ca.i);	/*x * x  -  y * y */
zz.i = 2.0 * ca.r * ca.i;

zz.r = 1.0 - zz.r;
zz.i = -zz.i;
md_csqrt( &zz, &z2 );

cadd( &z2, &ct, &zz );
md_clog( &zz, &zz );
w->r = zz.i;	/* mult by 1/i = -i */
w->i = -zz.r;
return;
}
/*							md_cacos()
 *
 *	Complex circular arc cosine
 *
 *
 *
 * SYNOPSIS:
 *
 * void md_cacos();
 * cmplx z, w;
 *
 * md_cacos( &z, &w );
 *
 *
 *
 * DESCRIPTION:
 *
 *
 * w = arccos z  =  PI/2 - arcsin z.
 *
 *
 *
 *
 * ACCURACY:
 *
 *                      Relative error:
 * arithmetic   domain     # trials      peak         rms
 *    DEC       -10,+10      5200      1.6e-15      2.8e-16
 *    IEEE      -10,+10     30000      1.8e-14      2.2e-15
 */

void md_cacos( z, w )
cmplx *z, *w;
{

md_casin( z, w );
w->r = PIO2  -  w->r;
w->i = -w->i;
}
/*							md_catan()
 *
 *	Complex circular arc tangent
 *
 *
 *
 * SYNOPSIS:
 *
 * void md_catan();
 * cmplx z, w;
 *
 * md_catan( &z, &w );
 *
 *
 *
 * DESCRIPTION:
 *
 * If
 *     z = x + iy,
 *
 * then
 *          1       (    2x     )
 * Re w  =  - arctan(-----------)  +  k PI
 *          2       (     2    2)
 *                  (1 - x  - y )
 *
 *               ( 2         2)
 *          1    (x  +  (y+1) )
 * Im w  =  - md_log(------------)
 *          4    ( 2         2)
 *               (x  +  (y-1) )
 *
 * Where k is an arbitrary integer.
 *
 *
 *
 * ACCURACY:
 *
 *                      Relative error:
 * arithmetic   domain     # trials      peak         rms
 *    DEC       -10,+10      5900       1.3e-16     7.8e-18
 *    IEEE      -10,+10     30000       2.3e-15     8.5e-17
 * The check md_catan( md_ctan(z) )  =  z, with |x| and |y| < PI/2,
 * had peak relative error 1.5e-16, rms relative error
 * 2.9e-17.  See also md_clog().
 */

void md_catan( z, w )
cmplx *z, *w;
{
double a, t, x, x2, y;

x = z->r;
y = z->i;

if( (x == 0.0) && (y > 1.0) )
	goto ovrf;

x2 = x * x;
a = 1.0 - x2 - (y * y);
if( a == 0.0 )
	goto ovrf;

#if ANSIC
t = md_atan2( 2.0 * x, a )/2.0;
#else
t = md_atan2( a, 2.0 * x )/2.0;
#endif
w->r = redupi( t );

t = y - 1.0;
a = x2 + (t * t);
if( a == 0.0 )
	goto ovrf;

t = y + 1.0;
a = (x2 + (t * t))/a;
w->i = md_log(a)/4.0;
return;

ovrf:
mtherr( "md_catan", OVERFLOW );
w->r = MAXNUM;
w->i = MAXNUM;
}


/*							md_csinh
 *
 *	Complex hyperbolic sine
 *
 *
 *
 * SYNOPSIS:
 *
 * void md_csinh();
 * cmplx z, w;
 *
 * md_csinh( &z, &w );
 *
 *
 * DESCRIPTION:
 *
 * md_csinh z = (md_cexp(z) - md_cexp(-z))/2
 *         = md_sinh x * md_cos y  +  i md_cosh x * md_sin y .
 *
 * ACCURACY:
 *
 *                      Relative error:
 * arithmetic   domain     # trials      peak         rms
 *    IEEE      -10,+10     30000       3.1e-16     8.2e-17
 *
 */

void
md_csinh (z, w)
     cmplx *z, *w;
{
  double x, y;

  x = z->r;
  y = z->i;
  w->r = md_sinh (x) * md_cos (y);
  w->i = md_cosh (x) * md_sin (y);
}


/*							md_casinh
 *
 *	Complex inverse hyperbolic sine
 *
 *
 *
 * SYNOPSIS:
 *
 * void md_casinh();
 * cmplx z, w;
 *
 * md_casinh (&z, &w);
 *
 *
 *
 * DESCRIPTION:
 *
 * md_casinh z = -i md_casin iz .
 *
 * ACCURACY:
 *
 *                      Relative error:
 * arithmetic   domain     # trials      peak         rms
 *    IEEE      -10,+10     30000       1.8e-14     2.6e-15
 *
 */

void
md_casinh (z, w)
     cmplx *z, *w;
{
  cmplx u;

  u.r = 0.0;
  u.i = 1.0;
  cmul( z, &u, &u );
  md_casin( &u, w );
  u.r = 0.0;
  u.i = -1.0;
  cmul( &u, w, w );
}

/*							md_ccosh
 *
 *	Complex hyperbolic cosine
 *
 *
 *
 * SYNOPSIS:
 *
 * void md_ccosh();
 * cmplx z, w;
 *
 * md_ccosh (&z, &w);
 *
 *
 *
 * DESCRIPTION:
 *
 * md_ccosh(z) = md_cosh x  md_cos y + i md_sinh x md_sin y .
 *
 * ACCURACY:
 *
 *                      Relative error:
 * arithmetic   domain     # trials      peak         rms
 *    IEEE      -10,+10     30000       2.9e-16     8.1e-17
 *
 */

void
md_ccosh (z, w)
     cmplx *z, *w;
{
  double x, y;

  x = z->r;
  y = z->i;
  w->r = md_cosh (x) * md_cos (y);
  w->i = md_sinh (x) * md_sin (y);
}


/*							md_cacosh
 *
 *	Complex inverse hyperbolic cosine
 *
 *
 *
 * SYNOPSIS:
 *
 * void md_cacosh();
 * cmplx z, w;
 *
 * md_cacosh (&z, &w);
 *
 *
 *
 * DESCRIPTION:
 *
 * md_acosh z = i md_acos z .
 *
 * ACCURACY:
 *
 *                      Relative error:
 * arithmetic   domain     # trials      peak         rms
 *    IEEE      -10,+10     30000       1.6e-14     2.1e-15
 *
 */

void
md_cacosh (z, w)
     cmplx *z, *w;
{
  cmplx u;

  md_cacos( z, w );
  u.r = 0.0;
  u.i = 1.0;
  cmul( &u, w, w );
}


/*							md_ctanh
 *
 *	Complex hyperbolic tangent
 *
 *
 *
 * SYNOPSIS:
 *
 * void md_ctanh();
 * cmplx z, w;
 *
 * md_ctanh (&z, &w);
 *
 *
 *
 * DESCRIPTION:
 *
 * md_tanh z = (md_sinh 2x  +  i md_sin 2y) / (md_cosh 2x + md_cos 2y) .
 *
 * ACCURACY:
 *
 *                      Relative error:
 * arithmetic   domain     # trials      peak         rms
 *    IEEE      -10,+10     30000       1.7e-14     2.4e-16
 *
 */

/* 5.253E-02,1.550E+00 1.643E+01,6.553E+00 1.729E-14  21355  */

void
md_ctanh (z, w)
     cmplx *z, *w;
{
  double x, y, d;

  x = z->r;
  y = z->i;
  d = md_cosh (2.0 * x) + md_cos (2.0 * y);
  w->r = md_sinh (2.0 * x) / d;
  w->i = md_sin (2.0 * y) / d;
  return;
}


/*							md_catanh
 *
 *	Complex inverse hyperbolic tangent
 *
 *
 *
 * SYNOPSIS:
 *
 * void md_catanh();
 * cmplx z, w;
 *
 * md_catanh (&z, &w);
 *
 *
 *
 * DESCRIPTION:
 *
 * Inverse md_tanh, equal to  -i md_catan (iz);
 *
 * ACCURACY:
 *
 *                      Relative error:
 * arithmetic   domain     # trials      peak         rms
 *    IEEE      -10,+10     30000       2.3e-16     6.2e-17
 *
 */

void
md_catanh (z, w)
     cmplx *z, *w;
{
  cmplx u;

  u.r = 0.0;
  u.i = 1.0;
  cmul (z, &u, &u);  /* i z */
  md_catan (&u, w);
  u.r = 0.0;
  u.i = -1.0;
  cmul (&u, w, w);  /* -i md_catan iz */
  return;
}


/*							md_cpow
 *
 *	Complex power function
 *
 *
 *
 * SYNOPSIS:
 *
 * void md_cpow();
 * cmplx a, z, w;
 *
 * md_cpow (&a, &z, &w);
 *
 *
 *
 * DESCRIPTION:
 *
 * Raises complex A to the complex Zth power.
 * Definition is per AMS55 # 4.2.8,
 * analytically equivalent to md_cpow(a,z) = md_cexp(z md_clog(a)).
 *
 * ACCURACY:
 *
 *                      Relative error:
 * arithmetic   domain     # trials      peak         rms
 *    IEEE      -10,+10     30000       9.4e-15     1.5e-15
 *
 */


void
md_cpow (a, z, w)
     cmplx *a, *z, *w;
{
  double x, y, r, theta, absa, arga;

  x = z->r;
  y = z->i;
  absa = md_cabs (a);
  if (absa == 0.0)
    {
      w->r = 0.0;
      w->i = 0.0;
      return;
    }
  arga = md_atan2 (a->i, a->r);
  r = md_pow (absa, x);
  theta = x * arga;
  if (y != 0.0)
    {
      r = r * md_exp (-y * arga);
      theta = theta + y * md_log (absa);
    }
  w->r = r * md_cos (theta);
  w->i = r * md_sin (theta);
  return;
}
