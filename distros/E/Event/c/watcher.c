static int NextID = 0;
static pe_ring AllWatchers;
static struct pe_watcher_vtbl pe_watcher_base_vtbl;

static void pe_watcher_init(pe_watcher *ev, HV *stash, SV *temple) {
    STRLEN n_a;
    assert(ev);
    assert(ev->vtbl);
    if (!ev->vtbl->stash)
	croak("sub-class VTBL must have a stash (doesn't!)");
    if (!ev->vtbl->did_require) {
	SV *tmp;
	char *name = HvNAME(ev->vtbl->stash);
	dTHX;
	if (memEQ(name, "Event::", 7))
	    name += 7;
	tmp = sv_2mortal(newSVpvf("Event/%s.pm", name));
	perl_require_pv(SvPV(tmp, n_a));
	if (sv_true(ERRSV))
	    croak("Event: could not load perl support code for Event::%s: %s",
		  name, SvPV(ERRSV,n_a));
	++ev->vtbl->did_require;
    }
    /* if we have a non-default stash then we need to save it! */
    ev->mysv = stash || temple ? wrap_watcher(ev, stash, temple) : 0;
    PE_RING_INIT(&ev->all, ev);
    PE_RING_INIT(&ev->events, 0);

    /* no exceptions after this point */

    PE_RING_UNSHIFT(&ev->all, &AllWatchers);
    WaFLAGS(ev) = 0;
    WaINVOKE1_on(ev);
    WaREENTRANT_on(ev);
    ev->FALLBACK = 0;
    NextID = (NextID+1) & 0x7fff; /* make it look like the kernel :-, */
    ev->refcnt = 0;
    ev->desc = newSVpvn("??",2);
    ev->running = 0;
    ev->max_cb_tm = 1;  /* make default configurable? */
    ev->cbtime = 0;
    ev->prio = PE_QUEUES;
    ev->callback = 0;
    ev->ext_data = 0;
    ev->stats = 0;
}

static void pe_watcher_cancel_events(pe_watcher *wa) {
    pe_event *ev;
    while (!PE_RING_EMPTY(&wa->events)) {
	pe_ring *lk = wa->events.prev;
	ev = (pe_event*) lk->self;
	dequeEvent(ev);
	pe_event_release(ev);
    }
}

static void pe_watcher_dtor(pe_watcher *wa) {
    STRLEN n_a;
    assert(WaCANDESTROY(wa));
    if (WaDESTROYED(wa)) {
	warn("Attempt to destroy watcher 0x%x again (ignored)", wa);
	return;
    }
    WaDESTROYED_on(wa);
    if (WaDEBUGx(wa) >= 3)
	warn("Watcher '%s' destroyed", SvPV(wa->desc, n_a));
    assert(PE_RING_EMPTY(&wa->events));
    if (WaPERLCB(wa))
	SvREFCNT_dec(wa->callback);
    if (wa->FALLBACK)
	SvREFCNT_dec(wa->FALLBACK);
    if (wa->desc)
	SvREFCNT_dec(wa->desc);
    if (wa->stats)
	Estat.dtor(wa->stats);
    /* safefree(wa); do it yourself */
}

/********************************** *******************************/

WKEYMETH(_watcher_callback) {
    if (nval) {
	AV *av;
	SV *sv;
	SV *old=0;
	if (WaPERLCB(ev))
	    old = (SV*) ev->callback;
	if (!SvOK(nval)) {
	    WaPERLCB_off(ev);
	    ev->callback = 0;
	    ev->ext_data = 0;
	    pe_watcher_stop(ev, 0);
	} else if (SvROK(nval) && (SvTYPE(sv=SvRV(nval)) == SVt_PVCV)) {
	    WaPERLCB_on(ev);
	    ev->callback = SvREFCNT_inc(nval);
	} else if (SvROK(nval) &&
		   (SvTYPE(av=(AV*)SvRV(nval)) == SVt_PVAV) &&
		   av_len(av) == 1) {
	    /* method lookup code adapted from universal.c */
	    STRLEN n_a;
	    SV *pkgsv = *av_fetch(av, 0, 0);
	    HV *pkg = NULL;
	    SV *namesv = *av_fetch(av, 1, 0);
	    char *name = SvPV(namesv, n_a);
	    int ok=0;
	    if(SvROK(pkgsv)) {
		pkgsv = (SV*)SvRV(pkgsv);
		if(SvOBJECT(pkgsv))
		    pkg = SvSTASH(pkgsv);
	    }
	    else {
		pkg = gv_stashsv(pkgsv, FALSE);
	    }
	    if (pkg) {
		GV *gv = gv_fetchmethod_autoload(pkg, name, FALSE);
		if (gv && isGV(gv))
		    ok=1;
	    }
	    else {
		warn("Event: package '%s' doesn't exist (creating)",
		     SvPV(pkgsv, n_a));
		pkg = gv_stashsv(pkgsv, 1);
	    }
	    if (!ok) {
		warn("Event: callback method %s->%s doesn't exist",
		     HvNAME(pkg), name);
	    }
	    WaPERLCB_on(ev);
	    ev->callback = SvREFCNT_inc(nval);
	} else {
	    if (SvIV(DebugLevel) >= 2)
		sv_dump(sv);
	    croak("Callback must be a code ref or [$object, $method_name]");
	}
	if (old)
	    SvREFCNT_dec(old);
    }
    {
	SV *ret = (WaPERLCB(ev)?
		   (SV*) ev->callback :
		   (ev->callback?
		    sv_2mortal(newSVpvf("<FPTR=0x%p EXT=0x%p>",
					ev->callback, ev->ext_data)) :
		    &PL_sv_undef));
	dSP;
	XPUSHs(ret);
	PUTBACK;
    }
}

