package Hypersonic::WebSocket::Handler;
use strict;
use warnings;

# Hypersonic::WebSocket::Handler - XS WebSocket connection management
#
# All connection management is done in C via XS::JIT::Builder.
# This module generates XS functions callable from Perl.
# Object-oriented API: $conn = Handler->new($fd, $ws); $conn->send($msg);

our $VERSION = '0.12';

# Maximum concurrent WebSocket connections
use constant MAX_CONNECTIONS => 65536;

# Generate all Handler XS code
sub generate_c_code {
    my ($class, $builder, $opts) = @_;
    $opts //= {};
    
    my $max_conns = $opts->{max_connections} // MAX_CONNECTIONS;
    
    # Generate connection registry (static C)
    $class->gen_connection_registry($builder, $max_conns);
    
    # Generate XS functions - instance methods
    $class->gen_xs_new($builder);
    $class->gen_xs_fd($builder);
    $class->gen_xs_state($builder);
    $class->gen_xs_is_open($builder);
    $class->gen_xs_ws($builder);
    $class->gen_xs_send($builder);
    $class->gen_xs_send_binary($builder);
    $class->gen_xs_handle_data($builder);
    $class->gen_xs_close($builder);
    
    # Class methods
    $class->gen_xs_count($builder);
    $class->gen_xs_get($builder);
    $class->gen_xs_is_websocket($builder);
    $class->gen_xs_broadcast($builder);
    
    return $builder;
}

# Generate connection registry (C data structures)
sub gen_connection_registry {
    my ($class, $builder, $max_conns) = @_;
    
    $builder->comment('WebSocket connection registry')
      ->line('#define WS_MAX_CONNECTIONS ' . $max_conns)
      ->blank
      ->comment('Connection states')
      ->line('#define WS_STATE_INIT 0')
      ->line('#define WS_STATE_OPEN 1')
      ->line('#define WS_STATE_CLOSING 2')
      ->line('#define WS_STATE_CLOSED 3')
      ->blank
      ->comment('Connection structure')
      ->line('typedef struct {')
      ->line('    int active;')
      ->line('    int state;')
      ->line('    SV* ws_object;')
      ->line('    SV* handler;')
      ->line('} WSConnection;')
      ->blank
      ->line('static WSConnection ws_handler_registry[WS_MAX_CONNECTIONS];')
      ->line('static int ws_connection_count = 0;')
      ->blank;
    
    return $builder;
}

# XS: new($fd, $ws) - create connection, return blessed object
sub gen_xs_new {
    my ($class, $builder) = @_;
    
    $builder->xs_function('xs_ws_new')
      ->xs_preamble
      ->line('int fd;')
      ->line('SV* ws;')
      ->line('WSConnection* conn;')
      ->line('SV* fd_sv;')
      ->line('SV* fd_ref;')
      ->blank
      ->if('items != 3')
        ->line('croak("Usage: Hypersonic::WebSocket::Handler->new(fd, ws)");')
      ->endif
      ->blank
      ->line('fd = SvIV(ST(1));')
      ->line('ws = ST(2);')
      ->blank
      ->if('fd < 0 || fd >= WS_MAX_CONNECTIONS')
        ->line('croak("fd out of range: %d", fd);')
      ->endif
      ->blank
      ->line('conn = &ws_handler_registry[fd];')
      ->if('conn->active')
        ->comment('Already registered, return existing')
      ->else
        ->line('conn->active = 1;')
        ->line('conn->state = WS_STATE_OPEN;')
        ->line('conn->ws_object = SvREFCNT_inc(ws);')
        ->line('conn->handler = NULL;')
        ->line('ws_connection_count++;')
      ->endif
      ->blank
      ->comment('Create blessed object: bless \\$fd, class')
      ->line('fd_sv = newSViv(fd);')
      ->line('fd_ref = newRV_noinc(fd_sv);')
      ->line('sv_bless(fd_ref, gv_stashpv("Hypersonic::WebSocket::Handler", GV_ADD));')
      ->line('ST(0) = sv_2mortal(fd_ref);')
      ->line('XSRETURN(1);')
      ->xs_end
      ->blank;
    
    return $builder;
}

