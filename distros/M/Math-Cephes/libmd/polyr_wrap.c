
/* Arithmetic operations on polynomials with rational coefficients
 *
 * In the following descriptions a, b, c are polynomials of degree
 * na, nb, nc respectively.  The degree of a polynomial cannot
 * exceed a run-time value FMAXPOL.  An operation that attempts
 * to use or generate a polynomial of higher degree may produce a
 * result that suffers truncation at degree FMAXPOL.  The value of
 * FMAXPOL is set by calling the function
 *
 *     polini( maxpol );
 *
 * where maxpol is the desired maximum degree.  This must be
 * done prior to calling any of the other functions in this module.
 * Memory for internal temporary polynomial storage is allocated
 * by polini().
 *
 * Each polynomial is represented by an array containing its
 * coefficients, together with a separately declared integer equal
 * to the degree of the polynomial.  The coefficients appear in
 * ascending order; that is,
 *
 *                                        2                      na
 * a(x)  =  a[0]  +  a[1] * x  +  a[2] * x   +  ...  +  a[na] * x  .
 *
 *   wrapper functions to the following:
 *
 * `a', `b', `c' are arrays of fracts.
 * fpoleva( a, na, &x, &sum );	Evaluate polynomial a(t) at t = x.
 * fpoladd( a, na, b, nb, c );	c = b + a, nc = max(na,nb)
 * fpolsub( a, na, b, nb, c );	c = b - a, nc = max(na,nb)
 * fpolmul( a, na, b, nb, c );	c = b * a, nc = na+nb
 *
 *
 * Division:
 *
 * i = fpoldiv( a, na, b, nb, c );	c = b / a, nc = FMAXPOL
 *
 * returns i = the degree of the first nonzero coefficient of a.
 * The computed quotient c must be divided by x^i.  An error message
 * is printed if a is identically zero.
 *
 *
 * Change of variables:
 * If a and b are polynomials, and t = a(x), then
 *     c(t) = b(a(x))
 * is a polynomial found by substituting a(x) for t.  The
 * subroutine call for this is
 *
 * fpolsbt( a, na, b, nb, c );
 *
 *
 * Notes:
 * fpoldiv() is an integer routine; fpoleva() is double.
 * Any of the arguments a, b, c may refer to the same array.
 *
 */

#include <stdio.h>
#include "mconf.h"
#ifndef NULL
#define NULL 0
#endif
typedef struct{
	double n;
	double d;
	}fract;

#ifdef ANSIPROT
extern void * malloc ( long );
extern void free ( void * );
#else
void * malloc();
void free ();
#endif

int FMAXPOL = 0;
extern int FMAXPOL;


void fpoladd_wrap( an, ad, na, bn, bd, nb, cn, cd, nc)
double an[], ad[], bn[], bd[], cn[], cd[];
int na, nb, nc;
{
  extern void fpoladd(  fract a[], int na, fract b[], int nb, fract c[]);
  fract *a, *b, *c;
  int j;
  a = (fract *) malloc( (na+1) * sizeof (fract) ); 
  b = (fract *) malloc( (nb+1) * sizeof (fract) ); 
  c = (fract *) malloc( (nc+1) * sizeof (fract) ); 
  for (j=0; j<=na; j++) {
    a[j].n = an[j];
    a[j].d = ad[j];
  }
  for (j=0; j<=nb; j++) {
    b[j].n = bn[j];
    b[j].d = bd[j];
  }
  for (j=0; j<=nc; j++) {
    c[j].n = 0;
    c[j].d = 1;
  }
  fpoladd(a, na, b, nb, c);
  for (j=0; j<=nc; j++) {
    cn[j] = c[j].n;
    cd[j] = c[j].d;
  }
  free(a);
  free(b);
  free(c);
}

void fpolsub_wrap( an, ad, na, bn, bd, nb, cn, cd, nc)
double an[], ad[], bn[], bd[], cn[], cd[];
int na, nb, nc;
{
  extern void fpolsub(  fract a[], int na, fract b[], int nb, fract c[]);
  fract *a, *b, *c;
  int j;
  a = (fract *) malloc( (na+1) * sizeof (fract) ); 
  b = (fract *) malloc( (nb+1) * sizeof (fract) ); 
  c = (fract *) malloc( (nc+1) * sizeof (fract) ); 
  for (j=0; j<=na; j++) {
    a[j].n = an[j];
    a[j].d = ad[j];
  }
  for (j=0; j<=nb; j++) {
    b[j].n = bn[j];
    b[j].d = bd[j];
  }
  for (j=0; j<=nc; j++) {
    c[j].n = 0;
    c[j].d = 1;
  }
  fpolsub(a, na, b, nb, c);
  for (j=0; j<=nc; j++) {
    cn[j] = c[j].n;
    cd[j] = c[j].d;
  }
  free(a);
  free(b);
  free(c);
}

