#include "EXTERN.h"
#include "perl.h"

/*
 * chocolateboy 2009-02-08
 *
 * for binary compatibility (see perlapi.h), XS modules perform a function call to
 * access each and every interpreter variable. So, for instance, an innocuous-looking
 * reference to PL_op becomes:
 *
 *     (*Perl_Iop_ptr(my_perl))
 *
 * This (obviously) impacts performance. Internally, PL_op is accessed as:
 *
 *     my_perl->Iop
 *
 * (in threaded/multiplicity builds (see intrpvar.h)), which is significantly faster.
 *
 * defining PERL_CORE gets us the fast version, at the expense of a future maintenance release
 * possibly breaking things: http://www.xray.mpe.mpg.de/mailing-lists/perl5-porters/2008-04/msg00171.html
 *
 * Rather than globally defining PERL_CORE, which pokes its fingers into various headers, exposing
 * internals we'd rather not see, just define it for XSUB.h, which includes
 * perlapi.h, which imposes the speed limit.
 */

#define PERL_CORE
#include "XSUB.h"
#undef PERL_CORE

#include "ppport.h"

#include "hook_op_check.h"
#include "hook_op_annotation.h"

#define GOTO_CACHED_KEY "Goto::Cached"

STATIC hook_op_check_id GOTO_CACHED_CHECK_ID = 0;
STATIC OPAnnotationGroup GOTO_CACHED_ANNOTATIONS = NULL;
STATIC OP * goto_cached_check(pTHX_ OP *o, void *user_data);
STATIC OP * goto_cached_dynamic(pTHX);
STATIC OP * goto_cached_static_fast(pTHX);
STATIC OP * goto_cached_static(pTHX);
STATIC U32 GOTO_CACHED_CHECK_ENABLED = 0;
STATIC void goto_cached_data_destructor(pTHX_ void *data);

STATIC void goto_cached_data_destructor(pTHX_ void *data) {
    HV *hv = (HV *)data;
    hv_clear(hv);
    hv_undef(hv);
}

/* XXX calling the next OP's op_ppaddr directly is no faster in my tests */
STATIC OP* goto_cached_static_fast(pTHX) {
    return (PL_op->op_next);
}

STATIC OP* goto_cached_static(pTHX) {
    OP * nextop;
    OPAnnotation * annotation = op_annotation_get(GOTO_CACHED_ANNOTATIONS, PL_op);
    nextop = (annotation->op_ppaddr)(aTHX);

    if (PL_lastgotoprobe) { /* target is not in scope: disable caching */
        PL_op->op_ppaddr = annotation->op_ppaddr;
    } else {
        PL_op->op_next = nextop;
        PL_op->op_ppaddr = goto_cached_static_fast;
    }

    op_annotation_delete(aTHX_ GOTO_CACHED_ANNOTATIONS, PL_op); /* not needed anymore */

    return nextop;
}

STATIC OP* goto_cached_dynamic(pTHX) {
    dSP;
    SV * sv = TOPs;
    OP * nextop = NULL;
    OPAnnotation * annotation = op_annotation_get(GOTO_CACHED_ANNOTATIONS, PL_op);

    if (SvROK(sv)) { /* goto SUB: disable caching */
        PL_op->op_ppaddr = annotation->op_ppaddr;
        nextop = (PL_op->op_ppaddr)(aTHX);
        op_annotation_delete(aTHX_ GOTO_CACHED_ANNOTATIONS, PL_op); /* not needed anymore */
    } else if (annotation->data) { /* there is a cache for this op */
        SV ** svp;
        HV *hv = (HV *)(annotation->data);
        STRLEN len;
        const char * label = SvPV_const(sv, len);

        svp = hv_fetch(hv, label, len, 0);

        if (svp && *svp && SvOK(*svp)) {
            nextop = INT2PTR(OP *, SvIVX(*svp));
        } else {
            nextop = (annotation->op_ppaddr)(aTHX);

            if (PL_lastgotoprobe) { /* target is not in scope: disable caching */
                PL_op->op_ppaddr = annotation->op_ppaddr;
                op_annotation_delete(aTHX_ GOTO_CACHED_ANNOTATIONS, PL_op); /* not needed anymore */
            } else {
                (void)hv_store(hv, label, len, newSVuv(PTR2UV(nextop)), 0);
            }
        }
    } else { /* initialize cache */
        nextop = (annotation->op_ppaddr)(aTHX);

        if (PL_lastgotoprobe) { /* target is not in scope: disable caching */
            PL_op->op_ppaddr = annotation->op_ppaddr;
            op_annotation_delete(aTHX_ GOTO_CACHED_ANNOTATIONS, PL_op); /* not needed anymore */
        } else {
            STRLEN len;
            char * label = SvPV(sv, len);
            HV * hv = newHV();
            (void)hv_store(hv, label, len, newSVuv(PTR2UV(nextop)), 0);
            annotation->data = hv;
            annotation->dtor = goto_cached_data_destructor;
        }
    }

    return nextop;
}

STATIC OP *goto_cached_check(pTHX_ OP *o, void *user_data) {
    PERL_UNUSED_ARG(user_data);

    if ((o->op_type == OP_GOTO) && (PL_hints & 0x020000)) {
        SV ** svp;
        HV * table = GvHVn(PL_hintgv);

        if (table && (svp = hv_fetch(table, GOTO_CACHED_KEY, 12, FALSE)) && *svp && SvOK(*svp)) {
            op_annotate(GOTO_CACHED_ANNOTATIONS, o, NULL, NULL);
            o->op_ppaddr = (o->op_flags & OPf_STACKED) ?
                goto_cached_dynamic :
                goto_cached_static;
        }
    }

    return o;
}

MODULE = Goto::Cached                PACKAGE = Goto::Cached                

PROTOTYPES: ENABLE

BOOT:
    GOTO_CACHED_ANNOTATIONS = op_annotation_group_new();

void
END()
    PROTOTYPE:
    CODE:
        if (GOTO_CACHED_ANNOTATIONS) { /* make sure it was initialised */
            op_annotation_group_free(aTHX_ GOTO_CACHED_ANNOTATIONS);
        }

void
_enter()
    PROTOTYPE:
    CODE: 
        if (GOTO_CACHED_CHECK_ENABLED == 0) {
            GOTO_CACHED_CHECK_ID = hook_op_check(OP_GOTO, goto_cached_check, NULL);
        }
        ++GOTO_CACHED_CHECK_ENABLED;

void
_leave()
    PROTOTYPE:
    CODE: 
        --GOTO_CACHED_CHECK_ENABLED;
        if (GOTO_CACHED_CHECK_ENABLED == 0) {
            hook_op_check_remove(OP_GOTO, GOTO_CACHED_CHECK_ID);
        }
