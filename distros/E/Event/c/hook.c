static pe_ring Prepare, Check, AsyncCheck, Callback;

static void boot_hook()
{
  PE_RING_INIT(&Prepare, 0);
  PE_RING_INIT(&Check, 0);
  PE_RING_INIT(&AsyncCheck, 0);
  PE_RING_INIT(&Callback, 0);
}

static pe_qcallback *
pe_add_hook(char *which, int is_perl, void *cb, void *ext_data)
{
  pe_qcallback *qcb;
  EvNew(2, qcb, 1, pe_qcallback);
  PE_RING_INIT(&qcb->ring, qcb);
  qcb->is_perl = is_perl;
  if (is_perl) {
    qcb->callback = SvREFCNT_inc((SV*)cb);
    qcb->ext_data = 0;
  }
  else {
    qcb->callback = cb;
    qcb->ext_data = ext_data;
  }
  if (strEQ(which, "prepare"))
    PE_RING_UNSHIFT(&qcb->ring, &Prepare);
  else if (strEQ(which, "check"))
    PE_RING_UNSHIFT(&qcb->ring, &Check);
  else if (strEQ(which, "asynccheck"))
    PE_RING_UNSHIFT(&qcb->ring, &AsyncCheck);
  else if (strEQ(which, "callback"))
    PE_RING_UNSHIFT(&qcb->ring, &Callback);
  else
    croak("Unknown hook '%s' in pe_add_hook", which);
  return qcb;
}

static pe_qcallback *capi_add_hook(char *which, void *cb, void *ext_data)
{ return pe_add_hook(which, 0, cb, ext_data); }

static void pe_cancel_hook(pe_qcallback *qcb)
{
  if (qcb->is_perl)
    SvREFCNT_dec((SV*)qcb->callback);
  PE_RING_DETACH(&qcb->ring);
  EvFree(2, qcb);
}

static void pe_map_check(pe_ring *List)
{
  pe_qcallback *qcb = (pe_qcallback*) List->prev->self;
  while (qcb) {
    if (qcb->is_perl) {
      dSP;
      PUSHMARK(SP);
      PUTBACK;
      perl_call_sv((SV*)qcb->callback, G_DISCARD);
    }
    else { /* !is_perl */
      (* (void(*)(void*)) qcb->callback)(qcb->ext_data);
    }
    qcb = (pe_qcallback*) qcb->ring.prev->self;
  }
}

