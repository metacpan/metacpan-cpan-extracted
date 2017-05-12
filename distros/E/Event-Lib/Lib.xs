#ifdef WIN32
#undef read
#undef write
#else
#include <sys/time.h>
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <event.h>
#include <assert.h>

/* shut up a compiler warning: ppport.h redefines
 * PERL_UNUSED_DECL already defined in perl.h */
#ifdef PERL_UNUSED_DECL
#   undef PERL_UNUSED_DECL
#endif

#include "ppport.h"

#include "const-c.inc"

#define CALLBACK_CAST	(void (*)(int, short, void*))
#define to_perlio(sv)	IoIFP(sv_2io(sv))
#define is_event(sv)	(SvTYPE(sv) == SVt_RV && sv_derived_from(sv, "Event::Lib::base"))

#define	EV_TRACE	    0x20

#define EVf_EVENT_SET	    0x00000001
#define EVf_PRIO_SET	    0x00000002
#define EVf_EVENT_DELETED   0x00000004
#define EVf_EVENT_TRACED    0x00000010	

#define EvFLAGS(ev)	    (ev->flags)

#define EvEVENT_SET(ev)		(EvFLAGS(ev) & EVf_EVENT_SET)
#define EvEVENT_SET_on(ev)	EvFLAGS(ev) |= EVf_EVENT_SET
#define EvEVENT_SET_off(ev)	EvFLAGS(ev) &= ~EVf_EVENT_SET

#define EvPRIO_SET(ev)		(EvFLAGS(ev) & EVf_PRIO_SET)
#define EvPRIO_SET_on(ev)	EvFLAGS(ev) |= EVf_PRIO_SET
#define EvPRIO_SET_off(ev)	EvFLAGS(ev) &= ~EVf_PRIO_SET

#define EvEVENT_TRACED(ev)	(EvFLAGS(ev) & EVf_EVENT_TRACED)
#define EvEVENT_TRACED_on(ev)	EvFLAGS(ev) |= EVf_EVENT_TRACED
#define EvEVENT_TRACED_off(ev)	EvFLAGS(ev) &= ~EVf_EVENT_TRACED

#define IN_GLOBAL_CLEANUP PL_dirty

SV * do_exception_handler (pTHX_ short event, SV *ev, SV *err);
void do_callback (int fd, short event, SV *ev);

struct event_args {
    struct event    ev;		/* the event that was triggered */
    SV		    *io;	/* the associated filehandle */
    CV		    *func;	/* the Perl callback to handle event */
    int		    num;	/* number of additional args */
    int		    buckets;	/* number of allocated slots for args (buckets >= args) */
    SV		    **args;	/* additional args */
    const char	    *type;	/* so we know into which class to bless in do_callback */
    CV		    *trapper;	/* exception handler */
    int		    evtype;	/* what kind of event or signal; always 0 for timer events */
    int		    priority;	/* what priority */
    int		    flags;	/* EVf_EVENT_SET, EVf_PRIO_SET */
#ifdef EVENT_LIB_DEBUG
    SV		    *loc;	/* location information: where was event created */
    char	    *cbname;	/* name of the callback */
#endif
};


CV *DEFAULT_EXCEPTION_HANDLER = NULL;

/* The following flag is set when we are inside a callback.  It is to prevent
 * incrementing of the reference-count of a an event when it is re-added from
 * inside its handler.  However, in order to allow something like that:
 *
 *  sub event_handler {
 *	my $ev = shift;
 *	...
 *	timer_new(...)->add(1);
 *  }
 *  
 * we additionally have to check if the currently executing event is to be
 * re-added (in this case: no refcnt++) or if another event was added (in this
 * case: refcnt++). 
 *
 * Therefore we have to store the address of the currently executing event in
 * IN_CALLBACK and a simply true/false flag wont do.
 *
 * If we don't do that, we get a refcount-to-infinity problem because
 * do_callback wont decrement the refcnt of an event when it's pending. And i
 * is certainly pending when it has been readded from within its handler.
 */
struct event_args *IN_CALLBACK = NULL;
#define ENTER_callback(ev)	IN_CALLBACK = ev
#define LEAVE_callback		IN_CALLBACK = NULL
#define RUNNING_callback(ev)	((ev) == IN_CALLBACK)

