MODULE = Hyperman		PACKAGE = Hyperman::Future

# Native array-slot Future, fully XS: creation, resolution,
# callbacks, chaining, combinators, and CPAN Future interop. Continuations
# are C closures (hm_future.h) trampolined through the fire queue.

SV *
new(class)
    SV *class
    CODE:
    {
        const char *name;
        if (SvROK(class) && SvOBJECT(SvRV(class)))
            name = HvNAME(SvSTASH(SvRV(class)));
        else
            name = SvPV_nolen(class);
        RETVAL = hmf_new(aTHX_ name);
    }
    OUTPUT:
        RETVAL

SV *
done(self, ...)
    SV *self
    CODE:
        if (hmf_state(aTHX_ self) == HMF_PENDING)
            hmf_settle(aTHX_ self, HMF_DONE, &ST(1), items - 1);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV *
fail(self, ...)
    SV *self
    CODE:
        if (hmf_state(aTHX_ self) == HMF_PENDING) {
            if (items > 1) {
                hmf_settle(aTHX_ self, HMF_FAILED, &ST(1), items - 1);
            } else {
                SV *def = sv_2mortal(newSVpvs("Failed\n"));
                hmf_settle(aTHX_ self, HMF_FAILED, &def, 1);
            }
        }
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV *
done_future(class, ...)
    SV *class
    CODE:
    {
        const char *name = SvROK(class) ? HvNAME(SvSTASH(SvRV(class)))
                                        : SvPV_nolen(class);
        RETVAL = hmf_new(aTHX_ name);
        hmf_settle(aTHX_ RETVAL, HMF_DONE, &ST(1), items - 1);
    }
    OUTPUT:
        RETVAL

SV *
fail_future(class, ...)
    SV *class
    CODE:
    {
        const char *name = SvROK(class) ? HvNAME(SvSTASH(SvRV(class)))
                                        : SvPV_nolen(class);
        RETVAL = hmf_new(aTHX_ name);
        if (items > 1) {
            hmf_settle(aTHX_ RETVAL, HMF_FAILED, &ST(1), items - 1);
        } else {
            SV *def = sv_2mortal(newSVpvs("Failed\n"));
            hmf_settle(aTHX_ RETVAL, HMF_FAILED, &def, 1);
        }
    }
    OUTPUT:
        RETVAL

SV *
cancel(self)
    SV *self
    CODE:
        hmf_cancel(aTHX_ self);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

int
is_ready(self)
    SV *self
    CODE:
        RETVAL = hmf_state(aTHX_ self) != HMF_PENDING;
    OUTPUT:
        RETVAL

int
is_done(self)
    SV *self
    CODE:
        RETVAL = hmf_state(aTHX_ self) == HMF_DONE;
    OUTPUT:
        RETVAL

int
is_failed(self)
    SV *self
    CODE:
        RETVAL = hmf_state(aTHX_ self) == HMF_FAILED;
    OUTPUT:
        RETVAL

int
is_cancelled(self)
    SV *self
    CODE:
        RETVAL = hmf_state(aTHX_ self) == HMF_CANCELLED;
    OUTPUT:
        RETVAL

SV *
on_ready(self, cb)
    SV *self
    SV *cb
    CODE:
        hmf_on_ready(aTHX_ self, cb);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

SV *
on_done(self, usercb)
    SV *self
    SV *usercb
    ALIAS:
        on_fail = 1
    CODE:
    {
        SV *cb = hm_closure(aTHX_ hm_xs_ondone_cb, NULL, usercb, NULL, NULL,
                            ix == 0 ? HMF_DONE : HMF_FAILED, 0);
        hmf_on_ready(aTHX_ self, cb);
        SvREFCNT_dec(cb);
        RETVAL = SvREFCNT_inc(self);
    }
    OUTPUT:
        RETVAL

SV *
await(self)
    SV *self
    CODE:
        hmf_await(aTHX_ self);
        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
        RETVAL

void
get(self)
    SV *self
    ALIAS:
        result = 1
    PPCODE:
    {
        IV st;
        PERL_UNUSED_VAR(ix);
        hmf_await(aTHX_ self);
        st = hmf_state(aTHX_ self);
        if (st == HMF_FAILED) {
            AV *fav = hmf_values_av(aTHX_ self);
            SV **e = fav ? av_fetch(fav, 0, 0) : NULL;
            if (e) croak_sv(sv_mortalcopy(*e));
            croak("Failed");
        }
        if (st == HMF_CANCELLED)
            croak("Hyperman::Future was cancelled");
        {
            AV *rav = hmf_values_av(aTHX_ self);
            SSize_t n = rav ? av_len(rav) + 1 : 0;
            if (GIMME_V == G_ARRAY) {
                SSize_t i;
                EXTEND(SP, n);
                for (i = 0; i < n; i++) {
                    SV **e = av_fetch(rav, i, 0);
                    PUSHs(e ? sv_mortalcopy(*e) : &PL_sv_undef);
                }
            } else if (n) {
                SV **e = av_fetch(rav, 0, 0);
                XPUSHs(e ? sv_mortalcopy(*e) : &PL_sv_undef);
            } else {
                XPUSHs(&PL_sv_undef);
            }
        }
    }

