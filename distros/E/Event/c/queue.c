static pe_ring NQueue;
static int StarvePrio = PE_QUEUES - 2;

static void boot_queue() {
    HV *stash = gv_stashpv("Event", 1);
    PE_RING_INIT(&NQueue, 0);
    newCONSTSUB(stash, "QUEUES", newSViv(PE_QUEUES));
    newCONSTSUB(stash, "PRIO_NORMAL", newSViv(PE_PRIO_NORMAL));
    newCONSTSUB(stash, "PRIO_HIGH", newSViv(PE_PRIO_HIGH));
}

/*inline*/ static void dequeEvent(pe_event *ev) {
    assert(ev);
    PE_RING_DETACH(&ev->que);
    --ActiveWatchers;
}

static void db_show_queue() {
    pe_event *ev;
    ev = (pe_event*) NQueue.next->self;
    while (ev) {
	warn("0x%x : %d\n", ev, ev->prio);
	ev = (pe_event*) ev->que.next->self;
    }
}

static int prepare_event(pe_event *ev, char *forwhat) {
    /* AVOID DIEING IN HERE!! */
    STRLEN n_a;
    pe_watcher *wa = ev->up;
    if (!ev->callback) {
	if (WaPERLCB(wa)) {
	    ev->callback = SvREFCNT_inc(wa->callback);
	    EvPERLCB_on(ev);
	} else {
	    ev->callback = wa->callback;
	    ev->ext_data = wa->ext_data;
	    EvPERLCB_off(ev);
	}
	assert(ev->callback);
    }
    assert(!WaSUSPEND(wa));
    assert(WaREENTRANT(wa) || !wa->running);
    if (!WaACTIVE(wa)) {
	if (!WaRUNNOW(wa))
	    warn("Event: event for !ACTIVE watcher '%s'", SvPV(wa->desc,n_a));
    }
    else {
	if (!WaREPEAT(wa))
	    pe_watcher_stop(wa, 0);
	else if (WaINVOKE1(wa))
	    pe_watcher_off(wa);
    }
    WaRUNNOW_off(wa); /* race condition? XXX */
    if (WaDEBUGx(wa) >= 3)
	warn("Event: %s '%s' prio=%d\n", forwhat, SvPV(wa->desc,n_a), ev->prio);
    return 1;
}

static void queueEvent(pe_event *ev) {  /**INVOKE**/
    assert(ev->hits);
    if (!PE_RING_EMPTY(&ev->que)) return; /* clump'd event already queued */
    if (!prepare_event(ev, "queue")) return;

    if (ev->prio < 0) {  /* invoke the event immediately! */
	ev->prio = 0;
	pe_event_invoke(ev);
	return;
    }
    if (ev->prio >= PE_QUEUES)
	ev->prio = PE_QUEUES-1;

    {
	/* queue in reverse direction? XXX */ 
	/*  warn("-- adding 0x%x/%d\n", ev, prio); db_show_queue();/**/
	pe_ring *rg;
	rg = NQueue.next;
	while (rg->self && ((pe_event*)rg->self)->prio <= ev->prio)
	    rg = rg->next;
	PE_RING_ADD_BEFORE(&ev->que, rg);
	/*  warn("=\n"); db_show_queue();/**/
	++ActiveWatchers;
    }
}

static int pe_empty_queue(int maxprio) { /**INVOKE**/
    pe_event *ev;
    ev = (pe_event*) NQueue.next->self;
    if (ev && ev->prio < maxprio) {
	dequeEvent(ev);
	pe_event_invoke(ev);
	return 1;
    }
    return 0;
}

/*inline*/ static void pe_multiplex(NV tm) {
    if (SvIVX(DebugLevel) >= 2) {
	warn("Event: multiplex %.4fs %s%s\n", tm,
	     PE_RING_EMPTY(&NQueue)?"":"QUEUE",
	     PE_RING_EMPTY(&Idle)?"":"IDLE");
    }
    if (!Estat.on)
	pe_sys_multiplex(tm);
    else {
	void *st = Estat.enter(-1, 0);
	pe_sys_multiplex(tm);
	Estat.commit(st, 0);
    }
}

