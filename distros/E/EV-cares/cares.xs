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
#ifndef T_CAA
  #define T_CAA   257
#endif
#ifndef T_ANY
  #define T_ANY   255
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
  #define NO_ARES_FLAG_NO_DFLT_SVR 1
#endif
#ifndef ARES_FLAG_DNS0x20
  #define ARES_FLAG_DNS0x20 0
  #define NO_ARES_FLAG_DNS0x20 1
#endif
#ifndef ARES_ESERVICE
  #define ARES_ESERVICE 25
  #define NO_ARES_ESERVICE 1
#endif
#ifndef ARES_ENOSERVER
  #define ARES_ENOSERVER 26
  #define NO_ARES_ENOSERVER 1
#endif

#define EV_CARES_MAGIC 0xCA7E5001
#define EV_CARES_FREED 0xCA7E5DEF
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
    ev_timer timer;
    ev_cares_io_t ios[MAX_IO];
    int active_queries;
    int destroyed;
    int in_callback;   /* prevent Safefree while callbacks run */
    int free_pending;  /* deferred Safefree after last callback */
};

typedef struct {
    ev_cares_t *resolver;
    SV *cb;
    int qtype;
} ev_cares_req_t;

/* forward declarations */
static void update_timer(ev_cares_t *self);

/* Bracket an ares_* call that may fire callbacks synchronously.
 * Prevents UAF if user DESTROY's the resolver inside a callback. */
#define ARES_CALL_BEGIN(self)  (self)->in_callback++
#define ARES_CALL_END(self)   \
    STMT_START { \
        if (--(self)->in_callback == 0 && (self)->free_pending) \
            Safefree(self); \
        else \
            update_timer(self); \
    } STMT_END
static void io_cb(EV_P_ ev_io *w, int revents);
static void timer_cb(EV_P_ ev_timer *w, int revents);
static void sock_state_cb(void *data, ares_socket_t fd, int readable, int writable);
static void cleanup(ev_cares_t *self);

