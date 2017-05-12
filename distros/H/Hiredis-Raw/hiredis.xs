#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <errno.h>
#define NEED_sv_2pv_flags
#include "ppport.h"
#include <xs_object_magic.h>
#include "hiredis.h"
#include "async.h"

typedef struct redisPerlEvents {
    redisAsyncContext *context;

    SV *addRead;
    SV *delRead;
    SV *addWrite;
    SV *delWrite;
    SV *cleanup;
} redisPerlEvents;

typedef int redisErrorCode;

typedef struct {
    SV *callback;
    char **argv;
    size_t *arglen;

    unsigned int callback_ok:1;
    unsigned int argv_ok:1;
    unsigned int arglen_ok:1;
} callbackContext;

void redis_async_xs_unmagic (pTHX_ SV *self, redisAsyncContext *ac) {
    xs_object_magic_detach_struct(aTHX_ self, (void *) ac);
}

SV* redisReplyToSV(redisReply *reply){
    SV *result;
    AV *array;
    int i;
    struct redisReply **elements;

    if(reply){
        switch(reply->type){
            case REDIS_REPLY_STATUS:
            case REDIS_REPLY_STRING:
            case REDIS_REPLY_ERROR:
                result = newSVpvn(reply->str, reply->len);
                break;

            case REDIS_REPLY_INTEGER:
                result = newSViv(reply->integer);
                break;

            case REDIS_REPLY_ARRAY:
                array = newAV();
                for(i = 0; i < reply->elements; i++){
                    elements = reply->element;
                    result = redisReplyToSV(elements[i]);
                    av_push(array, result);
                    result = NULL;
                }
                result = newRV_noinc((SV *)array);

                break;

            default:
                result = &PL_sv_undef;
                break;
       }
    }
    else {
        result = &PL_sv_undef;
    }

    return result;
}

void redisPerlCallback(redisPerlEvents *e, SV* callback) {
    int fd = (int)e->context->c.fd;
    if (SvOK(callback)) {
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSViv(fd)));
        PUTBACK;
        call_sv(callback, G_DISCARD);
        FREETMPS;
        LEAVE;
    }
}

void redisPerlAddRead(void *privdata) {
    redisPerlEvents *e = (redisPerlEvents*)privdata;
    redisPerlCallback(e, e->addRead);
}

void redisPerlDelRead(void *privdata) {
    redisPerlEvents *e = (redisPerlEvents*)privdata;
    redisPerlCallback(e, e->delRead);
}

void redisPerlAddWrite(void *privdata) {
    redisPerlEvents *e = (redisPerlEvents*)privdata;
    redisPerlCallback(e, e->addWrite);
}

void redisPerlDelWrite(void *privdata) {
    redisPerlEvents *e = (redisPerlEvents*)privdata;
    redisPerlCallback(e, e->delWrite);
}

void redisPerlCleanup(void *privdata) {
    redisPerlEvents *e    = (redisPerlEvents*)privdata;
    redisAsyncContext *ac = e->context;
    void *self            = ac->data;

    redis_async_xs_unmagic(aTHX_ self, ac);
    Safefree(e);
}

void redisConnectHandleCallback(const struct redisAsyncContext *ac, int status) {
}

void redisDisconnectHandleCallback(const struct redisAsyncContext *ac, int status) {
}

void redisAsyncHandleCallback(redisAsyncContext *ac, void *_reply, void *_privdata){
    SV *result;
    callbackContext *c;
    redisReply *reply;
    SV *callback;

    if(_privdata == NULL) {
        croak("OH NOES!  Null privdata passed to redisAsyncHandleCallback!");
    }

    reply    = _reply;
    c        = _privdata;
    callback = c->callback;

    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    if (reply == NULL) {
        result = &PL_sv_undef;
        XPUSHs(&PL_sv_undef);
        if (ac->err) {
            XPUSHs(sv_2mortal(newSVpv(ac->errstr, 0)));
        }
        else {
            XPUSHs(sv_2mortal(newSVpv("Command failed: NULL reply", 0)));
        }
    }
    else {
        result = redisReplyToSV(reply);
        if(reply->type == REDIS_REPLY_ERROR){ /* is success? */
            XPUSHs(&PL_sv_undef);
            XPUSHs(result);
        }
        else {
            XPUSHs(result);
            XPUSHs(&PL_sv_undef);
        }
    }
    PUTBACK;

    call_sv(callback, G_DISCARD);

    FREETMPS;
    LEAVE;

    SvREFCNT_dec(result);

    /* Unless we're subscribed, cleanup the callback */
    if (!(ac->c.flags & REDIS_SUBSCRIBED)) {
        SvREFCNT_dec((SV*)c->callback);
        Safefree(c->argv);
        Safefree(c->arglen);
        Safefree(c);
    }
}

