#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <nghttp2/nghttp2.h>
#include <string.h>

struct perl_nghttp2_session_s;

typedef struct perl_data_source_s {
    char *buf;
    size_t len;
    size_t pos;
    struct perl_nghttp2_session_s *owner;
    struct perl_data_source_s *prev;
    struct perl_data_source_s *next;
} perl_data_source_t;

typedef struct perl_nghttp2_session_s {
    nghttp2_session *session;
    SV *on_headers_cb;
    SV *on_data_cb;
    SV *on_trailers_cb;
    SV *on_stream_close_cb;
    SV *callback_err;
    perl_data_source_t *active_sources;
    int in_callback;
    int pending_destroy;
} perl_nghttp2_session_t;

static void link_data_source(perl_nghttp2_session_t *sess, perl_data_source_t *src) {
    src->owner = sess;
    src->prev = NULL;
    src->next = sess->active_sources;
    if (sess->active_sources) {
        sess->active_sources->prev = src;
    }
    sess->active_sources = src;
}

static void free_data_source(perl_data_source_t *src) {
    if (!src) return;
    perl_nghttp2_session_t *sess = src->owner;
    if (sess) {
        if (src->prev) {
            src->prev->next = src->next;
        } else if (sess->active_sources == src) {
            sess->active_sources = src->next;
        }
        if (src->next) {
            src->next->prev = src->prev;
        }
        src->owner = NULL;
    }
    if (src->buf) {
        Safefree(src->buf);
        src->buf = NULL;
    }
    Safefree(src);
}

static void free_session_struct(pTHX_ perl_nghttp2_session_t *sess) {
    if (!sess) return;
    if (sess->session) {
        nghttp2_session_del(sess->session);
        sess->session = NULL;
    }
    while (sess->active_sources) {
        free_data_source(sess->active_sources);
    }
    if (sess->on_headers_cb) SvREFCNT_dec(sess->on_headers_cb);
    if (sess->on_data_cb) SvREFCNT_dec(sess->on_data_cb);
    if (sess->on_trailers_cb) SvREFCNT_dec(sess->on_trailers_cb);
    if (sess->on_stream_close_cb) SvREFCNT_dec(sess->on_stream_close_cb);
    if (sess->callback_err) SvREFCNT_dec(sess->callback_err);
    Safefree(sess);
}

static perl_nghttp2_session_t *get_raw_session_ptr(pTHX_ SV *sv) {
    if (!sv || !sv_isobject(sv) || !sv_derived_from(sv, "Google::gRPC::Engine::NGHTTP2")) {
        return NULL;
    }
    SV *inner = SvRV(sv);
    if (!inner || !SvIOK(inner) || SvIV(inner) == 0) {
        return NULL;
    }
    return INT2PTR(perl_nghttp2_session_t*, SvIV(inner));
}

static perl_nghttp2_session_t *get_session_ptr(pTHX_ SV *sv) {
    perl_nghttp2_session_t *sess = get_raw_session_ptr(aTHX_ sv);
    if (!sess || sess->pending_destroy) {
        return NULL;
    }
    return sess;
}

static int capture_callback_error(pTHX_ perl_nghttp2_session_t *sess) {
    if (SvTRUE(ERRSV)) {
        if (!sess->callback_err) {
            sess->callback_err = newSVsv(ERRSV);
        }
        sv_setsv(ERRSV, &PL_sv_undef);
        return NGHTTP2_ERR_CALLBACK_FAILURE;
    }
    return 0;
}

static ssize_t my_data_read_callback(nghttp2_session *session, int32_t stream_id,
                                     uint8_t *buf, size_t length,
                                     uint32_t *data_flags,
                                     nghttp2_data_source *source,
                                     void *user_data) {
    perl_data_source_t *src = (perl_data_source_t*)source->ptr;
    if (!src) {
        *data_flags |= NGHTTP2_DATA_FLAG_EOF;
        return 0;
    }
    size_t rem = src->len - src->pos;
    size_t copy_len = (rem < length) ? rem : length;
    if (copy_len > 0 && src->buf) {
        memcpy(buf, src->buf + src->pos, copy_len);
        src->pos += copy_len;
    }
    if (src->pos >= src->len) {
        *data_flags |= NGHTTP2_DATA_FLAG_EOF;
        nghttp2_session_set_stream_user_data(session, stream_id, NULL);
        free_data_source(src);
        source->ptr = NULL;
    }
    return (ssize_t)copy_len;
}

