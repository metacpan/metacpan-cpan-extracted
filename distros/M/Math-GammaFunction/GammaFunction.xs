#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#define MATHLIB_STANDALONE 1
#include <Rmath.h>

double log_gamma(double x)
{
    return gamma(x);
}

MODULE = Math::GammaFunction		PACKAGE = Math::GammaFunction		

double
log_gamma (x)
        double x
    OUTPUT:
        RETVAL

double
gamma (x)
        double x
    INIT:
        double res;
    CODE:
        res = gammafn(x);
        RETVAL = res;
    OUTPUT:
        RETVAL

int
faculty (x)
        int x
    INIT:
        int res;
    CODE:
        res = (int) gammafn(x+1);
        RETVAL = res;
    OUTPUT:
        RETVAL


double
psi (x)
        double x
    CODE:
        x = psigamma(x, 0);
        RETVAL = x;
    OUTPUT:
        RETVAL

double
psi_derivative (x, deriv)
        double x
        int deriv;
    CODE:
        x = psigamma(x, (double)deriv);
        RETVAL = x;
    OUTPUT:
        RETVAL

