/*
 * EV::cares - high-performance async DNS resolver using c-ares and EV
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "EVAPI.h"

#include <ares.h>

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <string.h>
#include <stdlib.h>

/* suppress c-ares deprecation warnings - these functions still work */
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"

/* DNS type constants (removed from ares_dns.h in newer c-ares) */
#ifndef T_A
  #define T_A     1
#endif
#ifndef T_NS
  #define T_NS    2
#endif
#ifndef T_CNAME
  #define T_CNAME 5
#endif
#ifndef T_SOA
  #define T_SOA   6
#endif
#ifndef T_PTR
  #define T_PTR   12
#endif
#ifndef T_MX
  #define T_MX    15
#endif
#ifndef T_TXT
  #define T_TXT   16
#endif
#ifndef T_AAAA
  #define T_AAAA  28
#endif
#ifndef T_SRV
  #define T_SRV   33
#endif
#ifndef T_NAPTR
  #define T_NAPTR 35
#endif
#ifndef T_DS
  #define T_DS    43
#endif
#ifndef T_RRSIG
  #define T_RRSIG 46
#endif
#ifndef T_DNSKEY
  #define T_DNSKEY 48
#endif
#ifndef T_TLSA
  #define T_TLSA  52
#endif
#ifndef T_SVCB
  #define T_SVCB  64
#endif
#ifndef T_HTTPS
  #define T_HTTPS 65
#endif
#ifndef T_CAA
  #define T_CAA   257
#endif
#ifndef T_ANY
  #define T_ANY   255
#endif

/* Modern ares_dns_record_t API (HTTPS/SVCB parsing) — c-ares >= 1.28 */
#ifndef HAVE_ARES_DNS_PARSE
#  if defined(ARES_VERSION) && ARES_VERSION >= 0x011C00
#    define HAVE_ARES_DNS_PARSE 1
#  endif
#endif

/* DNS class constants */
#ifndef C_IN
  #define C_IN    1
#endif
#ifndef C_CHAOS
  #define C_CHAOS 3
#endif
#ifndef C_HS
  #define C_HS    4
#endif
#ifndef C_ANY
  #define C_ANY   255
#endif

/* helper macro for BOOT constant registration */
#define CONST_IV(stash, name) newCONSTSUB(stash, #name, newSViv(name))

/* flags that may not exist in older c-ares */
#ifndef ARES_FLAG_NO_DFLT_SVR
  #define ARES_FLAG_NO_DFLT_SVR 0
#endif
#ifndef ARES_FLAG_DNS0x20
  #define ARES_FLAG_DNS0x20 0
#endif
#ifndef ARES_ESERVICE
  #define ARES_ESERVICE 25
#endif
#ifndef ARES_ENOSERVER
  #define ARES_ENOSERVER 26
#endif

#define EV_CARES_MAGIC 0xCA7E5001
#define MAX_IO 16

#define REQUIRE_LIVE(self) \
    STMT_START { \
        if ((self)->magic != EV_CARES_MAGIC) croak("EV::cares: invalid object"); \
        if ((self)->destroyed) croak("EV::cares: resolver is destroyed"); \
    } STMT_END

#define REQUIRE_CB(cb) \
    STMT_START { \
        if (!(SvROK(cb) && SvTYPE(SvRV(cb)) == SVt_PVCV)) \
            croak("EV::cares: callback must be a CODE reference"); \
    } STMT_END

typedef struct ev_cares_s ev_cares_t;
typedef ev_cares_t *EV__cares;

typedef struct {
    ev_io watcher;
    ares_socket_t fd;
} ev_cares_io_t;

struct ev_cares_s {
    U32 magic;
    ares_channel channel;
    struct ev_loop *loop;
    SV *loop_sv;       /* keeps a custom EV::Loop alive; NULL for default loop */
    ev_timer timer;
    ev_cares_io_t ios[MAX_IO];
    int active_queries;
    int destroyed;
    int in_callback;    /* prevent Safefree while callbacks run */
    int free_pending;   /* deferred Safefree after last callback */
    int cleanup_pending; /* deferred channel teardown after last callback */
    int last_timeouts;  /* timeouts count from the most recent callback */
};

typedef struct {
    ev_cares_t *resolver;
    SV *cb;
    int qtype;
    int with_ttl;  /* addrinfo_cb returns hashrefs when set */
    int by_addr;   /* host_cb returns h_name+h_aliases instead of h_addr_list */
} ev_cares_req_t;

/* forward declarations */
static void update_timer(ev_cares_t *self);
static void cleanup_now(ev_cares_t *self);

/* Bracket an ares_* call that may fire callbacks synchronously.  Guards
 * against the user destroying the resolver from inside such a callback: both
 * the Safefree of self AND the ares_destroy of the channel are deferred until
 * the outermost ares_* call has fully unwound, because the channel is still
 * referenced further up the C stack until then (destroying it inline is a
 * use-after-free that musl turns into a hard crash; glibc only tolerates it). */
#define ARES_CALL_BEGIN(self)  (self)->in_callback++
/* Deferred teardown at the outermost unwind: cleanup_now may free self
   (it consumes free_pending), so nothing may touch self after it runs. */
#define ARES_CALL_END(self)   \
    STMT_START { \
        if (--(self)->in_callback == 0) { \
            if ((self)->cleanup_pending) cleanup_now(self); \
            else if ((self)->free_pending) { \
                (self)->free_pending = 0; \
                Safefree(self); \
            } else update_timer(self); \
        } else { \
            update_timer(self); \
        } \
    } STMT_END
static void io_cb(EV_P_ ev_io *w, int revents);
static void timer_cb(EV_P_ ev_timer *w, int revents);
static void sock_state_cb(void *data, ares_socket_t fd, int readable, int writable);
static void cleanup(ev_cares_t *self);

/* qtype is set by callers that need it (only search()); Newxz zeroes it. */
static ev_cares_req_t *
new_req(pTHX_ ev_cares_t *self, SV *cb) {
    ev_cares_req_t *req;
    Newxz(req, 1, ev_cares_req_t);
    req->resolver = self;
    req->cb = SvREFCNT_inc_simple_NN(cb);
    self->active_queries++;
    return req;
}

/* Build a comma-separated server list. Each AV element may be either
   a plain string (e.g. "8.8.8.8" or "8.8.8.8:53") or a hashref
   { host => ..., port => ... }.  Sparse-array holes are skipped
   without emitting a stray comma. */
static SV *
av_to_csv(pTHX_ AV *av) {
    SSize_t i, len = av_len(av) + 1;
    SV *csv = sv_2mortal(newSVpvs(""));
    int written = 0;
    for (i = 0; i < len; i++) {
        SV **elem = av_fetch(av, i, 0);
        if (!elem) continue;
        /* Validate (and croak) before bumping `written` so an aborted
           iteration can't leave a dangling separator. */
        if (SvROK(*elem) && SvTYPE(SvRV(*elem)) == SVt_PVHV) {
            HV *hv = (HV *)SvRV(*elem);
            SV **host = hv_fetchs(hv, "host", 0);
            SV **port = hv_fetchs(hv, "port", 0);
            if (!host)
                croak("EV::cares: server hashref missing 'host' key (index %d)",
                      (int)i);
            if (written++) sv_catpvs(csv, ",");
            sv_catsv(csv, *host);
            if (port) sv_catpvf(csv, ":%d", (int)SvIV(*port));
        } else {
            if (written++) sv_catpvs(csv, ",");
            sv_catsv(csv, *elem);
        }
    }
    return csv;
}

static void
free_req(pTHX_ ev_cares_req_t *req) {
    req->resolver->active_queries--;
    SvREFCNT_dec(req->cb);
    Safefree(req);
}

/* ---- EV integration ---- */

