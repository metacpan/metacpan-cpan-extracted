/*
 * Legba.xs - Ultra-fast global slot storage for Perl
 *
 * Named after Papa Legba, the Vodou gatekeeper of crossroads.
 *
 * Architecture ported from Ancient/slot (slot.c):
 * - Plain SV** array with realloc; no PVX-buffer trick
 * - Slot index stored in op_targ (standard OP field), not embedded as SV*
 *   in a custom struct — no dangling pointer risk on registry resize
 * - Reactive watchers (optional, zero overhead without them)
 *
 * Legba extensions over Ancient/slot:
 * - lock/freeze access control per slot
 * - Dedicated SV* per slot (mutated via sv_setsv) so _slot_ptr remains
 *   stable across value changes
 * - _slot_ptr / _make_get_op / _make_set_op for external op building
 * - _registry introspection
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

/* ============================================
   Compatibility macros
   ============================================ */

#ifndef PERL_VERSION_GE
#  define PERL_VERSION_GE(r,v,s) \
      (PERL_REVISION > (r) || (PERL_REVISION == (r) && \
       (PERL_VERSION > (v) || (PERL_VERSION == (v) && PERL_SUBVERSION >= (s)))))
#endif

#ifndef OpHAS_SIBLING
#  define OpHAS_SIBLING(o)      ((o)->op_sibling != NULL)
#endif
#ifndef OpSIBLING
#  define OpSIBLING(o)          ((o)->op_sibling)
#endif
#ifndef OpMORESIB_set
#  define OpMORESIB_set(o, sib) ((o)->op_sibling = (sib))
#endif
#ifndef OpLASTSIB_set
#  define OpLASTSIB_set(o, parent) ((o)->op_sibling = NULL)
#endif
#ifndef SvREFCNT_inc_simple_NN
#  define SvREFCNT_inc_simple_NN(sv) SvREFCNT_inc(sv)
#endif
#ifndef SvREFCNT_dec_NN
#  define SvREFCNT_dec_NN(sv) SvREFCNT_dec(sv)
#endif

/* PADNAMEf_CONST - compile-time constant flag (0x40 unused in standard perl) */
#ifndef PADNAMEf_CONST
#  define PADNAMEf_CONST 0x40
#endif

#if !PERL_VERSION_GE(5,18,0)
typedef SV PADNAME;
#  define PadnamelistMAX(pn)       (AvFILLp(pn))
#  define PadnamelistARRAY(pn)     ((PADNAME**)AvARRAY(pn))
#  define PadnameFLAGS(pn)         (SvFLAGS(pn))
#  undef  PADNAMEf_CONST
#  define PADNAMEf_CONST 0
#elif !PERL_VERSION_GE(5,22,0)
#  ifndef PadnameFLAGS
#    define PadnameFLAGS(pn) (SvFLAGS((SV*)(pn)))
#  endif
#endif

/* cv_set_call_checker - 5.14+ only */
#if !PERL_VERSION_GE(5,14,0)
#  define cv_set_call_checker(cv, checker, ckobj) /* no-op on pre-5.14 */
#endif

/* XOP API - 5.14+ */
#if PERL_VERSION_GE(5,14,0)
#  define LEGBA_HAS_XOP 1
#else
#  define LEGBA_HAS_XOP 0
#  ifndef XOP_DEFINED_BY_COMPAT
#    define XOP_DEFINED_BY_COMPAT 1
typedef struct { const char *xop_name; const char *xop_desc; } XOP;
#  endif
#  ifndef XopENTRY_set
#    define XopENTRY_set(xop, field, value) do { (xop)->field = (value); } while(0)
#  endif
#  ifdef PERL_IMPLICIT_CONTEXT
#    define Perl_custom_op_register(ctx, ppfunc, xop) \
         legba_compat_reg_xop((ctx), (Perl_ppaddr_t)(ppfunc), (xop)->xop_name, (xop)->xop_desc)
#  else
#    define Perl_custom_op_register(ppfunc, xop) \
         legba_compat_reg_xop(aTHX_ (Perl_ppaddr_t)(ppfunc), (xop)->xop_name, (xop)->xop_desc)
#  endif
static void legba_compat_reg_xop(pTHX_ Perl_ppaddr_t ppfunc, const char *name, const char *desc) {
    if (!PL_custom_op_names) PL_custom_op_names = newHV();
    if (!PL_custom_op_descs) PL_custom_op_descs = newHV();
    hv_store(PL_custom_op_names, (char*)&ppfunc, sizeof(ppfunc), newSVpv(name, 0), 0);
    hv_store(PL_custom_op_descs, (char*)&ppfunc, sizeof(ppfunc), newSVpv(desc, 0), 0);
}
#endif /* LEGBA_HAS_XOP */

#ifndef dXSBOOTARGSXSAPIVERCHK
#  define dXSBOOTARGSXSAPIVERCHK dXSARGS
#endif
#if !PERL_VERSION_GE(5,22,0)
#  ifndef Perl_xs_boot_epilog
#    ifdef PERL_IMPLICIT_CONTEXT
#      define Perl_xs_boot_epilog(ctx, ax) XSRETURN_YES
#    else
#      define Perl_xs_boot_epilog(ax) XSRETURN_YES
#    endif
#  endif
#endif
#ifndef XS_EXTERNAL
#  define XS_EXTERNAL(name) XS(name)
#endif

/* ============================================
   Globals
   ============================================ */

/*
 * Each g_slots[i] is a dedicated SV* allocated once at slot creation and
 * mutated via sv_setsv for value changes.  The pointer itself never changes,
 * so PTR2UV(g_slots[i]) is stable — required for _slot_ptr compatibility.
 */
static SV   **g_slots      = NULL;
static IV     g_slots_size = 0;
static IV     g_slots_count= 0;
static char  *g_has_watchers= NULL;

/* Per-slot access-control flags (lock / freeze) */
static UV    *slot_flags   = NULL;
#define SLOT_FLAG_LOCKED 0x1
#define SLOT_FLAG_FROZEN 0x2

