#ifndef FZ_BUILD_H
#define FZ_BUILD_H

#include "fz/fz_format.h"
#include "fz/fz_mphf.h"
#include "fz/fz_read.h"

typedef struct {
    unsigned char *p;
    size_t         len;
    size_t         cap;
} fz_buf;

typedef struct {
    fz_buf  buf;
    HV     *interned;
    HV     *seen;
    SV     *path;
    int     depth;
    int     lossy_nv;
} fz_builder;

#define FZ_INPROGRESS ((IV)-1)

static int fz_buf_need(fz_buf *b, size_t n) {
    if (b->len + n <= b->cap) return 1;
    {
        size_t want = b->cap ? b->cap : 1024;
        unsigned char *np;
        while (want < b->len + n) {
            if (want > (size_t)FZ_MAX_BLOCK) return 0;
            want *= 2;
        }
        np = (unsigned char *)realloc(b->p, want);
        if (!np) return 0;
        b->p = np;
        b->cap = want;
    }
    return 1;
}

static int fz_buf_align(fz_buf *b) {
    size_t pad = (FZ_ALIGN - (b->len & (FZ_ALIGN - 1))) & (FZ_ALIGN - 1);
    if (!pad) return 1;
    if (!fz_buf_need(b, pad)) return 0;
    memset(b->p + b->len, 0, pad);
    b->len += pad;
    return 1;
}

static int fz_buf_put(fz_buf *b, const void *src, size_t n) {
    if (!fz_buf_need(b, n)) return 0;
    if (n) memcpy(b->p + b->len, src, n);
    b->len += n;
    return 1;
}

static int fz_buf_u32(fz_buf *b, uint32_t v) {
    if (!fz_buf_need(b, 4)) return 0;
    fz_wr_u32(b->p + b->len, v);
    b->len += 4;
    return 1;
}

static void fz_path_push(pTHX_ fz_builder *B, const char *seg, STRLEN len,
                         int is_index) {
    if (SvCUR(B->path) && !is_index) sv_catpvn(B->path, ".", 1);
    if (is_index) sv_catpvs(B->path, "[");
    sv_catpvn(B->path, seg, len);
    if (is_index) sv_catpvs(B->path, "]");
}

static void fz_croak(pTHX_ fz_builder *B, const char *what) {
    croak("Frozen: %s at %s%s", what,
          SvCUR(B->path) ? "" : "the root",
          SvCUR(B->path) ? SvPV_nolen(B->path) : "");
}

static uint32_t fz_emit_str(pTHX_ fz_builder *B, SV *sv) {
    STRLEN len;
    const char *s;
    int utf8;
    SV *key, **found;
    uint32_t off;

    s    = SvPV(sv, len);
    utf8 = SvUTF8(sv) ? 1 : 0;

    if (utf8 && len && !is_utf8_string((const U8 *)s, len))
        fz_croak(aTHX_ B, "a string flagged UTF-8 whose bytes are not valid UTF-8");

    key = sv_2mortal(newSVpvf("%d\1", utf8));
    sv_catpvn(key, s, len);
    found = hv_fetch(B->interned, SvPVX(key), (I32)SvCUR(key), 0);
    if (found && *found) return (uint32_t)SvUV(*found);

    if (!fz_buf_align(&B->buf)) fz_croak(aTHX_ B, "the block would exceed 2 GiB");
    off = (uint32_t)B->buf.len;
    if (!fz_buf_u32(&B->buf, (uint32_t)len)
        || !fz_buf_need(&B->buf, 4 + len + 1))
        fz_croak(aTHX_ B, "the block would exceed 2 GiB");
    B->buf.p[B->buf.len]     = (unsigned char)utf8;
    B->buf.p[B->buf.len + 1] = 0;
    B->buf.p[B->buf.len + 2] = 0;
    B->buf.p[B->buf.len + 3] = 0;
    B->buf.len += 4;
    memcpy(B->buf.p + B->buf.len, s, len);
    B->buf.len += len;
    B->buf.p[B->buf.len++] = 0;

    (void)hv_store(B->interned, SvPVX(key), (I32)SvCUR(key), newSVuv(off), 0);
    return off;
}