static ev_cares_req_t *
new_req(pTHX_ ev_cares_t *self, SV *cb, int qtype) {
    ev_cares_req_t *req;
    Newx(req, 1, ev_cares_req_t);
    req->resolver = self;
    req->cb = SvREFCNT_inc_simple_NN(cb);
    req->qtype = qtype;
    self->active_queries++;
    return req;
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
            if (i == MAX_IO) return; /* no slots */
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

static void
io_cb(EV_P_ ev_io *w, int revents) {
    ev_cares_t *self = (ev_cares_t *)w->data;
    ares_socket_t rfd = ARES_SOCKET_BAD, wfd = ARES_SOCKET_BAD;
    int i;

    if (self->destroyed || !self->channel) return;

    for (i = 0; i < MAX_IO; i++) {
        if (&self->ios[i].watcher == w) {
            if (revents & EV_READ)  rfd = self->ios[i].fd;
            if (revents & EV_WRITE) wfd = self->ios[i].fd;
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

    if (self->destroyed || !self->channel) return;

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

static void
cleanup(ev_cares_t *self) {
    int i;

    if (self->destroyed) return;
    self->destroyed = 1;

    ev_timer_stop(self->loop, &self->timer);
    for (i = 0; i < MAX_IO; i++) {
        if (self->ios[i].fd != ARES_SOCKET_BAD) {
            ev_io_stop(self->loop, &self->ios[i].watcher);
            self->ios[i].fd = ARES_SOCKET_BAD;
        }
    }

    ares_destroy(self->channel);
    self->channel = NULL;
}

/* ---- callback prologue/epilogue (prevents UAF if resolver freed mid-callback) ---- */

#define CB_PROLOGUE(arg, status_val) \
    ev_cares_req_t *req = (ev_cares_req_t *)(arg); \
    ev_cares_t *self = req->resolver; \
    dTHX; dSP; \
    self->in_callback++; \
    ENTER; SAVETMPS; \
    PUSHMARK(SP); \
    mXPUSHi(status_val)

#define CB_EPILOGUE \
    PUTBACK; \
    { \
        SV *_cb = SvREFCNT_inc_simple_NN(req->cb); \
        call_sv(_cb, G_DISCARD | G_EVAL); \
        if (SvTRUE(ERRSV)) \
            warn("EV::cares: callback error: %" SVf, SVfARG(ERRSV)); \
        SvREFCNT_dec(_cb); \
    } \
    FREETMPS; LEAVE; \
    free_req(aTHX_ req); \
    update_timer(self); \
    if (--self->in_callback == 0 && self->free_pending) \
        Safefree(self)

/* ---- query callbacks ---- */

static void
addrinfo_cb(void *arg, int status, int timeouts, struct ares_addrinfo *result) {
    CB_PROLOGUE(arg, status);

    if (status == ARES_SUCCESS && result) {
        struct ares_addrinfo_node *node;
        for (node = result->nodes; node; node = node->ai_next) {
            char ip[INET6_ADDRSTRLEN];
            if (node->ai_family == AF_INET) {
                struct sockaddr_in *sin = (struct sockaddr_in *)node->ai_addr;
                inet_ntop(AF_INET, &sin->sin_addr, ip, sizeof(ip));
                mXPUSHp(ip, strlen(ip));
            } else if (node->ai_family == AF_INET6) {
                struct sockaddr_in6 *sin6 = (struct sockaddr_in6 *)node->ai_addr;
                inet_ntop(AF_INET6, &sin6->sin6_addr, ip, sizeof(ip));
                mXPUSHp(ip, strlen(ip));
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
    SV *servers_csv = NULL;

    if ((items - 1) % 2 != 0)
        croak("EV::cares::new: odd number of arguments");

    memset(&opts, 0, sizeof(opts));

    for (i = 1; i < items; i += 2) {
        const char *key = SvPV_nolen(ST(i));
        SV *val = ST(i + 1);

        if (strEQ(key, "timeout")) {
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
                SSize_t len = av_len(av) + 1;
                SSize_t j;
                servers_csv = sv_2mortal(newSVpvs(""));
                for (j = 0; j < len; j++) {
                    SV **elem = av_fetch(av, j, 0);
                    if (j > 0) sv_catpvs(servers_csv, ",");
                    if (elem) sv_catsv(servers_csv, *elem);
                }
                servers = SvPV_nolen(servers_csv);
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
            opts.resolvconf_path = SvPV_nolen(val);
            optmask |= ARES_OPT_RESOLVCONF;
        }
 #endif
 #ifdef ARES_OPT_HOSTS_FILE
        else if (strEQ(key, "hosts_file")) {
            opts.hosts_path = SvPV_nolen(val);
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
    self->loop = EV_DEFAULT;
    for (i = 0; i < MAX_IO; i++)
        self->ios[i].fd = ARES_SOCKET_BAD;

    opts.sock_state_cb = sock_state_cb;
    opts.sock_state_cb_data = (void *)self;
    optmask |= ARES_OPT_SOCK_STATE_CB;

    status = ares_init_options(&self->channel, &opts, optmask);
    if (status != ARES_SUCCESS) {
        Safefree(self);
        croak("EV::cares::new: ares_init_options: %s", ares_strerror(status));
    }

    if (servers) {
        status = ares_set_servers_csv(self->channel, servers);
        if (status != ARES_SUCCESS) {
            ares_destroy(self->channel);
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

    req = new_req(aTHX_ self, cb, 0);
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

    if (SvROK(hints_hv) && SvTYPE(SvRV(hints_hv)) == SVt_PVHV) {
        HV *hv = (HV *)SvRV(hints_hv);
        SV **sv;
        if ((sv = hv_fetchs(hv, "family",   0))) hints.ai_family   = SvIV(*sv);
        if ((sv = hv_fetchs(hv, "socktype", 0))) hints.ai_socktype = SvIV(*sv);
        if ((sv = hv_fetchs(hv, "protocol", 0))) hints.ai_protocol = SvIV(*sv);
        if ((sv = hv_fetchs(hv, "flags",    0))) hints.ai_flags    = SvIV(*sv);
    }

    req = new_req(aTHX_ self, cb, 0);
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
    req = new_req(aTHX_ self, cb, 0);
    ARES_CALL_BEGIN(self);
    ares_gethostbyname(self->channel, name, family, host_cb, req);
    ARES_CALL_END(self);
}

void
search(self, name, type, cb)
    EV::cares self
    const char *name
    int type
    SV *cb
CODE:
{
    ev_cares_req_t *req;
    REQUIRE_LIVE(self);
    REQUIRE_CB(cb);
    req = new_req(aTHX_ self, cb, type);
    ARES_CALL_BEGIN(self);
    ares_search(self->channel, name, C_IN, type, search_cb, req);
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
    req = new_req(aTHX_ self, cb, 0);
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

    REQUIRE_LIVE(self);
    REQUIRE_CB(cb);

    ARES_CALL_BEGIN(self);
    if (inet_pton(AF_INET, ip, &addr4) == 1) {
        req = new_req(aTHX_ self, cb, 0);
        ares_gethostbyaddr(self->channel, &addr4, sizeof(addr4), AF_INET, host_cb, req);
    } else if (inet_pton(AF_INET6, ip, &addr6) == 1) {
        req = new_req(aTHX_ self, cb, 0);
        ares_gethostbyaddr(self->channel, &addr6, sizeof(addr6), AF_INET6, host_cb, req);
    } else {
        self->in_callback--;
        croak("EV::cares::reverse: invalid IP address: %s", ip);
    }
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

    REQUIRE_LIVE(self);
    REQUIRE_CB(cb);

    if (len < sizeof(sa_family_t))
        croak("EV::cares::getnameinfo: sockaddr too short (%d bytes)", (int)len);
    {
        sa_family_t family = ((struct sockaddr *)addr)->sa_family;
        STRLEN min_len = (family == AF_INET6)
            ? sizeof(struct sockaddr_in6) : sizeof(struct sockaddr_in);
        if (len < min_len)
            croak("EV::cares::getnameinfo: sockaddr too short for %s (%d bytes)",
                  family == AF_INET6 ? "AF_INET6" : "AF_INET", (int)len);
    }

    req = new_req(aTHX_ self, cb, 0);
    ARES_CALL_BEGIN(self);
    ares_getnameinfo(self->channel, (const struct sockaddr *)addr,
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
PREINIT:
    int i;
CODE:
{
    REQUIRE_LIVE(self);
    if (items > 1) {
        SV *csv = sv_2mortal(newSVpvs(""));
        int rc;
        for (i = 1; i < items; i++) {
            if (i > 1) sv_catpvs(csv, ",");
            sv_catsv(csv, ST(i));
        }
        rc = ares_set_servers_csv(self->channel, SvPV_nolen(csv));
        if (rc != ARES_SUCCESS)
            croak("EV::cares::set_servers: %s", ares_strerror(rc));
    }
}

void
servers(self)
    EV::cares self
PPCODE:
{
    char *csv;
    REQUIRE_LIVE(self);
    csv = ares_get_servers_csv(self->channel);
    if (csv) {
        mXPUSHp(csv, strlen(csv));
        ares_free_string(csv);
    }
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

void
destroy(self)
    EV::cares self
CODE:
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
    if (self->magic == EV_CARES_MAGIC) {
        if (PL_dirty) {
            /* global destruction: EV loop may already be freed,
               just release the channel without touching watchers */
            self->destroyed = 1;
            if (self->channel) {
                self->channel = NULL;
                /* skip ares_destroy — it triggers sock_state_cb which
                   would access the potentially freed EV loop */
            }
        } else {
            cleanup(self);
        }
    }
    self->magic = EV_CARES_FREED;
    if (self->in_callback) {
        self->free_pending = 1;  /* CB_EPILOGUE will Safefree */
    } else {
        Safefree(self);
    }

const char *
strerror(...)
CODE:
{
    int status;
    if (items < 1) croak("Usage: EV::cares::strerror(status)");
    /* handle both EV::cares->strerror(n) and EV::cares::strerror(n) */
    status = SvIV(ST(items > 1 ? 1 : 0));
    RETVAL = ares_strerror(status);
}
OUTPUT:
    RETVAL

const char *
lib_version(...)
CODE:
    RETVAL = ares_version(NULL);
OUTPUT:
    RETVAL
