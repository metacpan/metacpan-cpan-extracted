#ifndef HAMT_ABI_IMPL_H
#define HAMT_ABI_IMPL_H

/* What stands behind hamt_abi.h. Each function here is one entry of the
 * table; the table itself is at the end, and after it the selftest that
 * walks every entry.
 *
 * Nothing here croaks for want of memory, which is why none of it goes
 * through the XS layer's own helpers: those croak, and a C caller holding
 * resources of its own cannot be unwound past. */

/* ---- keys ---------------------------------------------------------------
 *
 * The hash-key rule, applied to bytes and a flag. A flagged key that holds
 * only characters below 256 is rewritten as its unflagged bytes, in a
 * buffer this owns and the caller frees with hamt_abi_key_done. */

typedef struct hamt_abi_key {
    hamt_key k;
    U8      *owned;
} hamt_abi_key;

static void hamt_abi_key_init(pTHX_ hamt_abi_key *ak, const char *key, STRLEN klen, int utf8) {
    ak->owned = NULL;
    if (utf8) {
        const U8 *s = (const U8 *)key, *e = s + klen;
        while (s < e && !(*s & 0x80)) s++;
        if (s == e) utf8 = 0;                       /* plain ASCII: the flag means nothing */
        else {
            bool still = TRUE;
            STRLEN len = klen;
            U8 *d = bytes_from_utf8((const U8 *)key, &len, &still);
            if (!still) {                           /* it fitted in bytes */
                ak->owned = d;
                key  = (const char *)d;
                klen = len;
                utf8 = 0;
            }
        }
    }
    ak->k.p    = key;
    ak->k.len  = klen;
    ak->k.utf8 = utf8 ? 1 : 0;
    ak->k.hash = hamt_hash(key, (size_t)klen, ak->k.utf8);
}

static void hamt_abi_key_done(pTHX_ hamt_abi_key *ak) {
    if (ak->owned) Safefree(ak->owned);
    ak->owned = NULL;
}

/* ---- the struct, for maps and sets -------------------------------------- */

static hamt_map *hamt_abi_map_new(pTHX) {
    hamt_map *m = (hamt_map *)HAMT_ALLOC(HAMT_CX, sizeof(hamt_map));
    PERL_UNUSED_CONTEXT;
    if (!m) return NULL;
    m->root  = NULL;
    m->count = 0;
    return m;
}

static hamt_map *hamt_abi_map_copy(pTHX_ const hamt_map *src) {
    hamt_map *m = hamt_abi_map_new(aTHX);
    if (!m) return NULL;
    m->root  = src->root ? hamt_node_retain(src->root) : NULL;
    m->count = src->count;
    return m;
}

static void hamt_abi_map_release(pTHX_ hamt_map *m) {
    hamt_node *root;
    if (!m) return;
    root = m->root;
    HAMT_FREE(HAMT_CX, m, sizeof(hamt_map));
    if (root) hamt_node_release(HAMT_CX, root);
}

/* A struct built from a root the caller owns one reference to, which it
 * takes over; or NULL, with the root released. */
static hamt_map *hamt_abi_map_wrap(pTHX_ hamt_node *root, size_t count) {
    hamt_map *m = hamt_abi_map_new(aTHX);
    if (!m) { if (root) hamt_node_release(HAMT_CX, root); return NULL; }
    m->root  = root;
    m->count = count;
    return m;
}

/* A new object around a struct that becomes the object's own. */
static SV *hamt_abi_bless(pTHX_ const MGVTBL *vt, const char *klass, const char *deflt,
                          void *payload) {
    SV *inner = newSV(0), *rv;
    MAGIC *mg = sv_magicext(inner, NULL, PERL_MAGIC_ext, (MGVTBL *)vt, (const char *)payload, 0);
    mg->mg_flags |= MGf_DUP;
    rv = newRV_noinc(inner);
    sv_bless(rv, gv_stashpv(klass ? klass : deflt, GV_ADD));
    return rv;
}

static const hamt_map *hamt_abi_map_from_sv(pTHX_ SV *obj) {
    return obj ? hamt_handle_try(aTHX_ obj, &hamt_map_vtbl) : NULL;
}
static const hamt_map *hamt_abi_set_from_sv(pTHX_ SV *obj) {
    return obj ? hamt_handle_try(aTHX_ obj, &hamt_set_vtbl) : NULL;
}

