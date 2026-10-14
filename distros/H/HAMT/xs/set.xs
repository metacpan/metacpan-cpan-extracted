# HAMT::Set. The trie is the map's with entries that carry no value, so
# membership, add and remove are the map's lookup, put and delete; what is a
# set's own is the algebra.

MODULE = HAMT    PACKAGE = HAMT::Set

void
new(klass, ...)
        SV *klass
    PREINIT:
        hamt_map *m;
        SV *obj;
        I32 i;
    CODE:
        obj = hamt_handle_new(aTHX_ &hamt_set_vtbl, hamt_class_stash(aTHX_ klass),
                              NULL, 0, &m, "HAMT::Set::new");
        for (i = 1; i < items; i++)
            hamt_xs_put(aTHX_ m, ST(i), NULL, "HAMT::Set::new");
        ST(0) = obj;
        XSRETURN(1);

void
add(self, ...)
        SV *self
    PREINIT:
        hamt_map *m, *n;
        hamt_node *was;
        SV *obj;
        I32 i;
    CODE:
        m = hamt_handle(aTHX_ self, &hamt_set_vtbl, "HAMT::Set::add", "set");
        was = m->root;
        if (GIMME_V == G_VOID) {
            hamt_void_warn(aTHX_ "HAMT::Set::add");
            XSRETURN_EMPTY;
        }
        obj = hamt_handle_new(aTHX_ &hamt_set_vtbl, SvSTASH(SvRV(self)),
                              m->root, m->count, &n, "HAMT::Set::add");
        for (i = 1; i < items; i++)
            hamt_xs_put(aTHX_ n, ST(i), NULL, "HAMT::Set::add");
        if (n->root != was) ST(0) = obj;
        XSRETURN(1);

void
remove(self, ...)
        SV *self
    PREINIT:
        hamt_map *m, *n;
        hamt_node *was;
        SV *obj;
        I32 i;
    CODE:
        m = hamt_handle(aTHX_ self, &hamt_set_vtbl, "HAMT::Set::remove", "set");
        was = m->root;
        if (GIMME_V == G_VOID) {
            hamt_void_warn(aTHX_ "HAMT::Set::remove");
            XSRETURN_EMPTY;
        }
        obj = hamt_handle_new(aTHX_ &hamt_set_vtbl, SvSTASH(SvRV(self)),
                              m->root, m->count, &n, "HAMT::Set::remove");
        for (i = 1; i < items; i++)
            hamt_xs_del(aTHX_ n, ST(i), "HAMT::Set::remove");
        if (n->root != was) ST(0) = obj;
        XSRETURN(1);

void
has(self, member)
        SV *self
        SV *member
    PREINIT:
        hamt_map *m;
        hamt_key k;
    CODE:
        m = hamt_handle(aTHX_ self, &hamt_set_vtbl, "HAMT::Set::has", "set");
        hamt_key_from_sv(aTHX_ member, &k);
        ST(0) = boolSV(hamt_map_find(m->root, k.p, (size_t)k.len, k.utf8, k.hash) != NULL);
        XSRETURN(1);

void
count(self)
        SV *self
    PREINIT:
        hamt_map *m;
    CODE:
        m = hamt_handle(aTHX_ self, &hamt_set_vtbl, "HAMT::Set::count", "set");
        ST(0) = sv_2mortal(newSVuv((UV)m->count));
        XSRETURN(1);

void
members(self)
        SV *self
    PREINIT:
        hamt_map *m;
        hamt_iter it;
        hamt_entry *e;
    PPCODE:
        m = hamt_handle(aTHX_ self, &hamt_set_vtbl, "HAMT::Set::members", "set");
        if (GIMME_V == G_VOID) XSRETURN_EMPTY;
        if (GIMME_V == G_SCALAR) {
            PUSHs(sv_2mortal(newSVuv((UV)m->count)));
            XSRETURN(1);
        }
        if (m->count > ((size_t)-1 >> 2))
            croak("HAMT::Set::members: too many members for one list");
        EXTEND(SP, (SSize_t)m->count);
        hamt_iter_init(&it, m->root);
        while ((e = hamt_iter_next(&it)))
            PUSHs(sv_2mortal(hamt_key_to_sv(aTHX_ e)));

void
each(self, code)
        SV *self
        SV *code
    PREINIT:
        hamt_map *m;
        hamt_node *root;
        hamt_iter it;
        hamt_entry *e;
        SV *keysv = NULL, *err = NULL;
        int how;
    CODE:
        m = hamt_handle(aTHX_ self, &hamt_set_vtbl, "HAMT::Set::each", "set");
        hamt_xs_need_code(aTHX_ code, "HAMT::Set::each");
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
            how = hamt_xs_call(aTHX_ code, &keysv, 1, NULL);
            if (how == HAMT_XS_LAST || (err = hamt_xs_call_err(aTHX_ how, 1))) break;
        }
        hamt_xs_call_leave(aTHX);
        FREETMPS;
        LEAVE;
        if (err) hamt_xs_rethrow(aTHX_ err);
        XSRETURN(1);

