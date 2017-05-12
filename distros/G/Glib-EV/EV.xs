#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <glib.h>
#include "EVAPI.h"

static GMainContext *
get_gcontext (SV *context)
{
  if (!SvOK (context))
    return g_main_context_default ();

  croak ("only the default context is currently supported.");
}

static void
timeout_cb (EV_P_ ev_timer *w, int revents)
{
  ev_break (EV_A, EVBREAK_ONE);
}

typedef struct
{
  struct ev_io io;
  int *got_events;
  GPollFD *pfd;
} slot;

static void
io_cb (EV_P_ ev_io *w, int revents)
{
  slot *s = (slot *)w;
  int oev = s->pfd->revents;

  s->pfd->revents |= s->pfd->events &
    ((revents & EV_READ ? G_IO_IN : 0)
     | (revents & EV_WRITE ? G_IO_OUT : 0));

  if (!oev && s->pfd->revents)
    ++*(s->got_events);

  ev_break (EV_A, EVBREAK_ONE);
}

static gint
event_poll_func (GPollFD *fds, guint nfds, gint timeout)
{
  dSP;
  // yes, I use C99. If your compiler barfs here, fix it, but don't
  // tell me your compiler vendor was too incompetent to implement
  // the C standard within the last eight years.
  ev_timer to;
  slot slots[nfds];
  int got_events = 0;
  int n;

  for (n = 0; n < nfds; ++n)
    {
      GPollFD *pfd = fds + n;
      slot *s = slots + n;

      pfd->revents = 0;

      s->pfd = pfd;
      s->got_events = &got_events;

      ev_io_init (
        &s->io,
        io_cb,
        pfd->fd,
        (pfd->events & G_IO_IN ? EV_READ : 0)
         | (pfd->events & G_IO_OUT ? EV_WRITE : 0)
      );
      ev_io_start (EV_DEFAULT, &s->io);
    }

  if (timeout >= 0)
    {
      ev_timer_init (&to, timeout_cb, timeout * 1e-3, 0.);
      ev_timer_start (EV_DEFAULT, &to);
    }

  ev_run (EV_DEFAULT, 0);

  if (timeout >= 0)
    ev_timer_stop (EV_DEFAULT, &to);

  for (n = 0; n < nfds; ++n)
    ev_io_stop (EV_DEFAULT, &slots[n].io);

  return got_events;
}

MODULE = Glib::EV                PACKAGE = Glib::EV

PROTOTYPES: ENABLE

BOOT:
{
	I_EV_API ("Glib::EV");
}

long
install (SV *context)
	CODE:
{
	GMainContext *ctx = get_gcontext (context);

        RETVAL = (long)g_main_context_get_poll_func (ctx);

        g_main_context_set_poll_func (ctx, event_poll_func);
}
	OUTPUT:
        RETVAL

void
uninstall (SV *context, long prev_poll_func)
	CODE:
{
	GMainContext *ctx = get_gcontext (context);

        g_main_context_set_poll_func (ctx, (GPollFunc) prev_poll_func);
}


