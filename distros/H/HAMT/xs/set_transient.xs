# HAMT::Set::Transient: a set opened for a batch of updates.

MODULE = HAMT    PACKAGE = HAMT::Set::Transient

void
add(self, ...)
        SV *self
    PREINIT:
        hamt_txn *t;
        I32 i;
    CODE:
        t = hamt_txn_handle(aTHX_ self, &hamt_set_txn_vtbl, "HAMT::Set::Transient::add");
        for (i = 1; i < items; i++) {
            hamt_xs_put(aTHX_ &t->m, ST(i), NULL, "HAMT::Set::Transient::add");
            /* Reading a member can run Perl, and Perl can close the transient. */
            t = hamt_txn_handle(aTHX_ self, &hamt_set_txn_vtbl, "HAMT::Set::Transient::add");
        }
        XSRETURN(1);

void
remove(self, ...)
        SV *self
    PREINIT:
        hamt_txn *t;
        I32 i;
    CODE:
        t = hamt_txn_handle(aTHX_ self, &hamt_set_txn_vtbl, "HAMT::Set::Transient::remove");
        for (i = 1; i < items; i++) {
            hamt_xs_del(aTHX_ &t->m, ST(i), "HAMT::Set::Transient::remove");
            t = hamt_txn_handle(aTHX_ self, &hamt_set_txn_vtbl, "HAMT::Set::Transient::remove");
        }
        XSRETURN(1);

void
has(self, member)
        SV *self
        SV *member
    PREINIT:
        hamt_txn *t;
        hamt_key k;
    CODE:
        hamt_txn_handle(aTHX_ self, &hamt_set_txn_vtbl, "HAMT::Set::Transient::has");
        hamt_key_from_sv(aTHX_ member, &k);
        t = hamt_txn_handle(aTHX_ self, &hamt_set_txn_vtbl, "HAMT::Set::Transient::has");
        ST(0) = boolSV(hamt_map_find(t->m.root, k.p, (size_t)k.len, k.utf8, k.hash) != NULL);
        XSRETURN(1);

void
count(self)
        SV *self
    PREINIT:
        hamt_txn *t;
    CODE:
        t = hamt_txn_handle(aTHX_ self, &hamt_set_txn_vtbl, "HAMT::Set::Transient::count");
        ST(0) = sv_2mortal(newSVuv((UV)t->m.count));
        XSRETURN(1);

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
        t = hamt_txn_handle(aTHX_ self, &hamt_set_txn_vtbl, "HAMT::Set::Transient::persistent");
        obj = hamt_handle_new(aTHX_ &hamt_set_vtbl, t->origin, t->m.root, t->m.count,
                              &n, "HAMT::Set::Transient::persistent");
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

void
_check(self)
        SV *self
    PREINIT:
        hamt_txn *t;
    CODE:
        t = hamt_txn_handle(aTHX_ self, &hamt_set_txn_vtbl, "HAMT::Set::Transient::_check");
        ST(0) = sv_2mortal(newSViv((IV)hamt_map_check(t->m.root, t->m.count)));
        XSRETURN(1);

void
CLONE_SKIP(...)
    CODE:
        ST(0) = &PL_sv_yes;
        XSRETURN(1);
