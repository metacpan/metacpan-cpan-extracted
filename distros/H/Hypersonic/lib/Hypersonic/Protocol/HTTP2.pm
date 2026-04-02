package Hypersonic::Protocol::HTTP2;
use strict;
use warnings;

# Hypersonic::Protocol::HTTP2 - JIT code generation for HTTP/2 protocol
#
# This module provides compile-time code generation for HTTP/2 support
# using nghttp2 for binary framing and HPACK compression.
# All methods generate C code - zero runtime overhead.

our $VERSION = '0.12';

# Cache nghttp2 detection result
my $_nghttp2_info;

# Detect nghttp2 library on the system
sub check_nghttp2 {
    return $_nghttp2_info if defined $_nghttp2_info;
    
    # Try pkg-config first (if available)
    my $cflags = `pkg-config --cflags libnghttp2 2>/dev/null`;
    my $ldflags = `pkg-config --libs libnghttp2 2>/dev/null`;
    
    if ($? == 0 && $ldflags) {
        chomp($cflags, $ldflags);
        $_nghttp2_info = { cflags => $cflags, ldflags => $ldflags };
        return $_nghttp2_info;
    }
    
    # Try standard paths on macOS/Linux
    my @prefixes = qw(/opt/homebrew /usr/local /usr);
    for my $prefix (@prefixes) {
        if (-f "$prefix/include/nghttp2/nghttp2.h") {
            $_nghttp2_info = {
                cflags  => "-I$prefix/include",
                ldflags => "-L$prefix/lib -lnghttp2",
            };
            return $_nghttp2_info;
        }
    }
    
    $_nghttp2_info = 0;  # Not found
    return undef;
}

# Get compiler flags
sub get_extra_cflags {
    my $info = check_nghttp2() or return '';
    return $info->{cflags};
}

sub get_extra_ldflags {
    my $info = check_nghttp2() or return '';
    return $info->{ldflags};
}

# Protocol identifier
sub protocol_id { 'h2' }
sub version_string { 'HTTP/2' }

# Generate nghttp2 includes
sub gen_includes {
    my ($class, $builder) = @_;
    
    $builder->line('#include <nghttp2/nghttp2.h>')
      ->line('#define HYPERSONIC_HTTP2 1')
      ->blank;
    
    return $builder;
}

# Generate HTTP/2 connection structure
sub gen_connection_struct {
    my ($class, $builder) = @_;
    
    $builder->comment('HTTP/2 connection state')
      ->line('typedef struct {')
      ->line('    int fd;')
      ->line('    nghttp2_session* session;')
      ->line('    int protocol;  /* PROTO_HTTP1=1, PROTO_HTTP2=2 */')
      ->line('    time_t last_activity;')
      ->line('    /* Stream state for multiplexed requests */')
      ->line('    char* pending_method;')
      ->line('    int pending_method_len;')
      ->line('    char* pending_path;')
      ->line('    int pending_path_len;')
      ->line('    char* pending_body;')
      ->line('    int pending_body_len;')
      ->line('    int32_t pending_stream_id;')
      ->line('} H2Connection;')
      ->blank
      ->line('#define PROTO_HTTP1 1')
      ->line('#define PROTO_HTTP2 2')
      ->line('#define MAX_H2_CONNECTIONS 1024')
      ->line('static H2Connection g_h2_connections[MAX_H2_CONNECTIONS];')
      ->blank;
    
    return $builder;
}

