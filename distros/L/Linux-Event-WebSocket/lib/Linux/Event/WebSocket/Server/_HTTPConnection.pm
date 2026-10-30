package Linux::Event::WebSocket::Server::_HTTPConnection;
use v5.36;
use strict;
use warnings;

use parent 'Linux::Event::IO::Sock::Stream';

use Carp qw(croak);
use Scalar::Util qw(blessed);
use Unblock::HTTP1::Server;
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

use Uniform::HTTP::Response;
use Linux::Event::WebSocket::_Handshake;
use Linux::Event::WebSocket::_State;

# This is an ordinary Linux::Event stream for just the opening handshake.
# The standalone HTTP/1 engine owns validation/framing. Once its 101 output
# is accepted, transition_to() installs the existing native WebSocket
# consumer on this SAME stream; the WebSocket API and bq frame path stay intact.
sub new ($class, %option) {
    my $config = $option{data};
    croak 'WebSocket server connection is missing server configuration'
        unless blessed($config)
        && $config->isa('Linux::Event::WebSocket::Server::_Config');

    my $state = Linux::Event::WebSocket::_State->new(
        endpoint_type    => 'server',
        callbacks        => $config->{callbacks},
        subprotocols     => $config->{subprotocols},
        data             => $config->{data},
        secure           => $config->{secure},
        close_timeout    => $config->{close_timeout},
        max_message_size => $config->{max_message_size},
    );
    $state->{connection_class} = $config->{connection_class};
    $state->{on_handshake} = $config->{on_handshake};
    $option{data} = $state;
    return $class->SUPER::new(%option);
}

sub _websocket_state ($self) {
    my $state = $self->SUPER::data;
    croak 'WebSocket server connection state is unavailable'
        unless blessed($state) && $state->isa('Linux::Event::WebSocket::_State');
    return $state;
}

sub data ($self, @value) {
    my $state = $self->_websocket_state;
    croak 'data() accepts at most one value' if @value > 1;
    $state->{data} = $value[0] if @value;
    return $state->{data};
}

sub _report_handshake_error ($self, $error) {
    my $state = $self->_websocket_state;
    my $message = "$error";
    $message =~ s/\s+\z//;
    if (my $callback = $state->{callbacks}{error}) {
        $callback->($self, $message);
    }
    return;
}

sub on_ready ($self) {
    my $http = Unblock::HTTP1::Server->new(
        transport => $self,
        on_request => sub ($tx, $request) {
            $self->_on_http_request($tx, $request);
        },
        on_error => sub ($tx, $error) {
            $self->_report_handshake_error($error) unless $self->is_closed;
        },
        on_switch => sub ($tx, $response) {
            $self->_on_http_switch($tx, $response);
        },
    );
    $self->{ws_opening_http} = $http unless $self->is_closed;
    return;
}

sub _on_http_request ($self, $tx, $request) {
    my $state = $self->_websocket_state;
    if (my $callback = $state->{on_handshake}) {
        my $accepted = eval { $callback->($request) };
        if ($@) {
            $self->_report_handshake_error($@);
            $tx->respond(status => 500, body => "WebSocket handshake callback failed\n");
            return;
        }
        unless ($accepted) {
            $tx->respond(status => 403, body => "WebSocket upgrade rejected\n");
            return;
        }
    }

    my $handshake = eval {
        Linux::Event::WebSocket::_Handshake->server_from_request(
            $request, subprotocols => $state->{subprotocols},
        );
    };
    if (!$handshake) {
        $self->_report_handshake_error($@);
        $tx->respond(status => 400, body => "Bad WebSocket handshake\n");
        return;
    }

    my $response = Uniform::HTTP::Response->new(status => 101);
    Linux::Event::WebSocket::_Handshake->apply_server_response(
        $handshake, $response,
    );
    $state->{handshake} = $handshake;
    $state->{request} = $request;
    $tx->respond($response);
    return;
}

sub _on_http_switch ($self, $tx, $response) {
    return if $self->is_closed;
    my $state = $self->_websocket_state;
    $state->{response} = $response;
    my $http = delete $self->{ws_opening_http};
    my $tail = $http ? $http->take_remainder : '';
    $self->transition_to($state->{connection_class});
    $self->_ensure_websocket_open;
    # An HTTP header and first masked WebSocket frame can arrive in a single
    # read. Hand off exactly the unparsed bytes after on_open.
    $state->{engine}->feed($tail) if length $tail && !$self->is_closed;
    return;
}

sub on_data ($self, $bytes) {
    my $http = $self->{ws_opening_http};
    return unless $http;
    my $ok = eval { $http->input($bytes); 1 };
    if (!$ok) {
        $self->_report_handshake_error($@);
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
    $self->_report_handshake_error($error);
    return;
}

sub on_drain ($self) {
    my $http = $self->{ws_opening_http};
    $http->resume_output if $http && !$http->is_closed;
    return;
}

sub on_close ($self) {
    my $http = delete $self->{ws_opening_http};
    $http->transport_error('WebSocket opening transport closed')
        if $http && !$http->is_closed && !$http->is_switched;
    return;
}

sub unblock_send ($self, $bytes) { return $self->write($bytes) }
sub unblock_finish ($self) { return $self->end }
sub unblock_abort ($self, $error) {
    $self->SUPER::close unless $self->is_closed;
    return;
}

1;
