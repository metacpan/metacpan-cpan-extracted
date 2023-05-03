#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "EVAPI.h"

#include "hiredis.h"
#include "async.h"
#include "libev_adapter.h"
#include "ngx-queue.h"

typedef struct ev_hiredis_s ev_hiredis_t;
typedef struct ev_hiredis_cb_s ev_hiredis_cb_t;

typedef ev_hiredis_t* EV__Hiredis;
typedef struct ev_loop* EV__Loop;

struct ev_hiredis_s {
    struct ev_loop* loop;
    redisAsyncContext* ac;
    SV* error_handler;
    SV* connect_handler;
    struct timeval* connect_timeout;
    struct timeval* command_timeout;
    ngx_queue_t cb_queue; /* for long term callbacks such as subscribe */
};

struct ev_hiredis_cb_s {
    SV* cb;
    ngx_queue_t queue;
    int persist;
};

static void emit_error(EV__Hiredis self, SV* error) {
    if (NULL == self->error_handler) return;

    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(error);
    PUTBACK;

    call_sv(self->error_handler, G_DISCARD);

    FREETMPS;
    LEAVE;
}

static void emit_error_str(EV__Hiredis self, char* error) {
    if (NULL == self->error_handler) return;
    emit_error(self, sv_2mortal(newSVpv(error, 0)));
}

static void remove_cb_queue(EV__Hiredis self) {
    ngx_queue_t* q;
    ev_hiredis_cb_t* cbt;

    while (!ngx_queue_empty(&self->cb_queue)) {
        q   = ngx_queue_last(&self->cb_queue);
        cbt = ngx_queue_data(q, ev_hiredis_cb_t, queue);
        ngx_queue_remove(q);

        SvREFCNT_dec(cbt->cb);
        Safefree(cbt);
    }
}

static void EV__hiredis_connect_cb(redisAsyncContext* c, int status) {
    EV__Hiredis self = (EV__Hiredis)c->data;

    if (REDIS_OK != status) {
        self->ac = NULL;
        emit_error_str(self, c->errstr);
    }
    else {
        if (NULL == self->connect_handler) return;

        dSP;

        ENTER;
        SAVETMPS;

        PUSHMARK(SP);
        PUTBACK;

        call_sv(self->connect_handler, G_DISCARD);

        FREETMPS;
        LEAVE;
    }
}

static void EV__hiredis_disconnect_cb(redisAsyncContext* c, int status) {
    EV__Hiredis self = (EV__Hiredis)c->data;
    SV* sv_error;

    if (REDIS_OK == status) {
        self->ac = NULL;
    }
    else {
        sv_error = sv_2mortal(newSVpv(c->errstr, 0));
        self->ac = NULL;
        emit_error(self, sv_error);
    }

    remove_cb_queue(self);
}

static void pre_connect_common(EV__Hiredis self, redisOptions* opts) {
    if (NULL != self->connect_timeout) {
        opts->connect_timeout = self->connect_timeout;
    }
    if (NULL != self->command_timeout) {
        opts->command_timeout = self->command_timeout;
    }
}

static void connect_common(EV__Hiredis self) {
    int r;
    SV* sv_error = NULL;

    self->ac->data = (void*)self;

    r = redisLibevAttach(self->loop, self->ac);
    if (REDIS_OK != r) {
        redisAsyncFree(self->ac);
        self->ac = NULL;
        emit_error_str(self, "connect error: cannot attach libev");
        return;
    }

    redisAsyncSetConnectCallback(self->ac, (redisConnectCallback*)EV__hiredis_connect_cb);
    redisAsyncSetDisconnectCallback(self->ac, (redisDisconnectCallback*)EV__hiredis_disconnect_cb);

    if (self->ac->err) {
        sv_error = sv_2mortal(newSVpvf("connect error: %s", self->ac->errstr));
        redisAsyncFree(self->ac);
        self->ac = NULL;
        emit_error(self, sv_error);
        return;
    }
}