#include "event_debug.h"

void free_args (struct event_args *args) {
    
    register int i;

    if (args->io) {
	SvREFCNT_dec(args->io);
    }
   
    SvREFCNT_dec(args->func);
    for (i = 0; i < args->num; ++i)
	SvREFCNT_dec(args->args[i]);

    Safefree(args->args);

    if (args->trapper != DEFAULT_EXCEPTION_HANDLER)
	SvREFCNT_dec(args->trapper);

#ifdef EVENT_LIB_DEBUG
    SvREFCNT_dec(args->loc);
    Safefree(args->cbname);
#endif
    Safefree(args);
}

void refresh_event (struct event_args *args, char *class) {
    SV *sv = newSV(0);
    sv_setref_pv(sv, class, (void*)args);
    args->ev.ev_arg = (void*)sv;
}

SV * do_exception_handler (pTHX_ short event, SV *ev, SV *err) {
    register int i;
    int count;
    struct event_args *args = (struct event_args*)SvIV(SvRV(ev));

    dSP;
    
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    
    EXTEND(SP, event ? args->num + 3 : 2);
    PUSHs(ev);
    
    PUSHs(sv_2mortal(err));

    if (event) {
	PUSHs(sv_2mortal(newSViv(event)));
	for (i = 0; i < args->num; i++)
	    PUSHs(args->args[i]);
    }
    

    PUTBACK;
    count = call_sv((SV*)args->trapper, G_SCALAR|G_EVAL);
    
    if (SvTRUE(ERRSV))
	croak(Nullch);
    
    SPAGAIN;
    
    if (count != 1)
	ev = &PL_sv_undef;
    else
	ev = POPs;
    
    PUTBACK;
    FREETMPS;
    LEAVE;

    return ev;
}

void do_callback (int fd, short event, SV *ev) {
    register int i;
    struct event_args *args = (struct event_args*)SvIV(SvRV(ev));
    dSP;

    DEBUG_trace(args);
    
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    
    EXTEND(SP, args->num + 2);

    PUSHs(ev);
    PUSHs(sv_2mortal(newSViv(event)));

    for (i = 0; i < args->num; ++i)
	PUSHs(args->args[i]);

    /* !!! START OF CALLBACK SECTION !!! */
    ENTER_callback(args);
    
    PUTBACK;
    call_sv((SV*)args->func, G_VOID|G_DISCARD|G_EVAL);
    if (SvTRUE(ERRSV))
	do_exception_handler(aTHX_ event, ev, newSVsv(ERRSV));
    
    LEAVE_callback;
    /* !!! END OF CALLBACK SECTION !!! */

    /* It's possible that the event was manually deleted inside the
     * handlers, in which case the ref-cnt has already been decremented */
    if (!event_pending(&args->ev, event, NULL)) {
	EvEVENT_SET_off(args);
    	SvREFCNT_dec((SV*)args->ev.ev_arg);
	if (SvOK(ev))
	    DEBUG_trace(args);
    }

    SPAGAIN;
    PUTBACK;
    FREETMPS;
    LEAVE;
}


#ifdef WIN32
#define THEINLINE __forceinline
#else
#define THEINLINE inline
#endif

THEINLINE void make_timeval (struct timeval *tv, double t) {
    tv->tv_sec = (long)t;
    tv->tv_usec = (t - (long)t) * 1e6f;
}

THEINLINE double delta_timeval (struct timeval *t1, struct timeval *t2) {
    double t1t = t1->tv_sec + (double)t1->tv_usec / 1e6f;
    double t2t = t2->tv_sec + (double)t2->tv_usec / 1e6f; 
    return t2t - t1t;
}

#ifdef HAVE_LOG_CALLBACKS
unsigned int LOG_LEVEL = _EVENT_LOG_ERR;
static const char* str[] = { "debug", "msg", "warn", "err", "???" };

void log_cb (int sev, const char *msg) {
    if (sev >= LOG_LEVEL) {
	if (sev > _EVENT_LOG_ERR) 
	    sev = _EVENT_LOG_ERR + 1;
	PerlIO_printf(PerlIO_stderr(), "[%s (pid=%i)] %s\n", str[sev], getpid() , msg);
    }
}
#endif

bool EVENT_LOOP_RUNNING = FALSE;
int  EVENT_INIT_DONE = -1;  /* we use the pid here */