/* Name <-> index mappings */
static HV *g_slot_index = NULL;   /* slot name   -> IV index  */
static HV *g_slot_names = NULL;   /* "N" (idx)   -> slot name */
static HV *g_watchers   = NULL;   /* slot name   -> AV of callbacks */

/* Custom op type descriptors */
#if LEGBA_HAS_XOP
static XOP legba_get_xop;
static XOP legba_set_xop;
static XOP legba_watch_xop;
static XOP legba_unwatch_xop;
static XOP legba_unwatch_one_xop;
static XOP legba_clear_xop;
#endif

/* Forward declaration */
static void fire_watchers(pTHX_ IV idx, SV *new_val);

/* ============================================
   Custom op pp functions
   ============================================ */

static OP* pp_slot_get(pTHX) {
    dSP;
    IV idx = PL_op->op_targ;
#ifdef DEBUGGING
    EXTEND(SP, 1);
#endif
    PUSHs(g_slots[idx]);
    PUTBACK;
    return NORMAL;
}

static OP* pp_slot_set(pTHX) {
    dSP;
    IV idx = PL_op->op_targ;
    SV *new_val = TOPs;
    if (slot_flags[idx] & (SLOT_FLAG_LOCKED | SLOT_FLAG_FROZEN)) {
        croak("Attempt to set %s slot",
              (slot_flags[idx] & SLOT_FLAG_FROZEN) ? "frozen" : "locked");
    }
    sv_setsv(g_slots[idx], new_val);
    if (g_has_watchers[idx]) fire_watchers(aTHX_ idx, g_slots[idx]);
    SETs(g_slots[idx]);
    PUTBACK;
    return NORMAL;
}

static OP* pp_slot_watch(pTHX) {
    dSP;
    IV idx = PL_op->op_targ;
    SV *callback = POPs;
    char key[32];
    int klen = snprintf(key, sizeof(key), "%ld", (long)idx);
    SV **name_svp = hv_fetch(g_slot_names, key, klen, 0);
    if (name_svp) {
        STRLEN name_len;
        const char *name = SvPV(*name_svp, name_len);
        SV **existing = hv_fetch(g_watchers, name, name_len, 0);
        AV *callbacks;
        if (existing && SvROK(*existing)) {
            callbacks = (AV*)SvRV(*existing);
        } else {
            callbacks = newAV();
            hv_store(g_watchers, name, name_len, newRV_noinc((SV*)callbacks), 0);
        }
        av_push(callbacks, SvREFCNT_inc(callback));
        g_has_watchers[idx] = 1;
    }
    RETURN;
}

static OP* pp_slot_unwatch(pTHX) {
    IV idx = PL_op->op_targ;
    char key[32];
    int klen = snprintf(key, sizeof(key), "%ld", (long)idx);
    SV **name_svp = hv_fetch(g_slot_names, key, klen, 0);
    if (name_svp) {
        STRLEN name_len;
        const char *name = SvPV(*name_svp, name_len);
        hv_delete(g_watchers, name, name_len, G_DISCARD);
        g_has_watchers[idx] = 0;
    }
    return NORMAL;
}

static OP* pp_slot_unwatch_one(pTHX) {
    dSP;
    IV idx = PL_op->op_targ;
    SV *callback = POPs;
    char key[32];
    int klen = snprintf(key, sizeof(key), "%ld", (long)idx);
    SV **name_svp = hv_fetch(g_slot_names, key, klen, 0);
    if (name_svp) {
        STRLEN name_len;
        const char *name = SvPV(*name_svp, name_len);
        SV **existing = hv_fetch(g_watchers, name, name_len, 0);
        if (existing && SvROK(*existing)) {
            AV *callbacks = (AV*)SvRV(*existing);
            SSize_t i, len = av_len(callbacks);
            for (i = len; i >= 0; i--) {
                SV **cb = av_fetch(callbacks, i, 0);
                if (cb && SvRV(*cb) == SvRV(callback))
                    av_delete(callbacks, i, G_DISCARD);
            }
            if (av_len(callbacks) < 0)
                g_has_watchers[idx] = 0;
        }
    }
    RETURN;
}

static OP* pp_slot_clear(pTHX) {
    IV idx = PL_op->op_targ;
    char key[32];
    int klen = snprintf(key, sizeof(key), "%ld", (long)idx);
    SV **name_svp = hv_fetch(g_slot_names, key, klen, 0);
    sv_setsv(g_slots[idx], &PL_sv_undef);
    if (name_svp) {
        STRLEN name_len;
        const char *name = SvPV(*name_svp, name_len);
        hv_delete(g_watchers, name, name_len, G_DISCARD);
    }
    g_has_watchers[idx] = 0;
    return NORMAL;
}

/* ============================================
   Call checkers
   ============================================ */

/* Installed on each imported accessor CV.
 * 0-arg call => getter custom op; 1-arg call => setter custom op. */
static OP* slot_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    CV *cv = (CV*)ckobj;
    IV idx = CvXSUBANY(cv).any_iv;
    OP *pushop, *cvop, *argop;
    PERL_UNUSED_ARG(namegv);

    pushop = cUNOPx(entersubop)->op_first;
    if (!OpHAS_SIBLING(pushop)) pushop = cUNOPx(pushop)->op_first;
    argop = OpSIBLING(pushop);
    cvop  = argop;
    while (OpHAS_SIBLING(cvop)) cvop = OpSIBLING(cvop);

    if (argop == cvop) {
        /* Getter: no arguments */
        OP *newop = newOP(OP_CUSTOM, 0);
        newop->op_ppaddr = pp_slot_get;
        newop->op_targ   = idx;
        op_free(entersubop);
        return newop;
    } else if (OpSIBLING(argop) == cvop) {
        /* Setter: single argument */
        OP *arg = argop;
        OP *newop;
        OpMORESIB_set(pushop, cvop);
        OpLASTSIB_set(arg, NULL);
        op_contextualize(arg, G_SCALAR);
        newop = newUNOP(OP_NULL, 0, arg);
        newop->op_type   = OP_CUSTOM;
        newop->op_ppaddr = pp_slot_set;
        newop->op_targ   = idx;
        op_free(entersubop);
        return newop;
    }
    return entersubop;
}