# Generate nghttp2 callbacks
sub gen_callbacks {
    my ($class, $builder, %opts) = @_;
    
    # Send callback - writes data to socket
    $builder->comment('HTTP/2: nghttp2 send callback')
      ->line('static ssize_t h2_send_cb(nghttp2_session* session,')
      ->line('                          const uint8_t* data, size_t length,')
      ->line('                          int flags, void* user_data) {')
      ->line('    (void)session; (void)flags;')
      ->line('    H2Connection* conn = (H2Connection*)user_data;')
      ->line('#ifdef HYPERSONIC_TLS')
      ->line('    TLSConnection* tls = get_tls_connection(conn->fd);')
      ->if('tls')
        ->line('return tls_send(tls, data, length);')
      ->endif
      ->line('#endif')
      ->line('    ssize_t rv = send(conn->fd, data, length, 0);')
      ->if('rv < 0')
        ->if('errno == EAGAIN || errno == EWOULDBLOCK')
          ->line('return NGHTTP2_ERR_WOULDBLOCK;')
        ->endif
        ->line('return NGHTTP2_ERR_CALLBACK_FAILURE;')
      ->endif
      ->line('    return rv;')
      ->line('}')
      ->blank;
    
    # Header callback - receives request headers
    $builder->comment('HTTP/2: Header received callback')
      ->line('static int h2_on_header_cb(nghttp2_session* session,')
      ->line('                           const nghttp2_frame* frame,')
      ->line('                           const uint8_t* name, size_t namelen,')
      ->line('                           const uint8_t* value, size_t valuelen,')
      ->line('                           uint8_t flags, void* user_data) {')
      ->line('    (void)session; (void)flags;')
      ->line('    H2Connection* conn = (H2Connection*)user_data;')
      ->blank
      ->if('frame->hd.type != NGHTTP2_HEADERS')
        ->line('return 0;')
      ->endif
      ->blank
      ->comment('Capture :method and :path pseudo-headers')
      ->if('namelen == 7 && memcmp(name, ":method", 7) == 0')
        ->line('conn->pending_method = (char*)malloc(valuelen + 1);')
        ->line('memcpy(conn->pending_method, value, valuelen);')
        ->line('conn->pending_method[valuelen] = \'\\0\';')
        ->line('conn->pending_method_len = valuelen;')
      ->elsif('namelen == 5 && memcmp(name, ":path", 5) == 0')
        ->line('conn->pending_path = (char*)malloc(valuelen + 1);')
        ->line('memcpy(conn->pending_path, value, valuelen);')
        ->line('conn->pending_path[valuelen] = \'\\0\';')
        ->line('conn->pending_path_len = valuelen;')
      ->endif
      ->line('    conn->pending_stream_id = frame->hd.stream_id;')
      ->line('    return 0;')
      ->line('}')
      ->blank;
    
    # Data chunk callback - receives request body
    $builder->comment('HTTP/2: Data chunk received callback')
      ->line('static int h2_on_data_chunk_cb(nghttp2_session* session,')
      ->line('                               uint8_t flags, int32_t stream_id,')
      ->line('                               const uint8_t* data, size_t len,')
      ->line('                               void* user_data) {')
      ->line('    (void)session; (void)flags; (void)stream_id;')
      ->line('    H2Connection* conn = (H2Connection*)user_data;')
      ->blank
      ->comment('Append to pending body')
      ->if('!conn->pending_body')
        ->line('conn->pending_body = (char*)malloc(len + 1);')
        ->line('memcpy(conn->pending_body, data, len);')
        ->line('conn->pending_body_len = len;')
      ->else
        ->line('conn->pending_body = realloc(conn->pending_body, conn->pending_body_len + len + 1);')
        ->line('memcpy(conn->pending_body + conn->pending_body_len, data, len);')
        ->line('conn->pending_body_len += len;')
      ->endif
      ->line('    conn->pending_body[conn->pending_body_len] = \'\\0\';')
      ->line('    return 0;')
      ->line('}')
      ->blank;
    
    # Frame received callback - trigger request handling
    $builder->comment('HTTP/2: Frame received - dispatch request when headers complete')
      ->line('static int h2_on_frame_recv_cb(nghttp2_session* session,')
      ->line('                               const nghttp2_frame* frame,')
      ->line('                               void* user_data) {')
      ->line('    H2Connection* conn = (H2Connection*)user_data;')
      ->blank
      ->comment('Process request when HEADERS frame with END_HEADERS is received')
      ->if('frame->hd.type == NGHTTP2_HEADERS && frame->headers.cat == NGHTTP2_HCAT_REQUEST && (frame->hd.flags & NGHTTP2_FLAG_END_HEADERS)')
        ->comment('If END_STREAM is also set, no body expected - dispatch now')
        ->if('frame->hd.flags & NGHTTP2_FLAG_END_STREAM')
          ->line('h2_dispatch_request(session, conn, frame->hd.stream_id);')
        ->endif
      ->endif
      ->blank
      ->comment('Process request when DATA frame with END_STREAM is received')
      ->if('frame->hd.type == NGHTTP2_DATA && (frame->hd.flags & NGHTTP2_FLAG_END_STREAM)')
        ->line('h2_dispatch_request(session, conn, frame->hd.stream_id);')
      ->endif
      ->blank
      ->line('    return 0;')
      ->line('}')
      ->blank;
    
    # Stream close callback - cleanup
    $builder->comment('HTTP/2: Stream closed callback - cleanup')
      ->line('static int h2_on_stream_close_cb(nghttp2_session* session,')
      ->line('                                 int32_t stream_id, uint32_t error_code,')
      ->line('                                 void* user_data) {')
      ->line('    (void)session; (void)stream_id; (void)error_code;')
      ->line('    H2Connection* conn = (H2Connection*)user_data;')
      ->blank
      ->comment('Free pending request data')
      ->if('conn->pending_method')
        ->line('free(conn->pending_method); conn->pending_method = NULL;')
      ->endif
      ->if('conn->pending_path')
        ->line('free(conn->pending_path); conn->pending_path = NULL;')
      ->endif
      ->if('conn->pending_body')
        ->line('free(conn->pending_body); conn->pending_body = NULL;')
      ->endif
      ->line('    conn->pending_method_len = 0;')
      ->line('    conn->pending_path_len = 0;')
      ->line('    conn->pending_body_len = 0;')
      ->line('    return 0;')
      ->line('}')
      ->blank;
    
    return $builder;
}