static int my_on_header_callback(nghttp2_session *session,
                                  const nghttp2_frame *frame,
                                  const uint8_t *name, size_t namelen,
                                  const uint8_t *value, size_t valuelen,
                                  uint8_t flags, void *user_data) {
    dTHX;
    perl_nghttp2_session_t *sess = (perl_nghttp2_session_t*)user_data;
    if (!sess || sess->pending_destroy) return 0;

    if (frame->hd.type == NGHTTP2_HEADERS) {
        int32_t stream_id = frame->hd.stream_id;
        SV *cb = NULL;
        if (frame->headers.cat == NGHTTP2_HCAT_RESPONSE ||
            frame->headers.cat == NGHTTP2_HCAT_REQUEST ||
            frame->headers.cat == NGHTTP2_HCAT_PUSH_RESPONSE) {
            cb = sess->on_headers_cb;
        } else {
            cb = sess->on_trailers_cb ? sess->on_trailers_cb : sess->on_headers_cb;
        }

        if (cb && SvOK(cb)) {
            dSP;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            mXPUSHi(stream_id);

            AV *av = newAV();
            av_push(av, newSVpvn((const char*)name, namelen));
            av_push(av, newSVpvn((const char*)value, valuelen));

            mXPUSHs(newRV_noinc((SV*)av));
            PUTBACK;
            call_sv(cb, G_DISCARD | G_EVAL);
            int rc = capture_callback_error(aTHX_ sess);
            FREETMPS;
            LEAVE;
            if (rc != 0) return rc;
        }
    }
    return 0;
}

static int my_on_data_chunk_recv_callback(nghttp2_session *session,
                                           uint8_t flags, int32_t stream_id,
                                           const uint8_t *data, size_t len,
                                           void *user_data) {
    dTHX;
    perl_nghttp2_session_t *sess = (perl_nghttp2_session_t*)user_data;
    if (!sess || sess->pending_destroy) return 0;

    if (sess->on_data_cb && SvOK(sess->on_data_cb)) {
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        mXPUSHi(stream_id);
        mXPUSHs(newSVpvn((const char*)data, len));
        PUTBACK;
        call_sv(sess->on_data_cb, G_DISCARD | G_EVAL);
        int rc = capture_callback_error(aTHX_ sess);
        FREETMPS;
        LEAVE;
        if (rc != 0) return rc;
    }
    return 0;
}

static int my_on_stream_close_callback(nghttp2_session *session,
                                        int32_t stream_id,
                                        uint32_t error_code,
                                        void *user_data) {
    dTHX;
    perl_nghttp2_session_t *sess = (perl_nghttp2_session_t*)user_data;
    perl_data_source_t *src = (perl_data_source_t*)nghttp2_session_get_stream_user_data(session, stream_id);
    if (src) {
        nghttp2_session_set_stream_user_data(session, stream_id, NULL);
        free_data_source(src);
    }
    if (!sess || sess->pending_destroy) return 0;

    if (sess->on_stream_close_cb && SvOK(sess->on_stream_close_cb)) {
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        mXPUSHi(stream_id);
        mXPUSHi(error_code);
        PUTBACK;
        call_sv(sess->on_stream_close_cb, G_DISCARD | G_EVAL);
        int rc = capture_callback_error(aTHX_ sess);
        FREETMPS;
        LEAVE;
        if (rc != 0) return rc;
    }
    return 0;
}

MODULE = Google::gRPC  PACKAGE = Google::gRPC::Engine::NGHTTP2

