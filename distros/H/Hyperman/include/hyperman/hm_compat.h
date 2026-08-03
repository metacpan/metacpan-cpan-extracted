#ifndef HM_COMPAT_H
#define HM_COMPAT_H

/* Hyperman - perl API compatibility shims.
 *
 * The C core is written against a modern perl API but the distribution
 * supports older toolchains. This header backfills the handful of macros
 * and functions the core relies on that only appeared in later perls, so
 * hm_core.h / hm_future.h / hm_http2.h / hm_tls.h compile unchanged.
 *
 * Must be included after EXTERN.h / perl.h / XSUB.h (it needs the perl
 * headers for XS, MAGIC, SvMAGIC, ERRSV, croak, etc.).
 *
 * Coverage (declared floor is perl 5.10):
 *   XS_INTERNAL / XS_EXTERNAL  - added 5.15.4 (5.16)
 *   mg_findext                 - added 5.13.7 (5.14)
 *   croak_sv                   - added 5.13.1
 * On 5.10-5.15 one or more of these is absent; everything the core needs
 * beyond them (sv_magicext, hv_fetchs, ...) exists from 5.10 onward. */

/* XSUB entry points. Before the internal/external split every XSUB used
 * XS(name), which already supplies the pTHX_/CV* cv signature; fall back
 * to it so the "cv" the callbacks reference stays in scope. */
#ifndef XS_INTERNAL
#  define XS_INTERNAL(name) XS(name)
#endif
#ifndef XS_EXTERNAL
#  define XS_EXTERNAL(name) XS(name)
#endif

/* mg_findext: find the ext-magic slot on an SV matching a given vtbl.
 * Trivially reconstructed from the magic chain on perls that lack it. */
#ifndef mg_findext
static MAGIC *
hm_mg_findext(const SV *sv, int type, const MGVTBL *vtbl)
{
    if (sv) {
        const MAGIC *mg;
        for (mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic) {
            if (mg->mg_type == type && mg->mg_virtual == vtbl)
                return (MAGIC *)mg;
        }
    }
    return NULL;
}
#  define mg_findext(sv, type, vtbl) hm_mg_findext((sv), (type), (vtbl))
#endif

/* croak_sv: throw an SV as the exception, preserving objects/refs (a
 * failed Future can carry a blessed error). Stash it in $@ and re-throw
 * with croak(NULL), which raises the current ERRSV verbatim. */
#ifndef croak_sv
static void
hm_croak_sv(pTHX_ SV *sv)
{
    sv_setsv(ERRSV, sv);
    croak(NULL);
}
#  define croak_sv(sv) hm_croak_sv(aTHX_ (sv))
#endif

#endif /* HM_COMPAT_H */
