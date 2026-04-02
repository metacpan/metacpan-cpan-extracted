package Hypersonic::UA::Stream;

use strict;
use warnings;
use 5.010;

our $VERSION = '0.12';

use constant {
    STATE_INIT      => 0,
    STATE_HEADERS   => 1,
    STATE_BODY      => 2,
    STATE_FINISHED  => 3,
    STATE_ERROR     => 4,
};

use constant {
    SLOT_FD          => 0,
    SLOT_ON_HEADERS  => 1,
    SLOT_ON_DATA     => 2,
    SLOT_ON_COMPLETE => 3,
    SLOT_ON_ERROR    => 4,
};

use constant MAX_STREAMS => 1024;

sub generate_c_code {
    my ($class, $builder, $opts) = @_;

    my $max_streams = $opts->{max_streams} // MAX_STREAMS;

    $class->gen_stream_registry($builder, $max_streams);
    $class->gen_xs_new($builder);
    $class->gen_xs_fd($builder);
    $class->gen_xs_state($builder);
    $class->gen_xs_status($builder);
    $class->gen_xs_headers($builder);
    $class->gen_xs_is_complete($builder);
    $class->gen_xs_is_error($builder);
    $class->gen_xs_read_chunk($builder);
    $class->gen_xs_abort($builder);
}

sub get_xs_functions {
    return {
        'Hypersonic::UA::Stream::new'         => { source => 'xs_uastream_new', is_xs_native => 1 },
        'Hypersonic::UA::Stream::fd'          => { source => 'xs_uastream_fd', is_xs_native => 1 },
        'Hypersonic::UA::Stream::state'       => { source => 'xs_uastream_state', is_xs_native => 1 },
        'Hypersonic::UA::Stream::status'      => { source => 'xs_uastream_status', is_xs_native => 1 },
        'Hypersonic::UA::Stream::headers'     => { source => 'xs_uastream_headers', is_xs_native => 1 },
        'Hypersonic::UA::Stream::is_complete' => { source => 'xs_uastream_is_complete', is_xs_native => 1 },
        'Hypersonic::UA::Stream::is_error'    => { source => 'xs_uastream_is_error', is_xs_native => 1 },
        'Hypersonic::UA::Stream::read_chunk'  => { source => 'xs_uastream_read_chunk', is_xs_native => 1 },
        'Hypersonic::UA::Stream::abort'       => { source => 'xs_uastream_abort', is_xs_native => 1 },
    };
}

