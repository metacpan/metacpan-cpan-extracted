#ifndef _event_api_H_
#define _event_api_H_

/*
  The API for the operating system dictates which events are
  truly asyncronous.  Event needs C-level support only for
  these types of events.
 */

typedef struct pe_watcher_vtbl pe_watcher_vtbl;
typedef struct pe_watcher pe_watcher;
typedef struct pe_event_vtbl pe_event_vtbl;
typedef struct pe_event pe_event;
typedef struct pe_ring pe_ring;

struct pe_ring { void *self; pe_ring *next, *prev; };

struct pe_watcher {
    pe_watcher_vtbl *vtbl;
    SV *mysv;
    NV cbtime; /* float? XXX */
    void *callback;
    void *ext_data;
    void *stats;
    int running; /* SAVEINT */
    U32 flags;
    SV *desc;
    pe_ring all;	/* all watchers */
    pe_ring events;	/* this watcher's queued events */
    HV *FALLBACK;
    I16 refcnt;		/* internal to Event; not perl related */
    I16 prio;
    I16 max_cb_tm;
};

struct pe_event {
    pe_event_vtbl *vtbl;
    SV *mysv;
    pe_watcher *up;
    U32 flags;
    void *callback;
    void *ext_data;
    pe_ring peer; /* homogeneous */
    pe_ring que;  /* heterogeneous */
    I16 hits;
    I16 prio;
};

/* This must be placed directly after pe_watcher so the memory
   layouts are always compatible. XXX? */
typedef struct pe_timeable pe_timeable;
struct pe_timeable {
    pe_ring ring;
    NV at;
};

typedef struct pe_qcallback pe_qcallback;
struct pe_qcallback {
    pe_ring ring;
    int is_perl;
    void *callback;
    void *ext_data;
};

/* PUBLIC FLAGS */
#define PE_REENTRANT	0x0008
#define PE_HARD		0x0010
#define PE_DEBUG	0x1000
#define PE_REPEAT	0x2000
#define PE_INVOKE1	0x4000

#define WaFLAGS(ev)		((pe_watcher*)ev)->flags

#define WaDEBUG(ev)		((WaFLAGS(ev) & PE_DEBUG)? 2:0) /*arthimetical*/
#define WaDEBUG_on(ev)		(WaFLAGS(ev) |= PE_DEBUG)
#define WaDEBUG_off(ev)		(WaFLAGS(ev) &= ~PE_DEBUG)

#define WaREPEAT(ev)		(WaFLAGS(ev) & PE_REPEAT)
#define WaREPEAT_on(ev)		(WaFLAGS(ev) |= PE_REPEAT)
#define WaREPEAT_off(ev)	(WaFLAGS(ev) &= ~PE_REPEAT)

#define WaREENTRANT(ev)		(WaFLAGS(ev) & PE_REENTRANT)
#define WaREENTRANT_on(ev)	(WaFLAGS(ev) |= PE_REENTRANT)
#define WaREENTRANT_off(ev)	(WaFLAGS(ev) &= ~PE_REENTRANT)

#define WaHARD(ev)		(WaFLAGS(ev) & PE_HARD)
#define WaHARD_on(ev)		(WaFLAGS(ev) |= PE_HARD)   /* :-) */
#define WaHARD_off(ev)		(WaFLAGS(ev) &= ~PE_HARD)

#define WaINVOKE1(ev)		(WaFLAGS(ev) & PE_INVOKE1)
#define WaINVOKE1_on(ev)	(WaFLAGS(ev) |= PE_INVOKE1)
#define WaINVOKE1_off(ev)	(WaFLAGS(ev) &= ~PE_INVOKE1)

/* QUEUE INFO */
#define PE_QUEUES 7	/* Hard to imagine a need for more than 7 queues... */
#define PE_PRIO_HIGH	2
#define PE_PRIO_NORMAL	4

/* io-ish flags */
#define PE_R 0x1
#define PE_W 0x2
#define PE_E 0x4
#define PE_T 0x8

typedef struct pe_ioevent pe_ioevent;
struct pe_ioevent {
    pe_event base;
    U16 got;
};

typedef struct pe_datafulevent pe_datafulevent;
struct pe_datafulevent {
    pe_event base;
    SV *data;
};

typedef struct pe_idle pe_idle;
struct pe_idle {
    pe_watcher base;
    pe_timeable tm;
    pe_ring iring;
    SV *max_interval, *min_interval;
};

