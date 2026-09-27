package Linux::Event::HTTP::Transaction;
use v5.36;
use strict;
use warnings;

use Scalar::Util qw(blessed weaken);

our $VERSION = '0.003';

my %TERMINAL = map { $_ => 1 } qw(complete cancelled error);

sub _new ($class, %args) {
    my $request    = delete $args{request};
    my $controller = delete $args{controller};

    die 'Transaction requires a Linux::Event::HTTP::Request'
        if !blessed($request)
        || !$request->isa('Linux::Event::HTTP::Request');
    die 'Transaction controller must be an object'
        if defined($controller) && !blessed($controller);
    die 'unknown Transaction option: ' . join(', ', sort keys %args)
        if %args;

    my $self = bless {
        request                   => $request,
        request_body              => undef,
        response                  => undef,
        response_body             => undef,
        response_output_started   => 0,
        response_output_complete  => 0,
        upgrade_pending           => 0,
        tunnel_pending            => 0,
        state                     => 'pending',
        error                     => undef,
        controller                => $controller,
    }, $class;
    weaken($self->{controller}) if defined $self->{controller};
    return $self;
}

sub _new_server_active ($class, $request, $response, $controller) {
    my $self = bless {
        request    => $request,
        response   => $response,
        state      => 'active',
        controller => $controller,
    }, $class;
    weaken($self->{controller});
    return $self;
}

sub request             ($self) { $self->{request} }
sub response            ($self) { $self->{response} }
sub state               ($self) { $self->{state} }
sub error               ($self) { $self->{error} }
sub is_complete         ($self) { $self->{state} eq 'complete' }
sub is_cancelled        ($self) { $self->{state} eq 'cancelled' }
sub is_terminal         ($self) { !!$TERMINAL{$self->{state}} }
sub is_response_started ($self) { !!$self->{response_output_started} }
sub is_upgrading        ($self) { !!$self->{upgrade_pending} }
sub is_tunneling        ($self) { !!$self->{tunnel_pending} }

sub request_body ($self, @args) {
    die 'request_body(): Transaction is already terminal'
        if $self->is_terminal;
    my $request = $self->{request};

    if (my $body = $self->{request_body}) {
        die 'request_body options may only be supplied when the producer is created'
            if @args;
        return $body;
    }

    die 'request_body(): Request is not configured for incremental body production'
        if !$request->_has_incremental_body;
    die 'request_body options must be key/value pairs' if @args % 2;

    require Linux::Event::HTTP::Body::Stream;
    my $body = Linux::Event::HTTP::Body::Stream->_new(
        $self, 'request', @args,
    );
    $self->{request_body} = $body;
    return $body;
}

sub response_body ($self, @args) {
    die 'response_body(): Transaction is already terminal'
        if $self->is_terminal;
    my $response = $self->{response}
        or die 'response_body(): Transaction has no Response yet';

    if (my $body = $self->{response_body}) {
        die 'response_body options may only be supplied when the producer is created'
            if @args;
        return $body;
    }

    die 'response_body(): response output has already started'
        if $self->{response_output_started};
    die 'response_body options must be key/value pairs' if @args % 2;

    require Linux::Event::HTTP::Body::Stream;
    my $body = Linux::Event::HTTP::Body::Stream->_new(
        $self, 'response', @args,
    );

    $response->_begin_stream_body;
    $self->{response_body} = $body;
    return $body;
}

sub send_response ($self) {
    die 'send_response(): Transaction is already terminal'
        if $self->is_terminal;
    die 'send_response(): response output has already started'
        if $self->{response_output_started};

    my $response = $self->{response}
        or die 'send_response(): Transaction has no Response yet';
    die 'send_response(): Response does not have a complete scalar body'
        if !$response->_has_scalar_body;

    my $controller = $self->{controller}
        or die 'send_response(): Transaction has no active controller';
    $controller->_send_http_response($self);
    return $self;
}

sub upgrade ($self, $target_class) {
    die 'upgrade(): Transaction is already terminal'
        if $self->is_terminal;
    die 'upgrade(): response output has already started'
        if $self->{response_output_started};
    die 'upgrade(): Transaction already has an Upgrade handoff pending'
        if $self->{upgrade_pending};
    die 'upgrade(): Transaction already has a CONNECT tunnel handoff pending'
        if $self->{tunnel_pending};

    my $response = $self->{response}
        or die 'upgrade(): Transaction has no Response yet';
    my $controller = $self->{controller}
        or die 'upgrade(): Transaction has no active controller';

    $controller->_upgrade_http_transaction($self, $target_class);
    return $self;
}

