/* 100 levels will trigger a manditory warning from perl */
#define MAX_CB_NEST 95

static NV QueueTime[PE_QUEUES];

static pe_cbframe CBFrame[MAX_CB_NEST];
static int CurCBFrame = -1;

pe_event_vtbl event_vtbl, ioevent_vtbl, datafulevent_vtbl;

static void pe_anyevent_init(pe_event *ev, pe_watcher *wa) {
    assert(wa);
    ev->up = wa;
    ++wa->refcnt;
    ev->mysv = 0;
    PE_RING_INIT(&ev->peer, ev);
    PE_RING_UNSHIFT(&ev->peer, &wa->events);
    ev->hits = 0;
    ev->prio = wa->prio;
    ev->callback = 0;
}

static void pe_anyevent_dtor(pe_event *ev) {
    STRLEN n_a;
    pe_watcher *wa = ev->up;
    if (WaDEBUGx(wa) >= 3)
	warn("Event=0x%x '%s' destroyed (SV=0x%x)",
	     ev,
	     SvPV(wa->desc, n_a),
	     ev->mysv? SvRV(ev->mysv) : 0);
    ev->up = 0;
    ev->mysv = 0;
    ev->hits = 0;
    if (EvPERLCB(ev))
	SvREFCNT_dec(ev->callback);
    ev->callback = 0;
    PE_RING_DETACH(&ev->peer);
    PE_RING_DETACH(&ev->que);
    --wa->refcnt;
    if (WaCANDESTROY(wa)) /* running */
	(*wa->vtbl->dtor)(wa);
}

static void pe_anyevent_set_cb(pe_event *ev, void *fptr, void *ext) {
    if (EvPERLCB(ev))
	SvREFCNT_dec(ev->callback);
    EvPERLCB_off(ev);
    ev->callback = fptr;
    ev->ext_data = ext;
}

static void pe_anyevent_set_perl_cb(pe_event *ev, SV *sv) {
    SV *old = 0;
    if (EvPERLCB(ev))
	old = ev->callback;
    ev->callback = SvREFCNT_inc(sv);
    SvREFCNT_dec(old);
    EvPERLCB_on(ev);
}

/*****************************************************************/

static pe_event *pe_event_allocate(pe_watcher *wa) {
    pe_event *ev;
    assert(wa);
    if (PE_RING_EMPTY(&event_vtbl.freelist)) {
	EvNew(0, ev, 1, pe_event);
	ev->vtbl = &event_vtbl;
	PE_RING_INIT(&ev->que, ev);
    } else {
	pe_ring *lk = event_vtbl.freelist.prev;
	PE_RING_DETACH(lk);
	ev = (pe_event*) lk->self;
    }	
    pe_anyevent_init(ev, wa);
    return ev;
}

static void pe_event_dtor(pe_event *ev) {
    pe_anyevent_dtor(ev);
    PE_RING_UNSHIFT(&ev->que, &event_vtbl.freelist);
}

static void pe_event_release(pe_event *ev) {
    if (!ev->mysv)
      (*ev->vtbl->dtor)(ev);
    else {
	  SvREFCNT_dec(ev->mysv);
	  ev->mysv=0;
    }
}

EKEYMETH(_event_hits) {
    if (!nval) {
	dSP;
	XPUSHs(sv_2mortal(newSViv(ev->hits)));
	PUTBACK;
    } else
	croak("'e_hits' is read-only");
}

EKEYMETH(_event_prio) {
    if (!nval) {
	dSP;
	XPUSHs(sv_2mortal(newSViv(ev->prio)));
	PUTBACK;
    } else
	croak("'e_prio' is read-only");
}

/*------------------------------------------------------*/

static pe_event *pe_ioevent_allocate(pe_watcher *wa) {
    pe_ioevent *ev;
    assert(wa);
    if (PE_RING_EMPTY(&ioevent_vtbl.freelist)) {
	EvNew(1, ev, 1, pe_ioevent);
	ev->base.vtbl = &ioevent_vtbl;
	PE_RING_INIT(&ev->base.que, ev);
    } else {
	pe_ring *lk = ioevent_vtbl.freelist.prev;
	PE_RING_DETACH(lk);
	ev = (pe_ioevent*) lk->self;
    }
    pe_anyevent_init(&ev->base, wa);
    ev->got = 0;
    return &ev->base;
}

