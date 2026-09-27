package Linux::Event::HTTP::Server;
use v5.36;
use strict;
use warnings;

use Carp qw(croak);

use Linux::Event::IO::Sock::Listener;
use Linux::Event::HTTP::Server::Connection;

our $VERSION = '0.003';

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

sub _http2_available () {
    return 0 if !eval {
        require Net::HTTP2::nghttp2;
        Net::HTTP2::nghttp2->VERSION('0.011');
        require Linux::Event::HTTP::_HTTP2::Server;
        require Linux::Event::HTTP::_HTTP2::ServerConnection;
        1;
    };
    return Net::HTTP2::nghttp2->available ? 1 : 0;
}

sub _http2_ready ($conn, $user_ready, $max_header_list_size) {
    if (($conn->selected_alpn // '') ne 'h2') {
        $user_ready->($conn) if $user_ready;
        return;
    }

    $conn->pause_read;
    $conn->loop->defer(sub {
        return if $conn->is_closed;

        my $executor = Linux::Event::HTTP::_HTTP2::Server->new(
            stream         => $conn,
            connection     => $conn,
            autostart      => 0,
            on_request     => $conn->{_http_on_request},
            on_body        => $conn->{_http_on_body},
            on_request_end => $conn->{_http_on_request_end},
            max_header_list_size => $max_header_list_size,
        );
        $conn->{_http2_executor} = $executor;

        $conn->transition_to(
            'Linux::Event::HTTP::_HTTP2::ServerConnection',
        );
        $executor->start;

        $user_ready->($conn) if $user_ready;
        $conn->resume_read if $conn->is_read_paused;
    });
    return;
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

    my $connection_class_option = delete $option{connection_class};
    my $connection_class = _load_connection_class(
        $connection_class_option
            // 'Linux::Event::HTTP::Server::Connection',
    );

    my $http2 = exists($option{http2}) ? delete($option{http2}) : 0;
    my $has_http2_max_header_list_size =
        exists $option{http2_max_header_list_size};
    my $http2_max_header_list_size =
        $has_http2_max_header_list_size
            ? delete($option{http2_max_header_list_size})
            : 65_536;
    croak 'new(): http2 must be zero or one'
        if !defined($http2) || ref($http2)
        || ("$http2" ne '0' && "$http2" ne '1');
    $http2 = $http2 ? 1 : 0;
    croak 'new(): http2_max_header_list_size must be a positive integer'
        if ref($http2_max_header_list_size)
        || "$http2_max_header_list_size" !~ /\A[0-9]+\z/
        || $http2_max_header_list_size < 1;
    croak 'new(): http2_max_header_list_size requires http2 => 1'
        if !$http2 && $has_http2_max_header_list_size;

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
    $tls = { %$tls } if $tls_enabled;

    if ($http2) {
        croak 'new(): http2 requires tls'
            if !$tls_enabled;
        croak 'new(): http2 currently requires the default connection_class'
            if defined($connection_class_option);
        croak 'new(): http2 owns TLS ALPN selection; do not supply tls => { alpn => ... }'
            if exists $tls->{alpn};
        croak 'new(): HTTP/2 support requires Net::HTTP2::nghttp2 0.011 or newer'
            if !_http2_available();
        $tls->{alpn} = [ 'h2', 'http/1.1' ];

        my $user_on_ready = $stream_callback{on_ready};
        $stream_callback{on_ready} = sub ($conn) {
            _http2_ready(
                $conn, $user_on_ready, 0 + $http2_max_header_list_size,
            );
        };
    }

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
        http2            => $http2,
        http2_max_header_list_size => 0 + $http2_max_header_list_size,
    }, $class;
}

sub listener         ($self) { $self->{listener} }
sub connection_class ($self) { $self->{connection_class} }
sub data             ($self) { $self->{data} }
sub http2            ($self) { !!$self->{http2} }
sub http2_max_header_list_size ($self) {
    return $self->{http2_max_header_list_size};
}
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

Linux::Event::HTTP::Server - HTTP/1.x and HTTP/2 server endpoint

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

For HTTPS with HTTP/2 negotiation:

    my $server = Linux::Event::HTTP::Server->new(
        loop  => $loop,
        port  => 8443,
        http2 => 1,

        tls => {
            cert_file => '/path/server-cert.pem',
            key_file  => '/path/server-key.pem',
        },

        on_request => sub ($conn, $req, $res) {
            $res->body("HTTP " . $req->version . "\n");
        },
    );

=head1 DESCRIPTION

C<Linux::Event::HTTP::Server> is the ordinary server entry point.

The same C<on_request> callback model is used for HTTP/1 and HTTP/2. The
callback receives:

    ($conn, $req, $res)

where C<$req> is the Request message, C<$res> is the Response message, and
C<$conn> is the live HTTP connection.

The active L<Linux::Event::HTTP::Transaction> is available through:

    my $tx = $conn->transaction;

Use the Transaction only when exchange lifecycle operations are needed, such as
streaming output, delayed output, Upgrade, or CONNECT handoff.

=head1 CONSTRUCTOR

    my $server = Linux::Event::HTTP::Server->new(%options);

Common options are:

=over 4

=item * C<loop>

The L<Linux::Event::Loop>.

=item * C<host>, C<port>, C<path>

Listener address options passed to Linux::Event.

=item * C<on_request>

