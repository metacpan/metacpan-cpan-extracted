# HAMT::Vector. Every method that "changes" a vector gives the change a
# struct of its own that starts out sharing the receiver's nodes, so the
# first thing it touches is copied and the receiver never moves.

MODULE = HAMT    PACKAGE = HAMT::Vector

void
new(klass, ...)
        SV *klass
    PREINIT:
        hamt_vec *v;
        SV *obj;
        I32 i;
    CODE:
        obj = hamt_vec_handle_new(aTHX_ hamt_class_stash(aTHX_ klass), NULL, &v,
                                  "HAMT::Vector::new");
        for (i = 1; i < items; i++)
            hamt_xs_vec_push(aTHX_ v, ST(i), "HAMT::Vector::new");
        ST(0) = obj;
        XSRETURN(1);

void
push(self, ...)
        SV *self
    PREINIT:
        hamt_vec *v, *n;
        SV *obj;
        I32 i;
    CODE:
        v = hamt_vec_handle(aTHX_ self, "HAMT::Vector::push");
        if (GIMME_V == G_VOID) {
            hamt_void_warn(aTHX_ "HAMT::Vector::push");
            XSRETURN_EMPTY;
        }
        if (items == 1) XSRETURN(1);
        obj = hamt_vec_handle_new(aTHX_ SvSTASH(SvRV(self)), v, &n, "HAMT::Vector::push");
        for (i = 1; i < items; i++)
            hamt_xs_vec_push(aTHX_ n, ST(i), "HAMT::Vector::push");
        ST(0) = obj;
        XSRETURN(1);

void
set(self, index, value)
        SV *self
        SV *index
        SV *value
    PREINIT:
        hamt_vec *v, *n;
        size_t i;
        SV *obj;
    CODE:
        v = hamt_vec_handle(aTHX_ self, "HAMT::Vector::set");
        if (!hamt_xs_index(aTHX_ index, v->count, &i))
            croak("HAMT::Vector::set: index %" IVdf " is out of range for %" UVuf " elements",
                  SvIV(index), (UV)v->count);
        if (GIMME_V == G_VOID) {
            hamt_void_warn(aTHX_ "HAMT::Vector::set");
            XSRETURN_EMPTY;
        }
        if (hamt_vec_get(v, i) == (void *)value) XSRETURN(1);
        obj = hamt_vec_handle_new(aTHX_ SvSTASH(SvRV(self)), v, &n, "HAMT::Vector::set");
        hamt_xs_vec_set(aTHX_ n, i, value, "HAMT::Vector::set");
        ST(0) = obj;
        XSRETURN(1);

void
pop(self)
        SV *self
    PREINIT:
        hamt_vec *v, *n;
        SV *obj;
    CODE:
        v = hamt_vec_handle(aTHX_ self, "HAMT::Vector::pop");
        if (GIMME_V == G_VOID) {
            hamt_void_warn(aTHX_ "HAMT::Vector::pop");
            XSRETURN_EMPTY;
        }
        if (v->count == 0) XSRETURN(1);
        obj = hamt_vec_handle_new(aTHX_ SvSTASH(SvRV(self)), v, &n, "HAMT::Vector::pop");
        hamt_xs_vec_pop(aTHX_ n, "HAMT::Vector::pop");
        ST(0) = obj;
        XSRETURN(1);

void
get(self, index)
        SV *self
        SV *index
    PREINIT:
        hamt_vec *v;
        size_t i;
    CODE:
        v = hamt_vec_handle(aTHX_ self, "HAMT::Vector::get");
        ST(0) = hamt_xs_index(aTHX_ index, v->count, &i)
              ? sv_2mortal(SvREFCNT_inc_simple_NN((SV *)hamt_vec_get(v, i)))
              : sv_newmortal();
        XSRETURN(1);

void
first(self)
        SV *self
    ALIAS:
        last = 1
    PREINIT:
        hamt_vec *v;
    CODE:
        v = hamt_vec_handle(aTHX_ self, ix ? "HAMT::Vector::last" : "HAMT::Vector::first");
        ST(0) = v->count
              ? sv_2mortal(SvREFCNT_inc_simple_NN((SV *)hamt_vec_get(v, ix ? v->count - 1 : 0)))
              : sv_newmortal();
        XSRETURN(1);