sub gen_stream_registry {
    my ($class, $builder, $max_streams) = @_;

    $builder->line("#define UA_MAX_STREAMS $max_streams")
      ->line('#define UA_STREAM_STATE_INIT 0')
      ->line('#define UA_STREAM_STATE_HEADERS 1')
      ->line('#define UA_STREAM_STATE_BODY 2')
      ->line('#define UA_STREAM_STATE_FINISHED 3')
      ->line('#define UA_STREAM_STATE_ERROR 4')
      ->line('#define UA_STREAM_BUFFER_INITIAL 65536')
      ->blank;

    $builder->line('typedef struct {')
      ->line('    int      fd;')
      ->line('    int      state;')
      ->line('    int      tls;')
      ->line('    int      status;')
      ->line('    int      http_minor;')
      ->line('    int64_t  content_length;')
      ->line('    int      chunked;')
      ->line('    int64_t  bytes_received;')
      ->line('    int64_t  chunk_remaining;')
      ->line('    int      in_chunk;')
      ->line('    char*    buffer;')
      ->line('    size_t   buffer_len;')
      ->line('    size_t   buffer_cap;')
      ->line('    HV*      headers_hv;')
      ->line('} UAStreamEntry;')
      ->blank
      ->line('static UAStreamEntry ua_stream_registry[UA_MAX_STREAMS];')
      ->blank;

    $builder->line('static UAStreamEntry* ua_stream_find(int fd) {')
      ->line('    int i;')
      ->line('    for (i = 0; i < UA_MAX_STREAMS; i++) {')
      ->line('        if (ua_stream_registry[i].fd == fd) {')
      ->line('            return &ua_stream_registry[i];')
      ->line('        }')
      ->line('    }')
      ->line('    return NULL;')
      ->line('}')
      ->blank;

    $builder->line('static UAStreamEntry* ua_stream_alloc(int fd) {')
      ->line('    int i;')
      ->line('    for (i = 0; i < UA_MAX_STREAMS; i++) {')
      ->line('        if (ua_stream_registry[i].fd == -1) {')
      ->line('            UAStreamEntry* s = &ua_stream_registry[i];')
      ->line('            memset(s, 0, sizeof(UAStreamEntry));')
      ->line('            s->fd = fd;')
      ->line('            s->state = UA_STREAM_STATE_INIT;')
      ->line('            s->content_length = -1;')
      ->line('            s->buffer = (char*)malloc(UA_STREAM_BUFFER_INITIAL);')
      ->line('            s->buffer_cap = UA_STREAM_BUFFER_INITIAL;')
      ->line('            s->buffer_len = 0;')
      ->line('            return s;')
      ->line('        }')
      ->line('    }')
      ->line('    return NULL;')
      ->line('}')
      ->blank;

    $builder->line('static void ua_stream_free(UAStreamEntry* s) {')
      ->line('    if (s->buffer) free(s->buffer);')
      ->line('    if (s->headers_hv) SvREFCNT_dec((SV*)s->headers_hv);')
      ->line('    s->fd = -1;')
      ->line('    s->buffer = NULL;')
      ->line('    s->headers_hv = NULL;')
      ->line('}')
      ->blank;

    $builder->line('static int ua_stream_buffer_append(UAStreamEntry* s, const char* data, size_t len) {')
      ->line('    if (s->buffer_len + len > s->buffer_cap) {')
      ->line('        size_t new_cap = s->buffer_cap * 2;')
      ->line('        while (new_cap < s->buffer_len + len) new_cap *= 2;')
      ->line('        char* new_buf = (char*)realloc(s->buffer, new_cap);')
      ->line('        if (!new_buf) return 0;')
      ->line('        s->buffer = new_buf;')
      ->line('        s->buffer_cap = new_cap;')
      ->line('    }')
      ->line('    memcpy(s->buffer + s->buffer_len, data, len);')
      ->line('    s->buffer_len += len;')
      ->line('    return 1;')
      ->line('}')
      ->blank;

    $builder->line('static void ua_stream_parse_headers(UAStreamEntry* s) {')
      ->line('    char* end = memmem(s->buffer, s->buffer_len, "\\r\\n\\r\\n", 4);')
      ->line('    if (!end) return;')
      ->blank
      ->line('    size_t headers_len = end - s->buffer;')
      ->blank
      ->line('    if (s->buffer_len > 12 && memcmp(s->buffer, "HTTP/1.", 7) == 0) {')
      ->line('        s->http_minor = s->buffer[7] - \'0\';')
      ->line('        s->status = atoi(s->buffer + 9);')
      ->line('    }')
      ->blank
      ->line('    s->headers_hv = newHV();')
      ->blank
      ->line('    char* p = memchr(s->buffer, \'\\n\', headers_len);')
      ->line('    if (p) p++;')
      ->blank
      ->line('    while (p && p < end) {')
      ->line('        char* line_end = memchr(p, \'\\n\', end - p);')
      ->line('        if (!line_end) break;')
      ->blank
      ->line('        char* colon = memchr(p, \':\', line_end - p);')
      ->line('        if (colon) {')
      ->line('            size_t name_len = colon - p;')
      ->line('            char* val = colon + 1;')
      ->line('            while (val < line_end && *val == \' \') val++;')
      ->line('            size_t val_len = line_end - val;')
      ->line('            if (val_len > 0 && val[val_len-1] == \'\\r\') val_len--;')
      ->blank
      ->line('            char name_lower[256];')
      ->line('            size_t i;')
      ->line('            for (i = 0; i < name_len && i < 255; i++) {')
      ->line('                char c = p[i];')
      ->line('                name_lower[i] = (c >= \'A\' && c <= \'Z\') ? c + 32 : (c == \'-\' ? \'_\' : c);')
      ->line('            }')
      ->blank
      ->line('            hv_store(s->headers_hv, name_lower, name_len, newSVpvn(val, val_len), 0);')
      ->blank
      ->line('            if (name_len == 14 && memcmp(name_lower, "content_length", 14) == 0) {')
      ->line('                s->content_length = atoll(val);')
      ->line('            }')
      ->line('            if (name_len == 17 && memcmp(name_lower, "transfer_encoding", 17) == 0) {')
      ->line('                if (memmem(val, val_len, "chunked", 7)) {')
      ->line('                    s->chunked = 1;')
      ->line('                }')
      ->line('            }')
      ->line('        }')
      ->line('        p = line_end + 1;')
      ->line('    }')
      ->blank
      ->line('    size_t consumed = (end - s->buffer) + 4;')
      ->line('    memmove(s->buffer, end + 4, s->buffer_len - consumed);')
      ->line('    s->buffer_len -= consumed;')
      ->blank
      ->line('    s->state = UA_STREAM_STATE_BODY;')
      ->line('}')
      ->blank;

    $builder->line('static void ua_stream_process_chunked(UAStreamEntry* s, AV* obj) {')
      ->line('    while (s->buffer_len > 0) {')
      ->line('        if (s->in_chunk) {')
      ->line('            size_t to_read = s->chunk_remaining;')
      ->line('            if (to_read > s->buffer_len) to_read = s->buffer_len;')
      ->blank
      ->line('            if (to_read > 0) {')
      ->line('                SV** cb_sv = av_fetch(obj, 2, 0);')
      ->line('                if (cb_sv && SvOK(*cb_sv)) {')
      ->line('                    dSP;')
      ->line('                    ENTER;')
      ->line('                    SAVETMPS;')
      ->line('                    PUSHMARK(SP);')
      ->line('                    XPUSHs(sv_2mortal(newSVpvn(s->buffer, to_read)));')
      ->line('                    PUTBACK;')
      ->line('                    call_sv(*cb_sv, G_DISCARD);')
      ->line('                    FREETMPS;')
      ->line('                    LEAVE;')
      ->line('                }')
      ->blank
      ->line('                memmove(s->buffer, s->buffer + to_read, s->buffer_len - to_read);')
      ->line('                s->buffer_len -= to_read;')
      ->line('                s->chunk_remaining -= to_read;')
      ->line('            }')
      ->blank
      ->line('            if (s->chunk_remaining == 0) {')
      ->line('                if (s->buffer_len >= 2) {')
      ->line('                    memmove(s->buffer, s->buffer + 2, s->buffer_len - 2);')
      ->line('                    s->buffer_len -= 2;')
      ->line('                    s->in_chunk = 0;')
      ->line('                } else {')
      ->line('                    break;')
      ->line('                }')
      ->line('            }')
      ->line('        } else {')
      ->line('            char* crlf = memmem(s->buffer, s->buffer_len, "\\r\\n", 2);')
      ->line('            if (!crlf) break;')
      ->blank
      ->line('            int64_t chunk_size = 0;')
      ->line('            for (char* cp = s->buffer; cp < crlf; cp++) {')
      ->line('                char c = *cp;')
      ->line('                if (c >= \'0\' && c <= \'9\') chunk_size = chunk_size * 16 + (c - \'0\');')
      ->line('                else if (c >= \'a\' && c <= \'f\') chunk_size = chunk_size * 16 + (c - \'a\' + 10);')
      ->line('                else if (c >= \'A\' && c <= \'F\') chunk_size = chunk_size * 16 + (c - \'A\' + 10);')
      ->line('                else break;')
      ->line('            }')
      ->blank
      ->line('            size_t consumed = (crlf - s->buffer) + 2;')
      ->line('            memmove(s->buffer, crlf + 2, s->buffer_len - consumed);')
      ->line('            s->buffer_len -= consumed;')
      ->blank
      ->line('            if (chunk_size == 0) {')
      ->line('                s->state = UA_STREAM_STATE_FINISHED;')
      ->line('                SV** cb_sv = av_fetch(obj, 3, 0);')
      ->line('                if (cb_sv && SvOK(*cb_sv)) {')
      ->line('                    dSP;')
      ->line('                    ENTER;')
      ->line('                    SAVETMPS;')
      ->line('                    PUSHMARK(SP);')
      ->line('                    PUTBACK;')
      ->line('                    call_sv(*cb_sv, G_DISCARD);')
      ->line('                    FREETMPS;')
      ->line('                    LEAVE;')
      ->line('                }')
      ->line('                return;')
      ->line('            }')
      ->blank
      ->line('            s->chunk_remaining = chunk_size;')
      ->line('            s->in_chunk = 1;')
      ->line('        }')
      ->line('    }')
      ->line('}')
      ->blank;

    $builder->line('static void ua_stream_process_content_length(UAStreamEntry* s, AV* obj) {')
      ->line('    if (s->buffer_len > 0) {')
      ->line('        SV** cb_sv = av_fetch(obj, 2, 0);')
      ->line('        if (cb_sv && SvOK(*cb_sv)) {')
      ->line('            dSP;')
      ->line('            ENTER;')
      ->line('            SAVETMPS;')
      ->line('            PUSHMARK(SP);')
      ->line('            XPUSHs(sv_2mortal(newSVpvn(s->buffer, s->buffer_len)));')
      ->line('            PUTBACK;')
      ->line('            call_sv(*cb_sv, G_DISCARD);')
      ->line('            FREETMPS;')
      ->line('            LEAVE;')
      ->line('        }')
      ->line('        s->buffer_len = 0;')
      ->line('    }')
      ->blank
      ->line('    if (s->content_length >= 0 && s->bytes_received >= (size_t)s->content_length) {')
      ->line('        s->state = UA_STREAM_STATE_FINISHED;')
      ->line('        SV** cb_sv = av_fetch(obj, 3, 0);')
      ->line('        if (cb_sv && SvOK(*cb_sv)) {')
      ->line('            dSP;')
      ->line('            ENTER;')
      ->line('            SAVETMPS;')
      ->line('            PUSHMARK(SP);')
      ->line('            PUTBACK;')
      ->line('            call_sv(*cb_sv, G_DISCARD);')
      ->line('            FREETMPS;')
      ->line('            LEAVE;')
      ->line('        }')
      ->line('    }')
      ->line('}')
      ->blank;

    $builder->line('static void ua_stream_registry_init(void) {')
      ->line('    int i;')
      ->line('    for (i = 0; i < UA_MAX_STREAMS; i++) {')
      ->line('        ua_stream_registry[i].fd = -1;')
      ->line('    }')
      ->line('}')
      ->blank;
}