/* The struct inside an open transient of the kind `vt` marks, or NULL. */
static hamt_txn *hamt_abi_txn(pTHX_ SV *obj, const MGVTBL *vt) {
    if (obj && SvROK(obj) && SvTYPE(SvRV(obj)) >= SVt_PVMG) {
        MAGIC *mg;
        for (mg = SvMAGIC(SvRV(obj)); mg; mg = mg->mg_moremagic) {
            hamt_txn *t;
            if (mg->mg_type != PERL_MAGIC_ext || mg->mg_virtual != vt) continue;
            t = (hamt_txn *)mg->mg_ptr;
            return (t && t->open) ? t : NULL;
        }
    }
    return NULL;
}
static hamt_map *hamt_abi_map_txn_from_sv(pTHX_ SV *obj) {
    hamt_txn *t = hamt_abi_txn(aTHX_ obj, &hamt_map_txn_vtbl);
    return t ? &t->m : NULL;
}
static hamt_map *hamt_abi_set_txn_from_sv(pTHX_ SV *obj) {
    hamt_txn *t = hamt_abi_txn(aTHX_ obj, &hamt_set_txn_vtbl);
    return t ? &t->m : NULL;
}

static SV *hamt_abi_map_to_sv(pTHX_ hamt_map *m, const char *klass) {
    return hamt_abi_bless(aTHX_ &hamt_map_vtbl, klass, "HAMT::Map", m);
}
static SV *hamt_abi_set_to_sv(pTHX_ hamt_map *m, const char *klass) {
    return hamt_abi_bless(aTHX_ &hamt_set_vtbl, klass, "HAMT::Set", m);
}

/* A transient is a larger struct, so this one allocates: NULL when there is
 * no memory, and then the struct given is still the caller's. */
static SV *hamt_abi_txn_to_sv(pTHX_ hamt_map *m, const MGVTBL *vt, const char *txn_class,
                              const char *klass, const char *deflt) {
    hamt_txn *t = (hamt_txn *)HAMT_ALLOC(HAMT_CX, sizeof(hamt_txn));
    if (!t) return NULL;
    t->m      = *m;                              /* the references move */
    t->origin = (HV *)SvREFCNT_inc_simple_NN((SV *)gv_stashpv(klass ? klass : deflt, GV_ADD));
    t->open   = 1;
    HAMT_FREE(HAMT_CX, m, sizeof(hamt_map));
    return hamt_abi_bless(aTHX_ vt, txn_class, txn_class, t);
}
static SV *hamt_abi_map_to_txn_sv(pTHX_ hamt_map *m, const char *klass) {
    return hamt_abi_txn_to_sv(aTHX_ m, &hamt_map_txn_vtbl, "HAMT::Map::Transient", klass, "HAMT::Map");
}
static SV *hamt_abi_set_to_txn_sv(pTHX_ hamt_map *m, const char *klass) {
    return hamt_abi_txn_to_sv(aTHX_ m, &hamt_set_txn_vtbl, "HAMT::Set::Transient", klass, "HAMT::Set");
}

/* ---- reading ------------------------------------------------------------ */

static size_t hamt_abi_map_count(pTHX_ const hamt_map *m) {
    PERL_UNUSED_CONTEXT;
    return m->count;
}

static hamt_entry *hamt_abi_find(pTHX_ const hamt_map *m, const char *key, STRLEN klen, int utf8) {
    hamt_abi_key ak;
    hamt_entry *e;
    hamt_abi_key_init(aTHX_ &ak, key, klen, utf8);
    e = hamt_map_find(m->root, ak.k.p, (size_t)ak.k.len, ak.k.utf8, ak.k.hash);
    hamt_abi_key_done(aTHX_ &ak);
    return e;
}

static SV *hamt_abi_map_fetch(pTHX_ const hamt_map *m, const char *key, STRLEN klen, int utf8) {
    hamt_entry *e = hamt_abi_find(aTHX_ m, key, klen, utf8);
    return e ? (SV *)e->val : NULL;
}

static int hamt_abi_map_has(pTHX_ const hamt_map *m, const char *key, STRLEN klen, int utf8) {
    return hamt_abi_find(aTHX_ m, key, klen, utf8) != NULL;
}

/* ---- updating in place -------------------------------------------------- */

/* One entry into the struct given: a copy of `value`, or no value at all
 * for a set. The displaced entry is released last, with the struct already
 * holding its new root. */
static int hamt_abi_put(pTHX_ hamt_map *m, const hamt_key *k, SV *value) {
    hamt_entry *e, *dead;
    SV *copy = value ? hamt_sv_copy_in(aTHX_ value) : NULL;
    int added, rc;

    e = hamt_entry_new(HAMT_CX, k->p, (size_t)k->len, k->utf8, k->hash, (void *)copy);
    if (copy) SvREFCNT_dec(copy);
    if (!e) return HAMT_ABI_NOMEM;

    rc = hamt_map_put_mut(HAMT_CX, &m->root, e, &added, &dead);
    hamt_entry_release(HAMT_CX, e);
    if (rc) return HAMT_ABI_NOMEM;
    m->count += (size_t)added;
    if (dead) hamt_entry_release(HAMT_CX, dead);
    return HAMT_ABI_OK;
}