# Generate HTTP/2 session initialization
sub gen_session_init {
    my ($class, $builder) = @_;
    
    $builder->comment('HTTP/2: Initialize nghttp2 callbacks (once)')
      ->line('static nghttp2_session_callbacks* g_h2_callbacks = NULL;')
      ->blank
      ->line('static void init_h2_callbacks(void) {')
      ->if('g_h2_callbacks')
        ->line('return;')
      ->endif
      ->line('    nghttp2_session_callbacks_new(&g_h2_callbacks);')
      ->line('    nghttp2_session_callbacks_set_send_callback(g_h2_callbacks, h2_send_cb);')
      ->line('    nghttp2_session_callbacks_set_on_header_callback(g_h2_callbacks, h2_on_header_cb);')
      ->line('    nghttp2_session_callbacks_set_on_data_chunk_recv_callback(g_h2_callbacks, h2_on_data_chunk_cb);')
      ->line('    nghttp2_session_callbacks_set_on_frame_recv_callback(g_h2_callbacks, h2_on_frame_recv_cb);')
      ->line('    nghttp2_session_callbacks_set_on_stream_close_callback(g_h2_callbacks, h2_on_stream_close_cb);')
      ->line('}')
      ->blank
      ->line('static int init_h2_session(H2Connection* conn) {')
      ->line('    init_h2_callbacks();')
      ->blank
      ->line('    int rv = nghttp2_session_server_new(&conn->session, g_h2_callbacks, conn);')
      ->if('rv != 0')
        ->line('return -1;')
      ->endif
      ->blank
      ->comment('Send server settings')
      ->line('    nghttp2_settings_entry settings[] = {')
      ->line('        { NGHTTP2_SETTINGS_MAX_CONCURRENT_STREAMS, 100 },')
      ->line('        { NGHTTP2_SETTINGS_INITIAL_WINDOW_SIZE, 65535 },')
      ->line('    };')
      ->line('    rv = nghttp2_submit_settings(conn->session, NGHTTP2_FLAG_NONE,')
      ->line('                                  settings, sizeof(settings)/sizeof(settings[0]));')
      ->if('rv != 0')
        ->line('nghttp2_session_del(conn->session);')
        ->line('conn->session = NULL;')
        ->line('return -1;')
      ->endif
      ->blank
      ->comment('Send settings immediately')
      ->line('    nghttp2_session_send(conn->session);')
      ->line('    conn->protocol = PROTO_HTTP2;')
      ->line('    return 0;')
      ->line('}')
      ->blank;
    
    return $builder;
}

