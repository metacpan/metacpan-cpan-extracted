#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

STATIC peep_t prev_rpeepp;

STATIC OP*
pp_once(pTHX) {
    SV *const sv = PAD_SVl(PL_op->op_targ);
    SvPADSTALE_on(sv);

    return PL_ppaddr[OP_ONCE](aTHX);
}

STATIC void
my_rpeep(pTHX_ OP* o) {
    OP* orig_o = o;

    for(; o; o = o->op_next) {
        if (o->op_type == OP_PADSV) {
            o->op_private &= ~OPpPAD_STATE;

        } else if (o->op_type == OP_ONCE && o->op_ppaddr == PL_ppaddr[OP_ONCE]) {
            o->op_ppaddr = pp_once;
        }
    }

    prev_rpeepp(aTHX_ orig_o);
}

MODULE = Devel::Unstate      PACKAGE = Devel::Unstate
PROTOTYPES: DISABLE

BOOT:
{
    prev_rpeepp = PL_rpeepp;
    PL_rpeepp = my_rpeep;
}