static uint32_t fz_emit_i64(pTHX_ fz_builder *B, IV v) {
    uint32_t off;
    int64_t w = (int64_t)v;
    unsigned char tmp[8];
    int i;
    if (!fz_buf_align(&B->buf)) fz_croak(aTHX_ B, "the block would exceed 2 GiB");
    off = (uint32_t)B->buf.len;
    for (i = 0; i < 8; i++) tmp[i] = (unsigned char)((w >> (i * 8)) & 0xff);
    if (!fz_buf_put(&B->buf, tmp, 8)) fz_croak(aTHX_ B, "the block would exceed 2 GiB");
    return off;
}

static uint32_t fz_emit_u64(pTHX_ fz_builder *B, UV v) {
    uint32_t off;
    uint64_t w = (uint64_t)v;
    unsigned char tmp[8];
    int i;
    if (!fz_buf_align(&B->buf)) fz_croak(aTHX_ B, "the block would exceed 2 GiB");
    off = (uint32_t)B->buf.len;
    for (i = 0; i < 8; i++) tmp[i] = (unsigned char)((w >> (i * 8)) & 0xff);
    if (!fz_buf_put(&B->buf, tmp, 8)) fz_croak(aTHX_ B, "the block would exceed 2 GiB");
    return off;
}

static uint32_t fz_emit_nv(pTHX_ fz_builder *B, NV v) {
    uint32_t off;
    double d = (double)v;

    if (!B->lossy_nv && (NV)d != v && v == v)
        fz_croak(aTHX_ B, "an NV that does not fit a double (pass lossy_nv => 1 to narrow it)");
    if (!fz_buf_align(&B->buf)) fz_croak(aTHX_ B, "the block would exceed 2 GiB");
    off = (uint32_t)B->buf.len;
    if (!fz_buf_put(&B->buf, &d, sizeof d)) fz_croak(aTHX_ B, "the block would exceed 2 GiB");
    return off;
}

typedef struct { const char *k; STRLEN len; int utf8; SV *val; } fz_kv;

static int fz_kv_cmp(const void *a, const void *b) {
    const fz_kv *x = (const fz_kv *)a, *y = (const fz_kv *)b;
    STRLEN n = x->len < y->len ? x->len : y->len;
    int c = n ? memcmp(x->k, y->k, n) : 0;
    if (c) return c;

    return x->len < y->len ? -1 : x->len > y->len ? 1 : 0;
}

static uint32_t fz_emit(pTHX_ fz_builder *B, SV *sv);

static uint32_t fz_emit_av(pTHX_ fz_builder *B, AV *av) {
    SSize_t n = av_len(av) + 1, i;
    uint32_t *slots, node;
    if (n < 0) n = 0;
    slots = (uint32_t *)malloc((size_t)(n ? n : 1) * sizeof(uint32_t));
    if (!slots) fz_croak(aTHX_ B, "out of memory");

    for (i = 0; i < n; i++) {
        SV **e = av_fetch(av, i, 0);
        STRLEN plen = SvCUR(B->path);
        char ibuf[32];
        int ilen = my_snprintf(ibuf, sizeof ibuf, "%" IVdf, (IV)i);
        fz_path_push(aTHX_ B, ibuf, (STRLEN)ilen, 1);
        slots[i] = fz_emit(aTHX_ B, (e && *e) ? *e : &PL_sv_undef);
        SvCUR_set(B->path, plen);
        if (plen == 0) SvPVX(B->path)[0] = '\0';
    }

    if (!fz_buf_align(&B->buf)) { free(slots); fz_croak(aTHX_ B, "the block would exceed 2 GiB"); }
    node = (uint32_t)B->buf.len;
    if (!fz_buf_u32(&B->buf, (uint32_t)n)) { free(slots); fz_croak(aTHX_ B, "the block would exceed 2 GiB"); }
    for (i = 0; i < n; i++) {
        if (!fz_buf_u32(&B->buf, slots[i])) { free(slots); fz_croak(aTHX_ B, "the block would exceed 2 GiB"); }
    }
    free(slots);
    return node;
}

