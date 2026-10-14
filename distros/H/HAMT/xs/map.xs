# HAMT::Map. Every method that "changes" a map builds a new handle around a
# new root and leaves the receiver's alone.
#
# These are CODE blocks that set ST(0) and return by count, not PPCODE with a
# local SP: storing a pair can run Perl (a tied value, a key with a string
# overload), which can move the stack, and ST() reads its base afresh each
# time where a saved SP would not.

MODULE = HAMT    PACKAGE = HAMT::Map

void
new(klass, ...)
        SV *klass
    PREINIT:
        hamt_map *m;
        SV *obj;
        I32 i;
    CODE:
        if ((items - 1) & 1)
            croak("HAMT::Map::new: odd number of arguments");
        obj = hamt_handle_new(aTHX_ &hamt_map_vtbl, hamt_class_stash(aTHX_ klass),
                              NULL, 0, &m, "HAMT::Map::new");
        for (i = 1; i < items; i += 2)
            hamt_xs_put(aTHX_ m, ST(i), ST(i + 1), "HAMT::Map::new");
        ST(0) = obj;
        XSRETURN(1);

void
from_hash(klass, href)
        SV *klass
        SV *href
    PREINIT:
        hamt_map *m;
        SV *obj;
        HV *hv;
        HE *he;
    CODE:
        SvGETMAGIC(href);
        if (!SvROK(href) || SvTYPE(SvRV(href)) != SVt_PVHV)
            croak("HAMT::Map::from_hash: not a hash reference");
        hv = (HV *)SvRV(href);
        obj = hamt_handle_new(aTHX_ &hamt_map_vtbl, hamt_class_stash(aTHX_ klass),
                              NULL, 0, &m, "HAMT::Map::from_hash");
        hv_iterinit(hv);
        while ((he = hv_iternext(hv))) {
            hamt_key k;
            hamt_key_from_he(aTHX_ hv, he, &k);
            hamt_xs_put_key(aTHX_ m, &k, hv_iterval(hv, he), "HAMT::Map::from_hash");
        }
        ST(0) = obj;
        XSRETURN(1);

void
set(self, ...)
        SV *self
    PREINIT:
        hamt_map *m, *n;
        hamt_node *was;
        SV *obj;
        I32 i;
    CODE:
        m = hamt_handle(aTHX_ self, &hamt_map_vtbl, "HAMT::Map::set", "map");
        was = m->root;
        if ((items - 1) & 1)
            croak("HAMT::Map::set: odd number of arguments");
        if (GIMME_V == G_VOID) {
            hamt_void_warn(aTHX_ "HAMT::Map::set");
            XSRETURN_EMPTY;
        }
        obj = hamt_handle_new(aTHX_ &hamt_map_vtbl, SvSTASH(SvRV(self)),
                              m->root, m->count, &n, "HAMT::Map::set");
        for (i = 1; i < items; i += 2)
            hamt_xs_put(aTHX_ n, ST(i), ST(i + 1), "HAMT::Map::set");
        /* Nothing changed: the receiver is the answer. */
        if (n->root != was) ST(0) = obj;
        XSRETURN(1);

void
delete(self, ...)
        SV *self
    PREINIT:
        hamt_map *m, *n;
        hamt_node *was;
        SV *obj;
        I32 i;
    CODE:
        m = hamt_handle(aTHX_ self, &hamt_map_vtbl, "HAMT::Map::delete", "map");
        was = m->root;
        if (GIMME_V == G_VOID) {
            hamt_void_warn(aTHX_ "HAMT::Map::delete");
            XSRETURN_EMPTY;
        }
        obj = hamt_handle_new(aTHX_ &hamt_map_vtbl, SvSTASH(SvRV(self)),
                              m->root, m->count, &n, "HAMT::Map::delete");
        for (i = 1; i < items; i++)
            hamt_xs_del(aTHX_ n, ST(i), "HAMT::Map::delete");
        if (n->root != was) ST(0) = obj;
        XSRETURN(1);