sub gen_xs_new {
    my ($class, $builder) = @_;

    $builder->comment('Create new stream')
      ->xs_function('xs_uastream_new')
      ->xs_preamble
      ->line('int fd;')
      ->line('int tls;')
      ->line('UAStreamEntry* s;')
      ->line('AV* obj;')
      ->line('SV* rv;')
      ->blank
      ->line('if (items < 2) croak("Usage: Hypersonic::UA::Stream->new(fd, [tls])");')
      ->line('fd = (int)SvIV(ST(1));')
      ->line('tls = (items > 2) ? (int)SvIV(ST(2)) : 0;')
      ->blank
      ->line('s = ua_stream_alloc(fd);')
      ->line('if (!s) croak("Stream registry full");')
      ->blank
      ->line('s->tls = tls;')
      ->blank
      ->line('obj = newAV();')
      ->line('av_extend(obj, 4);')
      ->line('av_store(obj, 0, newSViv(fd));')
      ->line('av_store(obj, 1, &PL_sv_undef);')
      ->line('av_store(obj, 2, &PL_sv_undef);')
      ->line('av_store(obj, 3, &PL_sv_undef);')
      ->line('av_store(obj, 4, &PL_sv_undef);')
      ->blank
      ->line('rv = newRV_noinc((SV*)obj);')
      ->line('sv_bless(rv, gv_stashpv("Hypersonic::UA::Stream", GV_ADD));')
      ->line('ST(0) = sv_2mortal(rv);')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_fd {
    my ($class, $builder) = @_;

    $builder->comment('Get stream fd')
      ->xs_function('xs_uastream_fd')
      ->xs_preamble
      ->line('AV* obj;')
      ->line('SV** fd_sv;')
      ->blank
      ->line('if (items != 1) croak("Usage: $stream->fd()");')
      ->line('obj = (AV*)SvRV(ST(0));')
      ->line('fd_sv = av_fetch(obj, 0, 0);')
      ->line('ST(0) = fd_sv ? *fd_sv : &PL_sv_undef;')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_state {
    my ($class, $builder) = @_;

    $builder->comment('Get stream state')
      ->xs_function('xs_uastream_state')
      ->xs_preamble
      ->line('AV* obj;')
      ->line('SV** fd_sv;')
      ->line('int fd;')
      ->line('UAStreamEntry* s;')
      ->blank
      ->line('if (items != 1) croak("Usage: $stream->state()");')
      ->line('obj = (AV*)SvRV(ST(0));')
      ->line('fd_sv = av_fetch(obj, 0, 0);')
      ->line('fd = (int)SvIV(*fd_sv);')
      ->blank
      ->line('s = ua_stream_find(fd);')
      ->line('ST(0) = s ? sv_2mortal(newSViv(s->state)) : &PL_sv_undef;')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_status {
    my ($class, $builder) = @_;

    $builder->comment('Get HTTP status')
      ->xs_function('xs_uastream_status')
      ->xs_preamble
      ->line('if (items != 1) croak("Usage: $stream->status()");')
      ->line('AV* obj = (AV*)SvRV(ST(0));')
      ->line('SV** fd_sv = av_fetch(obj, 0, 0);')
      ->line('int fd = (int)SvIV(*fd_sv);')
      ->blank
      ->line('UAStreamEntry* s = ua_stream_find(fd);')
      ->line('ST(0) = s ? sv_2mortal(newSViv(s->status)) : &PL_sv_undef;')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_headers {
    my ($class, $builder) = @_;

    $builder->comment('Get parsed headers')
      ->xs_function('xs_uastream_headers')
      ->xs_preamble
      ->line('if (items != 1) croak("Usage: $stream->headers()");')
      ->line('AV* obj = (AV*)SvRV(ST(0));')
      ->line('SV** fd_sv = av_fetch(obj, 0, 0);')
      ->line('int fd = (int)SvIV(*fd_sv);')
      ->blank
      ->line('UAStreamEntry* s = ua_stream_find(fd);')
      ->if('s && s->headers_hv')
        ->line('ST(0) = sv_2mortal(newRV_inc((SV*)s->headers_hv));')
      ->else
        ->line('ST(0) = &PL_sv_undef;')
      ->endif
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_is_complete {
    my ($class, $builder) = @_;

    $builder->comment('Check if stream finished')
      ->xs_function('xs_uastream_is_complete')
      ->xs_preamble
      ->line('if (items != 1) croak("Usage: $stream->is_complete()");')
      ->line('AV* obj = (AV*)SvRV(ST(0));')
      ->line('SV** fd_sv = av_fetch(obj, 0, 0);')
      ->line('int fd = (int)SvIV(*fd_sv);')
      ->blank
      ->line('UAStreamEntry* s = ua_stream_find(fd);')
      ->line('ST(0) = (s && s->state == UA_STREAM_STATE_FINISHED) ? &PL_sv_yes : &PL_sv_no;')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_is_error {
    my ($class, $builder) = @_;

    $builder->comment('Check if stream errored')
      ->xs_function('xs_uastream_is_error')
      ->xs_preamble
      ->line('if (items != 1) croak("Usage: $stream->is_error()");')
      ->line('AV* obj = (AV*)SvRV(ST(0));')
      ->line('SV** fd_sv = av_fetch(obj, 0, 0);')
      ->line('int fd = (int)SvIV(*fd_sv);')
      ->blank
      ->line('UAStreamEntry* s = ua_stream_find(fd);')
      ->line('ST(0) = (s && s->state == UA_STREAM_STATE_ERROR) ? &PL_sv_yes : &PL_sv_no;')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_read_chunk {
    my ($class, $builder) = @_;

    $builder->comment('Read and process data chunk')
      ->xs_function('xs_uastream_read_chunk')
      ->xs_preamble
      ->line('if (items != 1) croak("Usage: $stream->read_chunk()");')
      ->line('AV* obj = (AV*)SvRV(ST(0));')
      ->line('SV** fd_sv = av_fetch(obj, 0, 0);')
      ->line('int fd = (int)SvIV(*fd_sv);')
      ->blank
      ->line('UAStreamEntry* s = ua_stream_find(fd);')
      ->if('!s || s->state >= UA_STREAM_STATE_FINISHED')
        ->line('ST(0) = &PL_sv_undef;')
        ->line('XSRETURN(1);')
      ->endif
      ->blank
      ->line('static char recv_buf[65536];')
      ->line('ssize_t n = recv(fd, recv_buf, sizeof(recv_buf), MSG_DONTWAIT);')
      ->blank
      ->if('n < 0')
        ->if('errno == EAGAIN || errno == EWOULDBLOCK')
          ->line('ST(0) = sv_2mortal(newSVpvn("", 0));')
        ->else
          ->line('s->state = UA_STREAM_STATE_ERROR;')
          ->line('ST(0) = &PL_sv_undef;')
        ->endif
        ->line('XSRETURN(1);')
      ->endif
      ->blank
      ->if('n == 0')
        ->if('s->state == UA_STREAM_STATE_BODY && s->content_length < 0 && !s->chunked')
          ->line('s->state = UA_STREAM_STATE_FINISHED;')
        ->elsif('s->state < UA_STREAM_STATE_FINISHED')
          ->line('s->state = UA_STREAM_STATE_ERROR;')
        ->endif
        ->line('ST(0) = &PL_sv_undef;')
        ->line('XSRETURN(1);')
      ->endif
      ->blank
      ->line('ua_stream_buffer_append(s, recv_buf, n);')
      ->line('s->bytes_received += n;')
      ->blank
      ->if('s->state <= UA_STREAM_STATE_HEADERS')
        ->line('ua_stream_parse_headers(s);')
      ->endif
      ->blank
      ->if('s->state == UA_STREAM_STATE_BODY')
        ->if('s->chunked')
          ->line('ua_stream_process_chunked(s, obj);')
        ->else
          ->line('ua_stream_process_content_length(s, obj);')
        ->endif
      ->endif
      ->blank
      ->line('ST(0) = sv_2mortal(newSViv(n));')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_abort {
    my ($class, $builder) = @_;

    $builder->comment('Abort stream')
      ->xs_function('xs_uastream_abort')
      ->xs_preamble
      ->line('if (items < 1) croak("Usage: $stream->abort([reason])");')
      ->line('AV* obj = (AV*)SvRV(ST(0));')
      ->line('SV** fd_sv = av_fetch(obj, 0, 0);')
      ->line('int fd = (int)SvIV(*fd_sv);')
      ->blank
      ->line('UAStreamEntry* s = ua_stream_find(fd);')
      ->if('s')
        ->line('s->state = UA_STREAM_STATE_ERROR;')
        ->line('close(fd);')
        ->blank
        ->line('SV** cb_sv = av_fetch(obj, 4, 0);')
        ->if('cb_sv && SvOK(*cb_sv)')
          ->line('const char* reason = (items > 1 && SvOK(ST(1))) ? SvPV_nolen(ST(1)) : "Aborted";')
          ->line('dSP;')
          ->line('ENTER;')
          ->line('SAVETMPS;')
          ->line('PUSHMARK(SP);')
          ->line('XPUSHs(sv_2mortal(newSVpv(reason, 0)));')
          ->line('PUTBACK;')
          ->line('call_sv(*cb_sv, G_DISCARD);')
          ->line('FREETMPS;')
          ->line('LEAVE;')
        ->endif
        ->blank
        ->line('ua_stream_free(s);')
      ->endif
      ->blank
      ->line('ST(0) = &PL_sv_yes;')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub on_headers {
    my ($self, $cb) = @_;
    $self->[SLOT_ON_HEADERS] = $cb;
    return $self;
}

sub on_data {
    my ($self, $cb) = @_;
    $self->[SLOT_ON_DATA] = $cb;
    return $self;
}

sub on_complete {
    my ($self, $cb) = @_;
    $self->[SLOT_ON_COMPLETE] = $cb;
    return $self;
}

sub on_error {
    my ($self, $cb) = @_;
    $self->[SLOT_ON_ERROR] = $cb;
    return $self;
}

1;
