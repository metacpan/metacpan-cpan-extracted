#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#define MY_CXT_KEY "EV::YACurl::_guts" XS_VERSION

#include <curl/curl.h>
#include "libcurl-symbols.h"

/* curl_mime_* needs 7.56, CURLINFO_*_T 7.55, CURLOPT_TRAILERFUNCTION 7.64. */
#if LIBCURL_VERSION_NUM < 0x074000
# error "EV::YACurl needs libcurl 7.64.0 or newer"
#endif
#include "EVAPI.h"

typedef struct {
    HV *curlopt;
    int in_data_callback;
    HV *client_stash;
    HV *response_stash;
    int default_priority;
} my_cxt_t;

typedef struct EV__YACurl EV__YACurl;

/* ev_io must come first: libev hands the watcher back and we cast it. */
typedef struct yacurl_sock {
    ev_io io;
    EV__YACurl *client;
    curl_socket_t fd;
    int events;
    struct yacurl_sock *prev;
    struct yacurl_sock *next;
} yacurl_sock;

typedef struct {
    ev_timer timer;
    EV__YACurl *client;
} yacurl_timer;

struct EV__YACurl {
    CURLM *multi;
    struct ev_loop *loop;
    SV *weak_self_ref;

    yacurl_timer timer;
    yacurl_sock *socks;
    int priority;
    int priority_dirty;
    int in_callback;
    int in_loop;

    int needs_invoke_timeout;
    int needs_read_info;
    int last_running;
};

typedef struct {
    SV *self_rv;
    CURL *easy;
    curl_mime *mimepost;

    AV *held_references;
    FILE *redirected_stderr;
    int slists_count;
    int slists_alloc;
    struct curl_slist **slists;
    char errbuf[CURL_ERROR_SIZE];

    SV *callback;
} EV__YACurl__Response;

#define OPTION_SV_IS_NUMERIC(sv) (SvIOK(sv) || SvNOK(sv))

/* A user callback may drop the last reference to the client while we are still
 * working with it, so pin the referent for the duration. */
#define CLIENT_HOLD(c)    SvREFCNT_inc_simple_void_NN(SvRV((c)->weak_self_ref))
#define CLIENT_RELEASE(c) SvREFCNT_dec(SvRV((c)->weak_self_ref))

START_MY_CXT

static struct curl_slist *slist_from_av(pTHX_ struct curl_slist *list, AV *input);
static void update_running(EV__YACurl *client, int new_running);
static void do_post_work(pTHX_ EV__YACurl *client);
static void yacurl_io_cb(EV_P_ ev_io *w, int revents);
static void yacurl_timer_cb(EV_P_ ev_timer *w, int revents);
static void apply_priority(EV__YACurl *client);

/* The stash comparison settles the usual case without waking the mro cache. */
static int
sv_is_a(pTHX_ SV *sv, HV *stash, const char *class)
{
    SV *referent;

    if (!SvROK(sv))
        return 0;

    referent = SvRV(sv);
    if (!SvOBJECT(referent))
        return 0;

    return SvSTASH(referent) == stash || sv_derived_from(sv, class);
}

static void *
sv_to_ptr_or_croak(pTHX_ SV *sv, HV *stash, const char *class)
{
    IV address;

    if (!sv_is_a(aTHX_ sv, stash, class))
        croak("Expected a %s object", class);

    address = SvIV(SvRV(sv));
    if (!address)
        croak("%s object used after destruction", class);

    return INT2PTR(void *, address);
}

#define SV_TO_CLIENT(sv) \
    ((EV__YACurl *)sv_to_ptr_or_croak(aTHX_ (sv), MY_CXT.client_stash, "EV::YACurl"))
#define SV_TO_RESPONSE(sv) \
    ((EV__YACurl__Response *)sv_to_ptr_or_croak(aTHX_ (sv), MY_CXT.response_stash, \
                                                "EV::YACurl::Response"))

/* A $SIG{__WARN__} handler that dies must not unwind through libcurl's frames,
 * which would leave the multi handle wedged, so warnings go out under an eval. */
static void
safe_warn(pTHX_ SV *message)
{
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, 1);
    PUSHs(message);
    PUTBACK;

    call_pv("EV::YACurl::_warn", G_DISCARD | G_VOID | G_EVAL);

    FREETMPS;
    LEAVE;

    sv_setpvs(ERRSV, "");
}

static void
maybe_warn_eval(pTHX)
{
    SV *error = ERRSV;

    if (SvTRUE(error))
        safe_warn(aTHX_ sv_2mortal(newSVpvf("Error in callback: %s", SvPV_nolen(error))));
}

static void
sock_unlink(EV__YACurl *client, yacurl_sock *sock)
{
    if (sock->prev)
        sock->prev->next = sock->next;
    else
        client->socks = sock->next;

    if (sock->next)
        sock->next->prev = sock->prev;
}

