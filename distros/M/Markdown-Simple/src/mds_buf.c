#include "mds_buf.h"
#include <string.h>

/* Measured output/input ratios per bench corpus:
 *   progit (prose)              1.04
 *   commonmark-spec             1.12
 *   synth-prose                 1.21
 *   synth-tables                2.08    \u2190 dominates the high end
 * Old heuristic was a flat 1.25\u00d7 + 64, which under-allocated by 2 grows
 * on table-heavy inputs (a 1MB synth-tables corpus triggered two
 * SvGROW realloc-copies of >1 MB each). New heuristic samples up to
 * 4 KB of the head of the input to estimate pipe density; high pipe
 * density (table corpora) gets 2.25\u00d7, everything else gets 1.50\u00d7.
 * The 64-byte slack remains so tiny inputs never start at zero. */
static size_t mds_buf_predict_cap(const char* s, size_t hint) {
    if (hint == 0) return 64;
    size_t scan = hint < 4096 ? hint : 4096;
    size_t pipes = 0, newlines = 0;
    if (s) {
        for (size_t i = 0; i < scan; i++) {
            unsigned char c = (unsigned char)s[i];
            pipes    += (c == '|');
            newlines += (c == '\n');
        }
    }
    /* Table heuristic: average >= 1 pipe per line in the sampled head. */
    int table_heavy = (newlines && pipes >= newlines);
    size_t cap = table_heavy
        ? hint + (hint >> 1) + (hint >> 2) + 64    /* ~2.25\u00d7 */
        : hint + (hint >> 1) + 64;                  /* ~1.50\u00d7 */
    return cap;
}

void mds_buf_init(pTHX_ mds_buf* b, SV* sv, size_t hint) {
    b->sv = sv;
    size_t cap = mds_buf_predict_cap(SvPVX(sv), hint);
    /* Note: at this point sv has no PV yet; the predictor falls into the
     * `s == NULL` branch and returns the prose-default 1.5\u00d7. Callers
     * that want table-density sizing should call mds_buf_init_for_input
     * below with the input pointer. */
    SvUPGRADE(sv, SVt_PV);
    SvGROW(sv, cap);
    SvCUR_set(sv, 0);
    SvPOK_on(sv);
    b->base = SvPVX(sv);
    b->cur  = b->base;
    b->end  = b->base + SvLEN(sv) - 1;   /* keep room for NUL */
    *b->cur = '\0';
}

void mds_buf_init_for_input(pTHX_ mds_buf* b, SV* sv,
                            const char* input, size_t hint) {
    b->sv = sv;
    size_t cap = mds_buf_predict_cap(input, hint);
    SvUPGRADE(sv, SVt_PV);
    SvGROW(sv, cap);
    SvCUR_set(sv, 0);
    SvPOK_on(sv);
    b->base = SvPVX(sv);
    b->cur  = b->base;
    b->end  = b->base + SvLEN(sv) - 1;
    *b->cur = '\0';
}

MDS_COLD void mds_buf_reserve(pTHX_ mds_buf* b, size_t need) {
    size_t used = (size_t)(b->cur - b->base);
    size_t cap  = SvLEN(b->sv);
    size_t want = used + need + 1;
    if (want <= cap) {
        /* SvGROW may have been a no-op; just refresh end */
        b->end = b->base + cap - 1;
        return;
    }
    size_t newcap = cap ? cap : 64;
    while (newcap < want) newcap = newcap + (newcap >> 1) + 64;  /* 1.5x */
    /* materialise current cursor into SvCUR so SvGROW preserves it */
    SvCUR_set(b->sv, used);
    SvGROW(b->sv, newcap);
    b->base = SvPVX(b->sv);
    b->cur  = b->base + used;
    b->end  = b->base + SvLEN(b->sv) - 1;
}

void mds_buf_finalize(pTHX_ mds_buf* b) {
    size_t used = (size_t)(b->cur - b->base);
    SvCUR_set(b->sv, used);
    if (b->base) b->base[used] = '\0';
    SvPOK_on(b->sv);
}
