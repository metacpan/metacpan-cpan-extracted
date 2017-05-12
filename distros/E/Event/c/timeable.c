static pe_timeable Timeables;

/*#define D_TIMEABLE(x) x /**/
#define D_TIMEABLE(x) /**/

static void db_show_timeables()
{
  pe_timeable *tm = (pe_timeable*) Timeables.ring.next;
  warn("timeables at %.2f\n", NVtime() + IntervalEpsilon);
  while (tm->ring.self) {
    STRLEN n_a;
    pe_watcher *wa = (pe_watcher*) tm->ring.self;
    pe_timeable *next = (pe_timeable*) tm->ring.next;
    warn("  %.2f '%s'\n", tm->at, SvPV(wa->desc, n_a));
    tm = next;
  }
}

static void pe_timeables_check() {
    pe_timeable *tm = (pe_timeable*) Timeables.ring.next;
    NV now = NVtime() + IntervalEpsilon;
    /*db_show_timeables();/**/
    while (tm->ring.self && now >= tm->at) {
	pe_watcher *ev = (pe_watcher*) tm->ring.self;
	pe_timeable *next = (pe_timeable*) tm->ring.next;
	D_TIMEABLE({
	    if (WaDEBUGx(ev) >= 4) {
		STRLEN n_a;
		warn("Event: timeable expire '%s'\n", SvPV(ev->desc, n_a));
	    }
	})
	    assert(!WaSUSPEND(ev));
	assert(WaACTIVE(ev));
	PE_RING_DETACH(&tm->ring);
	(*ev->vtbl->alarm)(ev, tm);
	tm = next;
    }
}

static NV timeTillTimer() {
    pe_timeable *tm = (pe_timeable*) Timeables.ring.next;
    if (!tm->ring.self)
	return 3600;
    return tm->at - NVtime();
}

static void pe_timeable_start(pe_timeable *tm) {
    /* OPTIMIZE! */
    pe_watcher *ev = (pe_watcher*) tm->ring.self;
    pe_timeable *rg = (pe_timeable*) Timeables.ring.next;
    assert(!WaSUSPEND(ev));
    assert(PE_RING_EMPTY(&tm->ring));
    if (WaDEBUGx(ev)) {
	NV left = tm->at - NVtime();
	if (left < 0) {
	    STRLEN n_a;
	    warn("Event: timer for '%s' set to expire immediately (%.2f)",
		 SvPV(ev->desc, n_a), left);
	}
    }
    while (rg->ring.self && rg->at < tm->at) {
	rg = (pe_timeable*) rg->ring.next;
    }
    /*warn("-- adding 0x%x:\n", ev); db_show_timeables();/**/
    PE_RING_ADD_BEFORE(&tm->ring, &rg->ring);
    /*warn("T:\n"); db_show_timeables();/**/
    D_TIMEABLE({
	if (WaDEBUGx(ev) >= 4) {
	    STRLEN n_a;
	    warn("Event: timeable start '%s'\n", SvPV(ev->desc, n_a));
	}
    })
}

static void pe_timeable_stop(pe_timeable *tm) {
    D_TIMEABLE({
	pe_watcher *ev = (pe_watcher*) tm->ring.self;
	if (WaDEBUGx(ev) >= 4) {
	    STRLEN n_a;
	    warn("Event: timeable stop '%s'\n", SvPV(ev->desc, n_a));
	}
    })
    PE_RING_DETACH(&tm->ring);
}

static void pe_timeable_adjust(NV delta) {
    pe_timeable *rg = (pe_timeable*) Timeables.ring.next;
    while (rg != &Timeables) {
	rg->at += delta;
	rg = (pe_timeable*) rg->ring.next;
    }
}

WKEYMETH(_timeable_hard) { /* applies to all timers in a watcher; is ok? */
    if (nval) {
	if (sv_true(nval)) WaHARD_on(ev); else WaHARD_off(ev);
    }
    {
	dSP;
	XPUSHs(boolSV(WaHARD(ev)));
	PUTBACK;
    }
}

static void boot_timeable() {
    PE_RING_INIT(&Timeables.ring, 0);
}