static void pe_ioevent_dtor(pe_event *ev) {
    pe_anyevent_dtor(ev);
    PE_RING_UNSHIFT(&ev->que, &ioevent_vtbl.freelist);
}

EKEYMETH(_event_got) {
    pe_ioevent *io = (pe_ioevent *)ev;
    if (!nval) {
	dSP;
	XPUSHs(sv_2mortal(events_mask_2sv(io->got)));
	PUTBACK;
    } else
	croak("'e_got' is read-only");
}

/*------------------------------------------------------*/

static pe_event *pe_datafulevent_allocate(pe_watcher *wa) {
    pe_datafulevent *ev;
    assert(wa);
    if (PE_RING_EMPTY(&datafulevent_vtbl.freelist)) {
	EvNew(15, ev, 1, pe_datafulevent);
	ev->base.vtbl = &datafulevent_vtbl;
	PE_RING_INIT(&ev->base.que, ev);
    } else {
	pe_ring *lk = datafulevent_vtbl.freelist.prev;
	PE_RING_DETACH(lk);
	ev = (pe_datafulevent*) lk->self;
    }
    pe_anyevent_init(&ev->base, wa);
    ev->data = &PL_sv_undef;
    return &ev->base;
}

static void pe_datafulevent_dtor(pe_event *ev) {
    pe_datafulevent *de = (pe_datafulevent *)ev;
    SvREFCNT_dec(de->data);
    pe_anyevent_dtor(ev);
    PE_RING_UNSHIFT(&ev->que, &datafulevent_vtbl.freelist);
}

EKEYMETH(_event_data) {
    pe_datafulevent *de = (pe_datafulevent *)ev;
    if (!nval) {
	dSP;
	XPUSHs(de->data);
	PUTBACK;
    } else
	croak("'e_data' is read-only");
}

/*------------------------------------------------------*/

static void pe_event_postCB(pe_cbframe *fp) {
    pe_event *ev = fp->ev;
    pe_watcher *wa = ev->up;
    --CurCBFrame;
    if (WaACTIVE(wa) && WaINVOKE1(wa) && WaREPEAT(wa))
	pe_watcher_on(wa, 1);
    if (Estat.on) {
	if (fp->stats) {
	    Estat.scrub(fp->stats, wa);
	    fp->stats = 0;
	}
	if (CurCBFrame >= 0) {
	    pe_cbframe *pfp = CBFrame + CurCBFrame;
	    if (!pfp->stats)
		pfp->stats = Estat.enter(CurCBFrame, pfp->ev->up->max_cb_tm);
	    else
		Estat.resume(pfp->stats);
	}
    }
    /* this must be last because it can destroy the watcher */
    pe_event_release(ev);
}

static void pe_callback_died(pe_cbframe *fp) {
    dSP;
    STRLEN n_a;
    pe_watcher *wa = fp->ev->up;
    SV *eval = perl_get_sv("Event::DIED", 1);
    SV *err = (sv_true(ERRSV)?
	       sv_mortalcopy(ERRSV):
	       sv_2mortal(newSVpv("?",0)));
    if (WaDEBUGx(wa) >= 4)
	warn("Event: '%s' died with: %s\n", SvPV(wa->desc,n_a),
	     SvPV(ERRSV,n_a));
    PUSHMARK(SP);
    XPUSHs(event_2sv(fp->ev));
    XPUSHs(err);
    PUTBACK;
    perl_call_sv(eval, G_EVAL|G_DISCARD);
    if (sv_true(ERRSV)) {
	warn("Event: '%s' died and then $Event::DIED died with: %s\n",
	     SvPV(wa->desc,n_a), SvPV(ERRSV,n_a));
	sv_setpv(ERRSV, "");
    }
}

static void _resume_watcher(void *vp) {
    pe_watcher *wa = (pe_watcher *)vp;
    pe_watcher_resume(wa);
}

static void pe_check_recovery() {
    /* NO ASSERTIONS HERE!  EVAL CONTEXT IS VERY MESSY */
    int alert;
    struct pe_cbframe *fp;
    if (CurCBFrame < 0)
	return;

    alert=0;
    while (CurCBFrame >= 0) {
	fp = CBFrame + CurCBFrame;
	if (fp->ev->up->running == fp->run_id)
	    break;
	if (!alert) {
	    alert=1;
	    /* exception detected; alert the militia! */
	    pe_callback_died(fp);
	}
	pe_event_postCB(fp);
    }
}