# XS: fd() - get fd from object
sub gen_xs_fd {
    my ($class, $builder) = @_;
    
    $builder->xs_function('xs_ws_fd')
      ->xs_preamble
      ->line('int fd;')
      ->blank
      ->if('items != 1')
        ->line('croak("Usage: $conn->fd()");')
      ->endif
      ->blank
      ->line('fd = SvIV(SvRV(ST(0)));')
      ->line('XSRETURN_IV(fd);')
      ->xs_end
      ->blank;
    
    return $builder;
}

# XS: state() - get connection state
sub gen_xs_state {
    my ($class, $builder) = @_;
    
    $builder->xs_function('xs_ws_state')
      ->xs_preamble
      ->line('int fd;')
      ->blank
      ->if('items != 1')
        ->line('croak("Usage: $conn->state()");')
      ->endif
      ->blank
      ->line('fd = SvIV(SvRV(ST(0)));')
      ->blank
      ->if('fd < 0 || fd >= WS_MAX_CONNECTIONS')
        ->line('XSRETURN_IV(-1);')
      ->endif
      ->if('!ws_handler_registry[fd].active')
        ->line('XSRETURN_IV(-1);')
      ->endif
      ->blank
      ->line('XSRETURN_IV(ws_handler_registry[fd].state);')
      ->xs_end
      ->blank;
    
    return $builder;
}

# XS: is_open() - check if connection is open
sub gen_xs_is_open {
    my ($class, $builder) = @_;
    
    $builder->xs_function('xs_ws_is_open')
      ->xs_preamble
      ->if('items != 1')
        ->line('croak("Usage: $conn->is_open()");')
      ->endif
      ->blank
      ->line('int fd = SvIV(SvRV(ST(0)));')
      ->blank
      ->if('fd < 0 || fd >= WS_MAX_CONNECTIONS')
        ->line('XSRETURN_NO;')
      ->endif
      ->if('!ws_handler_registry[fd].active')
        ->line('XSRETURN_NO;')
      ->endif
      ->blank
      ->if('ws_handler_registry[fd].state == WS_STATE_OPEN')
        ->line('XSRETURN_YES;')
      ->else
        ->line('XSRETURN_NO;')
      ->endif
      ->xs_end
      ->blank;
    
    return $builder;
}

# XS: ws() - get WebSocket object
sub gen_xs_ws {
    my ($class, $builder) = @_;
    
    $builder->xs_function('xs_ws_ws')
      ->xs_preamble
      ->if('items != 1')
        ->line('croak("Usage: $conn->ws()");')
      ->endif
      ->blank
      ->line('int fd = SvIV(SvRV(ST(0)));')
      ->blank
      ->if('fd < 0 || fd >= WS_MAX_CONNECTIONS')
        ->line('XSRETURN_UNDEF;')
      ->endif
      ->if('!ws_handler_registry[fd].active')
        ->line('XSRETURN_UNDEF;')
      ->endif
      ->blank
      ->line('ST(0) = ws_handler_registry[fd].ws_object;')
      ->line('XSRETURN(1);')
      ->xs_end
      ->blank;
    
    return $builder;
}

# XS: send($message) - send text frame
sub gen_xs_send {
    my ($class, $builder) = @_;
    
    $builder->xs_function('xs_ws_send')
      ->xs_preamble
      ->if('items != 2')
        ->line('croak("Usage: $conn->send(message)");')
      ->endif
      ->blank
      ->line('int fd = SvIV(SvRV(ST(0)));')
      ->line('STRLEN msg_len;')
      ->line('const char* message = SvPV(ST(1), msg_len);')
      ->blank
      ->if('fd < 0 || fd >= WS_MAX_CONNECTIONS')
        ->line('XSRETURN_NO;')
      ->endif
      ->if('!ws_handler_registry[fd].active || ws_handler_registry[fd].state != WS_STATE_OPEN')
        ->line('XSRETURN_NO;')
      ->endif
      ->blank
      ->line('uint8_t frame[65546];')
      ->line('size_t frame_len = ws_encode_text(frame, sizeof(frame), message, msg_len);')
      ->blank
      ->if('frame_len == 0')
        ->line('XSRETURN_NO;')
      ->endif
      ->blank
      ->line('send(fd, frame, frame_len, 0);')
      ->line('XSRETURN_YES;')
      ->xs_end
      ->blank;
    
    return $builder;
}

