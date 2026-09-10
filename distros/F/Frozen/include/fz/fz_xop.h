#ifndef FZ_XOP_H
#define FZ_XOP_H

#include "fz/fz_sv.h"
#include "xop_compat.h"

static Perl_check_t fz_prev_ck_entersub = NULL;

static CV *fz_cv_get    = NULL;
static CV *fz_cv_find   = NULL;
static CV *fz_cv_root   = NULL;
static CV *fz_cv_fetch  = NULL;
static CV *fz_cv_child  = NULL;
static CV *fz_cv_exists = NULL;
static CV *fz_cv_at     = NULL;
static CV *fz_cv_count  = NULL;
static CV *fz_cv_kind   = NULL;
static CV *fz_cv_value  = NULL;
static HV *fz_stash     = NULL;

static IV fz_xop_hits = 0;
static IV fz_xop_miss = 0;
static IV fz_xop_hook = 0;

#define FZ_IS_OURS(sv) \
    (SvROK(sv) && SvOBJECT(SvRV(sv)) && SvSTASH(SvRV(sv)) == fz_stash)

static fz_container *fz_xop_invocant(pTHX_ SV **sp, CV *want, int nargs) {
    SV **mark = PL_stack_base + TOPMARK;
    SV *self;
    if (sp - mark != nargs + 2) return NULL;
    if ((CV *)*sp != want)      return NULL;
    self = mark[1];
    if (!FZ_IS_OURS(self))      return NULL;
    {
        fz_container *c = INT2PTR(fz_container *, SvIV(SvRV(self)));
        if (!c || !c->base) return NULL;
        return c;
    }
}

#define FZ_XOP_RETURN(nargs, sv)              \
    do {                                       \
        (void)POPMARK;                         \
        sp -= (nargs) + 2;                     \
        PUSHs(sv);                             \
        PUTBACK;                               \
        return NORMAL;                         \
    } while (0)

#ifdef G_LIST
#  define FZ_G_LIST G_LIST
#else
#  define FZ_G_LIST G_ARRAY
#endif

#define FZ_XOP_ABSENT(nargs)                          \
    do {                                              \
        (void)POPMARK;                                \
        sp -= (nargs) + 2;                            \
        if (GIMME_V != FZ_G_LIST) PUSHs(&PL_sv_undef); \
        PUTBACK;                                      \
        return NORMAL;                                \
    } while (0)

static OP *fz_pp_get(pTHX) {
    dSP;
    fz_container *c = fz_xop_invocant(aTHX_ sp, fz_cv_get, 1);
    if (c) {
        SV **mark = PL_stack_base + TOPMARK;
        SV *pathsv = mark[2];
        STRLEN plen;
        const char *p = SvPV(pathsv, plen);
        uint32_t cur, slot = 0;
        STRLEN i, start;

        fz_xop_hits++;

        if (fz_has_flat(c->base)) {
            uint32_t got = fz_flat_find(c->base, (uint32_t)c->len,
                                        p, (uint32_t)plen);
            if (got != FZ_NOTFOUND)
                FZ_XOP_RETURN(1, sv_2mortal(fz_slot_to_sv(aTHX_ c, got)));
        }
        cur = fz_rd_u32(c->base + FZ_H_ROOT);
        start = 0;
        for (i = 0; i <= plen; i++) {
            if (i == plen || p[i] == '.') {
                if (fz_probe(c->base, (uint32_t)c->len, cur, p + start,
                             (uint32_t)(i - start), &slot) == FZ_ABSENT)
                    FZ_XOP_ABSENT(1);
                cur = slot;
                start = i + 1;
            }
        }
        FZ_XOP_RETURN(1, sv_2mortal(fz_slot_to_sv(aTHX_ c, cur)));
    }
    fz_xop_miss++;
    return PL_ppaddr[OP_ENTERSUB](aTHX);
}