static void
sock_state_cb(void *data, ares_socket_t fd, int readable, int writable) {
    dTHX;
    ev_cares_t *self = (ev_cares_t *)data;
    int i, events = 0;

    if (self->destroyed) return;

    if (readable) events |= EV_READ;
    if (writable) events |= EV_WRITE;

    /* find existing watcher for this fd */
    for (i = 0; i < MAX_IO; i++)
        if (self->ios[i].fd == fd) break;

    if (events) {
        if (i == MAX_IO) {
            /* find empty slot */
            for (i = 0; i < MAX_IO; i++)
                if (self->ios[i].fd == ARES_SOCKET_BAD) break;
            if (i == MAX_IO) {
                warn("EV::cares: too many concurrent sockets (>%d), "
                     "query on fd %d may hang until timeout",
                     MAX_IO, (int)fd);
                return;
            }
            self->ios[i].fd = fd;
            ev_io_init(&self->ios[i].watcher, io_cb, (int)fd, events);
            self->ios[i].watcher.data = (void *)self;
        } else {
            ev_io_stop(self->loop, &self->ios[i].watcher);
            ev_io_set(&self->ios[i].watcher, (int)fd, events);
        }
        ev_io_start(self->loop, &self->ios[i].watcher);
    } else {
        /* fd closing */
        if (i < MAX_IO) {
            ev_io_stop(self->loop, &self->ios[i].watcher);
            self->ios[i].fd = ARES_SOCKET_BAD;
        }
    }
}

/* io_cb / timer_cb: cleanup() sets destroyed=1 before nulling channel,
   so the destroyed flag implies !channel; one check covers both. */
static void
io_cb(EV_P_ ev_io *w, int revents) {
    ev_cares_t *self = (ev_cares_t *)w->data;
    ares_socket_t rfd = ARES_SOCKET_BAD, wfd = ARES_SOCKET_BAD;
    int i;

    if (self->destroyed) return;

    for (i = 0; i < MAX_IO; i++) {
        if (&self->ios[i].watcher == w) {
            if (revents & EV_READ)  rfd = self->ios[i].fd;
            if (revents & EV_WRITE) wfd = self->ios[i].fd;
            /* Bare EV_ERROR (no READ/WRITE bits) signals an unrecoverable
               watcher problem and libev has already stopped the watcher.
               Hand the fd to c-ares anyway so its next I/O attempt fails
               immediately instead of waiting for the per-query timeout. */
            if ((revents & EV_ERROR) &&
                rfd == ARES_SOCKET_BAD && wfd == ARES_SOCKET_BAD)
                rfd = self->ios[i].fd;
            break;
        }
    }

    ARES_CALL_BEGIN(self);
    ares_process_fd(self->channel, rfd, wfd);
    ARES_CALL_END(self);
}

static void
timer_cb(EV_P_ ev_timer *w, int revents) {
    ev_cares_t *self = (ev_cares_t *)w->data;

    if (self->destroyed) return;

    ARES_CALL_BEGIN(self);
    ares_process_fd(self->channel, ARES_SOCKET_BAD, ARES_SOCKET_BAD);
    ARES_CALL_END(self);
}

static void
update_timer(ev_cares_t *self) {
    struct timeval tv, *tvp;

    if (self->destroyed) return;

    tvp = ares_timeout(self->channel, NULL, &tv);
    ev_timer_stop(self->loop, &self->timer);
    if (tvp) {
        double after = (double)tvp->tv_sec + (double)tvp->tv_usec / 1e6;
        if (after < 0.001) after = 0.001;
        ev_timer_set(&self->timer, after, 0.);
        ev_timer_start(self->loop, &self->timer);
    }
}

/* Actual teardown: stop watchers, destroy the channel, release the loop.
   Only safe when not inside an ares_* call (see cleanup()).  ares_destroy
   fires each still-pending callback inline (ARES_EDESTRUCTION); bracketing
   it with in_callback++/-- keeps those nested epilogues off the teardown
   branches.  This is also the single site that consumes free_pending, so
   cleanup_now may free self -- callers must not touch self afterwards. */
static void
cleanup_now(ev_cares_t *self) {
    int i;

    self->cleanup_pending = 0;

    ev_timer_stop(self->loop, &self->timer);
    for (i = 0; i < MAX_IO; i++) {
        if (self->ios[i].fd != ARES_SOCKET_BAD) {
            ev_io_stop(self->loop, &self->ios[i].watcher);
            self->ios[i].fd = ARES_SOCKET_BAD;
        }
    }

    /* Nested epilogues fired by ares_destroy must see in_callback > 0. */
    self->in_callback++;
    ares_destroy(self->channel);
    self->in_callback--;
    self->channel = NULL;

    /* Release our hold on a user-supplied EV::Loop. Doing this only after
       the watchers are stopped means the loop is still valid above. */
    if (self->loop_sv) {
        dTHX;
        SvREFCNT_dec(self->loop_sv);
        self->loop_sv = NULL;
    }

    /* single consumer of free_pending; nothing may touch self after */
    if (self->free_pending) {
        self->free_pending = 0;
        Safefree(self);
    }
}

static void
cleanup(ev_cares_t *self) {
    if (self->destroyed) return;
    self->destroyed = 1;

    /* If a callback dispatched synchronously from inside an ares_* call asked
       us to destroy (e.g. $resolver->destroy from a resolve callback that
       ares_getaddrinfo fired inline), the channel is still referenced further
       up the C stack.  Tearing it down now is a use-after-free; defer it to
       the ARES_CALL_END / CB_EPILOGUE that unwinds in_callback to zero. */
    if (self->in_callback) {
        self->cleanup_pending = 1;
        return;
    }

    cleanup_now(self);
}

/* ---- callback prologue/epilogue (prevents UAF if resolver freed mid-callback) ---- */

/* All c-ares callbacks share this prologue. The macro relies on each
   caller having an `int timeouts` parameter (per the c-ares callback
   ABI) so it can record the latest retry count on the resolver. */
#define CB_PROLOGUE(arg, status_val) \
    ev_cares_req_t *req = (ev_cares_req_t *)(arg); \
    ev_cares_t *self = req->resolver; \
    dTHX; dSP; \
    self->last_timeouts = timeouts; \
    self->in_callback++; \
    ENTER; SAVETMPS; \
    PUSHMARK(SP); \
    mXPUSHi(status_val)

#define CB_EPILOGUE \
    PUTBACK; \
    { \
        SV *_cb = SvREFCNT_inc_simple_NN(req->cb); \
        call_sv(_cb, G_DISCARD | G_EVAL); \
        if (SvTRUE(ERRSV)) { \
            warn("EV::cares: callback error: %" SVf, SVfARG(ERRSV)); \
            sv_setsv(ERRSV, &PL_sv_undef); \
        } \
        SvREFCNT_dec(_cb); \
    } \
    FREETMPS; LEAVE; \
    free_req(aTHX_ req); \
    if (--self->in_callback == 0) { \
        /* outermost frame: deferred teardown; cleanup_now may free self */ \
        if (self->cleanup_pending) cleanup_now(self); \
        else if (self->free_pending) { \
            self->free_pending = 0; \
            Safefree(self); \
        } else update_timer(self); \
    } else { \
        update_timer(self); \
    }

/* ---- query callbacks ---- */

