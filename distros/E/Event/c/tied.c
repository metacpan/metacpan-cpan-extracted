static struct pe_watcher_vtbl pe_tied_vtbl;

static pe_watcher *pe_tied_allocate(HV *stash, SV *temple) {
    pe_tied *ev;
    EvNew(6, ev, 1, pe_tied);
    ev->base.vtbl = &pe_tied_vtbl;
    if (!stash) croak("tied_allocate(0)");
    pe_watcher_init(&ev->base, stash, temple);
    PE_RING_INIT(&ev->tm.ring, ev);
    return (pe_watcher*) ev;
}

static void pe_tied_dtor(pe_watcher *ev) {
    pe_watcher_dtor(ev);
    EvFree(6, ev);
}

static char *pe_tied_start(pe_watcher *ev, int repeat) {
    HV *stash = SvSTASH(SvRV(ev->mysv));
    GV *gv;
    dSP;
    assert(stash);
    PUSHMARK(SP);
    XPUSHs(watcher_2sv(ev));
    XPUSHs(boolSV(repeat));
    PUTBACK;
    gv = gv_fetchmethod(stash, "_start");
    if (!gv)
	croak("Cannot find %s->_start()", HvNAME(stash));
    perl_call_sv((SV*)GvCV(gv), G_DISCARD);
    /* allow return of error! XXX */
    return 0;
}

static void pe_tied_stop(pe_watcher *ev) {
    HV *stash = SvSTASH(SvRV(ev->mysv));
    GV *gv = gv_fetchmethod(stash, "_stop");
    pe_timeable_stop(&((pe_tied*)ev)->tm);
    if (gv) {
	dSP;
	PUSHMARK(SP);
	XPUSHs(watcher_2sv(ev));
	PUTBACK;
	perl_call_sv((SV*)GvCV(gv), G_DISCARD);
    }
}

static void pe_tied_alarm(pe_watcher *ev, pe_timeable *_ign) {
    HV *stash = SvSTASH(SvRV(ev->mysv));
    GV *gv;
    dSP;
    PUSHMARK(SP);
    XPUSHs(watcher_2sv(ev));
    PUTBACK;
    gv = gv_fetchmethod(stash, "_alarm");
    if (!gv)
	croak("Cannot find %s->_alarm()", HvNAME(stash));
    perl_call_sv((SV*)GvCV(gv), G_DISCARD);
}

WKEYMETH(_tied_at) {
    pe_tied *tp = (pe_tied*) ev;
    if (nval) {
	pe_timeable_stop(&tp->tm);
	if (SvOK(nval)) {
	    tp->tm.at = SvNV(nval);
	    pe_timeable_start(&tp->tm);
	}
    }
    {
	dSP;
	XPUSHs(sv_2mortal(newSVnv(tp->tm.at)));
	PUTBACK;
    }
}

WKEYMETH(_tied_flags) {
    if (nval) {
	IV nflags = SvIV(nval);
	IV flip = nflags ^ ev->flags;
	IV other = flip & ~(PE_INVOKE1);
	if (flip & PE_INVOKE1) {
	    if (nflags & PE_INVOKE1) WaINVOKE1_on(ev); else WaINVOKE1_off(ev);
	}
	if (other)
	    warn("Other flags (0x%x) cannot be changed", other);
    }
    {
	dSP;
	XPUSHs(sv_2mortal(newSViv(ev->flags & PE_VISIBLE_FLAGS)));
	PUTBACK;
    }
}

static void boot_tied() {
    pe_watcher_vtbl *vt = &pe_tied_vtbl;
    memcpy(vt, &pe_watcher_base_vtbl, sizeof(pe_watcher_base_vtbl));
    vt->did_require = 1; /* otherwise tries to autoload Event::Event! */
    vt->dtor = pe_tied_dtor;
    vt->start = pe_tied_start;
    vt->stop = pe_tied_stop;
    vt->alarm = pe_tied_alarm;
    pe_register_vtbl(vt, gv_stashpv("Event::Watcher::Tied",1), &event_vtbl);
}
