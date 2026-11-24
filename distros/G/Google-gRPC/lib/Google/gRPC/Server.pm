package Google::gRPC::Server;

use strict;
use warnings;
use Moo;
use Carp qw(croak);
use Scalar::Util qw(blessed);
use Protocol::HTTP2::Server;
use Google::gRPC::Framing;
use Google::gRPC::Status;

our $VERSION = '0.10';

has host => (
    is      => 'ro',
    default => sub { '127.0.0.1' },
);

has port => (
    is      => 'rw',
    default => sub { 0 },
);

has _handlers => (
    is      => 'ro',
    default => sub { {} },
);

has _listener => (
    is      => 'rw',
    clearer => '_clear_listener',
);

has _stop_cv => (
    is      => 'rw',
    clearer => '_clear_stop_cv',
);

sub register_method {
    my ($self, $service, $method, $handler, $opts) = @_;
    croak 'service is required' unless defined $service && length $service;
    croak 'method is required'  unless defined $method  && length $method;
    croak 'handler must be a CODE ref' unless ref($handler) eq 'CODE';

    $opts ||= {};
    my $path = '/' . $service . '/' . $method;
    $self->_handlers->{$path} = {
        service       => $service,
        method        => $method,
        handler       => $handler,
        request_class => $opts->{request_class},
    };
    return $self;
}

sub register_service {
    my ($self, $service, $methods) = @_;
    croak 'service is required'          unless defined $service && length $service;
    croak 'methods must be a HASH ref'   unless ref($methods) eq 'HASH';

    for my $method (sort keys %{$methods}) {
        my $entry = $methods->{$method};
        if (ref($entry) eq 'CODE') {
            $self->register_method($service, $method, $entry);
        }
        elsif (ref($entry) eq 'HASH') {
            $self->register_method($service, $method, $entry->{handler}, $entry);
        }
        else {
            croak 'Invalid method entry for ' . $method;
        }
    }
    return $self;
}

sub dispatch_path {
    my ($self, $path) = @_;
    return undef unless defined $path;
    return $self->_handlers->{$path};
}

