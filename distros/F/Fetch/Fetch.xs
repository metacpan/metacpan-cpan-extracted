/*
 * Fetch.xs - root XS file
 *
 * Thin wrapper (Hyperman-style layout): pulls in the vendored C core from
 * include/fetch/ (readiness backends + Future + loop + HTTP/1.1/2 + TLS, plus
 * the Headers/CookieJar/user-agent logic), then the per-package XS fragments
 * via INCLUDE:. All Fetch behaviour lives in C; the .pm files are
 * documentation/loader stubs (except the foreign event-loop adapters, which
 * are Perl glue over other frameworks).
 */

/* Native Windows: rand_s() (ft_win.h) is only declared by <stdlib.h> when
 * _CRT_RAND_S is set before it is first included - and perl.h pulls <stdlib.h>
 * in. So define it here, ahead of every include. No-op off Windows. */
#ifdef _WIN32
#define _CRT_RAND_S
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "fetch/ft_compat.h"   /* perl-version portability shims (pre-5.16) */
#include "fetch/ft_core.h"

/* ---- helpers -------------------------------------------------------------- */

static ft_loop *ft_loop_from_sv(pTHX_ SV *sv) {
    if (!(SvROK(sv) && SvIOK(SvRV(sv))))
        croak("Fetch::Loop: not a loop object");
    return INT2PTR(ft_loop *, SvIV(SvRV(sv)));
}

static ft_pool *ft_pool_from_sv(pTHX_ SV *sv) {
    if (!SvOK(sv) || !(SvROK(sv) && SvIOK(SvRV(sv)))) return NULL;
    return INT2PTR(ft_pool *, SvIV(SvRV(sv)));
}

static int ft_fileno(pTHX_ SV *fh) {
    if (SvROK(fh) || SvTYPE(fh) == SVt_PVGV) {
        IO *io = sv_2io(fh);
        if (io && IoIFP(io)) return PerlIO_fileno(IoIFP(io));
        return -1;
    }
    return (int)SvIV(fh);   /* a bare fd number */
}

static int ft_mode(pTHX_ SV *m) {
    const char *s = SvPV_nolen(m);
    int mask = 0;
    if (strchr(s, 'r')) mask |= HM_EV_READ;
    if (strchr(s, 'w')) mask |= HM_EV_WRITE;
    if (!mask) croak("watch_io: mode must contain 'r' and/or 'w'");
    return mask;
}

/* does the (blessed) object $obj resolve a method named $meth? (->can) */
static int ft_obj_can(pTHX_ SV *obj, const char *meth) {
    HV *stash;
    if (!sv_isobject(obj)) return 0;
    stash = SvSTASH(SvRV(obj));
    return stash && gv_fetchmethod_autoload(stash, meth, FALSE) ? 1 : 0;
}

/* the user agent - URL parsing, header merge, cookies, request build, and
 * redirect following (depends on the statics above, so included here) */
#include "fetch/ft_ua.h"

/* the C ABI table other XS modules (e.g. Reverse::Proxy) call through */
#include "fetch/ft_abi.h"

MODULE = Fetch		PACKAGE = Fetch

PROTOTYPES: DISABLE

INCLUDE: xs/fetch.xs
INCLUDE: xs/abi.xs
INCLUDE: xs/future.xs
INCLUDE: xs/loop.xs
INCLUDE: xs/headers.xs
INCLUDE: xs/response.xs
INCLUDE: xs/cookiejar.xs
INCLUDE: xs/websocket.xs