/* Shared helper: extract constant string namesv from single-arg call */
static SV* get_const_namesv_1arg(pTHX_ OP *entersubop) {
    OP *pushop, *cvop, *argop;
    pushop = cUNOPx(entersubop)->op_first;
    if (!OpHAS_SIBLING(pushop)) pushop = cUNOPx(pushop)->op_first;
    argop = OpSIBLING(pushop);
    cvop  = argop;
    while (OpHAS_SIBLING(cvop)) cvop = OpSIBLING(cvop);
    if (argop == cvop || OpSIBLING(argop) != cvop) return NULL;
    if (argop->op_type == OP_CONST)
        return cSVOPx(argop)->op_sv;
    if (argop->op_type == OP_PADSV) {
        PADOFFSET po = argop->op_targ;
        if (PL_comppad_name && po < (PADOFFSET)(PadnamelistMAX(PL_comppad_name) + 1)) {
            PADNAME *pn = PadnamelistARRAY(PL_comppad_name)[po];
            if (pn && (PadnameFLAGS(pn) & PADNAMEf_CONST) && PL_comppad) {
                SV **svp = av_fetch(PL_comppad, po, 0);
                if (svp && SvPOK(*svp)) return *svp;
            }
        }
    }
    return NULL;
}

/* get('constant') / _get('constant') => getter custom op */
static OP* slot_get_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    SV *namesv;
    PERL_UNUSED_ARG(namegv); PERL_UNUSED_ARG(ckobj);
    namesv = get_const_namesv_1arg(aTHX_ entersubop);
    if (namesv && SvPOK(namesv)) {
        STRLEN name_len;
        const char *name = SvPV(namesv, name_len);
        SV **svp = hv_fetch(g_slot_index, name, name_len, 0);
        if (svp) {
            OP *newop = newOP(OP_CUSTOM, 0);
            newop->op_ppaddr = pp_slot_get;
            newop->op_targ   = SvIV(*svp);
            op_free(entersubop);
            return newop;
        }
    }
    return entersubop;
}

/* set('constant', $val) / _set('constant', $val) => setter custom op */
static OP* slot_set_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    OP *pushop, *cvop, *argop, *valop;
    SV *namesv = NULL;
    PERL_UNUSED_ARG(namegv); PERL_UNUSED_ARG(ckobj);

    pushop = cUNOPx(entersubop)->op_first;
    if (!OpHAS_SIBLING(pushop)) pushop = cUNOPx(pushop)->op_first;
    argop = OpSIBLING(pushop);
    cvop  = argop;
    while (OpHAS_SIBLING(cvop)) cvop = OpSIBLING(cvop);
    valop = OpSIBLING(argop);
    if (argop == cvop || !valop || valop == cvop || OpSIBLING(valop) != cvop)
        return entersubop;

    if (argop->op_type == OP_CONST) {
        namesv = cSVOPx(argop)->op_sv;
    } else if (argop->op_type == OP_PADSV) {
        PADOFFSET po = argop->op_targ;
        if (PL_comppad_name && po < (PADOFFSET)(PadnamelistMAX(PL_comppad_name) + 1)) {
            PADNAME *pn = PadnamelistARRAY(PL_comppad_name)[po];
            if (pn && (PadnameFLAGS(pn) & PADNAMEf_CONST) && PL_comppad) {
                SV **svp = av_fetch(PL_comppad, po, 0);
                if (svp && SvPOK(*svp)) namesv = *svp;
            }
        }
    }
    if (namesv && SvPOK(namesv)) {
        STRLEN name_len;
        const char *name = SvPV(namesv, name_len);
        SV **svp = hv_fetch(g_slot_index, name, name_len, 0);
        if (svp) {
            OP *newop;
            OpMORESIB_set(pushop, cvop);
            OpLASTSIB_set(valop, NULL);
            op_contextualize(valop, G_SCALAR);
            newop = newUNOP(OP_NULL, 0, valop);
            newop->op_type   = OP_CUSTOM;
            newop->op_ppaddr = pp_slot_set;
            newop->op_targ   = SvIV(*svp);
            op_free(entersubop);
            return newop;
        }
    }
    return entersubop;
}

/* index('constant') => OP_CONST (fully constant-folded) */
static OP* slot_index_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    OP *pushop, *cvop, *argop;
    PERL_UNUSED_ARG(namegv); PERL_UNUSED_ARG(ckobj);
    pushop = cUNOPx(entersubop)->op_first;
    if (!OpHAS_SIBLING(pushop)) pushop = cUNOPx(pushop)->op_first;
    argop = OpSIBLING(pushop);
    cvop  = argop;
    while (OpHAS_SIBLING(cvop)) cvop = OpSIBLING(cvop);
    if (argop != cvop && OpSIBLING(argop) == cvop && argop->op_type == OP_CONST) {
        SV *namesv = cSVOPx(argop)->op_sv;
        if (SvPOK(namesv)) {
            STRLEN name_len;
            const char *name = SvPV(namesv, name_len);
            SV **svp = hv_fetch(g_slot_index, name, name_len, 0);
            if (svp) {
                OP *newop = newSVOP(OP_CONST, 0, newSViv(SvIV(*svp)));
                op_free(entersubop);
                return newop;
            }
        }
    }
    return entersubop;
}

