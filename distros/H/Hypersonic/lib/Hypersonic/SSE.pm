package Hypersonic::SSE;
use strict;
use warnings;
use 5.010;

# Hypersonic::SSE - High-level Server-Sent Events API
#
# Wraps the streaming infrastructure to provide a clean SSE interface.
# Automatically handles headers, event formatting, and keepalives.
# Uses JIT-compiled XS for performance.

our $VERSION = '0.12';

use constant {
    STATE_INIT     => 0,
    STATE_STARTED  => 1,
    STATE_FINISHED => 2,
};
use constant MAX_SSE_INSTANCES => 65536;
use constant DEFAULT_KEEPALIVE => 30;

use Hypersonic::Protocol::SSE;

=head1 NAME

Hypersonic::SSE - Server-Sent Events streaming interface

=head1 SYNOPSIS

    $app->get('/events' => sub {
        my ($req, $stream) = @_;

        my $sse = Hypersonic::SSE->new($stream);

        $sse->event(
            type => 'message',
            data => 'Hello World!',
        );

        $sse->event(
            type => 'update',
            data => '{"count": 42}',
            id   => '123',
        );

        $sse->close();
    }, { streaming => 1 });

=head1 DESCRIPTION

Hypersonic::SSE provides a high-level API for sending Server-Sent Events.
It wraps a Hypersonic::Stream object and handles SSE-specific formatting,
headers, and keepalives.

=cut

# ============================================================
# XS Code Generation - ALL instance methods generated in C
# ============================================================

sub generate_c_code {
    my ($class, $builder, $opts) = @_;
    $opts //= {};
    my $max = $opts->{max_sse_instances} // MAX_SSE_INSTANCES;

    $builder->line('#include <time.h>')
      ->blank;

    $class->gen_sse_registry($builder, $max);
    $class->gen_sse_reset($builder);
    $class->gen_sse_format_event($builder);
    $class->gen_sse_format_keepalive($builder);
    $class->gen_sse_format_retry($builder);
    $class->gen_sse_format_comment($builder);

    # XS instance methods
    $class->gen_xs_new($builder);
    $class->gen_xs_stream($builder);
    $class->gen_xs_is_started($builder);
    $class->gen_xs_event_count($builder);
    $class->gen_xs_last_event_time($builder);
    $class->gen_xs_needs_keepalive($builder);
    $class->gen_xs_event($builder);
    $class->gen_xs_data($builder);
    $class->gen_xs_retry($builder);
    $class->gen_xs_keepalive($builder);
    $class->gen_xs_comment($builder);
    $class->gen_xs_close($builder);

    return $builder;
}

sub gen_sse_registry {
    my ($class, $builder, $max) = @_;

    $builder->comment('SSE instance registry - stores SSE state')
      ->line('#define SSE_MAX ' . $max)
      ->line('#define SSE_STATE_INIT     0')
      ->line('#define SSE_STATE_STARTED  1')
      ->line('#define SSE_STATE_FINISHED 2')
      ->blank
      ->line('typedef struct {')
      ->line('    SV* stream_sv;')
      ->line('    int state;')
      ->line('    int event_count;')
      ->line('    time_t last_event_time;')
      ->line('    int keepalive_interval;')
      ->line('} SSEState;')
      ->blank
      ->line('static SSEState sse_registry[SSE_MAX];')
      ->line('static int sse_next_id = 0;')
      ->blank;
}

sub gen_sse_reset {
    my ($class, $builder) = @_;

    $builder->line('static void sse_reset(int id) {')
      ->line('    if (sse_registry[id].stream_sv) {')
      ->line('        SvREFCNT_dec(sse_registry[id].stream_sv);')
      ->line('    }')
      ->line('    memset(&sse_registry[id], 0, sizeof(SSEState));')
      ->line('    sse_registry[id].last_event_time = time(NULL);')
      ->line('    sse_registry[id].keepalive_interval = 30;')
      ->line('}')
      ->blank;
}

