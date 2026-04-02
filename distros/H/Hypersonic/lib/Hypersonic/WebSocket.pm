package Hypersonic::WebSocket;
use strict;
use warnings;
use 5.010;

# Hypersonic::WebSocket - High-level WebSocket connection API
#
# Provides an event-driven interface for WebSocket connections:
#   $ws->on(open => sub { ... });
#   $ws->on(message => sub { my ($data) = @_; ... });
#   $ws->on(close => sub { my ($code, $reason) = @_; ... });
#   $ws->send($data);
#   $ws->close();

our $VERSION = '0.12';

use Scalar::Util ();
use Hypersonic::Protocol::WebSocket;
use Hypersonic::Protocol::WebSocket::Frame;

# Connection states
use constant {
    STATE_CONNECTING => 0,
    STATE_OPEN       => 1,
    STATE_CLOSING    => 2,
    STATE_CLOSED     => 3,
};
use constant MAX_WEBSOCKETS => 65536;

# State constants for external use
sub CONNECTING { STATE_CONNECTING }
sub OPEN       { STATE_OPEN }
sub CLOSING    { STATE_CLOSING }
sub CLOSED     { STATE_CLOSED }

# ============================================================
# XS Code Generation - ALL instance methods generated in C
# ============================================================

sub generate_c_code {
    my ($class, $builder, $opts) = @_;
    $opts //= {};
    my $max = $opts->{max_websockets} // MAX_WEBSOCKETS;

    $class->gen_websocket_registry($builder, $max);
    $class->gen_ws_helpers($builder);
    $class->gen_xs_new($builder);
    $class->gen_xs_fd($builder);
    $class->gen_xs_state($builder);
    $class->gen_xs_protocol($builder);
    $class->gen_xs_stream($builder);
    $class->gen_xs_request($builder);
    $class->gen_xs_is_open($builder);
    $class->gen_xs_is_closing($builder);
    $class->gen_xs_is_closed($builder);
    $class->gen_xs_on($builder);
    $class->gen_xs_emit($builder);
    $class->gen_xs_accept($builder);
    $class->gen_xs_send($builder);
    $class->gen_xs_send_binary($builder);
    $class->gen_xs_ping($builder);
    $class->gen_xs_pong($builder);
    $class->gen_xs_close($builder);
    $class->gen_xs_handle_close($builder);
    $class->gen_xs_handle_message($builder);
    $class->gen_xs_process_data($builder);
    $class->gen_xs_flush_send_buffer($builder);
    $class->gen_xs_param($builder);
    $class->gen_xs_header($builder);

    return $builder;
}

sub gen_websocket_registry {
    my ($class, $builder, $max) = @_;

    $builder->comment('WebSocket connection registry - O(1) lookup by fd')
      ->line('#define WS_MAX ' . $max)
      ->line('#define WS_STATE_CONNECTING  0')
      ->line('#define WS_STATE_OPEN        1')
      ->line('#define WS_STATE_CLOSING     2')
      ->line('#define WS_STATE_CLOSED      3')
      ->blank
      ->line('typedef struct {')
      ->line('    int state;')
      ->line('    int close_code;')
      ->line('    char protocol[128];')
      ->line('    char close_reason[128];')
      ->line('    SV* ws_object;')  # Store the WebSocket Perl object
      ->line('} WSConnectionState;')
      ->blank
      ->line('static WSConnectionState ws_registry[WS_MAX];')
      ->blank;
}

sub gen_ws_helpers {
    my ($class, $builder) = @_;

    $builder->comment('Reset WebSocket connection state')
      ->line('static void ws_reset(int fd) {')
      ->line('    if (fd < 0 || fd >= WS_MAX) return;')
      ->line('    if (ws_registry[fd].ws_object) {')
      ->line('        SvREFCNT_dec(ws_registry[fd].ws_object);')
      ->line('    }')
      ->line('    memset(&ws_registry[fd], 0, sizeof(WSConnectionState));')
      ->line('    ws_registry[fd].state = WS_STATE_CONNECTING;')
      ->line('    ws_registry[fd].close_code = 0;')
      ->line('    ws_registry[fd].ws_object = NULL;')
      ->line('}')
      ->blank;

    $builder->comment('Set WebSocket state')
      ->line('static void ws_set_state(int fd, int state) {')
      ->line('    if (fd >= 0 && fd < WS_MAX) {')
      ->line('        ws_registry[fd].state = state;')
      ->line('    }')
      ->line('}')
      ->blank;
}

sub gen_xs_new {
    my ($class, $builder) = @_;

    $builder->xs_function('xs_websocket_new')
      ->xs_preamble
      ->line('HV* self_hv = newHV();')
      ->line('SV* self_rv = newRV_noinc((SV*)self_hv);')
      ->line('sv_bless(self_rv, gv_stashpv("Hypersonic::WebSocket", GV_ADD));')
      ->blank
      ->line('int fd = -1;')
      ->line('SV* stream_sv = NULL;')
      ->line('SV* request_sv = NULL;')
      ->line('SV* protocol_sv = NULL;')
      ->line('IV max_message_size = 16 * 1024 * 1024;')
      ->blank
      ->comment('First arg is stream object')
      ->if('items >= 2')
        ->line('stream_sv = ST(1);')
      ->endif
      ->blank
      ->comment('Parse hash args: new($stream, fd => N, protocol => P, ...)')
      ->for('int i = 2', 'i < items', 'i += 2')
        ->if('i + 1 < items')
          ->line('STRLEN klen;')
          ->line('const char* key = SvPV(ST(i), klen);')
          ->if('klen == 2 && strncmp(key, "fd", 2) == 0')
            ->line('fd = SvIV(ST(i + 1));')
          ->endif
          ->if('klen == 7 && strncmp(key, "request", 7) == 0')
            ->line('request_sv = ST(i + 1);')
          ->endif
          ->if('klen == 8 && strncmp(key, "protocol", 8) == 0')
            ->line('protocol_sv = ST(i + 1);')
          ->endif
          ->if('klen == 16 && strncmp(key, "max_message_size", 16) == 0')
            ->line('max_message_size = SvIV(ST(i + 1));')
          ->endif
        ->endif
      ->endfor
      ->blank
      ->comment('Store stream reference')
      ->if('stream_sv')
        ->line('hv_stores(self_hv, "stream", newSVsv(stream_sv));')
      ->endif
      ->blank
      ->comment('Store fd and initialize registry')
      ->line('hv_stores(self_hv, "fd", newSViv(fd));')
      ->if('fd >= 0 && fd < WS_MAX')
        ->line('ws_reset(fd);')
        ->if('protocol_sv && SvOK(protocol_sv)')
          ->line('STRLEN plen;')
          ->line('const char* proto = SvPV(protocol_sv, plen);')
          ->if('plen < sizeof(ws_registry[fd].protocol)')
            ->line('memcpy(ws_registry[fd].protocol, proto, plen);')
            ->line('ws_registry[fd].protocol[plen] = \'\\0\';')
          ->endif
        ->endif
      ->endif
      ->blank
      ->comment('Store request reference')
      ->if('request_sv')
        ->line('hv_stores(self_hv, "request", newSVsv(request_sv));')
      ->endif
      ->blank
      ->comment('Store protocol as Perl scalar')
      ->if('protocol_sv && SvOK(protocol_sv)')
        ->line('hv_stores(self_hv, "protocol", newSVsv(protocol_sv));')
      ->endif
      ->blank
      ->comment('Initialize Perl-side fields for event handling')
      ->line('hv_stores(self_hv, "handlers", newRV_noinc((SV*)newHV()));')
      ->line('hv_stores(self_hv, "buffer", newSVpvn("", 0));')
      ->line('hv_stores(self_hv, "fragments", newRV_noinc((SV*)newAV()));')
      ->line('hv_stores(self_hv, "send_buffer", newRV_noinc((SV*)newAV()));')
      ->line('hv_stores(self_hv, "max_message_size", newSViv(max_message_size));')
      ->blank
      ->line('ST(0) = sv_2mortal(self_rv);')
      ->line('XSRETURN(1);')
      ->xs_end
      ->blank;
}