void
get(self, key)
        SV *self
        SV *key
    PREINIT:
        hamt_map *m;
        hamt_key k;
        hamt_entry *e;
    CODE:
        m = hamt_handle(aTHX_ self, &hamt_map_vtbl, "HAMT::Map::get", "map");
        hamt_key_from_sv(aTHX_ key, &k);
        e = hamt_map_find(m->root, k.p, (size_t)k.len, k.utf8, k.hash);
        /* The stored scalar itself, kept alive past the map by a reference
         * of its own. A missing key is a fresh undef, never the shared one:
         * that would be an alias to a scalar the whole interpreter uses. */
        ST(0) = (e && e->val)
              ? sv_2mortal(SvREFCNT_inc_simple_NN((SV *)e->val))
              : sv_newmortal();
        XSRETURN(1);

void
exists(self, key)
        SV *self
        SV *key
    PREINIT:
        hamt_map *m;
        hamt_key k;
    CODE:
        m = hamt_handle(aTHX_ self, &hamt_map_vtbl, "HAMT::Map::exists", "map");
        hamt_key_from_sv(aTHX_ key, &k);
        ST(0) = boolSV(hamt_map_find(m->root, k.p, (size_t)k.len, k.utf8, k.hash) != NULL);
        XSRETURN(1);

void
count(self)
        SV *self
    PREINIT:
        hamt_map *m;
    CODE:
        m = hamt_handle(aTHX_ self, &hamt_map_vtbl, "HAMT::Map::count", "map");
        ST(0) = sv_2mortal(newSVuv((UV)m->count));
        XSRETURN(1);

# keys, values and pairs share a body. In list context the list, in the
# trie's own order, which is the same for all three; in scalar context the
# count. Nothing here runs Perl, so a local SP is safe.
void
keys(self)
        SV *self
    ALIAS:
        values = 1
        pairs  = 2
    PREINIT:
        hamt_map *m;
        hamt_iter it;
        hamt_entry *e;
        static const char *const name[3] = {
            "HAMT::Map::keys", "HAMT::Map::values", "HAMT::Map::pairs"
        };
    PPCODE:
        m = hamt_handle(aTHX_ self, &hamt_map_vtbl, name[ix], "map");
        if (GIMME_V == G_VOID) XSRETURN_EMPTY;
        if (GIMME_V == G_SCALAR) {
            PUSHs(sv_2mortal(newSVuv((UV)m->count)));
            XSRETURN(1);
        }
        /* Twice the count has to fit the signed size EXTEND takes. There
         * is no SSize_t_MAX before 5.16 or so; a quarter of size_t is under
         * it on every platform. */
        if (m->count > ((size_t)-1 >> 2))
            croak("%s: too many entries for one list", name[ix]);
        EXTEND(SP, (SSize_t)(ix == 2 ? m->count * 2 : m->count));
        hamt_iter_init(&it, m->root);
        while ((e = hamt_iter_next(&it))) {
            if (ix != 1) PUSHs(sv_2mortal(hamt_key_to_sv(aTHX_ e)));
            if (ix != 0) PUSHs(e->val ? sv_2mortal(SvREFCNT_inc_simple_NN((SV *)e->val))
                                      : sv_newmortal());
        }

void
to_hash(self)
        SV *self
    PREINIT:
        hamt_map *m;
        hamt_iter it;
        hamt_entry *e;
        HV *hv;
    CODE:
        m = hamt_handle(aTHX_ self, &hamt_map_vtbl, "HAMT::Map::to_hash", "map");
        hv = newHV();
        ST(0) = sv_2mortal(newRV_noinc((SV *)hv));
        hamt_iter_init(&it, m->root);
        while ((e = hamt_iter_next(&it))) {
            SV *v;
            if (e->klen > (size_t)I32_MAX)
                croak("HAMT::Map::to_hash: a key is too long for a hash");
            /* A copy, so the hash is an ordinary one: writable throughout. */
            v = e->val ? newSVsv((SV *)e->val) : newSV(0);
            if (!hv_store(hv, e->key, e->utf8 ? -(I32)e->klen : (I32)e->klen, v, 0))
                SvREFCNT_dec(v);
        }
        XSRETURN(1);