#define event_do_init()	    \
{\
    int _pid_ = SvIV(get_sv("$", FALSE)); \
    if (!EVENT_INIT_DONE  || EVENT_INIT_DONE != _pid_) {\
	event_init();	\
	DEBUG_init_pending(aTHX);   \
	DEBUG_init_count(aTHX);	    \
	EVENT_INIT_DONE = _pid_;    \
	IN_CALLBACK = 0;	    \
    }\
}

MODULE = Event::Lib		PACKAGE = Event::Lib		

INCLUDE: const-xs.inc

BOOT:
{
    if (getenv("EVENT_LOG_LEVEL"))
	LOG_LEVEL = atoi(getenv("EVENT_LOG_LEVEL"));
#ifdef HAVE_LOG_CALLBACKS
    event_set_log_callback(log_cb);
#endif
    event_do_init();
    DEFAULT_EXCEPTION_HANDLER = newXS(NULL, XS_Event__Lib__default_callback, __FILE__);
}

void
_default_callback (...)
CODE:
{
    sv_setsv(ERRSV, ST(1));
    croak(Nullch);
    PERL_UNUSED_VAR(items); /* to silence the compiler */
}
 
void
event_init()
PROTOTYPE:
CODE:
{
    event_do_init();
}

const char *
event_get_method()
ALIAS:
    Event::Lib::get_method = 0

const char *
event_get_version()
ALIAS:
    Event::Lib::get_version = 0

void
event_log_level (level)
    unsigned int level;
CODE:
{
#ifdef HAVE_LOG_CALLBACKS
    LOG_LEVEL = level;
#endif
}

void
event_register_except_handler (func)
    SV *func;
CODE:
{
    if (!SvROK(func) && (SvTYPE(SvRV(func)) != SVt_PVCV))
	croak("Argument to event_register_except_handler must be code-reference");
    DEFAULT_EXCEPTION_HANDLER = (CV*)SvRV(func);
}

int
event_priority_init (nump)
    int nump;
PROTOTYPE: $
CODE:
{
    event_do_init();
#ifdef HAVE_PRIORITIES
    RETVAL = event_priority_init(nump);
#else
    RETVAL = 1;
#endif
}
OUTPUT:
    RETVAL

struct event_args *
event_new (io, event, func, ...)
    SV	    *io;
    short   event;
    SV	    *func;
PREINIT:
    static char *CLASS = "Event::Lib::event";
    struct event_args *args;
CODE:
{
    register int i;

    if (GIMME_V == G_VOID)
	XSRETURN_UNDEF;

    if (!SvROK(func) && (SvTYPE(SvRV(func)) != SVt_PVCV))
	croak("Third argument to event_new must be code-reference");
  
    event_do_init();

    New(0, args, 1, struct event_args); 

    args->io = io;
    args->func = (CV*)SvRV(func);
    args->type = CLASS;
    args->trapper = DEFAULT_EXCEPTION_HANDLER;
    args->evtype = event;
    args->priority = -1;

    EvFLAGS(args) = 0;

    DEBUG_store_location(aTHX_ args);
#ifdef EVENT_LIB_DEBUG
    /* is it a traced event? */
    if (event & EV_TRACE) {
	EvFLAGS(args) |= EVf_EVENT_TRACED;
	event &= ~EV_TRACE;
    }
#endif

    SvREFCNT_inc(args->io);
    SvREFCNT_inc(args->func);

    if ((args->buckets = args->num = items - 3)) 
	New(0, args->args, args->buckets, SV*);
    else
	args->args = NULL;

    for (i = 0; i < args->num; i++) {
	args->args[i] = ST(i+3);
	SvREFCNT_inc(args->args[i]);
    }

    RETVAL = args;
}
OUTPUT:
    RETVAL
POSTCALL:
    DEBUG_inc_count(EVENT_NEW_COUNT);
CLEANUP:
    DEBUG_record_allo(aTHX_ ST(0));

struct event_args *
signal_new (signal, func, ...)
    int signal;
    SV	*func;
PREINIT:
    static char *CLASS = "Event::Lib::signal";
    struct event_args *args;
