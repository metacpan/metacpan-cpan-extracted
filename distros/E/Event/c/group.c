static struct pe_watcher_vtbl pe_group_vtbl;

static pe_watcher *pe_group_allocate(HV *stash, SV *temple) {
    pe_group *ev;
    EvNew(12, ev, 1, pe_group);
    ev->base.vtbl = &pe_group_vtbl;
    PE_RING_INIT(&ev->tm.ring, ev);
    ev->tm.at = 0;
    ev->timeout = &PL_sv_undef;
    ev->members = 3;
    EvNew(13, ev->member, ev->members, pe_watcher*);
    Zero(ev->member, ev->members, pe_watcher*);
    pe_watcher_init(&ev->base, stash, temple);
    WaREPEAT_on(ev);
    return (pe_watcher*) ev;
}

static void pe_group_dtor(pe_watcher *ev) {
    int xx;
    pe_group *gp = (pe_group*) ev;
    SvREFCNT_dec(gp->timeout);
    for (xx=0; xx < gp->members; xx++) {
	pe_watcher *mb = gp->member[xx];
	if (mb)
	    --mb->refcnt;
    }
    EvFree(13, gp->member);
    pe_watcher_dtor(ev);
    EvFree(12, ev);
}

static char *pe_group_start(pe_watcher *ev, int repeat) {
    pe_group *gp = (pe_group*) ev;
    NV timeout;

    if (!ev->callback)
	return "without callback";
    if (!sv_2interval("group", gp->timeout, &timeout))
	return "repeating group has no timeout";

    gp->since = WaHARD(ev)? gp->tm.at : NVtime();
    gp->tm.at = timeout + gp->since;
    pe_timeable_start(&gp->tm);
    return 0;
}

static void pe_group_stop(pe_watcher *ev)
{ pe_timeable_stop(&((pe_group*)ev)->tm); }

static void pe_group_alarm(pe_watcher *wa, pe_timeable *tm) {
    STRLEN n_a;
    pe_group *gp = (pe_group*) wa;
    NV timeout;
    NV remaining;
    NV now = NVtime();
    int xx;
    for (xx=0; xx < gp->members; xx++) {
	pe_watcher *mb = gp->member[xx];
	if (!mb) continue;
	if (gp->since < mb->cbtime) {
	    gp->since = mb->cbtime;
	}
    }

    if (!sv_2interval("group", gp->timeout, &timeout))
	croak("Event: can't extract timeout"); /* impossible */

    remaining = gp->since + timeout - now;
    if (remaining > IntervalEpsilon) {
	gp->tm.at = now + remaining;
	pe_timeable_start(&gp->tm);
    } else {
	pe_event *ev = (*wa->vtbl->new_event)(wa);
	++ev->hits;
	queueEvent(ev);
    }
}

/* publish C API XXX */
static void pe_group_add(pe_group *gp, pe_watcher *wa) {
    int ok=0;
    int xx;
    if (gp == (pe_group*) wa) {
	STRLEN n_a;
	croak("Event: can't add group '%s' to itself",
	      SvPV(gp->base.desc, n_a));
    }
    ++wa->refcnt;
    for (xx=0; xx < gp->members; xx++) {
	if (!gp->member[xx]) {
	    gp->member[xx] = wa;
	    ok=1; break;
	}
    }
    if (!ok) {  /* expand array */
	pe_watcher **ary;
	EvNew(13, ary, gp->members*2, pe_watcher*);
	Zero(ary, gp->members*2, pe_watcher*);
	Copy(gp->member, ary, gp->members, sizeof(pe_watcher*));
	EvFree(13, gp->member);
	gp->member = ary;
	gp->member[gp->members] = wa;
	gp->members *= 2;
    }
}

static void pe_group_del(pe_group *gp, pe_watcher *target) {
    int xx;
    for (xx=0; xx < gp->members; xx++) {
	if (gp->member[xx] != target)
	    continue;
	--target->refcnt;
	gp->member[xx] = 0;
	break;
    }
}

WKEYMETH(_group_timeout) {
    pe_group *gp = (pe_group*)ev;
    if (nval) {
	SV *old = gp->timeout;
	gp->timeout = SvREFCNT_inc(nval);
	SvREFCNT_dec(old);
	VERIFYINTERVAL("group", gp->timeout);
	/* recalc expiration XXX */
    }
    {
	dSP;
	XPUSHs(gp->timeout);
	PUTBACK;
    }
}

WKEYMETH(_group_add) {
    pe_group *gp = (pe_group*)ev;
    if (!nval)
	return;
    pe_group_add(gp, sv_2watcher(nval));
}

WKEYMETH(_group_del) {
    pe_group *gp = (pe_group*)ev;
    if (!nval)
	return;
    pe_group_del(gp, sv_2watcher(nval));
}

static void boot_group() {
    pe_watcher_vtbl *vt = &pe_group_vtbl;
    memcpy(vt, &pe_watcher_base_vtbl, sizeof(pe_watcher_base_vtbl));
    vt->dtor = pe_group_dtor;
    vt->start = pe_group_start;
    vt->stop = pe_group_stop;
    vt->alarm = pe_group_alarm;
    pe_register_vtbl(vt, gv_stashpv("Event::group",1), &event_vtbl);
}
