package Hypersonic::Stream;
use strict;
use warnings;
use 5.010;

our $VERSION = '0.12';

use constant {
    STATE_INIT     => 0,
    STATE_STARTED  => 1,
    STATE_FINISHED => 2,
    STATE_ABORTED  => 3,
};
use constant MAX_STREAMS => 65536;

# Class method for streaming handler detection (only Perl code needed)
sub is_streaming_handler {
    my ($class, $handler, $opts) = @_;
    return 1 if $opts && $opts->{streaming};
    my $proto = prototype($handler);
    return 1 if defined $proto && $proto =~ /stream/i;
    eval {
        require B::Deparse;
        my $deparser = B::Deparse->new('-p', '-sC');
        my $code = $deparser->coderef2text($handler);
        return 1 if $code =~ /\$stream\s*->/;
    };
    return 0;
}

# ============================================================
# XS Code Generation - ALL instance methods generated in C
# ============================================================

sub generate_c_code {
    my ($class, $builder, $opts) = @_;
    $opts //= {};
    my $max = $opts->{max_streams} // MAX_STREAMS;
    
    $builder->line('#include <sys/uio.h>')
      ->blank;
    
    $class->gen_stream_registry($builder, $max);
    $class->gen_status_text($builder);
    $class->gen_stream_start_c($builder);
    $class->gen_stream_write_chunk_c($builder);
    $class->gen_stream_end_c($builder);
    $class->gen_stream_reset_c($builder);
    
    # XS instance methods
    $class->gen_xs_new($builder);
    $class->gen_xs_fd($builder);
    $class->gen_xs_protocol($builder);
    $class->gen_xs_state($builder);
    $class->gen_xs_chunks_sent($builder);
    $class->gen_xs_is_started($builder);
    $class->gen_xs_is_finished($builder);
    $class->gen_xs_headers($builder);
    $class->gen_xs_content_type($builder);
    $class->gen_xs_write($builder);
    $class->gen_xs_end($builder);
    $class->gen_xs_abort($builder);
    
    return $builder;
}

sub gen_stream_registry {
    my ($class, $builder, $max) = @_;
    
    $builder->comment('Stream registry - O(1) lookup by fd')
      ->line('#define STREAM_MAX ' . $max)
      ->line('#define STREAM_STATE_INIT     0')
      ->line('#define STREAM_STATE_STARTED  1')
      ->line('#define STREAM_STATE_FINISHED 2')
      ->line('#define STREAM_STATE_ABORTED  3')
      ->blank
      ->line('typedef struct {')
      ->line('    int state;')
      ->line('    int chunks_sent;')
      ->line('    int http2;')
      ->line('    int status;')
      ->line('    char content_type[128];')
      ->line('    char extra_headers[512];')  # For Cache-Control, X-Accel-Buffering, etc.
      ->line('} StreamState;')
      ->blank
      ->line('static StreamState stream_registry[STREAM_MAX];')
      ->blank;
}

sub gen_status_text {
    my ($class, $builder) = @_;
    
    $builder->line('static const char* stream_status_text(int status) {')
      ->line('    switch(status) {')
      ->line('        case 200: return "OK";')
      ->line('        case 201: return "Created";')
      ->line('        case 204: return "No Content";')
      ->line('        case 400: return "Bad Request";')
      ->line('        case 404: return "Not Found";')
      ->line('        case 500: return "Internal Server Error";')
      ->line('        default: return "OK";')
      ->line('    }')
      ->line('}')
      ->blank;
}

