/* -*- C -*- sometimes */

#define MIN_PERL_DEFINE 1

#ifdef __cplusplus
extern "C" {
#endif

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#ifdef __cplusplus
}
#endif

#include "ppport.h"

/* lexical warnings -- waiting for appropriate magic from
   paul.marquess@bt.com */
#if 0
static void Event_warn(const char* pat, ...) {
    dTHX;
    va_list args;
    va_start(args, pat);
    if (!ckWARN_d(WARN_ALL))
	return;
    Perl_vwarner(aTHX_ WARN_ALL, pat, &args);
    va_end(args);
}

#  undef warn
#  define warn Event_warn
#endif

#if 1
#ifdef warn
#  undef warn
#endif
#define warn Event_warn

static void Event_warn(const char* pat, ...) {
    STRLEN n_a;
    dSP;
    SV *msg;
    va_list args;
    /* perl_require_pv("Carp.pm");     Couldn't possibly be unloaded.*/
    va_start(args, pat);
    msg = sv_newmortal();
    sv_vsetpvfn(msg, pat, strlen(pat), &args, Null(SV**), 0, 0);
    va_end(args);
    SvREADONLY_on(msg);
    PUSHMARK(SP);
    XPUSHs(msg);
    PUTBACK;
    perl_call_pv("Carp::carp", G_DISCARD);
}
#endif

#ifdef croak
#  undef croak
#endif
#define croak Event_croak

static void Event_croak(const char* pat, ...) {
    STRLEN n_a;
    dSP;
    SV *msg;
    va_list args;
    /* perl_require_pv("Carp.pm");     Couldn't possibly be unloaded.*/
    va_start(args, pat);
    msg = sv_newmortal();
    sv_vsetpvfn(msg, pat, strlen(pat), &args, Null(SV**), 0, 0);
    va_end(args);
    SvREADONLY_on(msg);
    PUSHMARK(SP);
    XPUSHs(msg);
    PUTBACK;
    perl_call_pv("Carp::croak", G_DISCARD);
    PerlIO_puts(PerlIO_stderr(), "panic: Carp::croak failed\n");
    (void)PerlIO_flush(PerlIO_stderr());
    my_failure_exit();
}

#ifdef WIN32
#   include <fcntl.h>
#endif

#if defined(HAS_POLL)
# include <poll.h>

/*
	Many operating systems claim to support poll yet they
	actually emulate it with select.  c/unix.c supports
	either poll or select but it doesn't know which one to
	use.  Here we try to detect if we have a native poll
	implementation.  If we do, we use it.  Otherwise,
	select is assumed.
*/

# ifndef POLLOUT
#  undef HAS_POLL
# endif
# ifndef POLLWRNORM
#  undef HAS_POLL
# endif
# ifndef POLLWRBAND
#  undef HAS_POLL
# endif
#endif

/* Is time() portable everywhere?  Hope so!  XXX */

static NV fallback_NVtime()
{ return time(0); }

#include "Event.h"

/* The following is for very simplistic memory leak detection. */

#define MAX_MEMORYCOUNT 20
static int MemoryCount[MAX_MEMORYCOUNT];
static void dbg_count_memory(int id, int cnt) {
    assert(id >= 0 && id < MAX_MEMORYCOUNT);
    MemoryCount[id] += cnt;
}

#if EVENT_MEMORY_DEBUG
#  define EvNew(id, ptr, size, type) dbg_count_memory(id,1); New(0,ptr,size,type)
#  define EvFree(id, ptr) STMT_START { dbg_count_memory(id,-1); safefree(ptr); } STMT_END
#else
#  define EvNew(x, ptr, size, type) New(0,ptr,size,type)
#  define EvFree(id, ptr) safefree(ptr)
#endif

static int LoopLevel, ExitLevel;
static int ActiveWatchers=0; /* includes WaACTIVE + queued events */
static int WarnCounter=16; /*XXX nuke */
static SV *DebugLevel;
static SV *Eval;
static pe_event_stats_vtbl Estat;

/* IntervalEpsilon should be equal to the clock's sleep resolution
   (poll or select) times two.  It probably needs to be bigger if you turn
   on lots of debugging?  Can determine this dynamically? XXX */