sub gen_sse_format_event {
    my ($class, $builder) = @_;

    $builder->comment('SSE: Format an event into buffer')
      ->comment('Returns bytes written')
      ->line('static size_t sse_format_event(char* buf, size_t buf_size,')
      ->line('                               const char* event_type,')
      ->line('                               const char* data,')
      ->line('                               const char* id) {')
      ->line('    size_t pos = 0;')
      ->blank
      ->comment('Event type (optional)')
      ->if('event_type && event_type[0]')
        ->line('pos += snprintf(buf + pos, buf_size - pos, "event: %s\\n", event_type);')
      ->endif
      ->blank
      ->comment('ID (optional)')
      ->if('id && id[0]')
        ->line('pos += snprintf(buf + pos, buf_size - pos, "id: %s\\n", id);')
      ->endif
      ->blank
      ->comment('Data (required) - handle multiline')
      ->if('data')
        ->line('const char* line_start = data;')
        ->line('const char* p = data;')
        ->while('*p')
          ->if('*p == \'\\n\'')
            ->line('pos += snprintf(buf + pos, buf_size - pos, "data: %.*s\\n",')
            ->line('               (int)(p - line_start), line_start);')
            ->line('line_start = p + 1;')
          ->endif
          ->line('p++;')
        ->endloop
        ->comment('Last line (or only line if no newlines)')
        ->if('line_start <= p && *line_start')
          ->line('pos += snprintf(buf + pos, buf_size - pos, "data: %s\\n", line_start);')
        ->elsif('line_start == data')
          ->comment('Empty string - still need data line')
          ->line('pos += snprintf(buf + pos, buf_size - pos, "data: \\n");')
        ->endif
      ->endif
      ->blank
      ->comment('End of event (blank line)')
      ->if('pos < buf_size')
        ->line('buf[pos++] = \'\\n\';')
      ->endif
      ->blank
      ->line('return pos;')
      ->line('}')
      ->blank;

    return $builder;
}

sub gen_sse_format_keepalive {
    my ($class, $builder) = @_;

    $builder->comment('SSE: Format keepalive comment')
      ->line('static size_t sse_format_keepalive(char* buf, size_t buf_size) {')
      ->line('    return snprintf(buf, buf_size, ": keepalive\\n\\n");')
      ->line('}')
      ->blank;

    return $builder;
}

sub gen_sse_format_retry {
    my ($class, $builder) = @_;

    $builder->comment('SSE: Format retry directive')
      ->line('static size_t sse_format_retry(char* buf, size_t buf_size, int ms) {')
      ->line('    return snprintf(buf, buf_size, "retry: %d\\n\\n", ms);')
      ->line('}')
      ->blank;

    return $builder;
}

sub gen_sse_format_comment {
    my ($class, $builder) = @_;

    $builder->comment('SSE: Format comment')
      ->line('static size_t sse_format_comment(char* buf, size_t buf_size, const char* text) {')
      ->line('    return snprintf(buf, buf_size, ": %s\\n\\n", text);')
      ->line('}')
      ->blank;

    return $builder;
}

# XS: new($stream, %opts) - returns blessed scalar
sub gen_xs_new {
    my ($class, $builder) = @_;

    $builder->xs_function('xs_sse_new')
      ->xs_preamble
      ->line('int id = sse_next_id;')
      ->line('sse_next_id = (sse_next_id + 1) % SSE_MAX;')
      ->blank
      ->line('sse_reset(id);')
      ->blank
      ->comment('First arg after class is the stream object')
      ->if('items >= 2')
        ->line('sse_registry[id].stream_sv = newSVsv(ST(1));')
      ->else
        ->line('croak("Hypersonic::SSE->new requires a stream argument");')
      ->endif
      ->blank
      ->comment('Parse optional hash args: keepalive => N')
      ->for('int i = 2', 'i < items', 'i += 2')
        ->if('i + 1 < items')
          ->line('STRLEN klen;')
          ->line('const char* key = SvPV(ST(i), klen);')
          ->if('klen == 9 && strncmp(key, "keepalive", 9) == 0')
            ->line('sse_registry[id].keepalive_interval = SvIV(ST(i + 1));')
          ->endif
        ->endif
      ->endfor
      ->blank
      ->line('SV* id_sv = newSViv(id);')
      ->line('SV* ref = newRV_noinc(id_sv);')
      ->line('sv_bless(ref, gv_stashpv("Hypersonic::SSE", GV_ADD));')
      ->line('ST(0) = sv_2mortal(ref);')
      ->line('XSRETURN(1);')
      ->xs_end
      ->blank;
}

