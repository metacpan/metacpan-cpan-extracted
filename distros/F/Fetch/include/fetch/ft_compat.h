#ifndef FT_COMPAT_H
#define FT_COMPAT_H

/* Perl-version portability shims for the C core. Include after EXTERN.h /
 * perl.h / XSUB.h and before any other fetch/ header, so the definitions are
 * in scope for the C-closure callbacks throughout the core. */

/* XS_INTERNAL / XS_EXTERNAL (and XSPROTO) arrived in perl's XSUB.h at 5.16.
 * The core's C-closure callbacks (ft_future.h, ft_ua.h, ft_http.h and the ABI
 * in ft_abi.h) are declared with XS_INTERNAL, so on 5.8 - 5.14 they otherwise
 * fail to compile ("XS_INTERNAL undeclared" / "cv undeclared"). These are the
 * standard definitions, and let Fetch build on every perl it claims (5.8.3+). */
#ifndef XSPROTO
#  define XSPROTO(name) void name(pTHX_ CV *cv)
#endif
#ifndef XS_INTERNAL
#  define XS_INTERNAL(name) STATIC XSPROTO(name)
#endif
#ifndef XS_EXTERNAL
#  define XS_EXTERNAL(name) XSPROTO(name)
#endif

/* mg_findext (5.14) and croak_sv (5.13.1) postdate the oldest perls Fetch
 * claims (5.8.3). The C-closure machinery uses mg_findext to fetch the magic
 * carrying a closure's captures, and a few request paths croak_sv an error.
 * Provide both on pre-5.14 perls; newer perls use the core versions. */
#if PERL_REVISION == 5 && PERL_VERSION < 14

static MAGIC *Fetch_mg_findext(SV *sv, int type, const MGVTBL *vtbl) {
    if (sv) {
        MAGIC *mg;
        for (mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic)
            if (mg->mg_type == type && (const MGVTBL *)mg->mg_virtual == vtbl)
                return mg;
    }
    return NULL;
}
#  define mg_findext(sv, type, vtbl) Fetch_mg_findext((sv), (type), (vtbl))

#  define croak_sv(sv) Perl_croak(aTHX_ "%" SVf, SVfARG(sv))

#endif

#endif /* FT_COMPAT_H */
