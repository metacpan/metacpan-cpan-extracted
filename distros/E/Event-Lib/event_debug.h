#ifndef _EVENT_DEBUG_H_
#define _EVENT_DEBUG_H_

#ifdef EVENT_LIB_DEBUG

#include "dhash.h"

#define print(fmt,...)	\
    PerlIO_printf(PerlIO_stderr(), fmt, __VA_ARGS__)
#define print_(fmt,...)	\
{   \
    print("________________________________________________________________________\n", NULL);\
    print(fmt"\n", __VA_ARGS__);	\
    print("------------------------------------------------------------------------\n", NULL);\
}


#define ENV(var)    (getenv(var) && atoi(getenv(var)))

#define DEBUG_warn(...)  \
    if (ENV("EVENT_LIB_DEBUG_DESTROY"))   \
	print_(__VA_ARGS__)

dhash_t EVENTS	    = { 0, 0, NULL };	/* record pending events */
dhash_t ALLO	    = { 0, 0, NULL };	/* record allocation and destruction of events */

int EVENT_NEW_COUNT = 0, 
    SIGNAL_NEW_COUNT = 0,
    TIMER_NEW_COUNT = 0;

#define DEBUG_init_count(...)	EVENT_NEW_COUNT = SIGNAL_NEW_COUNT = TIMER_NEW_COUNT = 0
#define DEBUG_inc_count(var)	var++

void DEBUG_init_pending (pTHX) {
    if (ENV("EVENT_LIB_DEBUG_PENDING")) {
	dhash_init(&EVENTS);
    }
    if (ENV("EVENT_LIB_DEBUG_ALLOCS") && ALLO.size == 0) {
	dhash_init(&ALLO);
    }
}

#define DUMP_one_event(i) \
{   \
        print("%i:\n", i);  \
	print("   flags: %i\n", EVENTS.ary[i].flags);	\
	print("   event: 0x%p\n", EVENTS.ary[i].ev);	\
}

#define DUMP_dhash(ev)	\
{			\
    if (ENV("EVENT_LIB_DEBUG_DHASH")) {\
    int i;		\
    print("__________\n", NULL);\
    print("%s for 0x%p\n", __FUNCTION__, ev);	\
    print("size:%i count:%i\n", EVENTS.size, EVENTS.count);\
    for (i = 0; i < EVENTS.size; i++)	\
	DUMP_one_event(i);		\
    print("----------\n", NULL);\
    }\
}

void DEBUG_record_event (pTHX_ SV *ev) {
    register int i;
    struct event_args *args = (struct event_args*)SvIV(SvRV(ev));
    dhash_val_t val = EMPTY;

    if (!ENV("EVENT_LIB_DEBUG_PENDING")) {
	return;
    }
    
    DUMP_dhash(args);

    /* barf when an event to be added already is in the hash. 
     * Exception is when in callback to allow something like this:
     *	 sub handler { my $ev; $ev->add }
     */
    if (!IN_CALLBACK)
	assert(dhash_find(&EVENTS, args) == NULL);
    
    if (dhash_find(&EVENTS, args)) {
	print("not adding element 0x%p again\n", args);
	goto done;
    }
    
    /* prepare the type of event */
    if (sv_derived_from(ev, "Event::Lib::timer"))
	val.flags |= EV_TIMEOUT;
    else if (sv_derived_from(ev, "Event::Lib::signal"))
	val.flags |= EV_SIGNAL|EV_PERSIST;
    else /* fh-event */
	val.flags = args->ev.ev_events;
   
    val.ev = args;
    dhash_store(&EVENTS, val);
    
done:
    DUMP_dhash(args);
}

void DEBUG_record_allo (pTHX_ SV *ev) {
    register int i;
    struct event_args *args = (struct event_args*)SvIV(SvRV(ev));
    dhash_val_t val = EMPTY;

    if (!ENV("EVENT_LIB_DEBUG_ALLOCS")) {
	return;
    }
    
    /* barf when an event to be added already is in the hash. 
     * Exception is when in callback to allow something like this:
     *	 sub handler { my $ev; $ev->add }
     */
    if (!IN_CALLBACK)
	assert(dhash_find(&ALLO, args) == NULL);
    
    if (dhash_find(&ALLO, args)) {
	print("not adding element 0x%p again\n", args);
	return;
    }
    
    /* prepare the type of event */
    if (sv_derived_from(ev, "Event::Lib::timer"))
	val.flags |= EV_TIMEOUT;
    else if (sv_derived_from(ev, "Event::Lib::signal"))
	val.flags |= EV_SIGNAL|EV_PERSIST;
    else /* fh-event */
	val.flags = args->evtype;
   
    val.ev = args;
    dhash_store(&ALLO, val);
}