static NV IntervalEpsilon = 0.0002;
static int TimeoutTooEarly=0;

static struct EventAPI api;
#define NVtime() (*api.NVtime)()

static int pe_sys_fileno(SV *sv, char *context);

static void queueEvent(pe_event *ev);
static void dequeEvent(pe_event *ev);

static void pe_watcher_cancel(pe_watcher *ev);
static void pe_watcher_suspend(pe_watcher *ev);
static void pe_watcher_resume(pe_watcher *ev);
static void pe_watcher_now(pe_watcher *ev);
static void pe_watcher_start(pe_watcher *ev, int repeat);
static void pe_watcher_stop(pe_watcher *ev, int cancel_events);
static char*pe_watcher_on(pe_watcher *wa, int repeat);
static void pe_watcher_off(pe_watcher *wa);

/* The newHVhv in perl seems to mysteriously break in some cases.  Here
   is a simple and safe (but maybe slow) implementation. */

#ifdef newHVhv
# undef newHVhv
#endif
#define newHVhv event_newHVhv

static HV *event_newHVhv(HV *ohv) {
    register HV *hv = newHV();
    register HE *entry;
    hv_iterinit(ohv);		/* NOTE: this resets the iterator */
    while (entry = hv_iternext(ohv)) {
	hv_store(hv, HeKEY(entry), HeKLEN(entry), 
		SvREFCNT_inc(HeVAL(entry)), HeHASH(entry));
    }
    return hv;
}

static void pe_watcher_STORE_FALLBACK(pe_watcher *wa, SV *svkey, SV *nval)
{
    if (!wa->FALLBACK)
	wa->FALLBACK = newHV();
    hv_store_ent(wa->FALLBACK, svkey, SvREFCNT_inc(nval), 0);
}

/***************** STATS */
static int StatsInstalled=0;
static void pe_install_stats(pe_event_stats_vtbl *esvtbl) {
    ++StatsInstalled;
    Copy(esvtbl, &Estat, 1, pe_event_stats_vtbl);
    Estat.on=0;
}
static void pe_collect_stats(int yes) {
    if (!StatsInstalled)
	croak("collect_stats: no event statistics are available");
    Estat.on = yes;
}

#ifdef HAS_GETTIMEOFDAY
NV null_loops_per_second(int sec)
{
	/*
	  This should be more realistic.  It is used to normalize
	  the benchmark against some theoretical perfect event loop.
	*/
	struct timeval start_tm, done_tm;
	NV elapse;
	unsigned count=0;
	int fds[2];
	if (pipe(fds) != 0) croak("pipe");
	gettimeofday(&start_tm, 0);
	do {
#ifdef HAS_POLL
	  struct pollfd map[2];
	  Zero(map, 2, struct pollfd);
	  map[0].fd = fds[0];
	  map[0].events = POLLIN | POLLOUT;
	  map[0].revents = 0;
	  map[1].fd = fds[1];
	  map[1].events = POLLIN | POLLOUT;
	  map[1].revents = 0;
	  poll(map, 2, 0);
#elif defined(HAS_SELECT)
	  struct timeval null;
	  fd_set rfds, wfds, efds;
	  FD_ZERO(&rfds);
	  FD_ZERO(&wfds);
	  FD_ZERO(&efds);
	  FD_SET(fds[0], &rfds);
	  FD_SET(fds[0], &wfds);
	  FD_SET(fds[1], &rfds);
	  FD_SET(fds[1], &wfds);
	  null.tv_sec = 0;
	  null.tv_usec = 0;
	  select(3,&rfds,&wfds,&efds,&null);
#else
#  error
#endif
	  ++count;
	  gettimeofday(&done_tm, 0);
	  elapse = (done_tm.tv_sec - start_tm.tv_sec +
		    (done_tm.tv_usec - start_tm.tv_usec) / 1000000);
	} while(elapse < sec);
	close(fds[0]);
	close(fds[1]);
return count/sec;
}
#else /* !HAS_GETTIMEOFDAY */
NV null_loops_per_second(int sec)
{ croak("sorry, gettimeofday is not available"); }
#endif


