MODULE = Fetch		PACKAGE = Fetch::_Pool

void
DESTROY(self)
    SV *self
    CODE:
        ft_pool_free(aTHX_ ft_pool_from_sv(aTHX_ self));


MODULE = Fetch		PACKAGE = Fetch::Loop::Standalone

# The vendored standalone event loop: a readiness backend + IO/timer watchers.

SV *
new(class, name = NULL)
    SV         *class
    const char *name
    CODE:
    {
        ft_loop *l = ft_loop_new(aTHX_ name);
        PERL_UNUSED_VAR(class);
        RETVAL = sv_bless(newRV_noinc(newSViv(PTR2IV(l))),
                          gv_stashpv("Fetch::Loop::Standalone", GV_ADD));
    }
    OUTPUT:
        RETVAL

const char *
backend(self)
    SV *self
    CODE:
        RETVAL = ft_loop_from_sv(aTHX_ self)->be->name;
    OUTPUT:
        RETVAL

void
watch_io(self, fh, mode, cb)
    SV *self
    SV *fh
    SV *mode
    SV *cb
    CODE:
        ft_watch_io(aTHX_ ft_loop_from_sv(aTHX_ self),
                    ft_fileno(aTHX_ fh), ft_mode(aTHX_ mode), cb);

void
unwatch_io(self, fh, mode)
    SV *self
    SV *fh
    SV *mode
    CODE:
        ft_unwatch_io(aTHX_ ft_loop_from_sv(aTHX_ self),
                      ft_fileno(aTHX_ fh), ft_mode(aTHX_ mode));

void
timer(self, secs, cb)
    SV     *self
    double  secs
    SV     *cb
    CODE:
        ft_add_timer(aTHX_ ft_loop_from_sv(aTHX_ self), secs, cb, 1);

void
run(self)
    SV *self
    CODE:
        hm_loop_run(aTHX_ ft_loop_from_sv(aTHX_ self), NULL);

void
run_until(self, future)
    SV *self
    SV *future
    CODE:
        if (!(SvROK(future) && sv_derived_from(future, "Fetch::Future")))
            croak("run_until: not a Fetch::Future");
        hm_loop_run(aTHX_ ft_loop_from_sv(aTHX_ self), future);

void
stop(self)
    SV *self
    CODE:
        ft_loop_from_sv(aTHX_ self)->stop = 1;

void
DESTROY(self)
    SV *self
    CODE:
        ft_loop_free(aTHX_ ft_loop_from_sv(aTHX_ self));
