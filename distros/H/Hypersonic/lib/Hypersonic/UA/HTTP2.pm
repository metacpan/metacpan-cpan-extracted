package Hypersonic::UA::HTTP2;

use strict;
use warnings;
use 5.010;

our $VERSION = '0.12';

use constant {
    MAX_H2_SESSIONS        => 100,
    MAX_STREAMS_PER_SESSION => 100,
};

my $NGHTTP2_AVAILABLE;

sub check_nghttp2 {
    return $NGHTTP2_AVAILABLE if defined $NGHTTP2_AVAILABLE;

    my $libs = `pkg-config --libs libnghttp2 2>/dev/null`;
    if ($? == 0 && $libs) {
        $NGHTTP2_AVAILABLE = 1;
        return 1;
    }

    for my $path (qw(/usr/include/nghttp2/nghttp2.h /usr/local/include/nghttp2/nghttp2.h)) {
        if (-f $path) {
            $NGHTTP2_AVAILABLE = 1;
            return 1;
        }
    }

    $NGHTTP2_AVAILABLE = 0;
    return 0;
}

sub get_extra_cflags {
    my $cflags = `pkg-config --cflags libnghttp2 2>/dev/null` || '';
    chomp $cflags;
    return $cflags;
}

sub get_extra_ldflags {
    my $ldflags = `pkg-config --libs libnghttp2 2>/dev/null` || '-lnghttp2';
    chomp $ldflags;
    return $ldflags;
}

sub generate_c_code {
    my ($class, $builder, $opts) = @_;

    my $max_sessions = $opts->{max_h2_sessions} // MAX_H2_SESSIONS;
    my $max_streams = $opts->{max_streams_per_session} // MAX_STREAMS_PER_SESSION;

    $class->gen_h2_registry($builder, $max_sessions, $max_streams);
    $class->gen_h2_callbacks($builder);
    $class->gen_xs_session_new($builder);
    $class->gen_xs_submit_request($builder);
    $class->gen_xs_receive($builder);
    $class->gen_xs_session_close($builder);
    $class->gen_xs_is_complete($builder);
}

sub get_xs_functions {
    return {
        'Hypersonic::UA::HTTP2::session_new'     => { source => 'xs_h2_session_new', is_xs_native => 1 },
        'Hypersonic::UA::HTTP2::submit_request'  => { source => 'xs_h2_submit_request', is_xs_native => 1 },
        'Hypersonic::UA::HTTP2::receive'         => { source => 'xs_h2_receive', is_xs_native => 1 },
        'Hypersonic::UA::HTTP2::session_close'   => { source => 'xs_h2_session_close', is_xs_native => 1 },
        'Hypersonic::UA::HTTP2::is_complete'     => { source => 'xs_h2_is_complete', is_xs_native => 1 },
    };
}