sub gen_xs_stream {
    my ($class, $builder) = @_;

    $builder->xs_function('xs_sse_stream')
      ->xs_preamble
      ->check_items(1, 1, '$sse->stream')
      ->line('int id = SvIV(SvRV(ST(0)));')
      ->if('id < 0 || id >= SSE_MAX')
        ->line('XSRETURN_UNDEF;')
      ->endif
      ->if('sse_registry[id].stream_sv')
        ->line('ST(0) = sv_2mortal(newSVsv(sse_registry[id].stream_sv));')
        ->line('XSRETURN(1);')
      ->endif
      ->line('XSRETURN_UNDEF;')
      ->xs_end
      ->blank;
}

sub gen_xs_is_started {
    my ($class, $builder) = @_;

    $builder->xs_function('xs_sse_is_started')
      ->xs_preamble
      ->check_items(1, 1, '$sse->is_started')
      ->line('int id = SvIV(SvRV(ST(0)));')
      ->if('id < 0 || id >= SSE_MAX')
        ->line('XSRETURN_NO;')
      ->endif
      ->if('sse_registry[id].state >= SSE_STATE_STARTED')
        ->line('XSRETURN_YES;')
      ->else
        ->line('XSRETURN_NO;')
      ->endif
      ->xs_end
      ->blank;
}

sub gen_xs_event_count {
    my ($class, $builder) = @_;

    $builder->xs_function('xs_sse_event_count')
      ->xs_preamble
      ->check_items(1, 1, '$sse->event_count')
      ->line('int id = SvIV(SvRV(ST(0)));')
      ->if('id < 0 || id >= SSE_MAX')
        ->line('XSRETURN_IV(0);')
      ->endif
      ->line('XSRETURN_IV(sse_registry[id].event_count);')
      ->xs_end
      ->blank;
}

sub gen_xs_last_event_time {
    my ($class, $builder) = @_;

    $builder->xs_function('xs_sse_last_event_time')
      ->xs_preamble
      ->check_items(1, 1, '$sse->last_event_time')
      ->line('int id = SvIV(SvRV(ST(0)));')
      ->if('id < 0 || id >= SSE_MAX')
        ->line('XSRETURN_IV(0);')
      ->endif
      ->line('XSRETURN_IV((IV)sse_registry[id].last_event_time);')
      ->xs_end
      ->blank;
}

sub gen_xs_needs_keepalive {
    my ($class, $builder) = @_;

    $builder->xs_function('xs_sse_needs_keepalive')
      ->xs_preamble
      ->check_items(1, 1, '$sse->needs_keepalive')
      ->line('int id = SvIV(SvRV(ST(0)));')
      ->if('id < 0 || id >= SSE_MAX')
        ->line('XSRETURN_NO;')
      ->endif
      ->blank
      ->comment('Check if stream is finished')
      ->line('SSEState* s = &sse_registry[id];')
      ->if('s->state >= SSE_STATE_FINISHED')
        ->line('XSRETURN_NO;')
      ->endif
      ->blank
      ->line('time_t now = time(NULL);')
      ->line('time_t elapsed = now - s->last_event_time;')
      ->if('elapsed >= s->keepalive_interval')
        ->line('XSRETURN_YES;')
      ->else
        ->line('XSRETURN_NO;')
      ->endif
      ->xs_end
      ->blank;
}