# Generate HTTP/2 request dispatcher
sub gen_dispatcher {
    my ($class, $builder, %opts) = @_;
    
    $builder->comment('HTTP/2: Dispatch request and send response')
      ->line('static void h2_dispatch_request(nghttp2_session* session,')
      ->line('                                H2Connection* conn, int32_t stream_id) {')
      ->if('!conn->pending_method || !conn->pending_path')
        ->line('return;')
      ->endif
      ->blank
      ->comment('Strip query string for route matching')
      ->line('    const char* query_pos = memchr(conn->pending_path, \'?\', conn->pending_path_len);')
      ->line('    int path_len = query_pos ? (query_pos - conn->pending_path) : conn->pending_path_len;')
      ->blank
      ->comment('Dispatch to route handler')
      ->line('    const char* resp;')
      ->line('    int resp_len;')
      ->line('    int handler_idx;')
      ->line('    int result = dispatch_request(conn->pending_method, conn->pending_method_len,')
      ->line('                                  conn->pending_path, path_len,')
      ->line('                                  &resp, &resp_len, &handler_idx);')
      ->blank
      ->comment('Build HTTP/2 response')
      ->if('result == 0')
        ->comment('Static route - parse prebuilt HTTP/1.1 response')
        ->line('h2_send_static_response(session, stream_id, resp, resp_len);')
      ->elsif('result == 1')
        ->comment('Dynamic route - call Perl handler')
        ->line('h2_call_dynamic_handler(session, conn, stream_id, handler_idx);')
      ->else
        ->comment('404')
        ->line('h2_send_404(session, stream_id);')
      ->endif
      ->line('}')
      ->blank;
    
    return $builder;
}