# Calls the sub with each key and its value. Returns the map.
void
each(self, code)
        SV *self
        SV *code
    PREINIT:
        hamt_map *m;
        hamt_node *root;
        hamt_iter it;
        hamt_entry *e;
        SV *keysv = NULL, *args[2], *err = NULL;
        int how;
    CODE:
        m = hamt_handle(aTHX_ self, &hamt_map_vtbl, "HAMT::Map::each", "map");
        hamt_xs_need_code(aTHX_ code, "HAMT::Map::each");
        root = m->root;
        ENTER;
        SAVETMPS;
        hamt_xs_hold_root(aTHX_ root);
        hamt_xs_walk_enter(aTHX);
        hamt_iter_init(&it, root);
        while ((e = hamt_iter_next(&it))) {
            keysv = hamt_xs_scratch(aTHX_ keysv);
            sv_setpvn(keysv, e->key, (STRLEN)e->klen);
            if (e->utf8) SvUTF8_on(keysv); else SvUTF8_off(keysv);
            args[0] = keysv;
            args[1] = hamt_xs_val_sv(aTHX_ e);
            /* The call frees whatever temporaries the sub makes. */
            how = hamt_xs_call(aTHX_ code, args, 2, NULL);
            if (how == HAMT_XS_LAST || (err = hamt_xs_call_err(aTHX_ how, 1))) break;
        }
        hamt_xs_call_leave(aTHX);
        FREETMPS;
        LEAVE;
        if (err) hamt_xs_rethrow(aTHX_ err);
        XSRETURN(1);

# True when the other thing is a map holding the same keys with equal values.
void
equals(self, other, ...)
        SV *self
        SV *other
    PREINIT:
        hamt_map *m, *o;
        hamt_eq_ctx c;
        hamt_node *ra, *rb;
        int rc;
    CODE:
        m = hamt_handle(aTHX_ self, &hamt_map_vtbl, "HAMT::Map::equals", "map");
        if (items > 3) croak("HAMT::Map::equals: too many arguments");
        if (items == 3) hamt_xs_need_code(aTHX_ ST(2), "HAMT::Map::equals");
        o = hamt_handle_try(aTHX_ other, &hamt_map_vtbl);
        if (!o || o->count != m->count) XSRETURN_NO;
        ra = m->root;
        rb = o->root;
        c.cx = HAMT_CX;
        c.eq = items == 3 ? hamt_xs_eq_cb : NULL;
        c.ud = items == 3 ? (void *)ST(2) : NULL;
        c.visits = 0;
        ENTER;
        hamt_xs_hold_root(aTHX_ ra);
        hamt_xs_hold_root(aTHX_ rb);
        rc = hamt_node_equal(&c, ra, rb);
        LEAVE;
        ST(0) = boolSV(rc > 0);
        XSRETURN(1);