sub gen_xs_fd {
    my ($class, $builder) = @_;

    $builder->xs_function('xs_websocket_fd')
      ->xs_preamble
      ->check_items(1, 1, '$ws->fd')
      ->line('HV* self_hv = (HV*)SvRV(ST(0));')
      ->line('SV** fd_sv = hv_fetchs(self_hv, "fd", 0);')
      ->if('fd_sv && *fd_sv')
        ->line('XSRETURN_IV(SvIV(*fd_sv));')
      ->endif
      ->line('XSRETURN_IV(-1);')
      ->xs_end
      ->blank;
}

sub gen_xs_state {
    my ($class, $builder) = @_;

    $builder->xs_function('xs_websocket_state')
      ->xs_preamble
      ->check_items(1, 1, '$ws->state')
      ->line('HV* self_hv = (HV*)SvRV(ST(0));')
      ->line('SV** fd_sv = hv_fetchs(self_hv, "fd", 0);')
      ->if('fd_sv && *fd_sv')
        ->line('int fd = SvIV(*fd_sv);')
        ->if('fd >= 0 && fd < WS_MAX')
          ->line('XSRETURN_IV(ws_registry[fd].state);')
        ->endif
      ->endif
      ->line('XSRETURN_IV(WS_STATE_CONNECTING);')
      ->xs_end
      ->blank;
}

sub gen_xs_protocol {
    my ($class, $builder) = @_;

    $builder->xs_function('xs_websocket_protocol')
      ->xs_preamble
      ->check_items(1, 1, '$ws->protocol')
      ->line('HV* self_hv = (HV*)SvRV(ST(0));')
      ->line('SV** fd_sv = hv_fetchs(self_hv, "fd", 0);')
      ->if('fd_sv && *fd_sv')
        ->line('int fd = SvIV(*fd_sv);')
        ->if('fd >= 0 && fd < WS_MAX && ws_registry[fd].protocol[0]')
          ->line('XSRETURN_PV(ws_registry[fd].protocol);')
        ->endif
      ->endif
      ->line('SV** proto_sv = hv_fetchs(self_hv, "protocol", 0);')
      ->if('proto_sv && *proto_sv && SvOK(*proto_sv)')
        ->line('ST(0) = *proto_sv;')
        ->line('XSRETURN(1);')
      ->endif
      ->line('XSRETURN_UNDEF;')
      ->xs_end
      ->blank;
}

sub gen_xs_stream {
    my ($class, $builder) = @_;

    $builder->xs_function('xs_websocket_stream')
      ->xs_preamble
      ->check_items(1, 1, '$ws->stream')
      ->line('HV* self_hv = (HV*)SvRV(ST(0));')
      ->line('SV** stream_sv = hv_fetchs(self_hv, "stream", 0);')
      ->if('stream_sv && *stream_sv && SvOK(*stream_sv)')
        ->line('ST(0) = *stream_sv;')
        ->line('XSRETURN(1);')
      ->endif
      ->line('XSRETURN_UNDEF;')
      ->xs_end
      ->blank;
}

sub gen_xs_request {
    my ($class, $builder) = @_;

    $builder->xs_function('xs_websocket_request')
      ->xs_preamble
      ->check_items(1, 1, '$ws->request')
      ->line('HV* self_hv = (HV*)SvRV(ST(0));')
      ->line('SV** req_sv = hv_fetchs(self_hv, "request", 0);')
      ->if('req_sv && *req_sv && SvOK(*req_sv)')
        ->line('ST(0) = *req_sv;')
        ->line('XSRETURN(1);')
      ->endif
      ->line('XSRETURN_UNDEF;')
      ->xs_end
      ->blank;
}

sub gen_xs_is_open {
    my ($class, $builder) = @_;

    $builder->xs_function('xs_websocket_is_open')
      ->xs_preamble
      ->check_items(1, 1, '$ws->is_open')
      ->line('HV* self_hv = (HV*)SvRV(ST(0));')
      ->line('SV** fd_sv = hv_fetchs(self_hv, "fd", 0);')
      ->if('fd_sv && *fd_sv')
        ->line('int fd = SvIV(*fd_sv);')
        ->if('fd >= 0 && fd < WS_MAX && ws_registry[fd].state == WS_STATE_OPEN')
          ->line('XSRETURN_YES;')
        ->endif
      ->endif
      ->line('XSRETURN_NO;')
      ->xs_end
      ->blank;
}

sub gen_xs_is_closing {
    my ($class, $builder) = @_;

    $builder->xs_function('xs_websocket_is_closing')
      ->xs_preamble
      ->check_items(1, 1, '$ws->is_closing')
      ->line('HV* self_hv = (HV*)SvRV(ST(0));')
      ->line('SV** fd_sv = hv_fetchs(self_hv, "fd", 0);')
      ->if('fd_sv && *fd_sv')
        ->line('int fd = SvIV(*fd_sv);')
        ->if('fd >= 0 && fd < WS_MAX && ws_registry[fd].state == WS_STATE_CLOSING')
          ->line('XSRETURN_YES;')
        ->endif
      ->endif
      ->line('XSRETURN_NO;')
      ->xs_end
      ->blank;
}

sub gen_xs_is_closed {
    my ($class, $builder) = @_;

    $builder->xs_function('xs_websocket_is_closed')
      ->xs_preamble
      ->check_items(1, 1, '$ws->is_closed')
      ->line('HV* self_hv = (HV*)SvRV(ST(0));')
      ->line('SV** fd_sv = hv_fetchs(self_hv, "fd", 0);')
      ->if('fd_sv && *fd_sv')
        ->line('int fd = SvIV(*fd_sv);')
        ->if('fd >= 0 && fd < WS_MAX && ws_registry[fd].state == WS_STATE_CLOSED')
          ->line('XSRETURN_YES;')
        ->endif
      ->endif
      ->line('XSRETURN_NO;')
      ->xs_end
      ->blank;
}

