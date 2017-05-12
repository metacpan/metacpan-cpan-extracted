#include "EventAPI.h"

#define PE_NEWID ('e'+'v')  /* for New() macro */

#define PE_RING_INIT(LNK, SELF) 		\
STMT_START {					\
  (LNK)->next = LNK;				\
  (LNK)->prev = LNK;				\
  (LNK)->self = SELF;				\
} STMT_END

#define PE_RING_EMPTY(LNK) ((LNK)->next == LNK)

#define PE_RING_UNSHIFT(LNK, ALL)		\
STMT_START {					\
  assert((LNK)->next==LNK);			\
  (LNK)->next = (ALL)->next;			\
  (LNK)->prev = ALL;				\
  (LNK)->next->prev = LNK;			\
  (LNK)->prev->next = LNK;			\
} STMT_END

#define PE_RING_ADD_BEFORE(L1,L2)		\
STMT_START {					\
  assert((L1)->next==L1);			\
  (L1)->next = L2;				\
  (L1)->prev = (L2)->prev;			\
  (L1)->next->prev = L1;			\
  (L1)->prev->next = L1;			\
} STMT_END

#define PE_RING_DETACH(LNK)			\
STMT_START {					\
  if ((LNK)->next != LNK) {			\
    (LNK)->next->prev = (LNK)->prev;		\
    (LNK)->prev->next = (LNK)->next;		\
    (LNK)->next = LNK;				\
  }						\
} STMT_END

/* too bad typeof is a G++ specific extension
#define PE_RING_POP(ALL, TO)			\
STMT_START {					\
  pe_ring *lk = (ALL)->prev;			\
  PE_RING_DETACH(lk);				\
  TO = (typeof(TO)) lk->self;			\
} STMT_END
*/

typedef struct pe_cbframe pe_cbframe;
struct pe_cbframe {
    pe_event *ev;
    IV run_id;
    void *stats;
};

typedef struct pe_tied pe_tied;
struct pe_tied {
    pe_watcher base;
    pe_timeable tm;
};

#define WKEYMETH(M) static void M(pe_watcher *ev, SV *nval)
#define EKEYMETH(M) static void M(pe_event *ev, SV *nval)

/* When this becomes a public API then we should also publish C interfaces
   to set up perl & C callbacks.  For now we can be lazy. */
struct pe_event_vtbl {
    HV *stash;
    pe_event *(*new_event)(pe_watcher *);
    void (*dtor)(pe_event *);

    pe_ring freelist;
};

struct pe_watcher_vtbl {
    int did_require;
    HV *stash;
    void (*dtor)(pe_watcher *);
    char*(*start)(pe_watcher *, int);
    void (*stop)(pe_watcher *);
    void (*alarm)(pe_watcher *, pe_timeable *);
    pe_event_vtbl *event_vtbl;
    pe_event *(*new_event)(pe_watcher *);
};

#define PE_ACTIVE	0x001
#define PE_POLLING	0x002
#define PE_SUSPEND	0x004
#define PE_PERLCB	0x020
#define PE_RUNNOW	0x040
#define PE_TMPERLCB	0x080
#define PE_CANCELLED	0x400
#define PE_DESTROYED	0x800

#define PE_VISIBLE_FLAGS (PE_ACTIVE | PE_SUSPEND)

#ifdef DEBUGGING
#  define WaDEBUGx(ev) (SvIV(DebugLevel) + WaDEBUG(ev))
#else
#  define WaDEBUGx(ev) 0
#endif

/* logically waiting for something to happen */
#define WaACTIVE(ev)		(WaFLAGS(ev) & PE_ACTIVE)
#define WaACTIVE_on(ev)		(WaFLAGS(ev) |= PE_ACTIVE)
#define WaACTIVE_off(ev)	(WaFLAGS(ev) &= ~PE_ACTIVE)

/* physically registered for poll/select */
#define WaPOLLING(ev)		(WaFLAGS(ev) & PE_POLLING)
#define WaPOLLING_on(ev)	(WaFLAGS(ev) |= PE_POLLING)
#define WaPOLLING_off(ev)	(WaFLAGS(ev) &= ~PE_POLLING)

#define WaSUSPEND(ev)		(WaFLAGS(ev) & PE_SUSPEND)
#define WaSUSPEND_on(ev)	(WaFLAGS(ev) |= PE_SUSPEND)
#define WaSUSPEND_off(ev)	(WaFLAGS(ev) &= ~PE_SUSPEND)

#define WaPERLCB(ev)		(WaFLAGS(ev) & PE_PERLCB)
#define WaPERLCB_on(ev)		(WaFLAGS(ev) |= PE_PERLCB)
#define WaPERLCB_off(ev)	(WaFLAGS(ev) &= ~PE_PERLCB)

#define WaTMPERLCB(ev)		(WaFLAGS(ev) & PE_TMPERLCB)
#define WaTMPERLCB_on(ev)	(WaFLAGS(ev) |= PE_TMPERLCB)
#define WaTMPERLCB_off(ev)	(WaFLAGS(ev) &= ~PE_TMPERLCB)

/* RUNNOW should be event specific XXX */
#define WaRUNNOW(ev)		(WaFLAGS(ev) & PE_RUNNOW)
#define WaRUNNOW_on(ev)		(WaFLAGS(ev) |= PE_RUNNOW)
#define WaRUNNOW_off(ev)	(WaFLAGS(ev) &= ~PE_RUNNOW)

#define WaCANCELLED(ev)		(WaFLAGS(ev) & PE_CANCELLED)
#define WaCANCELLED_on(ev)	(WaFLAGS(ev) |= PE_CANCELLED)
#define WaCANCELLED_off(ev)	(WaFLAGS(ev) &= ~PE_CANCELLED)

#define WaDESTROYED(ev)		(WaFLAGS(ev) & PE_DESTROYED)
#define WaDESTROYED_on(ev)	(WaFLAGS(ev) |= PE_DESTROYED)
#define WaDESTROYED_off(ev)	(WaFLAGS(ev) &= ~PE_DESTROYED)

#define WaCANDESTROY(ev)					\
 (WaCANCELLED(ev) && ev->refcnt == 0 && !ev->mysv)


#define EvFLAGS(ev)		((pe_event*)ev)->flags

#define EvPERLCB(ev)		(EvFLAGS(ev) & PE_PERLCB)
#define EvPERLCB_on(ev)		(EvFLAGS(ev) |= PE_PERLCB)
#define EvPERLCB_off(ev)	(EvFLAGS(ev) &= ~PE_PERLCB)