#include "typemap.c"
#include "timeable.c"
#include "hook.c"
#include "ev.c"
#include "watcher.c"
#include "idle.c"
#include "timer.c"
#include "io.c"
#include "unix.c"
#include "var.c"
#include "signal.c"
#include "tied.c"
#include "group.c"
#include "generic.c"
#include "queue.c"

MODULE = Event		PACKAGE = Event

PROTOTYPES: DISABLE

BOOT:
  LoopLevel = ExitLevel = 0;
  DebugLevel = SvREFCNT_inc(perl_get_sv("Event::DebugLevel", 1));
  Eval = SvREFCNT_inc(perl_get_sv("Event::Eval", 1));
  Estat.on=0;
  boot_timeable();
  boot_hook();
  boot_pe_event();
  boot_pe_watcher();
  boot_idle();
  boot_timer();
  boot_io();
  boot_devpoll();
  boot_var();
  boot_tied();
  boot_signal();
  boot_group();
  boot_generic();
  boot_queue();
  {
      SV *apisv;
      api.Ver = EventAPI_VERSION;
      api.start = pe_watcher_start;
      api.queue = queueEvent;
      api.now = pe_watcher_now;
      api.suspend = pe_watcher_suspend;
      api.resume = pe_watcher_resume;
      api.stop = pe_watcher_stop;
      api.cancel = pe_watcher_cancel;
      api.tstart = pe_timeable_start;
      api.tstop  = pe_timeable_stop;
      api.NVtime = fallback_NVtime;
      api.new_idle =   (pe_idle*  (*)(HV*,SV*))    pe_idle_allocate;
      api.new_timer =  (pe_timer* (*)(HV*,SV*))    pe_timer_allocate;
      api.new_io =     (pe_io*    (*)(HV*,SV*))    pe_io_allocate;
      api.new_var =    (pe_var*   (*)(HV*,SV*))    pe_var_allocate;
      api.new_signal = (pe_signal*(*)(HV*,SV*))    pe_signal_allocate;
      api.add_hook = capi_add_hook;
      api.cancel_hook = pe_cancel_hook;
      api.install_stats = pe_install_stats;
      api.collect_stats = pe_collect_stats;
      api.AllWatchers = &AllWatchers;
      api.watcher_2sv = watcher_2sv;
      api.sv_2watcher = sv_2watcher;
      api.event_2sv = event_2sv;
      api.sv_2event = sv_2event;
      api.unloop = pe_unloop;
      api.unloop_all = pe_unloop_all;
      api.sv_2interval = sv_2interval;
      api.events_mask_2sv = events_mask_2sv;
      api.sv_2events_mask = sv_2events_mask;

      apisv = perl_get_sv("Event::API", 1);
      sv_setiv(apisv, (IV)&api);
      SvREADONLY_on(apisv);
  }

void
_add_hook(type, code)
	char *type
	SV *code
	CODE:
	pe_add_hook(type, 1, code, 0);
	/* would be nice to return new pe_qcallback* XXX */

int
_timeout_too_early()
	CODE:
	RETVAL = TimeoutTooEarly;
	TimeoutTooEarly=0;
	OUTPUT:
	RETVAL

void
_memory_counters()
     PPCODE:
{
#ifdef EVENT_MEMORY_DEBUG
    int xx;
    for (xx=0; xx < MAX_MEMORYCOUNT; xx++)
	XPUSHs(sv_2mortal(newSViv(MemoryCount[xx])));
#endif
}

void
_incr_looplevel()
     PPCODE:
     ++LoopLevel;
     ++ExitLevel;

void
_decr_looplevel()
     PPCODE:
     --LoopLevel;

void
unloop(...)
     CODE:
     pe_unloop(items? ST(0) : &PL_sv_undef);

void
unloop_all(...)
     CODE:
     pe_unloop_all(items? ST(0) : &PL_sv_undef);

bool
cache_time_api()
	CODE:
	SV **svp = hv_fetch(PL_modglobal, "Time::NVtime", 12, 0);
	if (!svp || !*svp || !SvIOK(*svp))
	    XSRETURN_NO;
	api.NVtime = INT2PTR(NV(*)(), SvIV(*svp));
	XSRETURN_YES;