# Generate HTTP/2 response sender
sub gen_response_sender {
    my ($class, $builder) = @_;
    
    $builder->comment('HTTP/2: Send static response')
      ->line('static void h2_send_static_response(nghttp2_session* session,')
      ->line('                                     int32_t stream_id,')
      ->line('                                     const char* http1_resp, int resp_len) {')
      ->line('    /* Parse HTTP/1.1 response to extract status and body */')
      ->line('    /* Format: HTTP/1.1 200 OK\\r\\nContent-Type: ...\\r\\n\\r\\nbody */')
      ->line('    ')
      ->line('    /* Find status code */')
      ->line('    int status = 200;')
      ->line('    if (resp_len > 12 && memcmp(http1_resp, "HTTP/1.1 ", 9) == 0) {')
      ->line('        status = (http1_resp[9] - \'0\') * 100 + ')
      ->line('                 (http1_resp[10] - \'0\') * 10 + ')
      ->line('                 (http1_resp[11] - \'0\');')
      ->line('    }')
      ->line('    ')
      ->line('    /* Find body (after \\r\\n\\r\\n) */')
      ->line('    const char* body = strstr(http1_resp, "\\r\\n\\r\\n");')
      ->line('    int body_len = 0;')
      ->line('    if (body) {')
      ->line('        body += 4;')
      ->line('        body_len = resp_len - (body - http1_resp);')
      ->line('    } else {')
      ->line('        body = "";')
      ->line('    }')
      ->line('    ')
      ->line('    /* Find Content-Type */')
      ->line('    const char* ct = "text/plain";')
      ->line('    const char* ct_hdr = strstr(http1_resp, "Content-Type: ");')
      ->line('    static char ct_buf[64];')
      ->line('    if (ct_hdr) {')
      ->line('        ct_hdr += 14;')
      ->line('        const char* ct_end = strstr(ct_hdr, "\\r\\n");')
      ->line('        if (ct_end && ct_end - ct_hdr < 63) {')
      ->line('            memcpy(ct_buf, ct_hdr, ct_end - ct_hdr);')
      ->line('            ct_buf[ct_end - ct_hdr] = \'\\0\';')
      ->line('            ct = ct_buf;')
      ->line('        }')
      ->line('    }')
      ->line('    ')
      ->line('    /* Build content-length string */')
      ->line('    char cl_buf[16];')
      ->line('    snprintf(cl_buf, sizeof(cl_buf), "%d", body_len);')
      ->line('    ')
      ->line('    /* Build status string */')
      ->line('    char status_buf[4];')
      ->line('    snprintf(status_buf, sizeof(status_buf), "%d", status);')
      ->line('    ')
      ->line('    /* Submit HTTP/2 response headers */')
      ->line('    nghttp2_nv hdrs[] = {')
      ->line('        { (uint8_t*)":status", (uint8_t*)status_buf, 7, strlen(status_buf), NGHTTP2_NV_FLAG_NONE },')
      ->line('        { (uint8_t*)"content-type", (uint8_t*)ct, 12, strlen(ct), NGHTTP2_NV_FLAG_NONE },')
      ->line('        { (uint8_t*)"content-length", (uint8_t*)cl_buf, 14, strlen(cl_buf), NGHTTP2_NV_FLAG_NONE },')
      ->line('    };')
      ->line('    ')
      ->line('    /* Create data provider for body */')
      ->line('    nghttp2_data_provider data_prd;')
      ->line('    data_prd.source.ptr = (void*)body;')
      ->line('    data_prd.read_callback = h2_data_source_read_cb;')
      ->line('    ')
      ->line('    nghttp2_submit_response(session, stream_id, hdrs, 3, &data_prd);')
      ->line('    nghttp2_session_send(session);')
      ->line('}')
      ->blank
      ->comment('HTTP/2: Data source read callback for response body')
      ->line('static ssize_t h2_data_source_read_cb(nghttp2_session* session,')
      ->line('                                       int32_t stream_id,')
      ->line('                                       uint8_t* buf, size_t length,')
      ->line('                                       uint32_t* data_flags,')
      ->line('                                       nghttp2_data_source* source,')
      ->line('                                       void* user_data) {')
      ->line('    (void)session; (void)stream_id; (void)user_data;')
      ->line('    const char* body = (const char*)source->ptr;')
      ->line('    size_t body_len = strlen(body);')
      ->line('    ')
      ->line('    if (body_len == 0) {')
      ->line('        *data_flags |= NGHTTP2_DATA_FLAG_EOF;')
      ->line('        return 0;')
      ->line('    }')
      ->line('    ')
      ->line('    size_t copy_len = (length < body_len) ? length : body_len;')
      ->line('    memcpy(buf, body, copy_len);')
      ->line('    ')
      ->line('    /* Update source pointer for next read */')
      ->line('    source->ptr = (void*)(body + copy_len);')
      ->line('    ')
      ->line('    if (copy_len == body_len) {')
      ->line('        *data_flags |= NGHTTP2_DATA_FLAG_EOF;')
      ->line('    }')
      ->line('    ')
      ->line('    return copy_len;')
      ->line('}')
      ->blank;
    
    return $builder;
}

# Generate 404 response for HTTP/2
sub gen_404_response {
    my ($class, $builder) = @_;
    
    $builder->comment('HTTP/2: Send 404 response')
      ->line('static void h2_send_404(nghttp2_session* session, int32_t stream_id) {')
      ->line('    static const char* body = "Not Found";')
      ->line('    ')
      ->line('    nghttp2_nv hdrs[] = {')
      ->line('        { (uint8_t*)":status", (uint8_t*)"404", 7, 3, NGHTTP2_NV_FLAG_NONE },')
      ->line('        { (uint8_t*)"content-type", (uint8_t*)"text/plain", 12, 10, NGHTTP2_NV_FLAG_NONE },')
      ->line('        { (uint8_t*)"content-length", (uint8_t*)"9", 14, 1, NGHTTP2_NV_FLAG_NONE },')
      ->line('    };')
      ->line('    ')
      ->line('    nghttp2_data_provider data_prd;')
      ->line('    data_prd.source.ptr = (void*)body;')
      ->line('    data_prd.read_callback = h2_data_source_read_cb;')
      ->line('    ')
      ->line('    nghttp2_submit_response(session, stream_id, hdrs, 3, &data_prd);')
      ->line('    nghttp2_session_send(session);')
      ->line('}')
      ->blank;
    
    return $builder;
}