SV *
_xs_new(char *class_name)
CODE:
    perl_nghttp2_session_t *sess = NULL;
    nghttp2_session_callbacks *callbacks = NULL;

    Newxz(sess, 1, perl_nghttp2_session_t);

    int rv = nghttp2_session_callbacks_new(&callbacks);
    if (rv != 0 || !callbacks) {
        Safefree(sess);
        croak("nghttp2_session_callbacks_new failed: %s", nghttp2_strerror(rv));
    }
    nghttp2_session_callbacks_set_on_header_callback(callbacks, my_on_header_callback);
    nghttp2_session_callbacks_set_on_data_chunk_recv_callback(callbacks, my_on_data_chunk_recv_callback);
    nghttp2_session_callbacks_set_on_stream_close_callback(callbacks, my_on_stream_close_callback);

    rv = nghttp2_session_client_new(&(sess->session), callbacks, sess);
    nghttp2_session_callbacks_del(callbacks);
    if (rv != 0 || !sess->session) {
        Safefree(sess);
        croak("nghttp2_session_client_new failed: %s", nghttp2_strerror(rv));
    }

    rv = nghttp2_submit_settings(sess->session, NGHTTP2_FLAG_NONE, NULL, 0);
    if (rv != 0) {
        nghttp2_session_del(sess->session);
        Safefree(sess);
        croak("nghttp2_submit_settings failed: %s", nghttp2_strerror(rv));
    }

    SV *obj = sv_newmortal();
    sv_setref_pv(obj, class_name ? class_name : "Google::gRPC::Engine::NGHTTP2", (void*)sess);
    RETVAL = newSVsv(obj);
OUTPUT:
    RETVAL

void
DESTROY(SV *self_sv)
CODE:
    perl_nghttp2_session_t *sess = get_raw_session_ptr(aTHX_ self_sv);
    if (sess) {
        sv_setiv(SvRV(self_sv), 0);
        if (sess->in_callback > 0) {
            sess->pending_destroy = 1;
        } else {
            free_session_struct(aTHX_ sess);
        }
    }

int
is_xs(SV *self_sv)
CODE:
    RETVAL = 1;
OUTPUT:
    RETVAL

void
_xs_set_callbacks(SV *self_sv, SV *on_headers, SV *on_data, SV *on_trailers, SV *on_stream_close)
CODE:
    perl_nghttp2_session_t *sess = get_session_ptr(aTHX_ self_sv);
    if (!sess) croak("invalid session pointer");

    if (SvOK(on_headers)) {
        if (sess->on_headers_cb) SvREFCNT_dec(sess->on_headers_cb);
        sess->on_headers_cb = newSVsv(on_headers);
    }
    if (SvOK(on_data)) {
        if (sess->on_data_cb) SvREFCNT_dec(sess->on_data_cb);
        sess->on_data_cb = newSVsv(on_data);
    }
    if (SvOK(on_trailers)) {
        if (sess->on_trailers_cb) SvREFCNT_dec(sess->on_trailers_cb);
        sess->on_trailers_cb = newSVsv(on_trailers);
    }
    if (SvOK(on_stream_close)) {
        if (sess->on_stream_close_cb) SvREFCNT_dec(sess->on_stream_close_cb);
        sess->on_stream_close_cb = newSVsv(on_stream_close);
    }

