#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stddef.h>

#include <glib.h>
#include "EVAPI.h"

static GMainContext *
get_gcontext (SV *context)
{
  if (!SvOK (context))
    return g_main_context_default ();

  croak ("only the default context is currently supported.");
}

struct econtext
{
  GPollFD *pfd;
  ev_io *iow;
  int nfd, afd;
  gint maxpri;

  ev_prepare pw;
  ev_check cw;
  ev_timer tw;

  GMainContext *gc;
};

static void
timer_cb (EV_P_ ev_timer *w, int revents)
{
  /* nop */
}

static void
io_cb (EV_P_ ev_io *w, int revents)
{
  /* nop */
}

static void
prepare_cb (EV_P_ ev_prepare *w, int revents)
{
  struct econtext *ctx = (struct econtext *)(((char *)w) - offsetof (struct econtext, pw));
  gint timeout;
  int i;

  g_main_context_dispatch (ctx->gc);

  g_main_context_prepare (ctx->gc, &ctx->maxpri);

  while (ctx->afd < (ctx->nfd = g_main_context_query  (
    ctx->gc,
    ctx->maxpri,
    &timeout,
    ctx->pfd,
    ctx->afd))
  )
    {
      free (ctx->pfd);
      free (ctx->iow);

      ctx->afd = 1;
      while (ctx->afd < ctx->nfd)
        ctx->afd <<= 1;

      ctx->pfd = malloc (ctx->afd * sizeof (GPollFD));
      ctx->iow = malloc (ctx->afd * sizeof (ev_io));
    }

  for (i = 0; i < ctx->nfd; ++i)
    {
      GPollFD *pfd = ctx->pfd + i;
      ev_io *iow = ctx->iow + i;

      pfd->revents = 0;

      ev_io_init (
        iow,
        io_cb,
        pfd->fd,
        (pfd->events & G_IO_IN ? EV_READ : 0)
         | (pfd->events & G_IO_OUT ? EV_WRITE : 0)
      );
      iow->data = (void *)pfd;
      ev_set_priority (iow, EV_MINPRI);
      ev_io_start (EV_A, iow);
    }

  if (timeout >= 0)
    {
      ev_timer_set (&ctx->tw, timeout * 1e-3, 0.);
      ev_timer_start (EV_A, &ctx->tw);
    }
}

static void
check_cb (EV_P_ ev_check *w, int revents)
{
  struct econtext *ctx = (struct econtext *)(((char *)w) - offsetof (struct econtext, cw));
  int i;

  for (i = 0; i < ctx->nfd; ++i)
    {
      ev_io *iow = ctx->iow + i;

      if (ev_is_pending (iow))
        {
          GPollFD *pfd = ctx->pfd + i;
          int revents = ev_clear_pending (EV_A, iow);

          pfd->revents |= pfd->events &
            ((revents & EV_READ ? G_IO_IN : 0)
             | (revents & EV_WRITE ? G_IO_OUT : 0));
        }

      ev_io_stop (EV_A, iow);
    }

  if (ev_is_active (&ctx->tw))
    ev_timer_stop (EV_A, &ctx->tw);

  g_main_context_check (ctx->gc, ctx->maxpri, ctx->pfd, ctx->nfd);
}

static struct econtext default_context;

MODULE = EV::Glib                PACKAGE = EV::Glib

PROTOTYPES: ENABLE

BOOT:
{
	I_EV_API ("EV::Glib");
}

long
install (SV *context)
	CODE:
{
	GMainContext *gc = get_gcontext (context);
        struct econtext *ctx = &default_context;

        ctx->gc  = g_main_context_ref (gc);
        ctx->nfd = 0;
        ctx->afd = 0;
        ctx->iow = 0;
        ctx->pfd = 0;

        ev_prepare_init (&ctx->pw, prepare_cb);
        ev_set_priority (&ctx->pw, EV_MINPRI);
        ev_prepare_start (EV_DEFAULT, &ctx->pw);

        ev_check_init (&ctx->cw, check_cb);
        ev_set_priority (&ctx->cw, EV_MAXPRI);
        ev_check_start (EV_DEFAULT, &ctx->cw);

        ev_init (&ctx->tw, timer_cb);
        ev_set_priority (&ctx->tw, EV_MINPRI);
}
	OUTPUT:
        RETVAL



