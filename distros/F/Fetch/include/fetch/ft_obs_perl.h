/* ft_obs_perl.h - the Perl door onto the fetch_abi v2 observer registry.
 *
 * ft_obs.h holds C function pointers, which is what an instrumented consumer
 * written in XS wants and what keeps an uninstrumented request at one branch.
 * This registers a pair of SHIMS into that same table whose user data is a
 * pair of Perl coderefs, so an application that is not an XS module can
 * observe its own outbound requests:
 *
 *     Fetch->on_request(\&start, \&done);
 *
 * The contract is deliberately identical to the C one rather than friendlier -
 * process-global, fired per hop, no deregistration - so the two doors cannot
 * drift into different semantics. What differs is only what it costs (one
 * call_sv per hop, paid by the process that asked for it) and one rule that C
 * could state and Perl cannot enforce:
 *
 *   "Neither callback may croak."
 *
 * A C consumer honours that by construction. A Perl one dies on a typo, and a
 * die propagating out of here would come up through whatever the event loop
 * was doing and take an unrelated request down with it. So both shims run
 * under G_EVAL and turn a death into a warning naming which half died: an
 * observer is a bystander, and a broken bystander must not fail the request
 * it was only watching.
 *
 * Included after ft_obs.h, which holds the table it registers into.
 */

#ifndef FT_OBS_PERL_H
#define FT_OBS_PERL_H

#include "ft_obs.h"

typedef struct { SV *start; SV *done; } ft_obs_perl;

/* The start shim. The header list arrives as an arrayref aliasing the SAME
 * AV the request is being built from, so a push in the callback reaches the
 * wire - which is the entire point of the hook. Whatever the callback returns
 * becomes the token: any Perl scalar, kept until done, which frees it. */
static void *ft_obs_perl_start(pTHX_ const char *method, STRLEN mlen,
                               const char *url, STRLEN ulen, AV *headers,
                               void *ud) {
    ft_obs_perl *p = (ft_obs_perl *)ud;
    SV *tok = NULL;
    dSP;
    int count;
    if (!p || !p->start) return NULL;
    ENTER; SAVETMPS;
    PUSHMARK(SP); EXTEND(SP, 3);
    mPUSHp(method, mlen);
    mPUSHp(url, ulen);
    mPUSHs(newRV_inc((SV *)headers));
    PUTBACK;
    count = call_sv(p->start, G_SCALAR | G_EVAL);
    SPAGAIN;
    if (SvTRUE(ERRSV)) {
        if (count > 0) (void)POPs;
        warn("Fetch: on_request start callback died: %s", SvPV_nolen(ERRSV));
    }
    else if (count > 0) {
        SV *r = POPs;
        if (SvOK(r)) tok = newSVsv(r);      /* +1; the done shim frees it */
    }
    PUTBACK; FREETMPS; LEAVE;
    return (void *)tok;
}

/* The done shim. Fires for every start, so it is also where the token dies -
 * including when the caller registered no done callback at all. */
static void ft_obs_perl_done(pTHX_ void *token, SV *res, SV *err, void *ud) {
    ft_obs_perl *p = (ft_obs_perl *)ud;
    SV *tok = (SV *)token;
    if (p && p->done) {
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP); EXTEND(SP, 3);
        PUSHs(tok ? sv_2mortal(newSVsv(tok)) : &PL_sv_undef);
        PUSHs(res ? res : &PL_sv_undef);
        PUSHs(err ? err : &PL_sv_undef);
        PUTBACK;
        call_sv(p->done, G_DISCARD | G_EVAL);
        SPAGAIN; PUTBACK; FREETMPS; LEAVE;
        if (SvTRUE(ERRSV))
            warn("Fetch: on_request done callback died: %s",
                 SvPV_nolen(ERRSV));
    }
    if (tok) SvREFCNT_dec(tok);
}

/* Fetch->on_request(\&start, \&done). A non-coderef croaks here, in the
 * caller's own frame: that is a mistake at registration time, and finding out
 * about it during an unrelated request would be far worse. `done` is
 * optional. */
static int ft_obs_add_perl(pTHX_ SV *start, SV *done) {
    ft_obs_perl *p;
    int have_done = (done && SvOK(done));
    if (!(start && SvROK(start) && SvTYPE(SvRV(start)) == SVt_PVCV))
        croak("Fetch->on_request: the start callback must be a code reference");
    if (have_done && !(SvROK(done) && SvTYPE(SvRV(done)) == SVt_PVCV))
        croak("Fetch->on_request: the done callback must be a code reference");
    Newxz(p, 1, ft_obs_perl);
    p->start = newSVsv(start);
    p->done  = have_done ? newSVsv(done) : NULL;
    /* the done shim is registered either way: it owns freeing the token */
    if (!ft_obs_add(aTHX_ ft_obs_perl_start, ft_obs_perl_done, p)) {
        SvREFCNT_dec(p->start);
        if (p->done) SvREFCNT_dec(p->done);
        Safefree(p);
        return 0;
    }
    return 1;
}

#endif /* FT_OBS_PERL_H */
