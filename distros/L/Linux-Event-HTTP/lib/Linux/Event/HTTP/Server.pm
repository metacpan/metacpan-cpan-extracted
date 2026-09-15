package Linux::Event::HTTP::Server;
use v5.36;
use strict;
use warnings;

use Carp qw(croak);

use Linux::Event::IO::Sock::Listener;
use Linux::Event::HTTP::Server::Connection;

our $VERSION = '0.001';

sub _load_connection_class ($class) {
    croak 'new(): connection_class must be a package name'
        if !defined($class) || ref($class)
        || $class !~ /\A[A-Za-z_][A-Za-z0-9_]*(?:::[A-Za-z_][A-Za-z0-9_]*)*\z/;

    if (!$class->can('new')) {
        (my $file = "$class.pm") =~ s{::}{/}g;
        require $file;
    }

    croak 'new(): connection_class must inherit Linux::Event::HTTP::Server::Connection'
        if !$class->isa('Linux::Event::HTTP::Server::Connection');
    return $class;
}

sub _take_callback ($name, $option) {
    return undef if !exists $option->{$name};
    my $callback = delete $option->{$name};
    croak "new(): $name must be a coderef" if ref($callback) ne 'CODE';
    return $callback;
}

sub new ($class, %option) {
    croak 'new(): stream_class is internal; use connection_class'
        if exists $option{stream_class};
    croak 'new(): stream is internal; use connection_class, tuning, tls, and callbacks'
        if exists $option{stream};
    croak 'new(): HTTP Server owns on_data; use on_request/on_body callbacks'
        if exists $option{on_data};
    croak 'new(): HTTP Server cannot use message framing callbacks'
        if exists($option{on_message}) || exists($option{on_messages});
    croak 'new(): on_request_final was removed; use on_request and Response->body or Transaction->response_body'
        if exists $option{on_request_final};

    my $connection_class = _load_connection_class(
        delete($option{connection_class})
            // 'Linux::Event::HTTP::Server::Connection',
    );

    my %callbacks;
    for my $name (qw(on_request on_body on_request_end)) {
        my $callback = _take_callback($name, \%option);
        $callbacks{$name} = $callback if $callback;
    }

    my %stream_callback;
    for my $name (qw(
        on_ready on_transport_ready on_drain on_eof on_error on_close
    )) {
        my $callback = _take_callback($name, \%option);
        $stream_callback{$name} = $callback if $callback;
    }

    my $listener_error = _take_callback('on_listener_error', \%option);

    my $tuning = exists($option{tuning}) ? delete($option{tuning}) : {};
    croak 'new(): tuning must be a hash reference'
        if ref($tuning) ne 'HASH';

    my $tls_enabled = exists $option{tls};
    my $tls = delete $option{tls};
    croak 'new(): tls must be a hash reference'
        if $tls_enabled && ref($tls) ne 'HASH';

    croak 'new(): HTTP Server requires on_request callback or connection_class method'
        if !$callbacks{on_request} && !$connection_class->can('on_request');

    my $data = delete $option{data};
    my $state = bless {
        callbacks => \%callbacks,
        data      => $data,
    }, 'Linux::Event::HTTP::Server::_ConnectionState';

    my %stream = (
        class  => $connection_class,
        data   => $state,
        tuning => $tuning,
        %stream_callback,
    );
    $stream{tls} = $tls if $tls_enabled;

    my $listener = Linux::Event::IO::Sock::Listener->new(
        %option,
        stream => \%stream,
        (defined($listener_error) ? (on_error => $listener_error) : ()),
    );

    return bless {
        listener         => $listener,
        connection_class => $connection_class,
        data             => $data,
        state            => $state,
    }, $class;
}

sub listener         ($self) { $self->{listener} }
sub connection_class ($self) { $self->{connection_class} }
sub data             ($self) { $self->{data} }
sub loop             ($self) { $self->{listener}->loop }
sub fh               ($self) { $self->{listener}->fh }
sub fd               ($self) { $self->{listener}->fd }
sub host             ($self) { $self->{listener}->host }
sub port             ($self) { $self->{listener}->port }
sub path             ($self) { $self->{listener}->path }
sub family           ($self) { $self->{listener}->family }
sub family_number    ($self) { $self->{listener}->family_number }
sub is_tcp           ($self) { $self->{listener}->is_tcp }
sub is_unix          ($self) { $self->{listener}->is_unix }
sub state            ($self) { $self->{listener}->state }

sub pause ($self) {
    $self->{listener}->pause;
    return $self;
}

sub resume ($self) {
    $self->{listener}->resume;
    return $self;
}

sub close ($self) {
    $self->{listener}->close;
    return $self;
}

1;

__END__

=head1 NAME

Linux::Event::HTTP::Server - HTTP server endpoint

=head1 SYNOPSIS

    use v5.36;
    use Linux::Event::Loop;
    use Linux::Event::HTTP::Server;

    my $loop = Linux::Event::Loop->new;

    my $server = Linux::Event::HTTP::Server->new(
        loop => $loop,
        host => '127.0.0.1',
        port => 8080,
        on_request => sub ($conn, $req, $res) {
            $res->header('Content-Type', 'text/plain');
            $res->body("hello\n");
        },
    );

    $loop->run;

=head1 DESCRIPTION

C<Linux::Event::HTTP::Server> is the ordinary entry point for an HTTP server.
It listens using Linux::Event and invokes C<on_request> whenever a validated
request head is available.

The callback receives:

=over 4

=item * C<$conn> - the persistent HTTP connection

=item * C<$req> - the current L<Linux::Event::HTTP::Request>

=item * C<$res> - the L<Linux::Event::HTTP::Response> for that request

=back