static int
mcurl_socket_callback(CURL *easy, curl_socket_t s, int what, void *userp, void *socketp)
{
    EV__YACurl *client = (EV__YACurl *)userp;
    yacurl_sock *sock = (yacurl_sock *)socketp;
    int events;

    PERL_UNUSED_ARG(easy);

    if (what == CURL_POLL_REMOVE) {
        if (sock) {
            ev_io_stop(client->loop, &sock->io);
            sock_unlink(client, sock);
            curl_multi_assign(client->multi, s, NULL);
            Safefree(sock);
        }
        return 0;
    }

    /* CURL_POLL_NONE keeps the registration but asks for no readiness. */
    events = ((what & CURL_POLL_IN)  ? EV_READ  : 0)
           | ((what & CURL_POLL_OUT) ? EV_WRITE : 0);

    if (!sock) {
        Newxz(sock, 1, yacurl_sock);
        sock->client = client;
        sock->fd = s;

        ev_io_init(&sock->io, yacurl_io_cb, (int)s, events);
        ev_set_priority(&sock->io, client->priority);

        sock->next = client->socks;
        if (sock->next)
            sock->next->prev = sock;
        client->socks = sock;

        curl_multi_assign(client->multi, s, sock);

    } else if (sock->events == events) {
        return 0;
    }

    sock->events = events;
    ev_io_stop(client->loop, &sock->io);
    if (events) {
        ev_io_set(&sock->io, (int)s, events);
        ev_io_start(client->loop, &sock->io);
    }

    return 0;
}

static int
mcurl_timer_callback(CURLM *multi, long timeout_ms, void *userp)
{
    EV__YACurl *client = (EV__YACurl *)userp;

    PERL_UNUSED_ARG(multi);

    if (timeout_ms < 0) {
        ev_timer_stop(client->loop, &client->timer.timer);
        return 0;
    }

    if (timeout_ms == 0) {
        /* do_post_work() runs moments from now anyway, and libev would round a
         * zero second timer up to a whole loop iteration. */
        client->needs_invoke_timeout = 1;
        return 0;
    }

    /* Inside a watcher callback libev's cached time is the time this iteration
     * started, which is what every other timer is scheduled against too. */
    if (!client->in_loop)
        ev_now_update(client->loop);

    ev_timer_stop(client->loop, &client->timer.timer);
    ev_timer_set(&client->timer.timer, timeout_ms / 1000.0, 0.);
    ev_timer_start(client->loop, &client->timer.timer);

    return 0;
}

static void
yacurl_io_cb(EV_P_ ev_io *w, int revents)
{
    yacurl_sock *sock = (yacurl_sock *)w;
    EV__YACurl *client = sock->client;
    curl_socket_t fd = sock->fd;
    int mask = 0;
    int running = 0;
    dTHX;

#if EV_MULTIPLICITY
    PERL_UNUSED_ARG(loop);
#endif

    if (revents & EV_READ)  mask |= CURL_CSELECT_IN;
    if (revents & EV_WRITE) mask |= CURL_CSELECT_OUT;
    if (revents & EV_ERROR) mask |= CURL_CSELECT_ERR;

    CLIENT_HOLD(client);
    client->in_callback++;
    client->in_loop++;

    if (client->priority_dirty)
        apply_priority(client);

    /* One action call per readiness notification: curl takes both directions
     * as a bitmask, and the socket may be gone by the time the first returns. */
    if (curl_multi_socket_action(client->multi, fd, mask, &running) == CURLM_OK)
        update_running(client, running);
    do_post_work(aTHX_ client);

    client->in_loop--;
    client->in_callback--;
    CLIENT_RELEASE(client);
}

static void
yacurl_timer_cb(EV_P_ ev_timer *w, int revents)
{
    EV__YACurl *client = ((yacurl_timer *)w)->client;
    dTHX;

#if EV_MULTIPLICITY
    PERL_UNUSED_ARG(loop);
#endif
    PERL_UNUSED_ARG(revents);

    CLIENT_HOLD(client);
    client->in_callback++;
    client->in_loop++;

    if (client->priority_dirty)
        apply_priority(client);

    client->needs_invoke_timeout = 1;
    do_post_work(aTHX_ client);

    client->in_loop--;
    client->in_callback--;
    CLIENT_RELEASE(client);
}

static void
apply_priority(EV__YACurl *client)
{
    ev_timer *timer = &client->timer.timer;
    yacurl_sock *sock;
    int deferred = 0;

    /* libev forbids re-prioritising a watcher that is pending, and stopping one
     * would discard the event it is holding. Those are left for the callback
     * that is about to run them, which re-enters here with the flag below. */
    if (ev_is_pending(timer)) {
        deferred = 1;
    } else {
        int active = ev_is_active(timer);
        if (active)
            ev_timer_stop(client->loop, timer);
        ev_set_priority(timer, client->priority);
        if (active)
            ev_timer_start(client->loop, timer);
    }

    for (sock = client->socks; sock; sock = sock->next) {
        if (ev_is_pending(&sock->io)) {
            deferred = 1;
        } else if (ev_is_active(&sock->io)) {
            ev_io_stop(client->loop, &sock->io);
            ev_set_priority(&sock->io, client->priority);
            ev_io_start(client->loop, &sock->io);
        } else {
            ev_set_priority(&sock->io, client->priority);
        }
    }

    client->priority_dirty = deferred;
}

static int
clamp_priority(IV priority)
{
    if (priority < EV_MINPRI) return EV_MINPRI;
    if (priority > EV_MAXPRI) return EV_MAXPRI;
    return (int)priority;
}

/* Serves both WRITEFUNCTION and HEADERFUNCTION. */
static size_t mcurl_write_callback(char *ptr,
                           size_t size,
                           size_t nmemb,
                           void *userdata)
{
    dTHX;
    dMY_CXT;
    dSP;
    size_t len = size * nmemb;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, 1);
    PUSHs(sv_2mortal(newSVpvn(ptr, len)));
    PUTBACK;

    MY_CXT.in_data_callback++;
    call_sv((SV*)userdata, G_DISCARD | G_VOID | G_EVAL);

    maybe_warn_eval(aTHX);

    FREETMPS;
    LEAVE;
    MY_CXT.in_data_callback--;

    return len;
}