sub gen_xs_on {
    my ($class, $builder) = @_;

    $builder->xs_function('xs_websocket_on')
      ->xs_preamble
      ->if('items != 3')
        ->line('croak("Usage: $ws->on(event, handler)");')
      ->endif
      ->line('HV* self_hv = (HV*)SvRV(ST(0));')
      ->line('STRLEN elen;')
      ->line('const char* event = SvPV(ST(1), elen);')
      ->line('SV* handler = ST(2);')
      ->blank
      ->comment('Validate event name')
      ->line('int valid = 0;')
      ->if('elen == 4 && strncmp(event, "open", 4) == 0') ->line('valid = 1;') ->endif
      ->if('elen == 7 && strncmp(event, "message", 7) == 0') ->line('valid = 1;') ->endif
      ->if('elen == 6 && strncmp(event, "binary", 6) == 0') ->line('valid = 1;') ->endif
      ->if('elen == 4 && strncmp(event, "ping", 4) == 0') ->line('valid = 1;') ->endif
      ->if('elen == 4 && strncmp(event, "pong", 4) == 0') ->line('valid = 1;') ->endif
      ->if('elen == 5 && strncmp(event, "close", 5) == 0') ->line('valid = 1;') ->endif
      ->if('elen == 5 && strncmp(event, "error", 5) == 0') ->line('valid = 1;') ->endif
      ->blank
      ->if('!valid')
        ->line('warn("Unknown WebSocket event: %s", event);')
        ->line('ST(0) = ST(0);')
        ->line('XSRETURN(1);')
      ->endif
      ->blank
      ->comment('Store handler in handlers hash')
      ->line('SV** handlers_rv = hv_fetchs(self_hv, "handlers", 0);')
      ->if('handlers_rv && *handlers_rv && SvROK(*handlers_rv)')
        ->line('HV* handlers_hv = (HV*)SvRV(*handlers_rv);')
        ->line('hv_store(handlers_hv, event, elen, newSVsv(handler), 0);')
      ->endif
      ->blank
      ->line('ST(0) = ST(0);')
      ->line('XSRETURN(1);')
      ->xs_end
      ->blank;
}

sub gen_xs_emit {
    my ($class, $builder) = @_;

    $builder->xs_function('xs_websocket_emit')
      ->xs_preamble
      ->if('items < 2')
        ->line('croak("Usage: $ws->emit(event, ...)");')
      ->endif
      ->line('HV* self_hv = (HV*)SvRV(ST(0));')
      ->line('STRLEN elen;')
      ->line('const char* event = SvPV(ST(1), elen);')
      ->blank
      ->comment('Get handler from handlers hash')
      ->line('SV** handlers_rv = hv_fetchs(self_hv, "handlers", 0);')
      ->if('!handlers_rv || !*handlers_rv || !SvROK(*handlers_rv)')
        ->line('ST(0) = ST(0);')
        ->line('XSRETURN(1);')
      ->endif
      ->blank
      ->line('HV* handlers_hv = (HV*)SvRV(*handlers_rv);')
      ->line('SV** handler_sv = hv_fetch(handlers_hv, event, elen, 0);')
      ->if('!handler_sv || !*handler_sv || !SvOK(*handler_sv)')
        ->line('ST(0) = ST(0);')
        ->line('XSRETURN(1);')
      ->endif
      ->blank
      ->comment('Call the handler with remaining args')
      ->line('ENTER;')
      ->line('SAVETMPS;')
      ->line('PUSHMARK(SP);')
      ->for('int i = 2', 'i < items', 'i++')
        ->line('XPUSHs(ST(i));')
      ->endfor
      ->line('PUTBACK;')
      ->blank
      ->line('int count = call_sv(*handler_sv, G_EVAL | G_DISCARD);')
      ->blank
      ->if('SvTRUE(ERRSV)')
        ->line('warn("WebSocket %s handler error: %s", event, SvPV_nolen(ERRSV));')
        ->comment('Emit error event if not already handling error')
        ->if('!(elen == 5 && strncmp(event, "error", 5) == 0)')
          ->line('SV** err_handler = hv_fetchs(handlers_hv, "error", 0);')
          ->if('err_handler && *err_handler && SvOK(*err_handler)')
            ->line('PUSHMARK(SP);')
            ->line('XPUSHs(ERRSV);')
            ->line('PUTBACK;')
            ->line('call_sv(*err_handler, G_EVAL | G_DISCARD);')
          ->endif
        ->endif
      ->endif
      ->blank
      ->line('FREETMPS;')
      ->line('LEAVE;')
      ->blank
      ->line('ST(0) = ST(0);')
      ->line('XSRETURN(1);')
      ->xs_end
      ->blank;
}

sub gen_xs_accept {
    my ($class, $builder) = @_;

    $builder->xs_function('xs_websocket_accept')
      ->xs_preamble
      ->if('items != 2')
        ->line('croak("Usage: $ws->accept(handshake)");')
      ->endif
      ->line('HV* self_hv = (HV*)SvRV(ST(0));')
      ->line('SV* handshake_sv = ST(1);')
      ->blank
      ->comment('Get fd and check state')
      ->line('SV** fd_sv = hv_fetchs(self_hv, "fd", 0);')
      ->line('int fd = (fd_sv && *fd_sv) ? SvIV(*fd_sv) : -1;')
      ->blank
      ->if('fd >= 0 && fd < WS_MAX && ws_registry[fd].state != WS_STATE_CONNECTING')
        ->line('XSRETURN_IV(0);')
      ->endif
      ->blank
      ->comment('Check handshake is valid hashref with is_websocket')
      ->if('!SvROK(handshake_sv) || SvTYPE(SvRV(handshake_sv)) != SVt_PVHV')
        ->line('XSRETURN_IV(0);')
      ->endif
      ->blank
      ->line('HV* hs_hv = (HV*)SvRV(handshake_sv);')
      ->line('SV** is_ws = hv_fetchs(hs_hv, "is_websocket", 0);')
      ->if('!is_ws || !*is_ws || !SvTRUE(*is_ws)')
        ->line('XSRETURN_IV(0);')
      ->endif
      ->blank
      ->comment('Call Perl to build response (uses Protocol::WebSocket)')
      ->line('ENTER;')
      ->line('SAVETMPS;')
      ->line('PUSHMARK(SP);')
      ->line('XPUSHs(sv_2mortal(newSVpvs("Hypersonic::Protocol::WebSocket")));')
      ->blank
      ->comment('Get ws_key')
      ->line('SV** ws_key = hv_fetchs(hs_hv, "ws_key", 0);')
      ->if('ws_key && *ws_key')
        ->line('XPUSHs(sv_2mortal(newSVpvs("key")));')
        ->line('XPUSHs(*ws_key);')
      ->endif
      ->blank
      ->comment('Get protocol')
      ->line('SV** proto_sv = hv_fetchs(self_hv, "protocol", 0);')
      ->if('!proto_sv || !*proto_sv || !SvOK(*proto_sv)')
        ->line('proto_sv = hv_fetchs(hs_hv, "ws_protocol", 0);')
      ->endif
      ->if('proto_sv && *proto_sv && SvOK(*proto_sv)')
        ->line('XPUSHs(sv_2mortal(newSVpvs("protocol")));')
        ->line('XPUSHs(*proto_sv);')
      ->endif
      ->blank
      ->line('PUTBACK;')
      ->line('int count = call_method("build_response", G_SCALAR);')
      ->line('SPAGAIN;')
      ->blank
      ->if('count != 1')
        ->line('FREETMPS;')
        ->line('LEAVE;')
        ->line('XSRETURN_IV(0);')
      ->endif
      ->blank
      ->line('SV* response = POPs;')
      ->blank
      ->comment('Write response via stream')
      ->line('SV** stream_sv = hv_fetchs(self_hv, "stream", 0);')
      ->if('stream_sv && *stream_sv && SvROK(*stream_sv)')
        ->line('PUSHMARK(SP);')
        ->line('XPUSHs(*stream_sv);')
        ->line('XPUSHs(response);')
        ->line('PUTBACK;')
        ->line('call_method("_raw_write", G_DISCARD | G_EVAL);')
      ->endif
      ->blank
      ->line('FREETMPS;')
      ->line('LEAVE;')
      ->blank
      ->comment('Transition to open state')
      ->if('fd >= 0 && fd < WS_MAX')
        ->line('ws_registry[fd].state = WS_STATE_OPEN;')
      ->endif
      ->blank
      ->comment('Emit open event')
      ->line('SV** handlers_rv = hv_fetchs(self_hv, "handlers", 0);')
      ->if('handlers_rv && *handlers_rv && SvROK(*handlers_rv)')
        ->line('HV* handlers_hv = (HV*)SvRV(*handlers_rv);')
        ->line('SV** open_handler = hv_fetchs(handlers_hv, "open", 0);')
        ->if('open_handler && *open_handler && SvOK(*open_handler)')
          ->line('PUSHMARK(SP);')
          ->line('PUTBACK;')
          ->line('call_sv(*open_handler, G_DISCARD | G_EVAL);')
        ->endif
      ->endif
      ->blank
      ->line('XSRETURN_IV(1);')
      ->xs_end
      ->blank;
}