/* watch('constant', $cb) => watch custom op */
static OP* slot_watch_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    OP *pushop, *cvop, *argop, *cbop;
    PERL_UNUSED_ARG(namegv); PERL_UNUSED_ARG(ckobj);
    pushop = cUNOPx(entersubop)->op_first;
    if (!OpHAS_SIBLING(pushop)) pushop = cUNOPx(pushop)->op_first;
    argop = OpSIBLING(pushop);
    cvop  = argop;
    while (OpHAS_SIBLING(cvop)) cvop = OpSIBLING(cvop);
    cbop = OpSIBLING(argop);
    if (argop != cvop && cbop && cbop != cvop && OpSIBLING(cbop) == cvop
        && argop->op_type == OP_CONST) {
        SV *namesv = cSVOPx(argop)->op_sv;
        if (SvPOK(namesv)) {
            STRLEN name_len;
            const char *name = SvPV(namesv, name_len);
            SV **svp = hv_fetch(g_slot_index, name, name_len, 0);
            if (svp) {
                OP *newop;
                OpMORESIB_set(pushop, cvop);
                OpLASTSIB_set(cbop, NULL);
                newop = newUNOP(OP_NULL, 0, cbop);
                newop->op_type   = OP_CUSTOM;
                newop->op_ppaddr = pp_slot_watch;
                newop->op_targ   = SvIV(*svp);
                op_free(entersubop);
                return newop;
            }
        }
    }
    return entersubop;
}

/* unwatch('constant') or unwatch('constant', $cb) */
static OP* slot_unwatch_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    OP *pushop, *cvop, *argop, *cbop;
    PERL_UNUSED_ARG(namegv); PERL_UNUSED_ARG(ckobj);
    pushop = cUNOPx(entersubop)->op_first;
    if (!OpHAS_SIBLING(pushop)) pushop = cUNOPx(pushop)->op_first;
    argop = OpSIBLING(pushop);
    cvop  = argop;
    while (OpHAS_SIBLING(cvop)) cvop = OpSIBLING(cvop);
    if (argop != cvop && argop->op_type == OP_CONST) {
        SV *namesv = cSVOPx(argop)->op_sv;
        if (SvPOK(namesv)) {
            STRLEN name_len;
            const char *name = SvPV(namesv, name_len);
            SV **svp = hv_fetch(g_slot_index, name, name_len, 0);
            if (svp) {
                IV idx = SvIV(*svp);
                cbop = OpSIBLING(argop);
                if (cbop == cvop) {
                    OP *newop = newOP(OP_CUSTOM, 0);
                    newop->op_ppaddr = pp_slot_unwatch;
                    newop->op_targ   = idx;
                    op_free(entersubop);
                    return newop;
                } else if (OpSIBLING(cbop) == cvop) {
                    OP *newop;
                    OpMORESIB_set(pushop, cvop);
                    OpLASTSIB_set(cbop, NULL);
                    newop = newUNOP(OP_NULL, 0, cbop);
                    newop->op_type   = OP_CUSTOM;
                    newop->op_ppaddr = pp_slot_unwatch_one;
                    newop->op_targ   = idx;
                    op_free(entersubop);
                    return newop;
                }
            }
        }
    }
    return entersubop;
}

/* clear('constant') => clear custom op */
static OP* slot_clear_call_checker(pTHX_ OP *entersubop, GV *namegv, SV *ckobj) {
    OP *pushop, *cvop, *argop;
    PERL_UNUSED_ARG(namegv); PERL_UNUSED_ARG(ckobj);
    pushop = cUNOPx(entersubop)->op_first;
    if (!OpHAS_SIBLING(pushop)) pushop = cUNOPx(pushop)->op_first;
    argop = OpSIBLING(pushop);
    cvop  = argop;
    while (OpHAS_SIBLING(cvop)) cvop = OpSIBLING(cvop);
    if (argop != cvop && OpSIBLING(argop) == cvop && argop->op_type == OP_CONST) {
        SV *namesv = cSVOPx(argop)->op_sv;
        if (SvPOK(namesv)) {
            STRLEN name_len;
            const char *name = SvPV(namesv, name_len);
            SV **svp = hv_fetch(g_slot_index, name, name_len, 0);
            if (svp) {
                OP *newop = newOP(OP_CUSTOM, 0);
                newop->op_ppaddr = pp_slot_clear;
                newop->op_targ   = SvIV(*svp);
                op_free(entersubop);
                return newop;
            }
        }
    }
    return entersubop;
}

/* ============================================
   XS slot accessor (fallback for unoptimized calls)
   ============================================ */

static XS(xs_slot_accessor) {
    dXSARGS;
    IV idx = CvXSUBANY(cv).any_iv;
    if (items) {
        UV flags = slot_flags[idx];
        if (flags & (SLOT_FLAG_LOCKED | SLOT_FLAG_FROZEN)) {
            croak("Attempt to set %s slot",
                  (flags & SLOT_FLAG_FROZEN) ? "frozen" : "locked");
        }
        sv_setsv(g_slots[idx], ST(0));
        if (g_has_watchers[idx]) fire_watchers(aTHX_ idx, g_slots[idx]);
        ST(0) = g_slots[idx];
        XSRETURN(1);
    }
    ST(0) = g_slots[idx];
    XSRETURN(1);
}

/* ============================================
   Watchers
   ============================================ */

static void fire_watchers(pTHX_ IV idx, SV *new_val) {
    char key[32];
    int klen = snprintf(key, sizeof(key), "%ld", (long)idx);
    SV **name_sv = hv_fetch(g_slot_names, key, klen, 0);
    if (!name_sv || !SvOK(*name_sv)) return;
    {
        STRLEN name_len;
        const char *name = SvPV(*name_sv, name_len);
        SV **svp = hv_fetch(g_watchers, name, name_len, 0);
        if (svp && SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVAV) {
            AV *callbacks = (AV*)SvRV(*svp);
            SSize_t i, len = av_len(callbacks);
            for (i = 0; i <= len; i++) {
                SV **cb = av_fetch(callbacks, i, 0);
                if (cb && SvROK(*cb)) {
                    dSP;
                    ENTER; SAVETMPS;
                    PUSHMARK(SP);
                    mXPUSHs(newSVpvn(name, name_len));
                    XPUSHs(new_val);
                    PUTBACK;
                    call_sv(*cb, G_DISCARD);
                    FREETMPS; LEAVE;
                }
            }
        }
    }
}