static int hamt_abi_store(pTHX_ hamt_map *m, const char *key, STRLEN klen, int utf8, SV *value) {
    hamt_abi_key ak;
    hamt_entry *old;
    int rc = HAMT_ABI_OK;

    hamt_abi_key_init(aTHX_ &ak, key, klen, utf8);
    /* The very scalar already stored: nothing to do, and nothing is copied
     * to find that out. Only a read-only scalar can be one, so only then is
     * the trie walked to see. */
    old = (value && SvREADONLY(value))
        ? hamt_map_find(m->root, ak.k.p, (size_t)ak.k.len, ak.k.utf8, ak.k.hash) : NULL;
    if (!old || old->val != (void *)value) rc = hamt_abi_put(aTHX_ m, &ak.k, value);
    hamt_abi_key_done(aTHX_ &ak);
    return rc;
}

static int hamt_abi_map_store(pTHX_ hamt_map *m, const char *key, STRLEN klen, int utf8, SV *value) {
    return hamt_abi_store(aTHX_ m, key, klen, utf8, value ? value : &PL_sv_undef);
}
static int hamt_abi_set_add(pTHX_ hamt_map *m, const char *key, STRLEN klen, int utf8) {
    return hamt_abi_store(aTHX_ m, key, klen, utf8, NULL);
}

static int hamt_abi_map_remove(pTHX_ hamt_map *m, const char *key, STRLEN klen, int utf8) {
    hamt_abi_key ak;
    hamt_entry *dead;
    int status;

    hamt_abi_key_init(aTHX_ &ak, key, klen, utf8);
    status = hamt_map_del_mut(HAMT_CX, &m->root, ak.k.p, (size_t)ak.k.len, ak.k.utf8, ak.k.hash, &dead);
    hamt_abi_key_done(aTHX_ &ak);
    if (status == HAMT_DEL_OOM) return HAMT_ABI_NOMEM;
    if (status == HAMT_DEL_DONE) m->count--;
    if (dead) hamt_entry_release(HAMT_CX, dead);
    return HAMT_ABI_OK;
}

static int hamt_abi_map_update(pTHX_ hamt_map *m, const char *key, STRLEN klen, int utf8,
                               hamt_abi_update_fn fn, void *ud) {
    hamt_abi_key ak;
    hamt_entry *old;
    SV *now;
    int rc = HAMT_ABI_OK;

    hamt_abi_key_init(aTHX_ &ak, key, klen, utf8);
    old = hamt_map_find(m->root, ak.k.p, (size_t)ak.k.len, ak.k.utf8, ak.k.hash);
    now = fn(aTHX_ ud, old ? (SV *)old->val : NULL);
    if (!now) rc = HAMT_ABI_STOPPED;
    else {
        /* The callback may have changed the struct; look again. */
        old = hamt_map_find(m->root, ak.k.p, (size_t)ak.k.len, ak.k.utf8, ak.k.hash);
        if (!old || !old->val || !hamt_sv_eq_cx(HAMT_CX, now, (SV *)old->val))
            rc = hamt_abi_put(aTHX_ m, &ak.k, now);
    }
    hamt_abi_key_done(aTHX_ &ak);
    return rc;
}

/* ---- walking ------------------------------------------------------------
 *
 * A walk holds its own reference to the root for as long as it runs, let go
 * by the save stack: the callback may do anything to the struct, release it
 * included, or croak. */

static int hamt_abi_map_walk(pTHX_ const hamt_map *m, hamt_abi_pair_fn fn, void *ud) {
    hamt_node *root = m->root;
    hamt_iter it;
    hamt_entry *e;
    int rc = HAMT_ABI_OK;

    ENTER;
    hamt_xs_hold_root(aTHX_ root);
    hamt_iter_init(&it, root);
    while ((e = hamt_iter_next(&it))) {
        if (fn(aTHX_ ud, e->key, (STRLEN)e->klen, e->utf8, (SV *)e->val)) { rc = HAMT_ABI_STOPPED; break; }
    }
    LEAVE;
    return rc;
}

/* ---- to and from a Perl hash -------------------------------------------- */

static hamt_map *hamt_abi_map_from_hv(pTHX_ HV *hv) {
    hamt_map *m = hamt_abi_map_new(aTHX);
    HE *he;

    if (!m) return NULL;
    hv_iterinit(hv);
    while ((he = hv_iternext(hv))) {
        hamt_key k;
        SV *v = hv_iterval(hv, he);
        hamt_key_from_he(aTHX_ hv, he, &k);
        if (hamt_abi_put(aTHX_ m, &k, v ? v : &PL_sv_undef)) {
            hamt_abi_map_release(aTHX_ m);
            return NULL;
        }
    }
    return m;
}

