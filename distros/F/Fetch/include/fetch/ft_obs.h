/* ft_obs.h - the outbound request observer registry (fetch_abi v2).
 *
 * Fetch had no way to see a request go out. `headers` is a per-request option
 * the CALLER sets, which is no use to anything that wants to annotate a
 * request the application wrote - a tracing layer adding a `traceparent`, an
 * audit log recording what this process asked of whom, a metrics counter
 * timing an upstream. All of those need to reach a request they did not
 * build, and to be told how it ended.
 *
 * So: a start callback, fired once per HOP with the merged header list still
 * mutable, which returns an opaque token; and a done callback, fired exactly
 * once with that token when the request settles, however it settled.
 *
 * Registration is process-global, matching hm_abi's worker hook and Punk's
 * pk_abi observers: an agent is a per-worker object and there may be many,
 * while an observer is a property of the process.
 *
 * Needs ft_abi.h (the typedefs). Included before ft_ua.h, which fires it.
 */

#ifndef FT_OBS_H
#define FT_OBS_H

#include "fetch_abi.h"

static struct { fetch_obs_start_cb start; fetch_obs_done_cb done; void *ud; }
    FT_OBS[FETCH_ABI_MAX_OBSERVERS];
static int FT_OBS_N = 0;

/* The per-request tokens. Heap, because it has to outlive the call that made
 * it and travel to the settle callback, and one allocation per instrumented
 * request is the price of not having a fixed slot per observer on every
 * request that is not instrumented at all. */
typedef struct { void *tok[FETCH_ABI_MAX_OBSERVERS]; int n; } ft_obs_tokens;

static int ft_obs_add(pTHX_ fetch_obs_start_cb start, fetch_obs_done_cb done,
                      void *ud) {
    PERL_UNUSED_CONTEXT;
    if (!start || FT_OBS_N >= FETCH_ABI_MAX_OBSERVERS) return 0;
    FT_OBS[FT_OBS_N].start = start;
    FT_OBS[FT_OBS_N].done  = done;
    FT_OBS[FT_OBS_N].ud    = ud;
    FT_OBS_N++;
    return 1;
}

/* Fire the start half. `hav` is the merged header list, still mutable: an
 * observer may push a name and a value onto it and the request will carry
 * them. Returns the tokens, or NULL when nobody is listening. */
static ft_obs_tokens *ft_obs_start(pTHX_ const char *method, STRLEN mlen,
                                   const char *url, STRLEN ulen, AV *hav) {
    ft_obs_tokens *t;
    int i;
    if (!FT_OBS_N) return NULL;
    Newxz(t, 1, ft_obs_tokens);
    t->n = FT_OBS_N;
    for (i = 0; i < FT_OBS_N; i++)
        t->tok[i] = FT_OBS[i].start(aTHX_ method, mlen, url, ulen, hav,
                                    FT_OBS[i].ud);
    return t;
}

/* Fire the done half and free the tokens. res and err are borrowed; exactly
 * one of them is non-NULL. */
static void ft_obs_done(pTHX_ ft_obs_tokens *t, SV *res, SV *err) {
    int i;
    if (!t) return;
    for (i = 0; i < t->n && i < FT_OBS_N; i++)
        if (FT_OBS[i].done) FT_OBS[i].done(aTHX_ t->tok[i], res, err,
                                           FT_OBS[i].ud);
    Safefree(t);
}

#endif /* FT_OBS_H */