sub gen_h2_registry {
    my ($class, $builder, $max_sessions, $max_streams) = @_;

    $builder->line('#include <nghttp2/nghttp2.h>')
      ->line('#include <string.h>')
      ->line('#include <stdlib.h>')
      ->line('#include <sys/socket.h>')
      ->line('#include <errno.h>')
      ->line('#include <unistd.h>')
      ->blank;

    $builder->line("#define MAX_H2_SESSIONS $max_sessions")
      ->line("#define MAX_STREAMS_PER_SESSION $max_streams")
      ->blank;

    $builder->line('typedef struct {')
      ->line('    int32_t  stream_id;')
      ->line('    int      status;')
      ->line('    char*    body;')
      ->line('    size_t   body_len;')
      ->line('    size_t   body_cap;')
      ->line('    HV*      headers;')
      ->line('    int      complete;')
      ->line('} H2Stream;')
      ->blank;

    $builder->line('typedef struct {')
      ->line('    int               fd;')
      ->line('    int               tls;')
      ->line('    nghttp2_session*  session;')
      ->line("    H2Stream          streams[MAX_STREAMS_PER_SESSION];")
      ->line('    int               stream_count;')
      ->line('} H2Session;')
      ->blank;

    $builder->line("static H2Session h2_registry[MAX_H2_SESSIONS];")
      ->blank;

    # Helper: find session by fd
    $builder->line('static H2Session* h2_find_session(int fd) {')
      ->line('    int i;')
      ->line('    for (i = 0; i < MAX_H2_SESSIONS; i++) {')
      ->line('        if (h2_registry[i].fd == fd) {')
      ->line('            return &h2_registry[i];')
      ->line('        }')
      ->line('    }')
      ->line('    return NULL;')
      ->line('}')
      ->blank;

    # Helper: get session by slot
    $builder->line('static H2Session* h2_get_session(int slot) {')
      ->line('    if (slot < 0 || slot >= MAX_H2_SESSIONS) return NULL;')
      ->line('    if (h2_registry[slot].fd == 0) return NULL;')
      ->line('    return &h2_registry[slot];')
      ->line('}')
      ->blank;

    # Helper: allocate session slot
    $builder->line('static int h2_alloc_session(int fd) {')
      ->line('    int i;')
      ->line('    for (i = 0; i < MAX_H2_SESSIONS; i++) {')
      ->line('        if (h2_registry[i].fd == 0) {')
      ->line('            memset(&h2_registry[i], 0, sizeof(H2Session));')
      ->line('            h2_registry[i].fd = fd;')
      ->line('            return i;')
      ->line('        }')
      ->line('    }')
      ->line('    return -1;')
      ->line('}')
      ->blank;

    # Helper: find stream in session
    $builder->line('static H2Stream* h2_find_stream(H2Session* sess, int32_t stream_id) {')
      ->line('    int i;')
      ->line('    for (i = 0; i < sess->stream_count; i++) {')
      ->line('        if (sess->streams[i].stream_id == stream_id) {')
      ->line('            return &sess->streams[i];')
      ->line('        }')
      ->line('    }')
      ->line('    return NULL;')
      ->line('}')
      ->blank;
}