/* ============================================
   Slot management helpers
   ============================================ */

static void ensure_slot_capacity(pTHX_ IV needed) {
    if (needed >= g_slots_size) {
        IV new_size = g_slots_size ? g_slots_size * 2 : 16;
        IV i;
        while (new_size <= needed) new_size *= 2;
        Renew(g_slots,       new_size, SV*);
        Renew(g_has_watchers,new_size, char);
        Renew(slot_flags,    new_size, UV);
        for (i = g_slots_size; i < new_size; i++) {
            g_slots[i]        = newSV(0); /* dedicated SV; pointer never replaced */
            g_has_watchers[i] = 0;
            slot_flags[i]     = 0;
        }
        g_slots_size = new_size;
    }
}

static IV create_slot(pTHX_ const char *name, STRLEN name_len) {
    IV idx = g_slots_count++;
    char key[32];
    int klen;
    ensure_slot_capacity(aTHX_ idx);
    hv_store(g_slot_index, name, name_len, newSViv(idx), 0);
    klen = snprintf(key, sizeof(key), "%ld", (long)idx);
    hv_store(g_slot_names, key, klen, newSVpvn(name, name_len), 0);
    return idx;
}

static IV get_or_create_slot_idx(pTHX_ const char *name, STRLEN len) {
    SV **svp = hv_fetch(g_slot_index, name, len, 0);
    return svp ? SvIV(*svp) : create_slot(aTHX_ name, len);
}

static void install_accessor(pTHX_ const char *pkg, const char *name, STRLEN name_len, IV idx) {
    char full[512];
    CV *cv;
    snprintf(full, sizeof(full), "%s::%s", pkg, name);
    cv = newXS(full, xs_slot_accessor, __FILE__);
    CvXSUBANY(cv).any_iv = idx;
    cv_set_call_checker(cv, slot_call_checker, (SV*)cv);
}

/* ============================================
   XS functions
   ============================================ */

static XS(xs_import) {
    dXSARGS;
    const char *pkg = HvNAME((HV*)CopSTASH(PL_curcop));
    int i;
    if (!pkg) pkg = "main";
    for (i = 1; i < items; i++) {
        STRLEN name_len;
        const char *name = SvPV(ST(i), name_len);
        SV **existing = hv_fetch(g_slot_index, name, name_len, 0);
        IV idx = existing ? SvIV(*existing) : create_slot(aTHX_ name, name_len);
        /* Skip if already installed as our accessor in this package */
        {
            HV *stash = gv_stashpv(pkg, GV_ADD);
            SV **gvp  = hv_fetch(stash, name, name_len, 0);
            if (gvp && isGV(*gvp)) {
                CV *ecv = GvCV((GV*)*gvp);
                if (ecv && CvISXSUB(ecv) && CvXSUB(ecv) == xs_slot_accessor)
                    continue;
            }
        }
        install_accessor(aTHX_ pkg, name, name_len, idx);
    }
    XSRETURN_EMPTY;
}

static XS(xs_add) {
    dXSARGS;
    int i;
    for (i = 0; i < items; i++) {
        STRLEN name_len;
        const char *name = SvPV(ST(i), name_len);
        if (!hv_fetch(g_slot_index, name, name_len, 0))
            create_slot(aTHX_ name, name_len);
    }
    XSRETURN_EMPTY;
}

static XS(xs_watch) {
    dXSARGS;
    STRLEN name_len;
    const char *name;
    SV *callback;
    SV **existing;
    AV *callbacks;
    SV **idx_sv;
    if (items < 2) croak("Usage: Legba::watch($name, $callback)");
    name     = SvPV(ST(0), name_len);
    callback = ST(1);
    existing = hv_fetch(g_watchers, name, name_len, 0);
    if (existing && SvROK(*existing)) {
        callbacks = (AV*)SvRV(*existing);
    } else {
        callbacks = newAV();
        hv_store(g_watchers, name, name_len, newRV_noinc((SV*)callbacks), 0);
    }
    av_push(callbacks, SvREFCNT_inc(callback));
    idx_sv = hv_fetch(g_slot_index, name, name_len, 0);
    if (idx_sv) g_has_watchers[SvIV(*idx_sv)] = 1;
    XSRETURN_EMPTY;
}

static XS(xs_unwatch) {
    dXSARGS;
    STRLEN name_len;
    const char *name;
    SV **idx_sv;
    int clear_flag = 0;
    if (items < 1) croak("Usage: Legba::unwatch($name [, $callback])");
    name = SvPV(ST(0), name_len);
    if (items == 1) {
        hv_delete(g_watchers, name, name_len, G_DISCARD);
        clear_flag = 1;
    } else {
        SV *callback = ST(1);
        SV **existing = hv_fetch(g_watchers, name, name_len, 0);
        if (existing && SvROK(*existing)) {
            AV *callbacks = (AV*)SvRV(*existing);
            SSize_t i, len = av_len(callbacks);
            for (i = len; i >= 0; i--) {
                SV **cb = av_fetch(callbacks, i, 0);
                if (cb && SvRV(*cb) == SvRV(callback))
                    av_delete(callbacks, i, G_DISCARD);
            }
            if (av_len(callbacks) < 0) clear_flag = 1;
        }
    }
    if (clear_flag) {
        idx_sv = hv_fetch(g_slot_index, name, name_len, 0);
        if (idx_sv) g_has_watchers[SvIV(*idx_sv)] = 0;
    }
    XSRETURN_EMPTY;
}

static XS(xs_index) {
    dXSARGS;
    STRLEN name_len; const char *name; SV **svp;
    if (items < 1) XSRETURN_UNDEF;
    name = SvPV(ST(0), name_len);
    svp  = hv_fetch(g_slot_index, name, name_len, 0);
    if (svp) { ST(0) = *svp; XSRETURN(1); }
    XSRETURN_UNDEF;
}