# XS: send_binary($data) - send binary frame
sub gen_xs_send_binary {
    my ($class, $builder) = @_;
    
    $builder->xs_function('xs_ws_send_binary')
      ->xs_preamble
      ->if('items != 2')
        ->line('croak("Usage: $conn->send_binary(data)");')
      ->endif
      ->blank
      ->line('int fd = SvIV(SvRV(ST(0)));')
      ->line('STRLEN data_len;')
      ->line('const char* data = SvPV(ST(1), data_len);')
      ->blank
      ->if('fd < 0 || fd >= WS_MAX_CONNECTIONS')
        ->line('XSRETURN_NO;')
      ->endif
      ->if('!ws_handler_registry[fd].active || ws_handler_registry[fd].state != WS_STATE_OPEN')
        ->line('XSRETURN_NO;')
      ->endif
      ->blank
      ->line('uint8_t frame[65546];')
      ->line('size_t frame_len = ws_encode_binary(frame, sizeof(frame), (const uint8_t*)data, data_len);')
      ->blank
      ->if('frame_len == 0')
        ->line('XSRETURN_NO;')
      ->endif
      ->blank
      ->line('send(fd, frame, frame_len, 0);')
      ->line('XSRETURN_YES;')
      ->xs_end
      ->blank;
    
    return $builder;
}

# XS: handle_data($data) - process incoming frame
sub gen_xs_handle_data {
    my ($class, $builder) = @_;
    
    $builder->xs_function('xs_ws_handle_data')
      ->xs_preamble
      ->if('items != 2')
        ->line('croak("Usage: $conn->handle_data(data)");')
      ->endif
      ->blank
      ->line('int fd = SvIV(SvRV(ST(0)));')
      ->line('STRLEN data_len;')
      ->line('const uint8_t* data = (const uint8_t*)SvPV(ST(1), data_len);')
      ->blank
      ->if('fd < 0 || fd >= WS_MAX_CONNECTIONS')
        ->line('XSRETURN_UNDEF;')
      ->endif
      ->if('!ws_handler_registry[fd].active')
        ->line('XSRETURN_UNDEF;')
      ->endif
      ->blank
      ->comment('Decode WebSocket frame')
      ->line('WSFrame frame;')
      ->line('int result = ws_decode_frame(data, data_len, &frame);')
      ->blank
      ->if('result <= 0')
        ->line('XSRETURN_UNDEF;')
      ->endif
      ->blank
      ->comment('Return decoded message')
      ->line('HV* hv = newHV();')
      ->line('hv_store(hv, "opcode", 6, newSViv(frame.opcode), 0);')
      ->line('hv_store(hv, "data", 4, newSVpvn((char*)frame.payload, frame.payload_length), 0);')
      ->line('ST(0) = sv_2mortal(newRV_noinc((SV*)hv));')
      ->line('XSRETURN(1);')
      ->xs_end
      ->blank;
    
    return $builder;
}

# XS: close([$code]) - close connection
sub gen_xs_close {
    my ($class, $builder) = @_;
    
    $builder->xs_function('xs_ws_close')
      ->xs_preamble
      ->if('items < 1')
        ->line('croak("Usage: $conn->close([code])");')
      ->endif
      ->blank
      ->line('int fd = SvIV(SvRV(ST(0)));')
      ->line('int code = (items >= 2) ? SvIV(ST(1)) : 1000;')
      ->blank
      ->if('fd < 0 || fd >= WS_MAX_CONNECTIONS')
        ->line('XSRETURN_NO;')
      ->endif
      ->if('!ws_handler_registry[fd].active')
        ->line('XSRETURN_NO;')
      ->endif
      ->blank
      ->line('WSConnection* conn = &ws_handler_registry[fd];')
      ->blank
      ->comment('Send close frame if connection is open')
      ->if('conn->state == WS_STATE_OPEN')
        ->line('uint8_t close_frame[4];')
        ->line('close_frame[0] = 0x88;')
        ->line('close_frame[1] = 2;')
        ->line('close_frame[2] = (code >> 8) & 0xFF;')
        ->line('close_frame[3] = code & 0xFF;')
        ->line('send(fd, close_frame, 4, 0);')
        ->line('conn->state = WS_STATE_CLOSING;')
      ->endif
      ->blank
      ->comment('Cleanup')
      ->if('conn->ws_object')
        ->line('SvREFCNT_dec(conn->ws_object);')
      ->endif
      ->if('conn->handler')
        ->line('SvREFCNT_dec(conn->handler);')
      ->endif
      ->line('memset(conn, 0, sizeof(WSConnection));')
      ->line('ws_connection_count--;')
      ->blank
      ->line('XSRETURN_YES;')
      ->xs_end
      ->blank;
    
    return $builder;
}

