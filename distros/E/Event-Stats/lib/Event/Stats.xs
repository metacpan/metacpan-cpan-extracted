/*-*-c-*-*/
#define MIN_PERL_DEFINE 1

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include "EventAPI.h"

static int EnforceMaxCBTime=0;

/*********************************************************/
typedef struct snap snap;
struct snap {
    double elapse;
    int live;
    int max_tm;
    struct timeval start;
};

static void snap_on(snap *sn)
{
    assert(sn);
    /* if (sn->live) warn("snap reinit"); /**/
    gettimeofday(&sn->start, 0);
    sn->live = 1;
}

static void snap_off(snap *sn)
{
  struct timeval done_tm;
  assert(sn);
  if (!sn->live) return;
  gettimeofday(&done_tm, 0);
  sn->live = 0;
  sn->elapse += (done_tm.tv_sec - sn->start.tv_sec +
		 (done_tm.tv_usec - sn->start.tv_usec)/1000000.0);
}

/*********************************************************/
#define PE_STAT_SECONDS 3  /* 3 sec per interval */
#define PE_STAT_I1  20
#define PE_STAT_I2  20

typedef struct pe_run pe_run;
struct pe_run {
  double elapse;
  int ran, die;
};

typedef struct pe_stat pe_stat;
struct pe_stat {
  int xsec, xmin;     /* first index of circular buffers */
  pe_run sec[PE_STAT_I1];
  pe_run min[PE_STAT_I2];
};

static pe_stat totalStats;
static pe_stat idleStats;
static struct timeval total_tm;
static pe_timer *RollTimer=0;

static void pe_stat_init(pe_stat *st)
{
  int xx;
  st->xsec = 0;
  for (xx=0; xx < PE_STAT_I1; xx++) {
    st->sec[xx].elapse = 0;
    st->sec[xx].ran = 0;
    st->sec[xx].die = 0;
  }
  st->xmin = 0;
  for (xx=0; xx < PE_STAT_I2; xx++) {
    st->min[xx].elapse = 0;
    st->min[xx].ran = 0;
    st->min[xx].die = 0;
  }
}

#if 0
static void pe_stat_dump(pe_stat *st) /*BROKEN*/
{
  int xx;
  fprintf(stderr,"stat(0x%x)\nsec> ", st);
  for (xx=0; xx < PE_STAT_I1; xx++) {
    pe_run *run = &st->sec[(st->xsec + xx) % PE_STAT_I1];
    fprintf(stderr, "%5.2f/%d ", run->elapse, run->ran);
  }
  fprintf(stderr,"\nmin5> ");
  for (xx=0; xx < PE_STAT_I2; xx++) {
    pe_run *run = &st->min[(st->xmin + xx) % PE_STAT_I2];
    fprintf(stderr, "%5.2f/%d ", run->elapse, run->ran);
  }
  fprintf(stderr,"\n");
}
#endif

static void pe_stat_record(pe_stat *st, double elapse)
{
  pe_run *run = &st->sec[st->xsec];
  /*  warn("recording %f\n", elapse);  pe_stat_dump(st); /**/
  run->elapse += elapse;
  run->ran += 1;
  /*  pe_stat_dump(st); /**/
}

static void pe_stat_query(pe_stat *st, int sec, int *ran, int *die, double *elapse)
{
  *ran = 0;
  *die = 0;
  *elapse = 0;
  if (sec <= 1)
    return;
  if (sec <= PE_STAT_SECONDS * PE_STAT_I1) {
    int xx;
    for (xx=0; xx <= (sec-1) / PE_STAT_SECONDS; xx++) {
      pe_run *run = &st->sec[(st->xsec + xx + 1) % PE_STAT_I1];
      assert(xx <= PE_STAT_I1);
      *ran += run->ran;
      *die += run->die;
      *elapse += run->elapse;
    }
    return;
  }
  if (sec <= PE_STAT_SECONDS * PE_STAT_I1 * PE_STAT_I2) {
    int xx;
    for (xx=0; xx <= (sec-1) / (PE_STAT_SECONDS*PE_STAT_I1); xx++) {
      pe_run *run = &st->min[(st->xmin + xx + 1) % PE_STAT_I2];
      assert(xx <= PE_STAT_I2);
      *ran += run->ran;
      *die += run->die;
      *elapse += run->elapse;
    }
    return;
  }
  warn("Stats available only for the last %d seconds (vs. %d)",
       PE_STAT_SECONDS * PE_STAT_I1 * PE_STAT_I2, sec);
}