sub gen_xs_event {
    my ($class, $builder) = @_;

    $builder->xs_function('xs_sse_event')
      ->xs_preamble
      ->line('int id = SvIV(SvRV(ST(0)));')
      ->if('id < 0 || id >= SSE_MAX')
        ->line('ST(0) = ST(0);')
        ->line('XSRETURN(1);')
      ->endif
      ->blank
      ->line('SSEState* s = &sse_registry[id];')
      ->blank
      ->comment('Check if stream is finished by calling is_finished method')
      ->if('s->stream_sv')
        ->line('dSP;')
        ->line('ENTER;')
        ->line('SAVETMPS;')
        ->line('PUSHMARK(SP);')
        ->line('XPUSHs(s->stream_sv);')
        ->line('PUTBACK;')
        ->line('int count = call_method("is_finished", G_SCALAR);')
        ->line('SPAGAIN;')
        ->line('int is_finished = 0;')
        ->if('count > 0')
          ->line('is_finished = SvTRUE(POPs);')
        ->endif
        ->line('PUTBACK;')
        ->line('FREETMPS;')
        ->line('LEAVE;')
        ->if('is_finished')
          ->line('ST(0) = ST(0);')
          ->line('XSRETURN(1);')
        ->endif
      ->endif
      ->blank
      ->comment('Start SSE if not started - call headers method on stream')
      ->if('s->state == SSE_STATE_INIT && s->stream_sv')
        ->line('dSP;')
        ->line('ENTER;')
        ->line('SAVETMPS;')
        ->line('PUSHMARK(SP);')
        ->line('XPUSHs(s->stream_sv);')
        ->line('XPUSHs(sv_2mortal(newSViv(200)));')
        ->comment('Create headers hash')
        ->line('HV* hv = newHV();')
        ->line('(void)hv_store(hv, "Content-Type", 12, newSVpv("text/event-stream", 0), 0);')
        ->line('(void)hv_store(hv, "Cache-Control", 13, newSVpv("no-cache", 0), 0);')
        ->line('(void)hv_store(hv, "Connection", 10, newSVpv("keep-alive", 0), 0);')
        ->line('(void)hv_store(hv, "X-Accel-Buffering", 17, newSVpv("no", 0), 0);')
        ->line('XPUSHs(sv_2mortal(newRV_noinc((SV*)hv)));')
        ->line('PUTBACK;')
        ->line('call_method("headers", G_DISCARD);')
        ->line('FREETMPS;')
        ->line('LEAVE;')
        ->line('s->state = SSE_STATE_STARTED;')
      ->endif
      ->blank
      ->comment('Parse event options from hash args')
      ->line('const char* event_type = NULL;')
      ->line('const char* data = "";')
      ->line('const char* event_id = NULL;')
      ->blank
      ->for('int i = 1', 'i < items', 'i += 2')
        ->if('i + 1 < items')
          ->line('STRLEN klen;')
          ->line('const char* key = SvPV(ST(i), klen);')
          ->if('klen == 4 && strncmp(key, "type", 4) == 0')
            ->line('event_type = SvPV_nolen(ST(i + 1));')
          ->endif
          ->if('klen == 4 && strncmp(key, "data", 4) == 0')
            ->line('data = SvPV_nolen(ST(i + 1));')
          ->endif
          ->if('klen == 2 && strncmp(key, "id", 2) == 0')
            ->line('event_id = SvPV_nolen(ST(i + 1));')
          ->endif
        ->endif
      ->endfor
      ->blank
      ->comment('Format event')
      ->line('char buf[8192];')
      ->line('size_t len = sse_format_event(buf, sizeof(buf), event_type, data, event_id);')
      ->blank
      ->comment('Write to stream')
      ->if('s->stream_sv && len > 0')
        ->line('dSP;')
        ->line('ENTER;')
        ->line('SAVETMPS;')
        ->line('PUSHMARK(SP);')
        ->line('XPUSHs(s->stream_sv);')
        ->line('XPUSHs(sv_2mortal(newSVpvn(buf, len)));')
        ->line('PUTBACK;')
        ->line('call_method("write", G_DISCARD);')
        ->line('FREETMPS;')
        ->line('LEAVE;')
      ->endif
      ->blank
      ->line('s->event_count++;')
      ->line('s->last_event_time = time(NULL);')
      ->blank
      ->line('ST(0) = ST(0);')
      ->line('XSRETURN(1);')
      ->xs_end
      ->blank;
}