static HV *hamt_abi_map_to_hv(pTHX_ const hamt_map *m) {
    HV *hv = newHV();
    hamt_iter it;
    hamt_entry *e;

    hamt_iter_init(&it, m->root);
    while ((e = hamt_iter_next(&it))) {
        SV *v;
        if (e->klen > (size_t)I32_MAX) { SvREFCNT_dec((SV *)hv); return NULL; }
        v = e->val ? newSVsv((SV *)e->val) : newSV(0);
        if (!hv_store(hv, e->key, e->utf8 ? -(I32)e->klen : (I32)e->klen, v, 0))
            SvREFCNT_dec(v);
    }
    return hv;
}

/* ---- two maps at once ---------------------------------------------------- */

typedef struct hamt_abi_merge_ud {
    hamt_abi_merge_fn fn;
    void             *ud;
} hamt_abi_merge_ud;

static int hamt_abi_resolve(void *ud, void *cx, hamt_entry *ea, hamt_entry *eb, hamt_entry **out) {
    dTHXa(cx);
    hamt_abi_merge_ud *u = (hamt_abi_merge_ud *)ud;
    SV *res = u->fn(aTHX_ u->ud, ea->key, (STRLEN)ea->klen, ea->utf8, (SV *)ea->val, (SV *)eb->val);
    SV *copy;

    if (!res) return HAMT_ERR_ABORT;
    if (ea->val && hamt_sv_eq_cx(cx, res, (SV *)ea->val)) { *out = hamt_entry_retain(ea); return HAMT_OK; }
    if (eb->val && hamt_sv_eq_cx(cx, res, (SV *)eb->val)) { *out = hamt_entry_retain(eb); return HAMT_OK; }
    copy = hamt_sv_copy_in(aTHX_ res);
    *out = hamt_entry_new(cx, ea->key, ea->klen, ea->utf8, ea->hash, (void *)copy);
    SvREFCNT_dec(copy);
    return *out ? HAMT_OK : HAMT_ERR_OOM;
}

static hamt_map *hamt_abi_map_merge(pTHX_ const hamt_map *a, const hamt_map *b,
                                    hamt_abi_merge_fn fn, void *ud, int *status) {
    hamt_merge_ctx c;
    hamt_abi_merge_ud u;
    hamt_node *r;
    hamt_map *m;

    u.fn = fn;
    u.ud = ud;
    c.cx = HAMT_CX;
    c.resolve = fn ? hamt_abi_resolve : NULL;
    c.ud = &u;
    r = hamt_map_merge(&c, a->root, b->root);
    if (c.err) {
        if (status) *status = c.err == HAMT_ERR_ABORT ? HAMT_ABI_STOPPED : HAMT_ABI_NOMEM;
        return NULL;
    }
    m = hamt_abi_map_wrap(aTHX_ r, a->count + c.added);
    if (status) *status = m ? HAMT_ABI_OK : HAMT_ABI_NOMEM;
    return m;
}

typedef struct hamt_abi_eq_ud {
    hamt_abi_equal_fn fn;
    void             *ud;
} hamt_abi_eq_ud;

static int hamt_abi_eq(void *ud, void *cx, void *va, void *vb) {
    dTHXa(cx);
    hamt_abi_eq_ud *u = (hamt_abi_eq_ud *)ud;
    return u->fn(aTHX_ u->ud, (SV *)va, (SV *)vb);
}

static int hamt_abi_map_equal(pTHX_ const hamt_map *a, const hamt_map *b,
                              hamt_abi_equal_fn fn, void *ud) {
    hamt_eq_ctx c;
    hamt_abi_eq_ud u;
    hamt_node *ra = a->root, *rb = b->root;
    int rc;

    if (a->count != b->count) return 0;
    u.fn = fn;
    u.ud = ud;
    c.cx = HAMT_CX;
    c.eq = fn ? hamt_abi_eq : NULL;
    c.ud = &u;
    c.visits = 0;
    ENTER;
    hamt_xs_hold_root(aTHX_ ra);
    hamt_xs_hold_root(aTHX_ rb);
    rc = hamt_node_equal(&c, ra, rb);
    LEAVE;
    return rc < 0 ? HAMT_ABI_STOPPED : rc;
}
static int hamt_abi_set_equal(pTHX_ const hamt_map *a, const hamt_map *b) {
    return hamt_abi_map_equal(aTHX_ a, b, NULL, NULL);
}