void DEBUG_delete_event (pTHX_ SV *ev) {
    struct event_args *args = (struct event_args*)SvIV(SvRV(ev));
    SV *recref;

    if (!ENV("EVENT_LIB_DEBUG_PENDING")) {
	return;
    }
  
    DUMP_dhash(args);

    /* an event not yet set has never been added to EVENT 
     * so don't even try to delete it */
    if (!EvEVENT_SET(args) && !dhash_find(&EVENTS, args)) {
	print("Attempt to delete non-set event SV = 0x%x with event at 0x%x caught\n", ev, args);
	return;
    }
    
    assert(dhash_find(&EVENTS, args));
   
    dhash_delete(&EVENTS, args);
    
    DUMP_dhash(args);
}

void DEBUG_delete_allo (pTHX_ SV *ev) {
    struct event_args *args = (struct event_args*)SvIV(SvRV(ev));
    SV *recref;

    if (!ENV("EVENT_LIB_DEBUG_ALLOCS")) {
	return;
    }
  
    assert(dhash_find(&ALLO, args));
    dhash_delete(&ALLO, args);
}
 
#define DEBUG_get_pending_events(...)	\
    int i, j;				\
    if (!ENV("EVENT_LIB_DEBUG_PENDING")) { \
	XSRETURN_EMPTY;			\
    }					\
    EXTEND(SP, EVENTS.count);		\
    for (i = 0, j = 0; i <= EVENTS.size; i++) { \
	if (!EVENTS.ary[i].ev)		\
	    continue;			\
	ST(j) = (SV*)EVENTS.ary[i].ev->ev.ev_arg;  \
	j++;				\
    }					\
    XSRETURN(EVENTS.count)		\

void DEBUG_dump_pending_events (pTHX) {
    
    register int i;

    if (!ENV("EVENT_LIB_DEBUG_PENDING")) {
	return;
    }

    if (EVENTS.count == 0) {
	print("No pending events\n", NULL);
	return;
    }
    
    for (i = 0; i < EVENTS.size; i++) {
	int type;
	struct event_args *ev;
	
	if (!EVENTS.ary[i].ev)
	    continue;

	ev = EVENTS.ary[i].ev;
	type = EVENTS.ary[i].flags;

	print("EV = 0x%p\n", ev);
	print("   type   = ", NULL);
	if (type & EV_PERSIST) {
	    print("EV_PERSIST | ", NULL);
	    type &= ~EV_PERSIST;
	}
	if (type & EV_TIMEOUT)	    print("EV_TIMEOUT", NULL);
	else if (type & EV_SIGNAL)  print("EV_SIGNAL", NULL);
	else if (type & EV_READ)    print("EV_READ", NULL);
	else if (type & EV_WRITE)   print("EV_WRITE", NULL);
	else if (type & EV_READ &&
		 type & EV_WRITE)   print("EV_READ | EV_WRITE", NULL);
	if (type & 0x20)	    print(" | EVf_EVENT_TRACED", NULL);
	print("\n", NULL);
	print("   args   = %i\n", ev->num);
	print("   refcnt = %i\n", SvREFCNT((SV*)ev->ev.ev_arg));
	print("   cback  = %s\n", ev->cbname);
	if (type & (EV_READ|EV_WRITE)) 
	    print("   fhid   = %s from %s:%i (fd=%i)\n", 
		    GvNAME((GV*)SvRV(ev->io)), 
		    GvFILE((GV*)SvRV(ev->io)),
		    GvLINE((GV*)SvRV(ev->io)),
		    ev->ev.ev_fd);
    }
    print("----------------------------------------------------------------------------\n", NULL);
    print("total: %i events still pending\n", EVENTS.count);
}	

