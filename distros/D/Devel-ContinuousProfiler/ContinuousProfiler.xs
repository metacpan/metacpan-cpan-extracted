#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#ifndef USE_ITHREADS
int count_down;
int inside_logger;
int log_size;
#endif

void
take_snapshot(pTHX)
{
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);

    call_pv("Devel::ContinuousProfiler::take_snapshot",G_DISCARD|G_NOARGS);

    FREETMPS;
    LEAVE;
}


int
sp_runops(pTHX)
{
    dVAR;
#ifdef USE_ITHREADS
    SV * count_down_sv, *inside_logger_sv, *log_size_sv;
    register OP *op = PL_op;
    while ((PL_op = op = CALL_FPTR(op->op_ppaddr)(aTHX))) {
        count_down_sv = get_sv("Devel::ContinuousProfiler::count_down", 0);
        assert(count_down_sv);
        assert(SvIV(count_down_sv) >= 0);

        if (SvTRUE(count_down_sv)) {
            sv_dec(count_down_sv);
        }
        else {
            inside_logger_sv = get_sv("Devel::ContinuousProfiler::inside_logger", 0);
            assert(inside_logger_sv);
            assert(SvIV(inside_logger_sv) == 1
                || SvIV(inside_logger_sv) == 0);

            log_size_sv = get_sv("Devel::ContinuousProfiler::log_size", GV_ADD);
            assert(log_size_sv);

            if (SvTRUE(inside_logger_sv)) {
                sv_inc(log_size_sv);
            }
            else {
                sv_setiv(inside_logger_sv, 1);
                sv_setiv(log_size_sv, 0);
                take_snapshot(aTHX);
                sv_setiv(
                    count_down_sv,
                    SvIV(log_size_sv) > 1024
                        ? (SvIV(log_size_sv) << 10)
                        : (1024 << 10));
                sv_setiv(inside_logger_sv, 0);
            }
        }
    }
#else
    register OP *op = PL_op;
    while ((PL_op = op = CALL_FPTR(op->op_ppaddr)(aTHX))) {
        if ( count_down > 0 ) {
            -- count_down;
        }
        else {
            if ( inside_logger ) {
                ++ log_size;
            }
            else {
                inside_logger = 1;
                log_size = 0;
                take_snapshot(aTHX);
                count_down =
                    log_size > 1024
                        ? (log_size << 10)
                        : (1024 << 10);
                inside_logger = 0;
            }
        }
    }
#endif

    TAINT_NOT;
    return 0;
}

void
_initialize()
{
#ifdef USE_ITHREADS
    sv_setiv(get_sv("Devel::ContinuousProfiler::count_down", GV_ADD), 0);
    sv_setiv(get_sv("Devel::ContinuousProfiler::inside_logger", GV_ADD), 0);
    sv_setiv(get_sv("Devel::ContinuousProfiler::log_size", GV_ADD), 1024 < 10);
#endif
    PL_runops = sp_runops;
}

MODULE = Devel::ContinuousProfiler PACKAGE = Devel::ContinuousProfiler

PROTOTYPES: DISABLE

void
_initialize()

BOOT:
    _initialize();
