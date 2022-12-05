/*
 * Copyright (c) homqyy
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <ikcp.h>

#define KCP_NORMAL_MODE   "normal"
#define KCP_FAST_MODE     "fast"

typedef struct {
    ikcpcb *ikcp;
    SV     *output;
    SV     *user;
} kcp_t;

static int
_output(const char *buf, int len, ikcpcb *ikcp, void *user)
{
    kcp_t *kcp = (kcp_t *)user;

    if (kcp->output)
    {
        dSP;

        ENTER;
        SAVETMPS;

        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpvn(buf, len)));
        if (kcp->user != NULL) XPUSHs(sv_2mortal(newSVsv(kcp->user)));
        PUTBACK;

        call_sv(kcp->output, G_VOID);

        FREETMPS;
        LEAVE;
    }

    return 0;
}

MODULE = KCP  PACKAGE = KCP  PREFIX = ikcp_

IUINT32
ikcp_get_conv(kcp_t *kcp, char *ptr = NULL)
  CODE:
    if (ptr == NULL)
    {
        RETVAL = kcp->ikcp->conv;
    }
    else
    {
        RETVAL = ikcp_getconv(ptr);
    }

  OUTPUT:
    RETVAL

IUINT32
ikcp_get_interval(kcp_t *kcp)
  CODE:
    RETVAL = kcp->ikcp->interval;

  OUTPUT:
    RETVAL

kcp_t *
ikcp_new(IUINT32 conv, SV *user = &PL_sv_undef)
  INIT:
    if (conv <= 0) XSRETURN_UNDEF;

    kcp_t *kcp = malloc(sizeof(kcp_t));
    if (kcp == NULL) XSRETURN_UNDEF;
    memzero(kcp, sizeof(kcp_t));


    ikcpcb * ikcp = ikcp_create(conv, kcp);
    if (kcp == NULL) XSRETURN_UNDEF;

    kcp->ikcp = ikcp;

    if (user)
    {
        kcp->user = newSVsv(user);
    }

  CODE:
    ikcp_nodelay(kcp->ikcp, 0, 40, 0, 0); // normal
    ikcp_setoutput(kcp->ikcp, _output);
    RETVAL = kcp;

  OUTPUT:
    RETVAL

int
ikcp_input(kcp_t *kcp, SV *data)
  CODE:
    char *buffer;
    STRLEN len;

    if (!SvPOK(data)) XSRETURN_UNDEF;

    buffer = SvPV(data, len);

    RETVAL = ikcp_input(kcp->ikcp, buffer, len);

  POSTCALL:
    if (RETVAL < 0) XSRETURN_UNDEF;

    RETVAL = 1;

  OUTPUT:
    RETVAL

int
ikcp_recv(kcp_t *kcp, SV *data, int len)
  CODE:
    if (len <= 0) XSRETURN_UNDEF;

    char buffer[len];
    RETVAL = ikcp_recv(kcp->ikcp, buffer, len);

  POSTCALL:
    if (RETVAL < 0) XSRETURN_UNDEF;

    sv_setpvn(data, buffer, RETVAL);

  OUTPUT:
    RETVAL
    data

int
ikcp_send(kcp_t *kcp, SV *data)
  CODE:
    char *buffer;
    STRLEN len;

    if (!SvPOK(data)) XSRETURN_UNDEF;

    buffer = SvPV(data, len);

    RETVAL = ikcp_send(kcp->ikcp, buffer, len);

  POSTCALL:
    if (RETVAL < 0) XSRETURN_UNDEF;

    RETVAL = len;

  OUTPUT:
    RETVAL

SV *
ikcp_set_output(kcp_t *kcp, SV *output)
  CODE:
    if (kcp->output) sv_2mortal(kcp->output);

    kcp->output = newSVsv(output);

    if (kcp->output == NULL) croak("KCP::setoutput: no enough memory");

    RETVAL = SvREFCNT_inc(ST(0));

  OUTPUT:
    RETVAL

SV *
ikcp_update(kcp_t *kcp, long current)
  CODE:
    ikcp_update(kcp->ikcp, current);

    RETVAL = SvREFCNT_inc(ST(0));

  OUTPUT:
    RETVAL

SV *
ikcp_flush(kcp_t *kcp)
  CODE:
    ikcp_flush(kcp->ikcp);

    RETVAL = SvREFCNT_inc(ST(0));

  OUTPUT:
    RETVAL

IUINT32
ikcp_mtu(kcp_t *kcp, int mtu = 0)
  INIT:
    IUINT32 old_mtu = kcp->ikcp->mtu;

  CODE:
    if (mtu != 0)
    {
        int ret = ikcp_setmtu(kcp->ikcp, mtu);

        if (ret < 0) croak("KCP::mtu: invalid mtu");
    }

    RETVAL = old_mtu;

  OUTPUT:
    RETVAL

IUINT32
ikcp_sndwnd(kcp_t *kcp, int sndwnd = 0)
  INIT:
    IUINT32 old_wnd = kcp->ikcp->snd_wnd;

  CODE:
    if (sndwnd != 0)
    {
        ikcp_wndsize(kcp->ikcp, sndwnd, kcp->ikcp->rcv_wnd);
    }

    RETVAL = old_wnd;

  OUTPUT:
    RETVAL

IUINT32
ikcp_rcvwnd(kcp_t *kcp, int rcvwnd = 0)
  INIT:
    IUINT32 old_wnd = kcp->ikcp->rcv_wnd;

  CODE:
    if (rcvwnd != 0)
    {
        ikcp_wndsize(kcp->ikcp, kcp->ikcp->snd_wnd, rcvwnd);
    }

    RETVAL = old_wnd;

  OUTPUT:
    RETVAL

int
ikcp_get_waitsnd(kcp_t *kcp)
  CODE:
    RETVAL = ikcp_waitsnd(kcp->ikcp);

  OUTPUT:
    RETVAL

SV *
ikcp_set_mode(kcp_t *kcp, SV *mode)
  CODE:
    if (mode == NULL) croak("KCP::setmode: invalid mode\n");

    char *m;
    STRLEN len;

    if (!SvPOK(mode)) XSRETURN_UNDEF;

    m = SvPV(mode, len);

    if (len + 1 == sizeof(KCP_NORMAL_MODE)
              && memcmp(m, KCP_NORMAL_MODE, len) == 0)
    {
        ikcp_nodelay(kcp->ikcp, 0, 40, 0, 0);
    }
    else if (len + 1 == sizeof(KCP_FAST_MODE)
              && memcmp(m, KCP_FAST_MODE, len) == 0)
    {
        ikcp_nodelay(kcp->ikcp, 1, 10, 2, 1);
    }
    else
    {
        croak("KCP::setmode: invalid mode\n");
    }

    RETVAL = SvREFCNT_inc(ST(0));

  OUTPUT:
    RETVAL

SV *
ikcp_nodelay(kcp_t *kcp, ...)
  CODE:
    // arguments
    int nodelay     = 0;
    int interval    = 40;
    int resend      = 0;
    int nc          = 0;

    // parse arguments
    int i;
    char *key;
    STRLEN len;
    for (i = 1; i < items; i+=2)
    {
        if (!SvPOK(ST(i)))
        {
            croak("key must is a 'string'");
        }

        key = SvPV(ST(i), len);

        if (i + 1 != items)
        {
            SV * value = ST(i + 1);

            if (len + 1 == sizeof("nodelay") &&
                    memcmp(key, "nodelay", len) == 0)
            {
                if (!SvIOK(value))
                {
                    croak("invalid value of nodelay. 0:disable(default), 1:enable");
                }

                nodelay = SvIV(value);

                if (nodelay != 0 && nodelay != 1)
                {
                    croak("invalid value of nodelay. 0:disable(default), 1:enable");
                }

                continue;
            }
            else if (len + 1 == sizeof("interval") &&
                    memcmp(key, "interval", len) == 0)
            {
                if (!SvIOK(value))
                {
                    croak("invalid value of interval. Internal update timer interval in millisec, default is 100ms ");
                }

                interval = SvIV(value);
                continue;
            }
            else if (len + 1 == sizeof("resend") &&
                    memcmp(key, "resend", len) == 0)
            {
                if (!SvIOK(value))
                {
                    croak("invalid value of resend. 0:disable fast resend(default), 1:enable fast resend");
                }

                resend = SvIV(value);
                continue;
            }
            else if (len + 1 == sizeof("disable_congestion_control") &&
                    memcmp(key, "disable_congestion_control", len) == 0)
            {
                if (!SvIOK(value))
                {
                    croak("invalid value of nc. nc: 0:normal congestion control(default), 1:disable congestion control");
                }

                nc = SvIV(value);
                continue;
            }
            else
            {
                croak("KCP::nodelay: invalid arguments '%s'\n", key);
            }
        }
        else
        {

            croak("KCP::nodelay: invalid arguments '%s'\n", key);
        }
    }

    // call c function
    ikcp_nodelay(kcp->ikcp, nodelay, interval, resend, nc);

    RETVAL = SvREFCNT_inc(ST(0));

  OUTPUT:
    RETVAL

int
peeksize(kcp_t *kcp)
  CODE:
    RETVAL = ikcp_peeksize(kcp->ikcp);

  OUTPUT:
    RETVAL

void
ikcp_DESTROY(kcp_t *kcp)
  CODE:
    if (kcp->output)  sv_2mortal(kcp->output);

    if (kcp->user)    sv_2mortal(kcp->user);

    ikcp_release(kcp->ikcp);

    free(kcp);