static OP *fz_pp_find(pTHX) {
    dSP;
    fz_container *c = fz_xop_invocant(aTHX_ sp, fz_cv_find, 1);
    if (c) {
        SV **mark = PL_stack_base + TOPMARK;
        STRLEN klen;
        const char *k = SvPV(mark[2], klen);
        uint32_t root = fz_rd_u32(c->base + FZ_H_ROOT), slot;
        fz_xop_hits++;
        if (FZ_SLOT_TAG(root) != FZ_T_HASH)
            FZ_XOP_RETURN(1, &PL_sv_undef);
        slot = fz_hash_find(c->base, (uint32_t)c->len, FZ_SLOT_OFF(root),
                            k, (uint32_t)klen);
        FZ_XOP_RETURN(1, slot == FZ_NOTFOUND ? &PL_sv_undef
                                             : sv_2mortal(newSVuv(slot)));
    }
    fz_xop_miss++;
    return PL_ppaddr[OP_ENTERSUB](aTHX);
}

static OP *fz_pp_root(pTHX) {
    dSP;
    fz_container *c = fz_xop_invocant(aTHX_ sp, fz_cv_root, 0);
    if (c) {
        fz_xop_hits++;
        FZ_XOP_RETURN(0, sv_2mortal(newSVuv(fz_rd_u32(c->base + FZ_H_ROOT))));
    }
    fz_xop_miss++;
    return PL_ppaddr[OP_ENTERSUB](aTHX);
}

#define FZ_XOP_HANDLE(mark_, idx_) ((uint32_t)SvUV((mark_)[(idx_)]))

static OP *fz_pp_fetch(pTHX) {
    dSP;
    fz_container *c = fz_xop_invocant(aTHX_ sp, fz_cv_fetch, 2);
    if (c) {
        SV **mark = PL_stack_base + TOPMARK;
        uint32_t h = FZ_XOP_HANDLE(mark, 2);
        STRLEN klen;
        const char *k = SvPV(mark[3], klen);
        uint32_t slot = 0;
        fz_xop_hits++;
        if (!fz_handle_ok(c->base, (uint32_t)c->len, h)) {
            fz_xop_hits--; fz_xop_miss++;
            return PL_ppaddr[OP_ENTERSUB](aTHX);
        }
        if (fz_probe(c->base, (uint32_t)c->len, h, k, (uint32_t)klen, &slot)
                == FZ_ABSENT)
            FZ_XOP_ABSENT(2);
        FZ_XOP_RETURN(2, sv_2mortal(fz_slot_to_sv(aTHX_ c, slot)));
    }
    fz_xop_miss++;
    return PL_ppaddr[OP_ENTERSUB](aTHX);
}

static OP *fz_pp_child(pTHX) {
    dSP;
    fz_container *c = fz_xop_invocant(aTHX_ sp, fz_cv_child, 2);
    if (c) {
        SV **mark = PL_stack_base + TOPMARK;
        uint32_t h = FZ_XOP_HANDLE(mark, 2);
        STRLEN klen;
        const char *k = SvPV(mark[3], klen);
        uint32_t slot = 0;
        fz_xop_hits++;
        if (!fz_handle_ok(c->base, (uint32_t)c->len, h)) {
            fz_xop_hits--; fz_xop_miss++;
            return PL_ppaddr[OP_ENTERSUB](aTHX);
        }
        FZ_XOP_RETURN(2,
            fz_probe(c->base, (uint32_t)c->len, h, k, (uint32_t)klen, &slot)
                == FZ_ABSENT ? &PL_sv_undef : sv_2mortal(newSVuv(slot)));
    }
    fz_xop_miss++;
    return PL_ppaddr[OP_ENTERSUB](aTHX);
}