static void pe_stat_roll(pe_stat *st)
{
  st->xsec = (st->xsec + PE_STAT_I1 - 1) % PE_STAT_I1;
  if (st->xsec == 0) {
    int xx;
    st->xmin = (st->xmin + PE_STAT_I2 - 1) % PE_STAT_I2;
    st->min[st->xmin].ran = 0;
    st->min[st->xmin].die = 0;
    st->min[st->xmin].elapse = 0;
    for (xx=0; xx < PE_STAT_I1; xx++) {
      st->min[st->xmin].ran += st->sec[xx].ran;
      st->min[st->xmin].die += st->sec[xx].die;
      st->min[st->xmin].elapse += st->sec[xx].elapse;
    }
  }
  st->sec[st->xsec].ran = 0;
  st->sec[st->xsec].die = 0;
  st->sec[st->xsec].elapse = 0;
}

static void pe_stat_roll_cb()
{
  pe_watcher *ev;
  struct timeval done_tm;
  /* warn("roll"); /**/
  gettimeofday(&done_tm, 0);
  pe_stat_record(&totalStats, (done_tm.tv_sec-total_tm.tv_sec +
			      (done_tm.tv_usec-total_tm.tv_usec)/1000000.0));
  gettimeofday(&total_tm, 0);

  ev = GEventAPI->AllWatchers->next->self;
  while (ev) {
    if (!ev->stats) {
      New(0, ev->stats, 1, pe_stat);
      pe_stat_init(ev->stats);
    }
    pe_stat_roll(ev->stats);
    ev = ev->all.next->self;
  }
  pe_stat_roll(&idleStats);
  pe_stat_roll(&totalStats);
}

static snap SysTm;       /* for idleStats */
static int RefTimes=0;
static snap *RefTime=0;

static void *pe_enter(int frame, int max_tm)
{
    snap *sn;
  /* warn("enter %d", frame); /**/
  if (frame == -1) {
      SysTm.elapse = 0;
      snap_on(&SysTm);
      return &SysTm;
  }
  if (frame >= RefTimes) {
    int cnt = frame + 10;
    if (!RefTime) {
      Newz(0, RefTime, cnt, snap);
    } else {
      int xx;
      Renew(RefTime, cnt, snap);
      for (xx=RefTimes; xx < cnt; xx++)
	RefTime[xx].live=0;
    }
    RefTimes = cnt;
  }
  sn = RefTime + frame;
  sn->elapse = 0;
  sn->max_tm = max_tm;
  snap_on(RefTime + frame);
  if (EnforceMaxCBTime && max_tm)
      alarm(max_tm);
  return sn;
}

static void pe_suspend(void *vp)
{
    if (EnforceMaxCBTime)
	alarm(0);
    snap_off((snap*)vp);
}

static void pe_resume(void *vp)
{
    snap *sn = (snap*) vp;
    if (EnforceMaxCBTime && sn->max_tm)
	alarm(sn->max_tm - ((int)sn->elapse));
    snap_on(sn);
}

static void pe_commit(void *vp, pe_watcher *wa)
{
  snap *sn = (snap*) vp;
  /* warn("commit %x %x", vp, wa); /**/
  if (EnforceMaxCBTime)
      alarm(0);
  if (wa && !wa->stats) {
    New(0, wa->stats, 1, pe_stat);
    pe_stat_init(wa->stats);
  }
  snap_off(sn);
  pe_stat_record(wa? wa->stats : &idleStats, sn->elapse);
}

static void pe_abort(void *vp, pe_watcher *wa)
{
  pe_run *run;
  pe_stat *st;
  if (EnforceMaxCBTime)
      alarm(0);
  ((snap*)vp)->live=0;
  assert(wa);
  if (!wa->stats) {
    New(0, wa->stats, 1, pe_stat);
    pe_stat_init(wa->stats);
  }
  st = (pe_stat*) wa->stats;
  run = &st->sec[st->xsec];
  run->die += 1;
}

static void pe_dtor(void *stats)
{ safefree(stats); }

static pe_event_stats_vtbl Myvtbl =
  { 0, pe_enter, pe_suspend, pe_resume, pe_commit, pe_abort, pe_dtor };