CODE:
{
    register int i;
    
    if (GIMME_V == G_VOID)
	XSRETURN_UNDEF;
    
    if (!SvROK(func) && (SvTYPE(SvRV(func)) != SVt_PVCV))
	croak("Second argument to event_new must be code-reference");
   
    event_do_init();

    New(0, args, 1, struct event_args);

    args->io = NULL;
    args->func = (CV*)SvRV(func);
    args->type = CLASS;
    args->trapper = DEFAULT_EXCEPTION_HANDLER;
    args->evtype = signal;
    args->priority = -1;

    EvFLAGS(args) = 0;

    DEBUG_store_location(aTHX_ args);

    SvREFCNT_inc(args->func);
    
    if ((args->buckets = args->num = items - 2))
	New(0, args->args, args->buckets, SV*);
    else
	args->args = NULL;

    for (i = 0; i < args->num; i++) {
	args->args[i] = ST(i+2);
	SvREFCNT_inc(args->args[i]);
    }

    RETVAL = args;
}
OUTPUT:
    RETVAL
POSTCALL:
    DEBUG_inc_count(SIGNAL_NEW_COUNT);
CLEANUP:
    DEBUG_record_allo(aTHX_ ST(0));

struct event_args *
timer_new (func, ...)
    SV *func;
PREINIT:
    static char *CLASS = "Event::Lib::timer";
    struct event_args *args;
CODE:
{
    register int i;

    if (GIMME_V == G_VOID)
	XSRETURN_UNDEF;
    
    if (!SvROK(func) && (SvTYPE(SvRV(func)) != SVt_PVCV))
	croak("First argument to timer_new must be code-reference");
   
    event_do_init();

    New(0, args, 1, struct event_args);
    
    args->io = NULL;
    args->func = (CV*)SvRV(func);
    args->type = CLASS;
    args->trapper = DEFAULT_EXCEPTION_HANDLER;
    args->evtype = 0;
    args->priority = -1;

    EvFLAGS(args) = 0;

    DEBUG_store_location(aTHX_ args);

    SvREFCNT_inc(args->func);
    
    if ((args->buckets = args->num = items - 1))
	New(0, args->args, args->buckets, SV*);
    else
	args->args = NULL;

    for (i = 0; i < args->num; i++) {
	    args->args[i] = ST(i+1);
	    SvREFCNT_inc(args->args[i]);
    }

    RETVAL = args;
}
OUTPUT:
    RETVAL
POSTCALL:
    DEBUG_inc_count(TIMER_NEW_COUNT);
CLEANUP:
    DEBUG_record_allo(aTHX_ ST(0));

void
event_add (args, ...)
    struct event_args *args;
CODE:
{
#define FORMAT		"[event_add] ev = 0x%p (%s)\n  (from %s)\n  (by %s:%d)"
    
    struct timeval tv = { 1, 0 };
    int time_given = 0;
    int exception_flag = 0;
    
    DEBUG_trace(args);

    if (!EvEVENT_SET(args)) {
	DEBUG_warn(FORMAT, args, args->type, SvPV_nolen(args->loc),
		   CopFILE(PL_curcop) ? CopFILE(PL_curcop) : "unknown",
		   CopLINE(PL_curcop) ? CopLINE(PL_curcop) : -1);
	if (strEQ(args->type, "Event::Lib::event")) {
	    PerlIO *io = to_perlio(args->io);
	    int fd = io ? PerlIO_fileno(to_perlio(args->io)) : -1;
	    event_set(&args->ev, fd, (short)args->evtype, CALLBACK_CAST do_callback, (void*)ST(0));
	    if (fd == -1) {
		/* We always call event_set even when fd is potentially -1.
		 * This is only so that the exception handler is called with a
		 * proper event. However, we don't set the EvEVENT_SET flag so
		 * that this event will again be event_set()ed next time. */
		errno = EBADF;
		exception_flag = -args->evtype;
		goto force_failure;
	    }
	}
	else if (strEQ(args->type, "Event::Lib::signal")) {
	    signal_set(&args->ev, args->evtype, CALLBACK_CAST do_callback, (void*)ST(0));
	    exception_flag = -args->evtype;
	}
	else if (strEQ(args->type, "Event::Lib::timer")) {
	    evtimer_set(&args->ev, CALLBACK_CAST do_callback, (void*)ST(0));
	    exception_flag = -EV_TIMEOUT;
	}
	EvEVENT_SET_on(args);
	DEBUG_trace(args);
    } else if (event_pending(&args->ev, EV_TIMEOUT|EV_READ|EV_WRITE|EV_SIGNAL, NULL))
	croak("Attempt to add event a second time");
#ifdef HAVE_PRIORITIES
    if (!EvPRIO_SET(args)) {
	event_priority_set(&args->ev, args->priority);
	EvPRIO_SET_on(args);
    }
#endif

    if (sv_derived_from(ST(0), "Event::Lib::timer") && items == 1)
	time_given = 1;

    if (items > 1) {

	/* add(0) should behave like add() */
	if (SvIOK(ST(1)) && SvIV(ST(1)) == 0)
	    goto skip;
	
	make_timeval(&tv, SvNV(ST(1)));
	time_given = 1;
    }
    
    skip:
    if (event_add(&args->ev, time_given ? &tv : NULL) == 0) {
	
	/* Are we trying to re-add the currently executing event? */
	if (RUNNING_callback(args)) {
	    XSRETURN(1);
	}
	
	/* Nope, it's another event so it's ok to increment the ref-cnt */
	SvREFCNT_inc((SV*)args->ev.ev_arg);
	DEBUG_record_event(aTHX_ ST(0));
	DEBUG_trace(args);
	XSRETURN(1);
    }

    force_failure:
    /* event_add failed :-( */
    do_exception_handler(aTHX_ exception_flag, ST(0), newSVpvn("Couldn't add event", 18));
}	
POSTCALL:

void
event_free (args, flags = 0)
    struct event_args *args;
    int flags;
CODE:
{
    if (!flags)
	warn("You should not call event_free unless it's an emergency");
    
    event_del(&args->ev);
    free_args(args);

    /* unbless referent:
     * this is crucial because access to the object after it
     * has been freed could lead to segfaults */
    SvFLAGS(SvRV(ST(0))) &= ~SVs_OBJECT;
}

void
event_mainloop ()
PROTOTYPE: 
CODE:
{
    int ret;
    if (EVENT_LOOP_RUNNING) {
	warn("Attempt to trigger another loop while the main-loop is already running");
	return;
    }

    EVENT_LOOP_RUNNING = TRUE;
    ret = event_dispatch();
    EVENT_LOOP_RUNNING = FALSE;
    if (ret == 1)
	XSRETURN_YES;
    else
	XSRETURN_NO;
}

void
event_one_loop (...)
PROTOTYPE: ;$
CODE:
{
    if (EVENT_LOOP_RUNNING) {
	warn("Attempt to trigger another loop while the main-loop is already running");
	return;
    }

    if (items > 0) {
	struct timeval tv;
	make_timeval(&tv, SvNV(ST(0)));
	event_loopexit(&tv);
    }
    event_loop(EVLOOP_ONCE);
}

void
event_one_nbloop ()
PROTOTYPE:
CODE:
{
    event_loop(EVLOOP_NONBLOCK);
}

MODULE = Event::Lib		PACKAGE = Event::Lib::base

void
remove (args)
    struct event_args *args;
CODE:
{
    /*******************************************************
     * !! THIS FUNCTION IS OVERRIDDEN FOR SIGNAL-EVENTS !! *
     *******************************************************/

    DEBUG_trace(args);

    if (!EvEVENT_SET(args)) {
	DEBUG_trace(args);
	XSRETURN_NO;
    }

    if (event_pending(&args->ev, EV_TIMEOUT|EV_READ|EV_WRITE, NULL) 
	&& event_del(&args->ev) == 0) {
	EvEVENT_SET_off(args);

	/* when called from inside a callback, we defer this
	 * SvREFCNT_dec. do_callback will do it for us. This
	 * is to prevent that the event is already DESTROYed
	 * from inside the handler which cannot be detected
	 * in do_callback. */
	if (!RUNNING_callback(args))
	    /* We are not using ST(0) here but instead the loop-back
	     * object stored inside the event because this is what is
	     * decremented in do_callback and incremented in event_add */
	    SvREFCNT_dec((SV*)args->ev.ev_arg);

	DEBUG_trace(args);
    }
    
    DEBUG_trace(args);
    XSRETURN_NO;
}
 
