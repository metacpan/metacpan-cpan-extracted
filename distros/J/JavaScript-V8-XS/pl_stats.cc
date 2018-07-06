#include "pl_util.h"
#include "pl_stats.h"

static void save_stat(pTHX_ V8Context* ctx, const char* category, const char* name, double value)
{
    STRLEN clen = strlen(category);
    STRLEN nlen = strlen(name);
    HV* data = 0;
    SV* pvalue = 0;
    SV** found = hv_fetch(ctx->stats, category, clen, 0);
    if (found) {
        SV* ref = SvRV(*found);
        /* value not a valid hashref? bail out */
        if (SvTYPE(ref) != SVt_PVHV) {
            croak("Found category %s in stats but it is not a hashref\n", category);
            return;
        }
        data = (HV*) ref;
    } else {
        SV* ref = 0;
        data = newHV();
        ref = newRV_noinc((SV*) data);
        if (hv_store(ctx->stats, category, clen, ref, 0)) {
            SvREFCNT_inc(ref);
        }
        else {
            croak("Could not create category %s in stats\n", category);
        }
    }

    pvalue = sv_2mortal(newSVnv(value));
    if (hv_store(data, name, nlen, pvalue, 0)) {
        SvREFCNT_inc(pvalue);
    }
    else {
        croak("Could not create entry %s for category %s in stats\n", name, category);
    }
}

void pl_stats_start(pTHX_ V8Context* ctx, Perf* perf)
{
    if (!(ctx->flags & V8_OPT_FLAG_GATHER_STATS)) {
        return;
    }
    perf->t0 = now_us();
    perf->m0 = total_memory_pages() * ctx->pagesize_bytes;
}

void pl_stats_stop(pTHX_ V8Context* ctx, Perf* perf, const char* name)
{
    if (!(ctx->flags & V8_OPT_FLAG_GATHER_STATS)) {
        return;
    }
    perf->t1 = now_us();
    perf->m1 = total_memory_pages() * ctx->pagesize_bytes;

    save_stat(aTHX_ ctx, name, "elapsed_us", perf->t1 - perf->t0);
    save_stat(aTHX_ ctx, name, "memory_bytes", perf->m1 - perf->m0);
}