static int Stats;
static void use_stats(int yes)
{
    int prev = Stats;
    Stats += yes;
    if (Stats < 0)
	Stats=0;
    if (!(!prev ^ !Stats))
	return;
    if (Stats) {
	pe_watcher *ev;
	/*    warn("reinit stats"); /**/
	ev = GEventAPI->AllWatchers->next->self;
	while (ev) {
	    if (ev->stats)
		pe_stat_init(ev->stats);
	    ev = ev->all.next->self;
	}
	pe_stat_init(&idleStats);
	pe_stat_init(&totalStats);
  
	if (!RollTimer)
	    RollTimer = GEventAPI->new_timer(0,0);
	RollTimer->interval = newSVnv(PE_STAT_SECONDS);
	ev = (pe_watcher*) RollTimer;
	WaREPEAT_on(ev);
	sv_setpv(ev->desc, "Event::Stats");
	ev->prio = PE_PRIO_NORMAL - 1;
	ev->callback = (void*) pe_stat_roll_cb;
	gettimeofday(&total_tm, 0);
	/* pretend we are repeating so 'at' can be uninitialized */
	GEventAPI->start(ev, 1);
	GEventAPI->collect_stats(1);
    } else {
	GEventAPI->stop((pe_watcher*) RollTimer, 1);
	GEventAPI->collect_stats(0);
    }
}

MODULE = Event::Stats		PACKAGE = Event::Stats

PROTOTYPES: DISABLE

BOOT:
     {
	HV *stash = gv_stashpv("Event::Stats", 1);
	newCONSTSUB(stash, "MINTIME", newSViv(PE_STAT_SECONDS));
	newCONSTSUB(stash, "MAXTIME",
	      newSViv(PE_STAT_SECONDS * PE_STAT_I1 * PE_STAT_I2));
	I_EVENT_API(HvNAME(stash));
	GEventAPI->install_stats(&Myvtbl);
     }

void
_enforcing_max_callback_time()
     PPCODE:
{
    XPUSHs(boolSV(EnforceMaxCBTime));
}

void
_enforce_max_callback_time(yes)
	bool yes
	PPCODE:
{
    XPUSHs(boolSV(EnforceMaxCBTime));
    if (!EnforceMaxCBTime ^ !yes)
	use_stats(yes? 1:-1);
    EnforceMaxCBTime = yes;
    if (!yes) alarm(0);
}

int
round_seconds(sec)
	int sec;
	CODE:
	if (sec <= 0)
	  RETVAL = PE_STAT_SECONDS;
	else if (sec < PE_STAT_SECONDS * PE_STAT_I1)
	  RETVAL = ((int)(sec + PE_STAT_SECONDS-1)/ PE_STAT_SECONDS) *
			PE_STAT_SECONDS;
	else if (sec < PE_STAT_SECONDS * PE_STAT_I1 * PE_STAT_I2)
	  RETVAL = ((int)(sec + PE_STAT_SECONDS * PE_STAT_I1 - 1) /
			       (PE_STAT_SECONDS * PE_STAT_I1)) *
			PE_STAT_SECONDS * PE_STAT_I1;
	else
	  RETVAL = PE_STAT_SECONDS * PE_STAT_I1 * PE_STAT_I2;
	OUTPUT:
	RETVAL

void
idle_time(sec)
	int sec
	PREINIT:
	int ran, die;
	double elapse;
	PPCODE:
	if (!Stats) croak("Event::Stats are not enabled");
	pe_stat_query(&idleStats, sec, &ran, &die, &elapse);
	XPUSHs(sv_2mortal(newSViv(ran)));
	XPUSHs(sv_2mortal(newSViv(die)));
	XPUSHs(sv_2mortal(newSVnv(elapse)));

void
total_time(sec)
	int sec
	PREINIT:
	int ran,die;
	double elapse;
	PPCODE:
	if (!Stats) croak("Event::Stats are not enabled");
	pe_stat_query(&totalStats, sec, &ran, &die, &elapse);
	XPUSHs(sv_2mortal(newSVnv(elapse)));

int
collect(yes)
	int yes
	CODE:
{
    use_stats(yes);
    RETVAL = Stats;
}
	OUTPUT:
	RETVAL

MODULE = Event::Stats		PACKAGE = Event::Watcher

void
stats(obj, sec)
	SV *obj
	int sec
	PREINIT:
	int ran, die;
	double elapse;
	pe_watcher *THIS;
	PPCODE:
	if (!Stats)
		croak("Event::Stats are not enabled");
	THIS = (pe_watcher*) GEventAPI->sv_2watcher(obj);
	if (THIS->stats)
	  pe_stat_query(THIS->stats, sec, &ran, &die, &elapse);
	else
	  ran = die = elapse = 0;
	XPUSHs(sv_2mortal(newSViv(ran)));
	XPUSHs(sv_2mortal(newSViv(die)));
	XPUSHs(sv_2mortal(newSVnv(elapse)));

