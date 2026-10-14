# HAMT::Vector::Transient: a vector opened for a batch of updates.

MODULE = HAMT    PACKAGE = HAMT::Vector::Transient

void
push(self, ...)
        SV *self
    PREINIT:
        hamt_vtxn *t;
        I32 i;
    CODE:
        t = hamt_vtxn_handle(aTHX_ self, "HAMT::Vector::Transient::push");
        for (i = 1; i < items; i++) {
            hamt_xs_vec_push(aTHX_ &t->v, ST(i), "HAMT::Vector::Transient::push");
            /* Reading a value can run Perl, and Perl can close the transient. */
            t = hamt_vtxn_handle(aTHX_ self, "HAMT::Vector::Transient::push");
        }
        XSRETURN(1);

void
set(self, index, value)
        SV *self
        SV *index
        SV *value
    PREINIT:
        hamt_vtxn *t;
        size_t i;
    CODE:
        t = hamt_vtxn_handle(aTHX_ self, "HAMT::Vector::Transient::set");
        if (!hamt_xs_index(aTHX_ index, t->v.count, &i))
            croak("HAMT::Vector::Transient::set: index %" IVdf " is out of range for %" UVuf " elements",
                  SvIV(index), (UV)t->v.count);
        hamt_xs_vec_set(aTHX_ &t->v, i, value, "HAMT::Vector::Transient::set");
        XSRETURN(1);

void
pop(self)
        SV *self
    PREINIT:
        hamt_vtxn *t;
    CODE:
        t = hamt_vtxn_handle(aTHX_ self, "HAMT::Vector::Transient::pop");
        hamt_xs_vec_pop(aTHX_ &t->v, "HAMT::Vector::Transient::pop");
        XSRETURN(1);

void
get(self, index)
        SV *self
        SV *index
    PREINIT:
        hamt_vtxn *t;
        size_t i;
    CODE:
        t = hamt_vtxn_handle(aTHX_ self, "HAMT::Vector::Transient::get");
        ST(0) = hamt_xs_index(aTHX_ index, t->v.count, &i)
              ? sv_2mortal(SvREFCNT_inc_simple_NN((SV *)hamt_vec_get(&t->v, i)))
              : sv_newmortal();
        XSRETURN(1);

void
count(self)
        SV *self
    PREINIT:
        hamt_vtxn *t;
    CODE:
        t = hamt_vtxn_handle(aTHX_ self, "HAMT::Vector::Transient::count");
        ST(0) = sv_2mortal(newSVuv((UV)t->v.count));
        XSRETURN(1);

# An ordinary vector of what the transient holds, of the class it was opened
# from. The transient is closed, and holds nothing afterwards.
void
persistent(self)
        SV *self
    PREINIT:
        hamt_vtxn *t;
        hamt_vec *n, gone;
        HV *origin;
        SV *obj;
    CODE:
        t = hamt_vtxn_handle(aTHX_ self, "HAMT::Vector::Transient::persistent");
        obj = hamt_vec_handle_new(aTHX_ t->origin, &t->v, &n,
                                  "HAMT::Vector::Transient::persistent");
        gone   = t->v;
        origin = t->origin;
        t->open   = 0;
        t->origin = NULL;
        hamt_vec_init(&t->v);
        SvREFCNT_dec((SV *)origin);
        hamt_vec_clear(HAMT_CX, &gone);
        ST(0) = obj;
        XSRETURN(1);

void
_check(self)
        SV *self
    PREINIT:
        hamt_vtxn *t;
    CODE:
        t = hamt_vtxn_handle(aTHX_ self, "HAMT::Vector::Transient::_check");
        ST(0) = sv_2mortal(newSViv((IV)hamt_vec_check(&t->v)));
        XSRETURN(1);

void
CLONE_SKIP(...)
    CODE:
        ST(0) = &PL_sv_yes;
        XSRETURN(1);
