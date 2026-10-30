package Linux::Event::WebSocket::Client::_HTTPConnection;
use v5.36;
use strict;
use warnings;

use parent 'Linux::Event::IO::Sock::Stream';

use Carp qw(croak);
use Scalar::Util qw(blessed);
use Unblock::HTTP1::Client;
use Linux::Event::Framer ();
use Linux::Event::WebSocket::_BQ ();

# Begin with the existing HTTP-byte native consumer so Linux::Event can
# replace it with the native bq WebSocket consumer during transition_to().
# Linux::Event forbids adding a first provider during a live transition.
Linux::Event::Framer->declare_native_consumer(
    __PACKAGE__,
    Linux::Event::WebSocket::_BQ->http_bridge_consumer_definition,
);

sub can ($class, $name) {
    return undef if $name eq 'on_data';
    return UNIVERSAL::can($class, $name);
}

sub _websocket_http_input ($self, $bytes) {
    return $self->on_data($bytes);
}

use Linux::Event::WebSocket::_Handshake;

# The HTTP opening exchange uses Unblock::HTTP1. On 101, this same Stream
# transitions directly to the caller's established WebSocket Connection class.
# Its native bq input provider takes over, preserving TLS and queued output.
sub _websocket_state ($self) {
    my $state = $self->SUPER::data;
    croak 'WebSocket client connection state is unavailable'
        unless blessed($state)
        && $state->isa('Linux::Event::WebSocket::_State');
    return $state;
}

sub data ($self, @value) {
    my $state = $self->_websocket_state;
    croak 'data() accepts at most one value' if @value > 1;
    $state->{data} = $value[0] if @value;
    return $state->{data};
}

sub _report_error ($self, $error) {
    my $state = $self->_websocket_state;
    return if $state->{handshake_error_reported}++;
    my $message = "$error";
    $message =~ s/\s+\z//;
    if (my $callback = $state->{callbacks}{error}) {
        $callback->($self, $message);
    }
    return;
}

sub on_ready ($self) {
    my $state = $self->_websocket_state;
    my $http = Unblock::HTTP1::Client->new(transport => $self);
    $self->{ws_opening_http} = $http;
    $http->request(
        $state->{request},
        on_response => sub ($tx, $response) {
            $state->{response} = $response;
            Linux::Event::WebSocket::_Handshake->validate_client_response(
                $state->{handshake}, $response,
            );
        },
        on_switch => sub ($tx, $response) {
            $state->{response} = $response;
            my $opening = delete $self->{ws_opening_http};
            my $tail = $opening ? $opening->take_remainder : '';
            $self->transition_to($state->{connection_class});
            $self->_ensure_websocket_open;
            $state->{engine}->feed($tail) if length $tail && !$self->is_closed;
        },
        on_error => sub ($tx, $error) {
            $self->_report_error($error);
        },
    );
    return;
}

sub on_data ($self, $bytes) {
    my $http = $self->{ws_opening_http} or return;
    my $ok = eval { $http->input($bytes); 1 };
    unless ($ok) {
        $self->_report_error($@);
        $self->SUPER::close unless $self->is_closed;
    }
    return;
}

sub on_eof ($self) {
    my $http = $self->{ws_opening_http};
    if ($http && !$http->is_closed && !$http->is_switched) {
        eval { $http->input_eof };
    }
    $self->SUPER::close unless $self->is_closed;
    return;
}

sub on_error ($self, $error) {
    $self->_report_error($error);
    return;
}

sub on_drain ($self) {
    my $http = $self->{ws_opening_http};
    $http->resume_output if $http && !$http->is_closed;
    return;
}

sub on_close ($self) {
    my $http = delete $self->{ws_opening_http};
    if ($http && !$http->is_closed && !$http->is_switched) {
        $http->transport_error('WebSocket opening transport closed');
    }
    return;
}

sub unblock_send ($self, $bytes) { return $self->write($bytes) }
sub unblock_finish ($self) { return $self->end }
sub unblock_abort ($self, $error) {
    $self->SUPER::close unless $self->is_closed;
    return;
}

1;
