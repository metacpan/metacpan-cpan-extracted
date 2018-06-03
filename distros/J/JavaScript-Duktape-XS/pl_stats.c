#include "pl_util.h"
#include "pl_stats.h"

static void save_stat(pTHX_ Duk* duk, const char* category, const char* name, double value)
{
    STRLEN clen = strlen(category);
    STRLEN nlen = strlen(name);
    HV* data = 0;
    SV** found = hv_fetch(duk->stats, category, clen, 0);
    if (found) {
        SV* ref = SvRV(*found);
        /* value not a valid hashref? bail out */
        if (SvTYPE(ref) != SVt_PVHV) {
            return;
        }
        data = (HV*) ref;
    } else {
        data = newHV();
        SV* ref = newRV_noinc((SV*) data);
        if (hv_store(duk->stats, category, clen, ref, 0)) {
            SvREFCNT_inc(ref);
        }
    }

    SV* pvalue = sv_2mortal(newSVnv(value));
    if (hv_store(data, name, nlen, pvalue, 0)) {
        SvREFCNT_inc(pvalue);
    }
}

void pl_stats_start(pTHX_ Duk* duk, Stats* stats)
{
    if (!(duk->flags & DUK_OPT_FLAG_GATHER_STATS)) {
        return;
    }
    stats->t0 = now_us();
    stats->m0 = total_memory_pages() * duk->pagesize;
}

void pl_stats_stop(pTHX_ Duk* duk, Stats* stats, const char* name)
{
    if (!(duk->flags & DUK_OPT_FLAG_GATHER_STATS)) {
        return;
    }
    stats->t1 = now_us();
    stats->m1 = total_memory_pages() * duk->pagesize;

    save_stat(aTHX_ duk, name, "elapsed_us", stats->t1 - stats->t0);
    save_stat(aTHX_ duk, name, "memory_bytes", stats->m1 - stats->m0);
}