MODULE = Hiredis::Raw	PACKAGE = Hiredis::Raw   PREFIX = redis
PROTOTYPES: DISABLE

void
redisVersion()
    PPCODE:
        EXTEND(SP, 3);
        PUSHs(sv_2mortal(newSViv(HIREDIS_MAJOR)));
        PUSHs(sv_2mortal(newSViv(HIREDIS_MINOR)));
        PUSHs(sv_2mortal(newSViv(HIREDIS_PATCH)));

MODULE = Hiredis::Raw  PACKAGE = Hiredis::Async  PREFIX = redisAsync
PROTOTYPES: DISABLE

void
redisAsyncConnect(SV *self, const char *host="localhost", int port=6379, SV *addRead=NULL, SV *delRead=NULL, SV *addWrite=NULL, SV *delWrite=NULL)
    PREINIT:
        redisAsyncContext *ac;
        redisPerlEvents *e;
    CODE:
        ac = redisAsyncConnect(host, port);

        if (ac->err) {
            croak("Failed to create async connection: %s", ac->errstr);
        }

        /* Nothing should be attached when something is already attached */
        if (ac->ev.data != NULL) {
            croak("event callbacks are aready initialized");
        }

        Newx(e, 1, redisPerlEvents);
        if(e == NULL) {
            croak("cannot allocate memory for redisEvents structure");
        }

        e->context  = ac;
        e->addRead  = newSVsv(addRead);
        e->delRead  = newSVsv(delRead);
        e->addWrite = newSVsv(addWrite);
        e->delWrite = newSVsv(delWrite);

        /* Register functions to start/stop listening for events */
        ac->ev.addRead  = redisPerlAddRead;
        ac->ev.delRead  = redisPerlDelRead;
        ac->ev.addWrite = redisPerlAddWrite;
        ac->ev.delWrite = redisPerlDelWrite;
        ac->ev.cleanup  = redisPerlCleanup;
        ac->ev.data     = e;

        redisAsyncSetConnectCallback(ac, &redisConnectHandleCallback);
        redisAsyncSetDisconnectCallback(ac, &redisDisconnectHandleCallback);

        xs_object_magic_attach_struct(aTHX_ SvRV(self), ac);
        ac->data = SvRV(self);

void
redisAsyncFree(redisAsyncContext *ac)

void
redisAsyncIsAllocated(SV *self)
    PPCODE:
        void *ac = xs_object_magic_get_struct(aTHX_ SvRV(self));
        EXTEND(SP, 1);
        if (ac == NULL)
            PUSHs(&PL_sv_no);
        else
            PUSHs(&PL_sv_yes);

redisErrorCode
redisAsyncCommand(redisAsyncContext *ac, AV *args, SV *callback)
    PREINIT:
        int i;
        STRLEN len;
        char **argv;
        size_t *arglen;
        int argc;
        SV **elt;
        callbackContext *c;
    CODE:
        argc = av_len(args);
        if(argc < 0)
            croak("Must supply command to execute!");
        argc++; /* av_len returns last index, which is one less than the length */

        Newx(argv, argc, char *);
        if(!argv)
            croak("Out of memory while allocating argv!");

        Newx(arglen, argc, size_t);
        if(!arglen){
            Safefree(argv);
            croak("Out of memory while allocating arglen array!");
        }

        Newx(c, 1, callbackContext);
        if(!c){
            Safefree(argv);
            Safefree(arglen);
            croak("Out of memory while allocating callback context!");
        }

        for(i = 0; i < argc; i++){
            argv[i] = NULL;
            elt = av_fetch(args, i, 0);
            if(elt != NULL){
                argv[i] = SvPV(*elt, len);
                arglen[i] = len;
            }
        }

        c->callback = SvREFCNT_inc_simple(callback);
        c->argv     = argv;
        c->arglen   = arglen;
        c->callback_ok = c->argv_ok = c->arglen_ok = 1;

        RETVAL = redisAsyncCommandArgv(ac, &redisAsyncHandleCallback, c, argc, (const char **) argv, arglen);
    OUTPUT:
        RETVAL

void
redisAsyncHandleRead(redisAsyncContext *ac)

void
redisAsyncHandleWrite(redisAsyncContext *ac)

void
redisAsyncDisconnect(redisAsyncContext *ac)

void
redisAsyncGetFd(redisAsyncContext *ac)
    PPCODE:
        EXTEND(SP, 1);
        PUSHs(sv_2mortal(newSViv(ac->c.fd)));