NV
time()
	PROTOTYPE:
	CODE:
	RETVAL = NVtime();
	OUTPUT:
	RETVAL

void
sleep(tm)
	NV tm;
	PROTOTYPE: $
	CODE:
	pe_sys_sleep(tm);

NV
null_loops_per_second(sec)
	int sec

void
all_watchers()
	PROTOTYPE:
	PPCODE:
	pe_watcher *ev;
	if (!AllWatchers.next)
	  return;
	ev = (pe_watcher*) AllWatchers.next->self;
	while (ev) {
	  XPUSHs(watcher_2sv(ev));
	  ev = (pe_watcher*) ev->all.next->self;
	}

void
all_idle()
	PROTOTYPE:
	PPCODE:
	pe_watcher *ev;
	if (!Idle.prev)
	  return;
	ev = (pe_watcher*) Idle.prev->self;
	while (ev) {
	  XPUSHs(watcher_2sv(ev));
	  ev = (pe_watcher*) ((pe_idle*)ev)->iring.prev->self;
	}

void
all_running()
	PROTOTYPE:
	PPCODE:
	int fx;
	for (fx = CurCBFrame; fx >= 0; fx--) {
	  pe_watcher *ev = (CBFrame + fx)->ev->up; /* XXX */
	  XPUSHs(watcher_2sv(ev));
	  if (GIMME_V != G_ARRAY)
	    break;
	}

void
queue(...)
	PROTOTYPE: $;$
	PREINIT:
	pe_watcher *wa;
	pe_event *ev;
	PPCODE:
	wa = (pe_watcher*) sv_2watcher(ST(0));
	if (items == 1) {
	    ev = (*wa->vtbl->new_event)(wa);
	    ++ev->hits;
	}
	else if (items == 2) {
	  if (SvNIOK(ST(1))) {
	    ev = (*wa->vtbl->new_event)(wa);
	    ev->hits += SvIV(ST(1));
	  }
	  else {
	    ev = (pe_event*) sv_2event(ST(1));
	    if (ev->up != wa)
	      croak("queue: event doesn't match watcher");
	  }
	}
	queueEvent(ev);

int
one_event(...)
	PROTOTYPE: ;$
	CODE:
	NV maxtm = 60;
	if (items == 1) maxtm = SvNV(ST(0));
	RETVAL = safe_one_event(maxtm);
	OUTPUT:
	RETVAL

void
_loop()
	CODE:
	pe_check_recovery();
	pe_reentry();
        if (!ActiveWatchers)
          warn("Event: loop without active watchers");
	while (ExitLevel >= LoopLevel && ActiveWatchers) {
	  ENTER;
	  SAVETMPS;
	  one_event(60);
	  FREETMPS;
	  LEAVE;
	}
	LEAVE; /* reentry */

void
queue_pending()
	CODE:
	pe_queue_pending();

int
_empty_queue(prio)
	int prio
	CODE:
	pe_check_recovery();
	pe_reentry();
	while (pe_empty_queue(prio));
	LEAVE; /* reentry */

void
queue_time(prio)
	int prio
	PPCODE:
	NV max=0;
	int xx;
	if (prio < 0 || prio >= PE_QUEUES)
	  croak("queue_time(%d) out of domain [0..%d]",
		prio, PE_QUEUES-1);
	for (xx=0; xx <= prio; xx++)
	  if (max < QueueTime[xx]) max = QueueTime[xx];
	XPUSHs(max? sv_2mortal(newSVnv(max)) : &PL_sv_undef);


MODULE = Event		PACKAGE = Event::Event::Io

void
pe_event::got()
	PPCODE:
	XPUSHs(sv_2mortal(events_mask_2sv(((pe_ioevent*)THIS)->got)));

MODULE = Event		PACKAGE = Event::Event::Dataful

void
pe_event::data()
	PPCODE:
	XPUSHs(((pe_datafulevent*)THIS)->data);

MODULE = Event		PACKAGE = Event::Event