# Generate HTTP/2 input processing
sub gen_input_processor {
    my ($class, $builder) = @_;
    
    $builder->comment('HTTP/2: Process incoming data from socket')
      ->line('static int h2_process_input(H2Connection* conn, const uint8_t* data, size_t len) {')
      ->line('    ssize_t rv = nghttp2_session_mem_recv(conn->session, data, len);')
      ->line('    if (rv < 0) {')
      ->line('        return -1;  /* Protocol error */')
      ->line('    }')
      ->line('    ')
      ->line('    /* Send any pending frames */')
      ->line('    rv = nghttp2_session_send(conn->session);')
      ->line('    if (rv != 0) {')
      ->line('        return -1;')
      ->line('    }')
      ->line('    ')
      ->line('    return 0;')
      ->line('}')
      ->blank;
    
    return $builder;
}

# Generate HTTP/2 connection detection (for h2c upgrade or ALPN)
sub gen_connection_preface_check {
    my ($class, $builder) = @_;
    
    $builder->comment('HTTP/2: Check for connection preface (h2c)')
      ->line('static const char H2_PREFACE[] = "PRI * HTTP/2.0\\r\\n\\r\\nSM\\r\\n\\r\\n";')
      ->line('#define H2_PREFACE_LEN 24')
      ->blank
      ->line('static int is_h2_preface(const char* data, size_t len) {')
      ->line('    return len >= H2_PREFACE_LEN && memcmp(data, H2_PREFACE, H2_PREFACE_LEN) == 0;')
      ->line('}')
      ->blank;
    
    return $builder;
}

# ============================================================
# HTTP/2 Streaming Support (Phase 3)
# ============================================================

# Generate streaming headers without END_STREAM
sub gen_stream_headers {
    my ($class, $builder) = @_;
    
    $builder->comment('HTTP/2 Streaming: Send HEADERS without END_STREAM (allows more DATA)')
      ->line('static int h2_stream_headers(nghttp2_session* session, int32_t stream_id,')
      ->line('                              int status, const char* content_type) {')
      ->line('    char status_str[4];')
      ->line('    snprintf(status_str, sizeof(status_str), "%d", status);')
      ->line('    ')
      ->line('    nghttp2_nv hdrs[] = {')
      ->line('        { (uint8_t*)":status", (uint8_t*)status_str, 7, strlen(status_str), NGHTTP2_NV_FLAG_NONE },')
      ->line('        { (uint8_t*)"content-type", (uint8_t*)content_type, 12, strlen(content_type), NGHTTP2_NV_FLAG_NONE },')
      ->line('    };')
      ->line('    ')
      ->line('    /* Submit headers WITHOUT END_STREAM - more DATA frames to come */')
      ->line('    int rv = nghttp2_submit_headers(session, NGHTTP2_FLAG_END_HEADERS,')
      ->line('                                     stream_id, NULL, hdrs, 2, NULL);')
      ->line('    if (rv < 0) return rv;')
      ->line('    ')
      ->line('    return nghttp2_session_send(session);')
      ->line('}')
      ->blank;
    
    return $builder;
}