void
failure(self)
    SV *self
    PPCODE:
    {
        hmf_await(aTHX_ self);
        if (hmf_state(aTHX_ self) != HMF_FAILED) XSRETURN_EMPTY;
        {
            AV *fav = hmf_values_av(aTHX_ self);
            SSize_t n = fav ? av_len(fav) + 1 : 0;
            if (GIMME_V == G_ARRAY) {
                SSize_t i;
                EXTEND(SP, n);
                for (i = 0; i < n; i++) {
                    SV **e = av_fetch(fav, i, 0);
                    PUSHs(e ? sv_mortalcopy(*e) : &PL_sv_undef);
                }
            } else if (n) {
                SV **e = av_fetch(fav, 0, 0);
                XPUSHs(e ? sv_mortalcopy(*e) : &PL_sv_undef);
            }
        }
    }

# result/failure values as a plain list, no dying, no awaiting.
void
_values(self)
    SV *self
    PPCODE:
    {
        AV *rav = hmf_values_av(aTHX_ self);
        SSize_t i, n = rav ? av_len(rav) + 1 : 0;
        EXTEND(SP, n);
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(rav, i, 0);
            PUSHs(e ? sv_mortalcopy(*e) : &PL_sv_undef);
        }
    }

# ---- chaining ----

SV *
then(self, ...)
    SV *self
    ALIAS:
        else = 1
    CODE:
    {
        SV *on_done = NULL, *on_fail = NULL;
        SV *cb;
        if (ix == 0) {   /* then($ok?, $err?) */
            if (items > 1 && SvOK(ST(1))) on_done = ST(1);
            if (items > 2 && SvOK(ST(2))) on_fail = ST(2);
        } else {         /* else($err) */
            if (items > 1 && SvOK(ST(1))) on_fail = ST(1);
        }
        RETVAL = hmf_new(aTHX_ hmf_class_of(aTHX_ self));
        hmf_set_upstream(aTHX_ RETVAL, self);
        cb = hm_closure(aTHX_ hm_xs_then_cb, RETVAL, on_done, on_fail, NULL, 0, 0);
        hmf_on_ready(aTHX_ self, cb);
        SvREFCNT_dec(cb);
    }
    OUTPUT:
        RETVAL

SV *
followed_by(self, usercb)
    SV *self
    SV *usercb
    CODE:
    {
        SV *cb;
        RETVAL = hmf_new(aTHX_ hmf_class_of(aTHX_ self));
        hmf_set_upstream(aTHX_ RETVAL, self);
        cb = hm_closure(aTHX_ hm_xs_then_cb, RETVAL, usercb, NULL, NULL, 1, 0);
        hmf_on_ready(aTHX_ self, cb);
        SvREFCNT_dec(cb);
    }
    OUTPUT:
        RETVAL

SV *
transform(self, ...)
    SV *self
    CODE:
    {
        SV *xd = NULL, *xf = NULL;
        SV *cb;
        int i;
        if ((items - 1) % 2)
            croak("transform: odd number of arguments");
        for (i = 1; i + 1 < items; i += 2) {
            const char *key = SvPV_nolen(ST(i));
            if (strEQ(key, "done"))      xd = ST(i + 1);
            else if (strEQ(key, "fail")) xf = ST(i + 1);
            else croak("transform: unknown argument '%s'", key);
        }
        RETVAL = hmf_new(aTHX_ hmf_class_of(aTHX_ self));
        hmf_set_upstream(aTHX_ RETVAL, self);
        cb = hm_closure(aTHX_ hm_xs_transform_cb, RETVAL, xd, xf, NULL, 0, 0);
        hmf_on_ready(aTHX_ self, cb);
        SvREFCNT_dec(cb);
    }
    OUTPUT:
        RETVAL

# Weakly link $derived to its $upstream for cancel propagation.
void
_set_upstream(derived, upstream)
    SV *derived
    SV *upstream
    CODE:
        hmf_set_upstream(aTHX_ derived, upstream);

# ---- convergent combinators ----

SV *
wait_all(class, ...)
    SV *class
    ALIAS:
        wait_any  = 1
        needs_all = 2
        needs_any = 3
    CODE:
    {
        static const IV modes[4] = { HM_COMB_WAIT_ALL, HM_COMB_WAIT_ANY,
                                     HM_COMB_NEEDS_ALL, HM_COMB_NEEDS_ANY };
        RETVAL = hmf_combine(aTHX_ class, &ST(1), items - 1, modes[ix]);
    }
    OUTPUT:
        RETVAL

# ---- CPAN Future interop ----

SV *
as_cpan_future(self)
    SV *self
    CODE:
    {
        SV *cf, *cb;
        dSP;
        int n;
        load_module(PERL_LOADMOD_NOIMPORT, newSVpvs("Future"), NULL);
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpvs("Future")));
        PUTBACK;
        n = call_method("new", G_SCALAR);
        SPAGAIN;
        cf = n ? SvREFCNT_inc(POPs) : &PL_sv_undef;
        PUTBACK; FREETMPS; LEAVE;
        cb = hm_closure(aTHX_ hm_xs_tocpan_cb, cf, NULL, NULL, NULL, 0, 0);
        hmf_on_ready(aTHX_ self, cb);
        SvREFCNT_dec(cb);
        RETVAL = cf;
    }
    OUTPUT:
        RETVAL

SV *
from_future(class, other)
    SV *class
    SV *other
    CODE:
    {
        const char *name = SvROK(class) ? HvNAME(SvSTASH(SvRV(class)))
                                        : SvPV_nolen(class);
        SV *cb;
        RETVAL = hmf_new(aTHX_ name);
        cb = hm_closure(aTHX_ hm_xs_fromcpan_cb, RETVAL, NULL, NULL, NULL, 0, 0);
        hm_any_on_ready(aTHX_ other, cb);
        SvREFCNT_dec(cb);
    }
    OUTPUT:
        RETVAL