void
DESTROY(ref)
	SV *ref;
	CODE:
{
	pe_event *THIS = (pe_event*) sv_2event(ref);
	if (WaDEBUGx(THIS) >= 3) {
	    STRLEN n_a;
	    warn("Event=0x%x '%s' DESTROY SV=0x%x",
		 THIS, SvPV(THIS->up->desc, n_a),
		 THIS->mysv? SvRV(THIS->mysv) : 0);
	}
	(*THIS->vtbl->dtor)(THIS);
}

void
pe_event::mom()
	PPCODE:
	if (--WarnCounter >= 0) warn("'mom' renamed to 'w'");
	XPUSHs(watcher_2sv(THIS->up));

void
pe_event::w()
	PPCODE:
	XPUSHs(watcher_2sv(THIS->up));

void
pe_event::hits()
	PPCODE:
	XPUSHs(sv_2mortal(newSViv(THIS->hits)));

void
pe_event::prio()
	PPCODE:
	XPUSHs(sv_2mortal(newSViv(THIS->prio)));

MODULE = Event		PACKAGE = Event::Watcher

void
DESTROY(ref)
	SV *ref;
	CODE:
{
	pe_watcher *THIS = (pe_watcher*) sv_2watcher(ref);
	assert(THIS);
	if (THIS->mysv) {
	    THIS->mysv=0;
	    if (WaCANDESTROY(THIS)) /*mysv*/
		(*THIS->vtbl->dtor)(THIS);
	}
}

void
pe_watcher::pending()
	PPCODE:
{
    if (GIMME_V == G_ARRAY) {
	pe_event *ev = (pe_event *) THIS->events.prev->self;
	while (ev) {
	    XPUSHs(event_2sv(ev));
	    ev = (pe_event*) ev->peer.prev->self;
	}
    } else {
	XPUSHs(THIS->events.next->self? &PL_sv_yes : &PL_sv_no);
    }
}

void
pe_watcher::again()
	CODE:
	pe_watcher_start(THIS, 1);

void
pe_watcher::start()
	CODE:
	pe_watcher_start(THIS, 0);

void
pe_watcher::suspend(...)
	CODE:
	if (items == 2) {
	    if (sv_true(ST(1)))
		pe_watcher_suspend(THIS);
	    else
		pe_watcher_resume(THIS);
	} else {
	    warn("Ambiguous use of suspend"); /*XXX*/
	    pe_watcher_suspend(THIS);
	    XSRETURN_YES;
	}

void
pe_watcher::resume()
	CODE:
	warn("Please use $w->suspend(0) instead of resume"); /* DEPRECATED */
	pe_watcher_resume(THIS);

void
pe_watcher::stop()
	CODE:
	pe_watcher_stop(THIS, 1);

void
pe_watcher::cancel()
	CODE:
	pe_watcher_cancel(THIS);

void
pe_watcher::now()
	CODE:
	pe_watcher_now(THIS);

void
pe_watcher::use_keys(...)
	PREINIT:
	PPCODE:
	warn("use_keys is deprecated");

void
pe_watcher::is_running(...)
	PPCODE:
	XPUSHs(sv_2mortal(newSViv(THIS->running)));

void
pe_watcher::is_active(...)
	PPCODE:
	PUTBACK;
	XPUSHs(boolSV(WaACTIVE(THIS)));

void
pe_watcher::is_suspended(...)
	PPCODE:
	PUTBACK;
	XPUSHs(boolSV(WaSUSPEND(THIS)));

void
pe_watcher::is_cancelled(...)
	PPCODE:
	PUTBACK;
	XPUSHs(boolSV(WaCANCELLED(THIS)));

void
pe_watcher::cb(...)
	PPCODE:
	PUTBACK;
	_watcher_callback(THIS, items == 2? sv_mortalcopy(ST(1)) : 0);
	SPAGAIN;

void
pe_watcher::cbtime(...)
	PPCODE:
	PUTBACK;
	_watcher_cbtime(THIS, items == 2? sv_mortalcopy(ST(1)) : 0);
	SPAGAIN;

void
pe_watcher::desc(...)
	PPCODE:
	PUTBACK;
	_watcher_desc(THIS, items == 2? sv_mortalcopy(ST(1)) : 0);
	SPAGAIN;