static size_t mcurl_read_callback(char *buffer,
                           size_t size,
                           size_t nitems,
                           void *userdata)
{
    size_t result;

    dTHX;
    dMY_CXT;
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, 1);
    PUSHs(sv_2mortal(newSViv(size * nitems)));
    PUTBACK;

    MY_CXT.in_data_callback++;
    call_sv((SV*)userdata, G_SCALAR | G_EVAL);

    SPAGAIN;

    /* Take the result off the stack before anything can run Perl again and
     * reallocate it underneath us. */
    {
        SV *data = POPs;
        STRLEN pvlen = 0;
        char *pv = SvOK(data) ? SvPV(data, pvlen) : NULL;

        if (!pv) {
            /* Also the croaked-callback case, which wants the same treatment. */
            result = CURL_READFUNC_ABORT;
        } else if (pvlen > size * nitems) {
            result = CURL_READFUNC_ABORT;
            safe_warn(aTHX_ sv_2mortal(newSVpvs(
                "Read callback returned more data than allowed; aborting stream\n")));
        } else {
            result = pvlen;
            Copy(pv, buffer, pvlen, char);
        }
    }

    maybe_warn_eval(aTHX);
    PUTBACK;

    FREETMPS;
    LEAVE;
    MY_CXT.in_data_callback--;

    return result;
}

static int mcurl_debug_callback(CURL *handle,
                         curl_infotype type,
                         char *data,
                         size_t size,
                         void *userdata)
{
    dTHX;
    dMY_CXT;
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, 2);
    PUSHs(sv_2mortal(newSViv(type)));
    PUSHs(sv_2mortal(newSVpvn(data, size)));
    PUTBACK;

    MY_CXT.in_data_callback++;
    call_sv((SV*)userdata, G_DISCARD | G_VOID | G_EVAL);

    maybe_warn_eval(aTHX);

    FREETMPS;
    LEAVE;
    MY_CXT.in_data_callback--;

    return 0;
}

static int mcurl_trailer_callback(struct curl_slist **output, void *userdata)
{
    dTHX;
    dMY_CXT;
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);

    MY_CXT.in_data_callback++;
    call_sv((SV*)userdata, G_EVAL | G_SCALAR);

    SPAGAIN;
    int return_result;
    SV *returned = POPs;
    if (SvTRUE(ERRSV)) {
        maybe_warn_eval(aTHX);
        return_result = CURL_TRAILERFUNC_ABORT;
    } else if (!SvTRUE(returned)) {
        return_result = CURL_TRAILERFUNC_ABORT;
    } else if (!SvROK(returned) || SvTYPE(SvRV(returned)) != SVt_PVAV) {
        return_result = CURL_TRAILERFUNC_ABORT;
        safe_warn(aTHX_ sv_2mortal(newSVpvf("Cannot convert %s to ARRAY reference\n",
                                            SvPV_nolen(returned))));
    } else {
        *output = slist_from_av(aTHX_ *output, (AV*)SvRV(returned));
        return_result = CURL_TRAILERFUNC_OK;
    }
    PUTBACK;

    FREETMPS;
    LEAVE;
    MY_CXT.in_data_callback--;

    return return_result;
}

static void
finish_request(pTHX_ CURL *easy, CURLcode code)
{
    EV__YACurl__Response *response;
    SV *self_rv, *callback;
    AV *held_references;

    curl_easy_getinfo(easy, CURLINFO_PRIVATE, (void *)&response);

    /* Detach everything the in-flight request owned before handing control to
     * Perl: the callback then cannot reach these through the response, so it
     * cannot free them out from under the code below. This also breaks the
     * reference cycle through the client now rather than at DESTROY time. */
    self_rv = response->self_rv;
    response->self_rv = NULL;
    callback = response->callback;
    response->callback = NULL;
    held_references = response->held_references;
    response->held_references = NULL;

    {
        dSP;
        ENTER;
        SAVETMPS;

        PUSHMARK(SP);
        EXTEND(SP, 2);

        if (code == CURLE_OK) {
            /* A copy, so that assigning to the callback's @_ cannot reach the
             * reference this function still owns. */
            PUSHs(sv_2mortal(newRV_inc(SvRV(self_rv))));
            PUSHs(sv_newmortal());
        } else {
            PUSHs(sv_newmortal());
            PUSHs(sv_2mortal(newSVpv(response->errbuf[0]
                                     ? response->errbuf
                                     : curl_easy_strerror(code), 0)));
        }

        PUTBACK;

        call_sv(callback, G_DISCARD | G_VOID | G_EVAL);

        maybe_warn_eval(aTHX);

        FREETMPS;
        LEAVE;
    }

    SvREFCNT_dec(held_references);
    SvREFCNT_dec(callback);
    SvREFCNT_dec(self_rv);
}

static void
update_running(EV__YACurl *client, int new_running)
{
    if (client->last_running == new_running)
        return;

    client->last_running = new_running;
    client->needs_read_info = 1;
}