sub gen_xs_send {
    my ($class, $builder) = @_;

    $builder->xs_function('xs_websocket_send')
      ->xs_preamble
      ->if('items != 2')
        ->line('croak("Usage: $ws->send(data)");')
      ->endif
      ->line('HV* self_hv = (HV*)SvRV(ST(0));')
      ->line('SV** fd_sv = hv_fetchs(self_hv, "fd", 0);')
      ->blank
      ->if('!fd_sv || !*fd_sv')
        ->line('XSRETURN_IV(0);')
      ->endif
      ->blank
      ->line('int fd = SvIV(*fd_sv);')
      ->if('fd < 0 || fd >= WS_MAX || ws_registry[fd].state != WS_STATE_OPEN')
        ->line('XSRETURN_IV(0);')
      ->endif
      ->blank
      ->line('STRLEN len;')
      ->line('const char* data = SvPV(ST(1), len);')
      ->if('!SvOK(ST(1))')
        ->line('XSRETURN_IV(0);')
      ->endif
      ->blank
      ->comment('Encode text frame')
      ->line('uint8_t frame[65546];')
      ->line('size_t frame_len = ws_encode_text(frame, sizeof(frame), data, len);')
      ->if('frame_len == 0')
        ->line('XSRETURN_IV(0);')
      ->endif
      ->blank
      ->comment('Send directly to fd')
      ->line('ssize_t sent = send(fd, frame, frame_len, 0);')
      ->if('sent < 0')
        ->line('XSRETURN_IV(0);')
      ->endif
      ->blank
      ->line('XSRETURN_IV(1);')
      ->xs_end
      ->blank;
}

sub gen_xs_send_binary {
    my ($class, $builder) = @_;

    $builder->xs_function('xs_websocket_send_binary')
      ->xs_preamble
      ->if('items != 2')
        ->line('croak("Usage: $ws->send_binary(data)");')
      ->endif
      ->line('HV* self_hv = (HV*)SvRV(ST(0));')
      ->line('SV** fd_sv = hv_fetchs(self_hv, "fd", 0);')
      ->blank
      ->if('!fd_sv || !*fd_sv')
        ->line('XSRETURN_IV(0);')
      ->endif
      ->blank
      ->line('int fd = SvIV(*fd_sv);')
      ->if('fd < 0 || fd >= WS_MAX || ws_registry[fd].state != WS_STATE_OPEN')
        ->line('XSRETURN_IV(0);')
      ->endif
      ->blank
      ->line('STRLEN len;')
      ->line('const char* data = SvPV(ST(1), len);')
      ->if('!SvOK(ST(1))')
        ->line('XSRETURN_IV(0);')
      ->endif
      ->blank
      ->line('uint8_t frame[65546];')
      ->line('size_t frame_len = ws_encode_binary(frame, sizeof(frame), (const uint8_t*)data, len);')
      ->if('frame_len == 0')
        ->line('XSRETURN_IV(0);')
      ->endif
      ->blank
      ->line('ssize_t sent = send(fd, frame, frame_len, 0);')
      ->if('sent < 0')
        ->line('XSRETURN_IV(0);')
      ->endif
      ->blank
      ->line('XSRETURN_IV(1);')
      ->xs_end
      ->blank;
}

sub gen_xs_ping {
    my ($class, $builder) = @_;

    $builder->xs_function('xs_websocket_ping')
      ->xs_preamble
      ->line('HV* self_hv = (HV*)SvRV(ST(0));')
      ->line('SV** fd_sv = hv_fetchs(self_hv, "fd", 0);')
      ->blank
      ->if('!fd_sv || !*fd_sv')
        ->line('XSRETURN_IV(0);')
      ->endif
      ->blank
      ->line('int fd = SvIV(*fd_sv);')
      ->if('fd < 0 || fd >= WS_MAX || ws_registry[fd].state != WS_STATE_OPEN')
        ->line('XSRETURN_IV(0);')
      ->endif
      ->blank
      ->line('const char* data = "";')
      ->line('STRLEN len = 0;')
      ->if('items >= 2 && SvOK(ST(1))')
        ->line('data = SvPV(ST(1), len);')
      ->endif
      ->blank
      ->line('uint8_t frame[256];')
      ->line('size_t frame_len = ws_encode_ping(frame, sizeof(frame), (const uint8_t*)data, len);')
      ->if('frame_len == 0')
        ->line('XSRETURN_IV(0);')
      ->endif
      ->blank
      ->line('ssize_t sent = send(fd, frame, frame_len, 0);')
      ->if('sent < 0')
        ->line('XSRETURN_IV(0);')
      ->endif
      ->blank
      ->line('XSRETURN_IV(1);')
      ->xs_end
      ->blank;
}

sub gen_xs_pong {
    my ($class, $builder) = @_;

    $builder->xs_function('xs_websocket_pong')
      ->xs_preamble
      ->line('HV* self_hv = (HV*)SvRV(ST(0));')
      ->line('SV** fd_sv = hv_fetchs(self_hv, "fd", 0);')
      ->blank
      ->if('!fd_sv || !*fd_sv')
        ->line('XSRETURN_IV(0);')
      ->endif
      ->blank
      ->line('int fd = SvIV(*fd_sv);')
      ->if('fd < 0 || fd >= WS_MAX || ws_registry[fd].state != WS_STATE_OPEN')
        ->line('XSRETURN_IV(0);')
      ->endif
      ->blank
      ->line('const char* data = "";')
      ->line('STRLEN len = 0;')
      ->if('items >= 2 && SvOK(ST(1))')
        ->line('data = SvPV(ST(1), len);')
      ->endif
      ->blank
      ->line('uint8_t frame[256];')
      ->line('size_t frame_len = ws_encode_pong(frame, sizeof(frame), (const uint8_t*)data, len);')
      ->if('frame_len == 0')
        ->line('XSRETURN_IV(0);')
      ->endif
      ->blank
      ->line('ssize_t sent = send(fd, frame, frame_len, 0);')
      ->if('sent < 0')
        ->line('XSRETURN_IV(0);')
      ->endif
      ->blank
      ->line('XSRETURN_IV(1);')
      ->xs_end
      ->blank;
}