sub handle_unary {
    my ($self, $path, $payload, $metadata) = @_;
    my $spec = $self->dispatch_path($path);
    if (!$spec) {
        return (12, 'Unimplemented method: ' . ($path // ''), undef);
    }

    my $req = $payload;
    if (my $req_class = $spec->{request_class}) {
        my $decoded = eval { $req_class->decode($payload) };
        if ($@) {
            my $err = $@;
            $err =~ s/\s+\z//;
            return (3, 'Invalid request payload: ' . $err, undef);
        }
        $req = $decoded;
    }

    my $ctx = {
        path     => $path,
        service  => $spec->{service},
        method   => $spec->{method},
        metadata => $metadata || {},
    };

    my $resp = eval { $spec->{handler}->($req, $ctx) };
    if ($@) {
        my $err = $@;
        if (blessed($err) && $err->isa('Google::gRPC::Status')) {
            return ($err->code, $err->message, undef);
        }
        $err =~ s/\s+\z//;
        return (13, $err, undef);
    }

    my $resp_bytes = '';
    if (defined $resp) {
        if (blessed($resp) && $resp->can('encode')) {
            $resp_bytes = $resp->encode();
        }
        else {
            $resp_bytes = $resp;
        }
    }

    return (0, '', $resp_bytes);
}

sub _extract_metadata {
    my ($headers_ref) = @_;
    my %meta;
    return \%meta unless ref($headers_ref) eq 'ARRAY';

    for (my $i = 0; $i < @{$headers_ref}; $i += 2) {
        my $k = lc($headers_ref->[$i]);
        my $v = $headers_ref->[$i + 1];
        $meta{$k} = $v;
    }
    return \%meta;
}

sub new_session {
    my ($self) = @_;
    my $server;
    $server = Protocol::HTTP2::Server->new(
        on_request => sub {
            my ($stream_id, $headers_ref, $data) = @_;
            my $meta = _extract_metadata($headers_ref);
            my $path = $meta->{':path'} // '';

            my $buf     = defined $data ? $data : '';
            my @frames  = Google::gRPC::Framing::unpack_frame(\$buf);
            my $payload = @frames ? $frames[0]->{payload} : '';

            my ($code, $message, $resp_bytes)
                = $self->handle_unary($path, $payload, $meta);

            my $body = defined $resp_bytes
                ? Google::gRPC::Framing::pack_frame($resp_bytes)
                : '';

            my @resp_headers = (
                'content-type' => 'application/grpc',
                'grpc-status'  => $code,
            );
            if (defined $message && length $message) {
                push @resp_headers, 'grpc-message' => $message;
            }

            $server->response(
                ':status' => 200,
                stream_id => $stream_id,
                headers   => \@resp_headers,
                data      => $body,
            );
        },
        on_error => sub {
            my ($err) = @_;
        },
    );
    return $server;
}

sub listen {
    my ($self, %opts) = @_;
    require AnyEvent;
    require AnyEvent::Socket;
    require AnyEvent::Handle;

    my $host = exists $opts{host} ? $opts{host} : $self->host;
    my $port = exists $opts{port} ? $opts{port} : $self->port;

    my $guard = AnyEvent::Socket::tcp_server(
        $host,
        $port,
        sub {
            my ($fh) = @_;
            my $session = $self->new_session();
            my $handle;
            $handle = AnyEvent::Handle->new(
                fh       => $fh,
                on_error => sub {
                    $handle->destroy if $handle;
                    undef $handle;
                },
                on_eof => sub {
                    $handle->destroy if $handle;
                    undef $handle;
                },
                on_read => sub {
                    my ($hdl) = @_;
                    my $chunk = delete $hdl->{rbuf};
                    $session->feed($chunk) if defined $chunk && length $chunk;
                    while (defined(my $frame = $session->next_frame)) {
                        $hdl->push_write($frame);
                    }
                    if ($session->shutdown) {
                        $hdl->push_shutdown;
                    }
                },
            );
            while (defined(my $frame = $session->next_frame)) {
                $handle->push_write($frame);
            }
        },
        sub {
            my ($fh, $bound_host, $bound_port) = @_;
            $self->port($bound_port);
            return 128;
        },
    );

    $self->_listener($guard);
    return $self->port;
}

sub stop {
    my ($self) = @_;
    $self->_clear_listener;
    if (my $cv = $self->_stop_cv) {
        $cv->send;
        $self->_clear_stop_cv;
    }
    return $self;
}

sub run {
    my ($self, %opts) = @_;
    require AnyEvent;
    $self->listen(%opts) unless $self->_listener;
    my $cv = AnyEvent->condvar;
    $self->_stop_cv($cv);
    $cv->recv;
    return $self;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Google::gRPC::Server - HTTP/2 gRPC server for Perl

=head1 SYNOPSIS

    use Google::gRPC::Server;

    my $server = Google::gRPC::Server->new(
        host => '127.0.0.1',
        port => 50051,
    );

    $server->register_method(
        'helloworld.Greeter',
        'SayHello',
        sub {
            my ($req, $ctx) = @_;
            return 'Hello, ' . $req;
        },
    );

    $server->run();

=head1 DESCRIPTION

C<Google::gRPC::Server> implements a gRPC-over-HTTP/2 server in Perl using
L<Protocol::HTTP2::Server>, L<AnyEvent::Socket>, L<Google::gRPC::Framing>, and
L<Google::gRPC::Status>.

=head1 ATTRIBUTES

=head2 host

Bind address for L</listen> (default: C<127.0.0.1>).

=head2 port

TCP port for L</listen> (default: C<0>, which binds an ephemeral port and
updates C<port> to the assigned port number).

=head1 METHODS

=head2 register_method( $service, $method, \&handler, \%opts )

Registers a unary RPC handler for C</$service/$method>. Optional
C<$opts-E<gt>{request_class}> automatically decodes incoming request payloads
via C<< $request_class->decode($bytes) >>.

=head2 register_service( $service, \%methods )

Registers multiple methods for C<$service>. Each value in C<%methods> may be a
C<CODE> reference or a hashref with C<handler> and optional C<request_class>.

=head2 dispatch_path( $path )

Returns the registered handler specification hashref for C<$path>, or C<undef>
if no handler is registered.

=head2 handle_unary( $path, $payload, \%metadata )

Invokes the registered handler for C<$path> and returns
C<($grpc_status_code, $grpc_message, $response_bytes)>.

=head2 new_session()

Returns a L<Protocol::HTTP2::Server> instance wired to this server's gRPC
dispatcher and framing layer, suitable for both live sockets and in-memory
testing.

=head2 listen( %opts )

Binds a TCP listener via L<AnyEvent::Socket::tcp_server> and returns the bound
port number.

=head2 run( %opts )

Calls L</listen> if not already listening and blocks in the L<AnyEvent> event
loop until L</stop> is called.

=head2 stop()

Closes the TCP listener and unblocks L</run>.

=head1 SEE ALSO

L<Google::gRPC>, L<Google::gRPC::Client>, L<Google::gRPC::Framing>,
L<Google::gRPC::Status>

=head1 AUTHOR

C.J. Collier <cjac@google.com>

=head1 LICENSE

Licensed under the Apache License, Version 2.0.

=cut