static void
do_post_work(pTHX_ EV__YACurl *client)
{
    /* A completion callback can reach us straight out of request(), not only
     * from a watcher, so the in-callback guard has to be taken here too. */
    CLIENT_HOLD(client);
    client->in_callback++;

    while (client->needs_invoke_timeout || client->needs_read_info) {
        int msgq;
        CURLMsg *m;

        if (client->needs_invoke_timeout) {
            int running = 0;
            CURLMcode code;

            client->needs_invoke_timeout = 0;
            code = curl_multi_socket_action(client->multi, CURL_SOCKET_TIMEOUT, 0, &running);

            if (code == CURLM_RECURSIVE_API_CALL) {
                /* Nothing else will re-arm the one-shot timer, so put the
                 * kick back and let the outer do_post_work() retry it. */
                client->needs_invoke_timeout = 1;
                break;
            }
            if (code == CURLM_OK)
                update_running(client, running);
        }

        /* Cleared first so that a request started from a completion callback
         * is not lost. */
        client->needs_read_info = 0;

        while ((m = curl_multi_info_read(client->multi, &msgq))) {
            if (m->msg == CURLMSG_DONE) {
                /* The message only lives until the next curl_multi_* call. */
                CURL *easy = m->easy_handle;
                CURLcode result = m->data.result;

                curl_multi_remove_handle(client->multi, easy);
                finish_request(aTHX_ easy, result);
            }
        }
    }

    client->in_callback--;
    CLIENT_RELEASE(client);
}

#ifdef __GNUC__
# pragma GCC diagnostic push
# pragma GCC diagnostic ignored "-Wdeprecated-declarations"
#endif
static int fill_hv_with_constants(pTHX_ HV* the_hv)
{
#include "constants.inc"
#ifdef __GNUC__
# pragma GCC diagnostic pop
#endif
    return 0;
}

static struct curl_slist *slist_from_av(pTHX_ struct curl_slist *list, AV *input)
{
    SSize_t i, len = av_len(input);
    for (i = 0; i <= len; i++) {
        SV **entry = av_fetch(input, i, 0);
        /* An undef here would warn, and a warning raised from inside a libcurl
         * callback cannot be allowed to reach a __WARN__ handler that dies. */
        if (entry && SvOK(*entry))
            list = curl_slist_append(list, SvPV_nolen(*entry));
    }
    return list;
}

/* The constant table holds every CURL* name, and the numbers collide across
 * the namespaces (CURLOPT_PORT and CURLMOPT_PIPELINING are both 3), so a name
 * has to be checked against the namespace the caller is working in. */
static long option_from_sv_or_croak(pTHX_ pMY_CXT_ SV *option, U32 optionhash,
                                    int *opt_from_str, const char *want)
{
    if (SvIOK(option) || SvNOK(option)) {
        *opt_from_str = 0;
        return SvIV(option);

    } else if (SvPOK(option) && looks_like_number(option)) {
        *opt_from_str = 0;
        return SvIV(option);

    } else {
        HE *lookedup = hv_fetch_ent(MY_CXT.curlopt, option, 0, optionhash);
        const char *name = SvPV_nolen(option);

        if (!lookedup || !SvIOK(HeVAL(lookedup)))
            croak("Don't understand CURL option %s", name);

        if (strncmp(name, want, strlen(want)) != 0)
            croak("%s is not a %s* option", name, want);

        *opt_from_str = 1;
        return SvIV(HeVAL(lookedup));
    }
}

