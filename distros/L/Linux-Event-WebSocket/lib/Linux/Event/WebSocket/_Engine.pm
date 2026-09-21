package Linux::Event::WebSocket::_Engine;
use v5.36;
use strict;
use warnings;

use Carp qw(croak);
use Scalar::Util qw(blessed weaken);

use Linux::Event::WebSocket::_BQ;
use Linux::Event::WebSocket::_Frame;
use Linux::Event::WebSocket::_UTF8;

sub new ($class, %option) {
    my $connection = delete $option{connection};
    croak 'new(): connection object is required'
        if !blessed($connection) || !$connection->can('write');

    my $endpoint_type = delete $option{endpoint_type};
    croak 'new(): endpoint_type must be client or server'
        if !defined($endpoint_type)
        || ($endpoint_type ne 'client' && $endpoint_type ne 'server');

    my $message_handler_supplied = exists $option{message_handler};
    my $message_handler = delete $option{message_handler};
    croak 'new(): message_handler must be a coderef'
        if defined($message_handler) && ref($message_handler) ne 'CODE';

    my $max_message_size = delete $option{max_message_size};
    croak 'new(): max_message_size must be a positive integer'
        if !defined($max_message_size) || ref($max_message_size)
        || "$max_message_size" !~ /\A[0-9]+\z/ || $max_message_size < 1;

    my $native = delete $option{native};
    croak 'new(): native must be a Linux::Event::WebSocket::_BQ object'
        if defined($native)
        && (!blessed($native)
            || !$native->isa('Linux::Event::WebSocket::_BQ'));

    croak 'new(): unknown option(s): ' . join(', ', sort keys %option)
        if %option;

    my $self = bless {
        connection       => $connection,
        endpoint_type    => $endpoint_type,
        message_handler_supplied => $message_handler_supplied ? 1 : 0,
        message_handler  => $message_handler,
        max_message_size => 0 + $max_message_size,
        native           => $native // Linux::Event::WebSocket::_BQ->new(
            $endpoint_type,
            $max_message_size,
        ),
        sent_close       => 0,
        received_close   => 0,
        failed           => 0,
        in_feed          => 0,
        pending_end      => 0,
    }, $class;
    weaken($self->{connection});
    return $self;
}

sub _connection ($self) {
    return $self->{connection}
        // die "WebSocket connection was destroyed while its engine remained alive\n";
}

sub is_closing ($self) {
    return !!($self->{sent_close} || $self->{received_close});
}

sub _flush ($self, $connection = undef) {
    return 0 if $self->{in_feed};

    my $wire = $self->{native}->flush;
    return 0 if !length $wire;

    $connection //= $self->_connection;
    return 0 if $connection->is_closed;
    return $connection->write($wire);
}

sub _queue_message ($self, $opcode, $bytes) {
    $self->{native}->queue_message($opcode, $bytes);
    return $self->_flush;
}

sub send_text ($self, $bytes) {
    croak 'send_text(): WebSocket connection is closing'
        if $self->{sent_close} || $self->{received_close};
    return $self->_queue_message(1, $bytes);
}

sub send_binary ($self, $bytes) {
    croak 'send_binary(): WebSocket connection is closing'
        if $self->{sent_close} || $self->{received_close};
    return $self->_queue_message(2, $bytes);
}

sub ping ($self, $bytes = '') {
    croak 'ping(): WebSocket connection is closing' if $self->is_closing;
    croak 'ping(): control frame payload exceeds 125 bytes'
        if length($bytes) > 125;
    return $self->_queue_message(9, $bytes);
}

sub start_close ($self, $code, $reason = '') {
    return $self if $self->{sent_close};

    croak 'close reason exceeds 123 bytes' if length($reason) > 123;
    my $number = Linux::Event::WebSocket::_Frame->close_code($code);
    $self->{native}->queue_close($number, $reason);
    $self->{sent_close} = 1;

    my $connection = $self->_connection;
    $connection->_websocket_engine_closing;
    $self->_flush($connection);
    return $self;
}

