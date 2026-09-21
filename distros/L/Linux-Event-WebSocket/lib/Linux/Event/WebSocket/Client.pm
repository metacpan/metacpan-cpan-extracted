package Linux::Event::WebSocket::Client;
use v5.36;
use strict;
use warnings;

use Carp qw(croak);
use Scalar::Util qw(blessed);
use URI ();

use Linux::Event::HTTP::Request;
use Linux::Event::WebSocket::Client::Connection;
use Linux::Event::WebSocket::Client::_HTTPConnection;
use Linux::Event::WebSocket::_Handshake;
use Linux::Event::WebSocket::_State;

our $VERSION = '0.001';

my $DEFAULT_MAX_MESSAGE_SIZE = 16 * 1024 * 1024;

sub _load_connection_class ($class) {
    croak 'new(): connection_class must be a package name'
        if !defined($class) || ref($class)
        || $class !~ /\A[A-Za-z_][A-Za-z0-9_]*(?:::[A-Za-z_][A-Za-z0-9_]*)*\z/;

    if (!$class->can('send_text')) {
        (my $file = "$class.pm") =~ s{::}{/}g;
        require $file;
    }

    croak 'new(): connection_class must inherit Linux::Event::WebSocket::Client::Connection'
        if !$class->isa('Linux::Event::WebSocket::Client::Connection');
    return $class;
}

sub _take_callback ($name, $option) {
    return undef if !exists $option->{$name};
    my $callback = delete $option->{$name};
    croak "new(): $name must be a coderef" if ref($callback) ne 'CODE';
    return $callback;
}