#ifdef __GNUC__
# pragma GCC diagnostic push
# pragma GCC diagnostic ignored "-Wdeprecated-declarations"
#endif
static CURLcode setopt_sv_or_croak(pTHX_ EV__YACurl__Response *request, CURLoption option, SV *parameter, SV *name)
{
    CURLcode result;

    switch (option) {
#include "curlopt-str.inc"
        {
            result = curl_easy_setopt(request->easy, option, SvPV_nolen(parameter));
            break;
        }

#include "curlopt-long.inc"
        {
            long param = SvIV(parameter);
            result = curl_easy_setopt(request->easy, option, param);
            break;
        }

#include "curlopt-off-t.inc"
        {
            /* An IV narrower than curl_off_t would clamp large values. */
            curl_off_t param = (sizeof(IV) < sizeof(curl_off_t) && SvNOK(parameter))
                             ? (curl_off_t)SvNV(parameter) : (curl_off_t)SvIV(parameter);
            result = curl_easy_setopt(request->easy, option, param);
            break;
        }

#include "curlopt-slist.inc"
        {
            if (!SvROK(parameter) || SvTYPE(SvRV(parameter)) != SVt_PVAV) {
                croak("%s: cannot convert to an ARRAY reference", SvPV_nolen(name));

            } else {
                struct curl_slist *list = slist_from_av(aTHX_ NULL, (AV*)SvRV(parameter));
                result = curl_easy_setopt(request->easy, option, list);

                if (request->slists_count >= request->slists_alloc) {
                    request->slists_alloc = request->slists_alloc ? request->slists_alloc * 2 : 4;
                    Renew(request->slists, request->slists_alloc, struct curl_slist*);
                }
                request->slists[request->slists_count++] = list;
            }
            break;
        }

#ifdef CURL_BLOB_COPY
#include "curlopt-blob.inc"
        {
            struct curl_blob blob;
            blob.data = SvPV(parameter, blob.len);
            blob.flags = CURL_BLOB_COPY;
            result = curl_easy_setopt(request->easy, option, &blob);
            break;
        }
#endif

        case CURLOPT_STDERR:
        {
            int fd = dup((int)SvIV(parameter));

            if (fd < 0)
                croak("Cannot set CURLOPT_STDERR: dup failed");

            if (request->redirected_stderr)
                fclose(request->redirected_stderr);

            request->redirected_stderr = fdopen(fd, "a");
            if (!request->redirected_stderr) {
                close(fd);
                croak("Cannot set CURLOPT_STDERR: fdopen failed");
            }

            result = curl_easy_setopt(request->easy, option, request->redirected_stderr);
            break;
        }

        case CURLOPT_WRITEFUNCTION:
        case CURLOPT_HEADERFUNCTION:
        case CURLOPT_READFUNCTION:
        case CURLOPT_DEBUGFUNCTION:
        case CURLOPT_TRAILERFUNCTION:
        {
            SV* fn_copy;

            if (!SvROK(parameter) || SvTYPE(SvRV(parameter)) != SVt_PVCV)
                croak("%s needs a code reference", SvPV_nolen(name));

            fn_copy = newSVsv(parameter);
            av_push(request->held_references, fn_copy);

            switch (option) {
                case CURLOPT_WRITEFUNCTION: {
                    result = curl_easy_setopt(request->easy, CURLOPT_WRITEFUNCTION, mcurl_write_callback);
                    result = curl_easy_setopt(request->easy, CURLOPT_WRITEDATA, fn_copy);
                    break;
                }
                case CURLOPT_HEADERFUNCTION: {
                    result = curl_easy_setopt(request->easy, CURLOPT_HEADERFUNCTION, mcurl_write_callback);
                    result = curl_easy_setopt(request->easy, CURLOPT_HEADERDATA, fn_copy);
                    break;
                }
                case CURLOPT_READFUNCTION: {
                    result = curl_easy_setopt(request->easy, CURLOPT_READFUNCTION, mcurl_read_callback);
                    result = curl_easy_setopt(request->easy, CURLOPT_READDATA, fn_copy);
                    break;
                }
                case CURLOPT_DEBUGFUNCTION: {
                    result = curl_easy_setopt(request->easy, CURLOPT_DEBUGFUNCTION, mcurl_debug_callback);
                    result = curl_easy_setopt(request->easy, CURLOPT_DEBUGDATA, fn_copy);
                    break;
                }
                case CURLOPT_TRAILERFUNCTION: {
                    result = curl_easy_setopt(request->easy, CURLOPT_TRAILERFUNCTION, mcurl_trailer_callback);
                    result = curl_easy_setopt(request->easy, CURLOPT_TRAILERDATA, fn_copy);
                    break;
                }
                default: { result = CURLE_OK; } /* unreachable */
            }
            break;
        }

        /* Copied by curl, and may contain zero bytes, so pass the length. */
        case CURLOPT_POSTFIELDS:
        {
            STRLEN pvlen;
            char *pv = SvPV(parameter, pvlen);

            result = curl_easy_setopt(request->easy, CURLOPT_POSTFIELDSIZE, pvlen);
            result = curl_easy_setopt(request->easy, CURLOPT_COPYPOSTFIELDS, pv);
            break;
        }

        case CURLOPT_MIMEPOST:
        {
            if (!SvROK(parameter) || SvTYPE(SvRV(parameter)) != SVt_PVAV) {
                croak("%s: cannot convert to an ARRAY reference", SvPV_nolen(name));
            }
            AV *param_av = (AV*)SvRV(parameter);

            curl_mimepart *part;
            if (request->mimepost) {
                curl_mime_free(request->mimepost);
            }
            request->mimepost = curl_mime_init(request->easy);
            if (!request->mimepost)
                croak("MIMEPOST: could not start a MIME body");

            int i;
            for (i = 0; i <= av_len(param_av); i++) {
                SV *entry = *av_fetch(param_av, i, TRUE);
                if (!SvROK(entry) || SvTYPE(SvRV(entry)) != SVt_PVHV) {
                    croak("Cannot convert %s to HASH reference", SvPV_nolen(entry));
                }

                HV *entry_hv = (HV*)SvRV(entry);
                part = curl_mime_addpart(request->mimepost);

                {
                    SV **name_sv = hv_fetchs(entry_hv, "name", FALSE);
                    if (!name_sv)
                        croak("MIMEPOST must be specified as an array of hashrefs "
                              "containing at least 'name', and one of 'value' or 'file'");

                    curl_mime_name(part, SvPV_nolen(*name_sv));
                }

                int have_value = 0;

                {
                    SV **value_sv = hv_fetchs(entry_hv, "value", FALSE);
                    if (value_sv && SvOK(*value_sv)) {
                        if (have_value)
                            croak("MIMEPOST: at most one of 'value' or 'file' may be provided");
                        have_value = 1;

                        STRLEN valuelen;
                        char *value = SvPV(*value_sv, valuelen);
                        curl_mime_data(part, value, valuelen);
                    }
                }

                {
                    SV **file_sv = hv_fetchs(entry_hv, "file", FALSE);
                    if (file_sv && SvOK(*file_sv)) {
                        if (have_value)
                            croak("MIMEPOST: at most one of 'value' or 'file' may be provided");
                        have_value = 1;

                        STRLEN filelen;
                        char *filename = SvPV(*file_sv, filelen);
                        if (curl_mime_filedata(part, filename) != CURLE_OK)
                            croak("MIMEPOST: cannot read %s", filename);
                    }
                }

                if (!have_value) {
                    croak("MIMEPOST: one of 'value' or 'file' is required, together with 'name'");
                }
            }

            result = curl_easy_setopt(request->easy, CURLOPT_MIMEPOST, request->mimepost);

            break;
        }

        default:
        {
            croak("Not sure what to do with CURL option %s", SvPV_nolen(name));
            break;
        }
    }

    return result;
}
#ifdef __GNUC__
# pragma GCC diagnostic pop
#endif