static XS(xs_get_by_idx) {
    dXSARGS;
    IV idx;
    if (items < 1) XSRETURN_UNDEF;
    idx = SvIV(ST(0));
    if (idx >= 0 && idx < g_slots_count) { ST(0) = g_slots[idx]; XSRETURN(1); }
    XSRETURN_UNDEF;
}

static XS(xs_set_by_idx) {
    dXSARGS;
    IV idx;
    if (items < 2) XSRETURN_EMPTY;
    idx = SvIV(ST(0));
    if (idx >= 0 && idx < g_slots_count) {
        UV flags = slot_flags[idx];
        if (flags & (SLOT_FLAG_LOCKED | SLOT_FLAG_FROZEN))
            croak("Attempt to set %s slot",
                  (flags & SLOT_FLAG_FROZEN) ? "frozen" : "locked");
        sv_setsv(g_slots[idx], ST(1));
        if (g_has_watchers[idx]) fire_watchers(aTHX_ idx, g_slots[idx]);
        ST(0) = g_slots[idx];
        XSRETURN(1);
    }
    XSRETURN_EMPTY;
}

static XS(xs_get) {
    dXSARGS;
    STRLEN name_len; const char *name; SV **svp;
    if (items < 1) XSRETURN_UNDEF;
    name = SvPV(ST(0), name_len);
    svp  = hv_fetch(g_slot_index, name, name_len, 0);
    if (svp) { ST(0) = g_slots[SvIV(*svp)]; XSRETURN(1); }
    XSRETURN_UNDEF;
}

/* _set / set: create slot if missing; respects lock/freeze */
static XS(xs_set) {
    dXSARGS;
    STRLEN name_len; const char *name;
    IV idx;
    if (items < 2) XSRETURN_EMPTY;
    name = SvPV(ST(0), name_len);
    idx  = get_or_create_slot_idx(aTHX_ name, name_len);
    if (slot_flags[idx] & (SLOT_FLAG_LOCKED | SLOT_FLAG_FROZEN))
        croak("Attempt to set %s slot '%s'",
              (slot_flags[idx] & SLOT_FLAG_FROZEN) ? "frozen" : "locked", name);
    sv_setsv(g_slots[idx], ST(1));
    if (g_has_watchers[idx]) fire_watchers(aTHX_ idx, g_slots[idx]);
    ST(0) = g_slots[idx];
    XSRETURN(1);
}

static XS(xs_slots) {
    dXSARGS;
    HE *entry;
    PERL_UNUSED_VAR(items);
    SP -= items;
    hv_iterinit(g_slot_index);
    while ((entry = hv_iternext(g_slot_index)))
        XPUSHs(hv_iterkeysv(entry));
    PUTBACK;
    return;
}

static XS(xs_exists) {
    dXSARGS;
    STRLEN name_len; const char *name;
    if (items != 1) croak("Usage: Legba::exists($name)");
    name = SvPV(ST(0), name_len);
    if (hv_exists(g_slot_index, name, name_len)) XSRETURN_YES;
    XSRETURN_NO;
}

/* clear($name, ...) - clear value + watchers, skips locked/frozen */
static XS(xs_clear_named) {
    dXSARGS;
    int i;
    for (i = 0; i < items; i++) {
        STRLEN name_len;
        const char *name = SvPV(ST(i), name_len);
        SV **svp = hv_fetch(g_slot_index, name, name_len, 0);
        if (svp) {
            IV idx = SvIV(*svp);
            if (slot_flags[idx] & (SLOT_FLAG_LOCKED | SLOT_FLAG_FROZEN)) continue;
            sv_setsv(g_slots[idx], &PL_sv_undef);
            hv_delete(g_watchers, name, name_len, G_DISCARD);
            g_has_watchers[idx] = 0;
        }
    }
    XSRETURN_EMPTY;
}

static XS(xs_clear_by_idx) {
    dXSARGS;
    int i;
    for (i = 0; i < items; i++) {
        IV idx = SvIV(ST(i));
        if (idx >= 0 && idx < g_slots_count) {
            char key[32]; int klen; SV **name_sv;
            sv_setsv(g_slots[idx], &PL_sv_undef);
            klen   = snprintf(key, sizeof(key), "%ld", (long)idx);
            name_sv = hv_fetch(g_slot_names, key, klen, 0);
            if (name_sv && SvOK(*name_sv)) {
                STRLEN name_len;
                const char *name = SvPV(*name_sv, name_len);
                hv_delete(g_watchers, name, name_len, G_DISCARD);
            }
            g_has_watchers[idx] = 0;
        }
    }
    XSRETURN_EMPTY;
}

/* _delete($name) - set to undef, slot still exists; respects lock/freeze */
static XS(xs_delete) {
    dXSARGS;
    STRLEN name_len; const char *name; SV **svp;
    if (items < 1) XSRETURN_EMPTY;
    name = SvPV(ST(0), name_len);
    svp  = hv_fetch(g_slot_index, name, name_len, 0);
    if (svp) {
        IV idx = SvIV(*svp);
        if (slot_flags[idx] & (SLOT_FLAG_LOCKED | SLOT_FLAG_FROZEN))
            croak("Attempt to delete %s slot '%s'",
                  (slot_flags[idx] & SLOT_FLAG_FROZEN) ? "frozen" : "locked", name);
        sv_setsv(g_slots[idx], &PL_sv_undef);
    }
    XSRETURN_EMPTY;
}

/* _keys() - list all slot names */
static XS(xs_keys) {
    dXSARGS;
    HE *entry;
    PERL_UNUSED_VAR(items);
    SP -= items;
    hv_iterinit(g_slot_index);
    while ((entry = hv_iternext(g_slot_index))) {
        I32 klen; char *key = hv_iterkey(entry, &klen);
        mXPUSHp(key, klen);
    }
    PUTBACK;
    return;
}

/* _clear() - clear all non-locked/frozen slot values (preserves slots/watchers) */
static XS(xs_clear_all) {
    dXSARGS;
    IV i;
    PERL_UNUSED_VAR(items);
    for (i = 0; i < g_slots_count; i++) {
        if (!(slot_flags[i] & (SLOT_FLAG_LOCKED | SLOT_FLAG_FROZEN)))
            sv_setsv(g_slots[i], &PL_sv_undef);
    }
    XSRETURN_EMPTY;
}