sub tunnel ($self, $target_class) {
    die 'tunnel(): Transaction is already terminal'
        if $self->is_terminal;
    die 'tunnel(): response output has already started'
        if $self->{response_output_started};
    die 'tunnel(): Transaction already has an Upgrade handoff pending'
        if $self->{upgrade_pending};
    die 'tunnel(): Transaction already has a CONNECT tunnel handoff pending'
        if $self->{tunnel_pending};

    my $response = $self->{response}
        or die 'tunnel(): Transaction has no Response yet';
    my $controller = $self->{controller}
        or die 'tunnel(): Transaction has no active controller';

    $controller->_tunnel_http_transaction($self, $target_class);
    return $self;
}

sub cancel ($self) {
    return $self if $self->is_terminal;

    if (my $controller = $self->{controller}) {
        $controller->_cancel_http_transaction($self);
    }

    return $self if $self->is_terminal;
    return $self->_mark_cancelled;
}

sub _set_controller ($self, $controller) {
    die 'cannot change controller of a terminal Transaction'
        if $self->is_terminal;
    die 'Transaction controller must be an object'
        if defined($controller) && !blessed($controller);

    $self->{controller} = $controller;
    weaken($self->{controller}) if defined $self->{controller};
    return $self;
}

sub _activate ($self) {
    die 'cannot activate a terminal Transaction' if $self->is_terminal;
    $self->{state} = 'active';
    return $self;
}

sub _set_response ($self, $response) {
    die 'cannot attach a Response to a terminal Transaction'
        if $self->is_terminal;
    die 'Transaction already has a Response' if $self->{response};
    die 'Transaction response must be a Linux::Event::HTTP::Response'
        if !blessed($response)
        || !$response->isa('Linux::Event::HTTP::Response');

    $self->{response} = $response;
    $self->{state} = 'active' if $self->{state} eq 'pending';
    return $response;
}

sub _write_body ($self, $kind, $bytes, $final, $operation) {
    die "$operation(): Transaction is already terminal"
        if $self->is_terminal;
    die "$operation(): unsupported HTTP body producer '$kind'"
        if $kind ne 'request' && $kind ne 'response';

    my $message = $kind eq 'request'
        ? $self->{request}
        : ($self->{response}
            or die "$operation(): Transaction has no Response");
    my $controller = $self->{controller}
        or die "$operation(): Transaction has no active controller";

    if ($final) {
        $message->_mark_complete;
    }

    my ($accepted, $ok, $error);
    {
        local $@;
        $ok = eval {
            if ($kind eq 'request') {
                $accepted = $controller->_write_http_request_body(
                    $self, $bytes, $final, $operation,
                );
            } else {
                $accepted = $controller->_write_http_response_body(
                    $self, $bytes, $final, $operation,
                );
            }
            1;
        };
        $error = $@;
    }

    if (!$ok) {
        $message->_mark_incomplete if $final;
        die $error;
    }

    return $accepted;
}

sub _request_body_object ($self) {
    return $self->{request_body};
}

sub _response_body_object ($self) {
    return $self->{response_body};
}

sub _is_response_output_complete ($self) {
    return !!$self->{response_output_complete};
}

sub _mark_response_started ($self) {
    $self->{response_output_started} = 1;
    return $self;
}

sub _mark_response_output_complete ($self) {
    $self->{response_output_started} = 1;
    $self->{response_output_complete} = 1;
    return $self;
}

sub _set_upgrade_pending ($self) {
    die 'cannot schedule Upgrade on a terminal Transaction'
        if $self->is_terminal;
    die 'cannot schedule Upgrade while CONNECT tunnel handoff is pending'
        if $self->{tunnel_pending};
    $self->{upgrade_pending} = 1;
    return $self;
}

sub _clear_upgrade_pending ($self) {
    $self->{upgrade_pending} = 0;
    return $self;
}

sub _set_tunnel_pending ($self) {
    die 'cannot schedule CONNECT tunnel on a terminal Transaction'
        if $self->is_terminal;
    die 'cannot schedule CONNECT tunnel while Upgrade handoff is pending'
        if $self->{upgrade_pending};
    $self->{tunnel_pending} = 1;
    return $self;
}

sub _clear_tunnel_pending ($self) {
    $self->{tunnel_pending} = 0;
    return $self;
}