#ifdef __GNUC__
# pragma GCC diagnostic push
# pragma GCC diagnostic ignored "-Wdeprecated-declarations"
#endif
static void
apply_multi_options(pTHX_ pMY_CXT_ EV__YACurl *client, HV *args)
{
    HE *iterentry;

    hv_iterinit(args);
    while ((iterentry = hv_iternext(args)) != NULL) {
        long opt;
        SV *key = HeSVKEY_force(iterentry);

        if (OPTION_SV_IS_NUMERIC(key)) {
            opt = SvIV(key);
        } else {
            int opt_from_str;
            opt = option_from_sv_or_croak(aTHX_ aMY_CXT_ key, HeHASH(iterentry),
                                          &opt_from_str, "CURLMOPT_");
        }

#ifdef __GNUC__
# pragma GCC diagnostic push
# pragma GCC diagnostic ignored "-Wdeprecated-declarations"
#endif
        switch (opt) {
            /* multi.h types these two as off_t, and varargs will not widen a
             * long for us where the two differ. */
            case CURLMOPT_CHUNK_LENGTH_PENALTY_SIZE:
            case CURLMOPT_CONTENT_LENGTH_PENALTY_SIZE:
            {
                curl_off_t value = (curl_off_t)SvIV(HeVAL(iterentry));
                CURLMcode mcode = curl_multi_setopt(client->multi, opt, value);

                if (mcode != CURLM_OK)
                    croak("Failed to set %s: %s", SvPV_nolen(key), curl_multi_strerror(mcode));
                break;
            }

            case CURLMOPT_MAX_HOST_CONNECTIONS:
            case CURLMOPT_MAX_PIPELINE_LENGTH:
            case CURLMOPT_MAX_TOTAL_CONNECTIONS:
            case CURLMOPT_MAXCONNECTS:
            case CURLMOPT_PIPELINING:
#ifdef CURLMOPT_MAX_CONCURRENT_STREAMS
            case CURLMOPT_MAX_CONCURRENT_STREAMS:
#endif
            {
                long value = SvIV(HeVAL(iterentry));
                CURLMcode mcode = curl_multi_setopt(client->multi, opt, value);
                if (mcode != CURLM_OK)
                    croak("Failed to set %s: %s", SvPV_nolen(key), curl_multi_strerror(mcode));
                break;
            }

            case CURLMOPT_PIPELINING_SITE_BL:
            case CURLMOPT_PIPELINING_SERVER_BL:
            {
                char **strings;
                AV *array;
                int arraylen, i;
                CURLMcode mcode;

                if (!SvROK(HeVAL(iterentry)) || SvTYPE(SvRV(HeVAL(iterentry))) != SVt_PVAV)
                    croak("%s: cannot convert value to ARRAY reference", SvPV_nolen(key));

                array = (AV *)SvRV(HeVAL(iterentry));
                arraylen = av_len(array) + 1;

                Newxz(strings, arraylen + 1, char *);

                for (i = 0; i < arraylen; i++) {
                    SV **entry = av_fetch(array, i, FALSE);
                    char *strcopy, *pv;
                    STRLEN pvlen;

                    if (!entry || !SvOK(*entry))
                        continue;

                    pv = SvPV(*entry, pvlen);
                    Newxz(strcopy, pvlen + 1, char);
                    Copy(pv, strcopy, pvlen, char);
                    strings[i] = strcopy;
                }

                mcode = curl_multi_setopt(client->multi, opt, strings);

                for (i = 0; i < arraylen; i++)
                    Safefree(strings[i]);
                Safefree(strings);

                if (mcode != CURLM_OK)
                    croak("Failed to set %s: %s", SvPV_nolen(key), curl_multi_strerror(mcode));
                break;
            }

            default:
                croak("Not sure what to do with CURL multi option %s", SvPV_nolen(key));
        }
#ifdef __GNUC__
# pragma GCC diagnostic pop
#endif
    }
}
#ifdef __GNUC__
# pragma GCC diagnostic pop
#endif

MODULE = EV::YACurl       PACKAGE = EV::YACurl

PROTOTYPES: DISABLE

BOOT:
{
    MY_CXT_INIT;
    MY_CXT.curlopt = newHV();
    MY_CXT.default_priority = 0;
    MY_CXT.in_data_callback = 0;
    MY_CXT.client_stash = gv_stashpv("EV::YACurl", GV_ADD);
    MY_CXT.response_stash = gv_stashpv("EV::YACurl::Response", GV_ADD);
    fill_hv_with_constants(aTHX_ MY_CXT.curlopt);

    I_EV_API("EV::YACurl");

    curl_global_init(CURL_GLOBAL_ALL);
}

void
CLONE(...)
    CODE:
        MY_CXT_CLONE;
        MY_CXT.curlopt = newHV();
        MY_CXT.in_data_callback = 0;
        MY_CXT.client_stash = gv_stashpv("EV::YACurl", GV_ADD);
        MY_CXT.response_stash = gv_stashpv("EV::YACurl::Response", GV_ADD);
        fill_hv_with_constants(aTHX_ MY_CXT.curlopt);

