#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = IPC::Shareable  PACKAGE = IPC::Shareable

PROTOTYPES: DISABLE

# XS version of _is_child()

SV *
_is_child_xs(sv)
    SV *sv
  CODE:
    if (!sv || !SvROK(sv)) {
        RETVAL = &PL_sv_undef;
    }
    else {
        SV *rv = SvRV(sv);
        MAGIC *mg = NULL;
        switch (SvTYPE(rv)) {
            case SVt_PVHV:
            case SVt_PVAV:
                mg = mg_find(rv, PERL_MAGIC_tied);
                break;
            case SVt_PVMG:
                mg = mg_find(rv, PERL_MAGIC_tiedscalar);
                break;
            default:
                break;
        }
        if (mg && mg->mg_obj && sv_derived_from(mg->mg_obj, "IPC::Shareable")) {
            RETVAL = SvREFCNT_inc(mg->mg_obj);
        }
        else {
            RETVAL = &PL_sv_undef;
        }
    }
  OUTPUT:
    RETVAL
