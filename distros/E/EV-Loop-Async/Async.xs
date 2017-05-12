#include "xthread.h"

#include <errno.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stddef.h>

#include "EVAPI.h"

/* our userdata */
typedef struct {
  xmutex_t lock; /* global loop lock */
  void (*signal_func) (void *signal_arg, int value);
  void *signal_arg;
  ev_async async_w;
  xthread_t tid;
  unsigned int max_loops;
  unsigned int count;

  xcond_t invoke_cv;

  SV *interrupt;
#if defined(_WIN32) && defined(USE_ITHREADS)
  void *thx;
#endif
} udat;

static void loop_set_cb (EV_P);

static void
fg_invoke_pending (EV_P)
{
  udat *u = ev_userdata (EV_A);

  u->count = ev_pending_count (EV_A);

  if (u->count)
    ev_invoke_pending (EV_A);
}

static void
c_func (pTHX_ void *loop_, int value)
{
  struct ev_loop *loop = (struct ev_loop *)loop_;
  udat *u = ev_userdata (EV_A);
  int i;

  X_LOCK (u->lock);
  ev_invoke_pending (EV_A);

  /* do any additional foreground loop runs */
  for (i = u->max_loops; i--; )
    {
      /* this is a bit tricky, but we can manage... */
      u->count = 0;

      ev_set_invoke_pending_cb (EV_A, fg_invoke_pending);
      ev_set_loop_release_cb (EV_A, 0, 0);
      ev_run (EV_A, EVRUN_NOWAIT);
      loop_set_cb (EV_A);

      if (!u->count)
        break;
    }

  X_COND_SIGNAL (u->invoke_cv);
  X_UNLOCK (u->lock);
}

static void
async_cb (EV_P_ ev_async *w, int revents)
{
  /* just used for the side effects */
}

static void
l_release (EV_P)
{
  udat *u = ev_userdata (EV_A);
  X_UNLOCK (u->lock);
}

static void
l_acquire (EV_P)
{
  udat *u = ev_userdata (EV_A);
  X_LOCK (u->lock);
}

static void
l_invoke (EV_P)
{
  udat *u = ev_userdata (EV_A);

  while (ev_pending_count (EV_A))
    {
      u->signal_func (u->signal_arg, 1);
      X_COND_WAIT (u->invoke_cv, u->lock);
    }
}

static void
loop_set_cb (EV_P)
{
  ev_set_invoke_pending_cb (EV_A, l_invoke);
  ev_set_loop_release_cb (EV_A, l_release, l_acquire);
}

X_THREAD_PROC(l_run)
{
  struct ev_loop *loop = (struct ev_loop *)thr_arg;
#if defined(_WIN32) && defined(USE_ITHREADS)
  udat *u = ev_userdata (EV_A);

  /* just setting the same context pointer as the other thread is */
  /* probably fatal, yet, I have no clue what makes libev crash (malloc?) */
  /* as visual c also crashes when it tries to debug the crash */
  /* the loser platform is indeed a crashy OS */
  PERL_SET_CONTEXT (u->thx);
#endif

  l_acquire (EV_A);

  /* yeah */
  pthread_setcanceltype (PTHREAD_CANCEL_ASYNCHRONOUS, 0);

  ev_ref (EV_A);
  ev_run (EV_A, 0);
  ev_unref (EV_A);

  l_release (EV_A);

  return 0;
}

static void
scope_lock_cb (pTHX_ void *loop_)
{
  struct ev_loop *loop = (struct ev_loop *)SvIVX ((SV *)loop_);
  udat *u = ev_userdata (EV_A);

  X_UNLOCK (u->lock);
  SvREFCNT_dec ((SV *)loop_);
}

MODULE = EV::Loop::Async                PACKAGE = EV::Loop::Async

PROTOTYPES: ENABLE

BOOT:
{
	I_EV_API ("EV::Loop::Async");
        CvNODEBUG_on (get_cv ("EV::Loop::Async::scope_lock", 0)); /* otherwise calling scope can be the debugger */
}