static uint32_t fz_emit_hv(pTHX_ fz_builder *B, HV *hv) {
    I32 n, i;
    fz_kv *kv;
    uint32_t *koff, *vslot, node, lookup;

    hv_iterinit(hv);
    n = hv_iterinit(hv);
    kv = (fz_kv *)malloc((size_t)(n ? n : 1) * sizeof(fz_kv));
    if (!kv) fz_croak(aTHX_ B, "out of memory");

    for (i = 0; i < n; i++) {
        HE *he = hv_iternext(hv);
        if (!he) { n = i; break; }
        kv[i].k    = HePV(he, kv[i].len);
        kv[i].utf8 = HeUTF8(he) ? 1 : 0;
        kv[i].val  = HeVAL(he);
    }

    if (n > 1) qsort(kv, (size_t)n, sizeof(fz_kv), fz_kv_cmp);

    for (i = 1; i < n; i++) {
        if (kv[i].len == kv[i - 1].len && kv[i].utf8 == kv[i - 1].utf8
            && memcmp(kv[i].k, kv[i - 1].k, kv[i].len) == 0) {
            SV *dup = sv_2mortal(newSVpvn(kv[i].k, kv[i].len));
            free(kv);
            croak("Frozen: duplicate key '%s' at %s", SvPV_nolen(dup),
                  SvCUR(B->path) ? SvPV_nolen(B->path) : "the root");
        }
    }

    koff  = (uint32_t *)malloc((size_t)(n ? n : 1) * sizeof(uint32_t));
    vslot = (uint32_t *)malloc((size_t)(n ? n : 1) * sizeof(uint32_t));
    if (!koff || !vslot) { free(kv); free(koff); free(vslot); fz_croak(aTHX_ B, "out of memory"); }

    for (i = 0; i < n; i++) {
        SV *ksv = sv_2mortal(newSVpvn(kv[i].k, kv[i].len));
        STRLEN plen = SvCUR(B->path);
        if (kv[i].utf8) SvUTF8_on(ksv);
        koff[i] = fz_emit_str(aTHX_ B, ksv);
        fz_path_push(aTHX_ B, kv[i].k, kv[i].len, 0);
        vslot[i] = fz_emit(aTHX_ B, kv[i].val);
        SvCUR_set(B->path, plen);
        if (plen == 0) SvPVX(B->path)[0] = '\0';
    }
    free(kv);

    lookup = 0;
    if ((uint32_t)n >= FZ_MPHF_MIN) {
        uint32_t nn = (uint32_t)n;
        uint32_t r  = nn / FZ_MPHF_LAMBDA;
        uint32_t *disp, *pos, seed = 0;
        fz_mphf_key *mk;
        int rc;

        if (r < 1) r = 1;
        mk   = (fz_mphf_key *)malloc((size_t)nn * sizeof(fz_mphf_key));
        disp = (uint32_t *)malloc((size_t)r * sizeof(uint32_t));
        pos  = (uint32_t *)malloc((size_t)nn * sizeof(uint32_t));
        if (!mk || !disp || !pos) {
            free(mk); free(disp); free(pos);
            goto oom;
        }
        for (i = 0; i < n; i++) {
            uint32_t ko = koff[i];
            mk[i].k   = (const char *)B->buf.p + ko + 8;
            mk[i].len = fz_rd_u32(B->buf.p + ko);
        }
        rc = fz_mphf_build(mk, nn, disp, r, pos, &seed);
        if (rc == FZ_MPHF_OK) {
            uint32_t *kk = (uint32_t *)malloc((size_t)nn * sizeof(uint32_t));
            uint32_t *vv = (uint32_t *)malloc((size_t)nn * sizeof(uint32_t));
            if (!kk || !vv) { free(mk); free(disp); free(pos); free(kk); free(vv); goto oom; }

            for (i = 0; i < n; i++) { kk[pos[i]] = koff[i]; vv[pos[i]] = vslot[i]; }
            for (i = 0; i < n; i++) { koff[i] = kk[i]; vslot[i] = vv[i]; }
            free(kk); free(vv);

            if (!fz_buf_align(&B->buf)) { free(mk); free(disp); free(pos); goto oom; }
            lookup = (uint32_t)B->buf.len;
            if (!fz_buf_u32(&B->buf, r) || !fz_buf_u32(&B->buf, seed)) {
                free(mk); free(disp); free(pos); goto oom;
            }
            for (i = 0; i < (I32)r; i++) {
                if (!fz_buf_u32(&B->buf, disp[i])) {
                    free(mk); free(disp); free(pos); goto oom;
                }
            }
        }
        else if (rc == FZ_MPHF_NOMEM) {
            free(mk); free(disp); free(pos);
            goto oom;
        }
        else {
            lookup = 0;
        }
        free(mk); free(disp); free(pos);
    }

    if (!fz_buf_align(&B->buf)) goto oom;
    node = (uint32_t)B->buf.len;
    if (!fz_buf_u32(&B->buf, (uint32_t)n)) goto oom;
    if (!fz_buf_u32(&B->buf, lookup)) goto oom;
    for (i = 0; i < n; i++) if (!fz_buf_u32(&B->buf, koff[i]))  goto oom;
    for (i = 0; i < n; i++) if (!fz_buf_u32(&B->buf, vslot[i])) goto oom;
    free(koff); free(vslot);
    return node;
oom:
    free(koff); free(vslot);
    fz_croak(aTHX_ B, "the block would exceed 2 GiB");
    return 0;
}