int
_xs_submit_request(SV *self_sv, SV *headers_av_ref, SV *data_sv, int end_stream)
CODE:
    PERL_UNUSED_VAR(end_stream);
    perl_nghttp2_session_t *sess = get_session_ptr(aTHX_ self_sv);
    if (!sess) croak("invalid session pointer");

    if (!SvROK(headers_av_ref) || SvTYPE(SvRV(headers_av_ref)) != SVt_PVAV) {
        croak("headers must be an array reference");
    }
    AV *av = (AV*)SvRV(headers_av_ref);
    SSize_t len = av_len(av) + 1;
    if (len % 2 != 0) {
        croak("headers array must contain key/value pairs");
    }
    size_t num_nv = len / 2;
    nghttp2_nv *nva;
    Newxz(nva, num_nv, nghttp2_nv);

    size_t i;
    for (i = 0; i < num_nv; i++) {
        SV **k_ptr = av_fetch(av, i * 2, 0);
        SV **v_ptr = av_fetch(av, i * 2 + 1, 0);
        STRLEN k_len, v_len;
        const char *k_str = k_ptr ? SvPVbyte(*k_ptr, k_len) : "";
        const char *v_str = v_ptr ? SvPVbyte(*v_ptr, v_len) : "";

        nva[i].name = (uint8_t*)k_str;
        nva[i].namelen = k_len;
        nva[i].value = (uint8_t*)v_str;
        nva[i].valuelen = v_len;
        nva[i].flags = NGHTTP2_NV_FLAG_NONE;
    }

    nghttp2_data_provider data_prd;
    nghttp2_data_provider *p_prd = NULL;
    perl_data_source_t *src = NULL;

    if (data_sv && SvOK(data_sv)) {
        STRLEN d_len;
        const char *raw_ptr = SvPVbyte(data_sv, d_len);
        Newxz(src, 1, perl_data_source_t);
        if (d_len > 0) {
            Newx(src->buf, d_len, char);
            Copy(raw_ptr, src->buf, d_len, char);
        }
        src->len = d_len;
        src->pos = 0;

        data_prd.source.ptr = src;
        data_prd.read_callback = my_data_read_callback;
        p_prd = &data_prd;
    }

    int32_t stream_id = nghttp2_submit_request(sess->session, NULL, nva, num_nv, p_prd, src);
    Safefree(nva);

    if (stream_id < 0) {
        if (src) {
            if (src->buf) Safefree(src->buf);
            Safefree(src);
        }
        croak("nghttp2_submit_request failed: %s", nghttp2_strerror(stream_id));
    }
    if (src) {
        link_data_source(sess, src);
    }
    RETVAL = (int)stream_id;
OUTPUT:
    RETVAL

void
feed_input(SV *self_sv, SV *input_sv)
CODE:
    perl_nghttp2_session_t *sess = get_session_ptr(aTHX_ self_sv);
    if (!sess) croak("invalid session pointer");

    if (input_sv && SvOK(input_sv)) {
        STRLEN len;
        const char *buf = SvPVbyte(input_sv, len);
        if (len > 0 && sess->session) {
            sess->in_callback++;
            ssize_t rv = nghttp2_session_mem_recv(sess->session, (const uint8_t*)buf, len);
            sess->in_callback--;

            SV *caught_err = NULL;
            if (sess->callback_err) {
                caught_err = sess->callback_err;
                sess->callback_err = NULL;
            }
            if (sess->in_callback == 0 && sess->pending_destroy) {
                free_session_struct(aTHX_ sess);
            }
            if (caught_err) {
                croak_sv(sv_2mortal(caught_err));
            }
            if (rv < 0) {
                croak("nghttp2_session_mem_recv failed: %s", nghttp2_strerror((int)rv));
            }
        }
    }

SV *
get_output(SV *self_sv)
CODE:
    perl_nghttp2_session_t *sess = get_session_ptr(aTHX_ self_sv);
    if (!sess) croak("invalid session pointer");

    const uint8_t *data_ptr = NULL;
    ssize_t len = 0;
    SV *res = newSVpvn("", 0);

    sess->in_callback++;
    while (sess->session && !sess->pending_destroy &&
           (len = nghttp2_session_mem_send(sess->session, &data_ptr)) > 0) {
        sv_catpvn(res, (const char*)data_ptr, len);
    }
    sess->in_callback--;

    SV *caught_err = NULL;
    if (sess->callback_err) {
        caught_err = sess->callback_err;
        sess->callback_err = NULL;
    }
    if (sess->in_callback == 0 && sess->pending_destroy) {
        free_session_struct(aTHX_ sess);
    }
    if (caught_err) {
        SvREFCNT_dec(res);
        croak_sv(sv_2mortal(caught_err));
    }
    if (len < 0) {
        SvREFCNT_dec(res);
        croak("nghttp2_session_mem_send failed: %s", nghttp2_strerror((int)len));
    }
    RETVAL = res;
OUTPUT:
    RETVAL
