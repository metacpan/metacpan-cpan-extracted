# HAMT::Map::Transient: a map opened for a batch of updates. set and delete
# change it and return it; persistent closes it and returns an ordinary map.

MODULE = HAMT    PACKAGE = HAMT::Map::Transient

void
set(self, ...)
        SV *self
    PREINIT:
        hamt_txn *t;
        I32 i;
    CODE:
        t = hamt_txn_handle(aTHX_ self, &hamt_map_txn_vtbl, "HAMT::Map::Transient::set");
        if ((items - 1) & 1)
            croak("HAMT::Map::Transient::set: odd number of arguments");
        for (i = 1; i < items; i += 2) {
            hamt_xs_put(aTHX_ &t->m, ST(i), ST(i + 1), "HAMT::Map::Transient::set");
            /* Storing a pair can run Perl, and Perl can close the transient. */
            t = hamt_txn_handle(aTHX_ self, &hamt_map_txn_vtbl, "HAMT::Map::Transient::set");
        }
        XSRETURN(1);

void
delete(self, ...)
        SV *self
    PREINIT:
        hamt_txn *t;
        I32 i;
    CODE:
        t = hamt_txn_handle(aTHX_ self, &hamt_map_txn_vtbl, "HAMT::Map::Transient::delete");
        for (i = 1; i < items; i++) {
            hamt_xs_del(aTHX_ &t->m, ST(i), "HAMT::Map::Transient::delete");
            t = hamt_txn_handle(aTHX_ self, &hamt_map_txn_vtbl, "HAMT::Map::Transient::delete");
        }
        XSRETURN(1);

void
get(self, key)
        SV *self
        SV *key
    PREINIT:
        hamt_txn *t;
        hamt_key k;
        hamt_entry *e;
    CODE:
        hamt_txn_handle(aTHX_ self, &hamt_map_txn_vtbl, "HAMT::Map::Transient::get");
        hamt_key_from_sv(aTHX_ key, &k);
        t = hamt_txn_handle(aTHX_ self, &hamt_map_txn_vtbl, "HAMT::Map::Transient::get");
        e = hamt_map_find(t->m.root, k.p, (size_t)k.len, k.utf8, k.hash);
        ST(0) = (e && e->val)
              ? sv_2mortal(SvREFCNT_inc_simple_NN((SV *)e->val))
              : sv_newmortal();
        XSRETURN(1);

void
exists(self, key)
        SV *self
        SV *key
    PREINIT:
        hamt_txn *t;
        hamt_key k;
    CODE:
        hamt_txn_handle(aTHX_ self, &hamt_map_txn_vtbl, "HAMT::Map::Transient::exists");
        hamt_key_from_sv(aTHX_ key, &k);
        t = hamt_txn_handle(aTHX_ self, &hamt_map_txn_vtbl, "HAMT::Map::Transient::exists");
        ST(0) = boolSV(hamt_map_find(t->m.root, k.p, (size_t)k.len, k.utf8, k.hash) != NULL);
        XSRETURN(1);

void
count(self)
        SV *self
    PREINIT:
        hamt_txn *t;
    CODE:
        t = hamt_txn_handle(aTHX_ self, &hamt_map_txn_vtbl, "HAMT::Map::Transient::count");
        ST(0) = sv_2mortal(newSVuv((UV)t->m.count));
        XSRETURN(1);

# An ordinary map holding what the transient holds, of the class the
# transient was opened from. The transient is closed: the root is the map's
# now, and nothing can reach it through here again.
void
persistent(self)
        SV *self
    PREINIT:
        hamt_txn *t;
        hamt_map *n;
        hamt_node *root;
        HV *origin;
        SV *obj;
    CODE:
        t = hamt_txn_handle(aTHX_ self, &hamt_map_txn_vtbl, "HAMT::Map::Transient::persistent");
        obj = hamt_handle_new(aTHX_ &hamt_map_vtbl, t->origin, t->m.root, t->m.count,
                              &n, "HAMT::Map::Transient::persistent");
        root   = t->m.root;
        origin = t->origin;
        t->open    = 0;
        t->m.root  = NULL;
        t->m.count = 0;
        t->origin  = NULL;
        SvREFCNT_dec((SV *)origin);
        if (root) hamt_node_release(HAMT_CX, root);
        ST(0) = obj;
        XSRETURN(1);

# For the tests.
void
_check(self)
        SV *self
    PREINIT:
        hamt_txn *t;
    CODE:
        t = hamt_txn_handle(aTHX_ self, &hamt_map_txn_vtbl, "HAMT::Map::Transient::_check");
        ST(0) = sv_2mortal(newSViv((IV)hamt_map_check(t->m.root, t->m.count)));
        XSRETURN(1);

void
CLONE_SKIP(...)
    CODE:
        ST(0) = &PL_sv_yes;
        XSRETURN(1);
