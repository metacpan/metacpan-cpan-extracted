package Hypersonic::UA::SSE;

use strict;
use warnings;
use 5.010;

our $VERSION = '0.12';

use constant MAX_SSE_CONNS => 256;

use constant {
    SLOT_FD        => 0,
    SLOT_URL       => 1,
    SLOT_CALLBACKS => 2,
    SLOT_RECONNECT => 3,
    SLOT_RETRY     => 4,
};

sub generate_c_code {
    my ($class, $builder, $opts) = @_;

    my $max_conns = $opts->{max_sse_conns} // MAX_SSE_CONNS;

    $class->gen_sse_registry($builder, $max_conns);
    $class->gen_sse_parser($builder);
    $class->gen_xs_new($builder);
    $class->gen_xs_connect($builder);
    $class->gen_xs_parse_events($builder);
    $class->gen_xs_recv_chunk($builder);
    $class->gen_xs_get_last_id($builder);
    $class->gen_xs_set_retry($builder);
    $class->gen_xs_close($builder);
}

sub get_xs_functions {
    return {
        'Hypersonic::UA::SSE::new'          => { source => 'xs_sse_new', is_xs_native => 1 },
        'Hypersonic::UA::SSE::connect'      => { source => 'xs_sse_connect', is_xs_native => 1 },
        'Hypersonic::UA::SSE::parse_events' => { source => 'xs_sse_parse_events', is_xs_native => 1 },
        'Hypersonic::UA::SSE::recv_chunk'   => { source => 'xs_sse_recv_chunk', is_xs_native => 1 },
        'Hypersonic::UA::SSE::get_last_id'  => { source => 'xs_sse_get_last_id', is_xs_native => 1 },
        'Hypersonic::UA::SSE::set_retry'    => { source => 'xs_sse_set_retry', is_xs_native => 1 },
        'Hypersonic::UA::SSE::close'        => { source => 'xs_sse_close', is_xs_native => 1 },
    };
}

sub gen_sse_registry {
    my ($class, $builder, $max_conns) = @_;

    $builder->line('#include <string.h>')
      ->line('#include <stdlib.h>')
      ->line('#include <sys/socket.h>')
      ->line('#include <errno.h>')
      ->line('#include <unistd.h>')
      ->blank;

    $builder->line("#define MAX_SSE_CONNS $max_conns")
      ->line('#define SSE_BUFFER_INITIAL 65536')
      ->blank;

    $builder->line('typedef struct {')
      ->line('    int      fd;')
      ->line('    int      tls;')
      ->line('    int      connected;')
      ->line('    int      reconnect;')
      ->line('    int      retry_ms;')
      ->line('    char*    buffer;')
      ->line('    size_t   buffer_len;')
      ->line('    size_t   buffer_cap;')
      ->line('    char     last_id[256];')
      ->line('    char     event_type[256];')
      ->line('    char*    event_data;')
      ->line('    size_t   event_data_len;')
      ->line('    size_t   event_data_cap;')
      ->line('} SSEConnection;')
      ->blank;

    $builder->line("static SSEConnection sse_registry[MAX_SSE_CONNS];")
      ->blank;

    # Helper: find connection by fd
    $builder->line('static SSEConnection* sse_find(int fd) {')
      ->line('    int i;')
      ->line('    for (i = 0; i < MAX_SSE_CONNS; i++) {')
      ->line('        if (sse_registry[i].fd == fd) {')
      ->line('            return &sse_registry[i];')
      ->line('        }')
      ->line('    }')
      ->line('    return NULL;')
      ->line('}')
      ->blank;

    # Helper: allocate connection slot
    $builder->line('static SSEConnection* sse_alloc(int fd) {')
      ->line('    int i;')
      ->line('    for (i = 0; i < MAX_SSE_CONNS; i++) {')
      ->line('        if (sse_registry[i].fd == 0) {')
      ->line('            SSEConnection* c = &sse_registry[i];')
      ->line('            memset(c, 0, sizeof(SSEConnection));')
      ->line('            c->fd = fd;')
      ->line('            c->retry_ms = 3000;')
      ->line('            c->reconnect = 1;')
      ->line('            c->buffer = (char*)malloc(SSE_BUFFER_INITIAL);')
      ->line('            c->buffer_cap = SSE_BUFFER_INITIAL;')
      ->line('            c->event_data = (char*)malloc(SSE_BUFFER_INITIAL);')
      ->line('            c->event_data_cap = SSE_BUFFER_INITIAL;')
      ->line('            return c;')
      ->line('        }')
      ->line('    }')
      ->line('    return NULL;')
      ->line('}')
      ->blank;

    # Helper: free connection
    $builder->line('static void sse_free(SSEConnection* c) {')
      ->line('    if (c->buffer) free(c->buffer);')
      ->line('    if (c->event_data) free(c->event_data);')
      ->line('    c->fd = 0;')
      ->line('    c->buffer = NULL;')
      ->line('    c->event_data = NULL;')
      ->line('}')
      ->blank;

    # Helper: append to buffer
    $builder->line('static int sse_buffer_append(SSEConnection* c, const char* data, size_t len) {')
      ->line('    if (c->buffer_len + len > c->buffer_cap) {')
      ->line('        size_t new_cap = c->buffer_cap * 2;')
      ->line('        while (new_cap < c->buffer_len + len) new_cap *= 2;')
      ->line('        char* new_buf = (char*)realloc(c->buffer, new_cap);')
      ->line('        if (!new_buf) return 0;')
      ->line('        c->buffer = new_buf;')
      ->line('        c->buffer_cap = new_cap;')
      ->line('    }')
      ->line('    memcpy(c->buffer + c->buffer_len, data, len);')
      ->line('    c->buffer_len += len;')
      ->line('    return 1;')
      ->line('}')
      ->blank;
}