sub gen_stream_start_c {
    my ($class, $builder) = @_;
    
    $builder->line('static void stream_start_http1(int fd) {')
      ->line('    StreamState* s = &stream_registry[fd];')
      ->line('    char headers[2048];')
      ->line('    int len = snprintf(headers, sizeof(headers),')
      ->line('        "HTTP/1.1 %d %s\\r\\n"')
      ->line('        "Content-Type: %s\\r\\n"')
      ->line('        "%s"')  # Extra headers (Cache-Control, etc.)
      ->line('        "Transfer-Encoding: chunked\\r\\n"')
      ->line('        "Connection: keep-alive\\r\\n\\r\\n",')
      ->line('        s->status, stream_status_text(s->status), s->content_type, s->extra_headers);')
      ->line('    send(fd, headers, len, 0);')
      ->line('    s->state = STREAM_STATE_STARTED;')
      ->line('    s->chunks_sent = 0;')
      ->line('}')
      ->blank;
}

sub gen_stream_write_chunk_c {
    my ($class, $builder) = @_;
    
    $builder->line('static void stream_write_chunk_http1(int fd, const char* data, size_t len) {')
      ->line('    if (len == 0) return;')
      ->line('    char size_line[32];')
      ->line('    int header_len = snprintf(size_line, sizeof(size_line), "%zx\\r\\n", len);')
      ->line('    struct iovec iov[3];')
      ->line('    iov[0].iov_base = size_line;')
      ->line('    iov[0].iov_len = header_len;')
      ->line('    iov[1].iov_base = (void*)data;')
      ->line('    iov[1].iov_len = len;')
      ->line('    iov[2].iov_base = "\\r\\n";')
      ->line('    iov[2].iov_len = 2;')
      ->line('    writev(fd, iov, 3);')
      ->line('    stream_registry[fd].chunks_sent++;')
      ->line('}')
      ->blank;
}

sub gen_stream_end_c {
    my ($class, $builder) = @_;
    
    $builder->line('static void stream_end_http1(int fd) {')
      ->line('    send(fd, "0\\r\\n\\r\\n", 5, 0);')
      ->line('    stream_registry[fd].state = STREAM_STATE_FINISHED;')
      ->line('}')
      ->blank;
}

sub gen_stream_reset_c {
    my ($class, $builder) = @_;
    
    $builder->line('static void stream_reset(int fd) {')
      ->line('    memset(&stream_registry[fd], 0, sizeof(StreamState));')
      ->line('    stream_registry[fd].status = 200;')
      ->line('    strcpy(stream_registry[fd].content_type, "text/plain");')
      ->line('}')
      ->blank;
}

# XS: new(fd => N, protocol => P) - returns blessed scalar
sub gen_xs_new {
    my ($class, $builder) = @_;
    
    $builder->xs_function('xs_stream_new')
      ->xs_preamble
      ->line('int fd = -1;')
      ->line('int http2 = 0;')
      ->line('STRLEN klen;')
      ->line('const char* key;')
      ->line('STRLEN plen;')
      ->line('const char* proto;')
      ->line('SV* fd_sv;')
      ->line('SV* ref;')
      ->blank
      ->comment('Parse hash args: new(fd => N) or new(fd => N, protocol => P)')
      ->for('int i = 1', 'i < items', 'i += 2')
        ->if('i + 1 < items')
          ->line('key = SvPV(ST(i), klen);')
          ->if('klen == 2 && strncmp(key, "fd", 2) == 0')
            ->line('fd = SvIV(ST(i + 1));')
          ->endif
          ->if('klen == 8 && strncmp(key, "protocol", 8) == 0')
            ->line('proto = SvPV(ST(i + 1), plen);')
            ->if('plen == 5 && strncmp(proto, "http2", 5) == 0')
              ->line('http2 = 1;')
            ->endif
          ->endif
        ->endif
      ->endfor
      ->blank
      ->if('fd < 0 || fd >= STREAM_MAX')
        ->line('croak("Invalid fd: %d", fd);')
      ->endif
      ->blank
      ->line('stream_reset(fd);')
      ->line('stream_registry[fd].http2 = http2;')
      ->blank
      ->line('fd_sv = newSViv(fd);')
      ->line('ref = newRV_noinc(fd_sv);')
      ->line('sv_bless(ref, gv_stashpv("Hypersonic::Stream", GV_ADD));')
      ->line('ST(0) = sv_2mortal(ref);')
      ->line('XSRETURN(1);')
      ->xs_end
      ->blank;
}