void
_c_func (SV *loop)
	PPCODE:
        EXTEND (SP, 2);
        PUSHs (sv_2mortal (newSViv (PTR2IV (c_func))));
        PUSHs (sv_2mortal (newSViv (SvIVX (SvRV (loop)))));

void
_attach (SV *loop_, SV *interrupt, IV sig_func, void *sig_arg)
        PROTOTYPE: @
	CODE:
{
  	pthread_mutexattr_t ma;
	struct ev_loop *loop = (struct ev_loop *)SvIVX (SvRV (loop_));
  	udat *u;

        Newz (0, u, 1, udat);
        u->interrupt   = newSVsv (interrupt);
        u->signal_func = (void (*)(void *, int))sig_func;
        u->signal_arg  = sig_arg;
#if defined(_WIN32) && defined(USE_ITHREADS)
        u->thx         = PERL_GET_CONTEXT;
#endif

        ev_async_init (&u->async_w, async_cb);
        ev_async_start (EV_A, &u->async_w);

        pthread_mutexattr_init (&ma);
#ifdef PTHREAD_MUTEX_RECURSIVE
        pthread_mutexattr_settype (&ma, PTHREAD_MUTEX_RECURSIVE);
#else
        pthread_mutexattr_settype (&ma, PTHREAD_MUTEX_RECURSIVE_NP);
#endif
        pthread_mutex_init (&u->lock, &ma);
        pthread_mutexattr_destroy (&ma);

        pthread_cond_init (&u->invoke_cv, 0);

        ev_set_userdata (EV_A, u);
        loop_set_cb (EV_A);

        thread_create (&u->tid, l_run, loop);
}

SV *
interrupt (SV *loop_)
	CODE:
{
	struct ev_loop *loop = (struct ev_loop *)SvIVX (SvRV (loop_));
  	udat *u = ev_userdata (EV_A);

        RETVAL = newSVsv (u->interrupt);
}
	OUTPUT:
        RETVAL

void
set_max_foreground_loops (SV *loop_, UV max_loops)
	CODE:
{
	struct ev_loop *loop = (struct ev_loop *)SvIVX (SvRV (loop_));
  	udat *u = ev_userdata (EV_A);

        u->max_loops = max_loops;
}

void
lock (SV *loop_)
	ALIAS:
        lock   = 0
        unlock = 1
        notify = 2
	CODE:
{
	struct ev_loop *loop = (struct ev_loop *)SvIVX (SvRV (loop_));
  	udat *u = ev_userdata (EV_A);

        switch (ix)
          {
            case 0: X_LOCK   (u->lock); break;
            case 1: X_UNLOCK (u->lock); break;
            case 2: ev_async_send (EV_A, &u->async_w); break;
          }
}

void
scope_lock (SV *loop_)
	CODE:
{
	struct ev_loop *loop = (struct ev_loop *)SvIVX (SvRV (loop_));
  	udat *u = ev_userdata (EV_A);

        X_LOCK (u->lock);

        LEAVE; /* unfortunately, perl sandwiches XS calls into ENTER/LEAVE */
        SAVEDESTRUCTOR_X (scope_lock_cb, (void *)SvREFCNT_inc (SvRV (loop_)));
        ENTER; /* unfortunately, perl sandwiches XS calls into ENTER/LEAVE */
}

void
DESTROY (SV *loop_)
	CODE:
{
	struct ev_loop *loop = (struct ev_loop *)SvIVX (SvRV (loop_));
  	udat *u = ev_userdata (EV_A);

        if (u)
          {
            X_LOCK (u->lock);
            ev_async_stop (EV_A, &u->async_w);
            /* now thread is around blocking call, or in pthread_cond_wait */
            pthread_cancel (u->tid);
            X_UNLOCK (u->lock);
            pthread_mutex_destroy (&u->lock);
            pthread_cond_destroy (&u->invoke_cv);
            SvREFCNT_dec (u->interrupt);
            Safefree (u);
          }
}



