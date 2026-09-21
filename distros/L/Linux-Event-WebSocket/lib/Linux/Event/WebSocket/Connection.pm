package Linux::Event::WebSocket::Connection;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.001';

use parent 'Linux::Event::IO::Sock::Stream';

use Carp qw(croak);
use Scalar::Util qw(blessed);
use utf8 ();

use Linux::Event::Framer ();
use Linux::Event::Kernel::Timer;
use Linux::Event::WebSocket::_BQ ();
use Linux::Event::WebSocket::_Engine;
use Linux::Event::WebSocket::_Handshake;
use Linux::Event::WebSocket::_State;
use Linux::Event::WebSocket::_UTF8;

Linux::Event::Framer->declare_native_consumer(
    __PACKAGE__,
    Linux::Event::WebSocket::_BQ->raw_consumer_definition,
);

sub _websocket_state ($self) {
    my $state = $self->SUPER::data;
    croak ref($self) . ': missing Linux::Event::WebSocket connection state'
        if !blessed($state)
        || !$state->isa('Linux::Event::WebSocket::_State');
    return $state;
}

sub data ($self, @value) {
    my $state = $self->_websocket_state;
    croak 'data() accepts at most one value' if @value > 1;
    $state->{data} = $value[0] if @value;
    return $state->{data};
}

sub endpoint_type ($self) { $self->_websocket_state->{endpoint_type} }
sub is_open       ($self) { !!$self->_websocket_state->{open} }
sub is_closing    ($self) { !!$self->_websocket_state->{closing} }
sub subprotocol   ($self) { $self->_websocket_state->{subprotocol} }
sub secure        ($self) { !!$self->_websocket_state->{secure} }
sub url           ($self) { $self->_websocket_state->{url} }
sub handshake_request  ($self) { $self->_websocket_state->{request} }
sub handshake_response ($self) { $self->_websocket_state->{response} }

sub _dispatch_websocket ($self, $name, @argument) {
    my $state = $self->_websocket_state;
    if (my $callback = $state->{callbacks}{$name}) {
        return $callback->($self, @argument);
    }

    my $method = "websocket_$name";
    if (my $handler = $self->can($method)) {
        return $handler->($self, @argument);
    }
    return;
}

sub _initialize_engine ($self, $state = undef, $native = undef) {
    $state //= $self->_websocket_state;
    return $state->{engine} if $state->{engine};

    my %native = defined($native) ? (native => $native) : ();
    $state->{engine} = Linux::Event::WebSocket::_Engine->new(
        connection       => $self,
        endpoint_type    => $state->{endpoint_type},
        max_message_size => $state->{max_message_size},
        message_handler  => $state->{message_handler},
        %native,
    );
    return $state->{engine};
}

sub _prepare_message_handler ($self, $state) {
    $state->{message_handler} = $state->{callbacks}{message}
        // $self->can('websocket_message');
    return;
}

sub _websocket_raw_config ($self) {
    my $state = $self->_websocket_state;
    return [ $state->{endpoint_type}, $state->{max_message_size} ];
}

sub _websocket_raw_native_ready ($self, $native) {
    my $state = $self->_ensure_websocket_open($native);
    return $state->{engine};
}

sub _ensure_websocket_open ($self, $native = undef) {
    my $state = $self->SUPER::data;
    return $state
        if ref($state) eq 'Linux::Event::WebSocket::_State'
        && $state->{open};

    $state = $self->_websocket_state;
    return $state if $state->{open};

    $self->_prepare_message_handler($state);
    $self->_initialize_engine($state, $native);
    if (my $handshake = $state->{handshake}) {
        $state->{subprotocol} =
            Linux::Event::WebSocket::_Handshake->subprotocol($handshake);
    }

    $state->{open} = 1;
    $self->_dispatch_websocket('open');
    return $state;
}

sub _byte_payload ($operation, $payload) {
    croak "$operation(): payload must be a defined scalar"
        if !defined($payload) || ref($payload);
    return $payload if !utf8::is_utf8($payload);

    my $bytes = "$payload";
    croak "$operation(): payload contains wide characters; encode it to bytes first"
        if !utf8::downgrade($bytes, 1);
    return $bytes;
}