sub gen_xs_data {
    my ($class, $builder) = @_;

    $builder->xs_function('xs_sse_data')
      ->xs_preamble
      ->if('items != 2')
        ->line('croak("Usage: $sse->data(payload)");')
      ->endif
      ->line('int id = SvIV(SvRV(ST(0)));')
      ->if('id < 0 || id >= SSE_MAX')
        ->line('ST(0) = ST(0);')
        ->line('XSRETURN(1);')
      ->endif
      ->blank
      ->line('SSEState* s = &sse_registry[id];')
      ->blank
      ->comment('Check if stream is finished')
      ->if('s->stream_sv')
        ->line('dSP;')
        ->line('ENTER;')
        ->line('SAVETMPS;')
        ->line('PUSHMARK(SP);')
        ->line('XPUSHs(s->stream_sv);')
        ->line('PUTBACK;')
        ->line('int count = call_method("is_finished", G_SCALAR);')
        ->line('SPAGAIN;')
        ->line('int is_finished = 0;')
        ->if('count > 0')
          ->line('is_finished = SvTRUE(POPs);')
        ->endif
        ->line('PUTBACK;')
        ->line('FREETMPS;')
        ->line('LEAVE;')
        ->if('is_finished')
          ->line('ST(0) = ST(0);')
          ->line('XSRETURN(1);')
        ->endif
      ->endif
      ->blank
      ->comment('Start SSE if not started')
      ->if('s->state == SSE_STATE_INIT && s->stream_sv')
        ->line('dSP;')
        ->line('ENTER;')
        ->line('SAVETMPS;')
        ->line('PUSHMARK(SP);')
        ->line('XPUSHs(s->stream_sv);')
        ->line('XPUSHs(sv_2mortal(newSViv(200)));')
        ->line('HV* hv = newHV();')
        ->line('(void)hv_store(hv, "Content-Type", 12, newSVpv("text/event-stream", 0), 0);')
        ->line('(void)hv_store(hv, "Cache-Control", 13, newSVpv("no-cache", 0), 0);')
        ->line('(void)hv_store(hv, "Connection", 10, newSVpv("keep-alive", 0), 0);')
        ->line('(void)hv_store(hv, "X-Accel-Buffering", 17, newSVpv("no", 0), 0);')
        ->line('XPUSHs(sv_2mortal(newRV_noinc((SV*)hv)));')
        ->line('PUTBACK;')
        ->line('call_method("headers", G_DISCARD);')
        ->line('FREETMPS;')
        ->line('LEAVE;')
        ->line('s->state = SSE_STATE_STARTED;')
      ->endif
      ->blank
      ->comment('Format data-only event')
      ->line('const char* data = SvPV_nolen(ST(1));')
      ->line('char buf[8192];')
      ->line('size_t len = sse_format_event(buf, sizeof(buf), NULL, data, NULL);')
      ->blank
      ->comment('Write to stream')
      ->if('s->stream_sv && len > 0')
        ->line('dSP;')
        ->line('ENTER;')
        ->line('SAVETMPS;')
        ->line('PUSHMARK(SP);')
        ->line('XPUSHs(s->stream_sv);')
        ->line('XPUSHs(sv_2mortal(newSVpvn(buf, len)));')
        ->line('PUTBACK;')
        ->line('call_method("write", G_DISCARD);')
        ->line('FREETMPS;')
        ->line('LEAVE;')
      ->endif
      ->blank
      ->line('s->event_count++;')
      ->line('s->last_event_time = time(NULL);')
      ->blank
      ->line('ST(0) = ST(0);')
      ->line('XSRETURN(1);')
      ->xs_end
      ->blank;
}

sub gen_xs_retry {
    my ($class, $builder) = @_;

    $builder->xs_function('xs_sse_retry')
      ->xs_preamble
      ->if('items != 2')
        ->line('croak("Usage: $sse->retry(milliseconds)");')
      ->endif
      ->line('int id = SvIV(SvRV(ST(0)));')
      ->if('id < 0 || id >= SSE_MAX')
        ->line('ST(0) = ST(0);')
        ->line('XSRETURN(1);')
      ->endif
      ->blank
      ->line('SSEState* s = &sse_registry[id];')
      ->blank
      ->comment('Check if stream is finished')
      ->if('s->stream_sv')
        ->line('dSP;')
        ->line('ENTER;')
        ->line('SAVETMPS;')
        ->line('PUSHMARK(SP);')
        ->line('XPUSHs(s->stream_sv);')
        ->line('PUTBACK;')
        ->line('int count = call_method("is_finished", G_SCALAR);')
        ->line('SPAGAIN;')
        ->line('int is_finished = 0;')
        ->if('count > 0')
          ->line('is_finished = SvTRUE(POPs);')
        ->endif
        ->line('PUTBACK;')
        ->line('FREETMPS;')
        ->line('LEAVE;')
        ->if('is_finished')
          ->line('ST(0) = ST(0);')
          ->line('XSRETURN(1);')
        ->endif
      ->endif
      ->blank
      ->comment('Start SSE if not started')
      ->if('s->state == SSE_STATE_INIT && s->stream_sv')
        ->line('dSP;')
        ->line('ENTER;')
        ->line('SAVETMPS;')
        ->line('PUSHMARK(SP);')
        ->line('XPUSHs(s->stream_sv);')
        ->line('XPUSHs(sv_2mortal(newSViv(200)));')
        ->line('HV* hv = newHV();')
        ->line('(void)hv_store(hv, "Content-Type", 12, newSVpv("text/event-stream", 0), 0);')
        ->line('(void)hv_store(hv, "Cache-Control", 13, newSVpv("no-cache", 0), 0);')
        ->line('(void)hv_store(hv, "Connection", 10, newSVpv("keep-alive", 0), 0);')
        ->line('(void)hv_store(hv, "X-Accel-Buffering", 17, newSVpv("no", 0), 0);')
        ->line('XPUSHs(sv_2mortal(newRV_noinc((SV*)hv)));')
        ->line('PUTBACK;')
        ->line('call_method("headers", G_DISCARD);')
        ->line('FREETMPS;')
        ->line('LEAVE;')
        ->line('s->state = SSE_STATE_STARTED;')
      ->endif
      ->blank
      ->comment('Format retry directive')
      ->line('int ms = SvIV(ST(1));')
      ->line('char buf[64];')
      ->line('size_t len = sse_format_retry(buf, sizeof(buf), ms);')
      ->blank
      ->comment('Write to stream')
      ->if('s->stream_sv && len > 0')
        ->line('dSP;')
        ->line('ENTER;')
        ->line('SAVETMPS;')
        ->line('PUSHMARK(SP);')
        ->line('XPUSHs(s->stream_sv);')
        ->line('XPUSHs(sv_2mortal(newSVpvn(buf, len)));')
        ->line('PUTBACK;')
        ->line('call_method("write", G_DISCARD);')
        ->line('FREETMPS;')
        ->line('LEAVE;')
      ->endif
      ->blank
      ->line('ST(0) = ST(0);')
      ->line('XSRETURN(1);')
      ->xs_end
      ->blank;
}