sub _failure_message ($error, $name) {
    return 'WebSocket message exceeds configured limit'
        if $name eq 'LIMIT_MAX_RECV_MSG_SIZE';
    return 'WebSocket continuation frame received outside a fragmented message'
        if $name eq 'BAD_CONTINUATION';
    return 'WebSocket data frame received while a fragmented message is unfinished'
        if $name eq 'UNFINISHED_PARTIAL';
    return 'WebSocket close frame has a one-byte payload or invalid status code'
        if $name eq 'BAD_CLOSE';
    return 'WebSocket close frame contains invalid UTF-8 reason'
        if $name eq 'BAD_UTF8';
    return "WebSocket protocol error ($name)";
}

sub _fail ($self, $message, $code, $native_has_close = 0) {
    return if $self->{failed}++;

    my $connection = $self->_connection;
    $connection->_websocket_engine_error($message);

    if (!$native_has_close && !$self->{sent_close} && !$connection->is_closed) {
        $self->{native}->queue_close($code, '');
    }

    $self->{sent_close} = 1;
    $connection->_websocket_engine_closing;
    $self->{pending_end} = 1;
    return;
}

sub _deliver ($self, $opcode, $payload, $connection) {
    return 0 if $self->{failed} || $self->{received_close};

    if (length($payload) > $self->{max_message_size}) {
        $self->_fail('WebSocket message exceeds configured limit', 1009);
        return 0;
    }

    my $type = $opcode == 1 ? 'text' : 'binary';

    if ($self->{message_handler_supplied}) {
        if (my $handler = $self->{message_handler}) {
            $handler->($connection, $payload, $type);
        }
    } else {
        $connection->_websocket_engine_message($payload, $type);
    }
    return !$connection->is_closed;
}

sub _handle_close ($self, $payload, $connection) {
    return 0 if $self->{received_close};

    my ($code, $reason);
    my $ok = eval {
        ($code, $reason) =
            Linux::Event::WebSocket::_Frame->parse_close_payload($payload);
        1;
    };
    if (!$ok) {
        $self->_fail($@, 1002);
        return 0;
    }

    my $decoded = '';
    if (length $reason) {
        $decoded = eval { Linux::Event::WebSocket::_UTF8->decode($reason) };
        if ($@) {
            $self->_fail('invalid UTF-8 in WebSocket close reason', 1007);
            return 0;
        }
    }

    $self->{received_close} = 1;
    $self->{sent_close} = 1;
    $connection->_websocket_engine_closing;
    $connection->_websocket_engine_close($code, $decoded);
    $self->{pending_end} = 1;
    return 0;
}

sub _bq_invalid_utf8 ($self, $connection) {
    return if $self->{failed} || $self->{received_close}
        || $connection->is_closed;
    $self->_fail('invalid UTF-8 in WebSocket text message', 1007);
    return;
}

sub _bq_event ($self, $connection, $opcode, $payload) {
    return if $self->{failed} || $self->{received_close}
        || $connection->is_closed;

    if ($opcode == 1 || $opcode == 2) {
        $self->_deliver($opcode, $payload, $connection);
    } elsif ($opcode == 8) {
        $self->_handle_close($payload, $connection);
    }
    return;
}

sub _handle_bq_error ($self, $error, $error_name) {
    return if $self->{failed} || !$error;
    $self->_fail(
        _failure_message($error, $error_name),
        $error_name eq 'LIMIT_MAX_RECV_MSG_SIZE' ? 1009
            : $error_name eq 'BAD_UTF8' ? 1007 : 1002,
        1,
    );
    return;
}

sub _finish_feed ($self, $connection = undef) {
    $connection //= $self->_connection;
    $self->{in_feed} = 0;
    $self->_flush($connection) if !$connection->is_closed;

    if ($self->{pending_end}
        && !$connection->is_write_ended
        && !$connection->is_closed) {
        $self->{pending_end} = 0;
        $connection->end;
    }
    return;
}

sub feed ($self, $bytes) {
    my $connection = $self->_connection;
    return if $self->{failed} || $self->{received_close}
        || $connection->is_closed;

    $self->{in_feed} = 1;
    my ($error, $error_name) =
        $self->{native}->feed($self, $connection, $bytes);

    $self->_handle_bq_error($error, $error_name);
    $self->_finish_feed($connection);
    return;
}

1;