void
new(class, args)
        SV *class
        HV *args
    PPCODE:
        dMY_CXT;

        EV__YACurl *client;
        struct ev_loop *loop = EV_DEFAULT;

        if (!loop)
            croak("EV has no default loop");

        Newxz(client, 1, EV__YACurl);

        ST(0) = sv_newmortal();
        sv_setref_pv(ST(0), SvPV_nolen(class), (void *)client);

        client->loop = loop;
        client->priority = MY_CXT.default_priority;
        client->timer.client = client;
        ev_timer_init(&client->timer.timer, yacurl_timer_cb, 0., 0.);
        ev_set_priority(&client->timer.timer, client->priority);

        /* Weak, so the client is not kept alive by its own curl callbacks. */
        client->weak_self_ref = newSVsv(ST(0));
        sv_rvweaken(client->weak_self_ref);

        client->multi = curl_multi_init();
        if (!client->multi)
            croak("Failed to instantiate CURLM object");

        curl_multi_setopt(client->multi, CURLMOPT_SOCKETFUNCTION, mcurl_socket_callback);
        curl_multi_setopt(client->multi, CURLMOPT_TIMERFUNCTION, mcurl_timer_callback);
        curl_multi_setopt(client->multi, CURLMOPT_SOCKETDATA, (void *)client);
        curl_multi_setopt(client->multi, CURLMOPT_TIMERDATA, (void *)client);

        apply_multi_options(aTHX_ aMY_CXT_ client, args);

        XSRETURN(1);

void
request(self, callback, options)
        SV *self
        SV *callback
        HV *options
    CODE:
        dMY_CXT;

        EV__YACurl *client;
        EV__YACurl__Response *response_ctx;

        if (MY_CXT.in_data_callback)
            croak("request() cannot be called from a data callback; "
                  "start follow-up requests from the completion callback");

        client = SV_TO_CLIENT(self);
        CURL *easy;
        CURLMcode error;
        HE *iterentry;

        if (!SvROK(callback) || SvTYPE(SvRV(callback)) != SVt_PVCV)
            croak("request() needs a code reference as its callback");

        /* Mortal until curl_multi_add_handle() succeeds, so an intervening
         * croak() still frees everything allocated so far. */
        Newxz(response_ctx, 1, EV__YACurl__Response);
        response_ctx->self_rv = sv_newmortal();
        sv_setref_pv(response_ctx->self_rv, "EV::YACurl::Response", (void *)response_ctx);

        easy = curl_easy_init();
        if (!easy)
            croak("Failed to instantiate CURL object");
        response_ctx->easy = easy;

        if (curl_easy_setopt(easy, CURLOPT_PRIVATE, response_ctx) != CURLE_OK)
            croak("Failed to setup CURL object");
        curl_easy_setopt(easy, CURLOPT_ERRORBUFFER, response_ctx->errbuf);

        response_ctx->held_references = newAV();
        response_ctx->callback = newSVsv(callback);

        /* Pins the client for as long as the request lives. */
        av_push(response_ctx->held_references, newSVsv(self));

        hv_iterinit(options);
        while ((iterentry = hv_iternext(options)) != NULL) {
            long opt;
            CURLcode ccode;
            SV *key = HeSVKEY_force(iterentry);

            if (OPTION_SV_IS_NUMERIC(key)) {
                opt = SvIV(key);
            } else {
                int opt_from_str;
                opt = option_from_sv_or_croak(aTHX_ aMY_CXT_ key, HeHASH(iterentry),
                                              &opt_from_str, "CURLOPT_");
            }

            ccode = setopt_sv_or_croak(aTHX_ response_ctx, opt, HeVAL(iterentry), key);
            if (ccode != CURLE_OK)
                croak("Failed to set %s: %s", SvPV_nolen(key), curl_easy_strerror(ccode));
        }

        error = curl_multi_add_handle(client->multi, easy);
        if (error != CURLM_OK)
            croak("Failed to perform CURL request: %s", curl_multi_strerror(error));

        SvREFCNT_inc(response_ctx->self_rv);

        client->needs_invoke_timeout = 1;
        do_post_work(aTHX_ client);

void
priority(self, ...)
        SV *self
    PPCODE:
        dMY_CXT;

        EV__YACurl *client = SV_TO_CLIENT(self);
        IV old = client->priority;

        if (items > 1) {
            int wanted = clamp_priority(SvIV(ST(1)));
            if (wanted != client->priority) {
                client->priority = wanted;
                apply_priority(client);
            }
        }

        ST(0) = sv_2mortal(newSViv(old));
        XSRETURN(1);

void
default_priority(class, ...)
        SV *class
    PPCODE:
        dMY_CXT;
        IV old = MY_CXT.default_priority;

        PERL_UNUSED_ARG(class);

        if (items > 1)
            MY_CXT.default_priority = clamp_priority(SvIV(ST(1)));

        ST(0) = sv_2mortal(newSViv(old));
        XSRETURN(1);

HV*
_get_known_constants()
    CODE:
        RETVAL = newHV();
        sv_2mortal((SV *)RETVAL);
        fill_hv_with_constants(aTHX_ RETVAL);
    OUTPUT:
        RETVAL

