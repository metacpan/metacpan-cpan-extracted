static struct pe_watcher_vtbl pe_io_vtbl;

static pe_ring IOWatch;
static int IOWatchCount;
static int IOWatch_OK;

static void pe_sys_io_add (pe_io *ev);
static void pe_sys_io_del (pe_io *ev);

static pe_watcher *pe_io_allocate(HV *stash, SV *temple) {
    pe_io *ev;
    EvNew(4, ev, 1, pe_io);
    ev->base.vtbl = &pe_io_vtbl;
    pe_watcher_init(&ev->base, stash, temple);
    PE_RING_INIT(&ev->tm.ring, ev);
    PE_RING_INIT(&ev->ioring, ev);
    ev->fd = -1;
    ev->timeout = 0;
    ev->handle = &PL_sv_undef;
    ev->poll = PE_R;
    ev->tm_callback = 0;
    ev->tm_ext_data = 0;
    WaINVOKE1_off(ev);
    WaREPEAT_on(ev);
    return (pe_watcher*) ev;
}

static void pe_io_dtor(pe_watcher *_ev) {
    pe_io *ev = (pe_io*) _ev;
    if (WaTMPERLCB(ev))
	SvREFCNT_dec(ev->tm_callback);
    PE_RING_DETACH(&ev->ioring);
    SvREFCNT_dec(ev->handle);
    pe_watcher_dtor(_ev);
    EvFree(4, _ev);
}

static char *pe_io_start(pe_watcher *_ev, int repeat) {
    STRLEN n_a;
    int ok=0;
    pe_io *ev = (pe_io*) _ev;
    if (SvOK(ev->handle))
	ev->fd = pe_sys_fileno(ev->handle, SvPV(ev->base.desc, n_a));

    /* On Unix, it is possible to set the 'fd' in C code without
       assigning anything to the 'handle'.  This should be more
       officially supported but maybe it is too unix specific. */

    if (ev->fd >= 0 && (ev->poll & ~PE_T)) {
	if (!ev->base.callback)
	    return "without io callback";
	PE_RING_UNSHIFT(&ev->ioring, &IOWatch);
	pe_sys_io_add(ev);
	++IOWatchCount;
	IOWatch_OK = 0;
	++ok;
    }
    if (ev->timeout) {
	if (!ev->base.callback && !ev->tm_callback) {
	    assert(!ok);
	    return "without timeout callback";
	}
	ev->poll |= PE_T;
	ev->tm.at = NVtime() + ev->timeout;  /* too early okay */
	pe_timeable_start(&ev->tm);
	++ok;
    } else {
	ev->poll &= ~PE_T;
    }
    return ok? 0 : "because there is nothing to watch";
}

static void pe_io_stop(pe_watcher *_ev) {
    pe_io *ev = (pe_io*) _ev;
    pe_timeable_stop(&ev->tm);
    if (!PE_RING_EMPTY(&ev->ioring)) {
        pe_sys_io_del(ev);
	PE_RING_DETACH(&ev->ioring);
	--IOWatchCount;
	IOWatch_OK = 0;
    }
}

static void pe_io_alarm(pe_watcher *_wa, pe_timeable *hit) {
    pe_io *wa = (pe_io*) _wa;
    NV now = NVtime();
    NV left = (_wa->cbtime + wa->timeout) - now;
    if (left < IntervalEpsilon) {
	pe_ioevent *ev;
	if (WaREPEAT(wa)) {
	    wa->tm.at = now + wa->timeout;
	    pe_timeable_start(&wa->tm);
	} else {
	  wa->timeout = 0; /*RESET*/
	}
	ev = (pe_ioevent*) (*_wa->vtbl->new_event)(_wa);
	++ev->base.hits;
	ev->got |= PE_T;
	if (wa->tm_callback) {
	    if (WaTMPERLCB(wa)) {
		pe_anyevent_set_perl_cb(&ev->base, wa->tm_callback);
	    } else {
		pe_anyevent_set_cb(&ev->base, wa->tm_callback, wa->tm_ext_data);
	    }
	}
	queueEvent((pe_event*) ev);
    }
    else {
	/* ++TimeoutTooEarly;
	   This branch is normal behavior and does not indicate
	   poor clock accuracy. */
	wa->tm.at = now + left;
	pe_timeable_start(&wa->tm);
    }
}