WKEYMETH(_watcher_cbtime) {
    if (!nval) {
	dSP;
	XPUSHs(sv_2mortal(newSVnv(ev->cbtime)));
	PUTBACK;
    } else
	croak("'e_cbtime' is read-only");
}

WKEYMETH(_watcher_desc) {
    if (nval) {
	sv_setsv(ev->desc, nval);
    }
    {
	dSP;
	XPUSHs(ev->desc);
	PUTBACK;
    }
}

WKEYMETH(_watcher_debug) {
    if (nval) {
	if (sv_true(nval)) WaDEBUG_on(ev); else WaDEBUG_off(ev);
    }
    {
	dSP;
	XPUSHs(boolSV(WaDEBUG(ev)));
	PUTBACK;
    }
}

WKEYMETH(_watcher_priority) {
    if (nval) {
	ev->prio = SvIV(nval);
    }
    {
	dSP;
	XPUSHs(sv_2mortal(newSViv(ev->prio)));
	PUTBACK;
    }
}

WKEYMETH(_watcher_reentrant) {
    if (nval) {
	if (sv_true(nval))
	    WaREENTRANT_on(ev);
	else {
	    if (ev->running > 1)
		croak("'reentrant' cannot be turned off while nested %d times",
		      ev->running);
	    WaREENTRANT_off(ev);
	}
    }
    {
	dSP;
	XPUSHs(boolSV(WaREENTRANT(ev)));
	PUTBACK;
    }
}

WKEYMETH(_watcher_repeat) {
    if (nval) {
	if (sv_true(nval)) WaREPEAT_on(ev); else WaREPEAT_off(ev);
    }
    {
	dSP;
	XPUSHs(boolSV(WaREPEAT(ev)));
	PUTBACK;
    }
}

WKEYMETH(_watcher_suspend) {
    if (nval) {
	if (sv_true(nval))
	    pe_watcher_suspend(ev);
	else
	    pe_watcher_resume(ev);
    }
    {
	dSP;
	XPUSHs(boolSV(WaSUSPEND(ev)));
	PUTBACK;
    }
}

WKEYMETH(_watcher_max_cb_tm) {
    if (nval) {
	int tm = SvIOK(nval)? SvIV(nval) : 0;
	if (tm < 0) {
	    warn("e_max_cb_tm must be non-negative");
	    tm=0;
	}
	ev->max_cb_tm = tm;
    }
    {
	dSP;
	XPUSHs(sv_2mortal(newSViv(ev->max_cb_tm)));
	PUTBACK;
    }
}

/********************************** *******************************/

static void pe_watcher_nomethod(pe_watcher *ev, char *meth) {
    HV *stash = ev->vtbl->stash;
    assert(stash);
    croak("%s::%s is missing", HvNAME(stash), meth);
}

static char *pe_watcher_nostart(pe_watcher *ev, int repeat)
{ pe_watcher_nomethod(ev,"start"); return 0; }
static void pe_watcher_nostop(pe_watcher *ev)
{ pe_watcher_nomethod(ev,"stop"); }
static void pe_watcher_alarm(pe_watcher *ev, pe_timeable *tm)
{ pe_watcher_nomethod(ev,"alarm"); }

static void boot_pe_watcher() {
    HV *stash = gv_stashpv("Event::Watcher", 1);
    struct pe_watcher_vtbl *vt;
    PE_RING_INIT(&AllWatchers, 0);
    vt = &pe_watcher_base_vtbl;
    vt->stash = 0;
    vt->did_require = 0;
    vt->dtor = 0;
    vt->start = pe_watcher_nostart;
    vt->stop = pe_watcher_nostop;
    vt->alarm = pe_watcher_alarm;
    newCONSTSUB(stash, "ACTIVE", newSViv(PE_ACTIVE));
    newCONSTSUB(stash, "SUSPEND", newSViv(PE_SUSPEND));
    newCONSTSUB(stash, "R", newSViv(PE_R));
    newCONSTSUB(stash, "W", newSViv(PE_W));
    newCONSTSUB(stash, "E", newSViv(PE_E));
    newCONSTSUB(stash, "T", newSViv(PE_T));
}