static NV pe_map_prepare(NV tm) {
    pe_qcallback *qcb = (pe_qcallback*) Prepare.prev->self;
    while (qcb) {
	if (qcb->is_perl) {
	    SV *got;
	    NV when;
	    dSP;
	    PUSHMARK(SP);
	    PUTBACK;
	    perl_call_sv((SV*)qcb->callback, G_SCALAR);
	    SPAGAIN;
	    got = POPs;
	    PUTBACK;
	    when = SvNOK(got) ? SvNVX(got) : SvNV(got);
	    if (when < tm) tm = when;
	}
	else { /* !is_perl */
	    NV got = (* (NV(*)(void*)) qcb->callback)(qcb->ext_data);
	    if (got < tm) tm = got;
	}
	qcb = (pe_qcallback*) qcb->ring.prev->self;
    }
    return tm;
}

static void pe_queue_pending() {
    NV tm = 0;
    if (!PE_RING_EMPTY(&Prepare)) tm = pe_map_prepare(tm);

    pe_multiplex(0);

    pe_timeables_check();
    if (!PE_RING_EMPTY(&Check)) pe_map_check(&Check);

    pe_signal_asynccheck();
    if (!PE_RING_EMPTY(&AsyncCheck)) pe_map_check(&AsyncCheck);
}

static int one_event(NV tm) {  /**INVOKE**/
    /*if (SvIVX(DebugLevel) >= 4)
      warn("Event: ActiveWatchers=%d\n", ActiveWatchers); /**/

    pe_signal_asynccheck();
    if (!PE_RING_EMPTY(&AsyncCheck)) pe_map_check(&AsyncCheck);

    if (pe_empty_queue(StarvePrio)) return 1;

    if (!PE_RING_EMPTY(&NQueue) || !PE_RING_EMPTY(&Idle)) {
	tm = 0;
    }
    else {
	NV t1 = timeTillTimer();
	if (t1 < tm) tm = t1;
    }
    if (!PE_RING_EMPTY(&Prepare)) tm = pe_map_prepare(tm);

    pe_multiplex(tm);

    pe_timeables_check();
    if (!PE_RING_EMPTY(&Check)) pe_map_check(&Check);

    if (tm) {
	pe_signal_asynccheck();
	if (!PE_RING_EMPTY(&AsyncCheck)) pe_map_check(&AsyncCheck);
    }

    if (pe_empty_queue(PE_QUEUES)) return 1;

    while (1) {
	pe_watcher *wa;
	pe_event *ev;
	pe_ring *lk;

	if (PE_RING_EMPTY(&Idle)) return 0;

	lk = Idle.prev;
	PE_RING_DETACH(lk);
	wa = (pe_watcher*) lk->self;

	/* idle is not an event so CLUMP is never an option but we still need
	   to create an event to pass info to the callback */
	ev = pe_event_allocate(wa);
	if (!prepare_event(ev, "idle")) continue;
	/* can't queueEvent because we are already missed that */
	pe_event_invoke(ev);
	return 1;
    }
}

static void pe_reentry() {
    pe_watcher *wa;
    struct pe_cbframe *frp;

    ENTER;  /* for SAVE*() macro (see below) */

    if (CurCBFrame < 0)
	return;

    frp = CBFrame + CurCBFrame;
    wa = frp->ev->up;
    assert(wa->running == frp->run_id);
    if (Estat.on)
	Estat.suspend(frp->stats);  /* reversed by pe_event_postCB? */
    if (WaREPEAT(wa)) {
	if (WaREENTRANT(wa)) {
	    if (WaACTIVE(wa) && WaINVOKE1(wa))
		pe_watcher_on(wa, 1);
	} else {
	    if (!WaSUSPEND(wa)) {
		/* temporarily suspend non-reentrant watcher until
		   callback is finished! */
		pe_watcher_suspend(wa);
		SAVEDESTRUCTOR(_resume_watcher, wa);
	    }
	}
    }
}

static int safe_one_event(NV maxtm) {
    int got;
    pe_check_recovery();
    pe_reentry();
    got = one_event(maxtm);
    LEAVE; /* reentry */
    return got;
}

static void pe_unloop(SV *why) {
    SV *rsv = perl_get_sv("Event::Result", 0);
    assert(rsv);
    sv_setsv(rsv, why);
    if (--ExitLevel < 0) {
	warn("Event::unloop() to %d", ExitLevel);
    }
}

static void pe_unloop_all(SV *why) {
    SV *rsv = perl_get_sv("Event::TopResult", 0);
    assert(rsv);
    sv_setsv(rsv, why);
    ExitLevel = 0;
}