# Every key of both. For a key in both, the other map's value, or what the
# sub returns when one is given.
void
merge(self, other, ...)
        SV *self
        SV *other
    PREINIT:
        hamt_map *m, *o, *n;
        hamt_merge_ctx c;
        hamt_xs_sub res;
        hamt_node *ra, *rb, *r;
        HV *stash;
        size_t count;
        SV *obj;
    CODE:
        m = hamt_handle(aTHX_ self, &hamt_map_vtbl, "HAMT::Map::merge", "map");
        o = hamt_handle(aTHX_ other, &hamt_map_vtbl, "HAMT::Map::merge", "map");
        if (items > 3) croak("HAMT::Map::merge: too many arguments");
        if (items == 3) hamt_xs_need_code(aTHX_ ST(2), "HAMT::Map::merge");
        if (GIMME_V == G_VOID) {
            hamt_void_warn(aTHX_ "HAMT::Map::merge");
            XSRETURN_EMPTY;
        }
        ra = m->root;
        rb = o->root;
        count = m->count;
        stash = SvSTASH(SvRV(self));
        res.code = items == 3 ? ST(2) : NULL;
        res.err  = NULL;
        c.cx = HAMT_CX;
        c.resolve = items == 3 ? hamt_xs_resolve_cb : NULL;
        c.ud = &res;

        ENTER;
        hamt_xs_hold_root(aTHX_ ra);
        hamt_xs_hold_root(aTHX_ rb);
        r = hamt_map_merge(&c, ra, rb);
        if (c.err == HAMT_ERR_ABORT) {
            /* The resolver died. Put its error back and die with it, object
             * or string, exactly as it was. */
            sv_setsv(ERRSV, res.err);
            SvREFCNT_dec(res.err);
            croak(NULL);
        }
        if (c.err) croak("HAMT::Map::merge: out of memory");

        if (r == ra) {
            /* The other map added nothing and changed nothing. */
            if (r) hamt_node_release(HAMT_CX, r);
            LEAVE;
            XSRETURN(1);
        }
        if (r == rb && SvSTASH(SvRV(other)) == stash) {
            /* The result is exactly the other map, and it is of our class. */
            if (r) hamt_node_release(HAMT_CX, r);
            LEAVE;
            ST(0) = other;
            XSRETURN(1);
        }
        if (r) SAVEDESTRUCTOR_X(hamt_xs_root_unref, r);
        obj = hamt_handle_new(aTHX_ &hamt_map_vtbl, stash, r, count + c.added, &n,
                              "HAMT::Map::merge");
        LEAVE;
        ST(0) = obj;
        XSRETURN(1);

# The map with one key's value replaced by what the sub makes of it.
void
update(self, key, code)
        SV *self
        SV *key
        SV *code
    PREINIT:
        hamt_map *m, *n;
        hamt_key k;
        hamt_node *root;
        hamt_entry *e;
        SV *obj, *keep, *res, *err;
        int same;
    CODE:
        m = hamt_handle(aTHX_ self, &hamt_map_vtbl, "HAMT::Map::update", "map");
        hamt_xs_need_code(aTHX_ code, "HAMT::Map::update");
        if (GIMME_V == G_VOID) {
            hamt_void_warn(aTHX_ "HAMT::Map::update");
            XSRETURN_EMPTY;
        }
        hamt_key_from_sv(aTHX_ key, &k);
        /* The sub may change or free the scalar the key was read from, so the
         * bytes are kept in a scalar of this call's own. */
        keep = sv_2mortal(newSVpvn(k.p, k.len));
        k.p = SvPVX(keep);
        root = m->root;
        obj = hamt_handle_new(aTHX_ &hamt_map_vtbl, SvSTASH(SvRV(self)), root,
                              m->count, &n, "HAMT::Map::update");
        e = hamt_map_find(root, k.p, (size_t)k.len, k.utf8, k.hash);
        {
            SV *arg;
            ENTER;
            SAVETMPS;
            hamt_xs_hold_root(aTHX_ root);
            arg = hamt_xs_val_sv(aTHX_ e);
            hamt_xs_call_enter(aTHX);
            err = hamt_xs_call_err(aTHX_ hamt_xs_call(aTHX_ code, &arg, 1, &res), 0);
            hamt_xs_call_leave(aTHX);
            /* Stored before the frame goes: what the sub returned is a
             * temporary of that frame. */
            /* By value, not by address: a sub's return is always a copy. */
            same = err || (e && e->val && hamt_sv_eq_cx(HAMT_CX, res, (SV *)e->val));
            if (!same) hamt_xs_put_key(aTHX_ n, &k, res, "HAMT::Map::update");
            FREETMPS;
            LEAVE;
        }
        if (err) hamt_xs_rethrow(aTHX_ err);
        if (!same) ST(0) = obj;
        XSRETURN(1);