static SV* EV__hiredis_decode_reply(redisReply* reply) {
    SV* res = NULL;

    switch (reply->type) {
        case REDIS_REPLY_STRING:
        case REDIS_REPLY_ERROR:
        case REDIS_REPLY_STATUS:
            res = newSVpvn(reply->str, reply->len);
            break;

        case REDIS_REPLY_INTEGER:
            res = newSViv(reply->integer);
            break;
        case REDIS_REPLY_NIL:
            res = newSV(0);
            break;

        case REDIS_REPLY_ARRAY: {
            AV* av = newAV();
            av_extend(av, (SSize_t)reply->elements);
            size_t i;
            for (i = 0; i < reply->elements; i++) {
                av_push(av, EV__hiredis_decode_reply(reply->element[i]));
            }
            res = newRV_noinc((SV*)av);
            break;
        }
    }

    return res;
}

static void EV__hiredis_reply_cb(redisAsyncContext* c, void* reply, void* privdata) {
    ev_hiredis_cb_t* cbt;
    SV* sv_reply;
    SV* sv_err;

    PERL_UNUSED_VAR(c);

    cbt      = (ev_hiredis_cb_t*)privdata;

    if (NULL == reply) {
        fprintf(stderr, "here error: %s\n", c->errstr);

        dSP;

        ENTER;
        SAVETMPS;

        sv_err = sv_2mortal(newSVpv(c->errstr, 0));

        PUSHMARK(SP);
        PUSHs(&PL_sv_undef);
        PUSHs(sv_err);
        PUTBACK;

        call_sv(cbt->cb, G_DISCARD);

        FREETMPS;
        LEAVE;
    }
    else {
        dSP;

        ENTER;
        SAVETMPS;

        PUSHMARK(SP);
        sv_reply = sv_2mortal(EV__hiredis_decode_reply((redisReply*)reply));
        if (((redisReply*)reply)->type == REDIS_REPLY_ERROR) {
            PUSHs(&PL_sv_undef);
            PUSHs(sv_reply);
        }
        else {
            PUSHs(sv_reply);
        }
        PUTBACK;

        call_sv(cbt->cb, G_DISCARD);

        FREETMPS;
        LEAVE;
    }

    if (0 == cbt->persist) {
        SvREFCNT_dec(cbt->cb);
        ngx_queue_remove(&cbt->queue);
        Safefree(cbt);
    }
}

MODULE = EV::Hiredis PACKAGE = EV::Hiredis

BOOT:
{
    I_EV_API("EV::Hiredis");
}

EV::Hiredis
_new(char* class, EV::Loop loop);
CODE:
{
    PERL_UNUSED_VAR(class);
    Newxz(RETVAL, 1, ev_hiredis_t);
    ngx_queue_init(&RETVAL->cb_queue);
    RETVAL->loop = loop;
}
OUTPUT:
    RETVAL

void
DESTROY(EV::Hiredis self);
CODE:
{
    self->loop = NULL;
    if (NULL != self->ac) {
        redisAsyncFree(self->ac);
        self->ac = NULL;
    }
    if (NULL != self->error_handler) {
        SvREFCNT_dec(self->error_handler);
        self->error_handler = NULL;
    }
    if (NULL != self->connect_handler) {
        SvREFCNT_dec(self->connect_handler);
        self->connect_handler = NULL;
    }
    if (NULL != self->connect_timeout) {
        Safefree(self->connect_timeout);
        self->connect_timeout = NULL;
    }
    if (NULL != self->command_timeout) {
        Safefree(self->command_timeout);
        self->command_timeout = NULL;
    }

    remove_cb_queue(self);

    Safefree(self);
}

void
connect(EV::Hiredis self, char* hostname, int port = 6379);
CODE:
{
    if (NULL != self->ac) {
        croak("already connected");
        return;
    }

    redisOptions opts = {0};
    pre_connect_common(self, &opts);
    REDIS_OPTIONS_SET_TCP(&opts, hostname, port);
    self->ac = redisAsyncConnectWithOptions(&opts);
    if (NULL == self->ac) {
        croak("cannot allocate memory");
        return;
    }

    connect_common(self);
}

