#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

static NV ops_run;

static int
runops_counting(pTHX)
{
    dVAR;
    while ((PL_op = CALL_FPTR(PL_op->op_ppaddr)(aTHX))) {
        PERL_ASYNC_CHECK();
        ops_run++;
    }

    TAINT_NOT;
    return 0;
}

static I32
get_ops_run(pTHX_ IV _index, SV* sv)
{
    sv_setnv(sv, ops_run);
    return 0;
}

static I32
set_ops_run(pTHX_ IV _index, SV* sv)
{
    ops_run = SvNV(sv);
    return 0;
}

MODULE = Devel::CountOps PACKAGE = Devel::CountOps

PROTOTYPES: ENABLE

BOOT:
    PL_runops = runops_counting;
    {
        struct ufuncs uf;
        SV *ops_perl = get_sv("\037OPCODES_RUN", GV_ADD);
        uf.uf_val = get_ops_run;
        uf.uf_set = set_ops_run;
        sv_magic(ops_perl, 0, PERL_MAGIC_uvar, (char*)&uf, sizeof(uf));
    }