void
count(self)
        SV *self
    PREINIT:
        hamt_vec *v;
    CODE:
        v = hamt_vec_handle(aTHX_ self, "HAMT::Vector::count");
        ST(0) = sv_2mortal(newSVuv((UV)v->count));
        XSRETURN(1);

# Every value, in order: the stored scalars themselves. In scalar context,
# how many.
void
list(self)
        SV *self
    PREINIT:
        hamt_vec *v;
        hamt_vec_iter it;
        void *const *run;
        size_t start;
        uint32_t n, i;
    PPCODE:
        v = hamt_vec_handle(aTHX_ self, "HAMT::Vector::list");
        if (GIMME_V == G_VOID) XSRETURN_EMPTY;
        if (GIMME_V == G_SCALAR) {
            PUSHs(sv_2mortal(newSVuv((UV)v->count)));
            XSRETURN(1);
        }
        if (v->count > ((size_t)-1 >> 2))
            croak("HAMT::Vector::list: too many elements for one list");
        EXTEND(SP, (SSize_t)v->count);
        hamt_vec_iter_init(&it, v);
        while ((run = hamt_vec_iter_next(&it, &start, &n)))
            for (i = 0; i < n; i++)
                PUSHs(sv_2mortal(SvREFCNT_inc_simple_NN((SV *)run[i])));

# A new, ordinary array holding a copy of every value.
void
to_array(self)
        SV *self
    PREINIT:
        hamt_vec *v;
        hamt_vec_iter it;
        void *const *run;
        size_t start;
        uint32_t n, i;
        AV *av;
    CODE:
        v = hamt_vec_handle(aTHX_ self, "HAMT::Vector::to_array");
        av = newAV();
        ST(0) = sv_2mortal(newRV_noinc((SV *)av));
        if (v->count) {
            if (v->count > (size_t)I32_MAX) croak("HAMT::Vector::to_array: too many elements for an array");
            av_extend(av, (I32)(v->count - 1));
        }
        hamt_vec_iter_init(&it, v);
        while ((run = hamt_vec_iter_next(&it, &start, &n)))
            for (i = 0; i < n; i++)
                av_push(av, newSVsv((SV *)run[i]));
        XSRETURN(1);

# Every value of this vector followed by every value of the other.
void
concat(self, other)
        SV *self
        SV *other
    PREINIT:
        hamt_vec *v, *o, *n, res;
        SV *obj;
    CODE:
        v = hamt_vec_handle(aTHX_ self, "HAMT::Vector::concat");
        o = hamt_vec_handle(aTHX_ other, "HAMT::Vector::concat");
        if (GIMME_V == G_VOID) {
            hamt_void_warn(aTHX_ "HAMT::Vector::concat");
            XSRETURN_EMPTY;
        }
        if (o->count == 0) XSRETURN(1);
        if (v->count == 0 && SvSTASH(SvRV(other)) == SvSTASH(SvRV(self))) {
            ST(0) = other;
            XSRETURN(1);
        }
        obj = hamt_vec_handle_new(aTHX_ SvSTASH(SvRV(self)), NULL, &n, "HAMT::Vector::concat");
        if (hamt_vec_concat(HAMT_CX, &res, v, o)) croak("HAMT::Vector::concat: out of memory");
        *n = res;
        ST(0) = obj;
        XSRETURN(1);