static void
addrinfo_cb(void *arg, int status, int timeouts, struct ares_addrinfo *result) {
    CB_PROLOGUE(arg, status);

    if (result) {
        if (status == ARES_SUCCESS) {
            struct ares_addrinfo_node *node;
            /* result->cnames->name is always set when cnames is non-NULL */
            const char *cname = result->cnames ? result->cnames->name : NULL;
            for (node = result->nodes; node; node = node->ai_next) {
                char ip[INET6_ADDRSTRLEN];
                if (node->ai_family == AF_INET) {
                    struct sockaddr_in *sin = (struct sockaddr_in *)node->ai_addr;
                    inet_ntop(AF_INET, &sin->sin_addr, ip, sizeof(ip));
                } else if (node->ai_family == AF_INET6) {
                    struct sockaddr_in6 *sin6 = (struct sockaddr_in6 *)node->ai_addr;
                    inet_ntop(AF_INET6, &sin6->sin6_addr, ip, sizeof(ip));
                } else {
                    continue;
                }
                if (req->with_ttl) {
                    HV *hv = newHV();
                    hv_stores(hv, "addr",     newSVpv(ip, 0));
                    hv_stores(hv, "family",   newSViv(node->ai_family));
                    hv_stores(hv, "ttl",      newSViv(node->ai_ttl));
                    hv_stores(hv, "timeouts", newSViv(timeouts));
                    if (cname)
                        hv_stores(hv, "canonname", newSVpv(cname, 0));
                    mXPUSHs(newRV_noinc((SV *)hv));
                } else {
                    mXPUSHp(ip, strlen(ip));
                }
            }
        }
        ares_freeaddrinfo(result);
    }

    CB_EPILOGUE;
}

static void
host_cb(void *arg, int status, int timeouts, struct hostent *hostent) {
    CB_PROLOGUE(arg, status);

    if (status == ARES_SUCCESS && hostent) {
        if (req->by_addr) {
            /* reverse lookup: return canonical name + any aliases */
            if (hostent->h_name)
                mXPUSHp(hostent->h_name, strlen(hostent->h_name));
            if (hostent->h_aliases) {
                char **p;
                for (p = hostent->h_aliases; *p; p++)
                    mXPUSHp(*p, strlen(*p));
            }
        } else {
            /* forward lookup: return the address list */
            char **p;
            for (p = hostent->h_addr_list; *p; p++) {
                char ip[INET6_ADDRSTRLEN];
                if (hostent->h_addrtype == AF_INET)
                    inet_ntop(AF_INET, *p, ip, sizeof(ip));
                else
                    inet_ntop(AF_INET6, *p, ip, sizeof(ip));
                mXPUSHp(ip, strlen(ip));
            }
        }
    }

    CB_EPILOGUE;
}

static void
raw_cb(void *arg, int status, int timeouts, unsigned char *abuf, int alen) {
    CB_PROLOGUE(arg, status);

    if (status == ARES_SUCCESS && abuf && alen > 0)
        mXPUSHp((char *)abuf, alen);

    CB_EPILOGUE;
}