/* _install_accessor($pkg, $slot_name) */
static XS(xs_install_accessor_fn) {
    dXSARGS;
    STRLEN pkg_len, name_len;
    const char *pkg_name, *name;
    IV idx;
    if (items < 2) croak("Usage: Legba::_install_accessor($pkg, $slot_name)");
    pkg_name = SvPV(ST(0), pkg_len);
    name     = SvPV(ST(1), name_len);
    idx      = get_or_create_slot_idx(aTHX_ name, name_len);
    install_accessor(aTHX_ pkg_name, name, name_len, idx);
    XSRETURN_EMPTY;
}

/* _slot_ptr($name) - UV of the dedicated SV* (stable across value changes) */
static XS(xs_slot_ptr) {
    dXSARGS;
    STRLEN name_len; const char *name; IV idx;
    if (items < 1) XSRETURN_UNDEF;
    name = SvPV(ST(0), name_len);
    idx  = get_or_create_slot_idx(aTHX_ name, name_len);
    ST(0) = sv_2mortal(newSVuv(PTR2UV(g_slots[idx])));
    XSRETURN(1);
}

/* _registry() - hashref of slot_name => index for introspection */
static XS(xs_registry) {
    dXSARGS;
    PERL_UNUSED_VAR(items);
    ST(0) = sv_2mortal(newRV_inc((SV*)g_slot_index));
    XSRETURN(1);
}

/* _make_get_op($name) - allocate a getter OP, return address as UV */
static XS(xs_make_get_op) {
    dXSARGS;
    STRLEN name_len; const char *name; IV idx; OP *op;
    if (items < 1) XSRETURN_UNDEF;
    name = SvPV(ST(0), name_len);
    idx  = get_or_create_slot_idx(aTHX_ name, name_len);
    op   = newOP(OP_CUSTOM, 0);
    op->op_ppaddr = pp_slot_get;
    op->op_targ   = idx;
    ST(0) = sv_2mortal(newSVuv(PTR2UV(op)));
    XSRETURN(1);
}

/* _make_set_op($name) - allocate a setter OP, return address as UV */
static XS(xs_make_set_op) {
    dXSARGS;
    STRLEN name_len; const char *name; IV idx; OP *op;
    if (items < 1) XSRETURN_UNDEF;
    name = SvPV(ST(0), name_len);
    idx  = get_or_create_slot_idx(aTHX_ name, name_len);
    /* Setter needs an operand child; use a null op as placeholder */
    op   = newUNOP(OP_NULL, 0, newOP(OP_NULL, 0));
    op->op_type   = OP_CUSTOM;
    op->op_ppaddr = pp_slot_set;
    op->op_targ   = idx;
    ST(0) = sv_2mortal(newSVuv(PTR2UV(op)));
    XSRETURN(1);
}

/* Lock / freeze */
static XS(xs_lock) {
    dXSARGS;
    STRLEN len; const char *n; SV **svp; IV idx;
    if (items < 1) croak("Usage: Legba::_lock($name)");
    n   = SvPV(ST(0), len);
    svp = hv_fetch(g_slot_index, n, len, 0);
    if (!svp) croak("Cannot lock non-existent slot '%s'", n);
    idx = SvIV(*svp);
    if (slot_flags[idx] & SLOT_FLAG_FROZEN) croak("Cannot lock frozen slot '%s'", n);
    slot_flags[idx] |= SLOT_FLAG_LOCKED;
    XSRETURN_EMPTY;
}

static XS(xs_unlock) {
    dXSARGS;
    STRLEN len; const char *n; SV **svp; IV idx;
    if (items < 1) croak("Usage: Legba::_unlock($name)");
    n   = SvPV(ST(0), len);
    svp = hv_fetch(g_slot_index, n, len, 0);
    if (!svp) croak("Cannot unlock non-existent slot '%s'", n);
    idx = SvIV(*svp);
    if (slot_flags[idx] & SLOT_FLAG_FROZEN) croak("Cannot unlock frozen slot '%s'", n);
    slot_flags[idx] &= ~SLOT_FLAG_LOCKED;
    XSRETURN_EMPTY;
}

static XS(xs_freeze) {
    dXSARGS;
    STRLEN len; const char *n; SV **svp; IV idx;
    if (items < 1) croak("Usage: Legba::_freeze($name)");
    n   = SvPV(ST(0), len);
    svp = hv_fetch(g_slot_index, n, len, 0);
    if (!svp) croak("Cannot freeze non-existent slot '%s'", n);
    idx = SvIV(*svp);
    slot_flags[idx] |= SLOT_FLAG_FROZEN;
    slot_flags[idx] &= ~SLOT_FLAG_LOCKED; /* frozen supersedes locked */
    XSRETURN_EMPTY;
}

static XS(xs_is_locked) {
    dXSARGS;
    STRLEN len; const char *n; SV **svp;
    if (items < 1) XSRETURN_NO;
    n   = SvPV(ST(0), len);
    svp = hv_fetch(g_slot_index, n, len, 0);
    if (!svp) XSRETURN_NO;
    if (slot_flags[SvIV(*svp)] & SLOT_FLAG_LOCKED) XSRETURN_YES;
    XSRETURN_NO;
}

static XS(xs_is_frozen) {
    dXSARGS;
    STRLEN len; const char *n; SV **svp;
    if (items < 1) XSRETURN_NO;
    n   = SvPV(ST(0), len);
    svp = hv_fetch(g_slot_index, n, len, 0);
    if (!svp) XSRETURN_NO;
    if (slot_flags[SvIV(*svp)] & SLOT_FLAG_FROZEN) XSRETURN_YES;
    XSRETURN_NO;
}

/* ============================================
   MODULE / BOOT
   ============================================ */

MODULE = Legba    PACKAGE = Legba