static OP *fz_pp_exists(pTHX) {
    dSP;
    fz_container *c = fz_xop_invocant(aTHX_ sp, fz_cv_exists, 2);
    if (c) {
        SV **mark = PL_stack_base + TOPMARK;
        uint32_t h = FZ_XOP_HANDLE(mark, 2);
        STRLEN klen;
        const char *k = SvPV(mark[3], klen);
        fz_xop_hits++;
        if (!fz_handle_ok(c->base, (uint32_t)c->len, h)) {
            fz_xop_hits--; fz_xop_miss++;
            return PL_ppaddr[OP_ENTERSUB](aTHX);
        }
        FZ_XOP_RETURN(2, sv_2mortal(newSViv(
            fz_probe(c->base, (uint32_t)c->len, h, k, (uint32_t)klen, NULL)
                != FZ_ABSENT)));
    }
    fz_xop_miss++;
    return PL_ppaddr[OP_ENTERSUB](aTHX);
}

static OP *fz_pp_at(pTHX) {
    dSP;
    fz_container *c = fz_xop_invocant(aTHX_ sp, fz_cv_at, 2);
    if (c) {
        SV **mark = PL_stack_base + TOPMARK;
        uint32_t h = FZ_XOP_HANDLE(mark, 2);
        uint32_t i = (uint32_t)SvUV(mark[3]);
        uint32_t slot = 0;
        fz_xop_hits++;
        if (!fz_handle_ok(c->base, (uint32_t)c->len, h)) {
            fz_xop_hits--; fz_xop_miss++;
            return PL_ppaddr[OP_ENTERSUB](aTHX);
        }
        if (fz_at(c->base, (uint32_t)c->len, h, i, &slot) == FZ_ABSENT)
            FZ_XOP_ABSENT(2);
        FZ_XOP_RETURN(2, sv_2mortal(fz_slot_to_sv(aTHX_ c, slot)));
    }
    fz_xop_miss++;
    return PL_ppaddr[OP_ENTERSUB](aTHX);
}

static OP *fz_pp_count(pTHX) {
    dSP;
    fz_container *c = fz_xop_invocant(aTHX_ sp, fz_cv_count, 1);
    if (c) {
        SV **mark = PL_stack_base + TOPMARK;
        uint32_t h = FZ_XOP_HANDLE(mark, 2);
        fz_xop_hits++;
        if (!fz_handle_ok(c->base, (uint32_t)c->len, h)) {
            fz_xop_hits--; fz_xop_miss++;
            return PL_ppaddr[OP_ENTERSUB](aTHX);
        }
        FZ_XOP_RETURN(1, sv_2mortal(newSVuv(
            fz_count(c->base, (uint32_t)c->len, h))));
    }
    fz_xop_miss++;
    return PL_ppaddr[OP_ENTERSUB](aTHX);
}

static OP *fz_pp_value(pTHX) {
    dSP;
    fz_container *c = fz_xop_invocant(aTHX_ sp, fz_cv_value, 1);
    if (c) {
        SV **mark = PL_stack_base + TOPMARK;
        uint32_t h = FZ_XOP_HANDLE(mark, 2);
        fz_xop_hits++;
        if (!fz_handle_ok(c->base, (uint32_t)c->len, h)) {
            fz_xop_hits--; fz_xop_miss++;
            return PL_ppaddr[OP_ENTERSUB](aTHX);
        }
        FZ_XOP_RETURN(1, sv_2mortal(fz_slot_to_sv(aTHX_ c, h)));
    }
    fz_xop_miss++;
    return PL_ppaddr[OP_ENTERSUB](aTHX);
}