sub gen_xs_keepalive {
    my ($class, $builder) = @_;

    $builder->xs_function('xs_sse_keepalive')
      ->xs_preamble
      ->check_items(1, 1, '$sse->keepalive')
      ->line('int id = SvIV(SvRV(ST(0)));')
      ->if('id < 0 || id >= SSE_MAX')
        ->line('ST(0) = ST(0);')
        ->line('XSRETURN(1);')
      ->endif
      ->blank
      ->line('SSEState* s = &sse_registry[id];')
      ->blank
      ->comment('Check if stream is finished')
      ->if('s->stream_sv')
        ->line('dSP;')
        ->line('ENTER;')
        ->line('SAVETMPS;')
        ->line('PUSHMARK(SP);')
        ->line('XPUSHs(s->stream_sv);')
        ->line('PUTBACK;')
        ->line('int count = call_method("is_finished", G_SCALAR);')
        ->line('SPAGAIN;')
        ->line('int is_finished = 0;')
        ->if('count > 0')
          ->line('is_finished = SvTRUE(POPs);')
        ->endif
        ->line('PUTBACK;')
        ->line('FREETMPS;')
        ->line('LEAVE;')
        ->if('is_finished')
          ->line('ST(0) = ST(0);')
          ->line('XSRETURN(1);')
        ->endif
      ->endif
      ->blank
      ->comment('Start SSE if not started')
      ->if('s->state == SSE_STATE_INIT && s->stream_sv')
        ->line('dSP;')
        ->line('ENTER;')
        ->line('SAVETMPS;')
        ->line('PUSHMARK(SP);')
        ->line('XPUSHs(s->stream_sv);')
        ->line('XPUSHs(sv_2mortal(newSViv(200)));')
        ->line('HV* hv = newHV();')
        ->line('(void)hv_store(hv, "Content-Type", 12, newSVpv("text/event-stream", 0), 0);')
        ->line('(void)hv_store(hv, "Cache-Control", 13, newSVpv("no-cache", 0), 0);')
        ->line('(void)hv_store(hv, "Connection", 10, newSVpv("keep-alive", 0), 0);')
        ->line('(void)hv_store(hv, "X-Accel-Buffering", 17, newSVpv("no", 0), 0);')
        ->line('XPUSHs(sv_2mortal(newRV_noinc((SV*)hv)));')
        ->line('PUTBACK;')
        ->line('call_method("headers", G_DISCARD);')
        ->line('FREETMPS;')
        ->line('LEAVE;')
        ->line('s->state = SSE_STATE_STARTED;')
      ->endif
      ->blank
      ->comment('Format keepalive')
      ->line('char buf[32];')
      ->line('size_t len = sse_format_keepalive(buf, sizeof(buf));')
      ->blank
      ->comment('Write to stream')
      ->if('s->stream_sv && len > 0')
        ->line('dSP;')
        ->line('ENTER;')
        ->line('SAVETMPS;')
        ->line('PUSHMARK(SP);')
        ->line('XPUSHs(s->stream_sv);')
        ->line('XPUSHs(sv_2mortal(newSVpvn(buf, len)));')
        ->line('PUTBACK;')
        ->line('call_method("write", G_DISCARD);')
        ->line('FREETMPS;')
        ->line('LEAVE;')
      ->endif
      ->blank
      ->line('s->last_event_time = time(NULL);')
      ->blank
      ->line('ST(0) = ST(0);')
      ->line('XSRETURN(1);')
      ->xs_end
      ->blank;
}