void
connect_unix(EV::Hiredis self, const char* path);
CODE:
{
    if (NULL != self->ac) {
        croak("already connected");
        return;
    }

    redisOptions opts = {0};
    pre_connect_common(self, &opts);
    REDIS_OPTIONS_SET_UNIX(&opts, path);
    self->ac = redisAsyncConnectWithOptions(&opts);
    if (NULL == self->ac) {
        croak("cannot allocate memory");
        return;
    }

    connect_common(self);
}

void
disconnect(EV::Hiredis self);
CODE:
{
    if (NULL == self->ac) {
        emit_error_str(self, "not connected");
        return;
    }

    redisAsyncDisconnect(self->ac);
}

void
connect_timeout(EV::Hiredis self, int timeout_ms);
CODE:
{
    if (NULL == self->connect_timeout) {
        Newx(self->connect_timeout, 1, struct timeval);
    }
    self->connect_timeout->tv_sec = timeout_ms / 1000;
    self->connect_timeout->tv_usec = (timeout_ms % 1000) * 1000;
}

void
command_timeout(EV::Hiredis self, int timeout_ms);
CODE:
{
    if (NULL == self->command_timeout) {
        Newx(self->command_timeout, 1, struct timeval);
    }
    self->command_timeout->tv_sec = timeout_ms / 1000;
    self->command_timeout->tv_usec = (timeout_ms % 1000) * 1000;
}

CV*
on_error(EV::Hiredis self, CV* handler = NULL);
CODE:
{
    if (NULL != self->error_handler) {
        SvREFCNT_dec(self->error_handler);
        self->error_handler = NULL;
    }

    if (NULL != handler) {
        self->error_handler = SvREFCNT_inc(handler);
    }

    RETVAL = (CV*)self->error_handler;
}
OUTPUT:
    RETVAL

void
on_connect(EV::Hiredis self, CV* handler = NULL);
CODE:
{
    if (NULL != handler) {
        if (NULL != self->connect_handler) {
            SvREFCNT_dec(self->connect_handler);
            self->connect_handler = NULL;
        }

        self->connect_handler = SvREFCNT_inc(handler);
    }

    if (self->connect_handler) {
        ST(0) = self->connect_handler;
        XSRETURN(1);
    }
    else {
        XSRETURN(0);
    }
}

int
command(EV::Hiredis self, ...);
PREINIT:
    SV* cb;
    char** argv;
    size_t* argvlen;
    STRLEN len;
    int argc, i;
    ev_hiredis_cb_t* cbt;
CODE:
{
    if (items <= 2) {
        croak("Usage: command(\"command\", ..., $callback)");
    }

    cb = ST(items - 1);
    if (!(SvROK(cb) && SvTYPE(SvRV(cb)) == SVt_PVCV)) {
        croak("last arguments should be CODE reference");
    }

    if (NULL == self->ac) {
        croak("connect required before call command");
    }

    argc = items - 2;
    Newx(argv, argc, char*);
    Newx(argvlen, argc, size_t);

    for (i = 0; i < argc; i++) {
        argv[i] = SvPV(ST(i + 1), len);
        argvlen[i] = len;
    }

    Newx(cbt, 1, ev_hiredis_cb_t);
    cbt->cb = SvREFCNT_inc(cb);
    ngx_queue_init(&cbt->queue);
    ngx_queue_insert_tail(&self->cb_queue, &cbt->queue);

    if (0 == strcasecmp(argv[0], "subscribe")
        || 0 == strcasecmp(argv[0], "psubscribe")
        || 0 == strcasecmp(argv[0], "monitor")
    ) {
        cbt->persist = 1;
    }
    else {
        cbt->persist = 0;
    }

    RETVAL = redisAsyncCommandArgv(
        self->ac, EV__hiredis_reply_cb, (void*)cbt,
        argc, (const char**)argv, argvlen
    );

    Safefree(argv);
    Safefree(argvlen);
}
OUTPUT:
    RETVAL