sub _subprotocols ($value) {
    croak 'new(): subprotocols must be an array reference'
        if ref($value) ne 'ARRAY';

    my @copy;
    for my $token (@$value) {
        croak 'new(): each subprotocol must be a WebSocket token'
            if !defined($token) || ref($token)
            || $token !~ /\A[!#\$%&'*+\-.^_`|~0-9A-Za-z]+\z/;
        push @copy, "$token";
    }
    return \@copy;
}

sub _headers ($value) {
    croak 'new(): headers must be an array reference'
        if ref($value) ne 'ARRAY';

    my %reserved = map { $_ => 1 } qw(
        host connection upgrade sec-websocket-key sec-websocket-version
        sec-websocket-protocol sec-websocket-extensions
    );
    my @copy;
    for my $pair (@$value) {
        croak 'new(): each header must be a [name, value] pair'
            if ref($pair) ne 'ARRAY' || @$pair != 2;
        my ($name, $header_value) = @$pair;
        croak 'new(): header name and value must be scalars'
            if !defined($name) || ref($name)
            || !defined($header_value) || ref($header_value);
        croak "new(): WebSocket handshake owns header $name"
            if $reserved{lc $name};
        push @copy, [ "$name", "$header_value" ];
    }
    return \@copy;
}

sub _nonnegative_number ($where, $value) {
    croak "$where must be a non-negative number"
        if !defined($value) || ref($value)
        || "$value" !~ /\A(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)\z/;
    return 0 + $value;
}

sub _positive_integer ($where, $value) {
    croak "$where must be a positive integer"
        if !defined($value) || ref($value)
        || "$value" !~ /\A[0-9]+\z/ || $value < 1;
    return 0 + $value;
}

sub new ($class, %option) {
    my $loop = delete $option{loop}
        // croak 'new(): loop is required';
    croak 'new(): loop must implement add() and watch_fd()'
        if !blessed($loop) || !$loop->can('add') || !$loop->can('watch_fd');

    my $connection_class = _load_connection_class(
        delete($option{connection_class})
            // 'Linux::Event::WebSocket::Client::Connection',
    );

    my %callbacks;
    for my $name (qw(on_open on_message on_close on_error on_drain)) {
        my $callback = _take_callback($name, \%option);
        (my $short = $name) =~ s/\Aon_//;
        $callbacks{$short} = $callback if $callback;
    }

    my $subprotocols = _subprotocols(
        exists($option{subprotocols}) ? delete($option{subprotocols}) : [],
    );
    my $headers = _headers(
        exists($option{headers}) ? delete($option{headers}) : [],
    );
    my $origin = delete $option{origin};
    croak 'new(): origin must be a scalar'
        if defined($origin) && ref($origin);

    my $tls = exists($option{tls}) ? delete($option{tls}) : {};
    croak 'new(): tls must be a hash reference' if ref($tls) ne 'HASH';

    my $connect_timeout = delete $option{connect_timeout};
    $connect_timeout = _nonnegative_number(
        'new(): connect_timeout', $connect_timeout,
    ) if defined $connect_timeout;

    my $close_timeout = _nonnegative_number(
        'new(): close_timeout',
        exists($option{close_timeout}) ? delete($option{close_timeout}) : 5,
    );
    my $max_message_size = _positive_integer(
        'new(): max_message_size',
        exists($option{max_message_size})
            ? delete($option{max_message_size})
            : $DEFAULT_MAX_MESSAGE_SIZE,
    );
    my $data = delete $option{data};

    croak 'new(): unknown option(s): ' . join(', ', sort keys %option)
        if %option;

    return bless {
        loop             => $loop,
        connection_class => $connection_class,
        callbacks        => \%callbacks,
        subprotocols     => $subprotocols,
        headers          => $headers,
        origin           => defined($origin) ? "$origin" : undef,
        tls              => { %$tls },
        connect_timeout  => $connect_timeout,
        close_timeout    => $close_timeout,
        max_message_size => $max_message_size,
        data             => $data,
        connection       => undef,
        url              => undef,
    }, $class;
}

sub _destination ($url) {
    croak 'connect(): URL must be a non-empty scalar'
        if !defined($url) || ref($url) || $url eq '';

    my ($scheme) = "$url" =~ /\A([A-Za-z][A-Za-z0-9+.-]*):/;
    $scheme = lc($scheme // '');
    croak 'connect(): URL scheme must be ws or wss'
        if $scheme ne 'ws' && $scheme ne 'wss';

    my $http_url = "$url";
    my $http_scheme = $scheme eq 'wss' ? 'https' : 'http';
    $http_url =~ s/\A[A-Za-z][A-Za-z0-9+.-]*:/$http_scheme:/;
    my $uri = URI->new($http_url);

    my $host = $uri->host;
    croak 'connect(): URL must contain a host'
        if !defined($host) || $host eq '';
    croak 'connect(): URL userinfo is not supported'
        if defined($uri->userinfo) && length($uri->userinfo);

    my $port = $uri->port;
    croak 'connect(): URL port must be between 1 and 65535'
        if !defined($port) || $port !~ /\A[0-9]+\z/
        || $port < 1 || $port > 65_535;

    my $default_port = $scheme eq 'wss' ? 443 : 80;
    my $authority_host = $host =~ /:/ ? "[$host]" : $host;
    my $host_header = $authority_host;
    $host_header .= ":$port" if $port != $default_port;

    return {
        scheme      => $scheme,
        secure      => $scheme eq 'wss' ? 1 : 0,
        host        => $host,
        port        => 0 + $port,
        host_header => $host_header,
    };
}

sub _report_error ($state, $connection, $error) {
    my $message = "$error";
    $message =~ s/\s+\z//;
    if (my $callback = $state->{callbacks}{error}) {
        $callback->($connection, $message);
    }
    return;
}

sub connect ($self, $url) {
    croak 'connect(): Client already has an active connection'
        if $self->{connection} && !$self->{connection}->is_closed;

    my $destination = _destination($url);
    my ($handshake, $request) = Linux::Event::WebSocket::_Handshake->client_request(
        $url,
        origin       => $self->{origin},
        subprotocols => $self->{subprotocols},
        headers      => $self->{headers},
        host_header  => $destination->{host_header},
    );

    my $state = Linux::Event::WebSocket::_State->new(
        endpoint_type    => 'client',
        callbacks        => $self->{callbacks},
        subprotocols     => $self->{subprotocols},
        data             => $self->{data},
        handshake        => $handshake,
        request          => $request,
        secure           => $destination->{secure},
        url              => "$url",
        close_timeout    => $self->{close_timeout},
        max_message_size => $self->{max_message_size},
    );

    my %connect = (
        loop => $self->{loop},
        host => $destination->{host},
        port => $destination->{port},
        data => $state,
    );
    $connect{timeout} = $self->{connect_timeout}
        if defined $self->{connect_timeout};

    if ($destination->{secure}) {
        require Linux::Event::TLS;
        $connect{transport} = Linux::Event::TLS->client(
            server_name => $destination->{host},
            alpn        => ['http/1.1'],
            %{$self->{tls}},
        );
    }

    my $connection = Linux::Event::WebSocket::Client::_HTTPConnection->connect(
        %connect,
    );
    $self->{connection} = $connection;
    $self->{url} = "$url";

    $connection->request(
        $request,
        upgrade_to => $self->{connection_class},

        on_response => sub ($transaction, $response) {
            $state->{response} = $response;
            my $ok = eval {
                Linux::Event::WebSocket::_Handshake->validate_client_response(
                    $handshake,
                    $response,
                );
                1;
            };
            if (!$ok) {
                my $error = $@;
                $transaction->cancel;
                _report_error($state, $connection, $error);
            }
        },

        on_upgrade => sub ($transaction, $response, $upgraded) {
            $state->{response} = $response;
            $upgraded->_ensure_websocket_open;
        },

        on_error => sub ($transaction, $error) {
            _report_error($state, $connection, $error);
        },
    );

    return $connection;
}

sub loop             ($self) { $self->{loop} }
sub data             ($self) { $self->{data} }
sub connection_class ($self) { $self->{connection_class} }
sub connection       ($self) { $self->{connection} }
sub url              ($self) { $self->{url} }
sub is_open          ($self) {
    my $connection = $self->{connection} or return 0;
    return 0 if !$connection->isa('Linux::Event::WebSocket::Connection');
    return $connection->is_open;
}

sub send_text ($self, @argument) {
    my $connection = $self->{connection}
        or croak 'send_text(): Client is not connected';
    croak 'send_text(): WebSocket handshake is not complete'
        if !$connection->isa('Linux::Event::WebSocket::Connection');
    return $connection->send_text(@argument);
}

sub send_binary ($self, @argument) {
    my $connection = $self->{connection}
        or croak 'send_binary(): Client is not connected';
    croak 'send_binary(): WebSocket handshake is not complete'
        if !$connection->isa('Linux::Event::WebSocket::Connection');
    return $connection->send_binary(@argument);
}

sub ping ($self, @argument) {
    my $connection = $self->{connection}
        or croak 'ping(): Client is not connected';
    croak 'ping(): WebSocket handshake is not complete'
        if !$connection->isa('Linux::Event::WebSocket::Connection');
    return $connection->ping(@argument);
}

sub close ($self, %option) {
    my $connection = $self->{connection} or return $self;
    if ($connection->isa('Linux::Event::WebSocket::Connection')) {
        $connection->close(%option);
    } elsif (!$connection->is_closed) {
        $connection->close;
    }
    return $self;
}

1;

__END__

=head1 NAME

Linux::Event::WebSocket::Client - callback-first WebSocket client

=head1 SYNOPSIS

    use v5.36;
    use Linux::Event::Loop;
    use Linux::Event::WebSocket::Client;

    my $loop = Linux::Event::Loop->new;

    my $client = Linux::Event::WebSocket::Client->new(
        loop => $loop,
        on_open => sub ($ws) {
            $ws->send_text('hello');
        },
        on_message => sub ($ws, $payload, $type) {
            say $payload if $type eq 'text';
        },
        on_close => sub ($ws, $code, $reason) {
            $loop->stop;
        },
    );

    $client->connect('wss://example.com/socket');
    $loop->run;

=head1 DESCRIPTION

The Client uses Linux::Event::HTTP only for the opening HTTP/1.1 Upgrade. The
same live connection object is then transitioned in place to
L<Linux::Event::WebSocket::Client::Connection>. The private handshake engine
validates WebSocket-specific response fields, including
C<Sec-WebSocket-Accept>.

C<connect> returns the live connection reference immediately. During the
opening handshake its class is private HTTP machinery; after a successful
Upgrade the same reference is reblessed to the configured WebSocket connection
class. Application WebSocket work should begin in C<on_open>.

C<ws://> and C<wss://> are supported. C<wss://> uses Linux::Event TLS and keeps
that transport attached across the HTTP-to-WebSocket transition.

=head1 METHODS

=head2 connect(URL)

Starts one WebSocket connection and returns the live connection reference.

=head2 connection

Returns the current live connection reference.

=head2 send_text, send_binary, ping

Convenience methods that delegate to the established connection. They reject
calls made before the WebSocket handshake completes.

=head2 close

Starts a graceful WebSocket close after the handshake. Before the handshake
completes it closes the pending transport.

=head1 LIMITS

C<max_message_size> defaults to 16 MiB and may be set to another positive byte
limit. The same bound also protects the frame reader from allocating an
unreasonably large single frame.

=head1 SUBPROTOCOLS AND HEADERS

C<subprotocols> is an array reference of protocols offered during the
handshake. C<origin> sets the Origin field. C<headers> may contain additional
HTTP fields, but fields owned by the WebSocket handshake cannot be overridden.

=head1 CONNECTION SUBCLASSES

C<connection_class> may name a subclass of
L<Linux::Event::WebSocket::Client::Connection>. The hierarchy remains ordinary
single inheritance.

=cut