static int fz_is_bool(pTHX_ SV *sv, int *out) {
#ifdef SvIsBOOL
    if (SvIsBOOL(sv)) { *out = SvTRUE(sv) ? 1 : 0; return 1; }
#endif
    if (SvROK(sv)) {
        SV *r = SvRV(sv);
        if (SvREADONLY(r) && !SvROK(r) && (SvIOK(r) || SvNOK(r))) {
            IV v = SvIV(r);
            if (v == 0 || v == 1) { *out = (int)v; return 1; }
        }
        if (sv_isobject(sv)) {
            const char *cls = sv_reftype(SvRV(sv), 1);
            if (cls && (strEQ(cls, "JSON::PP::Boolean")
                     || strEQ(cls, "Types::Serialiser::Boolean")
                     || strEQ(cls, "boolean"))) {
                *out = SvTRUE(SvRV(sv)) ? 1 : 0;
                return 1;
            }
        }
    }
    return 0;
}

static uint32_t fz_emit(pTHX_ fz_builder *B, SV *sv) {
    int b;

    if (++B->depth > FZ_MAX_DEPTH) {
        B->depth--;
        fz_croak(aTHX_ B, "a structure deeper than FZ_MAX_DEPTH");
    }

    if (!sv || !SvOK(sv)) { B->depth--; return FZ_SLOT(FZ_T_UNDEF, 0); }

    if (fz_is_bool(aTHX_ sv, &b)) {
        B->depth--;
        return FZ_SLOT(b ? FZ_T_TRUE : FZ_T_FALSE, 0);
    }

    if (SvROK(sv)) {
        SV *rv = SvRV(sv);
        svtype t = SvTYPE(rv);
        SV *addr = sv_2mortal(newSVpvf("%" UVuf, PTR2UV(rv)));
        SV **seen;
        uint32_t slot;

        if (sv_isobject(sv)) { B->depth--; fz_croak(aTHX_ B, "a blessed reference"); }
        if (t == SVt_PVCV)   { B->depth--; fz_croak(aTHX_ B, "a code reference"); }
        if (t == SVt_PVGV)   { B->depth--; fz_croak(aTHX_ B, "a glob"); }
        if (t == SVt_PVIO)   { B->depth--; fz_croak(aTHX_ B, "a filehandle"); }
        if (t != SVt_PVAV && t != SVt_PVHV) {
            B->depth--;
            fz_croak(aTHX_ B, "a reference to a scalar");
        }

        seen = hv_fetch(B->seen, SvPVX(addr), (I32)SvCUR(addr), 0);
        if (seen && *seen) {
            IV got = SvIV(*seen);
            if (got == FZ_INPROGRESS) {
                B->depth--;
                fz_croak(aTHX_ B, "a cycle");
            }
            B->depth--;
            return (uint32_t)got;
        }
        (void)hv_store(B->seen, SvPVX(addr), (I32)SvCUR(addr),
                       newSViv(FZ_INPROGRESS), 0);

        if (t == SVt_PVAV) slot = FZ_SLOT(FZ_T_ARRAY, fz_emit_av(aTHX_ B, (AV *)rv));
        else               slot = FZ_SLOT(FZ_T_HASH,  fz_emit_hv(aTHX_ B, (HV *)rv));

        (void)hv_store(B->seen, SvPVX(addr), (I32)SvCUR(addr),
                       newSViv((IV)slot), 0);
        B->depth--;
        return slot;
    }

    B->depth--;
    if (SvPOKp(sv)) return FZ_SLOT(FZ_T_STR,  fz_emit_str(aTHX_ B, sv));
    if (SvIOKp(sv)) {
        if (SvIsUV(sv) && SvUV(sv) > (UV)IV_MAX)
            return FZ_SLOT(FZ_T_UINT, fz_emit_u64(aTHX_ B, SvUV(sv)));
        return FZ_SLOT(FZ_T_INT, fz_emit_i64(aTHX_ B, SvIV(sv)));
    }
    if (SvNOKp(sv)) return FZ_SLOT(FZ_T_NUM, fz_emit_nv(aTHX_ B, SvNV(sv)));
    return FZ_SLOT(FZ_T_STR, fz_emit_str(aTHX_ B, sv));
}