void
pe_watcher::debug(...)
	PPCODE:
	PUTBACK;
	_watcher_debug(THIS, items == 2? sv_mortalcopy(ST(1)) : 0);
	SPAGAIN;

void
pe_watcher::prio(...)
	PPCODE:
	PUTBACK;
	_watcher_priority(THIS, items == 2? sv_mortalcopy(ST(1)) : 0);
	SPAGAIN;

void
pe_watcher::reentrant(...)
	PPCODE:
	PUTBACK;
	_watcher_reentrant(THIS, items == 2? sv_mortalcopy(ST(1)) : 0);
	SPAGAIN;

void
pe_watcher::repeat(...)
	PPCODE:
	PUTBACK;
	_watcher_repeat(THIS, items == 2? sv_mortalcopy(ST(1)) : 0);
	SPAGAIN;

void
pe_watcher::max_cb_tm(...)
	PPCODE:
	PUTBACK;
	_watcher_max_cb_tm(THIS, items == 2? sv_mortalcopy(ST(1)) : 0);
	SPAGAIN;

MODULE = Event		PACKAGE = Event::Watcher::Tied

void
allocate(clname, temple)
	SV *clname
	SV *temple
	PPCODE:
	if (!SvROK(temple)) croak("Bad template");
	XPUSHs(watcher_2sv(pe_tied_allocate(gv_stashsv(clname, 1),
					    SvRV(temple))));

void
pe_watcher::hard(...)
	PPCODE:
	PUTBACK;
	_timeable_hard(THIS, items == 2? sv_mortalcopy(ST(1)) : 0);
	SPAGAIN;

void
pe_watcher::at(...)
	PPCODE:
	PUTBACK;
	_tied_at(THIS, items == 2? sv_mortalcopy(ST(1)) : 0);
	SPAGAIN;

void
pe_watcher::flags(...)
	PPCODE:
	PUTBACK;
	_tied_flags(THIS, items == 2? sv_mortalcopy(ST(1)) : 0);
	SPAGAIN;

MODULE = Event		PACKAGE = Event::idle

void
allocate(clname, temple)
	SV *clname;
	SV *temple;
	PPCODE:
	if (!SvROK(temple)) croak("Bad template");
	XPUSHs(watcher_2sv(pe_idle_allocate(gv_stashsv(clname, 1),
			SvRV(temple))));

void
pe_watcher::hard(...)
	PPCODE:
	PUTBACK;
	_timeable_hard(THIS, items == 2? sv_mortalcopy(ST(1)) : 0);
	SPAGAIN;

void
pe_watcher::max(...)
	PPCODE:
	PUTBACK;
	_idle_max_interval(THIS, items == 2? sv_mortalcopy(ST(1)) : 0);
	SPAGAIN;

void
pe_watcher::min(...)
	PPCODE:
	PUTBACK;
	_idle_min_interval(THIS, items == 2? sv_mortalcopy(ST(1)) : 0);
	SPAGAIN;

MODULE = Event		PACKAGE = Event::timer

void
allocate(clname, temple)
	SV *clname;
	SV *temple;
	PPCODE:
	XPUSHs(watcher_2sv(pe_timer_allocate(gv_stashsv(clname, 1),
			SvRV(temple))));

void
pe_watcher::at(...)
	PPCODE:
	PUTBACK;
	_timer_at(THIS, items == 2? sv_mortalcopy(ST(1)) : 0);
	SPAGAIN;

void
pe_watcher::hard(...)
	PPCODE:
	PUTBACK;
	_timeable_hard(THIS, items == 2? sv_mortalcopy(ST(1)) : 0);
	SPAGAIN;

void
pe_watcher::interval(...)
	PPCODE:
	PUTBACK;
	_timer_interval(THIS, items == 2? sv_mortalcopy(ST(1)) : 0);
	SPAGAIN;

MODULE = Event		PACKAGE = Event::io

void
allocate(clname, temple)
	SV *clname;
	SV *temple;
	PPCODE:
	if (!SvROK(temple)) croak("Bad template");
	XPUSHs(watcher_2sv(pe_io_allocate(gv_stashsv(clname, 1),
			SvRV(temple))));