# ============================================================
# Class Methods
# ============================================================

# XS: count() - class method, total connection count
sub gen_xs_count {
    my ($class, $builder) = @_;
    
    $builder->xs_function('xs_ws_count')
      ->xs_preamble
      ->line('XSRETURN_IV(ws_connection_count);')
      ->xs_end
      ->blank;
    
    return $builder;
}

# XS: get($fd) - class method, get Handler by fd
sub gen_xs_get {
    my ($class, $builder) = @_;
    
    $builder->xs_function('xs_ws_get')
      ->xs_preamble
      ->if('items != 2')
        ->line('croak("Usage: Hypersonic::WebSocket::Handler->get(fd)");')
      ->endif
      ->blank
      ->line('int fd = SvIV(ST(1));')
      ->blank
      ->if('fd < 0 || fd >= WS_MAX_CONNECTIONS')
        ->line('XSRETURN_UNDEF;')
      ->endif
      ->if('!ws_handler_registry[fd].active')
        ->line('XSRETURN_UNDEF;')
      ->endif
      ->blank
      ->comment('Return blessed handler object')
      ->line('SV* fd_sv = newSViv(fd);')
      ->line('SV* fd_ref = newRV_noinc(fd_sv);')
      ->line('sv_bless(fd_ref, gv_stashpv("Hypersonic::WebSocket::Handler", GV_ADD));')
      ->line('ST(0) = sv_2mortal(fd_ref);')
      ->line('XSRETURN(1);')
      ->xs_end
      ->blank;
    
    return $builder;
}

# XS: is_websocket($fd) - class method
sub gen_xs_is_websocket {
    my ($class, $builder) = @_;
    
    $builder->xs_function('xs_ws_is_websocket')
      ->xs_preamble
      ->if('items != 2')
        ->line('croak("Usage: Hypersonic::WebSocket::Handler->is_websocket(fd)");')
      ->endif
      ->blank
      ->line('int fd = SvIV(ST(1));')
      ->blank
      ->if('fd < 0 || fd >= WS_MAX_CONNECTIONS')
        ->line('XSRETURN_NO;')
      ->endif
      ->blank
      ->if('ws_handler_registry[fd].active')
        ->line('XSRETURN_YES;')
      ->else
        ->line('XSRETURN_NO;')
      ->endif
      ->xs_end
      ->blank;
    
    return $builder;
}

# XS: broadcast($message, [$exclude]) - class method
sub gen_xs_broadcast {
    my ($class, $builder) = @_;
    
    $builder->xs_function('xs_ws_broadcast')
      ->xs_preamble
      ->if('items < 2')
        ->line('croak("Usage: Hypersonic::WebSocket::Handler->broadcast(message, [exclude])");')
      ->endif
      ->blank
      ->line('STRLEN msg_len;')
      ->line('const char* message = SvPV(ST(1), msg_len);')
      ->line('int exclude_fd = -1;')
      ->line('int fd;')
      ->blank
      ->comment('Handle exclude - can be fd or Handler object')
      ->if('items >= 3')
        ->if('SvROK(ST(2))')
          ->line('SV* deref = SvRV(ST(2));')
          ->if('SvTYPE(deref) == SVt_PVHV')
            ->comment('WebSocket object with fd key')
            ->line('HV* hv = (HV*)deref;')
            ->line('SV** fd_sv = hv_fetchs(hv, "fd", 0);')
            ->if('fd_sv && *fd_sv')
              ->line('exclude_fd = SvIV(*fd_sv);')
            ->endif
          ->else
            ->comment('Handler object (blessed scalar ref)')
            ->line('exclude_fd = SvIV(deref);')
          ->endif
        ->else
          ->line('exclude_fd = SvIV(ST(2));')
        ->endif
      ->endif
      ->blank
      ->comment('Encode as WebSocket text frame')
      ->line('uint8_t frame[65546];')
      ->line('size_t frame_len = ws_encode_text(frame, sizeof(frame), message, msg_len);')
      ->if('frame_len == 0')
        ->line('XSRETURN_IV(0);')
      ->endif
      ->blank
      ->line('int sent = 0;')
      ->for('fd = 0', 'fd < WS_MAX_CONNECTIONS', 'fd++')
        ->if('ws_handler_registry[fd].active && ws_handler_registry[fd].state == WS_STATE_OPEN && fd != exclude_fd')
          ->line('send(fd, frame, frame_len, 0);')
          ->line('sent++;')
        ->endif
      ->endfor
      ->blank
      ->line('XSRETURN_IV(sent);')
      ->xs_end
      ->blank;
    
    return $builder;
}