sub gen_xs_close {
    my ($class, $builder) = @_;

    $builder->xs_function('xs_websocket_close')
      ->xs_preamble
      ->line('HV* self_hv = (HV*)SvRV(ST(0));')
      ->line('SV** fd_sv = hv_fetchs(self_hv, "fd", 0);')
      ->blank
      ->if('!fd_sv || !*fd_sv')
        ->line('XSRETURN_IV(0);')
      ->endif
      ->blank
      ->line('int fd = SvIV(*fd_sv);')
      ->if('fd < 0 || fd >= WS_MAX || ws_registry[fd].state >= WS_STATE_CLOSING')
        ->line('XSRETURN_IV(0);')
      ->endif
      ->blank
      ->line('uint16_t code = 1000;')
      ->line('const char* reason = "";')
      ->line('STRLEN reason_len = 0;')
      ->blank
      ->if('items >= 2 && SvOK(ST(1))')
        ->line('code = (uint16_t)SvIV(ST(1));')
      ->endif
      ->if('items >= 3 && SvOK(ST(2))')
        ->line('reason = SvPV(ST(2), reason_len);')
      ->endif
      ->blank
      ->line('ws_registry[fd].state = WS_STATE_CLOSING;')
      ->line('ws_registry[fd].close_code = code;')
      ->if('reason_len > 0 && reason_len < sizeof(ws_registry[fd].close_reason)')
        ->line('memcpy(ws_registry[fd].close_reason, reason, reason_len);')
        ->line('ws_registry[fd].close_reason[reason_len] = \'\\0\';')
      ->endif
      ->blank
      ->line('uint8_t frame[256];')
      ->line('size_t frame_len = ws_encode_close(frame, sizeof(frame), code, reason);')
      ->if('frame_len == 0')
        ->line('XSRETURN_IV(0);')
      ->endif
      ->blank
      ->line('ssize_t sent = send(fd, frame, frame_len, 0);')
      ->if('sent < 0')
        ->line('XSRETURN_IV(0);')
      ->endif
      ->blank
      ->line('XSRETURN_IV(1);')
      ->xs_end
      ->blank;
}

sub gen_xs_handle_close {
    my ($class, $builder) = @_;

    $builder->xs_function('xs_websocket_handle_close')
      ->xs_preamble
      ->line('HV* self_hv = (HV*)SvRV(ST(0));')
      ->line('SV** fd_sv = hv_fetchs(self_hv, "fd", 0);')
      ->line('int fd = (fd_sv && *fd_sv) ? SvIV(*fd_sv) : -1;')
      ->blank
      ->line('uint16_t code = 1000;')
      ->line('const char* reason = "";')
      ->line('STRLEN reason_len = 0;')
      ->if('items >= 2 && SvOK(ST(1))')
        ->line('code = (uint16_t)SvIV(ST(1));')
      ->endif
      ->if('items >= 3 && SvOK(ST(2))')
        ->line('reason = SvPV(ST(2), reason_len);')
      ->endif
      ->blank
      ->comment('If state is OPEN, echo close back')
      ->if('fd >= 0 && fd < WS_MAX && ws_registry[fd].state == WS_STATE_OPEN')
        ->line('ws_registry[fd].state = WS_STATE_CLOSING;')
        ->line('ws_registry[fd].close_code = code;')
        ->blank
        ->line('uint8_t frame[256];')
        ->line('size_t frame_len = ws_encode_close(frame, sizeof(frame), code, "");')
        ->if('frame_len > 0')
          ->line('send(fd, frame, frame_len, 0);')
        ->endif
      ->endif
      ->blank
      ->comment('Set state to CLOSED')
      ->if('fd >= 0 && fd < WS_MAX')
        ->line('ws_registry[fd].state = WS_STATE_CLOSED;')
      ->endif
      ->blank
      ->comment('Emit close event')
      ->line('SV** handlers_rv = hv_fetchs(self_hv, "handlers", 0);')
      ->if('handlers_rv && *handlers_rv && SvROK(*handlers_rv)')
        ->line('HV* handlers_hv = (HV*)SvRV(*handlers_rv);')
        ->line('SV** close_handler = hv_fetchs(handlers_hv, "close", 0);')
        ->if('close_handler && *close_handler && SvOK(*close_handler)')
          ->line('ENTER;')
          ->line('SAVETMPS;')
          ->line('PUSHMARK(SP);')
          ->line('XPUSHs(sv_2mortal(newSViv(code)));')
          ->if('reason_len > 0')
            ->line('XPUSHs(sv_2mortal(newSVpvn(reason, reason_len)));')
          ->else
            ->line('XPUSHs(&PL_sv_undef);')
          ->endif
          ->line('PUTBACK;')
          ->line('call_sv(*close_handler, G_DISCARD | G_EVAL);')
          ->line('FREETMPS;')
          ->line('LEAVE;')
        ->endif
      ->endif
      ->blank
      ->line('XSRETURN_IV(1);')
      ->xs_end
      ->blank;
}

sub gen_xs_handle_message {
    my ($class, $builder) = @_;

    $builder->xs_function('xs_websocket_handle_message')
      ->xs_preamble
      ->if('items != 3')
        ->line('croak("Usage: $ws->handle_message(opcode, data)");')
      ->endif
      ->line('HV* self_hv = (HV*)SvRV(ST(0));')
      ->line('int opcode = SvIV(ST(1));')
      ->line('SV* data_sv = ST(2);')
      ->blank
      ->line('SV** fd_sv = hv_fetchs(self_hv, "fd", 0);')
      ->line('int fd = (fd_sv && *fd_sv) ? SvIV(*fd_sv) : -1;')
      ->blank
      ->if('fd < 0 || fd >= WS_MAX || ws_registry[fd].state != WS_STATE_OPEN')
        ->line('XSRETURN_UNDEF;')
      ->endif
      ->blank
      ->line('SV** handlers_rv = hv_fetchs(self_hv, "handlers", 0);')
      ->if('!handlers_rv || !*handlers_rv || !SvROK(*handlers_rv)')
        ->line('XSRETURN_UNDEF;')
      ->endif
      ->line('HV* handlers_hv = (HV*)SvRV(*handlers_rv);')
      ->blank
      ->comment('Handle by opcode')
      ->if('opcode == WS_OP_TEXT')
        ->comment('Emit message event')
        ->line('SV** msg_handler = hv_fetchs(handlers_hv, "message", 0);')
        ->if('msg_handler && *msg_handler && SvOK(*msg_handler)')
          ->line('ENTER;')
          ->line('SAVETMPS;')
          ->line('PUSHMARK(SP);')
          ->line('XPUSHs(data_sv);')
          ->line('XPUSHs(sv_2mortal(newSViv(0)));')  # is_binary = 0
          ->line('PUTBACK;')
          ->line('call_sv(*msg_handler, G_DISCARD | G_EVAL);')
          ->line('FREETMPS;')
          ->line('LEAVE;')
        ->endif
      ->elsif('opcode == WS_OP_BINARY')
        ->comment('Emit binary event')
        ->line('SV** bin_handler = hv_fetchs(handlers_hv, "binary", 0);')
        ->if('bin_handler && *bin_handler && SvOK(*bin_handler)')
          ->line('ENTER;')
          ->line('SAVETMPS;')
          ->line('PUSHMARK(SP);')
          ->line('XPUSHs(data_sv);')
          ->line('PUTBACK;')
          ->line('call_sv(*bin_handler, G_DISCARD | G_EVAL);')
          ->line('FREETMPS;')
          ->line('LEAVE;')
        ->endif
        ->comment('Also emit message event')
        ->line('SV** msg_handler = hv_fetchs(handlers_hv, "message", 0);')
        ->if('msg_handler && *msg_handler && SvOK(*msg_handler)')
          ->line('ENTER;')
          ->line('SAVETMPS;')
          ->line('PUSHMARK(SP);')
          ->line('XPUSHs(data_sv);')
          ->line('XPUSHs(sv_2mortal(newSViv(1)));')  # is_binary = 1
          ->line('PUTBACK;')
          ->line('call_sv(*msg_handler, G_DISCARD | G_EVAL);')
          ->line('FREETMPS;')
          ->line('LEAVE;')
        ->endif
      ->elsif('opcode == WS_OP_PING')
        ->comment('Emit ping event')
        ->line('SV** ping_handler = hv_fetchs(handlers_hv, "ping", 0);')
        ->if('ping_handler && *ping_handler && SvOK(*ping_handler)')
          ->line('ENTER;')
          ->line('SAVETMPS;')
          ->line('PUSHMARK(SP);')
          ->line('XPUSHs(data_sv);')
          ->line('PUTBACK;')
          ->line('call_sv(*ping_handler, G_DISCARD | G_EVAL);')
          ->line('FREETMPS;')
          ->line('LEAVE;')
        ->endif
        ->comment('Auto-pong')
        ->line('STRLEN pong_len;')
        ->line('const char* pong_data = SvPV(data_sv, pong_len);')
        ->line('uint8_t pong_frame[256];')
        ->line('size_t pong_frame_len = ws_encode_pong(pong_frame, sizeof(pong_frame), (const uint8_t*)pong_data, pong_len);')
        ->if('pong_frame_len > 0')
          ->line('send(fd, pong_frame, pong_frame_len, 0);')
        ->endif
      ->elsif('opcode == WS_OP_PONG')
        ->comment('Emit pong event')
        ->line('SV** pong_handler = hv_fetchs(handlers_hv, "pong", 0);')
        ->if('pong_handler && *pong_handler && SvOK(*pong_handler)')
          ->line('ENTER;')
          ->line('SAVETMPS;')
          ->line('PUSHMARK(SP);')
          ->line('XPUSHs(data_sv);')
          ->line('PUTBACK;')
          ->line('call_sv(*pong_handler, G_DISCARD | G_EVAL);')
          ->line('FREETMPS;')
          ->line('LEAVE;')
        ->endif
      ->endif
      ->blank
      ->line('XSRETURN_UNDEF;')
      ->xs_end
      ->blank;
}

