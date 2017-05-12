static struct pe_watcher_vtbl pe_var_vtbl;

static pe_watcher *pe_var_allocate(HV *stash, SV *temple) {
    pe_var *ev;
    EvNew(10, ev, 1, pe_var);
    ev->base.vtbl = &pe_var_vtbl;
    pe_watcher_init(&ev->base, stash, temple);
    ev->variable = &PL_sv_undef;
    ev->events = PE_W;
    WaREPEAT_on(ev);
    WaINVOKE1_off(ev);
    return (pe_watcher*) ev;
}

static void pe_var_dtor(pe_watcher *ev) {
    pe_var *wv = (pe_var *)ev;
    SvREFCNT_dec(wv->variable);
    pe_watcher_dtor(ev);
    EvFree(10, ev);
}

static void pe_tracevar(pe_watcher *wa, SV *sv, int got) {
    /* Adapted from tkGlue.c

       We are a "magic" set processor.
       So we are (I think) supposed to look at "private" flags 
       and set the public ones if appropriate.
       e.g. "chop" sets SvPOKp as a hint but not SvPOK

       presumably other operators set other private bits.

       Question are successive "magics" called in correct order?

       i.e. if we are tracing a tied variable should we call 
       some magic list or be careful how we insert ourselves in the list?
    */

    pe_ioevent *ev;

    if (SvPOKp(sv)) SvPOK_on(sv);
    if (SvNOKp(sv)) SvNOK_on(sv);
    if (SvIOKp(sv)) SvIOK_on(sv);

    ev = (pe_ioevent*) (*wa->vtbl->new_event)(wa);
    ++ev->base.hits;
    ev->got |= got;
    queueEvent((pe_event*) ev);
}

static I32 tracevar_r(pTHX_ IV ix, SV *sv)
{ pe_tracevar(INT2PTR(pe_watcher *, ix), sv, PE_R); return 0; /*ignored*/ }
static I32 tracevar_w(pTHX_ IV ix, SV *sv)
{ pe_tracevar(INT2PTR(pe_watcher *, ix), sv, PE_W); return 0; /*ignored*/ }

static char *pe_var_start(pe_watcher *_ev, int repeat) {
    STRLEN n_a;
    struct ufuncs *ufp;
    MAGIC **mgp;
    MAGIC *mg;
    pe_var *ev = (pe_var*) _ev;
    SV *sv = ev->variable;

    if (!_ev->callback)
	return "without callback";
    if (!sv || !SvOK(sv))
	return "watching what?";
    if (!ev->events)
	return "without poll events specified";
    sv = SvRV(sv);
    if (SvREADONLY(sv))
	return "cannot trace read-only variable";
    (void)SvUPGRADE(sv, SVt_PVMG);

    mgp = &SvMAGIC(sv);
    while ((mg = *mgp)) {
	mgp = &mg->mg_moremagic;
    }

    EvNew(11, mg, 1, MAGIC);
    Zero(mg, 1, MAGIC);
    mg->mg_type = 'U';
    mg->mg_virtual = &PL_vtbl_uvar;
    *mgp = mg;
    
    EvNew(8, ufp, 1, struct ufuncs);
    ufp->uf_val = ev->events & PE_R? tracevar_r : 0;
    ufp->uf_set = ev->events & PE_W? tracevar_w : 0;
    ufp->uf_index = PTR2IV(ev);
    mg->mg_ptr = (char *) ufp;
    mg->mg_obj = (SV*) ev;

    mg_magical(sv);
    if (!SvMAGICAL(sv))
	return "mg_magical didn't";
    return 0;
}

static void pe_var_stop(pe_watcher *_ev) {
    MAGIC **mgp;
    MAGIC *mg;
    pe_var *ev = (pe_var*) _ev;
    SV *sv = SvRV(ev->variable);

    if (SvTYPE(sv) < SVt_PVMG || !SvMAGIC(sv)) {
	warn("Var unmagic'd already?");
	return;
    }

    mgp = &SvMAGIC(sv);
    while ((mg = *mgp)) {
	if (mg->mg_type == 'U' && mg->mg_obj == (SV*)ev)
	    break;
	mgp = &mg->mg_moremagic;
    }

    if(!mg) {
	warn("Couldn't find var magic");
	return;
    }

    *mgp = mg->mg_moremagic;

    EvFree(8, mg->mg_ptr);
    EvFree(11, mg);
}

static void _var_restart(pe_watcher *ev) {
    if (!WaPOLLING(ev)) return;
    pe_watcher_off(ev);
    pe_watcher_on(ev, 0);
}

WKEYMETH(_var_events) {
    pe_var *vp = (pe_var*)ev;
    if (nval) {
	vp->events = sv_2events_mask(nval, PE_R|PE_W);
	_var_restart(ev);
    }
    {
	dSP;
	XPUSHs(sv_2mortal(events_mask_2sv(vp->events)));
	PUTBACK;
    }
}

WKEYMETH(_var_variable) {
    pe_var *vp = (pe_var*)ev;
    if (nval) {
	SV *old = vp->variable;
	int active = WaPOLLING(ev);
	if (SvOK(nval)) {
	    if (!SvROK(nval))
		croak("Expecting a reference");
	    if (SvTYPE(SvRV(nval)) > SVt_PVMG)
		croak("Var watchers can only watch plain vanilla scalars");
	}
	if (active) pe_watcher_off(ev);
	vp->variable = SvREFCNT_inc(nval);
	if (active) pe_watcher_on(ev, 0);
	SvREFCNT_dec(old);
    }
    {
	dSP;
	XPUSHs(vp->variable);
	PUTBACK;
    }
}

static void boot_var() {
    pe_watcher_vtbl *vt = &pe_var_vtbl;
    memcpy(vt, &pe_watcher_base_vtbl, sizeof(pe_watcher_base_vtbl));
    vt->dtor = pe_var_dtor;
    vt->start = pe_var_start;
    vt->stop = pe_var_stop;
    pe_register_vtbl(vt, gv_stashpv("Event::var",1), &ioevent_vtbl);
}