void
except_handler (args, func)
    struct event_args *args;
    SV *func;
CODE:
{
    if (!SvROK(func) && (SvTYPE(SvRV(func)) != SVt_PVCV))
	croak("Argument to event_register_except_handler must be code-reference");
    args->trapper = (CV*)SvRV(func);
    SvREFCNT_inc(args->trapper);
    XSRETURN(1);
}
    
void
callback (args)
    struct event_args *args;
CODE:
{
    ST(0) = sv_2mortal(newRV_inc((SV*)args->func));
    XSRETURN(1);
}

void
args (args, ...)
    struct event_args *args;
CODE:
{
    register int i;
    
    if (items == 1) {
	/* arguments are merely queried */
	U32 gimme = GIMME_V;
	switch (gimme) {
	    case G_VOID:
		return;
	    case G_SCALAR:
		ST(0) = sv_2mortal(newSViv(args->num));
		XSRETURN(1);
	    case G_ARRAY:
		EXTEND(SP, args->num);
		for (i = 0; i < args->num; ++i)
		    ST(i) = args->args[i];
		XSRETURN(args->num);
	}
    }

    /* items > 1: arguments are replaced */

    for (i = 0; i < args->num; ++i)
	SvREFCNT_dec(args->args[i]);
    if (items - 1 > args->buckets) {
	args->buckets = items - 1;
	Renew(args->args, args->buckets, SV*);
    }
    args->num = items - 1;
    for (i = 0; i < args->num; ++i) {
	args->args[i] = ST(i+1);
	SvREFCNT_inc(args->args[i]);
    }
}	

void
args_del (args)
    struct event_args *args;
CODE:
{
    register int i;
    for (i = 0; i < args->num; ++i)
	SvREFCNT_dec(args->args[i]);
    args->num = 0;
}

void
set_priority (args, prio)
    struct event_args *args;
    int prio;
CODE:
{
    args->priority = prio;
}

void
trace (args)
    struct event_args *args;
CODE:
{
    EvEVENT_TRACED_on(args);
    XSRETURN(1);
}
    
MODULE = Event::Lib             PACKAGE = Event::Lib::event

void
fh (args)
    struct event_args *args;
CODE:
{
    DEBUG_trace(args);
    ST(0) = args->io;
    XSRETURN(1);
}

void
pending (args)
    struct event_args *args;
CODE:
{
    struct timeval tv = { 0, 0 }, now;
    SV *sv;
    
    gettimeofday(&now, NULL);

    if (!event_pending(&args->ev, EV_READ|EV_WRITE|EV_TIMEOUT, &tv))
	XSRETURN_NO;
    
    if (tv.tv_sec == 0 && tv.tv_usec == 0)
	sv = newSVpvn("0 but true", 10);
    else 
	sv = newSVnv(fabs(delta_timeval(&now, &tv)));

    ST(0) = sv_2mortal(sv);
    XSRETURN(1);
}

void
DESTROY (args)
    struct event_args *args;
CODE:
{
    DEBUG_trace(args);
    DEBUG_warn("[DESTROY]   ev = 0x%p (%s)\n  (from %s)", args, args->type, SvPV_nolen(args->loc));
    
    /* We get to DESTROY a pending event:
     * This can happen when an event object was explictely 
     * reassigned to or when undef() was called on it.
     * We DO NOT delete and free it. Instead we issue a warning
     * disassociate this event from ST(0) and keep it pending */
    if (!IN_GLOBAL_CLEANUP && 
	EvEVENT_SET(args) && event_pending(&args->ev, EV_READ|EV_WRITE, NULL)) {
	if (ckWARN(WARN_MISC))
	    warn("Explicit undef() of or reassignment to pending event");
	refresh_event(args, HvNAME(SvSTASH(SvRV(ST(0)))));
	XSRETURN_EMPTY;
    }
    
    DEBUG_delete_event(aTHX_ ST(0));
    DEBUG_delete_allo(aTHX_ ST(0));

    free_args(args);
}


MODULE = Event::Lib             PACKAGE = Event::Lib::signal

void
pending (args)
    struct event_args *args;
