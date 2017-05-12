
#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include "math.h"

#define SQRT2PI 2.506628274631

inline NV _pdf(NV x, NV m, NV s) {
    NV z = (x - m)/s;
    return exp(-0.5 * z * z) / (SQRT2PI * s);
}

MODULE = Math::Gauss::XS   PACKAGE = Math::Gauss::XS

PROTOTYPES: DISABLE

NV
pdf(...)
    CODE:
        NV x = items > 0 ? SvNV(ST(0)) : 0;
        NV m = items > 1 ? SvNV(ST(1)) : 0;
        NV s = items > 2 ? SvNV(ST(2)) : 1;

        if (s <= 0) {
          Perl_croak(aTHX_ "Can't evaluate Math::Gauss:pdf for $s=%f not strictly positive", s);
        }

        RETVAL = _pdf(x, m, s);
    OUTPUT:
        RETVAL


NV
cdf(...)
    CODE:
        NV x = items > 0 ? SvNV(ST(0)) : 0;
        NV m = items > 1 ? SvNV(ST(1)) : 0;
        NV s = items > 2 ? SvNV(ST(2)) : 1;

        if (s <= 0) {
          Perl_croak(aTHX_ "Can't evaluate Math::Gauss:cdf for $s=%f not strictly positive", s);
        }

        NV z = (x - m)/s;
        NV t = 1.0/(1.0 + 0.2316419*fabs(z));
        NV y = t*(0.319381530
                  + t*(-0.356563782
                    + t*(1.781477937
                      + t*(-1.821255978
                        + t*1.330274429 ))));
        // fprintf(stderr, "x = %f, t = %f, y = %f\n", x, t, y);
        RETVAL = (z > 0)
          ? (1.0 - _pdf( z, 0, 1 ) * y)
          : _pdf( z, 0, 1 ) * y;
    OUTPUT:
        RETVAL


NV
inv_cdf(NV x)
    CODE:
        if ( x<=0.0 || x>=1.0 ) {
          Perl_croak(aTHX_ "Can't evaluate Math::Gauss::inv_cdf for $x=%f outside ]0,1[", x);
        }

        NV t = (x < 0.5) ? sqrt(-2.0 * log(x)) : sqrt( -2.0*log(1.0 - x) );
        NV y = (2.515517 + t*(0.802853 + t*0.010328));
        y /= 1.0 + t*(1.432788 + t*(0.189269 + t*0.001308));
        RETVAL = (x < 0.5) ? y - t : t -y;
    OUTPUT:
        RETVAL
