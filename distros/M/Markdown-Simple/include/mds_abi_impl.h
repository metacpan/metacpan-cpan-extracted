#ifndef MDS_ABI_IMPL_H
#define MDS_ABI_IMPL_H

/* Markdown::Simple-side implementation of the shared C ABI (mds_abi.h).
 * Included by Markdown/Simple.xs AFTER mds_session_mg_vtbl, mds_flags_from_hv
 * and strip_markdown_except_lists_tables are in scope, since the session hangs
 * off the object as ext magic and the wrappers below reach the parser through
 * those file-statics. The engine is a unity build, so everything here shares a
 * translation unit with them; consumers reach it only through the MDS_ABI
 * table returned by Markdown::Simple::_abi_ptr. */

#include "mds_abi.h"

/* Like mds_session_from_self but returns NULL where that croaks: a consumer
 * probing whether an SV is a renderable session must be able to ask without an
 * eval. */
static void *mds_abi_session_of(pTHX_ SV *obj_sv)
{
    SV    *rv;
    MAGIC *mg;
    if (!obj_sv || !SvROK(obj_sv)) return NULL;
    rv = SvRV(obj_sv);
    if (!sv_derived_from(obj_sv, "Markdown::Simple")) return NULL;
    for (mg = SvMAGIC(rv); mg; mg = mg->mg_moremagic) {
        if (mg->mg_type == PERL_MAGIC_ext &&
            mg->mg_virtual == &mds_session_mg_vtbl)
            return (void *)mg->mg_ptr;
    }
    return NULL;
}

static unsigned mds_abi_flags_from_hv(pTHX_ HV *opts)
{
    return mds_flags_from_hv(aTHX_ opts);
}

/* Shared tail for both render entries: the parser signals malformed input
 * under strict_utf8 by producing nothing, so an empty result with a non-empty
 * input is the one case worth re-checking before calling it success. */
static int mds_abi_check(pTHX_ const char *in, STRLEN len, unsigned flags,
                         SV *out, STRLEN before, SV **err)
{
    if (SvCUR(out) == before && len && (flags & MDS_FLAG_STRICT_UTF8)) {
        const mds_simd_ops *ops = (flags & MDS_FLAG_NO_SIMD)
            ? mds_simd_ops_scalar() : mds_simd_get();
        if (!ops->validate_utf8(in, len)) {
            if (err) *err = sv_2mortal(newSVpvs(
                "Markdown::Simple: input is not valid UTF-8"));
            return -1;
        }
    }
    return 0;
}

static int mds_abi_session_render(pTHX_ void *session, const char *in,
                                  STRLEN len, SV *out, AV *toc, SV **err)
{
    mds_session *s = (mds_session *)session;
    STRLEN before;
    if (!s || !out) {
        if (err) *err = sv_2mortal(newSVpvs(
            "Markdown::Simple: session_render needs a session and an output SV"));
        return -1;
    }
    if (!in) { in = ""; len = 0; }
    before = SvOK(out) ? SvCUR(out) : 0;
    mds_render_html_to_sv_toc(aTHX_ in, len, s->flags, out,
                              &s->arena, &s->scratch, toc);
    return mds_abi_check(aTHX_ in, len, s->flags, out, before, err);
}

static int mds_abi_render(pTHX_ const char *in, STRLEN len, unsigned flags,
                          SV *out, AV *toc, SV **err)
{
    STRLEN before;
    if (!out) {
        if (err) *err = sv_2mortal(newSVpvs(
            "Markdown::Simple: render needs an output SV"));
        return -1;
    }
    if (!in) { in = ""; len = 0; }
    before = SvOK(out) ? SvCUR(out) : 0;
    mds_render_html_to_sv_toc(aTHX_ in, len, flags, out, NULL, NULL, toc);
    return mds_abi_check(aTHX_ in, len, flags, out, before, err);
}

/* strip_markdown_except_lists_tables walks a NUL-terminated string, so give it
 * one: the ABI takes a pointer and a length, and a consumer's bytes are not
 * required to be terminated or free of embedded NULs. newSVpvn terminates for
 * us, and truncating at an embedded NUL is the same thing the Perl-visible
 * strip_markdown does with such input. */
static int mds_abi_strip(pTHX_ const char *in, STRLEN len, SV *out, SV **err)
{
    SV *tmp, *res;
    if (!out) {
        if (err) *err = sv_2mortal(newSVpvs(
            "Markdown::Simple: strip needs an output SV"));
        return -1;
    }
    if (!in) { in = ""; len = 0; }
    tmp = sv_2mortal(newSVpvn(in, len));
    res = strip_markdown_except_lists_tables(SvPVX(tmp));
    if (!res) {
        if (err) *err = sv_2mortal(newSVpvs("Markdown::Simple: strip failed"));
        return -1;
    }
    sv_catsv(out, res);
    SvREFCNT_dec(res);
    return 0;
}

static const mds_abi MDS_ABI = {
    MDS_ABI_VERSION,
    mds_abi_flags_from_hv,
    mds_abi_session_of,
    mds_abi_session_render,
    mds_abi_render,
    mds_abi_strip,
};

#endif /* MDS_ABI_IMPL_H */