# union, intersect and difference share a body. None of them runs Perl, so
# nothing needs holding across the walk; each returns the receiver itself
# when the result is the receiver, and union returns the other set when the
# result is that and it is of the receiver's class.
void
union(self, other)
        SV *self
        SV *other
    ALIAS:
        intersect  = 1
        difference = 2
    PREINIT:
        hamt_map *m, *o, *n;
        hamt_node *r;
        size_t count = 0;
        int err = 0;
        HV *stash;
        static const char *const name[3] = {
            "HAMT::Set::union", "HAMT::Set::intersect", "HAMT::Set::difference"
        };
    CODE:
        m = hamt_handle(aTHX_ self, &hamt_set_vtbl, name[ix], "set");
        o = hamt_handle(aTHX_ other, &hamt_set_vtbl, name[ix], "set");
        if (GIMME_V == G_VOID) {
            hamt_void_warn(aTHX_ name[ix]);
            XSRETURN_EMPTY;
        }
        stash = SvSTASH(SvRV(self));
        if (ix == 0) {
            hamt_merge_ctx c;
            c.cx = HAMT_CX;
            c.resolve = NULL;
            c.ud = NULL;
            r = hamt_map_merge(&c, m->root, o->root);
            err = c.err;
            count = m->count + c.added;
        }
        else {
            hamt_set_ctx c;
            c.cx = HAMT_CX;
            r = ix == 1 ? hamt_set_intersect(&c, m->root, o->root, m->count, o->count, &count)
                        : hamt_set_subtract(&c, m->root, o->root, m->count, o->count, &count);
            err = c.err;
        }
        if (err) croak("%s: out of memory", name[ix]);

        if (r == m->root) {
            if (r) hamt_node_release(HAMT_CX, r);
            XSRETURN(1);
        }
        if (ix == 0 && r == o->root && SvSTASH(SvRV(other)) == stash) {
            if (r) hamt_node_release(HAMT_CX, r);
            ST(0) = other;
            XSRETURN(1);
        }
        /* The new handle takes a reference of its own; the one the walk
         * returned is released whether or not making the handle works. */
        ENTER;
        if (r) SAVEDESTRUCTOR_X(hamt_xs_root_unref, r);
        ST(0) = hamt_handle_new(aTHX_ &hamt_set_vtbl, stash, r, count, &n, name[ix]);
        LEAVE;
        XSRETURN(1);

void
is_subset(self, other)
        SV *self
        SV *other
    ALIAS:
        is_disjoint = 1
    PREINIT:
        hamt_map *m, *o;
        size_t visits;
        static const char *const name[2] = { "HAMT::Set::is_subset", "HAMT::Set::is_disjoint" };
    CODE:
        m = hamt_handle(aTHX_ self, &hamt_set_vtbl, name[ix], "set");
        o = hamt_handle(aTHX_ other, &hamt_set_vtbl, name[ix], "set");
        ST(0) = boolSV(ix == 0
            ? hamt_set_subset(m->root, o->root, m->count, o->count, &visits)
            : hamt_set_disjoint(m->root, o->root, &visits));
        XSRETURN(1);

void
equals(self, other)
        SV *self
        SV *other
    PREINIT:
        hamt_map *m, *o;
        hamt_eq_ctx c;
    CODE:
        m = hamt_handle(aTHX_ self, &hamt_set_vtbl, "HAMT::Set::equals", "set");
        o = hamt_handle_try(aTHX_ other, &hamt_set_vtbl);
        if (!o || o->count != m->count) XSRETURN_NO;
        c.cx = HAMT_CX;
        c.eq = NULL;
        c.ud = NULL;
        c.visits = 0;
        ST(0) = boolSV(hamt_node_equal(&c, m->root, o->root) > 0);
        XSRETURN(1);

void
transient(self)
        SV *self
    PREINIT:
        hamt_map *m;
    CODE:
        m = hamt_handle(aTHX_ self, &hamt_set_vtbl, "HAMT::Set::transient", "set");
        ST(0) = hamt_txn_new(aTHX_ &hamt_set_txn_vtbl, "HAMT::Set::Transient",
                             SvSTASH(SvRV(self)), m->root, m->count,
                             "HAMT::Set::transient");
        XSRETURN(1);

void
_check(self)
        SV *self
    PREINIT:
        hamt_map *m;
    CODE:
        m = hamt_handle(aTHX_ self, &hamt_set_vtbl, "HAMT::Set::_check", "set");
        ST(0) = sv_2mortal(newSViv((IV)hamt_map_check(m->root, m->count)));
        XSRETURN(1);

void
CLONE_SKIP(...)
    CODE:
        ST(0) = &PL_sv_yes;
        XSRETURN(1);