# The values from one index on, or as many of them as asked for. It clamps:
# a length that runs past the end stops at the end, and a start past the end
# is an empty vector.
void
slice(self, from, ...)
        SV *self
        SV *from
    PREINIT:
        hamt_vec *v, *n, res;
        IV f, l;
        size_t start, len;
        SV *obj;
    CODE:
        v = hamt_vec_handle(aTHX_ self, "HAMT::Vector::slice");
        if (items > 3) croak("HAMT::Vector::slice: too many arguments");
        f = SvIV(from);
        if (f < 0) start = (UV)(-(f + 1)) >= (UV)v->count ? 0 : v->count - (size_t)(-(f + 1)) - 1;
        else       start = (UV)f > (UV)v->count ? v->count : (size_t)f;
        len = v->count - start;
        if (items == 3 && SvOK(ST(2))) {
            l = SvIV(ST(2));
            if (l < 0) croak("HAMT::Vector::slice: length %" IVdf " is negative", l);
            if ((UV)l < (UV)len) len = (size_t)l;
        }
        if (GIMME_V == G_VOID) {
            hamt_void_warn(aTHX_ "HAMT::Vector::slice");
            XSRETURN_EMPTY;
        }
        if (len == v->count) XSRETURN(1);
        obj = hamt_vec_handle_new(aTHX_ SvSTASH(SvRV(self)), NULL, &n, "HAMT::Vector::slice");
        if (len) {
            if (hamt_vec_slice(HAMT_CX, &res, v, start, len)) croak("HAMT::Vector::slice: out of memory");
            *n = res;
        }
        ST(0) = obj;
        XSRETURN(1);

# The vector with values put in before an index.
void
insert(self, index, ...)
        SV *self
        SV *index
    PREINIT:
        hamt_vec *v, *n, *mid;
        size_t at;
        SV *obj;
        I32 i;
    CODE:
        v = hamt_vec_handle(aTHX_ self, "HAMT::Vector::insert");
        if (!hamt_xs_gap(aTHX_ index, v->count, &at))
            croak("HAMT::Vector::insert: index %" IVdf " is out of range for %" UVuf " elements",
                  SvIV(index), (UV)v->count);
        if (GIMME_V == G_VOID) {
            hamt_void_warn(aTHX_ "HAMT::Vector::insert");
            XSRETURN_EMPTY;
        }
        if (items == 2) XSRETURN(1);
        /* The new values go into a vector of their own first, in a handle,
         * so that one of them dying as it is read leaves nothing behind. */
        hamt_vec_handle_new(aTHX_ SvSTASH(SvRV(self)), NULL, &mid, "HAMT::Vector::insert");
        for (i = 2; i < items; i++)
            hamt_xs_vec_push(aTHX_ mid, ST(i), "HAMT::Vector::insert");
        v = hamt_vec_handle(aTHX_ self, "HAMT::Vector::insert");
        obj = hamt_vec_handle_new(aTHX_ SvSTASH(SvRV(self)), NULL, &n, "HAMT::Vector::insert");
        hamt_xs_vec_splice(aTHX_ n, v, at, 0, mid, "HAMT::Vector::insert");
        ST(0) = obj;
        XSRETURN(1);

# The vector without the value at an index, or without several from there.
void
remove(self, index, ...)
        SV *self
        SV *index
    PREINIT:
        hamt_vec *v, *n;
        size_t at, len = 1;
        IV l;
        SV *obj;
    CODE:
        v = hamt_vec_handle(aTHX_ self, "HAMT::Vector::remove");
        if (items > 3) croak("HAMT::Vector::remove: too many arguments");
        if (items == 3 && SvOK(ST(2))) {
            l = SvIV(ST(2));
            if (l < 0) croak("HAMT::Vector::remove: length %" IVdf " is negative", l);
            len = (size_t)l;
        }
        if (GIMME_V == G_VOID) {
            hamt_void_warn(aTHX_ "HAMT::Vector::remove");
            XSRETURN_EMPTY;
        }
        /* An index that names nothing removes nothing. */
        if (!hamt_xs_index(aTHX_ index, v->count, &at) || len == 0) XSRETURN(1);
        if (len > v->count - at) len = v->count - at;
        obj = hamt_vec_handle_new(aTHX_ SvSTASH(SvRV(self)), NULL, &n, "HAMT::Vector::remove");
        hamt_xs_vec_splice(aTHX_ n, v, at, len, NULL, "HAMT::Vector::remove");
        ST(0) = obj;
        XSRETURN(1);