static OP *fz_pp_kind(pTHX) {
    dSP;
    fz_container *c = fz_xop_invocant(aTHX_ sp, fz_cv_kind, 1);
    if (c) {
        SV **mark = PL_stack_base + TOPMARK;
        uint32_t h = FZ_XOP_HANDLE(mark, 2);
        const char *k;
        fz_xop_hits++;
        if (!fz_handle_ok(c->base, (uint32_t)c->len, h)) {
            fz_xop_hits--; fz_xop_miss++;
            return PL_ppaddr[OP_ENTERSUB](aTHX);
        }
        switch (FZ_SLOT_TAG(h)) {
        case FZ_T_UNDEF: k = "undef";  break;
        case FZ_T_TRUE:  case FZ_T_FALSE: k = "bool"; break;
        case FZ_T_INT:   case FZ_T_UINT:  k = "int";  break;
        case FZ_T_NUM:   k = "num";    break;
        case FZ_T_STR:   k = "string"; break;
        case FZ_T_HASH:  k = "hash";   break;
        case FZ_T_ARRAY: k = "array";  break;
        default:         k = "unknown";
        }
        FZ_XOP_RETURN(1, sv_2mortal(newSVpv(k, 0)));
    }
    fz_xop_miss++;
    return PL_ppaddr[OP_ENTERSUB](aTHX);
}

static void fz_try_hook(pTHX_ OP *o) {
    OP *pushop, *selfop, *last, *cur;
    int nargs = 0;
    const char *name;

    if (!o || o->op_type != OP_ENTERSUB) return;

    if (o->op_ppaddr == fz_pp_get   || o->op_ppaddr == fz_pp_find
     || o->op_ppaddr == fz_pp_root  || o->op_ppaddr == fz_pp_fetch
     || o->op_ppaddr == fz_pp_child || o->op_ppaddr == fz_pp_exists
     || o->op_ppaddr == fz_pp_at    || o->op_ppaddr == fz_pp_count
     || o->op_ppaddr == fz_pp_value || o->op_ppaddr == fz_pp_kind) return;

    if (o->op_ppaddr != PL_ppaddr[OP_ENTERSUB]) return;

    pushop = cUNOPx(o)->op_first;
    if (!pushop) return;
    if (!OpHAS_SIBLING(pushop)) pushop = cUNOPx(pushop)->op_first;
    if (!pushop) return;

    selfop = OpSIBLING(pushop);
    if (!selfop) return;

    last = selfop;
    while (OpHAS_SIBLING(last)) { cur = OpSIBLING(last); if (!cur) break; last = cur; }
    if (!last || last->op_type != OP_METHOD_NAMED) return;

    for (cur = OpSIBLING(selfop); cur && cur != last; cur = OpSIBLING(cur))
        nargs++;

    {
        SV *namesv;
#if defined(OPpMETH_NO_BAREWORD_IO) || PERL_VERSION_GE(5,22,0)
        namesv = cMETHOPx_meth(last);
#else
        namesv = cSVOPx_sv(last);
#endif
        if (!namesv || !SvPOK(namesv)) return;
        name = SvPVX(namesv);
    }

    if      (nargs == 1 && strEQ(name, "get"))    o->op_ppaddr = fz_pp_get;
    else if (nargs == 1 && strEQ(name, "find"))   o->op_ppaddr = fz_pp_find;
    else if (nargs == 0 && strEQ(name, "root"))   o->op_ppaddr = fz_pp_root;
    else if (nargs == 2 && strEQ(name, "fetch"))  o->op_ppaddr = fz_pp_fetch;
    else if (nargs == 2 && strEQ(name, "child"))  o->op_ppaddr = fz_pp_child;
    else if (nargs == 2 && strEQ(name, "exists")) o->op_ppaddr = fz_pp_exists;
    else if (nargs == 2 && strEQ(name, "at"))     o->op_ppaddr = fz_pp_at;
    else if (nargs == 1 && strEQ(name, "count"))  o->op_ppaddr = fz_pp_count;
    else if (nargs == 1 && strEQ(name, "value"))  o->op_ppaddr = fz_pp_value;
    else if (nargs == 1 && strEQ(name, "kind"))   o->op_ppaddr = fz_pp_kind;
    else return;

    fz_xop_hook++;
}

static OP *fz_ck_entersub(pTHX_ OP *o) {
    if (fz_prev_ck_entersub) o = fz_prev_ck_entersub(aTHX_ o);
    fz_try_hook(aTHX_ o);
    return o;
}

#endif