typedef struct hamt_abi_diff_ud {
    hamt_abi_diff_fn fn;
    void            *ud;
} hamt_abi_diff_ud;

static int hamt_abi_diff(void *ud, void *cx, int kind, hamt_entry *ea, hamt_entry *eb) {
    dTHXa(cx);
    hamt_abi_diff_ud *u = (hamt_abi_diff_ud *)ud;
    const hamt_entry *k = ea ? ea : eb;
    return u->fn(aTHX_ u->ud, kind, k->key, (STRLEN)k->klen, k->utf8,
                 ea ? (SV *)ea->val : NULL, eb ? (SV *)eb->val : NULL);
}

static int hamt_abi_map_diff(pTHX_ const hamt_map *a, const hamt_map *b,
                             hamt_abi_diff_fn fn, void *ud, size_t *count) {
    hamt_diff_ctx c;
    hamt_abi_diff_ud u;
    hamt_node *ra = a->root, *rb = b->root;
    int rc;

    u.fn = fn;
    u.ud = ud;
    c.cx = HAMT_CX;
    c.fn = fn ? hamt_abi_diff : NULL;
    c.ud = &u;
    c.eq.cx = HAMT_CX;
    c.eq.eq = NULL;
    c.eq.ud = NULL;
    ENTER;
    hamt_xs_hold_root(aTHX_ ra);
    hamt_xs_hold_root(aTHX_ rb);
    rc = hamt_map_diff(&c, ra, rb);
    LEAVE;
    if (count) *count = c.reported;
    return rc ? HAMT_ABI_STOPPED : HAMT_ABI_OK;
}

static hamt_map *hamt_abi_map_key_set(pTHX_ const hamt_map *m) {
    hamt_map *s = hamt_abi_map_new(aTHX);
    hamt_iter it;
    hamt_entry *e;

    if (!s) return NULL;
    hamt_iter_init(&it, m->root);
    while ((e = hamt_iter_next(&it))) {
        hamt_key k;
        k.p = e->key; k.len = (STRLEN)e->klen; k.utf8 = e->utf8; k.hash = e->hash;
        if (hamt_abi_put(aTHX_ s, &k, NULL)) { hamt_abi_map_release(aTHX_ s); return NULL; }
    }
    return s;
}

static int hamt_abi_map_check(pTHX_ const hamt_map *m) {
    PERL_UNUSED_CONTEXT;
    return hamt_map_check(m->root, m->count);
}

/* ---- set algebra --------------------------------------------------------- */

static hamt_map *hamt_abi_set_union(pTHX_ const hamt_map *a, const hamt_map *b) {
    return hamt_abi_map_merge(aTHX_ a, b, NULL, NULL, NULL);
}

static hamt_map *hamt_abi_set_filter(pTHX_ const hamt_map *a, const hamt_map *b, int common) {
    hamt_set_ctx c;
    size_t count = 0;
    hamt_node *r;

    c.cx = HAMT_CX;
    r = common ? hamt_set_intersect(&c, a->root, b->root, a->count, b->count, &count)
               : hamt_set_subtract(&c, a->root, b->root, a->count, b->count, &count);
    if (c.err) return NULL;
    return hamt_abi_map_wrap(aTHX_ r, count);
}
static hamt_map *hamt_abi_set_intersect(pTHX_ const hamt_map *a, const hamt_map *b) {
    return hamt_abi_set_filter(aTHX_ a, b, 1);
}
static hamt_map *hamt_abi_set_difference(pTHX_ const hamt_map *a, const hamt_map *b) {
    return hamt_abi_set_filter(aTHX_ a, b, 0);
}

static int hamt_abi_set_is_subset(pTHX_ const hamt_map *a, const hamt_map *b) {
    size_t visits;
    PERL_UNUSED_CONTEXT;
    return hamt_set_subset(a->root, b->root, a->count, b->count, &visits);
}
static int hamt_abi_set_is_disjoint(pTHX_ const hamt_map *a, const hamt_map *b) {
    size_t visits;
    PERL_UNUSED_CONTEXT;
    return hamt_set_disjoint(a->root, b->root, &visits);
}

/* ---- vectors ------------------------------------------------------------- */

static hamt_vec *hamt_abi_vec_new(pTHX) {
    hamt_vec *v = (hamt_vec *)HAMT_ALLOC(HAMT_CX, sizeof(hamt_vec));
    PERL_UNUSED_CONTEXT;
    if (!v) return NULL;
    hamt_vec_init(v);
    return v;
}

static hamt_vec *hamt_abi_vec_copy(pTHX_ const hamt_vec *src) {
    hamt_vec *v = hamt_abi_vec_new(aTHX);
    if (!v) return NULL;
    hamt_vec_share(v, src);
    return v;
}