sub gen_xs_fd {
    my ($class, $builder) = @_;
    
    $builder->xs_function('xs_stream_fd')
      ->xs_preamble
      ->check_items(1, 1, '$stream->fd')
      ->line('XSRETURN_IV(SvIV(SvRV(ST(0))));')
      ->xs_end
      ->blank;
}

sub gen_xs_protocol {
    my ($class, $builder) = @_;
    
    $builder->xs_function('xs_stream_protocol')
      ->xs_preamble
      ->check_items(1, 1, '$stream->protocol')
      ->line('int fd = SvIV(SvRV(ST(0)));')
      ->if('stream_registry[fd].http2')
        ->line('XSRETURN_PV("http2");')
      ->else
        ->line('XSRETURN_PV("http1");')
      ->endif
      ->xs_end
      ->blank;
}

sub gen_xs_state {
    my ($class, $builder) = @_;
    
    $builder->xs_function('xs_stream_state')
      ->xs_preamble
      ->check_items(1, 1, '$stream->state')
      ->line('int fd = SvIV(SvRV(ST(0)));')
      ->if('fd < 0 || fd >= STREAM_MAX')
        ->line('XSRETURN_IV(0);')
      ->endif
      ->line('XSRETURN_IV(stream_registry[fd].state);')
      ->xs_end
      ->blank;
}

sub gen_xs_chunks_sent {
    my ($class, $builder) = @_;
    
    $builder->xs_function('xs_stream_chunks_sent')
      ->xs_preamble
      ->check_items(1, 1, '$stream->chunks_sent')
      ->line('int fd = SvIV(SvRV(ST(0)));')
      ->if('fd < 0 || fd >= STREAM_MAX')
        ->line('XSRETURN_IV(0);')
      ->endif
      ->line('XSRETURN_IV(stream_registry[fd].chunks_sent);')
      ->xs_end
      ->blank;
}

sub gen_xs_is_started {
    my ($class, $builder) = @_;
    
    $builder->xs_function('xs_stream_is_started')
      ->xs_preamble
      ->check_items(1, 1, '$stream->is_started')
      ->line('int fd = SvIV(SvRV(ST(0)));')
      ->if('stream_registry[fd].state >= STREAM_STATE_STARTED')
        ->line('XSRETURN_YES;')
      ->else
        ->line('XSRETURN_NO;')
      ->endif
      ->xs_end
      ->blank;
}

sub gen_xs_is_finished {
    my ($class, $builder) = @_;
    
    $builder->xs_function('xs_stream_is_finished')
      ->xs_preamble
      ->check_items(1, 1, '$stream->is_finished')
      ->line('int fd = SvIV(SvRV(ST(0)));')
      ->if('stream_registry[fd].state >= STREAM_STATE_FINISHED')
        ->line('XSRETURN_YES;')
      ->else
        ->line('XSRETURN_NO;')
      ->endif
      ->xs_end
      ->blank;
}