void
pe_watcher::poll(...)
	PPCODE:
	PUTBACK;
	_io_poll(THIS, items == 2? sv_mortalcopy(ST(1)) : 0);
	SPAGAIN;

void
pe_watcher::fd(...)
	PPCODE:
	PUTBACK;
	_io_handle(THIS, items == 2? sv_mortalcopy(ST(1)) : 0);
	SPAGAIN;

void
pe_watcher::timeout(...)
	PPCODE:
	PUTBACK;
	_io_timeout(THIS, items == 2? sv_mortalcopy(ST(1)) : 0);
	SPAGAIN;

void
pe_watcher::timeout_cb(...)
	PPCODE:
	PUTBACK;
	_io_timeout_cb(THIS, items == 2? sv_mortalcopy(ST(1)) : 0);
	SPAGAIN;

MODULE = Event		PACKAGE = Event::var

void
allocate(clname, temple)
	SV *clname;
	SV *temple;
	PPCODE:
	XPUSHs(watcher_2sv(pe_var_allocate(gv_stashsv(clname, 1),
		SvRV(temple))));

void
pe_watcher::var(...)
	PPCODE:
	PUTBACK;
	_var_variable(THIS, items == 2? ST(1) : 0); /* don't mortalcopy!! */
	SPAGAIN;

void
pe_watcher::poll(...)
	PPCODE:
	PUTBACK;
	_var_events(THIS, items == 2? sv_mortalcopy(ST(1)) : 0);
	SPAGAIN;

MODULE = Event		PACKAGE = Event::signal

void
allocate(clname, temple)
	SV *clname;
	SV *temple;
	PPCODE:
	XPUSHs(watcher_2sv(pe_signal_allocate(gv_stashsv(clname, 1),
		SvRV(temple))));

void
pe_watcher::signal(...)
	PPCODE:
	PUTBACK;
	_signal_signal(THIS, items == 2? sv_mortalcopy(ST(1)) : 0);
	SPAGAIN;

MODULE = Event		PACKAGE = Event::group

void
allocate(clname, temple)
     SV *clname;
     SV *temple;
     PPCODE:
     XPUSHs(watcher_2sv(pe_group_allocate(gv_stashsv(clname, 1),
		SvRV(temple))));

void
pe_watcher::timeout(...)
	PPCODE:
	PUTBACK;
	_group_timeout(THIS, items == 2? sv_mortalcopy(ST(1)) : 0);
	SPAGAIN;

void
pe_watcher::add(...)
	PPCODE:
	PUTBACK;
	_group_add(THIS, items == 2? sv_mortalcopy(ST(1)) : 0);
	SPAGAIN;

void
pe_watcher::del(...)
	PPCODE:
	PUTBACK;
	_group_del(THIS, items == 2? sv_mortalcopy(ST(1)) : 0);
	SPAGAIN;

MODULE = Event		PACKAGE = Event::generic

void
allocate(clname, temple)
     SV *clname;
     SV *temple;
     PPCODE:
     XPUSHs(watcher_2sv(pe_generic_allocate(gv_stashsv(clname, 1),
		SvRV(temple))));

void
pe_watcher::source(...)
	PPCODE:
	PUTBACK;
	_generic_source(THIS, items == 2? sv_mortalcopy(ST(1)) : 0);
	SPAGAIN;

MODULE = Event		PACKAGE = Event::generic::Source

void
allocate(clname, temple)
	SV *clname;
	SV *temple;
	PPCODE:
	if (!SvROK(temple)) croak("Bad template");
	XPUSHs(genericsrc_2sv(pe_genericsrc_allocate(gv_stashsv(clname, 1),
			SvRV(temple))));

void
DESTROY(ref)
	SV *ref;
	CODE:
{
	pe_genericsrc_dtor(sv_2genericsrc(ref));
}

void
pe_genericsrc::event(...)
	PPCODE:
	pe_genericsrc_event(THIS,
		items >= 2 ? sv_mortalcopy(ST(1)) : &PL_sv_undef);