sub _cancel_body_producers ($self) {
    if (my $body = $self->{request_body}) {
        $body->_cancel;
    }
    if (my $body = $self->{response_body}) {
        $body->_cancel;
    }
    return;
}

sub _mark_complete ($self) {
    die 'cannot complete a terminal Transaction' if $self->is_terminal;
    die 'cannot complete a Transaction before it has a Response'
        if !$self->{response};

    if (my $body = $self->{request_body}) {
        $body->_cancel if !$body->is_complete;
    }
    $self->{upgrade_pending} = 0;
    $self->{tunnel_pending} = 0;
    $self->{state} = 'complete';
    delete $self->{controller};
    return $self;
}

sub _mark_cancelled ($self) {
    return $self if $self->{state} eq 'cancelled';
    die 'cannot cancel a terminal Transaction' if $self->is_terminal;

    $self->_cancel_body_producers;
    $self->{upgrade_pending} = 0;
    $self->{tunnel_pending} = 0;
    $self->{state} = 'cancelled';
    delete $self->{controller};
    return $self;
}

sub _fail ($self, $error) {
    die 'cannot fail a terminal Transaction' if $self->is_terminal;
    die 'Transaction error must be defined' if !defined $error;

    $self->_cancel_body_producers;
    $self->{upgrade_pending} = 0;
    $self->{tunnel_pending} = 0;
    $self->{error} = $error;
    $self->{state} = 'error';
    delete $self->{controller};
    return $self;
}

sub CLONE_SKIP { 1 }

1;

__END__

=head1 NAME

Linux::Event::HTTP::Transaction - one HTTP request/response exchange

=head1 DESCRIPTION

A Transaction represents exactly one HTTP exchange:

    one Request + one Response + exchange lifecycle

This definition is the same for HTTP/1 and HTTP/2. An HTTP/2 connection may
have many Transactions active at once because each stream is a separate
exchange.

Request and Response are message objects. Transaction owns the lifecycle that
connects them: streaming body producers, cancellation, delayed response send,
and HTTP/1 Upgrade/CONNECT handoff.

A Transaction does not own the socket, connection pool, redirect chain, or
transport output queue.

Applications normally receive Transactions from
L<Linux::Event::HTTP::Client> or from an active server connection.

=head1 METHODS

=head2 request

Returns the Request for this exchange.

=head2 response

Returns the Response once one exists, or undef beforehand.

=head2 request_body

Returns the writable producer for an outgoing streaming Request body.

    my $body = $operation->request_body;
    $body->write($bytes);
    $body->complete;

The producer belongs to the Transaction, not to Request.

=head2 response_body

Creates or returns the writable producer for an outgoing streaming Response:

    my $body = $conn->transaction->response_body(
        on_drain  => sub ($body) { ... },
        on_cancel => sub ($body) { ... },
    );

    $body->write($bytes);
    $body->complete;

=head2 send_response

Explicitly sends a complete scalar server Response that was finished after the
original HTTP callback returned.

Ordinary responses completed during C<on_request>, C<on_body>, or
C<on_request_end> do not need this call.

=head2 upgrade

Schedules an HTTP/1.1 Upgrade handoff:

    $res->header('Upgrade', 'my-protocol');
    $conn->transaction->upgrade('MyProtocolConnection');

The same live Linux::Event stream is transitioned after the HTTP exchange
reaches the required boundary.

=head2 tunnel

Accepts a valid server-side HTTP/1.1 CONNECT exchange and schedules handoff of
the same live stream:

    $conn->transaction->tunnel('MyTunnelConnection');

Opening or bridging the upstream destination remains application policy.

=head2 is_response_started

True after response output has begun.

=head2 is_upgrading

True while an HTTP/1 Upgrade handoff is pending.

=head2 is_tunneling

True while an HTTP/1 CONNECT handoff is pending.

=head2 state

Returns the coarse lifecycle state: C<pending>, C<active>, C<complete>,
C<cancelled>, or C<error>.

=head2 cancel

Requests cancellation. Application-visible cancellation is idempotent; the
active protocol executor chooses the correct wire action.

=head2 is_complete

True after successful exchange completion.

=head2 is_cancelled

True after cancellation.

=head2 is_terminal

True after success, cancellation, or error.

=head2 error

Returns the terminal error value after failure, or undef otherwise.

=head1 SEE ALSO

L<Linux::Event::HTTP::Request>, L<Linux::Event::HTTP::Response>,
L<Linux::Event::HTTP::Client::Operation>,
L<Linux::Event::HTTP::Body::Stream>.

=cut