CODE:
{
    struct timeval tv = { 0, 0 }, now;
    SV *sv;
    
    DEBUG_trace(args);

    gettimeofday(&now, NULL);
    
    if (!signal_pending(&args->ev, &tv))
	XSRETURN_NO;
    
    if (tv.tv_sec == 0 && tv.tv_usec == 0)
	sv = newSVpvn("0 but true", 10);
    else 
	sv = newSVnv(fabs(delta_timeval(&now, &tv)));

    ST(0) = sv_2mortal(sv);
    XSRETURN(1);
}
 
void
remove (args)
    struct event_args *args;
CODE:
{

    /******************************************
     * !! OVERRIDING Event::Lib::base::remove !! *
     ******************************************/

    /* XXX This works for the test-suite but who knows.
     * XXX The culprit is that signal-events behave
     * XXX differently: They are per default persistent.
     * XXX Still, additional logic may be required here. */
    if (event_del(&args->ev) == 0) {
	EvEVENT_SET_off(args);
	XSRETURN_YES;
    }

    XSRETURN_NO;
}

void
DESTROY (args)
    struct event_args *args;
CODE:
{

    DEBUG_warn("[DESTROY]   ev = 0x%p (%s)\n  (from %s)", args, args->type, SvPV_nolen(args->loc));
    DEBUG_trace(args);
    
    /* We get to DESTROY a pending event:
     * This can happen when an event object was explictely 
     * reassigned to or when undef() was called on it.
     * We DO NOT delete and free it. Instead we issue a warning
     * disassociate this event from ST(0) and keep it pending */
    if (!IN_GLOBAL_CLEANUP &&
	EvEVENT_SET(args) && signal_pending(&args->ev, NULL)) {
	if (ckWARN_d(WARN_MISC))
	    warn("Explicit undef() of or reassignment to pending event");
	refresh_event(args, HvNAME(SvSTASH(SvRV(ST(0)))));
	XSRETURN_EMPTY;
    }
    
    DEBUG_delete_event(aTHX_ ST(0));
    DEBUG_delete_allo(aTHX_ ST(0));

    free_args(args);
}


MODULE = Event::Lib		PACKAGE = Event::Lib::timer

void
pending (args)
    struct event_args *args;
CODE:
{
    struct timeval tv = { 0, 0 }, now;
    SV *sv;

    gettimeofday(&now, NULL);
    
    if (!evtimer_pending(&args->ev, &tv))
	XSRETURN_NO;
    
    if (tv.tv_sec == 0 && tv.tv_usec == 0)
	sv = newSVpvn("0 but true", 10);
    else 
	sv = newSVnv(fabs(delta_timeval(&now, &tv)));

    ST(0) = sv_2mortal(sv);
    XSRETURN(1);
}

void
DESTROY (args)
    struct event_args *args;
CODE:
{
    DEBUG_warn("[DESTROY]   ev = 0x%p (%s)\n  (from %s)", args, args->type, SvPV_nolen(args->loc));
    DEBUG_trace(args);

    /* We get to DESTROY a pending event:
     * This can happen when an event object was explictely 
     * reassigned to or when undef() was called on it.
     * We DO NOT delete and free it. Instead we issue a warning
     * disassociate this event from ST(0) and keep it pending */
    if (!IN_GLOBAL_CLEANUP &&
	EvEVENT_SET(args) && evtimer_pending(&args->ev, NULL)) {
	if (ckWARN(WARN_MISC))
	    warn("Explicit undef() of or reassignment to pending event");
	refresh_event(args, HvNAME(SvSTASH(SvRV(ST(0)))));
	XSRETURN_EMPTY;
    }

    DEBUG_delete_event(aTHX_ ST(0));
    DEBUG_delete_allo(aTHX_ ST(0));

    free_args(args);
}

MODULE = Event::Lib             PACKAGE = Event::Lib::Debug

void
get_pending_events ()
CODE:
{
    DEBUG_get_pending_events(aTHX);
}
   
void
dump_pending_events ()
CODE:
{
    DEBUG_dump_pending_events(aTHX);
}

void
dump_allocated_events ()
CODE:
{
    DEBUG_dump_allocated(aTHX);
}

void
dump_event_count ()
CODE:
{
    PerlIO_printf(PerlIO_stderr(), "%i: fh:%i signal:%i timer:%i\n", getpid(), 
				   EVENT_NEW_COUNT, SIGNAL_NEW_COUNT, TIMER_NEW_COUNT);
}