typedef struct {
    char     **paths;
    uint32_t  *lens;
    uint32_t  *slots;
    uint32_t   n, cap;
    char       sep;
    int        oom;
} fz_flat;

static void fz_flat_cb(void *ud, const char **segs, const uint32_t *lens,
                       int depth, uint32_t slot) {
    fz_flat *f = (fz_flat *)ud;
    uint32_t total = 0;
    int i;
    char *p;

    if (f->oom) return;
    for (i = 0; i < depth; i++) total += lens[i] + (i ? 1 : 0);

    if (f->n == f->cap) {
        uint32_t nc = f->cap ? f->cap * 2 : 256;
        char **np     = (char **)realloc(f->paths, (size_t)nc * sizeof(char *));
        uint32_t *nl  = (uint32_t *)realloc(f->lens,  (size_t)nc * sizeof(uint32_t));
        uint32_t *ns  = (uint32_t *)realloc(f->slots, (size_t)nc * sizeof(uint32_t));
        if (!np || !nl || !ns) { f->oom = 1; free(np); free(nl); free(ns); return; }
        f->paths = np; f->lens = nl; f->slots = ns; f->cap = nc;
    }
    p = (char *)malloc(total ? total : 1);
    if (!p) { f->oom = 1; return; }
    {
        uint32_t at = 0;
        for (i = 0; i < depth; i++) {
            if (i) p[at++] = f->sep;
            memcpy(p + at, segs[i], lens[i]);
            at += lens[i];
        }
    }
    f->paths[f->n] = p;
    f->lens[f->n]  = total;
    f->slots[f->n] = slot;
    f->n++;
}

static void fz_flat_free(fz_flat *f) {
    uint32_t i;
    for (i = 0; i < f->n; i++) free(f->paths[i]);
    free(f->paths); free(f->lens); free(f->slots);
}

