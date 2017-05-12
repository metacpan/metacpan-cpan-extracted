#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <glib.h>
#include "EventAPI.h"

static GMainContext *
get_gcontext (SV *context)
{
  if (!SvOK (context))
    return g_main_context_default ();

  croak ("only the default context is currently supported.");
}

struct info {
  int *got_events;
  pe_io *w;
  GPollFD *pfd;
};

static void
event_io_cb (pe_event *pe)
{
  U16 got = ((pe_ioevent *)pe)->got;
  struct info *i = (struct info *)(pe->up->ext_data);

  i->pfd->revents |= i->pfd->events &
    ( (got & PE_R ? G_IO_IN  : 0)
    | (got & PE_W ? G_IO_OUT : 0)
    | (got & PE_E ? G_IO_PRI : 0)
    );

  if (i->pfd->revents)
    (*(i->got_events))++;
}

static gint
event_poll_func (GPollFD *fds, guint nfds, gint timeout)
{
  dSP;
  // yes, I use C99. If your compiler barfs here, fix it, but don't
  // tell me your compiler vendor was too incompetent to implement
  // the C standard within the last six years.
  struct info info[nfds];
  int got_events = 0;
  int n;

  for (n = 0; n < nfds; n++)
    {
      GPollFD *pfd = fds + n;
      struct info *i = info + n;

      i->pfd = pfd;
      i->got_events = &got_events;

      pe_io *w = i->w = GEventAPI->new_io (0, 0);
      w->base.callback = (void *)event_io_cb;
      w->base.ext_data = (void *)i;
      w->fd = pfd->fd;
      w->poll = (pfd->events & G_IO_IN  ? PE_R : 0)
              | (pfd->events & G_IO_OUT ? PE_W : 0)
              | (pfd->events & G_IO_PRI ? PE_E : 0);

      pfd->revents = 0;
      GEventAPI->start ((pe_watcher *)w, 0);
    }

  do {
    PUSHMARK (SP);
    XPUSHs (sv_2mortal (newSVnv (timeout >= 0 ? timeout * 0.001 : 86400. * 365.)));
    PUTBACK;
    call_pv ("Event::one_event", G_DISCARD | G_EVAL);
    SPAGAIN;
  } while (timeout < 0 && !got_events);

  for (n = 0; n < nfds; n++)
    GEventAPI->cancel ((pe_watcher *)info[n].w);

  if (SvTRUE (ERRSV))
    croak (0);

  return got_events;
}

MODULE = Glib::Event                PACKAGE = Glib::Event

PROTOTYPES: ENABLE

BOOT:
{
	I_EVENT_API ("Glib::Event");
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


