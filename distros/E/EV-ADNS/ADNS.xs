#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <poll.h>

#define ADNS_FEATURE_MANYAF
#include <adns.h>

#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#include "EVAPI.h"

#define DEFAULT_INIT_FLAGS \
   adns_if_noenv | adns_if_noerrprint | adns_if_noserverwarn \
   | adns_if_noautosys | adns_if_permit_ipv4 | adns_if_permit_ipv6

static struct pollfd *fds;
static int nfd, mfd;
static ev_io *iow;
static ev_timer tw;
static ev_idle iw;
static ev_prepare pw;
static struct timeval tv_now;
static int outstanding;

static void
outstanding_inc (adns_state ads)
{
  if (!outstanding++)
    ev_prepare_start (EV_DEFAULT, &pw);
}

static void
outstanding_dec (adns_state ads)
{
  --outstanding;
}

struct ctx
{
  SV *self;
  adns_state ads;
  adns_query query;
  SV *cb;
};

static SV *
ip_to_sv (int family, void *addr)
{
  char buf[128];

  return newSVpv (inet_ntop (family, addr, buf, sizeof buf), 0);
}

static SV *
addr_to_sv (adns_rr_addr *addr)
{
  return ip_to_sv (addr->addr.sa.sa_family,
                   addr->addr.sa.sa_family == AF_INET6
                   ? (void *)&addr->addr.inet6.sin6_addr
                   : (void *)&addr->addr.inet.sin_addr);
}

static SV *
ha2sv (adns_rr_hostaddr *rr)
{
  int i;
  AV *av = newAV ();
  av_push (av, newSVpv (rr->host, 0));
  av_push (av, newSViv (rr->astatus));

  for (i = 0; i < rr->naddrs; ++i)
    av_push (av, addr_to_sv (rr->addrs + i));

  return newRV_noinc ((SV *)av);
}

