#ifndef FRX_COMPAT_H
#define FRX_COMPAT_H

/* What the 5.10 floor costs, and one thing Windows costs.
 *
 * Every shim here is dead code on a modern perl, which is the problem with
 * shims: they are compiled only on the machines nobody develops on, and they
 * rot silently in between. They live in a header rather than inline in
 * XML.xs so that a scratch translation unit can #undef the macros and
 * compile them on purpose.
 *
 * Include after EXTERN.h / perl.h / XSUB.h and before everything else under
 * frx/, including <stdlib.h>.
 */

/* The PERL_IMPLICIT_SYS allocator macros, undone: in their own header so
 * the perl-free harnesses under tools/ can include it and prove it. */
#include "frx_mem.h"

/* G_LIST is the 5.36 name for G_ARRAY. Unguarded it breaks the build on
 * everything older, which is most of the smokers. */
#ifndef G_LIST
#define G_LIST G_ARRAY
#endif

/* XS_INTERNAL / XS_EXTERNAL and XSPROTO arrived in XSUB.h at 5.16. */
#ifndef XSPROTO
#  define XSPROTO(name) void name(pTHX_ CV *cv)
#endif
#ifndef XS_INTERNAL
#  define XS_INTERNAL(name) static XSPROTO(name)
#endif
#ifndef XS_EXTERNAL
#  define XS_EXTERNAL(name) XSPROTO(name)
#endif

/* mg_findext is 5.14+, and the object layer is built on it.
 *
 * The real one walks the same chain; the only thing this cannot do is find
 * magic that perl has not yet upgraded the SV for, which does not arise
 * because we attached it ourselves. */
#ifndef mg_findext
static MAGIC *
frx_mg_findext(pTHX_ const SV *sv, int type, const MGVTBL *vtbl)
{
    PERL_UNUSED_CONTEXT;
    if (sv) {
        MAGIC *mg;
        for (mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic) {
            if (mg->mg_type == type && mg->mg_virtual == vtbl)
                return mg;
        }
    }
    return NULL;
}
#define mg_findext(sv, type, vtbl) frx_mg_findext(aTHX_ (sv), (type), (vtbl))
#endif

/* croak_sv is 5.13.1+. The Perl boundary throws the formatted refusal
 * through it; on older perls the SV is rendered through %SVf, which is
 * verbatim on exactly the perls this branch compiles for. */
#ifndef croak_sv
#  define croak_sv(sv) Perl_croak(aTHX_ "%" SVf, SVfARG(sv))
#endif

/* PERL_STATIC_INLINE landed in 5.18. Plain `static` before that; an older
 * toolchain may decline to inline, which nobody cares about there. */
#ifndef PERL_STATIC_INLINE
#  define PERL_STATIC_INLINE static
#endif

/* PERL_UNUSED_CONTEXT is what to spell on a perl built without
 * MULTIPLICITY, where there is no my_perl to mark unused. Old perls lack
 * the macro itself. */
#ifndef PERL_UNUSED_CONTEXT
#  ifdef PERL_IMPLICIT_CONTEXT
#    define PERL_UNUSED_CONTEXT PERL_UNUSED_VAR(my_perl)
#  else
#    define PERL_UNUSED_CONTEXT NOOP
#  endif
#endif

#endif /* FRX_COMPAT_H */