void DEBUG_dump_allocated (pTHX) {
    
    register int i;

    if (!ENV("EVENT_LIB_DEBUG_ALLOCS")) {
	return;
    }

    if (ALLO.count == 0) {
	print("No allocated events\n", NULL);
	return;
    }
    
    for (i = 0; i < ALLO.size; i++) {
	int type;
	struct event_args *ev;
	
	if (!ALLO.ary[i].ev)
	    continue;

	ev = ALLO.ary[i].ev;
	type = ALLO.ary[i].flags;

	print("EV = 0x%p\n", ev);
	print("   type   = ", NULL);
	if (type & EV_PERSIST) {
	    print("EV_PERSIST | ", NULL);
	    type &= ~EV_PERSIST;
	}
	if (type & EV_TIMEOUT)	    print("EV_TIMEOUT", NULL);
	else if (type & EV_SIGNAL)  print("EV_SIGNAL", NULL);
	else if (type & EV_READ)    print("EV_READ", NULL);
	else if (type & EV_WRITE)   print("EV_WRITE", NULL);
	else if (type & EV_READ &&
		 type & EV_WRITE)   print("EV_READ | EV_WRITE", NULL);
	if (type & 0x20)	    print(" | EVf_EVENT_TRACED", NULL);
	print("\n", NULL);
	print("   args   = %i\n", ev->num);
	print("   cback  = %s\n", ev->cbname);
	print("   loc    = %s\n", SvPV_nolen(ev->loc));
	if (type & (EV_READ|EV_WRITE)) 
	    print("   fhid   = %s from %s:%i (fd=%i)\n", 
		    GvNAME((GV*)SvRV(ev->io)), 
		    GvFILE((GV*)SvRV(ev->io)),
		    GvLINE((GV*)SvRV(ev->io)),
		    ev->ev.ev_fd);
    }
    print("----------------------------------------------------------------------------\n", NULL);
    print("total: %i events still allocated\n", ALLO.count);
}

#define DEBUG_trace(e)		    \
{				    \
    if (EvEVENT_TRACED(e)) {	    \
	print("________________________________________________________________________\n", NULL);  \
	print("EV = 0x%p (%s) (%s)\n  (from %s)\n  touched at %s (%i)\n  (by %s:%d)\n", \
		 e, e->type, e->cbname, SvPV_nolen(e->loc), __FUNCTION__, __LINE__,	\
		 CopFILE(PL_curcop) ? CopFILE(PL_curcop) : "unknown", \
		 CopLINE(PL_curcop) ? CopLINE(PL_curcop) : -1);	\
	if (EvEVENT_SET(e))	{ \
	    sv_dump((SV*)e->ev.ev_arg); \
	    if (event_initialized(&e->ev) && SvOK((SV*)e->ev.ev_arg))	    \
		sv_dump((SV*)SvRV((SV*)e->ev.ev_arg));	\
	}\
	print ("------------------------------------------------------------------------\n", NULL);  \
    } \
}
   
void DEBUG_store_location (pTHX_ struct event_args* args) {
    New(0, args->cbname, strlen(HvNAME(GvSTASH(CvGV(args->func)))) + 
			 strlen("::") + 
			 strlen(GvNAME(CvGV(args->func))) + 1, char);
    sprintf(args->cbname, "%s::%s", HvNAME(GvSTASH(CvGV(args->func))), GvNAME(CvGV(args->func)));
    if (CopFILE(PL_curcop) && CopLINE(PL_curcop))
	args->loc = newSVpvf("%s:%d", CopFILE(PL_curcop), CopLINE(PL_curcop));
    else
	args->loc = newSVpv("unknown location", 0);
}

#else
#   define DEBUG_init_count(...)
#   define DEBUG_inc_count(...)
#   define DEBUG_warn(...)
#   define DEBUG_enter_callback(...)
#   define DEBUG_leave_callback(...)
#   define DEBUG_init_pending(...)
#   define DEBUG_record_event(...)
#   define DEBUG_record_allo(...)
#   define DEBUG_delete_event(...)
#   define DEBUG_delete_allo(...)
#   define DEBUG_get_pending_events(...)
#   define DEBUG_dump_pending_events(...)
#   define DEBUG_dump_allocated(...)
#   define DEBUG_trace(...)
#   define DEBUG_store_location(...)
#   define EVENT_NEW_COUNT  -1
#   define SIGNAL_NEW_COUNT -1
#   define TIMER_NEW_COUNT  -1
#endif

#endif	/* _EVENT_DEBUG_H_ */
