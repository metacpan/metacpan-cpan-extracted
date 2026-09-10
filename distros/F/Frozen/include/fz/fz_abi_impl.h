#ifndef FZ_ABI_IMPL_H
#define FZ_ABI_IMPL_H

typedef char fz_abi_assert_nohandle[(FZ_NOHANDLE == FZ_NOTFOUND) ? 1 : -1];
typedef char fz_abi_assert_probe[
    (FZ_ABSENT == 0 && FZ_LEAF == 1 && FZ_BRANCH == 2) ? 1 : -1];
typedef char fz_abi_assert_kinds[
    (FZ_K_UNDEF == (int)FZ_T_UNDEF && FZ_K_FALSE == (int)FZ_T_FALSE
  && FZ_K_TRUE  == (int)FZ_T_TRUE  && FZ_K_INT   == (int)FZ_T_INT
  && FZ_K_UINT  == (int)FZ_T_UINT  && FZ_K_NUM   == (int)FZ_T_NUM
  && FZ_K_STR   == (int)FZ_T_STR   && FZ_K_HASH  == (int)FZ_T_HASH
  && FZ_K_ARRAY == (int)FZ_T_ARRAY && FZ_K_ARRAY == (int)FZ_T_MAX) ? 1 : -1];
typedef char fz_abi_assert_errors[
    (FZ_ERR_OK      == FZ_OPEN_OK      && FZ_ERR_ENOENT == FZ_OPEN_ENOENT
  && FZ_ERR_SHORT   == FZ_OPEN_SHORT   && FZ_ERR_MAGIC  == FZ_OPEN_MAGIC
  && FZ_ERR_VERSION == FZ_OPEN_VERSION && FZ_ERR_ENDIAN == FZ_OPEN_ENDIAN
  && FZ_ERR_OFFW    == FZ_OPEN_OFFW    && FZ_ERR_TOTAL  == FZ_OPEN_TOTAL
  && FZ_ERR_MAP     == FZ_OPEN_MAP     && FZ_ERR_OFF64  == FZ_OPEN_OFF64)
    ? 1 : -1];

static fz_container *
fz_abi_open(pTHX_ const char *path, int copy, int *err)
{
    fz_container *c;
    int rc;
    if (err) *err = FZ_ERR_MAP;
    c = (fz_container *)malloc(sizeof(fz_container));
    if (!c) return NULL;
    rc = fz_container_open(aTHX_ c, path, copy);
    if (rc == FZ_OPEN_OK) rc = fz_check_header(c->base, c->len);
    if (err) *err = rc;
    if (rc != FZ_OPEN_OK) {
        fz_container_release(c);
        free(c);
        return NULL;
    }
    return c;
}

static fz_container *
fz_abi_attach(const char *bytes, STRLEN len, int *err)
{
    fz_container *c;
    int rc;
    if (err) *err = FZ_ERR_MAP;
    c = (fz_container *)malloc(sizeof(fz_container));
    if (!c) return NULL;
    rc = fz_container_attach_bytes(c, bytes, (size_t)len);
    if (rc == FZ_OPEN_OK) rc = fz_check_header(c->base, c->len);
    if (err) *err = rc;
    if (rc != FZ_OPEN_OK) {
        fz_container_release(c);
        free(c);
        return NULL;
    }
    return c;
}

static void
fz_abi_close(pTHX_ fz_container *c)
{
    if (!c) return;
    if (c->holder) { SvREFCNT_dec(c->holder); c->holder = NULL; }
    fz_container_release(c);
    free(c);
}

static uint32_t
fz_abi_root(const fz_container *c)
{
    if (!c || !c->base) return FZ_NOHANDLE;
    return fz_rd_u32(c->base + FZ_H_ROOT);
}

static int
fz_abi_probe(const fz_container *c, uint32_t node,
             const char *key, STRLEN klen, uint32_t *out)
{
    if (!c || !c->base || !fz_handle_ok(c->base, (uint32_t)c->len, node))
        return FZ_ABSENT;
    return fz_probe(c->base, (uint32_t)c->len, node, key, (uint32_t)klen, out);
}