sub gen_xs_headers {
    my ($class, $builder) = @_;
    
    $builder->xs_function('xs_stream_headers')
      ->xs_preamble
      ->line('int fd = SvIV(SvRV(ST(0)));')
      ->line('StreamState* s = &stream_registry[fd];')
      ->blank
      ->if('s->state != STREAM_STATE_INIT')
        ->line('croak("Cannot set headers after streaming started");')
      ->endif
      ->blank
      ->if('items >= 2')
        ->line('s->status = SvIV(ST(1));')
      ->endif
      ->blank
      ->line('s->extra_headers[0] = \'\\0\';')
      ->if('items >= 3 && SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) == SVt_PVHV')
        ->line('HV* hv = (HV*)SvRV(ST(2));')
        ->line('int extra_pos = 0;')
        ->blank
        ->comment('Extract Content-Type')
        ->line('SV** ct = hv_fetchs(hv, "Content-Type", 0);')
        ->if('!ct')
          ->line('ct = hv_fetchs(hv, "content-type", 0);')
        ->endif
        ->if('ct && *ct')
          ->line('STRLEN len;')
          ->line('const char* val = SvPV(*ct, len);')
          ->if('len < sizeof(s->content_type)')
            ->line('memcpy(s->content_type, val, len);')
            ->line('s->content_type[len] = \'\\0\';')
          ->endif
        ->endif
        ->blank
        ->comment('Extract other headers (Cache-Control, Connection, X-Accel-Buffering)')
        ->line('SV** cc = hv_fetchs(hv, "Cache-Control", 0);')
        ->if('cc && *cc')
          ->line('STRLEN len;')
          ->line('const char* val = SvPV(*cc, len);')
          ->line('extra_pos += snprintf(s->extra_headers + extra_pos,')
          ->line('    sizeof(s->extra_headers) - extra_pos, "Cache-Control: %s\\r\\n", val);')
        ->endif
        ->line('SV** conn = hv_fetchs(hv, "Connection", 0);')
        ->if('conn && *conn')
          ->line('STRLEN len;')
          ->line('const char* val = SvPV(*conn, len);')
          ->line('extra_pos += snprintf(s->extra_headers + extra_pos,')
          ->line('    sizeof(s->extra_headers) - extra_pos, "Connection: %s\\r\\n", val);')
        ->endif
        ->line('SV** xab = hv_fetchs(hv, "X-Accel-Buffering", 0);')
        ->if('xab && *xab')
          ->line('STRLEN len;')
          ->line('const char* val = SvPV(*xab, len);')
          ->line('extra_pos += snprintf(s->extra_headers + extra_pos,')
          ->line('    sizeof(s->extra_headers) - extra_pos, "X-Accel-Buffering: %s\\r\\n", val);')
        ->endif
      ->endif
      ->blank
      ->line('ST(0) = ST(0);')
      ->line('XSRETURN(1);')
      ->xs_end
      ->blank;
}

sub gen_xs_content_type {
    my ($class, $builder) = @_;
    
    $builder->xs_function('xs_stream_content_type')
      ->xs_preamble
      ->if('items != 2')
        ->line('croak("Usage: $stream->content_type(type)");')
      ->endif
      ->line('int fd = SvIV(SvRV(ST(0)));')
      ->line('StreamState* s = &stream_registry[fd];')
      ->blank
      ->if('s->state != STREAM_STATE_INIT')
        ->line('croak("Cannot set content_type after streaming started");')
      ->endif
      ->blank
      ->line('STRLEN len;')
      ->line('const char* ct = SvPV(ST(1), len);')
      ->if('len < sizeof(s->content_type)')
        ->line('memcpy(s->content_type, ct, len);')
        ->line('s->content_type[len] = \'\\0\';')
      ->endif
      ->blank
      ->line('ST(0) = ST(0);')
      ->line('XSRETURN(1);')
      ->xs_end
      ->blank;
}

sub gen_xs_write {
    my ($class, $builder) = @_;
    
    $builder->xs_function('xs_stream_write')
      ->xs_preamble
      ->if('items != 2')
        ->line('croak("Usage: $stream->write(data)");')
      ->endif
      ->line('int fd = SvIV(SvRV(ST(0)));')
      ->line('StreamState* s = &stream_registry[fd];')
      ->blank
      ->line('STRLEN len;')
      ->line('const char* data = SvPV(ST(1), len);')
      ->if('len == 0')
        ->line('ST(0) = ST(0);')
        ->line('XSRETURN(1);')
      ->endif
      ->blank
      ->if('s->state == STREAM_STATE_INIT && !s->http2')
        ->line('stream_start_http1(fd);')
      ->endif
      ->blank
      ->if('!s->http2')
        ->line('stream_write_chunk_http1(fd, data, len);')
      ->endif
      ->blank
      ->line('ST(0) = ST(0);')
      ->line('XSRETURN(1);')
      ->xs_end
      ->blank;
}

