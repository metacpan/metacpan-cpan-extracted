#ifndef FT_HM_H
#define FT_HM_H

/* Hyperman's public C ABI (hm_abi.h, vendored at a pinned HM_ABI_VERSION),
 * resolved lazily at runtime via Hyperman::_abi_ptr - the same pattern as
 * ft_json.h's frj table. When a UA drives a Hyperman loop, the connection
 * state machine arms fd interest and deadlines straight through this table:
 * readiness and timeouts reach ft_conn with no Perl call frame and no
 * per-arm method dispatch. When Hyperman is absent (or its ABI is older
 * than ours) ft_hm() returns NULL and the Perl adapter seam
 * (Fetch::Loop::Hyperman's _ft_arm/_ft_timer) keeps working unchanged. */

#include "hm_abi.h"

static const hm_abi *FT_HM = NULL;   /* resolved on first use */

static const hm_abi *ft_hm(pTHX) {
    if (!FT_HM) {
        dSP;
        int count;
        ENTER; SAVETMPS; PUSHMARK(SP); PUTBACK;
        count = call_pv("Hyperman::_abi_ptr", G_SCALAR | G_EVAL);
        SPAGAIN;
        if (!SvTRUE(ERRSV) && count > 0) {
            IV p = POPi;
            if (p) {
                const hm_abi *a = INT2PTR(const hm_abi *, p);
                if (a->abi_version >= HM_ABI_VERSION) FT_HM = a;
            }
        } else if (count > 0) (void)POPs;
        PUTBACK; FREETMPS; LEAVE;
    }
    return FT_HM;
}

/* ---- C await: $Fetch::Future::AWAIT over run_until -----------------------
 *
 * Awaiting a pending Fetch::Future on a Hyperman loop bridges it to a
 * Hyperman::Future (created and settled only through the ABI - no layout
 * assumption crosses the dist boundary; the Fetch future is touched only
 * with Fetch's own hmf_* helpers) and pumps the loop with run_until. This
 * replaces the Perl AWAIT sub (is_ready + on_ready(sub { $loop->stop }) +
 * $loop->run per await), and its stop flag: each nested await returns
 * exactly when ITS bridge settles, so an inner await can never break an
 * outer pump the way a mis-aimed ->stop could. */

/* settles the bridge (cl->a) when the awaited Fetch::Future readies */
XS_INTERNAL(ft_hm_bridge_cb);
XS_INTERNAL(ft_hm_bridge_cb) {
    dVAR; dXSARGS;
    hm_clos *cl = hm_clos_of(aTHX_ cv);
    const hm_abi *A = ft_hm(aTHX);
    PERL_UNUSED_VAR(items);
    if (cl && cl->a && A) A->future_done(aTHX_ cl->a, NULL, 0);
    XSRETURN_EMPTY;
}

/* the AWAIT body: cl->b = the Fetch::Loop::Hyperman adapter (refcounted, so
 * the Hyperman loop outlives the global), cl->u = the opaque loop handle */
XS_INTERNAL(ft_hm_await_cb);
XS_INTERNAL(ft_hm_await_cb) {
    dVAR; dXSARGS;
    hm_clos *cl = hm_clos_of(aTHX_ cv);
    const hm_abi *A = ft_hm(aTHX);
    SV *f, *bridge, *cb;
    if (!cl || !A || items < 1) XSRETURN_EMPTY;
    f = ST(0);
    if (hmf_state(aTHX_ f) != HMF_PENDING) XSRETURN_EMPTY;
    bridge = A->future_new(aTHX);
    cb = hm_closure(aTHX_ ft_hm_bridge_cb, bridge, NULL, NULL, NULL, 0, 0);
    hmf_on_ready(aTHX_ f, cb);
    SvREFCNT_dec(cb);
    A->run_until(aTHX_ INT2PTR(void *, cl->u), bridge);
    SvREFCNT_dec(bridge);
    XSRETURN_EMPTY;
}

/* overwrite whatever install_await put in $Fetch::Future::AWAIT */
static void ft_hm_install_await(pTHX_ SV *adapter, void *hm_loop) {
    SV *cb = hm_closure(aTHX_ ft_hm_await_cb, NULL, adapter, NULL, NULL,
                        0, PTR2UV(hm_loop));
    SV *aw = get_sv("Fetch::Future::AWAIT", GV_ADD);
    sv_setsv(aw, cb);
    SvREFCNT_dec(cb);
}

#endif /* FT_HM_H */