static uint32_t
fz_abi_child(const fz_container *c, uint32_t node,
             const char *key, STRLEN klen)
{
    uint32_t slot = 0;
    if (fz_abi_probe(c, node, key, klen, &slot) == FZ_ABSENT) return FZ_NOHANDLE;
    return slot;
}

static uint32_t
fz_abi_path(const fz_container *c, uint32_t node,
            const char *path, STRLEN plen, char sep)
{
    if (!c || !c->base || !fz_handle_ok(c->base, (uint32_t)c->len, node))
        return FZ_NOHANDLE;
    return fz_path_find(c->base, (uint32_t)c->len, node, path,
                        (uint32_t)plen, sep);
}

static int
fz_abi_at(const fz_container *c, uint32_t node, uint32_t i, uint32_t *out)
{
    if (!c || !c->base || !fz_handle_ok(c->base, (uint32_t)c->len, node))
        return FZ_ABSENT;
    return fz_at(c->base, (uint32_t)c->len, node, i, out);
}

static int
fz_abi_key_at(const fz_container *c, uint32_t node, uint32_t i,
              const char **key, STRLEN *klen, int *utf8)
{
    uint32_t kl = 0;
    if (!c || !c->base || !fz_handle_ok(c->base, (uint32_t)c->len, node))
        return 0;
    if (!fz_key_at(c->base, (uint32_t)c->len, node, i, key, &kl, utf8))
        return 0;
    if (klen) *klen = (STRLEN)kl;
    return 1;
}

static uint32_t
fz_abi_count(const fz_container *c, uint32_t node)
{
    if (!c || !c->base || !fz_handle_ok(c->base, (uint32_t)c->len, node))
        return 0;
    return fz_count(c->base, (uint32_t)c->len, node);
}

static int
fz_abi_kind(const fz_container *c, uint32_t node)
{
    if (!c || !c->base || !fz_handle_ok(c->base, (uint32_t)c->len, node))
        return FZ_K_BAD;
    return (int)FZ_SLOT_TAG(node);
}

static const char *
fz_abi_str(const fz_container *c, uint32_t node, STRLEN *len, int *utf8)
{
    uint32_t n = 0;
    const char *p;
    if (!c || !c->base) return NULL;
    p = fz_str_at(c->base, (uint32_t)c->len, node, &n, utf8);
    if (p && len) *len = (STRLEN)n;
    return p;
}

static int
fz_abi_iv(const fz_container *c, uint32_t node, IV *out)
{
    int64_t v = 0;
    if (!c || !c->base) return 0;
    if (!fz_i64_at(c->base, (uint32_t)c->len, node, &v)) return 0;
    if (out) *out = (IV)v;
    return 1;
}

static int
fz_abi_uv(const fz_container *c, uint32_t node, UV *out)
{
    uint64_t v = 0;
    if (!c || !c->base) return 0;
    if (!fz_u64_at(c->base, (uint32_t)c->len, node, &v)) return 0;
    if (out) *out = (UV)v;
    return 1;
}

static int
fz_abi_nv(const fz_container *c, uint32_t node, NV *out)
{
    double d = 0;
    if (!c || !c->base) return 0;
    if (!fz_f64_at(c->base, (uint32_t)c->len, node, &d)) return 0;
    if (out) *out = (NV)d;
    return 1;
}

typedef struct {
    fz_leaf_fn cb;
    void      *ud;
    UV         n;
} fz_abi_walk_st;

static void
fz_abi_walk_cb(void *ud, const char **segs, const uint32_t *lens,
               int depth, uint32_t slot)
{
    fz_abi_walk_st *w = (fz_abi_walk_st *)ud;
    w->n++;
    w->cb(w->ud, segs, lens, depth, slot);
}

static int
fz_abi_walk(const fz_container *c, uint32_t node,
            fz_leaf_fn cb, void *ud, UV *count)
{
    const char *segs[FZ_MAX_DEPTH];
    uint32_t    lens[FZ_MAX_DEPTH];
    fz_abi_walk_st w;
    char *idxbuf;
    uint32_t budget;
    int ok;

    if (count) *count = 0;
    if (!c || !c->base || !cb) return 0;
    idxbuf = (char *)malloc((size_t)FZ_MAX_DEPTH * 12);
    if (!idxbuf) return 0;

    w.cb = cb; w.ud = ud; w.n = 0;
    budget = (uint32_t)(c->len / 4) + 16;
    ok = fz_walk_rec(c->base, (uint32_t)c->len, node, segs, lens, idxbuf,
                     0, fz_abi_walk_cb, &w, &budget);
    free(idxbuf);
    if (count) *count = w.n;
    return ok;
}

