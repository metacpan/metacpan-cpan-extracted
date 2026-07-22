#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <nghttp2/nghttp2.h>
#include <string.h>

typedef struct {
    nghttp2_session *session;
    SV *on_headers_cb;
    SV *on_data_cb;
    SV *on_trailers_cb;
    SV *on_stream_close_cb;
} perl_nghttp2_session_t;

typedef struct {
    const char *buf;
    size_t len;
    size_t pos;
} perl_data_source_t;

static perl_nghttp2_session_t *get_session_ptr(SV *sv) {
    dTHX;
    if (!sv || !SvROK(sv)) return NULL;
    SV *inner = SvRV(sv);
    if (!inner) return NULL;
    return (perl_nghttp2_session_t*)INT2PTR(void*, SvIV(inner));
}

static ssize_t my_data_read_callback(nghttp2_session *session, int32_t stream_id,
                                     uint8_t *buf, size_t length,
                                     uint32_t *data_flags,
                                     nghttp2_data_source *source,
                                     void *user_data) {
    perl_data_source_t *src = (perl_data_source_t*)source->ptr;
    if (!src) return 0;
    size_t rem = src->len - src->pos;
    size_t copy_len = (rem < length) ? rem : length;
    if (copy_len > 0) {
        memcpy(buf, src->buf + src->pos, copy_len);
        src->pos += copy_len;
    }
    if (src->pos >= src->len) {
        *data_flags |= NGHTTP2_DATA_FLAG_EOF;
        Safefree(src);
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
    if (!sess) return 0;

    if (frame->hd.type == NGHTTP2_HEADERS) {
        int32_t stream_id = frame->hd.stream_id;
        SV *cb = NULL;
        if (frame->headers.cat == NGHTTP2_HCAT_HEADERS || frame->headers.cat == NGHTTP2_HCAT_RESPONSE) {
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
            call_sv(cb, G_DISCARD);
            FREETMPS;
            LEAVE;
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
    if (!sess) return 0;

    if (sess->on_data_cb && SvOK(sess->on_data_cb)) {
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        mXPUSHi(stream_id);
        mXPUSHs(newSVpvn((const char*)data, len));
        PUTBACK;
        call_sv(sess->on_data_cb, G_DISCARD);
        FREETMPS;
        LEAVE;
    }
    return 0;
}

static int my_on_stream_close_callback(nghttp2_session *session,
                                        int32_t stream_id,
                                        uint32_t error_code,
                                        void *user_data) {
    dTHX;
    perl_nghttp2_session_t *sess = (perl_nghttp2_session_t*)user_data;
    if (!sess) return 0;

    if (sess->on_stream_close_cb && SvOK(sess->on_stream_close_cb)) {
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        mXPUSHi(stream_id);
        mXPUSHi(error_code);
        PUTBACK;
        call_sv(sess->on_stream_close_cb, G_DISCARD);
        FREETMPS;
        LEAVE;
    }
    return 0;
}

MODULE = Google::gRPC  PACKAGE = Google::gRPC::Engine::NGHTTP2

SV *
_xs_new(char *class_name)
CODE:
    perl_nghttp2_session_t *sess;
    nghttp2_session_callbacks *callbacks;

    Newxz(sess, 1, perl_nghttp2_session_t);

    nghttp2_session_callbacks_new(&callbacks);
    nghttp2_session_callbacks_set_on_header_callback(callbacks, my_on_header_callback);
    nghttp2_session_callbacks_set_on_data_chunk_recv_callback(callbacks, my_on_data_chunk_recv_callback);
    nghttp2_session_callbacks_set_on_stream_close_callback(callbacks, my_on_stream_close_callback);

    nghttp2_session_client_new(&(sess->session), callbacks, sess);
    nghttp2_session_callbacks_del(callbacks);

    nghttp2_submit_settings(sess->session, NGHTTP2_FLAG_NONE, NULL, 0);

    SV *obj = sv_newmortal();
    sv_setref_pv(obj, class_name ? class_name : "Google::gRPC::Engine::NGHTTP2", (void*)sess);
    RETVAL = newSVsv(obj);
OUTPUT:
    RETVAL

void
DESTROY(SV *self_sv)
CODE:
    perl_nghttp2_session_t *sess = get_session_ptr(self_sv);
    if (sess) {
        if (sess->session) nghttp2_session_del(sess->session);
        if (sess->on_headers_cb) SvREFCNT_dec(sess->on_headers_cb);
        if (sess->on_data_cb) SvREFCNT_dec(sess->on_data_cb);
        if (sess->on_trailers_cb) SvREFCNT_dec(sess->on_trailers_cb);
        if (sess->on_stream_close_cb) SvREFCNT_dec(sess->on_stream_close_cb);
        Safefree(sess);
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
    perl_nghttp2_session_t *sess = get_session_ptr(self_sv);
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
    perl_nghttp2_session_t *sess = get_session_ptr(self_sv);
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

    if (data_sv && SvOK(data_sv)) {
        perl_data_source_t *src;
        Newxz(src, 1, perl_data_source_t);
        STRLEN d_len;
        src->buf = SvPVbyte(data_sv, d_len);
        src->len = d_len;
        src->pos = 0;

        data_prd.source.ptr = src;
        data_prd.read_callback = my_data_read_callback;
        p_prd = &data_prd;
    }

    int32_t stream_id = nghttp2_submit_request(sess->session, NULL, nva, num_nv, p_prd, NULL);
    Safefree(nva);

    if (stream_id < 0) {
        croak("nghttp2_submit_request failed: %s", nghttp2_strerror(stream_id));
    }
    RETVAL = (int)stream_id;
OUTPUT:
    RETVAL

void
feed_input(SV *self_sv, SV *input_sv)
CODE:
    perl_nghttp2_session_t *sess = get_session_ptr(self_sv);
    if (!sess) croak("invalid session pointer");

    if (input_sv && SvOK(input_sv)) {
        STRLEN len;
        const char *buf = SvPVbyte(input_sv, len);
        if (len > 0 && sess->session) {
            ssize_t rv = nghttp2_session_mem_recv(sess->session, (const uint8_t*)buf, len);
            if (rv < 0) {
                croak("nghttp2_session_mem_recv failed: %s", nghttp2_strerror((int)rv));
            }
        }
    }

SV *
get_output(SV *self_sv)
CODE:
    perl_nghttp2_session_t *sess = get_session_ptr(self_sv);
    if (!sess) croak("invalid session pointer");

    const uint8_t *data_ptr = NULL;
    ssize_t len;
    SV *res = newSVpvn("", 0);
    while (sess->session && (len = nghttp2_session_mem_send(sess->session, &data_ptr)) > 0) {
        sv_catpvn(res, (const char*)data_ptr, len);
    }
    RETVAL = res;
OUTPUT:
    RETVAL