# Generate streaming data chunk sender
sub gen_stream_data {
    my ($class, $builder) = @_;
    
    $builder->comment('HTTP/2 Streaming: Chunk provider for streaming DATA frames')
      ->line('typedef struct {')
      ->line('    const uint8_t* data;')
      ->line('    size_t length;')
      ->line('    size_t pos;')
      ->line('} H2ChunkProvider;')
      ->blank
      ->line('static ssize_t h2_chunk_read_cb(nghttp2_session* session,')
      ->line('                                 int32_t stream_id,')
      ->line('                                 uint8_t* buf, size_t length,')
      ->line('                                 uint32_t* data_flags,')
      ->line('                                 nghttp2_data_source* source,')
      ->line('                                 void* user_data) {')
      ->line('    (void)session; (void)stream_id; (void)user_data;')
      ->line('    H2ChunkProvider* provider = (H2ChunkProvider*)source->ptr;')
      ->line('    size_t remaining = provider->length - provider->pos;')
      ->line('    size_t to_copy = remaining < length ? remaining : length;')
      ->line('    ')
      ->line('    memcpy(buf, provider->data + provider->pos, to_copy);')
      ->line('    provider->pos += to_copy;')
      ->line('    ')
      ->line('    if (provider->pos >= provider->length) {')
      ->line('        /* This DATA frame is complete (but not end of stream) */')
      ->line('        *data_flags |= NGHTTP2_DATA_FLAG_EOF;')
      ->line('    }')
      ->line('    ')
      ->line('    return (ssize_t)to_copy;')
      ->line('}')
      ->blank
      ->comment('HTTP/2 Streaming: Send a single DATA frame (not final)')
      ->line('static int h2_stream_data(nghttp2_session* session, int32_t stream_id,')
      ->line('                           const uint8_t* data, size_t len) {')
      ->line('    /* Allocate provider on stack - nghttp2 copies data synchronously */')
      ->line('    H2ChunkProvider provider = { data, len, 0 };')
      ->line('    ')
      ->line('    nghttp2_data_provider data_prd;')
      ->line('    data_prd.source.ptr = &provider;')
      ->line('    data_prd.read_callback = h2_chunk_read_cb;')
      ->line('    ')
      ->line('    /* Submit DATA without END_STREAM */')
      ->line('    int rv = nghttp2_submit_data(session, NGHTTP2_FLAG_NONE,')
      ->line('                                  stream_id, &data_prd);')
      ->line('    if (rv < 0) return rv;')
      ->line('    ')
      ->line('    return nghttp2_session_send(session);')
      ->line('}')
      ->blank;
    
    return $builder;
}

# Generate stream end (empty DATA with END_STREAM)
sub gen_stream_end {
    my ($class, $builder) = @_;
    
    $builder->comment('HTTP/2 Streaming: Send empty DATA with END_STREAM flag')
      ->line('static int h2_stream_end(nghttp2_session* session, int32_t stream_id) {')
      ->line('    /* Submit empty data with END_STREAM flag */')
      ->line('    nghttp2_data_provider data_prd;')
      ->line('    data_prd.source.ptr = NULL;')
      ->line('    data_prd.read_callback = NULL;')
      ->line('    ')
      ->line('    int rv = nghttp2_submit_data(session, NGHTTP2_FLAG_END_STREAM,')
      ->line('                                  stream_id, NULL);')
      ->line('    if (rv < 0) return rv;')
      ->line('    ')
      ->line('    return nghttp2_session_send(session);')
      ->line('}')
      ->blank;
    
    return $builder;
}

# Generate flow control helpers
sub gen_flow_control {
    my ($class, $builder) = @_;
    
    $builder->comment('HTTP/2 Streaming: Check flow control window')
      ->line('static int h2_can_send(nghttp2_session* session, int32_t stream_id, size_t len) {')
      ->line('    /* Check connection-level window */')
      ->line('    int32_t conn_window = nghttp2_session_get_remote_window_size(session);')
      ->line('    if (conn_window < (int32_t)len) return 0;')
      ->line('    ')
      ->line('    /* Check stream-level window */')
      ->line('    int32_t stream_window = nghttp2_session_get_stream_remote_window_size(')
      ->line('        session, stream_id);')
      ->line('    if (stream_window < (int32_t)len) return 0;')
      ->line('    ')
      ->line('    return 1;')
      ->line('}')
      ->blank
      ->comment('HTTP/2 Streaming: Get available window size')
      ->line('static int32_t h2_window_size(nghttp2_session* session, int32_t stream_id) {')
      ->line('    int32_t conn_window = nghttp2_session_get_remote_window_size(session);')
      ->line('    int32_t stream_window = nghttp2_session_get_stream_remote_window_size(')
      ->line('        session, stream_id);')
      ->line('    return conn_window < stream_window ? conn_window : stream_window;')
      ->line('}')
      ->blank;
    
    return $builder;
}