sub gen_xs_process_data {
    my ($class, $builder) = @_;

    $builder->xs_function('xs_websocket_process_data')
      ->xs_preamble
      ->if('items != 2')
        ->line('croak("Usage: $ws->process_data(data)");')
      ->endif
      ->line('SV* self_sv = ST(0);')
      ->line('HV* self_hv = (HV*)SvRV(self_sv);')
      ->line('STRLEN data_len;')
      ->line('const char* data = SvPV(ST(1), data_len);')
      ->blank
      ->comment('Append to buffer')
      ->line('SV** buffer_sv = hv_fetchs(self_hv, "buffer", 0);')
      ->if('!buffer_sv || !*buffer_sv')
        ->line('XSRETURN_IV(1);')
      ->endif
      ->line('sv_catpvn(*buffer_sv, data, data_len);')
      ->blank
      ->line('SV** fd_sv = hv_fetchs(self_hv, "fd", 0);')
      ->line('int fd = (fd_sv && *fd_sv) ? SvIV(*fd_sv) : -1;')
      ->blank
      ->comment('Process frames in buffer')
      ->while('SvCUR(*buffer_sv) >= 2')
        ->comment('Call Frame->decode_frame via Perl')
        ->line('ENTER;')
        ->line('SAVETMPS;')
        ->line('PUSHMARK(SP);')
        ->line('XPUSHs(sv_2mortal(newSVpvs("Hypersonic::Protocol::WebSocket::Frame")));')
        ->line('XPUSHs(*buffer_sv);')
        ->line('PUTBACK;')
        ->line('int count = call_method("decode_frame", G_SCALAR);')
        ->line('SPAGAIN;')
        ->blank
        ->if('count != 1')
          ->line('FREETMPS;')
          ->line('LEAVE;')
          ->line('break;')
        ->endif
        ->blank
        ->line('SV* frame_sv = POPs;')
        ->if('!SvROK(frame_sv) || SvTYPE(SvRV(frame_sv)) != SVt_PVHV')
          ->line('FREETMPS;')
          ->line('LEAVE;')
          ->line('break;')
        ->endif
        ->blank
        ->line('HV* frame_hv = (HV*)SvRV(frame_sv);')
        ->blank
        ->comment('Get frame fields')
        ->line('SV** total_size_sv = hv_fetchs(frame_hv, "total_size", 0);')
        ->line('SV** opcode_sv = hv_fetchs(frame_hv, "opcode", 0);')
        ->line('SV** fin_sv = hv_fetchs(frame_hv, "fin", 0);')
        ->line('SV** payload_sv = hv_fetchs(frame_hv, "payload", 0);')
        ->blank
        ->if('!total_size_sv || !opcode_sv')
          ->line('FREETMPS;')
          ->line('LEAVE;')
          ->line('break;')
        ->endif
        ->blank
        ->line('STRLEN total_size = SvIV(*total_size_sv);')
        ->line('int opcode = SvIV(*opcode_sv);')
        ->line('int fin = fin_sv && *fin_sv ? SvIV(*fin_sv) : 1;')
        ->blank
        ->comment('Remove consumed bytes from buffer')
        ->line('STRLEN buf_len;')
        ->line('char* buf = SvPV(*buffer_sv, buf_len);')
        ->line('sv_setpvn(*buffer_sv, buf + total_size, buf_len - total_size);')
        ->blank
        ->comment('Handle CLOSE frame')
        ->if('opcode == WS_OP_CLOSE')
          ->comment('Parse close code/reason')
          ->line('PUSHMARK(SP);')
          ->line('XPUSHs(sv_2mortal(newSVpvs("Hypersonic::Protocol::WebSocket::Frame")));')
          ->if('payload_sv && *payload_sv')
            ->line('XPUSHs(*payload_sv);')
          ->else
            ->line('XPUSHs(&PL_sv_undef);')
          ->endif
          ->line('PUTBACK;')
          ->line('count = call_method("parse_close", G_ARRAY);')
          ->line('SPAGAIN;')
          ->blank
          ->line('SV* reason_sv = &PL_sv_undef;')
          ->line('SV* code_sv = &PL_sv_undef;')
          ->if('count >= 2')
            ->line('reason_sv = POPs;')
            ->line('code_sv = POPs;')
          ->elsif('count >= 1')
            ->line('code_sv = POPs;')
          ->endif
          ->blank
          ->comment('Call handle_close')
          ->line('PUSHMARK(SP);')
          ->line('XPUSHs(self_sv);')
          ->line('XPUSHs(code_sv);')
          ->line('XPUSHs(reason_sv);')
          ->line('PUTBACK;')
          ->line('call_method("handle_close", G_DISCARD);')
          ->blank
          ->line('FREETMPS;')
          ->line('LEAVE;')
          ->line('XSRETURN_IV(0);')
        ->endif
        ->blank
        ->comment('Handle CONTINUATION frame')
        ->if('opcode == WS_OP_CONTINUATION')
          ->line('SV** fragments_rv = hv_fetchs(self_hv, "fragments", 0);')
          ->if('fragments_rv && *fragments_rv && SvROK(*fragments_rv)')
            ->line('AV* fragments_av = (AV*)SvRV(*fragments_rv);')
            ->if('payload_sv && *payload_sv')
              ->line('av_push(fragments_av, newSVsv(*payload_sv));')
            ->endif
            ->if('fin')
              ->comment('Complete fragmented message')
              ->line('SV* full_msg = newSVpvn("", 0);')
              ->line('I32 frag_len = av_len(fragments_av);')
              ->for('I32 i = 0', 'i <= frag_len', 'i++')
                ->line('SV** frag = av_fetch(fragments_av, i, 0);')
                ->if('frag && *frag')
                  ->line('sv_catsv(full_msg, *frag);')
                ->endif
              ->endfor
              ->line('av_clear(fragments_av);')
              ->blank
              ->line('SV** first_opcode_sv = hv_fetchs(self_hv, "fragment_opcode", 0);')
              ->line('int first_opcode = (first_opcode_sv && *first_opcode_sv) ? SvIV(*first_opcode_sv) : WS_OP_TEXT;')
              ->blank
              ->line('PUSHMARK(SP);')
              ->line('XPUSHs(self_sv);')
              ->line('XPUSHs(sv_2mortal(newSViv(first_opcode)));')
              ->line('XPUSHs(sv_2mortal(full_msg));')
              ->line('PUTBACK;')
              ->line('call_method("handle_message", G_DISCARD);')
            ->endif
          ->endif
        ->elsif('!fin')
          ->comment('Start of fragmented message')
          ->line('hv_stores(self_hv, "fragment_opcode", newSViv(opcode));')
          ->line('SV** fragments_rv = hv_fetchs(self_hv, "fragments", 0);')
          ->if('fragments_rv && *fragments_rv && SvROK(*fragments_rv)')
            ->line('AV* fragments_av = (AV*)SvRV(*fragments_rv);')
            ->line('av_clear(fragments_av);')
            ->if('payload_sv && *payload_sv')
              ->line('av_push(fragments_av, newSVsv(*payload_sv));')
            ->endif
          ->endif
        ->else
          ->comment('Complete message in single frame')
          ->line('PUSHMARK(SP);')
          ->line('XPUSHs(self_sv);')
          ->line('XPUSHs(sv_2mortal(newSViv(opcode)));')
          ->if('payload_sv && *payload_sv')
            ->line('XPUSHs(*payload_sv);')
          ->else
            ->line('XPUSHs(sv_2mortal(newSVpvn("", 0)));')
          ->endif
          ->line('PUTBACK;')
          ->line('call_method("handle_message", G_DISCARD);')
        ->endif
        ->blank
        ->line('FREETMPS;')
        ->line('LEAVE;')
      ->endloop
      ->blank
      ->line('XSRETURN_IV(1);')
      ->xs_end
      ->blank;
}