static void
search_cb(void *arg, int status, int timeouts, unsigned char *abuf, int alen) {
    CB_PROLOGUE(arg, status);

    if (status == ARES_SUCCESS && abuf && alen > 0) {
        switch (req->qtype) {

        case T_A: {
            struct hostent *host = NULL;
            if (ares_parse_a_reply(abuf, alen, &host, NULL, NULL) == ARES_SUCCESS && host) {
                char **p;
                for (p = host->h_addr_list; *p; p++) {
                    char ip[INET_ADDRSTRLEN];
                    inet_ntop(AF_INET, *p, ip, sizeof(ip));
                    mXPUSHp(ip, strlen(ip));
                }
                ares_free_hostent(host);
            }
            break;
        }

        case T_AAAA: {
            struct hostent *host = NULL;
            if (ares_parse_aaaa_reply(abuf, alen, &host, NULL, NULL) == ARES_SUCCESS && host) {
                char **p;
                for (p = host->h_addr_list; *p; p++) {
                    char ip[INET6_ADDRSTRLEN];
                    inet_ntop(AF_INET6, *p, ip, sizeof(ip));
                    mXPUSHp(ip, strlen(ip));
                }
                ares_free_hostent(host);
            }
            break;
        }

        case T_MX: {
            struct ares_mx_reply *mx_out = NULL;
            if (ares_parse_mx_reply(abuf, alen, &mx_out) == ARES_SUCCESS && mx_out) {
                struct ares_mx_reply *mx;
                for (mx = mx_out; mx; mx = mx->next) {
                    HV *hv = newHV();
                    hv_stores(hv, "priority", newSViv(mx->priority));
                    hv_stores(hv, "host", newSVpv(mx->host, 0));
                    mXPUSHs(newRV_noinc((SV *)hv));
                }
                ares_free_data(mx_out);
            }
            break;
        }

        case T_SRV: {
            struct ares_srv_reply *srv_out = NULL;
            if (ares_parse_srv_reply(abuf, alen, &srv_out) == ARES_SUCCESS && srv_out) {
                struct ares_srv_reply *srv;
                for (srv = srv_out; srv; srv = srv->next) {
                    HV *hv = newHV();
                    hv_stores(hv, "priority", newSViv(srv->priority));
                    hv_stores(hv, "weight", newSViv(srv->weight));
                    hv_stores(hv, "port", newSViv(srv->port));
                    hv_stores(hv, "target", newSVpv(srv->host, 0));
                    mXPUSHs(newRV_noinc((SV *)hv));
                }
                ares_free_data(srv_out);
            }
            break;
        }

        case T_TXT: {
            struct ares_txt_ext *txt_out = NULL;
            if (ares_parse_txt_reply_ext(abuf, alen, &txt_out) == ARES_SUCCESS && txt_out) {
                struct ares_txt_ext *txt;
                SV *current = NULL;
                for (txt = txt_out; txt; txt = txt->next) {
                    if (txt->record_start || !current) {
                        if (current) mXPUSHs(current);
                        current = newSVpvn((char *)txt->txt, txt->length);
                    } else {
                        sv_catpvn(current, (char *)txt->txt, txt->length);
                    }
                }
                if (current) mXPUSHs(current);
                ares_free_data(txt_out);
            }
            break;
        }

        case T_NS: {
            struct hostent *host = NULL;
            if (ares_parse_ns_reply(abuf, alen, &host) == ARES_SUCCESS && host) {
                if (host->h_aliases) {
                    char **p;
                    for (p = host->h_aliases; *p; p++)
                        mXPUSHp(*p, strlen(*p));
                }
                ares_free_hostent(host);
            }
            break;
        }

        case T_SOA: {
            struct ares_soa_reply *soa = NULL;
            if (ares_parse_soa_reply(abuf, alen, &soa) == ARES_SUCCESS && soa) {
                HV *hv = newHV();
                hv_stores(hv, "mname",  newSVpv(soa->nsname, 0));
                hv_stores(hv, "rname",  newSVpv(soa->hostmaster, 0));
                hv_stores(hv, "serial", newSVuv(soa->serial));
                hv_stores(hv, "refresh", newSVuv(soa->refresh));
                hv_stores(hv, "retry",  newSVuv(soa->retry));
                hv_stores(hv, "expire", newSVuv(soa->expire));
                hv_stores(hv, "minttl", newSVuv(soa->minttl));
                mXPUSHs(newRV_noinc((SV *)hv));
                ares_free_data(soa);
            }
            break;
        }

        case T_PTR: {
            struct hostent *host = NULL;
            /* family only affects h_addrtype/h_length, not PTR name parsing;
               we pass NULL addr so these fields are unused */
            if (ares_parse_ptr_reply(abuf, alen, NULL, 0, AF_UNSPEC, &host) == ARES_SUCCESS && host) {
                if (host->h_name)
                    mXPUSHp(host->h_name, strlen(host->h_name));
                if (host->h_aliases) {
                    char **p;
                    for (p = host->h_aliases; *p; p++)
                        mXPUSHp(*p, strlen(*p));
                }
                ares_free_hostent(host);
            }
            break;
        }

        case T_NAPTR: {
            struct ares_naptr_reply *naptr_out = NULL;
            if (ares_parse_naptr_reply(abuf, alen, &naptr_out) == ARES_SUCCESS && naptr_out) {
                struct ares_naptr_reply *n;
                for (n = naptr_out; n; n = n->next) {
                    HV *hv = newHV();
                    hv_stores(hv, "order",       newSViv(n->order));
                    hv_stores(hv, "preference",  newSViv(n->preference));
                    hv_stores(hv, "flags",       newSVpv((char *)n->flags, 0));
                    hv_stores(hv, "service",     newSVpv((char *)n->service, 0));
                    hv_stores(hv, "regexp",      newSVpv((char *)n->regexp, 0));
                    hv_stores(hv, "replacement", newSVpv(n->replacement, 0));
                    mXPUSHs(newRV_noinc((SV *)hv));
                }
                ares_free_data(naptr_out);
            }
            break;
        }

        case T_CAA: {
            struct ares_caa_reply *caa_out = NULL;
            if (ares_parse_caa_reply(abuf, alen, &caa_out) == ARES_SUCCESS && caa_out) {
                struct ares_caa_reply *c;
                for (c = caa_out; c; c = c->next) {
                    HV *hv = newHV();
                    hv_stores(hv, "critical", newSViv(c->critical));
                    hv_stores(hv, "property", newSVpvn((char *)c->property, c->plength));
                    hv_stores(hv, "value",    newSVpvn((char *)c->value, c->length));
                    mXPUSHs(newRV_noinc((SV *)hv));
                }
                ares_free_data(caa_out);
            }
            break;
        }

#ifdef HAVE_ARES_DNS_PARSE
        case T_DS:
        case T_RRSIG:
        case T_DNSKEY: {
            /* DS/DNSKEY/RRSIG aren't in c-ares' parsed type set, so they
               arrive as ARES_REC_TYPE_RAW_RR. Pull out the rdata and
               parse the wire format ourselves (RFC 4034). */
            ares_dns_record_t *dnsrec = NULL;
            if (ares_dns_parse(abuf, alen, 0, &dnsrec) == ARES_SUCCESS && dnsrec) {
                size_t cnt = ares_dns_record_rr_cnt(dnsrec, ARES_SECTION_ANSWER);
                size_t i;
                for (i = 0; i < cnt; i++) {
                    const ares_dns_rr_t *rr = ares_dns_record_rr_get_const(
                        dnsrec, ARES_SECTION_ANSWER, i);
                    unsigned short raw_type;
                    const unsigned char *rd;
                    size_t rdlen;
                    HV *hv;

                    if (ares_dns_rr_get_type(rr) != ARES_REC_TYPE_RAW_RR)
                        continue;
                    raw_type = ares_dns_rr_get_u16(rr, ARES_RR_RAW_RR_TYPE);
                    if (raw_type != req->qtype) continue;

                    rd = ares_dns_rr_get_bin(rr, ARES_RR_RAW_RR_DATA, &rdlen);
                    if (!rd) continue;

                    hv = newHV();
                    if (raw_type == T_DS && rdlen >= 4) {
                        hv_stores(hv, "key_tag",     newSViv((rd[0] << 8) | rd[1]));
                        hv_stores(hv, "algorithm",   newSViv(rd[2]));
                        hv_stores(hv, "digest_type", newSViv(rd[3]));
                        hv_stores(hv, "digest",
                            newSVpvn((const char *)rd + 4, rdlen - 4));
                    } else if (raw_type == T_DNSKEY && rdlen >= 4) {
                        hv_stores(hv, "flags",      newSViv((rd[0] << 8) | rd[1]));
                        hv_stores(hv, "protocol",   newSViv(rd[2]));
                        hv_stores(hv, "algorithm",  newSViv(rd[3]));
                        hv_stores(hv, "public_key",
                            newSVpvn((const char *)rd + 4, rdlen - 4));
                    } else if (raw_type == T_RRSIG && rdlen >= 18) {
                        size_t pos = 18;
                        char signer[256];
                        size_t snlen = 0;
                        int signer_overflow = 0;
                        int saw_null_label = 0;
                        /* uncompressed DNS labels (RFC 4034 sec 3.1.7) */
                        while (pos < rdlen) {
                            unsigned char l = rd[pos++];
                            size_t need;
                            if (l == 0) { saw_null_label = 1; break; }
                            if ((l & 0xc0) || pos + l > rdlen) {
                                pos = rdlen + 1; /* malformed */
                                break;
                            }
                            need = (snlen ? 1 : 0) + l;
                            if (snlen + need >= sizeof signer) {
                                signer_overflow = 1;
                                break;
                            }
                            if (snlen) signer[snlen++] = '.';
                            memcpy(signer + snlen, rd + pos, l);
                            snlen += l;
                            pos += l;
                        }
                        /* RFC 4034 §3.1.7: signer's name is uncompressed wire
                           format with explicit root label.  Reject pointer/
                           overrun, presentation-buffer overflow, or labels
                           that were consumed without a closing null. */
                        if (pos > rdlen || signer_overflow || !saw_null_label) {
                            SvREFCNT_dec((SV *)hv);
                            continue;
                        }

                        hv_stores(hv, "type_covered",
                            newSViv((rd[0] << 8) | rd[1]));
                        hv_stores(hv, "algorithm",  newSViv(rd[2]));
                        hv_stores(hv, "labels",     newSViv(rd[3]));
                        hv_stores(hv, "original_ttl",
                            newSVuv(((U32)rd[4] << 24) | ((U32)rd[5] << 16) |
                                    ((U32)rd[6] <<  8) |  (U32)rd[7]));
                        hv_stores(hv, "sig_expiration",
                            newSVuv(((U32)rd[ 8] << 24) | ((U32)rd[ 9] << 16) |
                                    ((U32)rd[10] <<  8) |  (U32)rd[11]));
                        hv_stores(hv, "sig_inception",
                            newSVuv(((U32)rd[12] << 24) | ((U32)rd[13] << 16) |
                                    ((U32)rd[14] <<  8) |  (U32)rd[15]));
                        hv_stores(hv, "key_tag",
                            newSViv((rd[16] << 8) | rd[17]));
                        hv_stores(hv, "signer_name", newSVpv(signer, snlen));
                        hv_stores(hv, "signature",
                            newSVpvn((const char *)rd + pos, rdlen - pos));
                    } else {
                        SvREFCNT_dec((SV *)hv);
                        continue;
                    }
                    mXPUSHs(newRV_noinc((SV *)hv));
                }
                ares_dns_record_destroy(dnsrec);
            }
            break;
        }

        case T_TLSA: {
            ares_dns_record_t *dnsrec = NULL;
            if (ares_dns_parse(abuf, alen, 0, &dnsrec) == ARES_SUCCESS && dnsrec) {
                size_t cnt = ares_dns_record_rr_cnt(dnsrec, ARES_SECTION_ANSWER);
                size_t i;
                for (i = 0; i < cnt; i++) {
                    const ares_dns_rr_t *rr = ares_dns_record_rr_get_const(
                        dnsrec, ARES_SECTION_ANSWER, i);
                    HV *hv;
                    const unsigned char *data;
                    size_t data_len;

                    if (ares_dns_rr_get_type(rr) != ARES_REC_TYPE_TLSA) continue;

                    hv = newHV();
                    hv_stores(hv, "cert_usage",
                        newSViv(ares_dns_rr_get_u8(rr, ARES_RR_TLSA_CERT_USAGE)));
                    hv_stores(hv, "selector",
                        newSViv(ares_dns_rr_get_u8(rr, ARES_RR_TLSA_SELECTOR)));
                    hv_stores(hv, "matching_type",
                        newSViv(ares_dns_rr_get_u8(rr, ARES_RR_TLSA_MATCH)));
                    data = ares_dns_rr_get_bin(rr, ARES_RR_TLSA_DATA, &data_len);
                    hv_stores(hv, "data",
                        newSVpvn(data ? (const char *)data : "", data ? data_len : 0));
                    mXPUSHs(newRV_noinc((SV *)hv));
                }
                ares_dns_record_destroy(dnsrec);
            }
            break;
        }

        case T_HTTPS:
        case T_SVCB: {
            ares_dns_record_t *dnsrec = NULL;
            if (ares_dns_parse(abuf, alen, 0, &dnsrec) == ARES_SUCCESS && dnsrec) {
                size_t cnt = ares_dns_record_rr_cnt(dnsrec, ARES_SECTION_ANSWER);
                size_t i, j;
                for (i = 0; i < cnt; i++) {
                    const ares_dns_rr_t *rr = ares_dns_record_rr_get_const(
                        dnsrec, ARES_SECTION_ANSWER, i);
                    ares_dns_rec_type_t rtype = ares_dns_rr_get_type(rr);
                    ares_dns_rr_key_t prio_key, target_key, params_key;
                    unsigned short prio;
                    const char *target;
                    HV *hv, *params;
                    size_t opt_cnt;

                    if (rtype == ARES_REC_TYPE_HTTPS) {
                        prio_key   = ARES_RR_HTTPS_PRIORITY;
                        target_key = ARES_RR_HTTPS_TARGET;
                        params_key = ARES_RR_HTTPS_PARAMS;
                    } else if (rtype == ARES_REC_TYPE_SVCB) {
                        prio_key   = ARES_RR_SVCB_PRIORITY;
                        target_key = ARES_RR_SVCB_TARGET;
                        params_key = ARES_RR_SVCB_PARAMS;
                    } else {
                        continue;
                    }

                    prio   = ares_dns_rr_get_u16(rr, prio_key);
                    target = ares_dns_rr_get_str(rr, target_key);

                    hv = newHV();
                    hv_stores(hv, "priority", newSViv(prio));
                    hv_stores(hv, "target",   newSVpv(target ? target : "", 0));

                    params  = newHV();
                    opt_cnt = ares_dns_rr_get_opt_cnt(rr, params_key);
                    for (j = 0; j < opt_cnt; j++) {
                        const unsigned char *val;
                        size_t vlen;
                        unsigned short opt_id = ares_dns_rr_get_opt(
                            rr, params_key, j, &val, &vlen);

                        switch (opt_id) {
                        case 1: { /* alpn: list of length-prefixed strings */
                            AV *av = newAV();
                            size_t pos = 0;
                            while (pos < vlen) {
                                size_t plen = val[pos++];
                                /* zero-length entry would loop forever; bail */
                                if (plen == 0 || pos + plen > vlen) break;
                                av_push(av, newSVpvn((const char *)&val[pos], plen));
                                pos += plen;
                            }
                            hv_stores(params, "alpn", newRV_noinc((SV *)av));
                            break;
                        }
                        case 2: /* no-default-alpn */
                            hv_stores(params, "no_default_alpn", newSViv(1));
                            break;
                        case 3: /* port: u16 */
                            if (vlen >= 2)
                                hv_stores(params, "port",
                                    newSViv((val[0] << 8) | val[1]));
                            break;
                        case 4: { /* ipv4hint: list of in_addr */
                            AV *av = newAV();
                            size_t pos;
                            for (pos = 0; pos + 4 <= vlen; pos += 4) {
                                char ipstr[INET_ADDRSTRLEN];
                                struct in_addr a;     /* aligned local — val[pos]
                                                         is byte-aligned only */
                                memcpy(&a, &val[pos], sizeof a);
                                inet_ntop(AF_INET, &a, ipstr, sizeof ipstr);
                                av_push(av, newSVpv(ipstr, 0));
                            }
                            hv_stores(params, "ipv4hint", newRV_noinc((SV *)av));
                            break;
                        }
                        case 5: /* ech: opaque base64-able blob */
                            hv_stores(params, "ech",
                                newSVpvn((const char *)val, vlen));
                            break;
                        case 6: { /* ipv6hint: list of in6_addr */
                            AV *av = newAV();
                            size_t pos;
                            for (pos = 0; pos + 16 <= vlen; pos += 16) {
                                char ipstr[INET6_ADDRSTRLEN];
                                struct in6_addr a;    /* aligned local */
                                memcpy(&a, &val[pos], sizeof a);
                                inet_ntop(AF_INET6, &a, ipstr, sizeof ipstr);
                                av_push(av, newSVpv(ipstr, 0));
                            }
                            hv_stores(params, "ipv6hint", newRV_noinc((SV *)av));
                            break;
                        }
                        case 7: /* dohpath */
                            hv_stores(params, "dohpath",
                                newSVpvn((const char *)val, vlen));
                            break;
                        default: {
                            char k[16];
                            int klen = snprintf(k, sizeof k, "key%u", opt_id);
                            hv_store(params, k, klen,
                                newSVpvn((const char *)val, vlen), 0);
                            break;
                        }
                        }
                    }
                    hv_stores(hv, "params", newRV_noinc((SV *)params));
                    mXPUSHs(newRV_noinc((SV *)hv));
                }
                ares_dns_record_destroy(dnsrec);
            }
            break;
        }
#endif

        default:
            mXPUSHp((char *)abuf, alen);
            break;
        }
    }

    CB_EPILOGUE;
}

