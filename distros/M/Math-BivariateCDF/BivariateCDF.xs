#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <toms462.h>

MODULE = Math::BivariateCDF		PACKAGE = Math::BivariateCDF		



NV
bivnor(ah, ak, r)
	NV	ah
	NV	ak
	NV	r
    CODE:
        if (r > 1 || r < -1) {
          Perl_croak(aTHX_ "Can't evaluate Math::BivariateCDF::bivnor for |$r|>%f ", r );
        }

        RETVAL = bivnor(ah, ak, r);
    OUTPUT:
        RETVAL