# Calls the sub with each value and its index. Returns the vector.
void
each(self, code)
        SV *self
        SV *code
    PREINIT:
        hamt_vec *v, *held;
        hamt_vec_iter it;
        void *const *run;
        size_t start;
        uint32_t n, i;
        SV *idxsv = NULL, *args[2], *err = NULL;
        int how = HAMT_XS_RETURNED;
    CODE:
        v = hamt_vec_handle(aTHX_ self, "HAMT::Vector::each");
        hamt_xs_need_code(aTHX_ code, "HAMT::Vector::each");
        ENTER;
        SAVETMPS;
        held = hamt_xs_hold_vec(aTHX_ v, "HAMT::Vector::each");
        hamt_xs_walk_enter(aTHX);
        hamt_vec_iter_init(&it, held);
        while (how != HAMT_XS_LAST && !err && (run = hamt_vec_iter_next(&it, &start, &n))) {
            for (i = 0; i < n; i++) {
                idxsv = hamt_xs_scratch(aTHX_ idxsv);
                sv_setuv(idxsv, (UV)(start + i));
                args[0] = (SV *)run[i];
                args[1] = idxsv;
                how = hamt_xs_call(aTHX_ code, args, 2, NULL);
                if (how == HAMT_XS_LAST || (err = hamt_xs_call_err(aTHX_ how, 1))) break;
            }
        }
        hamt_xs_call_leave(aTHX);
        FREETMPS;
        LEAVE;
        if (err) hamt_xs_rethrow(aTHX_ err);
        XSRETURN(1);

# True when the other thing is a vector of equal values in the same order.
void
equals(self, other, ...)
        SV *self
        SV *other
    PREINIT:
        hamt_vec *v, *o, *ha, *hb;
        hamt_eq_ctx c;
        int rc;
    CODE:
        v = hamt_vec_handle(aTHX_ self, "HAMT::Vector::equals");
        if (items > 3) croak("HAMT::Vector::equals: too many arguments");
        if (items == 3) hamt_xs_need_code(aTHX_ ST(2), "HAMT::Vector::equals");
        o = hamt_vec_handle_try(aTHX_ other);
        if (!o || o->count != v->count) XSRETURN_NO;
        c.cx = HAMT_CX;
        c.eq = items == 3 ? hamt_xs_eq_cb : NULL;
        c.ud = items == 3 ? (void *)ST(2) : NULL;
        c.visits = 0;
        ENTER;
        ha = hamt_xs_hold_vec(aTHX_ v, "HAMT::Vector::equals");
        hb = hamt_xs_hold_vec(aTHX_ o, "HAMT::Vector::equals");
        rc = hamt_vec_equal(&c, ha, hb);
        LEAVE;
        ST(0) = boolSV(rc > 0);
        XSRETURN(1);

void
transient(self)
        SV *self
    PREINIT:
        hamt_vec *v;
        hamt_vtxn *t;
        SV *inner, *rv;
        MAGIC *mg;
    CODE:
        v = hamt_vec_handle(aTHX_ self, "HAMT::Vector::transient");
        t = (hamt_vtxn *)HAMT_ALLOC(HAMT_CX, sizeof(hamt_vtxn));
        if (!t) croak("HAMT::Vector::transient: out of memory");
        hamt_vec_share(&t->v, v);
        t->origin = (HV *)SvREFCNT_inc_simple_NN((SV *)SvSTASH(SvRV(self)));
        t->open   = 1;
        inner = newSV(0);
        mg = sv_magicext(inner, NULL, PERL_MAGIC_ext, &hamt_vec_txn_vtbl, (const char *)t, 0);
        mg->mg_flags |= MGf_DUP;
        rv = sv_2mortal(newRV_noinc(inner));
        sv_bless(rv, gv_stashpvs("HAMT::Vector::Transient", GV_ADD));
        ST(0) = rv;
        XSRETURN(1);

void
_check(self)
        SV *self
    PREINIT:
        hamt_vec *v;
    CODE:
        v = hamt_vec_handle(aTHX_ self, "HAMT::Vector::_check");
        ST(0) = sv_2mortal(newSViv((IV)hamt_vec_check(v)));
        XSRETURN(1);

void
CLONE_SKIP(...)
    CODE:
        ST(0) = &PL_sv_yes;
        XSRETURN(1);
