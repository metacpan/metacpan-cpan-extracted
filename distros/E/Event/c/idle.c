static struct pe_watcher_vtbl pe_idle_vtbl;
static pe_ring Idle;

/*#define D_IDLE(x) x  /**/
#define D_IDLE(x)  /**/

static pe_watcher *pe_idle_allocate(HV *stash, SV *temple) {
    pe_idle *ev;
    EvNew(3, ev, 1, pe_idle);
    ev->base.vtbl = &pe_idle_vtbl;
    pe_watcher_init(&ev->base, stash, temple);
    PE_RING_INIT(&ev->tm.ring, ev);
    PE_RING_INIT(&ev->iring, ev);
    ev->max_interval = &PL_sv_undef;
    ev->min_interval = newSVnv(.01);
    return (pe_watcher*) ev;
}

static void pe_idle_dtor(pe_watcher *ev) {
    pe_idle *ip = (pe_idle*) ev;
    SvREFCNT_dec(ip->max_interval);
    SvREFCNT_dec(ip->min_interval);
    pe_watcher_dtor(ev);
    EvFree(3, ev);
}

static char *pe_idle_start(pe_watcher *ev, int repeating) {
    NV now;
    NV min,max;
    pe_idle *ip = (pe_idle*) ev;
    if (!ev->callback)
	return "without callback";
    if (!repeating) ev->cbtime = NVtime();
    now = WaHARD(ev)? ev->cbtime : NVtime();
    if (sv_2interval("min", ip->min_interval, &min)) {
	ip->tm.at = min + now;
	pe_timeable_start(&ip->tm);
	D_IDLE(warn("min %.2f setup '%s'\n", min, SvPV(ev->desc,na)));
    }
    else {
	PE_RING_UNSHIFT(&ip->iring, &Idle);
	D_IDLE(warn("idle '%s'\n", SvPV(ev->desc,na)));
	if (sv_2interval("max", ip->max_interval, &max)) {
	    D_IDLE(warn("max %.2f setup '%s'\n", max, SvPV(ev->desc,na)));
	    ip->tm.at = max + now;
	    pe_timeable_start(&ip->tm);
	}
    }
    return 0;
}

static void pe_idle_alarm(pe_watcher *wa, pe_timeable *_ignore) {
    NV now = NVtime();
    NV min,max,left;
    pe_idle *ip = (pe_idle*) wa;
    pe_timeable_stop(&ip->tm);
    if (sv_2interval("min", ip->min_interval, &min)) {
	left = wa->cbtime + min - now;
	if (left > IntervalEpsilon) {
	    ++TimeoutTooEarly;
	    ip->tm.at = now + left;
	    pe_timeable_start(&ip->tm);
	    D_IDLE(warn("min %.2f '%s'\n", left, SvPV(wa->desc,na)));
	    return;
	}
    }
    if (PE_RING_EMPTY(&ip->iring)) {
	PE_RING_UNSHIFT(&ip->iring, &Idle);
	D_IDLE(warn("idle '%s'\n", SvPV(wa->desc,na)));
    }
    if (sv_2interval("max", ip->max_interval, &max)) {
	left = wa->cbtime + max - now;
	if (left < IntervalEpsilon) {
	    pe_event *ev;
	    D_IDLE(warn("max '%s'\n", SvPV(wa->desc,na)));
	    PE_RING_DETACH(&ip->iring);
	    ev = (*wa->vtbl->new_event)(wa);
	    ++ev->hits;
	    queueEvent(ev);
	    return;
	}
	else {
	    ++TimeoutTooEarly;
	    ip->tm.at = now + left;
	    D_IDLE(warn("max %.2f '%s'\n", left, SvPV(wa->desc,na)));
	    pe_timeable_start(&ip->tm);
	}
    }
}

static void pe_idle_stop(pe_watcher *ev) {
    pe_idle *ip = (pe_idle*) ev;
    PE_RING_DETACH(&ip->iring);
    pe_timeable_stop(&ip->tm);
}

WKEYMETH(_idle_max_interval) {
    pe_idle *ip = (pe_idle*) ev;
    if (nval) {
	SV *old = ip->max_interval;
	ip->max_interval = SvREFCNT_inc(nval);
	if (old) SvREFCNT_dec(old);
	VERIFYINTERVAL("max", ip->max_interval);
    }
    {
	dSP;
	XPUSHs(ip->max_interval);
	PUTBACK;
    }
}

WKEYMETH(_idle_min_interval) {
    pe_idle *ip = (pe_idle*) ev;
    if (nval) {
	SV *old = ip->min_interval;
	ip->min_interval = SvREFCNT_inc(nval);
	if (old) SvREFCNT_dec(old);
	VERIFYINTERVAL("min", ip->min_interval);
    }
    {
	dSP;
	XPUSHs(ip->min_interval);
	PUTBACK;
    }
}

static void boot_idle() {
    pe_watcher_vtbl *vt = &pe_idle_vtbl;
    PE_RING_INIT(&Idle, 0);
    memcpy(vt, &pe_watcher_base_vtbl, sizeof(pe_watcher_base_vtbl));
    vt->dtor = pe_idle_dtor;
    vt->start = pe_idle_start;
    vt->stop = pe_idle_stop;
    vt->alarm = pe_idle_alarm;
    pe_register_vtbl(vt, gv_stashpv("Event::idle",1), &event_vtbl);
}