sub gen_sse_parser {
    my ($class, $builder) = @_;

    $builder->comment('Parse SSE events from buffer, return array of events')
      ->line('static AV* sse_parse_events(SSEConnection* c) {')
      ->line('    AV* events = newAV();')
      ->line('    char* p = c->buffer;')
      ->line('    char* end = c->buffer + c->buffer_len;')
      ->line('    char* event_start = p;')
      ->blank
      ->line('    c->event_type[0] = \'\\0\';')
      ->line('    c->event_data_len = 0;')
      ->blank
      ->line('    while (p < end) {')
      ->line('        char* line_start = p;')
      ->line('        while (p < end && *p != \'\\n\') p++;')
      ->line('        if (p >= end) break;')
      ->blank
      ->line('        size_t line_len = p - line_start;')
      ->line('        p++;')
      ->blank
      ->line('        if (line_len > 0 && line_start[line_len - 1] == \'\\r\') {')
      ->line('            line_len--;')
      ->line('        }')
      ->blank
      ->line('        if (line_len == 0) {')
      ->line('            if (c->event_data_len > 0) {')
      ->line('                HV* event = newHV();')
      ->blank
      ->line('                if (c->event_data_len > 0 && c->event_data[c->event_data_len - 1] == \'\\n\') {')
      ->line('                    c->event_data_len--;')
      ->line('                }')
      ->blank
      ->line('                if (c->event_type[0]) {')
      ->line('                    hv_stores(event, "event", newSVpv(c->event_type, 0));')
      ->line('                }')
      ->line('                hv_stores(event, "data", newSVpvn(c->event_data, c->event_data_len));')
      ->line('                if (c->last_id[0]) {')
      ->line('                    hv_stores(event, "id", newSVpv(c->last_id, 0));')
      ->line('                }')
      ->blank
      ->line('                av_push(events, newRV_noinc((SV*)event));')
      ->blank
      ->line('                c->event_type[0] = \'\\0\';')
      ->line('                c->event_data_len = 0;')
      ->line('            }')
      ->line('            event_start = p;')
      ->line('            continue;')
      ->line('        }')
      ->blank
      ->line('        if (line_start[0] == \':\') {')
      ->line('            continue;')
      ->line('        }')
      ->blank
      ->line('        char* colon = memchr(line_start, \':\', line_len);')
      ->line('        char* field = line_start;')
      ->line('        size_t field_len;')
      ->line('        char* value;')
      ->line('        size_t value_len;')
      ->blank
      ->line('        if (colon) {')
      ->line('            field_len = colon - line_start;')
      ->line('            value = colon + 1;')
      ->line('            value_len = line_len - field_len - 1;')
      ->line('            if (value_len > 0 && value[0] == \' \') {')
      ->line('                value++;')
      ->line('                value_len--;')
      ->line('            }')
      ->line('        } else {')
      ->line('            field_len = line_len;')
      ->line('            value = "";')
      ->line('            value_len = 0;')
      ->line('        }')
      ->blank
      ->line('        if (field_len == 4 && memcmp(field, "data", 4) == 0) {')
      ->line('            if (c->event_data_len + value_len + 1 > c->event_data_cap) {')
      ->line('                size_t new_cap = c->event_data_cap * 2;')
      ->line('                c->event_data = realloc(c->event_data, new_cap);')
      ->line('                c->event_data_cap = new_cap;')
      ->line('            }')
      ->line('            if (c->event_data_len > 0) {')
      ->line('                c->event_data[c->event_data_len++] = \'\\n\';')
      ->line('            }')
      ->line('            memcpy(c->event_data + c->event_data_len, value, value_len);')
      ->line('            c->event_data_len += value_len;')
      ->line('        }')
      ->line('        else if (field_len == 5 && memcmp(field, "event", 5) == 0) {')
      ->line('            size_t copy_len = value_len < 255 ? value_len : 255;')
      ->line('            memcpy(c->event_type, value, copy_len);')
      ->line('            c->event_type[copy_len] = \'\\0\';')
      ->line('        }')
      ->line('        else if (field_len == 2 && memcmp(field, "id", 2) == 0) {')
      ->line('            if (!memchr(value, \'\\0\', value_len)) {')
      ->line('                size_t copy_len = value_len < 255 ? value_len : 255;')
      ->line('                memcpy(c->last_id, value, copy_len);')
      ->line('                c->last_id[copy_len] = \'\\0\';')
      ->line('            }')
      ->line('        }')
      ->line('        else if (field_len == 5 && memcmp(field, "retry", 5) == 0) {')
      ->line('            int retry = 0;')
      ->line('            int valid = 1;')
      ->line('            size_t i;')
      ->line('            for (i = 0; i < value_len; i++) {')
      ->line('                if (value[i] >= \'0\' && value[i] <= \'9\') {')
      ->line('                    retry = retry * 10 + (value[i] - \'0\');')
      ->line('                } else {')
      ->line('                    valid = 0;')
      ->line('                    break;')
      ->line('                }')
      ->line('            }')
      ->line('            if (valid && value_len > 0) {')
      ->line('                c->retry_ms = retry;')
      ->line('            }')
      ->line('        }')
      ->line('    }')
      ->blank
      ->line('    if (event_start > c->buffer) {')
      ->line('        size_t remaining = end - event_start;')
      ->line('        memmove(c->buffer, event_start, remaining);')
      ->line('        c->buffer_len = remaining;')
      ->line('    }')
      ->blank
      ->line('    return events;')
      ->line('}')
      ->blank;
}