sub gen_xs_flush_send_buffer {
    my ($class, $builder) = @_;

    $builder->xs_function('xs_websocket_flush_send_buffer')
      ->xs_preamble
      ->check_items(1, 1, '$ws->_flush_send_buffer')
      ->line('HV* self_hv = (HV*)SvRV(ST(0));')
      ->blank
      ->line('SV** send_buffer_rv = hv_fetchs(self_hv, "send_buffer", 0);')
      ->if('!send_buffer_rv || !*send_buffer_rv || !SvROK(*send_buffer_rv)')
        ->line('XSRETURN_UNDEF;')
      ->endif
      ->blank
      ->line('AV* send_buffer_av = (AV*)SvRV(*send_buffer_rv);')
      ->if('av_len(send_buffer_av) < 0')
        ->line('XSRETURN_UNDEF;')
      ->endif
      ->blank
      ->line('SV** stream_sv = hv_fetchs(self_hv, "stream", 0);')
      ->if('!stream_sv || !*stream_sv || !SvROK(*stream_sv)')
        ->line('XSRETURN_UNDEF;')
      ->endif
      ->blank
      ->comment('Concatenate all frames')
      ->line('SV* data = newSVpvn("", 0);')
      ->line('I32 len = av_len(send_buffer_av);')
      ->for('I32 i = 0', 'i <= len', 'i++')
        ->line('SV** frame = av_fetch(send_buffer_av, i, 0);')
        ->if('frame && *frame')
          ->line('sv_catsv(data, *frame);')
        ->endif
      ->endfor
      ->line('av_clear(send_buffer_av);')
      ->blank
      ->comment('Write via stream')
      ->line('ENTER;')
      ->line('SAVETMPS;')
      ->line('PUSHMARK(SP);')
      ->line('XPUSHs(*stream_sv);')
      ->line('XPUSHs(sv_2mortal(data));')
      ->line('PUTBACK;')
      ->line('call_method("_raw_write", G_DISCARD | G_EVAL);')
      ->line('FREETMPS;')
      ->line('LEAVE;')
      ->blank
      ->line('XSRETURN_UNDEF;')
      ->xs_end
      ->blank;
}

sub gen_xs_param {
    my ($class, $builder) = @_;

    $builder->xs_function('xs_websocket_param')
      ->xs_preamble
      ->if('items != 2')
        ->line('croak("Usage: $ws->param(name)");')
      ->endif
      ->line('HV* self_hv = (HV*)SvRV(ST(0));')
      ->line('SV* name_sv = ST(1);')
      ->blank
      ->line('SV** req_sv = hv_fetchs(self_hv, "request", 0);')
      ->if('!req_sv || !*req_sv || !SvOK(*req_sv)')
        ->line('XSRETURN_UNDEF;')
      ->endif
      ->blank
      ->comment('If request is a hashref, check params')
      ->if('SvROK(*req_sv) && SvTYPE(SvRV(*req_sv)) == SVt_PVHV')
        ->line('HV* req_hv = (HV*)SvRV(*req_sv);')
        ->line('SV** params_sv = hv_fetchs(req_hv, "params", 0);')
        ->if('params_sv && *params_sv && SvROK(*params_sv)')
          ->line('HV* params_hv = (HV*)SvRV(*params_sv);')
          ->line('STRLEN nlen;')
          ->line('const char* name = SvPV(name_sv, nlen);')
          ->line('SV** val = hv_fetch(params_hv, name, nlen, 0);')
          ->if('val && *val')
            ->line('ST(0) = *val;')
            ->line('XSRETURN(1);')
          ->endif
        ->endif
        ->line('XSRETURN_UNDEF;')
      ->endif
      ->blank
      ->comment('If request is an object, call param method')
      ->line('ENTER;')
      ->line('SAVETMPS;')
      ->line('PUSHMARK(SP);')
      ->line('XPUSHs(*req_sv);')
      ->line('XPUSHs(name_sv);')
      ->line('PUTBACK;')
      ->line('int count = call_method("param", G_SCALAR | G_EVAL);')
      ->line('SPAGAIN;')
      ->blank
      ->if('count >= 1')
        ->line('SV* result = POPs;')
        ->line('ST(0) = sv_2mortal(newSVsv(result));')
        ->line('FREETMPS;')
        ->line('LEAVE;')
        ->line('XSRETURN(1);')
      ->endif
      ->blank
      ->line('FREETMPS;')
      ->line('LEAVE;')
      ->line('XSRETURN_UNDEF;')
      ->xs_end
      ->blank;
}

