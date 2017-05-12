static struct pe_watcher_vtbl pe_generic_vtbl;

static pe_watcher *pe_generic_allocate(HV *stash, SV *temple) {
    pe_generic *ev;
    EvNew(14, ev, 1, pe_generic);
    ev->base.vtbl = &pe_generic_vtbl;
    pe_watcher_init(&ev->base, stash, temple);
    ev->source = &PL_sv_undef;
    PE_RING_INIT(&ev->active, ev);
    WaREPEAT_on(ev);
    WaINVOKE1_off(ev);
    return (pe_watcher*) ev;
}

static void pe_generic_dtor(pe_watcher *ev) {
    pe_generic *gw = (pe_generic *)ev;
    SvREFCNT_dec(gw->source);
    pe_watcher_dtor(ev);
    EvFree(14, ev);
}

static char *pe_generic_start(pe_watcher *_ev, int repeat) {
    pe_generic *ev = (pe_generic*) _ev;
    SV *source = ev->source;
    pe_genericsrc *src;
    if (!_ev->callback)
	return "without callback";
    if (!source || !SvOK(source))
	return "without source";
    src = sv_2genericsrc(source);
    PE_RING_UNSHIFT(&ev->active, &src->watchers);
    return 0;
}

static void pe_generic_stop(pe_watcher *_ev) {
    pe_generic *ev = (pe_generic*) _ev;
    PE_RING_DETACH(&ev->active);
}

WKEYMETH(_generic_source) {
    pe_generic *gw = (pe_generic*)ev;
    if (nval) {
        SV *old = gw->source;
	int active = WaPOLLING(ev);
	if(SvOK(nval)) {
	  (void) sv_2genericsrc(nval);  /* for type check */
	}
	if (active) pe_watcher_off(ev);
	gw->source = SvREFCNT_inc(nval);
	if (active) pe_watcher_on(ev, 0);
	SvREFCNT_dec(old);
    }
    {
	dSP;
	XPUSHs(gw->source);
	PUTBACK;
    }
}

static pe_genericsrc *pe_genericsrc_allocate(HV *stash, SV *temple) {
    pe_genericsrc *src;
    EvNew(16, src, 1, pe_genericsrc);
    src->mysv = stash || temple ? wrap_genericsrc(src, stash, temple) : 0;
    PE_RING_INIT(&src->watchers, 0);
    return src;
}

static void pe_genericsrc_dtor(pe_genericsrc *src) {
    PE_RING_DETACH(&src->watchers);
    EvFree(16, src);
}

static HV *pe_genericsrc_stash;

static void pe_genericsrc_event(pe_genericsrc *src, SV *data) {
    pe_generic *wa = src->watchers.next->self;
    while(wa) {
	pe_datafulevent *ev =
		(pe_datafulevent*) (*wa->base.vtbl->new_event)(&wa->base);
	++ev->base.hits;
	ev->data = SvREFCNT_inc(data);
	queueEvent(&ev->base);
	wa = wa->active.next->self;
    }
}

static void boot_generic() {
    pe_watcher_vtbl *vt = &pe_generic_vtbl;
    memcpy(vt, &pe_watcher_base_vtbl, sizeof(pe_watcher_base_vtbl));
    vt->dtor = pe_generic_dtor;
    vt->start = pe_generic_start;
    vt->stop = pe_generic_stop;
    pe_register_vtbl(vt, gv_stashpv("Event::generic",1), &datafulevent_vtbl);
    pe_genericsrc_stash = gv_stashpv("Event::generic::Source", 1);
}