static void
process (adns_state ads)
{
  dSP;

  ENTER;
  SAVETMPS;

  for (;;)
    {
      int i;
      adns_query q = 0;
      adns_answer *a;
      void *ctx;
      SV *cb;
      struct ctx *c;
      int r = adns_check (ads, &q, &a, &ctx);
      
      if (r)
        break;

      c = (struct ctx *)ctx;
      cb = c->cb;
      c->cb = 0; outstanding_dec (ads);
      SvREFCNT_dec (c->self);

      assert (cb);

      PUSHMARK (SP);

      EXTEND (SP, a->nrrs + 2);
      PUSHs (sv_2mortal (newSViv (a->status)));
      PUSHs (sv_2mortal (newSViv (a->expires)));

      for (i = 0; i < a->nrrs; ++i)
        {
          SV *sv;

          switch (a->type & adns_r_unknown ? adns_r_unknown : a->type)
            {
              case adns_r_ns_raw:
              case adns_r_cname:
              case adns_r_ptr:
              case adns_r_ptr_raw:
                sv = newSVpv (a->rrs.str [i], 0);
                break;

              case adns_r_txt:
                {
                  AV *av = newAV ();
                  adns_rr_intstr *rr = a->rrs.manyistr [i];

                  while (rr->str)
                    {
                      av_push (av, newSVpvn (rr->str, rr->i));
                      ++rr;
                    }

                  sv = newRV_noinc ((SV *)av);
                }
                break;

              case adns_r_addr:
                sv = addr_to_sv (a->rrs.addr + i);
                break;

              case adns_r_a:
                sv = ip_to_sv (AF_INET, a->rrs.inaddr + i);
                break;

              case adns_r_aaaa:
                sv = ip_to_sv (AF_INET6, a->rrs.in6addr + i);
                break;

              case adns_r_ns:
                sv = ha2sv (a->rrs.hostaddr + i);
                break;

              case adns_r_hinfo:
                {
                  /* untested */
                  AV *av = newAV ();
                  adns_rr_intstrpair *rr = a->rrs.intstrpair + i;

                  av_push (av, newSVpvn (rr->array [0].str, rr->array [0].i));
                  av_push (av, newSVpvn (rr->array [1].str, rr->array [1].i));

                  sv = newRV_noinc ((SV *)av);
                }
                break;

              case adns_r_rp:
              case adns_r_rp_raw:
                {
                  /* untested */
                  AV *av = newAV ();
                  adns_rr_strpair *rr = a->rrs.strpair + i;

                  av_push (av, newSVpv (rr->array [0], 0));
                  av_push (av, newSVpv (rr->array [1], 0));

                  sv = newRV_noinc ((SV *)av);
                }
                break;

              case adns_r_mx:
                {
                  AV *av = newAV ();
                  adns_rr_inthostaddr *rr = a->rrs.inthostaddr + i;

                  av_push (av, newSViv (rr->i));
                  av_push (av, ha2sv (&rr->ha));

                  sv = newRV_noinc ((SV *)av);
                }
                break;

              case adns_r_mx_raw:
                {
                  AV *av = newAV ();
                  adns_rr_intstr *rr = a->rrs.intstr + i;

                  av_push (av, newSViv (rr->i));
                  av_push (av, newSVpv (rr->str, 0));

                  sv = newRV_noinc ((SV *)av);
                }
                break;

              case adns_r_soa:
              case adns_r_soa_raw:
                {
                  AV *av = newAV ();
                  adns_rr_soa *rr = a->rrs.soa + i;

                  av_push (av, newSVpv (rr->mname, 0));
                  av_push (av, newSVpv (rr->rname, 0));
                  av_push (av, newSVuv (rr->serial));
                  av_push (av, newSVuv (rr->refresh));
                  av_push (av, newSVuv (rr->retry));
                  av_push (av, newSVuv (rr->expire));
                  av_push (av, newSVuv (rr->minimum));

                  sv = newRV_noinc ((SV *)av);
                }
                break;

              case adns_r_srv_raw:
                {
                  AV *av = newAV ();
                  adns_rr_srvraw *rr = a->rrs.srvraw + i;

                  av_push (av, newSViv (rr->priority));
                  av_push (av, newSViv (rr->weight));
                  av_push (av, newSViv (rr->port));
                  av_push (av, newSVpv (rr->host, 0));

                  sv = newRV_noinc ((SV *)av);
                }
                break;

              case adns_r_srv:
                {
                  AV *av = newAV ();
                  adns_rr_srvha *rr = a->rrs.srvha + i;

                  av_push (av, newSViv (rr->priority));
                  av_push (av, newSViv (rr->weight));
                  av_push (av, newSViv (rr->port));
                  av_push (av, ha2sv (&rr->ha));

                  sv = newRV_noinc ((SV *)av);
                }
                break;

              case adns_r_unknown:
                sv = newSVpvn (a->rrs.byteblock [i].data, a->rrs.byteblock [i].len);
                break;

              default:
                sv = newSV (0); /* not supported */
                break;
            }

          PUSHs (sv_2mortal (sv));
        }

      free (a);

      PUTBACK;
      call_sv (cb, G_VOID | G_DISCARD | G_EVAL);
      SPAGAIN;

      if (SvTRUE (ERRSV))
        warn ("%s", SvPV_nolen (ERRSV));

      SvREFCNT_dec (cb);
    }

  FREETMPS;
  LEAVE;
}

static void
update_now (EV_P)
{
  ev_tstamp t = ev_now (EV_A);

  tv_now.tv_sec  = (long)t;
  tv_now.tv_usec = (long)((t - (ev_tstamp)tv_now.tv_sec) * 1e6);
}

static void
idle_cb (EV_P_ ev_idle *w, int revents)
{
  ev_idle_stop (EV_A, w);
}

static void
timer_cb (EV_P_ ev_timer *w, int revents)
{
  adns_state ads = (adns_state)w->data;
  update_now (EV_A);

  adns_processtimeouts (ads, &tv_now);
}