static SV *
fz_abi_sv_from_node(pTHX_ fz_container *c, uint32_t node)
{
    if (!c || !c->base) return newSV(0);
    return fz_slot_to_sv(aTHX_ c, node);
}

static const fz_abi FZ_ABI = {
    FZ_ABI_VERSION,

    fz_abi_open,
    fz_abi_attach,
    fz_abi_close,
    fz_open_error,

    fz_abi_root,
    fz_abi_probe,
    fz_abi_child,
    fz_abi_path,
    fz_abi_at,
    fz_abi_key_at,
    fz_abi_count,
    fz_abi_kind,

    fz_abi_str,
    fz_abi_iv,
    fz_abi_uv,
    fz_abi_nv,

    fz_abi_walk,
    fz_abi_sv_from_node
};

#define FZ_STEP(n) do { *step = (n); } while (0)

static SV *
fz_abi_build_data(pTHX)
{
    HV *top    = newHV();
    HV *plural = newHV();
    HV *flags  = newHV();
    AV *nums   = newAV();

    (void)hv_stores(plural, "one",   newSVpvs("1 item"));
    (void)hv_stores(plural, "other", newSVpvs("n items"));

    av_push(nums, newSViv(-5));
    av_push(nums, newSVuv(UV_MAX));
    av_push(nums, newSVnv(1.5));

    {
        SV *t = newSViv(1), *f = newSViv(0);
        SvREADONLY_on(t);
        SvREADONLY_on(f);
        (void)hv_stores(flags, "on",  newRV_noinc(t));
        (void)hv_stores(flags, "off", newRV_noinc(f));
    }
    (void)hv_stores(flags, "none", newSV(0));

    (void)hv_stores(top, "greeting", newSVpvs("hello"));
    (void)hv_stores(top, "plural",   newRV_noinc((SV *)plural));
    (void)hv_stores(top, "nums",     newRV_noinc((SV *)nums));
    (void)hv_stores(top, "flags",    newRV_noinc((SV *)flags));
    (void)hv_stores(top, "a.b",      newSVpvs("dotted"));

    return newRV_noinc((SV *)top);
}

typedef struct {
    int  leaves;
    int  saw_dotted;
    int  saw_index;
    int  bad_depth;
} fz_abi_seen;

static void
fz_abi_selftest_leaf(void *ud, const char **segs, const uint32_t *lens,
                     int depth, uint32_t node)
{
    fz_abi_seen *s = (fz_abi_seen *)ud;
    PERL_UNUSED_ARG(node);
    s->leaves++;
    if (depth < 1 || depth > 2) s->bad_depth = 1;
    if (depth == 1 && lens[0] == 3 && memcmp(segs[0], "a.b", 3) == 0)
        s->saw_dotted = 1;
    if (depth == 2 && lens[0] == 4 && memcmp(segs[0], "nums", 4) == 0
        && lens[1] == 1 && segs[1][0] == '2')
        s->saw_index = 1;
}