sub gen_xs_comment {
    my ($class, $builder) = @_;

    $builder->xs_function('xs_sse_comment')
      ->xs_preamble
      ->if('items != 2')
        ->line('croak("Usage: $sse->comment(text)");')
      ->endif
      ->line('int id = SvIV(SvRV(ST(0)));')
      ->if('id < 0 || id >= SSE_MAX')
        ->line('ST(0) = ST(0);')
        ->line('XSRETURN(1);')
      ->endif
      ->blank
      ->line('SSEState* s = &sse_registry[id];')
      ->blank
      ->comment('Check if stream is finished')
      ->if('s->stream_sv')
        ->line('dSP;')
        ->line('ENTER;')
        ->line('SAVETMPS;')
        ->line('PUSHMARK(SP);')
        ->line('XPUSHs(s->stream_sv);')
        ->line('PUTBACK;')
        ->line('int count = call_method("is_finished", G_SCALAR);')
        ->line('SPAGAIN;')
        ->line('int is_finished = 0;')
        ->if('count > 0')
          ->line('is_finished = SvTRUE(POPs);')
        ->endif
        ->line('PUTBACK;')
        ->line('FREETMPS;')
        ->line('LEAVE;')
        ->if('is_finished')
          ->line('ST(0) = ST(0);')
          ->line('XSRETURN(1);')
        ->endif
      ->endif
      ->blank
      ->comment('Start SSE if not started')
      ->if('s->state == SSE_STATE_INIT && s->stream_sv')
        ->line('dSP;')
        ->line('ENTER;')
        ->line('SAVETMPS;')
        ->line('PUSHMARK(SP);')
        ->line('XPUSHs(s->stream_sv);')
        ->line('XPUSHs(sv_2mortal(newSViv(200)));')
        ->line('HV* hv = newHV();')
        ->line('(void)hv_store(hv, "Content-Type", 12, newSVpv("text/event-stream", 0), 0);')
        ->line('(void)hv_store(hv, "Cache-Control", 13, newSVpv("no-cache", 0), 0);')
        ->line('(void)hv_store(hv, "Connection", 10, newSVpv("keep-alive", 0), 0);')
        ->line('(void)hv_store(hv, "X-Accel-Buffering", 17, newSVpv("no", 0), 0);')
        ->line('XPUSHs(sv_2mortal(newRV_noinc((SV*)hv)));')
        ->line('PUTBACK;')
        ->line('call_method("headers", G_DISCARD);')
        ->line('FREETMPS;')
        ->line('LEAVE;')
        ->line('s->state = SSE_STATE_STARTED;')
      ->endif
      ->blank
      ->comment('Format comment')
      ->line('const char* text = SvPV_nolen(ST(1));')
      ->line('char buf[4096];')
      ->line('size_t len = sse_format_comment(buf, sizeof(buf), text);')
      ->blank
      ->comment('Write to stream')
      ->if('s->stream_sv && len > 0')
        ->line('dSP;')
        ->line('ENTER;')
        ->line('SAVETMPS;')
        ->line('PUSHMARK(SP);')
        ->line('XPUSHs(s->stream_sv);')
        ->line('XPUSHs(sv_2mortal(newSVpvn(buf, len)));')
        ->line('PUTBACK;')
        ->line('call_method("write", G_DISCARD);')
        ->line('FREETMPS;')
        ->line('LEAVE;')
      ->endif
      ->blank
      ->line('ST(0) = ST(0);')
      ->line('XSRETURN(1);')
      ->xs_end
      ->blank;
}