static void
io_cb (EV_P_ ev_io *w, int revents)
{
  adns_state ads = (adns_state)w->data;
  update_now (EV_A);

  if (revents & EV_READ ) adns_processreadable  (ads, w->fd, &tv_now);
  if (revents & EV_WRITE) adns_processwriteable (ads, w->fd, &tv_now);
}

// create io watchers for each fd and a timer before blocking
static void
prepare_cb (EV_P_ ev_prepare *w, int revents)
{
  int i;
  int timeout = 3600000;
  adns_state ads = (adns_state)w->data;

  if (ev_is_active (&tw))
    ev_timer_stop (EV_A, &tw);

  if (ev_is_active (&iw))
    ev_idle_stop (EV_A, &iw);

  for (i = 0; i < nfd; ++i)
    ev_io_stop (EV_A, iow + i);

  process (ads);

  if (!outstanding)
    {
      ev_prepare_stop (EV_A, w);
      return;
    }

  update_now (EV_A);

  nfd = mfd;

  while (adns_beforepoll (ads, fds, &nfd, &timeout, &tv_now))
    {
      mfd = nfd;

      free (iow); iow = malloc (mfd * sizeof (ev_io));
      free (fds); fds = malloc (mfd * sizeof (struct pollfd));
    }

  ev_timer_set (&tw, timeout * 1e-3, 0.);
  ev_timer_start (EV_A, &tw);

  // create one ev_io per pollfd
  for (i = 0; i < nfd; ++i)
    {
      ev_io *w = iow + i;

      ev_io_init (w, io_cb, fds [i].fd,
        ((fds [i].events & POLLIN ? EV_READ : 0)
         | (fds [i].events & POLLOUT ? EV_WRITE : 0)));

      w->data = (void *)ads;
      ev_io_start (EV_A, w);
    }
}

static HV *stash;
static adns_state ads;

MODULE = EV::ADNS                PACKAGE = EV::ADNS

PROTOTYPES: ENABLE

BOOT:
{
  stash = gv_stashpv ("EV::ADNS", 1);

  static const struct {
    const char *name;
    IV iv;
  } *civ, const_iv[] = {
#   define const_iv(name) { # name, (IV) adns_ ## name },
    const_iv (if_none)
    const_iv (if_noenv)
    const_iv (if_noerrprint)
    const_iv (if_noserverwarn)
    const_iv (if_debug)
    const_iv (if_logpid)
    const_iv (if_noautosys)
    const_iv (if_eintr)
    const_iv (if_nosigpipe)
    const_iv (if_checkc_entex)
    const_iv (if_checkc_freq)
    const_iv (if_permit_ipv4)
    const_iv (if_permit_ipv6)
    const_iv (if_afmask)

    const_iv (qf_none)
    const_iv (qf_search)
    const_iv (qf_usevc)
    const_iv (qf_owner)
    const_iv (qf_quoteok_query)
    const_iv (qf_quoteok_cname)
    const_iv (qf_quoteok_anshost)
    const_iv (qf_quotefail_cname)
    const_iv (qf_cname_loose)
    const_iv (qf_cname_strict)
    const_iv (qf_cname_forbid)
    const_iv (qf_want_ipv4)
    const_iv (qf_want_ipv6)
    const_iv (qf_want_allaf)
    const_iv (qf_ipv6_mapv4)
    const_iv (qf_addrlit_scope_forbid)
    const_iv (qf_addrlit_scope_numeric)
    const_iv (qf_addrlit_ipv4_quadonly)

    const_iv (rrt_typemask)
    const_iv (rrt_reprmask)
    const_iv (r_unknown)
    const_iv (r_none)
    const_iv (r_a)
    const_iv (r_ns_raw)
    const_iv (r_ns)
    const_iv (r_cname)
    const_iv (r_soa_raw)
    const_iv (r_soa)
    const_iv (r_ptr_raw)
    const_iv (r_ptr)
    const_iv (r_hinfo)
    const_iv (r_mx_raw)
    const_iv (r_mx)
    const_iv (r_txt)
    const_iv (r_rp_raw)
    const_iv (r_rp)
    const_iv (r_aaaa)
    const_iv (r_srv_raw)
    const_iv (r_srv)
    const_iv (r_addr)

    const_iv (s_ok)
    const_iv (s_nomemory)
    const_iv (s_unknownrrtype)
    const_iv (s_systemfail)
    const_iv (s_max_localfail)
    const_iv (s_timeout)
    const_iv (s_allservfail)
    const_iv (s_norecurse)
    const_iv (s_invalidresponse)
    const_iv (s_unknownformat)
    const_iv (s_max_remotefail)
    const_iv (s_rcodeservfail)
    const_iv (s_rcodeformaterror)
    const_iv (s_rcodenotimplemented)
    const_iv (s_rcoderefused)
    const_iv (s_rcodeunknown)
    const_iv (s_max_tempfail)
    const_iv (s_inconsistent)
    const_iv (s_prohibitedcname)
    const_iv (s_answerdomaininvalid)
    const_iv (s_answerdomaintoolong)
    const_iv (s_invaliddata)
    const_iv (s_max_misconfig)
    const_iv (s_querydomainwrong)
    const_iv (s_querydomaininvalid)
    const_iv (s_querydomaintoolong)
    const_iv (s_max_misquery)
    const_iv (s_nxdomain)
    const_iv (s_nodata)
    const_iv (s_max_permfail)
  };

  for (civ = const_iv + sizeof (const_iv) / sizeof (const_iv [0]); civ > const_iv; civ--)
    newCONSTSUB (stash, (char *)civ[-1].name, newSViv (civ[-1].iv));

  I_EV_API ("EV::ADNS");

  adns_init (&ads, DEFAULT_INIT_FLAGS, 0);

  ev_prepare_init (&pw, prepare_cb);
  pw.data = (void *)ads;

  ev_init (&iw, idle_cb); ev_set_priority (&iw, EV_MINPRI);
  iw.data = (void *)ads;
  ev_init (&tw, timer_cb);
  tw.data = (void *)ads;
}