static void
nameinfo_cb(void *arg, int status, int timeouts, char *node, char *service) {
    CB_PROLOGUE(arg, status);

    if (status == ARES_SUCCESS) {
        if (node)
            mXPUSHp(node, strlen(node));
        else
            XPUSHs(&PL_sv_undef);

        if (service)
            mXPUSHp(service, strlen(service));
        else
            XPUSHs(&PL_sv_undef);
    }

    CB_EPILOGUE;
}


MODULE = EV::cares    PACKAGE = EV::cares    PREFIX = ev_cares_

BOOT:
{
    I_EV_API("EV::cares");
    {
        int rc = ares_library_init(ARES_LIB_INIT_ALL);
        if (rc != ARES_SUCCESS)
            croak("EV::cares: ares_library_init: %s", ares_strerror(rc));
    }
    {
        HV *stash = gv_stashpvn("EV::cares", 9, GV_ADD);

        /* status codes */
        CONST_IV(stash, ARES_SUCCESS);
        CONST_IV(stash, ARES_ENODATA);
        CONST_IV(stash, ARES_EFORMERR);
        CONST_IV(stash, ARES_ESERVFAIL);
        CONST_IV(stash, ARES_ENOTFOUND);
        CONST_IV(stash, ARES_ENOTIMP);
        CONST_IV(stash, ARES_EREFUSED);
        CONST_IV(stash, ARES_EBADQUERY);
        CONST_IV(stash, ARES_EBADNAME);
        CONST_IV(stash, ARES_EBADFAMILY);
        CONST_IV(stash, ARES_EBADRESP);
        CONST_IV(stash, ARES_ECONNREFUSED);
        CONST_IV(stash, ARES_ETIMEOUT);
        CONST_IV(stash, ARES_EOF);
        CONST_IV(stash, ARES_EFILE);
        CONST_IV(stash, ARES_ENOMEM);
        CONST_IV(stash, ARES_EDESTRUCTION);
        CONST_IV(stash, ARES_EBADSTR);
        CONST_IV(stash, ARES_EBADFLAGS);
        CONST_IV(stash, ARES_ENONAME);
        CONST_IV(stash, ARES_EBADHINTS);
        CONST_IV(stash, ARES_ENOTINITIALIZED);
        CONST_IV(stash, ARES_ECANCELLED);
        CONST_IV(stash, ARES_ESERVICE);
        CONST_IV(stash, ARES_ENOSERVER);

        /* DNS types */
        CONST_IV(stash, T_A);
        CONST_IV(stash, T_NS);
        CONST_IV(stash, T_CNAME);
        CONST_IV(stash, T_SOA);
        CONST_IV(stash, T_PTR);
        CONST_IV(stash, T_MX);
        CONST_IV(stash, T_TXT);
        CONST_IV(stash, T_AAAA);
        CONST_IV(stash, T_SRV);
        CONST_IV(stash, T_NAPTR);
        CONST_IV(stash, T_DS);
        CONST_IV(stash, T_RRSIG);
        CONST_IV(stash, T_DNSKEY);
        CONST_IV(stash, T_TLSA);
        CONST_IV(stash, T_SVCB);
        CONST_IV(stash, T_HTTPS);
        CONST_IV(stash, T_CAA);
        CONST_IV(stash, T_ANY);

        /* DNS classes */
        CONST_IV(stash, C_IN);
        CONST_IV(stash, C_CHAOS);
        CONST_IV(stash, C_HS);
        CONST_IV(stash, C_ANY);

        /* channel flags */
        CONST_IV(stash, ARES_FLAG_USEVC);
        CONST_IV(stash, ARES_FLAG_PRIMARY);
        CONST_IV(stash, ARES_FLAG_IGNTC);
        CONST_IV(stash, ARES_FLAG_NORECURSE);
        CONST_IV(stash, ARES_FLAG_STAYOPEN);
        CONST_IV(stash, ARES_FLAG_NOSEARCH);
        CONST_IV(stash, ARES_FLAG_NOALIASES);
        CONST_IV(stash, ARES_FLAG_NOCHECKRESP);
        CONST_IV(stash, ARES_FLAG_EDNS);
        CONST_IV(stash, ARES_FLAG_NO_DFLT_SVR);
        CONST_IV(stash, ARES_FLAG_DNS0x20);

        /* addrinfo hint flags */
        CONST_IV(stash, ARES_AI_CANONNAME);
        CONST_IV(stash, ARES_AI_NUMERICHOST);
        CONST_IV(stash, ARES_AI_PASSIVE);
        CONST_IV(stash, ARES_AI_NUMERICSERV);
        CONST_IV(stash, ARES_AI_V4MAPPED);
        CONST_IV(stash, ARES_AI_ALL);
        CONST_IV(stash, ARES_AI_ADDRCONFIG);
        CONST_IV(stash, ARES_AI_NOSORT);

        /* nameinfo flags */
        CONST_IV(stash, ARES_NI_NOFQDN);
        CONST_IV(stash, ARES_NI_NUMERICHOST);
        CONST_IV(stash, ARES_NI_NAMEREQD);
        CONST_IV(stash, ARES_NI_NUMERICSERV);
        CONST_IV(stash, ARES_NI_DGRAM);
        CONST_IV(stash, ARES_NI_TCP);
        CONST_IV(stash, ARES_NI_UDP);

        /* address families */
        CONST_IV(stash, AF_INET);
        CONST_IV(stash, AF_INET6);
        CONST_IV(stash, AF_UNSPEC);
    }
}