static void hamt_abi_vec_release(pTHX_ hamt_vec *v) {
    hamt_vec gone;
    if (!v) return;
    gone = *v;
    HAMT_FREE(HAMT_CX, v, sizeof(hamt_vec));
    hamt_vec_clear(HAMT_CX, &gone);
}

static const hamt_vec *hamt_abi_vec_from_sv(pTHX_ SV *obj) {
    return obj ? hamt_vec_handle_try(aTHX_ obj) : NULL;
}

static hamt_vec *hamt_abi_vec_txn_from_sv(pTHX_ SV *obj) {
    if (obj && SvROK(obj) && SvTYPE(SvRV(obj)) >= SVt_PVMG) {
        MAGIC *mg;
        for (mg = SvMAGIC(SvRV(obj)); mg; mg = mg->mg_moremagic) {
            hamt_vtxn *t;
            if (mg->mg_type != PERL_MAGIC_ext || mg->mg_virtual != &hamt_vec_txn_vtbl) continue;
            t = (hamt_vtxn *)mg->mg_ptr;
            return (t && t->open) ? &t->v : NULL;
        }
    }
    return NULL;
}

static SV *hamt_abi_vec_to_sv(pTHX_ hamt_vec *v, const char *klass) {
    return hamt_abi_bless(aTHX_ &hamt_vec_vtbl, klass, "HAMT::Vector", v);
}

static SV *hamt_abi_vec_to_txn_sv(pTHX_ hamt_vec *v, const char *klass) {
    hamt_vtxn *t = (hamt_vtxn *)HAMT_ALLOC(HAMT_CX, sizeof(hamt_vtxn));
    if (!t) return NULL;
    t->v      = *v;
    t->origin = (HV *)SvREFCNT_inc_simple_NN((SV *)gv_stashpv(klass ? klass : "HAMT::Vector", GV_ADD));
    t->open   = 1;
    HAMT_FREE(HAMT_CX, v, sizeof(hamt_vec));
    return hamt_abi_bless(aTHX_ &hamt_vec_txn_vtbl, "HAMT::Vector::Transient",
                          "HAMT::Vector::Transient", t);
}

static size_t hamt_abi_vec_count(pTHX_ const hamt_vec *v) {
    PERL_UNUSED_CONTEXT;
    return v->count;
}

static SV *hamt_abi_vec_fetch(pTHX_ const hamt_vec *v, size_t index) {
    PERL_UNUSED_CONTEXT;
    return index < v->count ? (SV *)hamt_vec_get(v, index) : NULL;
}

static int hamt_abi_vec_push(pTHX_ hamt_vec *v, SV *value) {
    SV *copy = hamt_sv_copy_in(aTHX_ value ? value : &PL_sv_undef);
    int rc = hamt_vec_push(HAMT_CX, v, (void *)copy);
    SvREFCNT_dec(copy);
    return rc ? HAMT_ABI_NOMEM : HAMT_ABI_OK;
}

static int hamt_abi_vec_store(pTHX_ hamt_vec *v, size_t index, SV *value) {
    SV *copy;
    void *dead;
    int rc;

    if (index >= v->count) return HAMT_ABI_RANGE;
    if (!value) value = &PL_sv_undef;
    if (hamt_vec_get(v, index) == (void *)value) return HAMT_ABI_OK;
    copy = hamt_sv_copy_in(aTHX_ value);
    rc = hamt_vec_set(HAMT_CX, v, index, (void *)copy, &dead);
    SvREFCNT_dec(copy);
    if (rc) return HAMT_ABI_NOMEM;
    if (dead) HAMT_VAL_RELEASE(HAMT_CX, dead);
    return HAMT_ABI_OK;
}

static int hamt_abi_vec_pop(pTHX_ hamt_vec *v) {
    void *dead;
    if (hamt_vec_pop(HAMT_CX, v, &dead)) return HAMT_ABI_NOMEM;
    if (dead) HAMT_VAL_RELEASE(HAMT_CX, dead);
    return HAMT_ABI_OK;
}

static int hamt_abi_vec_walk(pTHX_ const hamt_vec *v, hamt_abi_item_fn fn, void *ud) {
    hamt_vec *held;
    hamt_vec_iter it;
    void *const *run;
    size_t start;
    uint32_t n, i;
    int rc = HAMT_ABI_OK;

    held = (hamt_vec *)HAMT_ALLOC(HAMT_CX, sizeof(hamt_vec));
    if (!held) return HAMT_ABI_NOMEM;
    ENTER;
    hamt_vec_share(held, v);
    SAVEDESTRUCTOR_X(hamt_xs_vec_unhold, held);
    hamt_vec_iter_init(&it, held);
    while (rc == HAMT_ABI_OK && (run = hamt_vec_iter_next(&it, &start, &n)))
        for (i = 0; i < n; i++)
            if (fn(aTHX_ ud, start + i, (SV *)run[i])) { rc = HAMT_ABI_STOPPED; break; }
    LEAVE;
    return rc;
}

