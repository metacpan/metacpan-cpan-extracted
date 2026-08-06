MODULE = Hyperman		PACKAGE = Hyperman::Loop

# The per-worker event loop, standalone. Callback watchers plus
# the Future-returning primitives; run is re-entrant (await pumps it).

SV *
new(class, ...)
    SV *class
    CODE:
    {
        const char *bname = (items > 1 && SvOK(ST(1))) ? SvPV_nolen(ST(1)) : NULL;
        hm_loop *loop = hm_loop_new(aTHX_ bname);
        PERL_UNUSED_VAR(class);
        if (!loop) croak("Hyperman::Loop: no usable event backend%s%s",
                         bname ? " named " : "", bname ? bname : "");
        loop->perl_owned = 1;
        RETVAL = hm_loop_to_sv(aTHX_ loop);
    }
    OUTPUT:
        RETVAL

void
run(self)
    SV *self
    CODE:
        hm_loop_run(aTHX_ hm_loop_from_sv(aTHX_ self), NULL);

void
run_until(self, future)
    SV *self
    SV *future
    CODE:
        if (!hmf_is_future(aTHX_ future))
            croak("run_until: not a Hyperman::Future");
        hm_loop_run(aTHX_ hm_loop_from_sv(aTHX_ self), future);

void
stop(self)
    SV *self
    CODE:
        hm_loop_from_sv(aTHX_ self)->stop = 1;

# Persistent callback watcher; returns a watcher handle for unwatch_io.
SV *
watch_io(self, fh, mode, cb)
    SV *self
    SV *fh
    SV *mode
    SV *cb
    CODE:
    {
        hm_loop *loop = hm_loop_from_sv(aTHX_ self);
        int fd = hm_fd_of(aTHX_ fh);
        const char *m = SvOK(mode) ? SvPV_nolen(mode) : "r";
        AV *handle = newAV();
        hm_add_io_watch(aTHX_ loop, fd, m, cb, 1);
        av_push(handle, newSViv(fd));
        av_push(handle, newSVpv(m, 0));
        RETVAL = newRV_noinc((SV *)handle);
    }
    OUTPUT:
        RETVAL

# Remove a watcher: takes the watch_io handle, or ($fh_or_fd, $mode).
void
unwatch_io(self, watcher, ...)
    SV *self
    SV *watcher
    CODE:
    {
        hm_loop *loop = hm_loop_from_sv(aTHX_ self);
        int fd;
        const char *m = "r";
        if (SvROK(watcher) && SvTYPE(SvRV(watcher)) == SVt_PVAV
            && !SvOBJECT(SvRV(watcher))) {
            AV *h = (AV *)SvRV(watcher);
            SV **f = av_fetch(h, 0, 0);
            SV **mo = av_fetch(h, 1, 0);
            fd = f ? (int)SvIV(*f) : -1;
            if (mo && SvOK(*mo)) m = SvPV_nolen(*mo);
        } else {
            fd = hm_fd_of(aTHX_ watcher);
            if (items > 2 && SvOK(ST(2))) m = SvPV_nolen(ST(2));
        }
        hm_del_io_watch(aTHX_ loop, fd,
                        m[0] == 'w' ? HM_EV_WRITE : HM_EV_READ);
    }

# One-shot callback timer.
void
timer(self, secs, cb)
    SV *self
    double secs
    SV *cb
    CODE:
        hm_add_timer_watch(aTHX_ hm_loop_from_sv(aTHX_ self), secs, cb, HM_TW_CB);

# ---- Future-returning primitives ----

SV *
timer_f(self, secs)
    SV *self
    double secs
    CODE:
        RETVAL = hmf_new(aTHX_ "Hyperman::Future");
        hm_add_timer_watch(aTHX_ hm_loop_from_sv(aTHX_ self), secs, RETVAL,
                           HM_TW_FUTURE);
    OUTPUT:
        RETVAL

SV *
readable_f(self, fh)
    SV *self
    SV *fh
    ALIAS:
        writable_f = 1
    CODE:
        RETVAL = hmf_new(aTHX_ "Hyperman::Future");
        hm_add_io_watch(aTHX_ hm_loop_from_sv(aTHX_ self),
                        hm_fd_of(aTHX_ fh), ix ? "w" : "r", RETVAL, 0);
    OUTPUT:
        RETVAL

void
defer(self, cb)
    SV *self
    SV *cb
    CODE:
        av_push(hm_loop_from_sv(aTHX_ self)->deferred, newSVsv(cb));

# Make ->get/->await on pending futures pump this loop when it is not the
# currently running one (scripts and tests; workers need nothing).
SV *
install_await(self)
    SV *self
    CODE:
    {
        SV *cb = hm_closure(aTHX_ hm_xs_await_cb, self, NULL, NULL, NULL, 0, 0);
        SV *aw = get_sv("Hyperman::Future::AWAIT", GV_ADD);
        sv_setsv(aw, cb);
        SvREFCNT_dec(cb);
        RETVAL = SvREFCNT_inc(self);
    }
    OUTPUT:
        RETVAL

const char *
backend(self)
    SV *self
    CODE:
        RETVAL = hm_loop_from_sv(aTHX_ self)->be->name;
    OUTPUT:
        RETVAL

void
DESTROY(self)
    SV *self
    CODE:
    {
        hm_loop *loop = hm_loop_from_sv(aTHX_ self);
        if (loop->perl_owned && !loop->running && loop != hm_cur_loop)
            hm_loop_free(aTHX_ loop);
    }