sub gen_xs_close {
    my ($class, $builder) = @_;

    $builder->xs_function('xs_sse_close')
      ->xs_preamble
      ->check_items(1, 1, '$sse->close')
      ->line('int id = SvIV(SvRV(ST(0)));')
      ->if('id < 0 || id >= SSE_MAX')
        ->line('ST(0) = ST(0);')
        ->line('XSRETURN(1);')
      ->endif
      ->blank
      ->line('SSEState* s = &sse_registry[id];')
      ->blank
      ->comment('Check if stream is finished')
      ->if('s->stream_sv')
        ->line('dSP;')
        ->line('ENTER;')
        ->line('SAVETMPS;')
        ->line('PUSHMARK(SP);')
        ->line('XPUSHs(s->stream_sv);')
        ->line('PUTBACK;')
        ->line('int count = call_method("is_finished", G_SCALAR);')
        ->line('SPAGAIN;')
        ->line('int is_finished = 0;')
        ->if('count > 0')
          ->line('is_finished = SvTRUE(POPs);')
        ->endif
        ->line('PUTBACK;')
        ->line('FREETMPS;')
        ->line('LEAVE;')
        ->if('is_finished')
          ->line('ST(0) = ST(0);')
          ->line('XSRETURN(1);')
        ->endif
      ->endif
      ->blank
      ->comment('Call end on stream')
      ->if('s->stream_sv')
        ->line('dSP;')
        ->line('ENTER;')
        ->line('SAVETMPS;')
        ->line('PUSHMARK(SP);')
        ->line('XPUSHs(s->stream_sv);')
        ->line('PUTBACK;')
        ->line('call_method("end", G_DISCARD);')
        ->line('FREETMPS;')
        ->line('LEAVE;')
      ->endif
      ->blank
      ->line('s->state = SSE_STATE_FINISHED;')
      ->blank
      ->line('ST(0) = ST(0);')
      ->line('XSRETURN(1);')
      ->xs_end
      ->blank;
}

sub get_xs_functions {
    return {
        'Hypersonic::SSE::new'             => { source => 'xs_sse_new', is_xs_native => 1 },
        'Hypersonic::SSE::stream'          => { source => 'xs_sse_stream', is_xs_native => 1 },
        'Hypersonic::SSE::is_started'      => { source => 'xs_sse_is_started', is_xs_native => 1 },
        'Hypersonic::SSE::event_count'     => { source => 'xs_sse_event_count', is_xs_native => 1 },
        'Hypersonic::SSE::last_event_time' => { source => 'xs_sse_last_event_time', is_xs_native => 1 },
        'Hypersonic::SSE::needs_keepalive' => { source => 'xs_sse_needs_keepalive', is_xs_native => 1 },
        'Hypersonic::SSE::event'           => { source => 'xs_sse_event', is_xs_native => 1 },
        'Hypersonic::SSE::data'            => { source => 'xs_sse_data', is_xs_native => 1 },
        'Hypersonic::SSE::retry'           => { source => 'xs_sse_retry', is_xs_native => 1 },
        'Hypersonic::SSE::keepalive'       => { source => 'xs_sse_keepalive', is_xs_native => 1 },
        'Hypersonic::SSE::comment'         => { source => 'xs_sse_comment', is_xs_native => 1 },
        'Hypersonic::SSE::close'           => { source => 'xs_sse_close', is_xs_native => 1 },
    };
}

1;

__END__

=head1 CLIENT EXAMPLE

JavaScript:

    const events = new EventSource('/events');
    
    events.onmessage = (e) => {
        console.log('Message:', e.data);
    };
    
    events.addEventListener('update', (e) => {
        console.log('Update:', JSON.parse(e.data));
        console.log('Event ID:', e.lastEventId);
    });
    
    events.onerror = (e) => {
        if (e.target.readyState === EventSource.CLOSED) {
            console.log('Connection closed');
        } else {
            console.log('Error, will auto-reconnect');
        }
    };

=head1 RECONNECTION

The browser automatically reconnects when the connection drops.
Use the C<id> field to enable resumption:

    $app->get('/events' => sub {
        my ($req, $stream) = @_;
        
        my $last_id = $req->header('Last-Event-ID') // 0;
        my $sse = Hypersonic::SSE->new($stream);
        
        for my $id (($last_id + 1) .. 100) {
            $sse->event(
                type => 'update',
                data => "Event $id",
                id   => $id,
            );
        }
        
        $sse->close();
    }, { streaming => 1 });

=head1 SEE ALSO

L<Hypersonic::Stream>, L<Hypersonic::Protocol::SSE>

=head1 AUTHOR

Hypersonic Contributors

=cut
