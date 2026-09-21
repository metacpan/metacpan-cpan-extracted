package Linux::Event::WebSocket::Server::_HTTPConnection;
use v5.36;
use strict;
use warnings;

use parent 'Linux::Event::HTTP::Server::Connection';

use Carp qw(croak);
use Scalar::Util qw(blessed);

use Linux::Event::Kernel::Timer;
use Linux::Event::WebSocket::_Handshake;
use Linux::Event::WebSocket::_State;

sub new ($class, %option) {
    my $self = $class->SUPER::new(%option);
    my $config = $self->SUPER::data;

    croak 'WebSocket server connection is missing server configuration'
        if !blessed($config)
        || !$config->isa('Linux::Event::WebSocket::Server::_Config');

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

    $self->SUPER::data($state);
    return $self;
}

sub _websocket_state ($self) {
    my $state = $self->SUPER::data;
    croak 'WebSocket server connection state is unavailable'
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

sub _report_handshake_error ($self, $error) {
    my $state = $self->_websocket_state;
    my $message = "$error";
    $message =~ s/\s+\z//;
    if (my $callback = $state->{callbacks}{error}) {
        $callback->($self, $message);
    }
    return;
}

sub _finish_server_open ($timer) {
    my $timer_state = $timer->data;
    my $connection = $timer_state->{connection};
    return if !$connection || $connection->is_closed;

    if ($connection->isa('Linux::Event::WebSocket::Connection')) {
        $connection->_ensure_websocket_open;
        return;
    }

    my $attempt = ($timer_state->{attempt} // 0) + 1;
    if ($attempt > 4) {
        $connection->_report_handshake_error(
            'WebSocket HTTP Upgrade did not complete protocol handoff'
        );
        $connection->SUPER::close if !$connection->is_closed;
        return;
    }

    Linux::Event::Kernel::Timer->new(
        loop     => $connection->loop,
        after    => 0,
        data     => {
            connection => $connection,
            attempt    => $attempt,
        },
        on_timer => \&_finish_server_open,
    );
    return;
}

sub _schedule_server_open ($self) {
    Linux::Event::Kernel::Timer->new(
        loop     => $self->loop,
        after    => 0,
        data     => {
            connection => $self,
            attempt    => 0,
        },
        on_timer => \&_finish_server_open,
    );
    return;
}

sub on_request ($self, $request, $response) {
    my $state = $self->_websocket_state;

    if (my $callback = $state->{on_handshake}) {
        my ($accepted, $ok, $error);
        {
            local $@;
            $ok = eval {
                $accepted = $callback->($request);
                1;
            };
            $error = $@;
        }

        if (!$ok) {
            $self->_report_handshake_error($error);
            $response->status(500);
            $response->body("WebSocket handshake callback failed\n");
            return;
        }

        if (!$accepted) {
            $response->status(403);
            $response->body("WebSocket upgrade rejected\n");
            return;
        }
    }

    my ($handshake, $ok, $error);
    {
        local $@;
        $ok = eval {
            $handshake = Linux::Event::WebSocket::_Handshake->server_from_request(
                $request,
                subprotocols => $state->{subprotocols},
            );
            Linux::Event::WebSocket::_Handshake->apply_server_response(
                $handshake,
                $response,
            );
            1;
        };
        $error = $@;
    }

    if (!$ok) {
        $self->_report_handshake_error($error);
        $response->status(400);
        $response->body("Bad WebSocket handshake\n");
        return;
    }

    $state->{handshake} = $handshake;
    $state->{request} = $request;

    my $target = $state->{connection_class};
    $self->transaction->upgrade($target);
    $self->_schedule_server_open;
    return;
}

sub on_error ($self, $error) {
    my $state = $self->_websocket_state;
    if (my $callback = $state->{callbacks}{error}) {
        $callback->($self, $error);
    }
    return;
}

sub on_eof ($self) {
    $self->_report_handshake_error('transport EOF during WebSocket handshake');
    $self->SUPER::close if !$self->is_closed;
    return;
}

# Linux::Event::HTTP intentionally preserves its constructor-installed drain
# and close wrappers across transition_to(). Those wrappers retain these two
# method coderefs, so forward them to the WebSocket lifecycle once the same
# object has transitioned.
sub on_drain ($self) {
    if ($self->isa('Linux::Event::WebSocket::Connection')) {
        Linux::Event::WebSocket::Connection::on_drain($self);
    }
    return;
}

sub on_close ($self) {
    if ($self->isa('Linux::Event::WebSocket::Connection')) {
        $self->_websocket_transport_closed;
    }
    return;
}

1;