sub gen_xs_header {
    my ($class, $builder) = @_;

    $builder->xs_function('xs_websocket_header')
      ->xs_preamble
      ->if('items != 2')
        ->line('croak("Usage: $ws->header(name)");')
      ->endif
      ->line('HV* self_hv = (HV*)SvRV(ST(0));')
      ->line('STRLEN nlen;')
      ->line('const char* name = SvPV(ST(1), nlen);')
      ->blank
      ->line('SV** req_sv = hv_fetchs(self_hv, "request", 0);')
      ->if('!req_sv || !*req_sv || !SvOK(*req_sv)')
        ->line('XSRETURN_UNDEF;')
      ->endif
      ->blank
      ->comment('If request is a hashref, check headers')
      ->if('SvROK(*req_sv) && SvTYPE(SvRV(*req_sv)) == SVt_PVHV')
        ->line('HV* req_hv = (HV*)SvRV(*req_sv);')
        ->line('SV** headers_sv = hv_fetchs(req_hv, "headers", 0);')
        ->if('headers_sv && *headers_sv && SvROK(*headers_sv)')
          ->line('HV* headers_hv = (HV*)SvRV(*headers_sv);')
          ->comment('Lowercase the name for lookup')
          ->line('char* lc_name = (char*)alloca(nlen + 1);')
          ->for('STRLEN i = 0', 'i < nlen', 'i++')
            ->line('lc_name[i] = tolower((unsigned char)name[i]);')
          ->endfor
          ->line('lc_name[nlen] = \'\\0\';')
          ->blank
          ->line('SV** val = hv_fetch(headers_hv, lc_name, nlen, 0);')
          ->if('val && *val')
            ->line('ST(0) = *val;')
            ->line('XSRETURN(1);')
          ->endif
        ->endif
        ->line('XSRETURN_UNDEF;')
      ->endif
      ->blank
      ->comment('If request is an object, call header method')
      ->line('ENTER;')
      ->line('SAVETMPS;')
      ->line('PUSHMARK(SP);')
      ->line('XPUSHs(*req_sv);')
      ->line('XPUSHs(ST(1));')
      ->line('PUTBACK;')
      ->line('int count = call_method("header", G_SCALAR | G_EVAL);')
      ->line('SPAGAIN;')
      ->blank
      ->if('count >= 1')
        ->line('SV* result = POPs;')
        ->line('ST(0) = sv_2mortal(newSVsv(result));')
        ->line('FREETMPS;')
        ->line('LEAVE;')
        ->line('XSRETURN(1);')
      ->endif
      ->blank
      ->line('FREETMPS;')
      ->line('LEAVE;')
      ->line('XSRETURN_UNDEF;')
      ->xs_end
      ->blank;
}

# XS function registry for JIT compilation
sub get_xs_functions {
    return {
        'Hypersonic::WebSocket::new'               => { source => 'xs_websocket_new', is_xs_native => 1 },
        'Hypersonic::WebSocket::fd'                => { source => 'xs_websocket_fd', is_xs_native => 1 },
        'Hypersonic::WebSocket::state'             => { source => 'xs_websocket_state', is_xs_native => 1 },
        'Hypersonic::WebSocket::protocol'          => { source => 'xs_websocket_protocol', is_xs_native => 1 },
        'Hypersonic::WebSocket::stream'            => { source => 'xs_websocket_stream', is_xs_native => 1 },
        'Hypersonic::WebSocket::request'           => { source => 'xs_websocket_request', is_xs_native => 1 },
        'Hypersonic::WebSocket::is_open'           => { source => 'xs_websocket_is_open', is_xs_native => 1 },
        'Hypersonic::WebSocket::is_closing'        => { source => 'xs_websocket_is_closing', is_xs_native => 1 },
        'Hypersonic::WebSocket::is_closed'         => { source => 'xs_websocket_is_closed', is_xs_native => 1 },
        'Hypersonic::WebSocket::on'                => { source => 'xs_websocket_on', is_xs_native => 1 },
        'Hypersonic::WebSocket::emit'              => { source => 'xs_websocket_emit', is_xs_native => 1 },
        'Hypersonic::WebSocket::accept'            => { source => 'xs_websocket_accept', is_xs_native => 1 },
        'Hypersonic::WebSocket::send'              => { source => 'xs_websocket_send', is_xs_native => 1 },
        'Hypersonic::WebSocket::send_binary'       => { source => 'xs_websocket_send_binary', is_xs_native => 1 },
        'Hypersonic::WebSocket::ping'              => { source => 'xs_websocket_ping', is_xs_native => 1 },
        'Hypersonic::WebSocket::pong'              => { source => 'xs_websocket_pong', is_xs_native => 1 },
        'Hypersonic::WebSocket::close'             => { source => 'xs_websocket_close', is_xs_native => 1 },
        'Hypersonic::WebSocket::handle_close'      => { source => 'xs_websocket_handle_close', is_xs_native => 1 },
        'Hypersonic::WebSocket::handle_message'    => { source => 'xs_websocket_handle_message', is_xs_native => 1 },
        'Hypersonic::WebSocket::process_data'      => { source => 'xs_websocket_process_data', is_xs_native => 1 },
        'Hypersonic::WebSocket::_flush_send_buffer' => { source => 'xs_websocket_flush_send_buffer', is_xs_native => 1 },
        'Hypersonic::WebSocket::param'             => { source => 'xs_websocket_param', is_xs_native => 1 },
        'Hypersonic::WebSocket::header'            => { source => 'xs_websocket_header', is_xs_native => 1 },
    };
}

1;

__END__

=head1 NAME

Hypersonic::WebSocket - High-level WebSocket connection API (JIT-compiled)

=head1 SYNOPSIS

    my $ws = Hypersonic::WebSocket->new($stream, protocol => 'chat');

    $ws->on(open => sub {
        print "Connected!\n";
    });

    $ws->on(message => sub {
        my ($data) = @_;
        $ws->send("Echo: $data");
    });

    $ws->on(close => sub {
        my ($code, $reason) = @_;
        print "Closed: $code $reason\n";
    });

=head1 DESCRIPTION

Event-driven WebSocket API for Hypersonic. All methods are JIT-compiled
to native C code via XS for maximum performance.

=head1 METHODS

=over 4

=item new($stream, %opts)

Create new WebSocket wrapper. Options: fd, request, protocol, max_message_size.

=item on($event, $handler)

Register event handler. Events: open, message, binary, ping, pong, close, error.

=item emit($event, @args)

Emit event to registered handler.

=item accept($handshake)

Accept WebSocket upgrade. Returns 1 on success, 0 on failure.

=item send($data)

Send text message. Returns 1 on success, 0 on failure.

=item send_binary($data)

Send binary message.

=item ping($data)

Send ping frame.

=item pong($data)

Send pong frame.

=item close($code, $reason)

Initiate close handshake.

=item handle_close($code, $reason)

Handle received close frame.

=item handle_message($opcode, $data)

Handle received message frame.

=item process_data($data)

Process incoming WebSocket data.

=item state, protocol, stream, fd, request

Accessors.

=item is_open, is_closing, is_closed

State checks.

=item param($name), header($name)

Access request parameters and headers.

=back

=head1 CONSTANTS

CONNECTING (0), OPEN (1), CLOSING (2), CLOSED (3)

=head1 SEE ALSO

L<Hypersonic::Protocol::WebSocket>, L<Hypersonic::Protocol::WebSocket::Frame>

=cut