static hamt_vec *hamt_abi_vec_from_av(pTHX_ AV *av) {
    hamt_vec *v = hamt_abi_vec_new(aTHX);
    SSize_t i, top = av_len(av);

    if (!v) return NULL;
    for (i = 0; i <= top; i++) {
        SV **svp = av_fetch(av, i, 0);
        if (hamt_abi_vec_push(aTHX_ v, svp ? *svp : &PL_sv_undef)) {
            hamt_abi_vec_release(aTHX_ v);
            return NULL;
        }
    }
    return v;
}

static AV *hamt_abi_vec_to_av(pTHX_ const hamt_vec *v) {
    AV *av = newAV();
    hamt_vec_iter it;
    void *const *run;
    size_t start;
    uint32_t n, i;

    if (v->count > (size_t)I32_MAX) { SvREFCNT_dec((SV *)av); return NULL; }
    if (v->count) av_extend(av, (I32)(v->count - 1));
    hamt_vec_iter_init(&it, v);
    while ((run = hamt_vec_iter_next(&it, &start, &n)))
        for (i = 0; i < n; i++) av_push(av, newSVsv((SV *)run[i]));
    return av;
}

/* A struct holding what `built` holds, which it takes over; or NULL, with
 * `built` cleared. */
static hamt_vec *hamt_abi_vec_wrap(pTHX_ hamt_vec *built) {
    hamt_vec *v = hamt_abi_vec_new(aTHX);
    if (!v) { hamt_vec_clear(HAMT_CX, built); return NULL; }
    *v = *built;
    return v;
}

static hamt_vec *hamt_abi_vec_concat(pTHX_ const hamt_vec *a, const hamt_vec *b) {
    hamt_vec res;
    if (hamt_vec_concat(HAMT_CX, &res, a, b)) return NULL;
    return hamt_abi_vec_wrap(aTHX_ &res);
}

static hamt_vec *hamt_abi_vec_slice(pTHX_ const hamt_vec *v, size_t from, size_t len, int *status) {
    hamt_vec res;
    hamt_vec *out;

    if (from > v->count || len > v->count - from) {
        if (status) *status = HAMT_ABI_RANGE;
        return NULL;
    }
    hamt_vec_init(&res);
    if (len && hamt_vec_slice(HAMT_CX, &res, v, from, len)) {
        if (status) *status = HAMT_ABI_NOMEM;
        return NULL;
    }
    out = hamt_abi_vec_wrap(aTHX_ &res);
    if (status) *status = out ? HAMT_ABI_OK : HAMT_ABI_NOMEM;
    return out;
}

/* `v` with `drop` values from `at` taken out and `mid` put in their place. */
static hamt_vec *hamt_abi_vec_splice(pTHX_ const hamt_vec *v, size_t at, size_t drop,
                                     const hamt_vec *mid, int *status) {
    hamt_vec left, right, joined, res;
    hamt_vec *out;
    size_t after;
    int rc = 0;

    if (at > v->count || drop > v->count - at) {
        if (status) *status = HAMT_ABI_RANGE;
        return NULL;
    }
    after = at + drop;
    hamt_vec_init(&left);
    hamt_vec_init(&right);
    hamt_vec_init(&joined);
    hamt_vec_init(&res);

    if (at > 0) rc = hamt_vec_slice(HAMT_CX, &left, v, 0, at);
    if (!rc && after < v->count) rc = hamt_vec_slice(HAMT_CX, &right, v, after, v->count - after);
    if (!rc) {
        if (mid) rc = hamt_vec_concat(HAMT_CX, &joined, &left, mid);
        else     hamt_vec_share(&joined, &left);
    }
    if (!rc) rc = hamt_vec_concat(HAMT_CX, &res, &joined, &right);
    hamt_vec_clear(HAMT_CX, &left);
    hamt_vec_clear(HAMT_CX, &right);
    hamt_vec_clear(HAMT_CX, &joined);
    if (rc) {
        if (status) *status = HAMT_ABI_NOMEM;
        return NULL;
    }
    out = hamt_abi_vec_wrap(aTHX_ &res);
    if (status) *status = out ? HAMT_ABI_OK : HAMT_ABI_NOMEM;
    return out;
}