void
new(class, ...)
PPCODE:
{
    const char *class_name = SvPV_nolen(ST(0));
    ev_cares_t *self;
    struct ares_options opts;
    int optmask = 0;
    int status, i;
    const char *servers = NULL;
    struct ev_loop *loop_ptr = EV_DEFAULT;
    SV *loop_sv = NULL;

    if ((items - 1) % 2 != 0)
        croak("EV::cares::new: odd number of arguments");

    memset(&opts, 0, sizeof(opts));

    for (i = 1; i < items; i += 2) {
        const char *key = SvPV_nolen(ST(i));
        SV *val = ST(i + 1);

        if (strEQ(key, "loop")) {
            if (SvOK(val)) {
                if (!SvROK(val) || !sv_derived_from(val, "EV::Loop"))
                    croak("EV::cares::new: 'loop' must be an EV::Loop instance");
                /* SvIV (not SvIVX) so any get-magic on the inner SV is
                   honoured before extracting the loop pointer. */
                loop_ptr = INT2PTR(struct ev_loop *, SvIV(SvRV(val)));
                loop_sv = val;  /* refcount bumped after struct alloc */
            }
        }
        else if (strEQ(key, "timeout")) {
            opts.timeout = (int)(SvNV(val) * 1000);
            optmask |= ARES_OPT_TIMEOUTMS;
        }
        else if (strEQ(key, "tries")) {
            opts.tries = SvIV(val);
            optmask |= ARES_OPT_TRIES;
        }
        else if (strEQ(key, "ndots")) {
            opts.ndots = SvIV(val);
            optmask |= ARES_OPT_NDOTS;
        }
        else if (strEQ(key, "flags")) {
            opts.flags = SvIV(val);
            optmask |= ARES_OPT_FLAGS;
        }
        else if (strEQ(key, "lookups")) {
            opts.lookups = SvPV_nolen(val);  /* c-ares copies internally */
            optmask |= ARES_OPT_LOOKUPS;
        }
        else if (strEQ(key, "tcp_port")) {
            opts.tcp_port = (unsigned short)SvUV(val);
            optmask |= ARES_OPT_TCP_PORT;
        }
        else if (strEQ(key, "udp_port")) {
            opts.udp_port = (unsigned short)SvUV(val);
            optmask |= ARES_OPT_UDP_PORT;
        }
        else if (strEQ(key, "servers")) {
            if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
                AV *av = (AV *)SvRV(val);
                if (av_len(av) < 0)
                    croak("EV::cares::new: 'servers' arrayref is empty");
                servers = SvPV_nolen(av_to_csv(aTHX_ av));
            } else {
                servers = SvPV_nolen(val);
            }
        }
        else if (strEQ(key, "rotate")) {
            if (SvTRUE(val)) {
 #ifdef ARES_OPT_ROTATE
                optmask |= ARES_OPT_ROTATE;
 #endif
            }
        }
 #ifdef ARES_OPT_EDNSPSZ
        else if (strEQ(key, "ednspsz")) {
            opts.ednspsz = SvIV(val);
            optmask |= ARES_OPT_EDNSPSZ;
        }
 #endif
 #ifdef ARES_OPT_RESOLVCONF
        else if (strEQ(key, "resolvconf")) {
            opts.resolvconf_path = SvPV_nolen(val);  /* c-ares copies internally */
            optmask |= ARES_OPT_RESOLVCONF;
        }
 #endif
 #ifdef ARES_OPT_HOSTS_FILE
        else if (strEQ(key, "hosts_file")) {
            opts.hosts_path = SvPV_nolen(val);  /* c-ares copies internally */
            optmask |= ARES_OPT_HOSTS_FILE;
        }
 #endif
 #ifdef ARES_OPT_UDP_MAX_QUERIES
        else if (strEQ(key, "udp_max_queries")) {
            opts.udp_max_queries = SvIV(val);
            optmask |= ARES_OPT_UDP_MAX_QUERIES;
        }
 #endif
 #ifdef ARES_OPT_MAXTIMEOUTMS
        else if (strEQ(key, "maxtimeout")) {
            opts.maxtimeout = (int)(SvNV(val) * 1000);
            optmask |= ARES_OPT_MAXTIMEOUTMS;
        }
 #endif
 #ifdef ARES_OPT_QUERY_CACHE
        else if (strEQ(key, "qcache")) {
            opts.qcache_max_ttl = (unsigned int)SvUV(val);
            optmask |= ARES_OPT_QUERY_CACHE;
        }
 #endif
        else {
            warn("EV::cares::new: unknown option '%s'", key);
        }
    }

    Newxz(self, 1, ev_cares_t);
    self->magic = EV_CARES_MAGIC;
    self->loop = loop_ptr;
    /* Keep the EV::Loop's blessed object alive — its DESTROY calls
       ev_loop_destroy().  Holding the outer RV is not enough; inc the
       underlying SV (the IV that stores the loop pointer). */
    if (loop_sv) self->loop_sv = SvREFCNT_inc_simple_NN(SvRV(loop_sv));
    for (i = 0; i < MAX_IO; i++)
        self->ios[i].fd = ARES_SOCKET_BAD;

    opts.sock_state_cb = sock_state_cb;
    opts.sock_state_cb_data = self;
    optmask |= ARES_OPT_SOCK_STATE_CB;

    status = ares_init_options(&self->channel, &opts, optmask);
    if (status != ARES_SUCCESS) {
        if (self->loop_sv) SvREFCNT_dec(self->loop_sv);
        Safefree(self);
        croak("EV::cares::new: ares_init_options: %s", ares_strerror(status));
    }

    if (servers) {
        status = ares_set_servers_csv(self->channel, servers);
        if (status != ARES_SUCCESS) {
            ares_destroy(self->channel);
            if (self->loop_sv) SvREFCNT_dec(self->loop_sv);
            Safefree(self);
            croak("EV::cares::new: set_servers: %s", ares_strerror(status));
        }
    }

    ev_timer_init(&self->timer, timer_cb, 0., 0.);
    self->timer.data = (void *)self;

    {
        SV *sv = newSV(0);
        sv_setref_pv(sv, class_name, (void *)self);
        XPUSHs(sv_2mortal(sv));
    }
}

