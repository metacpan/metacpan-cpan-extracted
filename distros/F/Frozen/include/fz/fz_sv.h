#ifndef FZ_SV_H
#define FZ_SV_H

#include "fz/fz_read.h"
#include "fz/fz_map.h"

static fz_container *fz_self(pTHX_ SV *self) {
    fz_container *c;
    if (!SvROK(self)) croak("Frozen: not a Frozen container");
    c = INT2PTR(fz_container *, SvIV(SvRV(self)));
    if (!c || !c->base) croak("Frozen: this container is closed");
    return c;
}

static void fz_check_handle(pTHX_ fz_container *c, uint32_t h) {
    if (!fz_handle_ok(c->base, (uint32_t)c->len, h))
        croak("Frozen: %" UVuf " is not a handle into this block", (UV)h);
}

static SV *fz_slot_to_sv_b(pTHX_ fz_container *c, uint32_t slot, int depth,
                           uint32_t *budget);

static SV *fz_slot_to_sv(pTHX_ fz_container *c, uint32_t slot) {
    uint32_t budget = (uint32_t)(c->len / 4) + 16;
    return fz_slot_to_sv_b(aTHX_ c, slot, 0, &budget);
}

static SV *fz_slot_to_sv_d(pTHX_ fz_container *c, uint32_t slot, int depth) {
    uint32_t budget = (uint32_t)(c->len / 4) + 16;
    return fz_slot_to_sv_b(aTHX_ c, slot, depth, &budget);
}

static SV *fz_slot_to_sv_b(pTHX_ fz_container *c, uint32_t slot, int depth,
                           uint32_t *budget) {
    const unsigned char *b = c->base;
    uint32_t off = FZ_SLOT_OFF(slot);

    if (depth > FZ_MAX_DEPTH) return newSV(0);
    if (!*budget) return newSV(0);
    (*budget)--;
    if (!fz_handle_ok(b, (uint32_t)c->len, slot)) return newSV(0);

    switch (FZ_SLOT_TAG(slot)) {
    case FZ_T_UNDEF:
        return newSV(0);
    case FZ_T_TRUE:
    case FZ_T_FALSE: {
        SV *sv = newSViv(FZ_SLOT_TAG(slot) == FZ_T_TRUE ? 1 : 0);
        return sv;
    }

    case FZ_T_INT: {
        int64_t v = 0;
        (void)fz_i64_at(b, (uint32_t)c->len, slot, &v);
        return newSViv((IV)v);
    }
    case FZ_T_UINT: {
        uint64_t v = 0;
        (void)fz_u64_at(b, (uint32_t)c->len, slot, &v);
        return newSVuv((UV)v);
    }
    case FZ_T_NUM: {
        double d = 0;
        (void)fz_f64_at(b, (uint32_t)c->len, slot, &d);
        return newSVnv((NV)d);
    }
    case FZ_T_STR: {
        uint32_t len = 0;
        int utf8 = 0;
        const char *p = fz_str_at(b, (uint32_t)c->len, slot, &len, &utf8);
        SV *sv = newSVpvn(p ? p : "", p ? len : 0);
        if (utf8) SvUTF8_on(sv);
        return sv;
    }
    case FZ_T_ARRAY: {
        uint32_t n = fz_count(b, (uint32_t)c->len, slot), i;
        AV *av = newAV();
        av_extend(av, (SSize_t)n);
        for (i = 0; i < n; i++) {
            uint32_t s = fz_rd_u32(b + off + 4 + i * 4);
            av_push(av, fz_slot_to_sv_b(aTHX_ c, s, depth + 1, budget));
        }
        return newRV_noinc((SV *)av);
    }
    case FZ_T_HASH: {
        uint32_t n = fz_count(b, (uint32_t)c->len, slot), i;
        HV *hv = newHV();
        hv_ksplit(hv, (IV)(n ? n : 1));
        for (i = 0; i < n; i++) {
            const char *k; uint32_t kl; int u = 0;
            if (!fz_key_at(b, (uint32_t)c->len, slot, i, &k, &kl, &u)) continue;
            {
                SV *key = newSVpvn(k, kl);
                if (u) SvUTF8_on(key);
                (void)hv_store_ent(hv, sv_2mortal(key),
                                   fz_slot_to_sv_b(aTHX_ c,
                                       fz_val_at(b, (uint32_t)c->len, slot, i),
                                       depth + 1, budget),
                                   0);
            }
        }
        return newRV_noinc((SV *)hv);
    }
    }
    return newSV(0);
}

typedef struct {
    SV  *cb;
    SV  *self;
    char sep;
    IV   count;
} fz_walk_perl;

static void fz_walk_perl_cb(void *ud, const char **segs, const uint32_t *lens,
                            int depth, uint32_t slot) {
    fz_walk_perl *w = (fz_walk_perl *)ud;
    dTHX;
    dSP;
    SV *path = newSVpvs("");
    int i;
    for (i = 0; i < depth; i++) {
        if (i) sv_catpvn(path, &w->sep, 1);
        sv_catpvn(path, segs[i], lens[i]);
    }
    w->count++;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, 3);
    PUSHs(sv_2mortal(path));
    PUSHs(sv_2mortal(newSVuv(slot)));
    {
        AV *av = newAV();
        av_extend(av, (SSize_t)depth);
        for (i = 0; i < depth; i++) av_push(av, newSVpvn(segs[i], lens[i]));
        PUSHs(sv_2mortal(newRV_noinc((SV *)av)));
    }
    PUTBACK;
    call_sv(w->cb, G_VOID | G_DISCARD);
    FREETMPS; LEAVE;
}

static SV *fz_tie_for(pTHX_ SV *csv, uint32_t slot) {
    AV *state;
    SV *obj;
    const char *cls;
    uint32_t tag = FZ_SLOT_TAG(slot);

    if (tag != FZ_T_HASH && tag != FZ_T_ARRAY) {
        fz_container *c = INT2PTR(fz_container *, SvIV(SvRV(csv)));
        return fz_slot_to_sv(aTHX_ c, slot);
    }

    state = newAV();
    av_push(state, SvREFCNT_inc_simple_NN(csv));
    av_push(state, newSVuv(slot));
    av_push(state, newSViv(0));
    cls = (tag == FZ_T_HASH) ? "Frozen::Tie::Hash" : "Frozen::Tie::Array";
    obj = sv_bless(newRV_noinc((SV *)state), gv_stashpv(cls, GV_ADD));

    if (tag == FZ_T_HASH) {
        HV *hv = newHV();
        hv_magic(hv, (GV *)obj, PERL_MAGIC_tied);
        SvREFCNT_dec(obj);
        return newRV_noinc((SV *)hv);
    }
    else {
        AV *av = newAV();
        sv_magic((SV *)av, obj, PERL_MAGIC_tied, NULL, 0);
        SvREFCNT_dec(obj);
        return newRV_noinc((SV *)av);
    }
}

static void fz_tie_parts(pTHX_ SV *self, SV **csv, fz_container **c,
                         uint32_t *h) {
    AV *state;
    SV **e;
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVAV)
        croak("Frozen: not a Frozen tie");
    state = (AV *)SvRV(self);
    e = av_fetch(state, 0, 0);
    if (!e || !*e) croak("Frozen: this tie has lost its container");
    *csv = *e;
    *c   = INT2PTR(fz_container *, SvIV(SvRV(*csv)));
    if (!*c || !(*c)->base) croak("Frozen: this container is closed");
    e = av_fetch(state, 1, 0);
    *h = (uint32_t)(e && *e ? SvUV(*e) : 0);
}

#endif
