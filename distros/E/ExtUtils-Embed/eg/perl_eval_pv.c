
/* we'll do this until 5.004 final */
#include "patchlevel.h"
#if (PATCHLEVEL < 4) && (SUBVERSION < 98)

SV *
perl_eval_pv(string, croak_on_error)
char *string;
int croak_on_error;
{
    dSP;
    SV *sv = newSVpv(string,0);

    PUSHMARK(sp);
    perl_eval_sv(sv, G_SCALAR);
    SvREFCNT_dec(sv);

    SPAGAIN;
    sv = POPs;
    PUTBACK;

    if (croak_on_error && SvTRUE(GvSV(errgv)))
	croak(SvPV(GvSV(errgv),na));

    return sv;
}

#endif