typedef struct pe_io pe_io;
struct pe_io {
    pe_watcher base;
    pe_timeable tm; /*timeout*/
    pe_ring ioring;
    SV *handle;
    void *tm_callback;
    void *tm_ext_data;
    float timeout;
    U16 poll;
    /* ifdef UNIX */
    int fd;
    int xref;  /*private: for poll*/
    /* endif */
};

typedef struct pe_signal pe_signal;
struct pe_signal {
    pe_watcher base;
    pe_ring sring;
    IV signal;
};

typedef struct pe_timer pe_timer;
struct pe_timer {
    pe_watcher base;
    pe_timeable tm;
    SV *interval;
};

typedef struct pe_var pe_var;
struct pe_var {
    pe_watcher base;
    SV *variable;
    U16 events;
};

typedef struct pe_group pe_group;
struct pe_group {
    pe_watcher base;
    NV since;
    pe_timeable tm;
    SV *timeout;
    int members;
    pe_watcher **member;
};

typedef struct pe_generic pe_generic;
struct pe_generic {
    pe_watcher base;
    SV *source;
    pe_ring active;
};

typedef struct pe_genericsrc pe_genericsrc;
struct pe_genericsrc {
    SV *mysv;
    pe_ring watchers;
};

typedef struct pe_event_stats_vtbl pe_event_stats_vtbl;
struct pe_event_stats_vtbl {
    int on;
    /* if frame == -1 then we are timing pe_multiplex */
    void*(*enter)(int frame, int max_tm);
    void (*suspend)(void *);
    void (*resume)(void *);
    void (*commit)(void *, pe_watcher *);  /* callback finished OK */
    void (*scrub)(void *, pe_watcher *);   /* callback died */
    void (*dtor)(void *);
};

struct EventAPI {
#define EventAPI_VERSION 22
    I32 Ver;

    /* EVENTS */
    void (*queue   )(pe_event *ev);
    void (*start   )(pe_watcher *ev, int repeat);
    void (*now     )(pe_watcher *ev);
    void (*stop    )(pe_watcher *ev, int cancel_events);
    void (*cancel  )(pe_watcher *ev);
    void (*suspend )(pe_watcher *ev);
    void (*resume  )(pe_watcher *ev);

    /* All constructors optionally take a stash and template.  Either
      or both can be NULL.  The template should not be a reference. */
    pe_idle     *(*new_idle  )(HV*, SV*);
    pe_timer    *(*new_timer )(HV*, SV*);
    pe_io       *(*new_io    )(HV*, SV*);
    pe_var      *(*new_var   )(HV*, SV*);
    pe_signal   *(*new_signal)(HV*, SV*);

    /* TIMEABLE */
    NV (*NVtime)();
    void (*tstart)(pe_timeable *);
    void (*tstop)(pe_timeable *);

    /* HOOKS */
    pe_qcallback *(*add_hook)(char *which, void *cb, void *ext_data);
    void (*cancel_hook)(pe_qcallback *qcb);

    /* STATS */
    void (*install_stats)(pe_event_stats_vtbl *esvtbl);
    void (*collect_stats)(int yes);
    pe_ring *AllWatchers;

    /* TYPEMAP */
    SV   *(*watcher_2sv)(pe_watcher *wa);
    void *(*sv_2watcher)(SV *sv);
    SV   *(*event_2sv)(pe_event *ev);
    void *(*sv_2event)(SV *sv);
    int   (*sv_2interval)(char *label, SV *in, NV *out);
    SV   *(*events_mask_2sv)(int mask);
    int   (*sv_2events_mask)(SV *sv, int bits);

    /* EVERYTHING ELSE */
    void (*unloop)(SV *);
    void (*unloop_all)(SV *);
};

static struct EventAPI *GEventAPI=0;

#define I_EVENT_API(YourName)						   \
STMT_START {								   \
  SV *sv = perl_get_sv("Event::API",0);					   \
  if (!sv) croak("Event::API not found");				   \
  GEventAPI = (struct EventAPI*) SvIV(sv);				   \
  if (GEventAPI->Ver != EventAPI_VERSION) {				   \
    croak("Event::API version mismatch (%d != %d) -- please recompile %s", \
	  GEventAPI->Ver, EventAPI_VERSION, YourName);			   \
  }									   \
} STMT_END

#endif