void
DESTROY(self)
        SV *self
    CODE:
        dMY_CXT;

        if (sv_is_a(aTHX_ self, MY_CXT.client_stash, "EV::YACurl")) {
            EV__YACurl *client = INT2PTR(EV__YACurl *, SvIV(SvRV(self)));

            /* An explicit DESTROY from inside a callback would free the struct
             * that the code still unwinding above it is using. Refusing leaks
             * the client, which beats returning into freed memory. */
            if (client && client->in_callback) {
                warn("Ignoring DESTROY of a client that is still in a callback\n");
                client = NULL;
            }

            if (client) {
                int abandoned = client->last_running;

                sv_setiv(SvRV(self), 0);

                if (client->multi) {
                    /* curl_multi_cleanup() must not reach callbacks that would
                     * touch the structures we are about to free. */
                    curl_multi_setopt(client->multi, CURLMOPT_SOCKETFUNCTION, NULL);
                    curl_multi_setopt(client->multi, CURLMOPT_TIMERFUNCTION, NULL);
                }

                ev_timer_stop(client->loop, &client->timer.timer);
                while (client->socks) {
                    yacurl_sock *next = client->socks->next;
                    ev_io_stop(client->loop, &client->socks->io);
                    Safefree(client->socks);
                    client->socks = next;
                }

                if (client->multi)
                    curl_multi_cleanup(client->multi);
                if (client->weak_self_ref)
                    SvREFCNT_dec(client->weak_self_ref);

                Safefree(client);

                /* After teardown: a warn handler that dies must not leave it half done. */
                if (abandoned)
                    warn("Destroying with %d request%s active", abandoned,
                         abandoned == 1 ? "" : "s");
            }
        }

MODULE = EV::YACurl       PACKAGE = EV::YACurl::Response


SV*
getinfo(self, option)
        SV *self
        SV *option
    CODE:
        dMY_CXT;

        EV__YACurl__Response *response = SV_TO_RESPONSE(self);
        int opt_from_str;
        CURLINFO opt = option_from_sv_or_croak(aTHX_ aMY_CXT_ option, 0,
                                                &opt_from_str, "CURLINFO_");
        CURLcode ccode;

        if (opt == CURLINFO_PRIVATE) {
            croak("Refusing access to private CURL data");

        } else if ((opt & CURLINFO_TYPEMASK) == CURLINFO_STRING) {
            char *result;
            ccode = curl_easy_getinfo(response->easy, opt, &result);
            if (ccode != CURLE_OK)
                croak("%s", curl_easy_strerror(ccode));
            RETVAL = result ? newSVpv(result, 0) : newSV(0);

        } else if ((opt & CURLINFO_TYPEMASK) == CURLINFO_LONG) {
            long result;
            ccode = curl_easy_getinfo(response->easy, opt, &result);
            if (ccode != CURLE_OK)
                croak("%s", curl_easy_strerror(ccode));
            RETVAL = newSViv(result);

        } else if ((opt & CURLINFO_TYPEMASK) == CURLINFO_OFF_T) {
            curl_off_t result;
            ccode = curl_easy_getinfo(response->easy, opt, &result);
            if (ccode != CURLE_OK)
                croak("%s", curl_easy_strerror(ccode));
            RETVAL = (result >= IV_MIN && result <= IV_MAX)
                   ? newSViv((IV)result) : newSVnv((NV)result);

        /* CURLINFO_PTR shares CURLINFO_SLIST's typemask bit, so dispatching on
         * the type would hand curl's own memory to curl_slist_free_all(). */
        } else if (opt == CURLINFO_SSL_ENGINES || opt == CURLINFO_COOKIELIST) {
            struct curl_slist *result = NULL, *item;
            AV *lines = newAV();

            ccode = curl_easy_getinfo(response->easy, opt, &result);
            if (ccode != CURLE_OK) {
                SvREFCNT_dec((SV *)lines);
                croak("%s", curl_easy_strerror(ccode));
            }

            for (item = result; item; item = item->next)
                av_push(lines, newSVpv(item->data, 0));

            curl_slist_free_all(result);
            RETVAL = newRV_noinc((SV *)lines);

        } else if ((opt & CURLINFO_TYPEMASK) == CURLINFO_DOUBLE) {
            double result;
            ccode = curl_easy_getinfo(response->easy, opt, &result);
            if (ccode != CURLE_OK)
                croak("%s", curl_easy_strerror(ccode));
            RETVAL = newSVnv(result);

        } else if (opt_from_str) {
            croak("Don't know what to do with curl's %d (%s)", (int)opt, SvPV_nolen(option));
        } else {
            croak("Don't know what to do with curl's %d", (int)opt);
        }
    OUTPUT:
        RETVAL

void
DESTROY(self)
        SV *self
    CODE:
        dMY_CXT;

        if (sv_is_a(aTHX_ self, MY_CXT.response_stash, "EV::YACurl::Response")) {
            EV__YACurl__Response *response =
                INT2PTR(EV__YACurl__Response *, SvIV(SvRV(self)));

            if (response) {
                sv_setiv(SvRV(self), 0);

                if (response->easy)
                    curl_easy_cleanup(response->easy);
                if (response->mimepost)
                    curl_mime_free(response->mimepost);
                if (response->held_references)
                    SvREFCNT_dec(response->held_references);
                if (response->callback)
                    SvREFCNT_dec(response->callback);
                if (response->redirected_stderr)
                    fclose(response->redirected_stderr);

                if (response->slists) {
                    int i;
                    for (i = 0; i < response->slists_count; i++)
                        curl_slist_free_all(response->slists[i]);
                    Safefree(response->slists);
                }

                Safefree(response);
            }
        }