sub gen_h2_callbacks {
    my ($class, $builder) = @_;

    # Send callback
    $builder->comment('nghttp2 send callback')
      ->line('static ssize_t h2_send_cb(nghttp2_session* session,')
      ->line('                          const uint8_t* data, size_t length,')
      ->line('                          int flags, void* user_data) {')
      ->line('    H2Session* h2sess = (H2Session*)user_data;')
      ->line('    ssize_t ret = send(h2sess->fd, data, length, 0);')
      ->line('    if (ret < 0) {')
      ->line('        if (errno == EAGAIN || errno == EWOULDBLOCK) {')
      ->line('            return NGHTTP2_ERR_WOULDBLOCK;')
      ->line('        }')
      ->line('        return NGHTTP2_ERR_CALLBACK_FAILURE;')
      ->line('    }')
      ->line('    return ret;')
      ->line('}')
      ->blank;

    # Recv callback
    $builder->comment('nghttp2 recv callback')
      ->line('static ssize_t h2_recv_cb(nghttp2_session* session,')
      ->line('                          uint8_t* buf, size_t length,')
      ->line('                          int flags, void* user_data) {')
      ->line('    H2Session* h2sess = (H2Session*)user_data;')
      ->line('    ssize_t ret = recv(h2sess->fd, buf, length, 0);')
      ->line('    if (ret < 0) {')
      ->line('        if (errno == EAGAIN || errno == EWOULDBLOCK) {')
      ->line('            return NGHTTP2_ERR_WOULDBLOCK;')
      ->line('        }')
      ->line('        return NGHTTP2_ERR_CALLBACK_FAILURE;')
      ->line('    }')
      ->line('    if (ret == 0) return NGHTTP2_ERR_EOF;')
      ->line('    return ret;')
      ->line('}')
      ->blank;

    # Header callback
    $builder->comment('nghttp2 header callback')
      ->line('static int h2_on_header_cb(nghttp2_session* session,')
      ->line('                           const nghttp2_frame* frame,')
      ->line('                           const uint8_t* name, size_t namelen,')
      ->line('                           const uint8_t* value, size_t valuelen,')
      ->line('                           uint8_t flags, void* user_data) {')
      ->line('    H2Session* h2sess = (H2Session*)user_data;')
      ->line('    int32_t stream_id = frame->hd.stream_id;')
      ->blank
      ->line('    H2Stream* st = h2_find_stream(h2sess, stream_id);')
      ->line('    if (!st) return 0;')
      ->blank
      ->line('    if (namelen == 7 && memcmp(name, ":status", 7) == 0) {')
      ->line('        st->status = atoi((char*)value);')
      ->line('    } else if (name[0] != \':\') {')
      ->line('        if (!st->headers) st->headers = newHV();')
      ->line('        hv_store(st->headers, (char*)name, namelen, newSVpvn((char*)value, valuelen), 0);')
      ->line('    }')
      ->line('    return 0;')
      ->line('}')
      ->blank;

    # Data chunk callback
    $builder->comment('nghttp2 data chunk callback')
      ->line('static int h2_on_data_chunk_cb(nghttp2_session* session, uint8_t flags,')
      ->line('                               int32_t stream_id,')
      ->line('                               const uint8_t* data, size_t len,')
      ->line('                               void* user_data) {')
      ->line('    H2Session* h2sess = (H2Session*)user_data;')
      ->line('    H2Stream* st = h2_find_stream(h2sess, stream_id);')
      ->line('    if (!st) return 0;')
      ->blank
      ->line('    if (st->body_len + len > st->body_cap) {')
      ->line('        size_t new_cap = (st->body_cap + len) * 2;')
      ->line('        if (new_cap < 4096) new_cap = 4096;')
      ->line('        st->body = realloc(st->body, new_cap);')
      ->line('        st->body_cap = new_cap;')
      ->line('    }')
      ->blank
      ->line('    memcpy(st->body + st->body_len, data, len);')
      ->line('    st->body_len += len;')
      ->line('    return 0;')
      ->line('}')
      ->blank;

    # Stream close callback
    $builder->comment('nghttp2 stream close callback')
      ->line('static int h2_on_stream_close_cb(nghttp2_session* session,')
      ->line('                                 int32_t stream_id,')
      ->line('                                 uint32_t error_code, void* user_data) {')
      ->line('    H2Session* h2sess = (H2Session*)user_data;')
      ->line('    H2Stream* st = h2_find_stream(h2sess, stream_id);')
      ->line('    if (st) st->complete = 1;')
      ->line('    return 0;')
      ->line('}')
      ->blank;
}