int
reinit (SV *flags = &PL_sv_undef, SV *str = &PL_sv_undef)
	CODE:
{
        int initflags = SvOK (flags) ? SvIV (flags) : DEFAULT_INIT_FLAGS;
        adns_finish (ads);
        adns_init_logfn (&ads, initflags, SvOK (str) ? SvPVbyte_nolen (str) : 0, 0, 0);
}

void submit (char *owner, int type, int flags, SV *cb)
	PPCODE:
{
        SV *csv = NEWSV (0, sizeof (struct ctx));
	struct ctx *c = (struct ctx *)SvPVX (csv);
        int r = adns_submit (ads, owner, type, flags, (void *)c, &c->query);

        outstanding_inc (ads);

        if (r)
          {
            SvREFCNT_dec (csv);
            croak ("EV::ADNS::submit: %s", strerror ((errno = r)));
          }

        SvPOK_only (csv);
        SvCUR_set (csv, sizeof (struct ctx));

        c->self = csv;
        c->cb   = newSVsv (cb);
        c->ads  = ads;

        if (!ev_is_active (&iw))
          ev_idle_start (EV_DEFAULT, &iw);

        if (GIMME_V != G_VOID)
          {
            csv = sv_2mortal (newRV_inc (csv));
            sv_bless (csv, stash);
            XPUSHs (csv);
          }
}

void DESTROY (SV *req)
	ALIAS:
        cancel = 1
	CODE:
{
        struct ctx *c;

        if (!(SvROK (req) && SvOBJECT (SvRV (req))
              && (SvSTASH (SvRV (req)) == stash)))
          croak ("object is not of type EV::ADNS");
        
        c = (struct ctx *)SvPVX (SvRV (req));

        if (c->cb)
          {
            SvREFCNT_dec (c->cb);
            c->cb = 0; outstanding_dec (c->ads);
            adns_cancel (c->query);
            SvREFCNT_dec (c->self);
          }
}