static void pe_event_invoke(pe_event *ev) {
    STRLEN n_a;
    int Dbg;
    pe_watcher *wa = ev->up;
    struct pe_cbframe *frp;

    pe_check_recovery();

    /* SETUP */
    ENTER;
    SAVEINT(wa->running);
    PE_RING_DETACH(&ev->peer);
    frp = &CBFrame[++CurCBFrame];
    frp->ev = ev;
    frp->run_id = ++wa->running;
    if (Estat.on)
	frp->stats = Estat.enter(CurCBFrame, wa->max_cb_tm);
    assert(ev->prio >= 0 && ev->prio < PE_QUEUES);
    QueueTime[ev->prio] = wa->cbtime = NVtime();
    /* SETUP */

    if (CurCBFrame+1 >= MAX_CB_NEST) {
	ExitLevel = 0;
	croak("Deep recursion detected; invoking unloop_all()\n");
    }

    Dbg = WaDEBUGx(wa);
    if (Dbg) {
	/*
	SV *cvb = perl_get_sv("Carp::Verbose", 1);
	if (!SvIV(cvb)) {
	    SAVEIV(SvIVX(cvb));
	    SvIVX(cvb) = 1;
	}
	*/

	if (Dbg >= 2)
	    warn("Event: [%d]invoking '%s' (prio %d)\n",
		 CurCBFrame, SvPV(wa->desc,n_a),ev->prio);
    }

    if (!PE_RING_EMPTY(&Callback)) pe_map_check(&Callback);

    if (EvPERLCB(ev)) {
	SV *cb = SvRV((SV*)ev->callback);
	int pcflags = G_VOID | (SvIVX(Eval)? G_EVAL : 0);
	int retcnt;
	SV *evsv = event_2sv(ev);
	dSP;
	PUSHMARK(SP);
	if (SvTYPE(cb) == SVt_PVCV) {
	    XPUSHs(evsv);
	    PUTBACK;
	    retcnt = perl_call_sv((SV*) ev->callback, pcflags);
	} else {
	    AV *av = (AV*)cb;
	    assert(SvTYPE(cb) == SVt_PVAV);
	    XPUSHs(*av_fetch(av, 0, 0));
	    XPUSHs(evsv);
	    PUTBACK;
	    retcnt = perl_call_method(SvPV(*av_fetch(av, 1, 0),n_a), pcflags);
	}
	SPAGAIN;
	SP -= retcnt;
	PUTBACK;
	if (SvTRUE(ERRSV)) {
	    if (pcflags & G_EVAL)
		pe_callback_died(frp);
	    else
		sv_setsv(ERRSV, &PL_sv_no);
	}
    } else {
	assert(ev->callback);
	(* (void(*)(pe_event*)) ev->callback)(ev);
    }

    LEAVE;

    if (Estat.on) {
	if (frp->stats)  /* maybe in transition */
	    Estat.commit(frp->stats, wa);
	frp->stats=0;
    }
    if (Dbg >= 3)
	warn("Event: completed '%s'\n", SvPV(wa->desc, n_a));
    pe_event_postCB(frp);
}

static void boot_pe_event() {
    pe_event_vtbl *vt;

    vt = &event_vtbl;
    vt->new_event = pe_event_allocate;
    vt->dtor = pe_event_dtor;
    vt->stash = gv_stashpv("Event::Event", 1);
    PE_RING_INIT(&vt->freelist, 0);

    vt = &ioevent_vtbl;
    memcpy(vt, &event_vtbl, sizeof(pe_event_vtbl));
    vt->stash = gv_stashpv("Event::Event::Io", 1);
    vt->new_event = pe_ioevent_allocate;
    vt->dtor = pe_ioevent_dtor;
    PE_RING_INIT(&vt->freelist, 0);

    vt = &datafulevent_vtbl;
    memcpy(vt, &event_vtbl, sizeof(pe_event_vtbl));
    vt->stash = gv_stashpv("Event::Event::Dataful", 1);
    vt->new_event = pe_datafulevent_allocate;
    vt->dtor = pe_datafulevent_dtor;
    PE_RING_INIT(&vt->freelist, 0);

    memset(QueueTime, 0, sizeof(QueueTime));
}