sub send_text ($self, $payload) {
    croak 'send_text(): payload must be a defined scalar'
        if !defined($payload) || ref($payload);
    my $state = $self->_ensure_websocket_open;
    croak 'send_text(): WebSocket connection is closing'
        if $state->{closing};

    return $state->{engine}->send_text($payload);
}

sub send_binary ($self, $payload) {
    my $state = $self->_ensure_websocket_open;
    croak 'send_binary(): WebSocket connection is closing'
        if $state->{closing};
    my $bytes = _byte_payload('send_binary', $payload);
    return $state->{engine}->send_binary($bytes);
}

sub ping ($self, $payload = '') {
    my $state = $self->_ensure_websocket_open;
    croak 'ping(): WebSocket connection is closing' if $state->{closing};
    my $bytes = _byte_payload('ping', $payload);
    return $state->{engine}->ping($bytes);
}

sub _cancel_close_timer ($self) {
    my $state = $self->_websocket_state;
    if (my $timer = delete $state->{close_timer}) {
        $timer->cancel;
    }
    return;
}

sub _close_timeout_fired ($timer) {
    my $self = $timer->data;
    return if !$self || $self->is_closed;
    $self->abort;
    return;
}

sub _arm_close_timeout ($self) {
    my $state = $self->_websocket_state;
    return if $state->{close_timer};

    if ($state->{close_timeout} == 0) {
        $self->end;
        return;
    }

    $state->{close_timer} = Linux::Event::Kernel::Timer->new(
        loop     => $self->loop,
        after    => $state->{close_timeout},
        data     => $self,
        on_timer => \&_close_timeout_fired,
    );
    return;
}

sub close ($self, %option) {
    return $self if $self->is_closed;
    $self->_ensure_websocket_open;

    my $state = $self->_websocket_state;
    return $self if $state->{closing};

    my $code = exists($option{code}) ? delete($option{code}) : 'SUCCESS';
    my $reason = delete $option{reason};
    croak 'close(): unknown option(s): ' . join(', ', sort keys %option)
        if %option;

    my $reason_bytes = '';
    if (defined $reason) {
        croak 'close(): reason must be a scalar' if ref $reason;
        $reason_bytes = eval {
            Linux::Event::WebSocket::_UTF8->encode($reason);
        };
        croak 'close(): reason contains invalid UTF-8' if $@;
    }

    $state->{engine}->start_close($code, $reason_bytes);
    $self->_arm_close_timeout;
    return $self;
}

sub abort ($self) {
    return $self if $self->is_closed;
    $self->_cancel_close_timer;
    $self->SUPER::close;
    return $self;
}

sub _notify_websocket_close ($self, $code, $reason) {
    my $state = $self->_websocket_state;
    return if $state->{close_notified}++;
    $self->_cancel_close_timer;
    $state->{closing} = 1;
    $self->_dispatch_websocket('close', $code, $reason);
    return;
}

sub _websocket_engine_message ($self, $payload, $type) {
    my $state = $self->SUPER::data;
    if (my $handler = $state->{message_handler}) {
        $handler->($self, $payload, $type);
    }
    return;
}

sub _websocket_engine_error ($self, $error) {
    $self->_dispatch_websocket('error', $error);
    return;
}

sub _websocket_engine_closing ($self) {
    $self->_websocket_state->{closing} = 1;
    return;
}

sub _websocket_engine_close ($self, $code, $reason) {
    $self->_notify_websocket_close($code, $reason);
    return;
}

sub on_eof ($self) {
    return if $self->is_closed;
    my $state = $self->_websocket_state;
    $self->_notify_websocket_close(undef, 'transport EOF')
        if !$state->{close_notified};
    $self->SUPER::close if !$self->is_closed;
    return;
}

sub on_error ($self, $error) {
    return if $self->is_closed;
    $self->_dispatch_websocket('error', $error);
    return;
}

sub on_close ($self) {
    $self->_websocket_transport_closed;
    return;
}

sub on_drain ($self) {
    return if !$self->is_open;
    $self->_dispatch_websocket('drain');
    return;
}

sub _websocket_transport_closed ($self) {
    my $state = $self->_websocket_state;
    $self->_cancel_close_timer;
    $self->_notify_websocket_close(undef, 'transport closed')
        if $state->{open} && !$state->{close_notified};
    return;
}

1;