# Generate XS wrappers for HTTP/2 streaming from Perl
sub gen_stream_xs_wrappers {
    my ($class, $builder) = @_;
    
    $builder->comment('XS wrappers for HTTP/2 streaming from Perl');
    
    # h2_stream_start(session_ptr, stream_id, status, content_type)
    $builder->xs_function('hypersonic_h2_stream_start')
      ->xs_preamble
      ->check_items(4, 4, 'session_ptr, stream_id, status, content_type')
      ->line('nghttp2_session* session = (nghttp2_session*)SvUV(ST(0));')
      ->line('int32_t stream_id = (int32_t)SvIV(ST(1));')
      ->line('int status = (int)SvIV(ST(2));')
      ->line('STRLEN ct_len;')
      ->line('const char* content_type = SvPV(ST(3), ct_len);')
      ->line('int rv = h2_stream_headers(session, stream_id, status, content_type);')
      ->line('XSRETURN_IV(rv);')
      ->xs_end
      ->blank;
    
    # h2_stream_write(session_ptr, stream_id, data)
    $builder->xs_function('hypersonic_h2_stream_write')
      ->xs_preamble
      ->check_items(3, 3, 'session_ptr, stream_id, data')
      ->line('nghttp2_session* session = (nghttp2_session*)SvUV(ST(0));')
      ->line('int32_t stream_id = (int32_t)SvIV(ST(1));')
      ->line('STRLEN data_len;')
      ->line('const char* data = SvPV(ST(2), data_len);')
      ->line('int rv = h2_stream_data(session, stream_id, (const uint8_t*)data, data_len);')
      ->line('XSRETURN_IV(rv);')
      ->xs_end
      ->blank;
    
    # h2_stream_end(session_ptr, stream_id)
    $builder->xs_function('hypersonic_h2_stream_end')
      ->xs_preamble
      ->check_items(2, 2, 'session_ptr, stream_id')
      ->line('nghttp2_session* session = (nghttp2_session*)SvUV(ST(0));')
      ->line('int32_t stream_id = (int32_t)SvIV(ST(1));')
      ->line('int rv = h2_stream_end(session, stream_id);')
      ->line('XSRETURN_IV(rv);')
      ->xs_end
      ->blank;
    
    return $builder;
}

# Generate all HTTP/2 streaming code
sub generate_streaming {
    my ($class, $builder, $opts) = @_;
    
    $class->gen_stream_headers($builder);
    $class->gen_stream_data($builder);
    $class->gen_stream_end($builder);
    $class->gen_flow_control($builder);
    $class->gen_stream_xs_wrappers($builder);
    
    return $builder;
}

1;

__END__

=head1 NAME

Hypersonic::Protocol::HTTP2 - JIT code generation for HTTP/2 protocol

=head1 SYNOPSIS

    use Hypersonic::Protocol::HTTP2;
    
    # Check if nghttp2 is available
    if (Hypersonic::Protocol::HTTP2->check_nghttp2()) {
        my $cflags = Hypersonic::Protocol::HTTP2->get_extra_cflags();
        my $ldflags = Hypersonic::Protocol::HTTP2->get_extra_ldflags();
    }
    
    # Generate HTTP/2 C code
    Hypersonic::Protocol::HTTP2->gen_includes($builder);
    Hypersonic::Protocol::HTTP2->gen_callbacks($builder);

=head1 DESCRIPTION

This module provides JIT compile-time code generation for HTTP/2 protocol
support using the nghttp2 library. All methods generate C code using
XS::JIT::Builder - there is zero runtime overhead.

=head2 HTTP/2 Features

=over 4

=item * Binary framing via nghttp2

=item * HPACK header compression

=item * Stream multiplexing

=item * Server push (future)

=back

=head1 AUTHOR

Hypersonic Contributors

=cut