Request and Response are HTTP message objects. The one-request/one-response
exchange is represented by L<Linux::Event::HTTP::Transaction> and is available
as C<< $conn->transaction >> while active. Response does not retain a hidden
Connection or peer-Request back-reference.

A complete scalar response body is configured on the Response:

    $res->body("hello\n");

For an incremental outgoing body, use the active Transaction:

    on_request => sub ($conn, $req, $res) {
        $res->header('Content-Type', 'text/plain');
        my $body = $conn->transaction->response_body;
        $body->write("one\n");
        $body->complete("two\n");
    },

Completing an HTTP response does not normally close the connection. HTTP
keep-alive may reuse the same connection for later Transactions.

=head1 DEFERRED RESPONSES

Inside an HTTP callback, C<< $res->body(...) >> is committed after callback
return when protocol state permits. This allows metadata to be configured in
any natural order before output begins.

If another event completes the Response later, retain the Transaction and send
the complete scalar message explicitly:

    my $tx = $conn->transaction;

    Linux::Event::Kernel::Timer->new(
        loop => $conn->loop,
        after => 0.1,
        on_timer => sub ($timer) {
            $tx->response->body("later\n");
            $tx->send_response;
        },
    );

The explicit C<send_response> call is intentional. Response remains a
transport-independent message and setting C<body> later does not secretly write
to a socket.

=head1 REQUEST BODIES

Request bodies are incremental-first. Add C<on_body> when body bytes are needed,
and C<on_request_end> when work should happen after the complete request input
has arrived:

    my $server = Linux::Event::HTTP::Server->new(
        loop => $loop,
        port => 8080,

        on_request => sub ($conn, $req, $res) {
            $conn->data->{body} = '';
        },

        on_body => sub ($conn, $req, $res, $bytes) {
            $conn->data->{body} .= $bytes;
        },

        on_request_end => sub ($conn, $req, $res) {
            $res->body("received\n");
        },
    );

If C<on_body> is absent, the server drains request-body bytes without building a
whole-body scalar. C<Request-E<gt>is_complete> becomes true at the actual
request-body boundary.

=head1 UPGRADE

HTTP Upgrade is an exchange operation owned by Transaction. Configure the
Response switching metadata and ask the active Transaction to hand off the live
transport:

    $res->header('Upgrade', 'my-protocol');
    $conn->transaction->upgrade('MyProtocolConnection');

The server validates the HTTP/1.1 Upgrade, queues the 101 response, completes
the HTTP Transaction, and then uses Linux::Event C<transition_to()> on the same
stream object. Response itself has no C<upgrade> method.

=head1 CONNECTION SUBCLASSES

Most applications do not need to subclass the HTTP connection. Use
C<connection_class> when reusable transport defaults, stream tuning, socket
policy, or callback methods belong on a class:

    package MyHTTP;
    use parent 'Linux::Event::HTTP::Server::Connection';

    sub stream_tuning ($class) {
        return read_budget_bytes => 262_144;
    }

    sub on_request ($self, $req, $res) {
        $res->body("hello\n");
    }

    package main;

    my $server = Linux::Event::HTTP::Server->new(
        loop             => $loop,
        port             => 8080,
        connection_class => 'MyHTTP',
    );

C<connection_class> defaults to
L<Linux::Event::HTTP::Server::Connection>.

=head1 TUNING AND CONNECTION CALLBACKS

Supply deployment-specific Stream tuning directly to the Server. These values
override C<stream_tuning()> defaults on the configured Connection class:

    my $server = Linux::Event::HTTP::Server->new(
        loop => $loop,
        port => 8080,
        tuning => {
            read_size         => 131_072,
            read_budget_bytes => 524_288,
            idle_timeout      => 60,
        },
        on_request => sub ($conn, $req, $res) {
            $res->body("hello\n");
        },
    );

Accepted-connection lifecycle callbacks are C<on_ready>,
C<on_transport_ready>, C<on_drain>, C<on_eof>, C<on_error>, and C<on_close>.
C<on_listener_error> is the distinct callback for listening and acceptance
failures. The advanced C<on_accept($listener, $conn)> callback receives the
underlying Listener and each newly accepted HTTP Connection.

=head1 TLS

HTTPS uses the same Server API. Activate Linux::Event TLS transport policy with
the Server C<tls> option:

    my $server = Linux::Event::HTTP::Server->new(
        loop => $loop,
        port => 8443,
        tls => {
            cert_file => '/etc/myapp/server-cert.pem',
            key_file  => '/etc/myapp/server-key.pem',
            alpn      => ['http/1.1'],
        },
        on_request => sub ($conn, $req, $res) {
            $res->body("secure\n");
        },
    );

A Connection subclass may define C<tls_defaults()> for reusable ALPN and
timeout defaults. The Server C<tls> option is still required to activate TLS,
so the same Connection class may be used for plain HTTP and HTTPS listeners.

=head1 METHODS

=head2 listener

Returns the underlying L<Linux::Event::IO::Sock::Listener> for advanced use.

=head2 connection_class

Returns the configured HTTP Connection class name.

=head2 data

Returns the application data supplied to the Server.

=head2 loop, fh, fd, host, port, path, family, family_number, is_tcp, is_unix, state

Delegate to the underlying Listener.

=head2 pause

Pauses acceptance and returns the Server.

=head2 resume

Resumes acceptance and returns the Server.

=head2 close

Closes the listening endpoint and returns the Server. Existing accepted HTTP
connections keep their independent lifecycles.

=head1 SEE ALSO

L<Linux::Event::HTTP::Server::Connection>, L<Linux::Event::HTTP::Transaction>,
L<Linux::Event::HTTP::Request>, L<Linux::Event::HTTP::Response>,
L<Linux::Event::HTTP::Body::Stream>, L<Linux::Event::TLS>.

=cut
