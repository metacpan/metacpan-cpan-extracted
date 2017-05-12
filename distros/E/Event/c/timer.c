static struct pe_watcher_vtbl pe_timer_vtbl;

static pe_watcher *pe_timer_allocate(HV *stash, SV *temple) {
    pe_timer *ev;
    EvNew(7, ev, 1, pe_timer);
    assert(ev);
    ev->base.vtbl = &pe_timer_vtbl;
    PE_RING_INIT(&ev->tm.ring, ev);
    ev->tm.at = 0;
    ev->interval = &PL_sv_undef;
    pe_watcher_init(&ev->base, stash, temple);
    return (pe_watcher*) ev;
}

static void pe_timer_dtor(pe_watcher *ev) {
    pe_timer *tm = (pe_timer*) ev;
    SvREFCNT_dec(tm->interval);
    pe_watcher_dtor(ev);
    EvFree(7, ev);
}

static char *pe_timer_start(pe_watcher *ev, int repeat) {
    STRLEN n_a;
    pe_timer *tm = (pe_timer*) ev;
    if (!ev->callback)
	return "without callback";
    if (repeat) {
	/* We just finished the callback and need to re-insert at
	   the appropriate time increment. */
	NV interval;

	if (!sv_2interval("timer", tm->interval, &interval))
	    return "repeating timer has no interval";

	tm->tm.at = interval + (WaHARD(ev)? tm->tm.at : NVtime());
    }
    if (!tm->tm.at)
	return "timer unset";

    pe_timeable_start(&tm->tm);
    return 0;
}

static void pe_timer_stop(pe_watcher *ev)
{ pe_timeable_stop(&((pe_timer*)ev)->tm); }

static void pe_timer_alarm(pe_watcher *wa, pe_timeable *tm) {
    pe_event *ev = (*wa->vtbl->new_event)(wa);
    ++ev->hits;
    queueEvent(ev);
}

WKEYMETH(_timer_at) {
    pe_timer *tp = (pe_timer*)ev;
    if (nval) {
	int active = WaPOLLING(ev);
	if (active) pe_watcher_off(ev);
	tp->tm.at = SvNV(nval);
	if (active) pe_watcher_on(ev, 0);
    }
    {
	dSP;
	XPUSHs(sv_2mortal(newSVnv(tp->tm.at)));
	PUTBACK;
    }
}

WKEYMETH(_timer_interval) {
    pe_timer *tp = (pe_timer*)ev;
    if (nval) {
	SV *old = tp->interval;
	tp->interval = SvREFCNT_inc(nval);
	SvREFCNT_dec(old);
	VERIFYINTERVAL("timer", tp->interval);
	/* recalc expiration XXX */
    }
    {
	dSP;
	XPUSHs(tp->interval);
	PUTBACK;
    }
}

static void boot_timer() {
    pe_watcher_vtbl *vt = &pe_timer_vtbl;
    memcpy(vt, &pe_watcher_base_vtbl, sizeof(pe_watcher_base_vtbl));
    vt->dtor = pe_timer_dtor;
    vt->start = pe_timer_start;
    vt->stop = pe_timer_stop;
    vt->alarm = pe_timer_alarm;
    pe_register_vtbl(vt, gv_stashpv("Event::timer",1), &event_vtbl);
}