sub gen_xs_end {
    my ($class, $builder) = @_;
    
    $builder->xs_function('xs_stream_end')
      ->xs_preamble
      ->line('int fd = SvIV(SvRV(ST(0)));')
      ->line('StreamState* s = &stream_registry[fd];')
      ->blank
      ->if('s->state >= STREAM_STATE_FINISHED')
        ->line('ST(0) = ST(0);')
        ->line('XSRETURN(1);')
      ->endif
      ->blank
      ->if('items >= 2 && SvOK(ST(1))')
        ->line('STRLEN len;')
        ->line('const char* data = SvPV(ST(1), len);')
        ->if('len > 0')
          ->if('s->state == STREAM_STATE_INIT && !s->http2')
            ->line('stream_start_http1(fd);')
          ->endif
          ->if('!s->http2')
            ->line('stream_write_chunk_http1(fd, data, len);')
          ->endif
        ->endif
      ->endif
      ->blank
      ->if('s->state == STREAM_STATE_INIT && !s->http2')
        ->line('stream_start_http1(fd);')
      ->endif
      ->blank
      ->if('!s->http2')
        ->line('stream_end_http1(fd);')
      ->endif
      ->blank
      ->line('ST(0) = ST(0);')
      ->line('XSRETURN(1);')
      ->xs_end
      ->blank;
}

sub gen_xs_abort {
    my ($class, $builder) = @_;
    
    $builder->xs_function('xs_stream_abort')
      ->xs_preamble
      ->line('int fd = SvIV(SvRV(ST(0)));')
      ->line('StreamState* s = &stream_registry[fd];')
      ->line('int code = items >= 2 ? SvIV(ST(1)) : 500;')
      ->line('const char* reason = items >= 3 ? SvPV_nolen(ST(2)) : "Internal Server Error";')
      ->blank
      ->if('s->state == STREAM_STATE_INIT && !s->http2')
        ->line('s->status = code;')
        ->line('stream_start_http1(fd);')
        ->line('stream_write_chunk_http1(fd, reason, strlen(reason));')
      ->endif
      ->blank
      ->if('!s->http2')
        ->line('stream_end_http1(fd);')
      ->endif
      ->line('s->state = STREAM_STATE_ABORTED;')
      ->blank
      ->line('ST(0) = ST(0);')
      ->line('XSRETURN(1);')
      ->xs_end
      ->blank;
}


sub get_xs_functions {
    return {
        'Hypersonic::Stream::new'          => { source => 'xs_stream_new', is_xs_native => 1 },
        'Hypersonic::Stream::fd'           => { source => 'xs_stream_fd', is_xs_native => 1 },
        'Hypersonic::Stream::protocol'     => { source => 'xs_stream_protocol', is_xs_native => 1 },
        'Hypersonic::Stream::state'        => { source => 'xs_stream_state', is_xs_native => 1 },
        'Hypersonic::Stream::chunks_sent'  => { source => 'xs_stream_chunks_sent', is_xs_native => 1 },
        'Hypersonic::Stream::is_started'   => { source => 'xs_stream_is_started', is_xs_native => 1 },
        'Hypersonic::Stream::is_finished'  => { source => 'xs_stream_is_finished', is_xs_native => 1 },
        'Hypersonic::Stream::headers'      => { source => 'xs_stream_headers', is_xs_native => 1 },
        'Hypersonic::Stream::content_type' => { source => 'xs_stream_content_type', is_xs_native => 1 },
        'Hypersonic::Stream::write'        => { source => 'xs_stream_write', is_xs_native => 1 },
        'Hypersonic::Stream::end'          => { source => 'xs_stream_end', is_xs_native => 1 },
        'Hypersonic::Stream::abort'        => { source => 'xs_stream_abort', is_xs_native => 1 },
    };
}

1;