PROTOTYPES: DISABLE

BOOT:
{
#if LEGBA_HAS_XOP
    XopENTRY_set(&legba_get_xop, xop_name, "legba_get");
    XopENTRY_set(&legba_get_xop, xop_desc, "Legba slot getter");
    XopENTRY_set(&legba_get_xop, xop_class, OA_BASEOP);
    Perl_custom_op_register(aTHX_ pp_slot_get, &legba_get_xop);

    XopENTRY_set(&legba_set_xop, xop_name, "legba_set");
    XopENTRY_set(&legba_set_xop, xop_desc, "Legba slot setter");
    XopENTRY_set(&legba_set_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_slot_set, &legba_set_xop);

    XopENTRY_set(&legba_watch_xop, xop_name, "legba_watch");
    XopENTRY_set(&legba_watch_xop, xop_desc, "Legba slot watcher registration");
    XopENTRY_set(&legba_watch_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_slot_watch, &legba_watch_xop);

    XopENTRY_set(&legba_unwatch_xop, xop_name, "legba_unwatch");
    XopENTRY_set(&legba_unwatch_xop, xop_desc, "Legba slot unwatch all");
    XopENTRY_set(&legba_unwatch_xop, xop_class, OA_BASEOP);
    Perl_custom_op_register(aTHX_ pp_slot_unwatch, &legba_unwatch_xop);

    XopENTRY_set(&legba_unwatch_one_xop, xop_name, "legba_unwatch_one");
    XopENTRY_set(&legba_unwatch_one_xop, xop_desc, "Legba slot unwatch specific");
    XopENTRY_set(&legba_unwatch_one_xop, xop_class, OA_UNOP);
    Perl_custom_op_register(aTHX_ pp_slot_unwatch_one, &legba_unwatch_one_xop);

    XopENTRY_set(&legba_clear_xop, xop_name, "legba_clear");
    XopENTRY_set(&legba_clear_xop, xop_desc, "Legba slot clear");
    XopENTRY_set(&legba_clear_xop, xop_class, OA_BASEOP);
    Perl_custom_op_register(aTHX_ pp_slot_clear, &legba_clear_xop);
#endif

    /* Initialise globals */
    g_slot_index = newHV();
    g_slot_names = newHV();
    g_watchers   = newHV();

    g_slots_size = 16;
    Newx(g_slots,        g_slots_size, SV*);
    Newxz(g_has_watchers,g_slots_size, char);
    Newxz(slot_flags,    g_slots_size, UV);
    {
        IV i;
        for (i = 0; i < g_slots_size; i++)
            g_slots[i] = newSV(0); /* dedicated SV — pointer is stable */
    }

    /* import */
    newXS("Legba::import", xs_import, __FILE__);

    /* New API (from Ancient/slot) */
    newXS("Legba::add",          xs_add,          __FILE__);
    newXS("Legba::get_by_idx",   xs_get_by_idx,   __FILE__);
    newXS("Legba::set_by_idx",   xs_set_by_idx,   __FILE__);
    newXS("Legba::slots",        xs_slots,        __FILE__);
    newXS("Legba::exists",       xs_exists,       __FILE__);
    newXS("Legba::clear_by_idx", xs_clear_by_idx, __FILE__);
    {
        CV *cv = newXS("Legba::get", xs_get, __FILE__);
        cv_set_call_checker(cv, slot_get_call_checker, (SV*)cv);
    }
    {
        CV *cv = newXS("Legba::set", xs_set, __FILE__);
        cv_set_call_checker(cv, slot_set_call_checker, (SV*)cv);
    }
    {
        CV *cv = newXS("Legba::index", xs_index, __FILE__);
        cv_set_call_checker(cv, slot_index_call_checker, (SV*)cv);
    }
    {
        CV *cv = newXS("Legba::watch", xs_watch, __FILE__);
        cv_set_call_checker(cv, slot_watch_call_checker, (SV*)cv);
    }
    {
        CV *cv = newXS("Legba::unwatch", xs_unwatch, __FILE__);
        cv_set_call_checker(cv, slot_unwatch_call_checker, (SV*)cv);
    }
    {
        CV *cv = newXS("Legba::clear", xs_clear_named, __FILE__);
        cv_set_call_checker(cv, slot_clear_call_checker, (SV*)cv);
    }

    /* Backward-compatible API (_get, _set, _exists, _delete, _keys, _clear,
       _lock, _unlock, _freeze, _is_locked, _is_frozen, _install_accessor,
       _slot_ptr, _registry, _make_get_op, _make_set_op) */
    {
        CV *cv = newXS("Legba::_get", xs_get, __FILE__);
        cv_set_call_checker(cv, slot_get_call_checker, (SV*)cv);
    }
    {
        CV *cv = newXS("Legba::_set", xs_set, __FILE__);
        cv_set_call_checker(cv, slot_set_call_checker, (SV*)cv);
    }
    newXS("Legba::_exists",           xs_exists,            __FILE__);
    newXS("Legba::_delete",           xs_delete,            __FILE__);
    newXS("Legba::_keys",             xs_keys,              __FILE__);
    newXS("Legba::_clear",            xs_clear_all,         __FILE__);
    newXS("Legba::_lock",             xs_lock,              __FILE__);
    newXS("Legba::_unlock",           xs_unlock,            __FILE__);
    newXS("Legba::_freeze",           xs_freeze,            __FILE__);
    newXS("Legba::_is_locked",        xs_is_locked,         __FILE__);
    newXS("Legba::_is_frozen",        xs_is_frozen,         __FILE__);
    newXS("Legba::_install_accessor", xs_install_accessor_fn,__FILE__);
    newXS("Legba::_slot_ptr",         xs_slot_ptr,          __FILE__);
    newXS("Legba::_registry",         xs_registry,          __FILE__);
    newXS("Legba::_make_get_op",      xs_make_get_op,       __FILE__);
    newXS("Legba::_make_set_op",      xs_make_set_op,       __FILE__);
}