static SV *fz_freeze_sv(pTHX_ SV *data, int lossy_nv, const char *flatsep) {
    fz_builder B;
    uint32_t root, flat_off = 0;
    SV *out;
    unsigned char *h;

    B.buf.p = NULL; B.buf.len = 0; B.buf.cap = 0;
    B.interned = newHV();
    B.seen     = newHV();
    B.path     = newSVpvs("");
    B.depth    = 0;
    B.lossy_nv = lossy_nv;

    SAVEFREESV((SV *)B.interned);
    SAVEFREESV((SV *)B.seen);
    SAVEFREESV(B.path);

    if (!fz_buf_need(&B.buf, FZ_HEADER_SIZE)) croak("Frozen: out of memory");
    memset(B.buf.p, 0, FZ_HEADER_SIZE);
    B.buf.len = FZ_HEADER_SIZE;

    root = fz_emit(aTHX_ &B, data);

    if (flatsep) {
        fz_flat f;
        const char *segs[FZ_MAX_DEPTH];
        uint32_t lens[FZ_MAX_DEPTH];
        char *idxbuf;
        uint32_t i;

        memset(&f, 0, sizeof f);
        f.sep = flatsep[0];
        idxbuf = (char *)malloc((size_t)FZ_MAX_DEPTH * 12);
        if (!idxbuf) croak("Frozen: out of memory");
        {
            uint32_t budget = (uint32_t)(B.buf.len / 4) + 16;
            fz_walk_rec(B.buf.p, (uint32_t)B.buf.len, root,
                        segs, lens, idxbuf, 0, fz_flat_cb, &f, &budget);
        }
        free(idxbuf);
        if (f.oom) { fz_flat_free(&f); croak("Frozen: out of memory"); }

        for (i = 0; i + 1 < f.n; i++) {
            uint32_t j;
            for (j = i + 1; j < f.n; j++) {
                if (f.lens[i] == f.lens[j]
                    && memcmp(f.paths[i], f.paths[j], f.lens[i]) == 0) {
                    SV *d = sv_2mortal(newSVpvn(f.paths[i], f.lens[i]));
                    fz_flat_free(&f);
                    croak("Frozen: the flat index would collide on '%s' - two "
                          "distinct leaves join to one path because a key "
                          "contains '%c'", SvPV_nolen(d), flatsep[0]);
                }
            }
            if (f.n > 4096) break;
        }
        if (f.n > 4096) {
            fz_flat_free(&f);
            croak("Frozen: the flat index is limited to 4096 leaves in this "
                  "release (the collision check is quadratic)");
        }

        if (f.n) {
            uint32_t *koff  = (uint32_t *)malloc((size_t)f.n * sizeof(uint32_t));
            uint32_t r      = f.n / FZ_MPHF_LAMBDA;
            uint32_t *disp, *pos, seed = 0;
            fz_mphf_key *mk;
            int rc;

            if (r < 1) r = 1;
            disp = (uint32_t *)malloc((size_t)r * sizeof(uint32_t));
            pos  = (uint32_t *)malloc((size_t)f.n * sizeof(uint32_t));
            mk   = (fz_mphf_key *)malloc((size_t)f.n * sizeof(fz_mphf_key));
            if (!koff || !disp || !pos || !mk) {
                free(koff); free(disp); free(pos); free(mk);
                fz_flat_free(&f);
                croak("Frozen: out of memory");
            }
            for (i = 0; i < f.n; i++) {
                SV *k = sv_2mortal(newSVpvn(f.paths[i], f.lens[i]));
                koff[i] = fz_emit_str(aTHX_ &B, k);
            }
            for (i = 0; i < f.n; i++) {
                mk[i].k   = (const char *)B.buf.p + koff[i] + 8;
                mk[i].len = fz_rd_u32(B.buf.p + koff[i]);
            }
            rc = fz_mphf_build(mk, f.n, disp, r, pos, &seed);
            if (rc == FZ_MPHF_OK) {
                uint32_t *kk = (uint32_t *)malloc((size_t)f.n * sizeof(uint32_t));
                uint32_t *vv = (uint32_t *)malloc((size_t)f.n * sizeof(uint32_t));
                if (kk && vv) {
                    for (i = 0; i < f.n; i++) { kk[pos[i]] = koff[i]; vv[pos[i]] = f.slots[i]; }
                    (void)fz_buf_align(&B.buf);
                    flat_off = (uint32_t)B.buf.len;
                    (void)fz_buf_u32(&B.buf, f.n);
                    (void)fz_buf_u32(&B.buf, r);
                    (void)fz_buf_u32(&B.buf, seed);
                    for (i = 0; i < r; i++)   (void)fz_buf_u32(&B.buf, disp[i]);
                    for (i = 0; i < f.n; i++) (void)fz_buf_u32(&B.buf, kk[i]);
                    for (i = 0; i < f.n; i++) (void)fz_buf_u32(&B.buf, vv[i]);
                }
                free(kk); free(vv);
            }

            free(koff); free(disp); free(pos); free(mk);
        }
        fz_flat_free(&f);
    }

    h = B.buf.p;
    h[FZ_H_MAGIC + 0] = FZ_MAGIC0; h[FZ_H_MAGIC + 1] = FZ_MAGIC1;
    h[FZ_H_MAGIC + 2] = FZ_MAGIC2; h[FZ_H_MAGIC + 3] = FZ_MAGIC3;
    h[FZ_H_VERSION]     = FZ_FORMAT_VERSION;
    h[FZ_H_VERSION + 1] = 0;
    h[FZ_H_HEADER_SIZE]     = FZ_HEADER_SIZE;
    h[FZ_H_HEADER_SIZE + 1] = 0;
    fz_wr_u32(h + FZ_H_FLAGS,
              FZ_FLAG_INTERNED | (flat_off ? FZ_FLAG_FLATINDEX : 0));
    fz_wr_u32(h + FZ_H_ENDIAN, FZ_ENDIAN_PROBE);
    h[FZ_H_OFFWIDTH] = FZ_OFFSET_WIDTH;
    fz_wr_u32(h + FZ_H_TOTAL, (uint32_t)B.buf.len);
    fz_wr_u32(h + FZ_H_ROOT,  root);
    fz_wr_u32(h + FZ_H_SEED,  0);
    fz_wr_u32(h + FZ_H_NODES,   (uint32_t)HvKEYS(B.seen));
    fz_wr_u32(h + FZ_H_STRINGS, (uint32_t)HvKEYS(B.interned));
    fz_wr_u32(h + FZ_H_FLATIDX, flat_off);

    fz_wr_u32(h + FZ_H_CHECKSUM, fz_checksum(B.buf.p, (uint32_t)B.buf.len));

    out = sv_2mortal(newSVpvn((const char *)B.buf.p, B.buf.len));
    free(B.buf.p);
    return out;
}

#endif