void
resolve(self, name, cb)
    EV::cares self
    const char *name
    SV *cb
CODE:
{
    struct ares_addrinfo_hints hints;
    ev_cares_req_t *req;

    REQUIRE_LIVE(self);
    REQUIRE_CB(cb);

    memset(&hints, 0, sizeof(hints));
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;

    req = new_req(aTHX_ self, cb);
    ARES_CALL_BEGIN(self);
    ares_getaddrinfo(self->channel, name, NULL, &hints, addrinfo_cb, req);
    ARES_CALL_END(self);
}

void
resolve_ttl(self, name, cb)
    EV::cares self
    const char *name
    SV *cb
CODE:
{
    struct ares_addrinfo_hints hints;
    ev_cares_req_t *req;

    REQUIRE_LIVE(self);
    REQUIRE_CB(cb);

    memset(&hints, 0, sizeof(hints));
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;

    req = new_req(aTHX_ self, cb);
    req->with_ttl = 1;
    ARES_CALL_BEGIN(self);
    ares_getaddrinfo(self->channel, name, NULL, &hints, addrinfo_cb, req);
    ARES_CALL_END(self);
}

void
getaddrinfo(self, node, service, hints_hv, cb)
    EV::cares self
    SV *node
    SV *service
    SV *hints_hv
    SV *cb
CODE:
{
    const char *c_node    = SvOK(node)    ? SvPV_nolen(node)    : NULL;
    const char *c_service = SvOK(service) ? SvPV_nolen(service) : NULL;
    struct ares_addrinfo_hints hints;
    ev_cares_req_t *req;

    REQUIRE_LIVE(self);
    REQUIRE_CB(cb);

    memset(&hints, 0, sizeof(hints));
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;  /* avoid duplicate entries per socktype */

    req = new_req(aTHX_ self, cb);

    if (SvROK(hints_hv) && SvTYPE(SvRV(hints_hv)) == SVt_PVHV) {
        HV *hv = (HV *)SvRV(hints_hv);
        SV **sv;
        if ((sv = hv_fetchs(hv, "family",   0))) hints.ai_family   = SvIV(*sv);
        if ((sv = hv_fetchs(hv, "socktype", 0))) hints.ai_socktype = SvIV(*sv);
        if ((sv = hv_fetchs(hv, "protocol", 0))) hints.ai_protocol = SvIV(*sv);
        if ((sv = hv_fetchs(hv, "flags",    0))) hints.ai_flags    = SvIV(*sv);
        if ((sv = hv_fetchs(hv, "ttl",      0)) && SvTRUE(*sv))
            req->with_ttl = 1;
    }

    ARES_CALL_BEGIN(self);
    ares_getaddrinfo(self->channel, c_node, c_service, &hints, addrinfo_cb, req);
    ARES_CALL_END(self);
}

void
gethostbyname(self, name, family, cb)
    EV::cares self
    const char *name
    int family
    SV *cb
CODE:
{
    ev_cares_req_t *req;
    REQUIRE_LIVE(self);
    REQUIRE_CB(cb);
    req = new_req(aTHX_ self, cb);
    ARES_CALL_BEGIN(self);
    ares_gethostbyname(self->channel, name, family, host_cb, req);
    ARES_CALL_END(self);
}

void
search(self, name, type, ...)
    EV::cares self
    const char *name
    int type
PREINIT:
    SV *cb;
    int dnsclass = C_IN;
    ev_cares_req_t *req;
CODE:
{
    REQUIRE_LIVE(self);
    /* search($name, $type, $cb)            -> items == 4
       search($name, $type, $class, $cb)    -> items == 5 */
    if (items == 4) {
        cb = ST(3);
    } else if (items == 5) {
        dnsclass = SvIV(ST(3));
        cb = ST(4);
    } else {
        croak("Usage: $r->search($name, $type, [$class,] $cb)");
    }
    REQUIRE_CB(cb);

    req = new_req(aTHX_ self, cb);
    req->qtype = type;
    ARES_CALL_BEGIN(self);
    ares_search(self->channel, name, dnsclass, type, search_cb, req);
    ARES_CALL_END(self);
}

void
query(self, name, dnsclass, type, cb)
    EV::cares self
    const char *name
    int dnsclass
    int type
    SV *cb
CODE:
{
    ev_cares_req_t *req;
    REQUIRE_LIVE(self);
    REQUIRE_CB(cb);
    req = new_req(aTHX_ self, cb);
    ARES_CALL_BEGIN(self);
    ares_query(self->channel, name, dnsclass, type, raw_cb, req);
    ARES_CALL_END(self);
}

void
reverse(self, ip, cb)
    EV::cares self
    const char *ip
    SV *cb
CODE:
{
    struct in_addr addr4;
    struct in6_addr addr6;
    ev_cares_req_t *req;
    const void *ap;
    size_t alen;
    int family;

    REQUIRE_LIVE(self);
    REQUIRE_CB(cb);

    /* validate before entering the ARES_CALL bracket so croak doesn't
       leave in_callback unbalanced */
    if (inet_pton(AF_INET, ip, &addr4) == 1) {
        family = AF_INET;  ap = &addr4; alen = sizeof addr4;
    } else if (inet_pton(AF_INET6, ip, &addr6) == 1) {
        family = AF_INET6; ap = &addr6; alen = sizeof addr6;
    } else {
        croak("EV::cares::reverse: invalid IP address: %s", ip);
    }

    req = new_req(aTHX_ self, cb);
    req->by_addr = 1;
    ARES_CALL_BEGIN(self);
    ares_gethostbyaddr(self->channel, ap, alen, family, host_cb, req);
    ARES_CALL_END(self);
}

void
getnameinfo(self, sa, flags, cb)
    EV::cares self
    SV *sa
    int flags
    SV *cb