sub gen_xs_new {
    my ($class, $builder) = @_;

    $builder->comment('Create new SSE object')
      ->xs_function('xs_sse_new')
      ->xs_preamble
      ->line('int fd;')
      ->line('int retry;')
      ->line('int reconnect;')
      ->line('SSEConnection* c;')
      ->line('AV* obj;')
      ->line('SV* rv;')
      ->blank
      ->line('if (items < 2) croak("Usage: Hypersonic::UA::SSE->new(fd, [retry], [reconnect])");')
      ->blank
      ->line('fd = (int)SvIV(ST(1));')
      ->line('retry = (items > 2) ? SvIV(ST(2)) : 3000;')
      ->line('reconnect = (items > 3) ? SvIV(ST(3)) : 1;')
      ->blank
      ->line('c = sse_alloc(fd);')
      ->line('if (!c) croak("SSE registry full");')
      ->blank
      ->line('c->retry_ms = retry;')
      ->line('c->reconnect = reconnect;')
      ->blank
      ->line('obj = newAV();')
      ->line('av_extend(obj, 4);')
      ->line('av_store(obj, 0, newSViv(fd));')
      ->line('av_store(obj, 1, &PL_sv_undef);')
      ->line('av_store(obj, 2, newRV_noinc((SV*)newHV()));')
      ->line('av_store(obj, 3, newSViv(reconnect));')
      ->line('av_store(obj, 4, newSViv(retry));')
      ->blank
      ->line('rv = newRV_noinc((SV*)obj);')
      ->line('sv_bless(rv, gv_stashpv("Hypersonic::UA::SSE", GV_ADD));')
      ->line('ST(0) = sv_2mortal(rv);')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_connect {
    my ($class, $builder) = @_;

    $builder->comment('Mark SSE connection as established')
      ->xs_function('xs_sse_connect')
      ->xs_preamble
      ->line('AV* obj;')
      ->line('SV** fd_sv;')
      ->line('int fd;')
      ->line('SSEConnection* c;')
      ->blank
      ->line('if (items != 1) croak("Usage: $sse->connect()");')
      ->line('obj = (AV*)SvRV(ST(0));')
      ->line('fd_sv = av_fetch(obj, 0, 0);')
      ->line('fd = SvIV(*fd_sv);')
      ->blank
      ->line('c = sse_find(fd);')
      ->line('if (c) {')
      ->line('    c->connected = 1;')
      ->line('    ST(0) = &PL_sv_yes;')
      ->line('} else {')
      ->line('    ST(0) = &PL_sv_no;')
      ->line('}')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_parse_events {
    my ($class, $builder) = @_;

    $builder->comment('Parse and return pending SSE events')
      ->xs_function('xs_sse_parse_events')
      ->xs_preamble
      ->line('if (items != 1) croak("Usage: $sse->parse_events()");')
      ->line('AV* obj = (AV*)SvRV(ST(0));')
      ->line('SV** fd_sv = av_fetch(obj, 0, 0);')
      ->line('int fd = SvIV(*fd_sv);')
      ->blank
      ->line('SSEConnection* c = sse_find(fd);')
      ->line('if (!c) {')
      ->line('    ST(0) = sv_2mortal(newRV_noinc((SV*)newAV()));')
      ->line('    XSRETURN(1);')
      ->line('}')
      ->blank
      ->line('AV* events = sse_parse_events(c);')
      ->line('ST(0) = sv_2mortal(newRV_noinc((SV*)events));')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_recv_chunk {
    my ($class, $builder) = @_;

    $builder->comment('Non-blocking receive for SSE data')
      ->xs_function('xs_sse_recv_chunk')
      ->xs_preamble
      ->line('if (items != 1) croak("Usage: $sse->recv_chunk()");')
      ->line('AV* obj = (AV*)SvRV(ST(0));')
      ->line('SV** fd_sv = av_fetch(obj, 0, 0);')
      ->line('int fd = SvIV(*fd_sv);')
      ->blank
      ->line('SSEConnection* c = sse_find(fd);')
      ->line('if (!c || !c->connected) {')
      ->line('    ST(0) = &PL_sv_undef;')
      ->line('    XSRETURN(1);')
      ->line('}')
      ->blank
      ->line('static char recv_buf[65536];')
      ->line('ssize_t n = recv(fd, recv_buf, sizeof(recv_buf), MSG_DONTWAIT);')
      ->blank
      ->line('if (n < 0) {')
      ->line('    if (errno == EAGAIN || errno == EWOULDBLOCK) {')
      ->line('        ST(0) = sv_2mortal(newSViv(0));')
      ->line('    } else {')
      ->line('        c->connected = 0;')
      ->line('        ST(0) = sv_2mortal(newSViv(-1));')
      ->line('    }')
      ->line('    XSRETURN(1);')
      ->line('}')
      ->blank
      ->line('if (n == 0) {')
      ->line('    c->connected = 0;')
      ->line('    ST(0) = &PL_sv_undef;')
      ->line('    XSRETURN(1);')
      ->line('}')
      ->blank
      ->line('sse_buffer_append(c, recv_buf, n);')
      ->line('ST(0) = sv_2mortal(newSViv(n));')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_get_last_id {
    my ($class, $builder) = @_;

    $builder->comment('Get Last-Event-ID for reconnect')
      ->xs_function('xs_sse_get_last_id')
      ->xs_preamble
      ->line('if (items != 1) croak("Usage: $sse->get_last_id()");')
      ->line('AV* obj = (AV*)SvRV(ST(0));')
      ->line('SV** fd_sv = av_fetch(obj, 0, 0);')
      ->line('int fd = SvIV(*fd_sv);')
      ->blank
      ->line('SSEConnection* c = sse_find(fd);')
      ->line('if (c && c->last_id[0]) {')
      ->line('    ST(0) = sv_2mortal(newSVpv(c->last_id, 0));')
      ->line('} else {')
      ->line('    ST(0) = &PL_sv_undef;')
      ->line('}')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_set_retry {
    my ($class, $builder) = @_;

    $builder->comment('Set retry interval')
      ->xs_function('xs_sse_set_retry')
      ->xs_preamble
      ->line('if (items != 2) croak("Usage: $sse->set_retry(ms)");')
      ->line('AV* obj = (AV*)SvRV(ST(0));')
      ->line('SV** fd_sv = av_fetch(obj, 0, 0);')
      ->line('int fd = SvIV(*fd_sv);')
      ->line('int retry_ms = SvIV(ST(1));')
      ->blank
      ->line('SSEConnection* c = sse_find(fd);')
      ->line('if (c) {')
      ->line('    c->retry_ms = retry_ms;')
      ->line('    ST(0) = &PL_sv_yes;')
      ->line('} else {')
      ->line('    ST(0) = &PL_sv_no;')
      ->line('}')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

sub gen_xs_close {
    my ($class, $builder) = @_;

    $builder->comment('Close SSE connection')
      ->xs_function('xs_sse_close')
      ->xs_preamble
      ->line('if (items != 1) croak("Usage: $sse->close()");')
      ->line('AV* obj = (AV*)SvRV(ST(0));')
      ->line('SV** fd_sv = av_fetch(obj, 0, 0);')
      ->line('int fd = SvIV(*fd_sv);')
      ->blank
      ->line('SSEConnection* c = sse_find(fd);')
      ->line('if (c) {')
      ->line('    c->connected = 0;')
      ->line('    c->reconnect = 0;')
      ->line('    close(fd);')
      ->line('    sse_free(c);')
      ->line('}')
      ->blank
      ->line('ST(0) = &PL_sv_yes;')
      ->xs_return('1')
      ->xs_end
      ->blank;
}

# Perl methods for callback management
sub on {
    my ($self, $event_type, $callback) = @_;
    my $callbacks = $self->[SLOT_CALLBACKS];
    $callbacks->{$event_type} = $callback;
    return $self;
}

sub emit {
    my ($self, $event_type, $event) = @_;
    my $callbacks = $self->[SLOT_CALLBACKS];
    if (my $cb = $callbacks->{$event_type}) {
        $cb->($event);
    }
    if (my $cb = $callbacks->{'*'}) {
        $cb->($event_type, $event);
    }
}

1;
