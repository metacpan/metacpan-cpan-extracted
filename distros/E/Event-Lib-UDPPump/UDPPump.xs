#include "EXTERN.h"
#include "perl.h"
#include "perlio.h"
#include "XSUB.h"

#include "ppport.h"

#include "blocked_read.h"

struct udppump {
  blocked_read_t *br;
  SV *io;
  CV *func;
  int buckets;
  SV** args;
};

#define to_perlio(sv)   IoIFP(sv_2io(sv))

struct udppump *IN_CALLBACK = NULL;
#define ENTER_callback(ev)      IN_CALLBACK = ev
#define LEAVE_callback          IN_CALLBACK = NULL
#define RUNNING_callback(ev)    ((ev) == IN_CALLBACK)

void pump_cb(void *data, void *cbarg) {
  int i;
  struct udppump *pump = (struct udppump*) cbarg;
  dSP;

  ENTER;
  SAVETMPS;
  PUSHMARK(SP);
  EXTEND(SP, pump->buckets + 1);

  HV* results = (HV *)sv_2mortal((SV *)newHV());
  hv_store(results, "len", 3, newSViv(pump->br->msg.len), 0);
  hv_store(results, "errno", 5, newSViv(pump->br->msg.error), 0);
  hv_store(results, "from", 4, 
           newSVpv((char *)&pump->br->msg.from, sizeof(pump->br->msg.from)), 0);
  hv_store(results, "buffer", 6,
           newSVpv(pump->br->msg.buffer, pump->br->msg.len), 0);

  PUSHs(sv_2mortal(newRV_inc((SV *)results)));
  for (i = 0; i < pump->buckets; i++) {
    PUSHs(pump->args[i]);
  }

  ENTER_callback(pump);
  PUTBACK;
  call_sv((SV*)pump->func, G_VOID | G_DISCARD | G_EVAL);
  if (SvTRUE(ERRSV)) {
    STRLEN n_a;
    PerlIO* io = to_perlio(pump->io);
    int fd = io ? PerlIO_fileno(io) : -1;
    die("Event::Lib::UDPPump callback for fh %d died: %s", 
        fd, SvPV(ERRSV, n_a));
  }
  LEAVE_callback;

  SPAGAIN;
  PUTBACK;
  FREETMPS;
  LEAVE;
  
}

MODULE = Event::Lib::UDPPump		PACKAGE = Event::Lib::UDPPump		

struct udppump*
udppump_new(SV *io, SV* func, ...)
PREINIT:
  static char* CLASS = "Event::Lib::UDPPump";
  struct udppump *pump;
CODE:
  int i;

  if (GIMME_V == G_VOID)
    XSRETURN_UNDEF;

  if (!SvROK(func) && (SvTYPE(SvRV(func)) != SVt_PVCV))
    croak("second argument to udppump_new must be code-reference");

  New(0, pump, 1, struct udppump);
  pump->io = io;
  pump->func = (CV*)SvRV(func);
  pump->br = NULL;

  SvREFCNT_inc(pump->io);
  SvREFCNT_inc(pump->func);


  if ((pump->buckets = items - 2) > 0)
    New(0, pump->args, pump->buckets, SV*);
  else
    pump->args = NULL;

  for (i = 0; i < pump->buckets; i++) {
    pump->args[i] = ST(i+2);
    SvREFCNT_inc(pump->args[i]);
  }

  RETVAL = pump;
OUTPUT:
  RETVAL

void
add(struct udppump* pump) 
CODE:
  PerlIO* io = to_perlio(pump->io);
  int fd = io ? PerlIO_fileno(io) : -1;
  if (fd == -1) {
    croak("Event::Lib::UDPPump::add - bad file descriptor");
  }
  pump->br = register_blocked_read(fd, pump_cb, (void *)pump);

void 
fh(struct udppump* pump)
CODE:
  ST(0) = pump->io;
  XSRETURN(1);