static hamt_vec *hamt_abi_vec_insert(pTHX_ const hamt_vec *v, size_t at, const hamt_vec *mid, int *status) {
    return hamt_abi_vec_splice(aTHX_ v, at, 0, mid, status);
}
static hamt_vec *hamt_abi_vec_remove(pTHX_ const hamt_vec *v, size_t at, size_t len, int *status) {
    return hamt_abi_vec_splice(aTHX_ v, at, len, NULL, status);
}

static int hamt_abi_vec_equal(pTHX_ const hamt_vec *a, const hamt_vec *b,
                              hamt_abi_equal_fn fn, void *ud) {
    hamt_eq_ctx c;
    hamt_abi_eq_ud u;
    hamt_vec *ha, *hb;
    int rc;

    if (a->count != b->count) return 0;
    ha = (hamt_vec *)HAMT_ALLOC(HAMT_CX, sizeof(hamt_vec));
    hb = ha ? (hamt_vec *)HAMT_ALLOC(HAMT_CX, sizeof(hamt_vec)) : NULL;
    if (!hb) {
        if (ha) HAMT_FREE(HAMT_CX, ha, sizeof(hamt_vec));
        return HAMT_ABI_NOMEM;
    }
    u.fn = fn;
    u.ud = ud;
    c.cx = HAMT_CX;
    c.eq = fn ? hamt_abi_eq : NULL;
    c.ud = &u;
    c.visits = 0;
    ENTER;
    hamt_vec_share(ha, a);
    SAVEDESTRUCTOR_X(hamt_xs_vec_unhold, ha);
    hamt_vec_share(hb, b);
    SAVEDESTRUCTOR_X(hamt_xs_vec_unhold, hb);
    rc = hamt_vec_equal(&c, ha, hb);
    LEAVE;
    return rc < 0 ? HAMT_ABI_STOPPED : rc;
}

static int hamt_abi_vec_check(pTHX_ const hamt_vec *v) {
    PERL_UNUSED_CONTEXT;
    return hamt_vec_check(v);
}

static int hamt_abi_value_equal(pTHX_ SV *a, SV *b) {
    return hamt_sv_eq_cx(HAMT_CX, a, b);
}

/* ---- the table ----------------------------------------------------------
 *
 * In the order hamt_abi.h declares it. Appended to, never reordered. */

static const hamt_abi HAMT_ABI = {
    HAMT_ABI_VERSION,

    hamt_abi_value_equal,

    hamt_abi_map_new,
    hamt_abi_map_copy,
    hamt_abi_map_release,
    hamt_abi_map_from_sv,
    hamt_abi_map_txn_from_sv,
    hamt_abi_map_to_sv,
    hamt_abi_map_to_txn_sv,
    hamt_abi_map_from_hv,
    hamt_abi_map_to_hv,
    hamt_abi_map_count,
    hamt_abi_map_fetch,
    hamt_abi_map_has,
    hamt_abi_map_store,
    hamt_abi_map_remove,
    hamt_abi_map_update,
    hamt_abi_map_walk,
    hamt_abi_map_merge,
    hamt_abi_map_equal,
    hamt_abi_map_diff,
    hamt_abi_map_key_set,
    hamt_abi_map_check,

    hamt_abi_map_new,           /* set_new      */
    hamt_abi_map_copy,          /* set_copy     */
    hamt_abi_map_release,       /* set_release  */
    hamt_abi_map_count,         /* set_count    */
    hamt_abi_map_has,           /* set_has      */
    hamt_abi_map_remove,        /* set_remove   */
    hamt_abi_map_walk,          /* set_walk     */
    hamt_abi_map_check,         /* set_check    */
    hamt_abi_set_from_sv,
    hamt_abi_set_txn_from_sv,
    hamt_abi_set_to_sv,
    hamt_abi_set_to_txn_sv,
    hamt_abi_set_add,
    hamt_abi_set_union,
    hamt_abi_set_intersect,
    hamt_abi_set_difference,
    hamt_abi_set_is_subset,
    hamt_abi_set_is_disjoint,
    hamt_abi_set_equal,

    hamt_abi_vec_new,
    hamt_abi_vec_copy,
    hamt_abi_vec_release,
    hamt_abi_vec_from_sv,
    hamt_abi_vec_txn_from_sv,
    hamt_abi_vec_to_sv,
    hamt_abi_vec_to_txn_sv,
    hamt_abi_vec_from_av,
    hamt_abi_vec_to_av,
    hamt_abi_vec_count,
    hamt_abi_vec_fetch,
    hamt_abi_vec_push,
    hamt_abi_vec_store,
    hamt_abi_vec_pop,
    hamt_abi_vec_walk,
    hamt_abi_vec_concat,
    hamt_abi_vec_slice,
    hamt_abi_vec_insert,
    hamt_abi_vec_remove,
    hamt_abi_vec_equal,
    hamt_abi_vec_check
};

#endif