# Get XS function mappings for XS::JIT->compile
sub get_xs_functions {
    return {
        # Instance methods
        'Hypersonic::WebSocket::Handler::new'         => { source => 'xs_ws_new', is_xs_native => 1 },
        'Hypersonic::WebSocket::Handler::fd'          => { source => 'xs_ws_fd', is_xs_native => 1 },
        'Hypersonic::WebSocket::Handler::state'       => { source => 'xs_ws_state', is_xs_native => 1 },
        'Hypersonic::WebSocket::Handler::is_open'     => { source => 'xs_ws_is_open', is_xs_native => 1 },
        'Hypersonic::WebSocket::Handler::ws'          => { source => 'xs_ws_ws', is_xs_native => 1 },
        'Hypersonic::WebSocket::Handler::send'        => { source => 'xs_ws_send', is_xs_native => 1 },
        'Hypersonic::WebSocket::Handler::send_binary' => { source => 'xs_ws_send_binary', is_xs_native => 1 },
        'Hypersonic::WebSocket::Handler::handle_data' => { source => 'xs_ws_handle_data', is_xs_native => 1 },
        'Hypersonic::WebSocket::Handler::close'       => { source => 'xs_ws_close', is_xs_native => 1 },
        # Class methods
        'Hypersonic::WebSocket::Handler::count'        => { source => 'xs_ws_count', is_xs_native => 1 },
        'Hypersonic::WebSocket::Handler::get'          => { source => 'xs_ws_get', is_xs_native => 1 },
        'Hypersonic::WebSocket::Handler::is_websocket' => { source => 'xs_ws_is_websocket', is_xs_native => 1 },
        'Hypersonic::WebSocket::Handler::broadcast'    => { source => 'xs_ws_broadcast', is_xs_native => 1 },
    };
}

1;

__END__

=head1 NAME

Hypersonic::WebSocket::Handler - XS WebSocket connection management (OO)

=head1 SYNOPSIS

    use Hypersonic::WebSocket::Handler;
    use XS::JIT::Builder;
    use XS::JIT;
    
    my $builder = XS::JIT::Builder->new;
    Hypersonic::WebSocket::Handler->generate_c_code($builder, {
        max_connections => 65536,
    });
    
    # Compile XS functions
    XS::JIT->compile(
        code      => $builder->code,
        name      => 'Hypersonic::WebSocket::Handler',
        functions => Hypersonic::WebSocket::Handler->get_xs_functions,
    );
    
    # Object-oriented API
    my $conn = Hypersonic::WebSocket::Handler->new($fd, $ws);
    $conn->send('Hello!');
    $conn->send_binary($data);
    $conn->close;
    
    # Class methods
    my $count = Hypersonic::WebSocket::Handler->count;
    Hypersonic::WebSocket::Handler->broadcast('Message to all');

=head1 DESCRIPTION

Generates XS functions for WebSocket connection management via XS::JIT::Builder.
All hot paths (connection registry, frame handling, broadcast) are in C.

Handler objects are blessed scalars containing the fd, created entirely in XS.

=head1 INSTANCE METHODS (XS)

=over 4

=item new($fd, $ws) - Create/register connection, returns blessed object

=item fd() - Get the file descriptor

=item state() - Get connection state (0=init, 1=open, 2=closing, 3=closed)

=item is_open() - Check if connection is open

=item ws() - Get the WebSocket object

=item send($message) - Send text frame

=item send_binary($data) - Send binary frame

=item handle_data($data) - Process incoming frame, returns {opcode, data}

=item close([$code]) - Close connection with optional code

=back

=head1 CLASS METHODS (XS)

=over 4

=item count() - Get total active connection count

=item get($fd) - Get Handler object by fd

=item is_websocket($fd) - Check if fd is a registered WebSocket

=item broadcast($message, [$exclude]) - Broadcast to all connections

=back

=cut