static void pe_register_vtbl(pe_watcher_vtbl *vt, HV *stash,
			     pe_event_vtbl *evt) {
    vt->stash = stash;
    vt->event_vtbl = evt;
    vt->new_event = evt->new_event;
}

static void pe_watcher_now(pe_watcher *wa) {
    pe_event *ev;
    if (WaSUSPEND(wa)) return;
    if (!wa->callback) {
      STRLEN n_a;
      croak("Event: attempt to invoke now() method with callback unset on watcher '%s'", SvPV(wa->desc,n_a));
    }

    WaRUNNOW_on(wa); /* race condition XXX */
    ev = (*wa->vtbl->new_event)(wa);
    ++ev->hits;
    queueEvent(ev);
}

/*******************************************************************
  The following methods change the status flags.  This is the only
  code that should be changing these flags!
*/

static void pe_watcher_cancel(pe_watcher *wa) {
    if (WaCANCELLED(wa))
	return;
    WaSUSPEND_off(wa);
    pe_watcher_stop(wa, 1); /* peer */
    WaCANCELLED_on(wa);
    PE_RING_DETACH(&wa->all);
    if (wa->mysv)
	SvREFCNT_dec(wa->mysv);	/* might destroy */
    else if (WaCANDESTROY(wa))
	(*wa->vtbl->dtor)(wa);
}

static void pe_watcher_suspend(pe_watcher *ev) {
    STRLEN n_a;
    assert(ev);
    if (WaSUSPEND(ev))
	return;
    if (WaDEBUGx(ev) >= 4)
	warn("Event: suspend '%s'\n", SvPV(ev->desc,n_a));
    pe_watcher_off(ev);
    pe_watcher_cancel_events(ev);
    WaSUSPEND_on(ev); /* must happen nowhere else!! */
}

static void pe_watcher_resume(pe_watcher *ev) {
    STRLEN n_a;
    assert(ev);
    if (!WaSUSPEND(ev))
	return;
    WaSUSPEND_off(ev);
    if (WaDEBUGx(ev) >= 4)
	warn("Event: resume '%s'%s\n", SvPV(ev->desc,n_a),
	     WaACTIVE(ev)?" ACTIVE":"");
    if (WaACTIVE(ev))
        pe_watcher_on(ev, 0);
}

static char *pe_watcher_on(pe_watcher *wa, int repeat) {
    STRLEN n_a;
    char *excuse;
    if (WaPOLLING(wa) || WaSUSPEND(wa))
	return 0;
    if (WaCANCELLED(wa))
	croak("Event: attempt to start cancelled watcher '%s'",
	      SvPV(wa->desc,n_a));
    excuse = (*wa->vtbl->start)(wa, repeat);
    if (excuse) {
	if (SvIV(DebugLevel))
	    warn("Event: can't restart '%s' %s", SvPV(wa->desc, n_a), excuse);
	pe_watcher_stop(wa, 1); /* update flags! */
    } else
	WaPOLLING_on(wa); /* must happen nowhere else!! */
    return excuse;
}

static void pe_watcher_off(pe_watcher *wa) {
    if (!WaPOLLING(wa) || WaSUSPEND(wa)) return;
    (*wa->vtbl->stop)(wa);
    WaPOLLING_off(wa);
}

static void pe_watcher_start(pe_watcher *ev, int repeat) {
    char *excuse;
    STRLEN n_a;
    if (WaACTIVE(ev))
	return;
    if (WaDEBUGx(ev) >= 4)
	warn("Event: active ON '%s'\n", SvPV(ev->desc,n_a));
    excuse = pe_watcher_on(ev, repeat);
    if (excuse)
	croak("Event: can't start '%s' %s", SvPV(ev->desc,n_a), excuse);
    WaACTIVE_on(ev); /* must happen nowhere else!! */
    ++ActiveWatchers;
}

static void pe_watcher_stop(pe_watcher *ev, int cancel_events) {
    STRLEN n_a;
    if (!WaACTIVE(ev))
	return;
    if (WaDEBUGx(ev) >= 4)
	warn("Event: active OFF '%s'\n", SvPV(ev->desc,n_a));
    pe_watcher_off(ev);
    WaACTIVE_off(ev); /* must happen nowhere else!! */
    if (cancel_events) pe_watcher_cancel_events(ev);
    --ActiveWatchers;
}