CODE:
{
    STRLEN len;
    const char *addr = SvPV(sa, len);
    ev_cares_req_t *req;
    struct sockaddr_storage ss;
    sa_family_t family;
    STRLEN min_len;

    REQUIRE_LIVE(self);
    REQUIRE_CB(cb);

    /* Require enough bytes to safely read sa_family (sa_family_t lives at
       different offsets across platforms — Linux puts it at byte 0, BSD
       has sa_len at byte 0 and sa_family at byte 1).  sizeof(struct
       sockaddr) is the universal lower bound for either layout. */
    if (len < sizeof(struct sockaddr))
        croak("EV::cares::getnameinfo: sockaddr too short (%d bytes)", (int)len);

    /* Copy into a local sockaddr_storage so both the family read and
       the c-ares call see properly-aligned bytes (matters on strict-
       alignment architectures like SPARC / classic MIPS). */
    if (len > sizeof ss) len = sizeof ss;
    memcpy(&ss, addr, len);
    family = ((struct sockaddr *)&ss)->sa_family;
    if (family == AF_INET)       min_len = sizeof(struct sockaddr_in);
    else if (family == AF_INET6) min_len = sizeof(struct sockaddr_in6);
    else croak("EV::cares::getnameinfo: unsupported sockaddr family %d "
               "(need AF_INET or AF_INET6)", (int)family);
    if (len < min_len)
        croak("EV::cares::getnameinfo: sockaddr too short for %s (%d bytes)",
              family == AF_INET6 ? "AF_INET6" : "AF_INET", (int)len);

    req = new_req(aTHX_ self, cb);
    ARES_CALL_BEGIN(self);
    ares_getnameinfo(self->channel, (const struct sockaddr *)&ss,
                     (ares_socklen_t)len, flags, nameinfo_cb, req);
    ARES_CALL_END(self);
}

void
cancel(self)
    EV::cares self
CODE:
    REQUIRE_LIVE(self);
    ARES_CALL_BEGIN(self);
    ares_cancel(self->channel);
    ARES_CALL_END(self);

void
set_servers(self, ...)
    EV::cares self
CODE:
{
    SV *csv;
    int rc, i;

    REQUIRE_LIVE(self);
    if (items <= 1)
        croak("EV::cares::set_servers: requires at least one server address");

    /* accept either a single arrayref or a flat list, mirroring `new(servers => ...)` */
    if (items == 2 && SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVAV) {
        AV *av = (AV *)SvRV(ST(1));
        if (av_len(av) < 0)
            croak("EV::cares::set_servers: empty arrayref");
        csv = av_to_csv(aTHX_ av);
    } else {
        csv = sv_2mortal(newSVpvs(""));
        for (i = 1; i < items; i++) {
            if (SvROK(ST(i)))
                croak("EV::cares::set_servers: arg %d is a reference; "
                      "use the arrayref form for {host,port} hashrefs", i);
            if (i > 1) sv_catpvs(csv, ",");
            sv_catsv(csv, ST(i));
        }
    }

    rc = ares_set_servers_csv(self->channel, SvPV_nolen(csv));
    if (rc != ARES_SUCCESS)
        croak("EV::cares::set_servers: %s", ares_strerror(rc));
}

void
servers(self)
    EV::cares self
PPCODE:
{
    char *csv;
    REQUIRE_LIVE(self);
    csv = ares_get_servers_csv(self->channel);
    if (!csv) croak("EV::cares::servers: ares_get_servers_csv failed");
    mXPUSHp(csv, strlen(csv));
    ares_free_string(csv);
}

void
set_local_dev(self, dev)
    EV::cares self
    const char *dev
CODE:
    REQUIRE_LIVE(self);
    ares_set_local_dev(self->channel, dev);

void
set_local_ip4(self, ip)
    EV::cares self
    const char *ip
CODE:
{
    struct in_addr addr;
    REQUIRE_LIVE(self);
    if (inet_pton(AF_INET, ip, &addr) != 1)
        croak("EV::cares::set_local_ip4: invalid IPv4 address: %s", ip);
    ares_set_local_ip4(self->channel, ntohl(addr.s_addr));
}

void
set_local_ip6(self, ip)
    EV::cares self
    const char *ip
CODE:
{
    struct in6_addr addr;
    REQUIRE_LIVE(self);
    if (inet_pton(AF_INET6, ip, &addr) != 1)
        croak("EV::cares::set_local_ip6: invalid IPv6 address: %s", ip);
    ares_set_local_ip6(self->channel, (const unsigned char *)&addr);
}

int
active_queries(self)
    EV::cares self
CODE:
    RETVAL = self->active_queries;
OUTPUT:
    RETVAL

int
last_query_timeouts(self)
    EV::cares self
CODE:
    RETVAL = self->last_timeouts;
OUTPUT:
    RETVAL

int
is_destroyed(self)
    EV::cares self
CODE:
    RETVAL = self->destroyed;
OUTPUT:
    RETVAL

SV *
loop(self)
    EV::cares self
CODE:
    /* Return a fresh RV to the user-supplied EV::Loop blessed object, or
       undef when this resolver runs on EV's default loop.  Used by
       wait_idle() so it pumps the same loop the watchers are armed on. */
    RETVAL = self->loop_sv ? newRV_inc(self->loop_sv) : &PL_sv_undef;
OUTPUT:
    RETVAL

double
next_timeout(self)
    EV::cares self
CODE:
{
    struct timeval tv, *tvp;
    REQUIRE_LIVE(self);
    tvp = ares_timeout(self->channel, NULL, &tv);
    RETVAL = tvp ? (double)tvp->tv_sec + (double)tvp->tv_usec / 1e6 : -1.0;
}
OUTPUT:
    RETVAL

void
set_sortlist(self, sortlist)
    EV::cares self
    const char *sortlist
CODE:
{
    int rc;
    REQUIRE_LIVE(self);
    rc = ares_set_sortlist(self->channel, sortlist);
    if (rc != ARES_SUCCESS)
        croak("EV::cares::set_sortlist: %s", ares_strerror(rc));
}

void
destroy(self)
    EV::cares self
CODE:
    /* Deliberately weaker than REQUIRE_LIVE — only checks magic, not
       destroyed.  This makes double-destroy a silent no-op (cleanup()
       early-returns when destroyed=1), per the documented contract. */
    if (self->magic != EV_CARES_MAGIC) croak("EV::cares: invalid object");
    cleanup(self);

void
reinit(self)
    EV::cares self
CODE:
{
    int rc;
    REQUIRE_LIVE(self);
    rc = ares_reinit(self->channel);
    if (rc != ARES_SUCCESS)
        croak("EV::cares::reinit: %s", ares_strerror(rc));
}

void
DESTROY(self)
    EV::cares self
CODE:
    if (self->magic != EV_CARES_MAGIC) return;

    if (PL_dirty) {
        /* Global destruction: skip everything that would touch other
           SVs or libev (their teardown order is unspecified) and leak
           self.  Stopping watchers during PL_dirty is unsafe, and
           freeing self while watchers still reference it has caused
           SEGVs on musl during process exit.  OS reclaims at exit. */
        self->destroyed = 1;
        self->channel = NULL;
        return;
    }

    cleanup(self);
    if (self->in_callback) {
        /* defer Safefree until the outer ARES_CALL_END unwinds.  Every
           callback path enters through an ARES_CALL_BEGIN bracket (io_cb,
           timer_cb, or an XS query method), so the matching ARES_CALL_END
           drops in_callback to 0 and frees self there. */
        self->free_pending = 1;
    } else {
        Safefree(self);
    }

const char *
strerror(...)
CODE:
{
    SV *arg;
    /* accept both EV::cares::strerror($n) and EV::cares->strerror($n) */
    if (items == 1)      arg = ST(0);
    else if (items >= 2) arg = ST(1);   /* skip class/instance arg */
    else croak("Usage: EV::cares::strerror(status)");

    /* looks_like_number returns false for refs, so SvROK precheck not needed */
    if (!looks_like_number(arg))
        croak("Usage: EV::cares::strerror(status)");

    RETVAL = ares_strerror(SvIV(arg));
}
OUTPUT:
    RETVAL

const char *
lib_version(...)
CODE:
    RETVAL = ares_version(NULL);
OUTPUT:
    RETVAL