static SV *
fz_abi_selftest(pTHX_ int *step, SV **data)
{
    const fz_abi *A = &FZ_ABI;
    fz_container *c = NULL;
    SV *sv = NULL, *block = NULL;
    uint32_t root, n, h, h2;
    const char *p;
    STRLEN len;
    int utf8, err = 0;
    IV iv;
    UV uv;
    NV nv;
    fz_abi_seen seen;

    *step = 0;
    sv = fz_abi_build_data(aTHX);
    *data = sv;
    block = SvREFCNT_inc(fz_freeze_sv(aTHX_ sv, 0, "."));

    if (A->abi_version < FZ_ABI_VERSION) { FZ_STEP(1); goto done; }

    {
        STRLEN blen;
        const char *b = SvPV(block, blen);
        c = A->attach(b, blen, &err);
        if (!c || err != FZ_ERR_OK) { FZ_STEP(2); goto done; }
    }

    {
        char zeros[FZ_HEADER_SIZE];
        int e2 = FZ_ERR_OK;
        fz_container *bad = A->attach("not a block", 11, &e2);
        if (bad) { A->close(aTHX_ bad); FZ_STEP(3); goto done; }
        if (e2 != FZ_ERR_SHORT || !A->error(e2)) { FZ_STEP(3); goto done; }
        memset(zeros, 0, sizeof zeros);
        e2 = FZ_ERR_OK;
        bad = A->attach(zeros, sizeof zeros, &e2);
        if (bad) { A->close(aTHX_ bad); FZ_STEP(3); goto done; }
        if (e2 != FZ_ERR_MAGIC || !A->error(e2)) { FZ_STEP(3); goto done; }
    }

    root = A->root(c);
    if (root == FZ_NOHANDLE) { FZ_STEP(4); goto done; }
    if (A->kind(c, root) != FZ_K_HASH) { FZ_STEP(4); goto done; }
    if (A->count(c, root) != 5) { FZ_STEP(4); goto done; }

    if (A->probe(c, root, "greeting", 8, &h) != FZ_LEAF)  { FZ_STEP(5); goto done; }
    if (A->probe(c, root, "plural", 6, &h2) != FZ_BRANCH) { FZ_STEP(5); goto done; }
    if (A->probe(c, root, "nope", 4, NULL) != FZ_ABSENT)  { FZ_STEP(5); goto done; }

    if (A->child(c, root, "greeting", 8) != h)         { FZ_STEP(6); goto done; }
    if (A->child(c, root, "nope", 4) != FZ_NOHANDLE)   { FZ_STEP(6); goto done; }

    utf8 = 1;
    p = A->str(c, h, &len, &utf8);
    if (!p || len != 5 || memcmp(p, "hello", 5) || p[5] != '\0' || utf8 != 0)
        { FZ_STEP(7); goto done; }

    if (p < (const char *)c->base || p >= (const char *)c->base + c->len)
        { FZ_STEP(7); goto done; }
    if (A->str(c, root, NULL, NULL)) { FZ_STEP(7); goto done; }

    h = A->child(c, root, "nums", 4);
    if (A->kind(c, h) != FZ_K_ARRAY || A->count(c, h) != 3) { FZ_STEP(8); goto done; }
    if (A->at(c, h, 0, &h2) != FZ_LEAF) { FZ_STEP(8); goto done; }
    if (!A->iv(c, h2, &iv) || iv != -5) { FZ_STEP(8); goto done; }
    if (A->iv(c, root, &iv)) { FZ_STEP(8); goto done; }
    if (A->at(c, h, 1, &h2) != FZ_LEAF) { FZ_STEP(8); goto done; }
    if (A->kind(c, h2) != FZ_K_UINT) { FZ_STEP(8); goto done; }
    if (!A->uv(c, h2, &uv) || uv != UV_MAX) { FZ_STEP(8); goto done; }

    if (A->iv(c, h2, &iv)) { FZ_STEP(8); goto done; }
    if (A->at(c, h, 2, &h2) != FZ_LEAF) { FZ_STEP(8); goto done; }
    if (!A->nv(c, h2, &nv) || nv != (NV)1.5) { FZ_STEP(8); goto done; }
    if (A->at(c, h, 3, NULL) != FZ_ABSENT) { FZ_STEP(8); goto done; }

    h = A->child(c, root, "flags", 5);
    if (A->kind(c, A->child(c, h, "on",   2)) != FZ_K_TRUE)  { FZ_STEP(9); goto done; }
    if (A->kind(c, A->child(c, h, "off",  3)) != FZ_K_FALSE) { FZ_STEP(9); goto done; }
    if (A->kind(c, A->child(c, h, "none", 4)) != FZ_K_UNDEF) { FZ_STEP(9); goto done; }

    n = A->count(c, h);
    if (n != 3) { FZ_STEP(10); goto done; }
    {
        uint32_t i;
        int found = 0;
        for (i = 0; i < n; i++) {
            utf8 = 1;
            if (!A->key_at(c, h, i, &p, &len, &utf8)) { FZ_STEP(10); goto done; }
            if (utf8 != 0) { FZ_STEP(10); goto done; }
            if (len == 4 && memcmp(p, "none", 4) == 0) found = 1;
        }
        if (!found) { FZ_STEP(10); goto done; }
        if (A->key_at(c, h, n, &p, &len, NULL)) { FZ_STEP(10); goto done; }
    }

    h = A->path(c, root, "plural.other", 12, '.');
    if (h == FZ_NOHANDLE) { FZ_STEP(11); goto done; }
    p = A->str(c, h, &len, NULL);
    if (!p || len != 7 || memcmp(p, "n items", 7)) { FZ_STEP(11); goto done; }
    h2 = A->child(c, root, "plural", 6);
    if (A->path(c, h2, "other", 5, '.') != h) { FZ_STEP(11); goto done; }
    if (A->path(c, root, "plural.nope", 11, '.') != FZ_NOHANDLE)
        { FZ_STEP(11); goto done; }

    h = A->child(c, root, "a.b", 3);
    if (h == FZ_NOHANDLE) { FZ_STEP(11); goto done; }
    p = A->str(c, h, &len, NULL);
    if (!p || len != 6 || memcmp(p, "dotted", 6)) { FZ_STEP(11); goto done; }
    if (A->path(c, root, "a.b", 3, ';') != h) { FZ_STEP(11); goto done; }
    if (A->path(c, root, "a.b", 3, '.') != h) { FZ_STEP(11); goto done; }

    {
        uint32_t reserved = (uint32_t)(FZ_T_MAX + 1) | 0xFFFFFFF0u;
        uint32_t outside  = FZ_SLOT(FZ_T_STR, ((uint32_t)c->len + 4096) & ~7u);
        int k;
        for (k = 0; k < 2; k++) {
            uint32_t bogus = k ? outside : reserved;
            if (A->kind(c, bogus) != FZ_K_BAD)  { FZ_STEP(12); goto done; }
            if (A->count(c, bogus) != 0)        { FZ_STEP(12); goto done; }
            if (A->str(c, bogus, NULL, NULL))   { FZ_STEP(12); goto done; }
            if (A->iv(c, bogus, NULL))          { FZ_STEP(12); goto done; }
            if (A->child(c, bogus, "greeting", 8) != FZ_NOHANDLE)
                { FZ_STEP(12); goto done; }
            if (A->probe(c, bogus, "greeting", 8, NULL) != FZ_ABSENT)
                { FZ_STEP(12); goto done; }
            if (A->path(c, bogus, "greeting", 8, '.') != FZ_NOHANDLE)
                { FZ_STEP(12); goto done; }
            if (A->at(c, bogus, 0, NULL) != FZ_ABSENT) { FZ_STEP(12); goto done; }
            if (A->key_at(c, bogus, 0, &p, &len, NULL)) { FZ_STEP(12); goto done; }
            if (A->walk(c, bogus, fz_abi_selftest_leaf, &seen, NULL))
                { FZ_STEP(12); goto done; }
        }
    }

    {
        UV count = 0;
        seen.leaves = seen.saw_dotted = seen.saw_index = seen.bad_depth = 0;
        if (!A->walk(c, root, fz_abi_selftest_leaf, &seen, &count))
            { FZ_STEP(13); goto done; }

        if (count != 10 || seen.leaves != 10) { FZ_STEP(13); goto done; }
        if (!seen.saw_dotted || !seen.saw_index || seen.bad_depth)
            { FZ_STEP(13); goto done; }
    }

    {
        SV *one = A->sv_from_node(aTHX_ c, A->child(c, root, "greeting", 8));
        SV *all;
        if (!one || !SvPOK(one) || SvCUR(one) != 5
            || memcmp(SvPVX(one), "hello", 5)) {
            if (one) SvREFCNT_dec(one);
            FZ_STEP(14); goto done;
        }
        SvREFCNT_dec(one);
        all = A->sv_from_node(aTHX_ c, root);
        if (!all || !SvROK(all) || SvTYPE(SvRV(all)) != SVt_PVHV
            || HvUSEDKEYS((HV *)SvRV(all)) != 5) {
            if (all) SvREFCNT_dec(all);
            FZ_STEP(14); goto done;
        }
        SvREFCNT_dec(all);
    }

done:
    if (c) A->close(aTHX_ c);
    return block;
}

#undef FZ_STEP

#endif
