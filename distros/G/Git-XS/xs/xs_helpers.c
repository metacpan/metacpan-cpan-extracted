#include <xs_helpers.h>

SV * call_getter(SV *self, char *has) {
    dSP;
    int count;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(self);
    PUTBACK;

    count = call_method(has, G_SCALAR);

    SPAGAIN;

    if (SvTRUE(ERRSV)) {
        POPs;
        croak("Git::XS error - %s\n", SvPV_nolen(ERRSV));
    }

    if (count != 1)
        croak("O NOES");

    SV *ret = SvREFCNT_inc(POPs);

    PUTBACK;
    FREETMPS;
    LEAVE;

    return ret;
}

int call_test(SV *self, char *test, SV* arg) {
    dSP;
    int count;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(self);
    XPUSHs(arg);
    PUTBACK;

    count = call_method(test, G_SCALAR);

    SPAGAIN;

    if (SvTRUE(ERRSV)) {
        POPs;
        croak("Git::XS error - %s\n", SvPV_nolen(ERRSV));
    }

    if (count != 1)
        croak("O NOES");

    int ret = POPi;

    PUTBACK;
    FREETMPS;
    LEAVE;

    return ret;
}