void fpolmul_wrap( an, ad, na, bn, bd, nb, cn, cd, nc)
double an[], ad[], bn[], bd[], cn[], cd[];
int na, nb, nc;
{
  extern void fpolmul(  fract a[], int na, fract b[], int nb, fract c[]);
  fract *a, *b, *c;
  int j;
  a = (fract *) malloc( (na+1) * sizeof (fract) ); 
  b = (fract *) malloc( (nb+1) * sizeof (fract) ); 
  c = (fract *) malloc( (nc+1) * sizeof (fract) ); 
  for (j=0; j<=na; j++) {
    a[j].n = an[j];
    a[j].d = ad[j];
  }
  for (j=0; j<=nb; j++) {
    b[j].n = bn[j];
    b[j].d = bd[j];
  }
  for (j=0; j<=nc; j++) {
    c[j].n = 0;
    c[j].d = 1;
  }
  fpolmul(a, na, b, nb, c);
  for (j=0; j<=nc; j++) {
    cn[j] = c[j].n;
    cd[j] = c[j].d;
  }
  free(a);
  free(b);
  free(c);
}

int fpoldiv_wrap( an, ad, na, bn, bd, nb, cn, cd, nc)
double an[], ad[], bn[], bd[], cn[], cd[];
int na, nb, nc;
{
  extern int fpoldiv(  fract a[], int na, fract b[], int nb, fract c[]);
  fract *a, *b, *c;
  int j, ret;
  a = (fract *) malloc( (na+1) * sizeof (fract) ); 
  b = (fract *) malloc( (nb+1) * sizeof (fract) ); 
  c = (fract *) malloc( (nc+1) * sizeof (fract) ); 
  for (j=0; j<=na; j++) {
    a[j].n = an[j];
    a[j].d = ad[j];
  }
  for (j=0; j<=nb; j++) {
    b[j].n = bn[j];
    b[j].d = bd[j];
  }
  for (j=0; j<=nc; j++) {
    c[j].n = 0;
    c[j].d = 1;
  }
  ret = fpoldiv(a, na, b, nb, c);
  for (j=0; j<=nc; j++) {
    cn[j] = c[j].n;
    cd[j] = c[j].d;
  }
  free(a);
  free(b);
  free(c);
  return ret;
}

void fpoleva_wrap( an, ad, na, x, s)
double an[], ad[];
int na;
fract *x, *s;
{
  extern void fpoleva(  fract a[], int na, fract *x, fract *s);
  fract *a;
  int j;
  a = (fract *) malloc( (na+1) * sizeof (fract) ); 
  for (j=0; j<=na; j++) {
    a[j].n = an[j];
    a[j].d = ad[j];
  }
  s->n = 0.0;
  s->d = 1.0;
  fpoleva(a, na, x, s);
  free(a);
}

void fpolsbt_wrap( an, ad, na, bn, bd, nb, cn, cd, nc)
double an[], ad[], bn[], bd[], cn[], cd[];
int na, nb, nc;
{
  extern void fpolsbt(  fract a[], int na, fract b[], int nb, fract c[]);
  fract *a, *b, *c;
  int j;
  a = (fract *) malloc( (na+1) * sizeof (fract) ); 
  b = (fract *) malloc( (nb+1) * sizeof (fract) ); 
  c = (fract *) malloc( (nc+1) * sizeof (fract) ); 
  for (j=0; j<=na; j++) {
    a[j].n = an[j];
    a[j].d = ad[j];
  }
  for (j=0; j<=nb; j++) {
    b[j].n = bn[j];
    b[j].d = bd[j];
    }
  for (j=0; j<=nc; j++) {
    c[j].n = 0;
    c[j].d = 1;
  }
  fpolsbt(a, na, b, nb, c);
  for (j=0; j<=nc; j++) {
    cn[j] = c[j].n;
    cd[j] = c[j].d;
  }
  free(a);
  free(b);
  free(c);
}