Required unless the configured connection class provides an C<on_request>
method.

=item * C<on_body>

Receives request-body chunks:

    on_body => sub ($conn, $req, $res, $bytes) { ... }

If omitted, request-body bytes are drained instead of accumulated.

=item * C<on_request_end>

Runs after the complete request body boundary is reached.

=item * C<tls>

Enables Linux::Event TLS transport.

=item * C<http2>

When true, enables HTTP/2 negotiation for TLS connections. HTTP/2 requires
L<Net::HTTP2::nghttp2> 0.011 or newer.

=item * C<http2_max_header_list_size>

Maximum decoded HTTP/2 request/trailer header-list size. Default: 65,536 bytes.

=item * C<tuning>

Linux::Event Stream tuning for accepted connections.

=item * C<data>

Application data available through C<< $server->data >> and connection state.

=item * C<connection_class>

Advanced HTTP/1 connection subclass. The default is
L<Linux::Event::HTTP::Server::Connection>. HTTP/2 currently requires the
default connection class.

=back

Listener and accepted-connection lifecycle callbacks supported by the
constructor include C<on_ready>, C<on_transport_ready>, C<on_drain>, C<on_eof>,
C<on_error>, C<on_close>, and C<on_listener_error>.

=head1 RESPONSES

For a complete response already in memory:

    on_request => sub ($conn, $req, $res) {
        $res->status(200);
        $res->header('Content-Type', 'text/plain');
        $res->body("hello\n");
    }

A scalar body configured during an HTTP callback is committed after that
callback returns.

Completing a response does not normally close the connection. HTTP persistence
is handled by the selected protocol.

=head1 STREAMING RESPONSES

For incremental output, obtain a body producer from the Transaction:

    on_request => sub ($conn, $req, $res) {
        my $body = $conn->transaction->response_body(
            on_drain  => sub ($body) { ... },
            on_cancel => sub ($body) { ... },
        );

        $body->write($chunk);
        $body->complete($final_chunk);
    };

C<write> follows Linux::Event backpressure semantics. A false return means the
bytes were accepted but the producer should pause until C<on_drain> runs.

=head1 REQUEST BODIES

Request bodies are streaming-first:

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

If C<on_body> is omitted, body bytes are drained rather than stored in the
Request.

=head1 DELAYED RESPONSES

A Response may be completed by another event later. Retain the Transaction and
send the finished scalar response explicitly:

    my $tx = $conn->transaction;

    Linux::Event::Kernel::Timer->new(
        loop  => $conn->loop,
        after => 0.1,

        on_timer => sub ($timer) {
            $tx->response->body("later\n");
            $tx->send_response;
        },
    );

C<send_response> is explicit because Response is a message object, not a hidden
transport handle.

=head1 TLS AND HTTP/2

TLS is enabled with the C<tls> constructor option.

HTTP/2 is enabled with:

    http2 => 1

When enabled, the Server advertises C<h2> before C<http/1.1>. ALPN selects the
protocol while applications continue using the same C<on_request> callback and
Request/Response classes.

The current production HTTP/2 server path is TLS + ALPN. Cleartext h2c is not
provided.

C<http2 =E<gt> 1> owns the TLS ALPN list and currently requires the default
connection class.

=head1 UPGRADE AND CONNECT

HTTP/1.1 protocol handoff belongs to Transaction.

Upgrade:

    $res->header('Upgrade', 'my-protocol');
    $conn->transaction->upgrade('MyProtocolConnection');

CONNECT:

    if ($req->method eq 'CONNECT') {
        $conn->transaction->tunnel('MyTunnelConnection');
    }

Both operations transition the same live Linux::Event stream after the HTTP
exchange reaches the correct boundary. Already-read post-HTTP bytes are
preserved.

These are HTTP/1 transport-handoff operations; they do not describe HTTP/2
stream-level tunnels.

=head1 MANAGED PRE-FORK

For plain HTTP, the underlying Listener can be intentionally shared with
L<Linux::Event> managed fork support:

    my $pid = $loop->fork(
        share => [ $server->listener ],
    );

Worker creation and supervision remain application policy. This documented
sharing pattern is for plain HTTP; do not assume the same recipe for TLS
Listeners without separate validation.

=head1 METHODS

=head2 listener

Returns the underlying L<Linux::Event::IO::Sock::Listener>.

=head2 loop

Returns the Loop.

=head2 connection_class

Returns the configured HTTP/1 connection class.

=head2 http2

True when HTTP/2 support was enabled for this Server.

=head2 http2_max_header_list_size

Returns the configured HTTP/2 decoded header-list limit.

=head2 data

Returns the Server application data.

=head2 fh, fd, host, port, path, family, family_number, is_tcp, is_unix, state

Delegate to the underlying Listener.

=head2 pause

Pauses acceptance and returns the Server.

=head2 resume

Resumes acceptance and returns the Server.

=head2 close

Closes the listening endpoint and returns the Server. Existing accepted
connections keep their own lifecycles.

=head1 SEE ALSO

L<Linux::Event::HTTP>, L<Linux::Event::HTTP::Client>,
L<Linux::Event::HTTP::Server::Connection>,
L<Linux::Event::HTTP::Transaction>, L<Linux::Event::HTTP::Request>,
L<Linux::Event::HTTP::Response>, L<Linux::Event::HTTP::Body::Stream>.

=cut