sub gen_xs_session_new {
    my ($class, $builder) = @_;

    $builder->comment('Create HTTP/2 client session')
      ->xs_function('xs_h2_session_new')
      ->xs_preamble
      ->line('int fd;')
      ->line('int slot;')
      ->line('H2Session* h2sess;')
      ->line('nghttp2_session_callbacks* callbacks;')
      ->line('nghttp2_settings_entry iv[1];')
      ->blank
      ->line('if (items != 1) croak("Usage: session_new(fd)");')
      ->line('fd = (int)SvIV(ST(0));')
      ->blank
      ->line('slot = h2_alloc_session(fd);')
      ->line('if (slot < 0) {')
      ->line('    ST(0) = sv_2mortal(newSViv(-1));')
      ->line('    XSRETURN(1);')
      ->line('}')
      ->blank
      ->line('h2sess = &h2_registry[slot];')
      ->blank
      ->line('nghttp2_session_callbacks_new(&callbacks);')
      ->line('nghttp2_session_callbacks_set_send_callback(callbacks, h2_send_cb);')
      ->line('nghttp2_session_callbacks_set_recv_callback(callbacks, h2_recv_cb);')
      ->line('nghttp2_session_callbacks_set_on_header_callback(callbacks, h2_on_header_cb);')
      ->line('nghttp2_session_callbacks_set_on_data_chunk_recv_callback(callbacks, h2_on_data_chunk_cb);')
      ->line('nghttp2_session_callbacks_set_on_stream_close_callback(callbacks, h2_on_stream_close_cb);')
      ->blank
      ->line('nghttp2_session_client_new(&h2sess->session, callbacks, h2sess);')
      ->line('nghttp2_session_callbacks_del(callbacks);')
      ->blank
      ->line('iv[0].settings_id = NGHTTP2_SETTINGS_MAX_CONCURRENT_STREAMS;')
      ->line('iv[0].value = 100;')
      ->line('nghttp2_submit_settings(h2sess->session, NGHTTP2_FLAG_NONE, iv, 1);')
      ->line('nghttp2_session_send(h2sess->session);')
      ->blank
      ->line('ST(0) = sv_2mortal(newSViv(slot));')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_submit_request {
    my ($class, $builder) = @_;

    $builder->comment('Submit HTTP/2 request')
      ->xs_function('xs_h2_submit_request')
      ->xs_preamble
      ->line('int slot;')
      ->line('STRLEN method_len, scheme_len, auth_len, path_len;')
      ->line('const char* method;')
      ->line('const char* scheme;')
      ->line('const char* authority;')
      ->line('const char* path;')
      ->line('H2Session* h2sess;')
      ->line('nghttp2_nv hdrs[4];')
      ->line('int32_t stream_id;')
      ->line('int idx;')
      ->line('H2Stream* st;')
      ->blank
      ->line('if (items < 5) croak("Usage: submit_request(session_slot, method, scheme, authority, path)");')
      ->blank
      ->line('slot = (int)SvIV(ST(0));')
      ->line('method = SvPV(ST(1), method_len);')
      ->line('scheme = SvPV(ST(2), scheme_len);')
      ->line('authority = SvPV(ST(3), auth_len);')
      ->line('path = SvPV(ST(4), path_len);')
      ->blank
      ->line('h2sess = h2_get_session(slot);')
      ->line('if (!h2sess) {')
      ->line('    ST(0) = sv_2mortal(newSViv(-1));')
      ->line('    XSRETURN(1);')
      ->line('}')
      ->blank
      ->line('hdrs[0].name = (uint8_t*)":method";')
      ->line('hdrs[0].value = (uint8_t*)method;')
      ->line('hdrs[0].namelen = 7;')
      ->line('hdrs[0].valuelen = method_len;')
      ->line('hdrs[0].flags = NGHTTP2_NV_FLAG_NONE;')
      ->line('hdrs[1].name = (uint8_t*)":scheme";')
      ->line('hdrs[1].value = (uint8_t*)scheme;')
      ->line('hdrs[1].namelen = 7;')
      ->line('hdrs[1].valuelen = scheme_len;')
      ->line('hdrs[1].flags = NGHTTP2_NV_FLAG_NONE;')
      ->line('hdrs[2].name = (uint8_t*)":authority";')
      ->line('hdrs[2].value = (uint8_t*)authority;')
      ->line('hdrs[2].namelen = 10;')
      ->line('hdrs[2].valuelen = auth_len;')
      ->line('hdrs[2].flags = NGHTTP2_NV_FLAG_NONE;')
      ->line('hdrs[3].name = (uint8_t*)":path";')
      ->line('hdrs[3].value = (uint8_t*)path;')
      ->line('hdrs[3].namelen = 5;')
      ->line('hdrs[3].valuelen = path_len;')
      ->line('hdrs[3].flags = NGHTTP2_NV_FLAG_NONE;')
      ->blank
      ->line('stream_id = nghttp2_submit_request(h2sess->session, NULL, hdrs, 4, NULL, NULL);')
      ->line('if (stream_id < 0) {')
      ->line('    ST(0) = sv_2mortal(newSViv(stream_id));')
      ->line('    XSRETURN(1);')
      ->line('}')
      ->blank
      ->line('idx = h2sess->stream_count++;')
      ->line('st = &h2sess->streams[idx];')
      ->line('memset(st, 0, sizeof(H2Stream));')
      ->line('st->stream_id = stream_id;')
      ->line('st->body = malloc(4096);')
      ->line('st->body_cap = 4096;')
      ->blank
      ->line('nghttp2_session_send(h2sess->session);')
      ->blank
      ->line('ST(0) = sv_2mortal(newSViv(stream_id));')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_receive {
    my ($class, $builder) = @_;

    $builder->comment('Receive HTTP/2 response')
      ->xs_function('xs_h2_receive')
      ->xs_preamble
      ->line('if (items != 2) croak("Usage: receive(session_slot, stream_id)");')
      ->blank
      ->line('int slot = (int)SvIV(ST(0));')
      ->line('int32_t stream_id = (int32_t)SvIV(ST(1));')
      ->blank
      ->line('H2Session* h2sess = h2_get_session(slot);')
      ->line('if (!h2sess) {')
      ->line('    ST(0) = &PL_sv_undef;')
      ->line('    XSRETURN(1);')
      ->line('}')
      ->blank
      ->line('int max_loops = 1000;')
      ->line('while (max_loops-- > 0) {')
      ->line('    H2Stream* st = h2_find_stream(h2sess, stream_id);')
      ->blank
      ->line('    if (st && st->complete) {')
      ->line('        AV* result = newAV();')
      ->line('        av_push(result, newSViv(st->status));')
      ->line('        av_push(result, st->body ? newSVpvn(st->body, st->body_len) : newSVpvn("", 0));')
      ->line('        av_push(result, st->headers ? newRV_inc((SV*)st->headers) : newRV_noinc((SV*)newHV()));')
      ->line('        ST(0) = sv_2mortal(newRV_noinc((SV*)result));')
      ->line('        XSRETURN(1);')
      ->line('    }')
      ->blank
      ->line('    int rv = nghttp2_session_recv(h2sess->session);')
      ->line('    if (rv != 0 && rv != NGHTTP2_ERR_WOULDBLOCK) break;')
      ->line('}')
      ->blank
      ->line('ST(0) = &PL_sv_undef;')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_session_close {
    my ($class, $builder) = @_;

    $builder->comment('Close HTTP/2 session')
      ->xs_function('xs_h2_session_close')
      ->xs_preamble
      ->line('int i;')
      ->line('if (items != 1) croak("Usage: session_close(session_slot)");')
      ->blank
      ->line('int slot = (int)SvIV(ST(0));')
      ->line('H2Session* h2sess = h2_get_session(slot);')
      ->line('if (!h2sess) {')
      ->line('    ST(0) = sv_2mortal(newSViv(0));')
      ->line('    XSRETURN(1);')
      ->line('}')
      ->blank
      ->line('for (i = 0; i < h2sess->stream_count; i++) {')
      ->line('    H2Stream* st = &h2sess->streams[i];')
      ->line('    if (st->body) free(st->body);')
      ->line('    if (st->headers) SvREFCNT_dec((SV*)st->headers);')
      ->line('}')
      ->blank
      ->line('if (h2sess->session) {')
      ->line('    nghttp2_session_del(h2sess->session);')
      ->line('}')
      ->blank
      ->line('if (h2sess->fd > 0) {')
      ->line('    close(h2sess->fd);')
      ->line('}')
      ->blank
      ->line('memset(h2sess, 0, sizeof(H2Session));')
      ->line('ST(0) = sv_2mortal(newSViv(1));')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_is_complete {
    my ($class, $builder) = @_;

    $builder->comment('Check if stream complete')
      ->xs_function('xs_h2_is_complete')
      ->xs_preamble
      ->line('if (items != 2) croak("Usage: is_complete(session_slot, stream_id)");')
      ->blank
      ->line('int slot = (int)SvIV(ST(0));')
      ->line('int32_t stream_id = (int32_t)SvIV(ST(1));')
      ->blank
      ->line('H2Session* h2sess = h2_get_session(slot);')
      ->line('if (!h2sess) {')
      ->line('    ST(0) = &PL_sv_no;')
      ->line('    XSRETURN(1);')
      ->line('}')
      ->blank
      ->line('H2Stream* st = h2_find_stream(h2sess, stream_id);')
      ->line('ST(0) = (st && st->complete) ? &PL_sv_yes : &PL_sv_no;')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

1;