static void _io_restart(pe_watcher *ev) {
    if (!WaPOLLING(ev)) return;
    pe_watcher_off(ev);
    pe_watcher_on(ev, 0);
}

static void pe_io_reset_handle(pe_watcher *ev) {  /* used by unix_io */
    pe_io *io = (pe_io*)ev;
    SvREFCNT_dec(io->handle);
    io->handle = &PL_sv_undef;
    io->fd = -1;
    _io_restart(ev);
}

WKEYMETH(_io_poll) {
    pe_io *io = (pe_io*)ev;
    if (nval) {
	int nev = sv_2events_mask(nval, PE_R|PE_W|PE_E|PE_T);
	if (io->timeout) nev |=  PE_T;
	else             nev &= ~PE_T;
	if (io->poll != nev) {
	    io->poll = nev;
	    _io_restart(ev);
	}
    }
    {
	dSP;
	XPUSHs(sv_2mortal(events_mask_2sv(io->poll)));
	PUTBACK;
    }
}

WKEYMETH(_io_handle) {
    pe_io *io = (pe_io*)ev;
    if (nval) {
	SV *old = io->handle;
	io->handle = SvREFCNT_inc(nval);
	SvREFCNT_dec(old);
	io->fd = -1;
	_io_restart(ev);
    }
    {
	dSP;
	XPUSHs(io->handle);
	PUTBACK;
    }
}

WKEYMETH(_io_timeout) {
    pe_io *io = (pe_io*)ev;
    if (nval) {
	io->timeout = SvOK(nval)? SvNV(nval) : 0;  /*undef is ok*/
	_io_restart(ev);
    }
    {
	dSP;
	XPUSHs(sv_2mortal(newSVnv(io->timeout)));
	PUTBACK;
    }
}

WKEYMETH(_io_timeout_cb) {
    pe_io *io = (pe_io*)ev;
    if (nval) {
	AV *av;
	SV *sv;
	SV *old=0;
	if (WaTMPERLCB(ev))
	    old = (SV*) io->tm_callback;
	if (!SvOK(nval)) {
	    WaTMPERLCB_off(ev);
	    io->tm_callback = 0;
	    io->tm_ext_data = 0;
	} else if (SvROK(nval) && (SvTYPE(sv=SvRV(nval)) == SVt_PVCV)) {
	    WaTMPERLCB_on(ev);
	    io->tm_callback = SvREFCNT_inc(nval);
	} else if (SvROK(nval) &&
		   (SvTYPE(av=(AV*)SvRV(nval)) == SVt_PVAV) &&
		   av_len(av) == 1 &&
		   !SvROK(sv=*av_fetch(av, 1, 0))) {
	    WaTMPERLCB_on(ev);
	    io->tm_callback = SvREFCNT_inc(nval);
	} else {
	    if (SvIV(DebugLevel) >= 2)
		sv_dump(sv);
	    croak("Callback must be a code ref or [$object, $method_name]");
	}
	if (old)
	    SvREFCNT_dec(old);
    }
    {
	SV *ret = (WaTMPERLCB(ev)?
		   (SV*) io->tm_callback :
		   (io->tm_callback?
		    sv_2mortal(newSVpvf("<FPTR=0x%p EXT=0x%p>",
					io->tm_callback, io->tm_ext_data)) :
		    &PL_sv_undef));
	dSP;
	XPUSHs(ret);
	PUTBACK;
    }
}

static void boot_io() {
    pe_watcher_vtbl *vt = &pe_io_vtbl;
    memcpy(vt, &pe_watcher_base_vtbl, sizeof(pe_watcher_base_vtbl));
    vt->dtor = pe_io_dtor;
    vt->start = pe_io_start;
    vt->stop = pe_io_stop;
    vt->alarm = pe_io_alarm;
    PE_RING_INIT(&IOWatch, 0);
    IOWatch_OK = 0;
    IOWatchCount = 0;
    pe_register_vtbl(vt, gv_stashpv("Event::io",1), &ioevent_vtbl);
}