# Calls the sub for every key that is in one map and not the other, or in
# both with values that are not equal. Returns how many that was.
void
diff(self, other, code)
        SV *self
        SV *other
        SV *code
    PREINIT:
        hamt_map *m, *o;
        hamt_diff_ctx c;
        hamt_xs_sub sub;
        hamt_node *ra, *rb;
    CODE:
        m = hamt_handle(aTHX_ self, &hamt_map_vtbl, "HAMT::Map::diff", "map");
        o = hamt_handle(aTHX_ other, &hamt_map_vtbl, "HAMT::Map::diff", "map");
        hamt_xs_need_code(aTHX_ code, "HAMT::Map::diff");
        ra = m->root;
        rb = o->root;
        c.cx = HAMT_CX;
        sub.code = code;
        sub.err = NULL;
        c.fn = hamt_xs_diff_cb;
        c.ud = &sub;
        c.eq.cx = HAMT_CX;
        c.eq.eq = NULL;
        c.eq.ud = NULL;
        ENTER;
        hamt_xs_hold_root(aTHX_ ra);
        hamt_xs_hold_root(aTHX_ rb);
        hamt_xs_walk_enter(aTHX);
        hamt_map_diff(&c, ra, rb);
        hamt_xs_call_leave(aTHX);
        LEAVE;
        if (sub.err) hamt_xs_rethrow(aTHX_ sub.err);
        ST(0) = sv_2mortal(newSVuv((UV)c.reported));
        XSRETURN(1);

# The keys of the map, as a set. The set shares nothing with the map: a
# map's entries carry values and a set's do not.
void
key_set(self)
        SV *self
    PREINIT:
        hamt_map *m, *n;
        hamt_node *root;
        hamt_iter it;
        hamt_entry *e;
        SV *obj;
    CODE:
        m = hamt_handle(aTHX_ self, &hamt_map_vtbl, "HAMT::Map::key_set", "map");
        root = m->root;
        obj = hamt_handle_new(aTHX_ &hamt_set_vtbl, gv_stashpvs("HAMT::Set", GV_ADD),
                              NULL, 0, &n, "HAMT::Map::key_set");
        hamt_iter_init(&it, root);
        while ((e = hamt_iter_next(&it))) {
            hamt_key k;
            k.p = e->key; k.len = (STRLEN)e->klen; k.utf8 = e->utf8; k.hash = e->hash;
            hamt_xs_put_key(aTHX_ n, &k, NULL, "HAMT::Map::key_set");
        }
        ST(0) = obj;
        XSRETURN(1);

# A transient opened on this map: it starts out holding what the map holds,
# and the map never sees what is done to it.
void
transient(self)
        SV *self
    PREINIT:
        hamt_map *m;
    CODE:
        m = hamt_handle(aTHX_ self, &hamt_map_vtbl, "HAMT::Map::transient", "map");
        ST(0) = hamt_txn_new(aTHX_ &hamt_map_txn_vtbl, "HAMT::Map::Transient",
                             SvSTASH(SvRV(self)), m->root, m->count,
                             "HAMT::Map::transient");
        XSRETURN(1);

# For the tests: 0, or the number of the rule in hamt_check.h that the trie
# breaks.
void
_check(self)
        SV *self
    PREINIT:
        hamt_map *m;
    CODE:
        m = hamt_handle(aTHX_ self, &hamt_map_vtbl, "HAMT::Map::_check", "map");
        ST(0) = sv_2mortal(newSViv((IV)hamt_map_check(m->root, m->count)));
        XSRETURN(1);

# A handle is not carried into a new thread: its nodes hold this
# interpreter's scalars.
void
CLONE_SKIP(...)
    CODE:
        ST(0) = &PL_sv_yes;
        XSRETURN(1);
