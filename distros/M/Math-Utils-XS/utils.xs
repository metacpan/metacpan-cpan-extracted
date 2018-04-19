#define PERL_NO_GET_CONTEXT      /* we want efficiency */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <math.h>

static int sum_value(pTHX_ double* sum, double* correction, SV* value)
{
    double term = 0.0;
    double new_sum = 0.0;

    do {
        if (SvIOK(value)) {
            term = SvIV(value);
            break;
        }
        if (SvNOK(value)) {
            term = SvNV(value);
            break;
        }
        if (SvROK(value)) {
            SV* ref = SvRV(value);
            if (SvTYPE(ref) == SVt_PVAV) {
                int j = 0;
                AV* data = (AV*) ref;
                int top = av_top_index(data) + 1;
                for (j = 0; j < top; ++j) {
                    SV** elem = av_fetch(data, j, 0);
                    if (!elem || !*elem) {
                        break; // could not get element
                    }
                    sum_value(aTHX_ sum, correction, *elem);
                }
            }
            break;
        }

        croak("Cannot handle parameter");
        return 0;
    } while (0);

    new_sum = *sum + term;
    if (fabs(*sum) >= fabs(term)) {
        *correction += (*sum - new_sum) + term;
    }
    else {
        *correction += (term - new_sum) + *sum;
    }
    *sum = new_sum;
    return 1;
}

MODULE = Math::Utils::XS       PACKAGE = Math::Utils::XS
PROTOTYPES: DISABLE

#################################################################

double
log10(double n)
  CODE:
    RETVAL = log10(n);
  OUTPUT: RETVAL

double
log2(double n)
  CODE:
    RETVAL = log2(n);
  OUTPUT: RETVAL

double
floor(double n)
  CODE:
    RETVAL = floor(n);
  OUTPUT: RETVAL

double
ceil(double n)
  CODE:
    RETVAL = ceil(n);
  OUTPUT: RETVAL

int
sign(double n)
  CODE:
    RETVAL = n < 0 ? -1
           : n > 0 ? +1
           : 0;
  OUTPUT: RETVAL

double
fsum(...)
  PREINIT:
    double sum = 0.0;
    double correction = 0.0;
    int j = 0;
  CODE:
    for (j = 0; j < items; ++j) {
        sum_value(aTHX_ &sum, &correction, ST(j));
    }
    RETVAL = sum + correction;
  OUTPUT: RETVAL
