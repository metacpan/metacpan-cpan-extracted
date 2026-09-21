package Linux::Event::WebSocket::_Handshake;
use v5.36;
use strict;
use warnings;

use Carp qw(croak);
use Digest::SHA qw(sha1);
use MIME::Base64 qw(decode_base64 encode_base64);
use URI ();

use Linux::Event::HTTP::Request;
use Linux::Event::WebSocket::_Random;

my $GUID = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11';
my $TOKEN_RE = qr/\A[!#\$%&'*+\-.^_`|~0-9A-Za-z]+\z/;

sub _trim ($value) {
    $value =~ s/\A[ \t]+//;
    $value =~ s/[ \t]+\z//;
    return $value;
}

sub _header_values ($message, $wanted) {
    my @value;
    for my $index (0 .. $message->header_count - 1) {
        my $name = $message->header_name($index);
        push @value, $message->header_value($index)
            if lc($name) eq lc($wanted);
    }
    return @value;
}

sub _tokens ($where, @value) {
    my @token;
    for my $value (@value) {
        for my $token (split /,/, $value, -1) {
            $token = _trim($token);
            croak "$where contains an empty token" if $token eq '';
            croak "$where contains an invalid token '$token'"
                if $token !~ $TOKEN_RE;
            push @token, $token;
        }
    }
    return @token;
}

sub _has_token ($message, $name, $wanted) {
    for my $token (_tokens($name, _header_values($message, $name))) {
        return 1 if lc($token) eq lc($wanted);
    }
    return 0;
}

sub _singleton ($message, $name) {
    my @value = _header_values($message, $name);
    croak "WebSocket handshake requires $name" if !@value;
    croak "WebSocket handshake contains duplicate $name" if @value > 1;
    return _trim($value[0]);
}

sub _valid_key ($key) {
    return 0 if $key !~ /\A[A-Za-z0-9+\/]{22}==\z/;
    return length(decode_base64($key)) == 16;
}

sub _accept ($key) {
    return encode_base64(sha1($key . $GUID), '');
}

sub _checked_subprotocols ($where, $subprotocols) {
    croak "$where: subprotocols must be an array reference"
        if ref($subprotocols) ne 'ARRAY';

    my %seen;
    my @copy;
    for my $token (@$subprotocols) {
        croak "$where: each subprotocol must be a WebSocket token"
            if !defined($token) || ref($token) || $token !~ $TOKEN_RE;
        croak "$where: duplicate subprotocol '$token'"
            if $seen{$token}++;
        push @copy, "$token";
    }
    return \@copy;
}

sub server_from_request ($class, $request, %option) {
    croak 'server_from_request(): request object is required'
        if !defined($request) || !ref($request);

    my $supported = _checked_subprotocols(
        'server_from_request()',
        delete($option{subprotocols}) // [],
    );
    croak 'server_from_request(): unknown option(s): '
        . join(', ', sort keys %option)
        if %option;

    croak 'WebSocket handshake method must be GET'
        if $request->method ne 'GET';
    croak 'WebSocket handshake requires HTTP/1.1'
        if !defined($request->version) || $request->version ne '1.1';
    croak 'WebSocket handshake Upgrade header must contain websocket'
        if !_has_token($request, 'Upgrade', 'websocket');
    croak 'WebSocket handshake Connection header must contain Upgrade'
        if !_has_token($request, 'Connection', 'Upgrade');

    my $version = _singleton($request, 'Sec-WebSocket-Version');
    croak 'WebSocket handshake Sec-WebSocket-Version must be 13'
        if $version ne '13';

    my $key = _singleton($request, 'Sec-WebSocket-Key');
    croak 'WebSocket handshake contains invalid Sec-WebSocket-Key'
        if !_valid_key($key);

    my @offered = _tokens(
        'Sec-WebSocket-Protocol',
        _header_values($request, 'Sec-WebSocket-Protocol'),
    );
    my %offered_seen;
    for my $token (@offered) {
        croak "WebSocket handshake contains duplicate subprotocol '$token'"
            if $offered_seen{$token}++;
    }

    my %supported = map { $_ => 1 } @$supported;
    my ($selected) = grep { $supported{$_} } @offered;

    return bless {
        endpoint_type        => 'server',
        key                  => $key,
        offered_subprotocols => \@offered,
        selected_subprotocol => $selected,
    }, $class;
}

sub apply_server_response ($class, $handshake, $response) {
    croak 'apply_server_response(): handshake object is required'
        if !defined($handshake) || !ref($handshake)
        || !$handshake->isa($class) || $handshake->{endpoint_type} ne 'server';
    croak 'apply_server_response(): response object is required'
        if !defined($response) || !ref($response);

    $response->status(101);
    $response->reason('Switching Protocols');
    $response->header(Upgrade => 'websocket');
    $response->header(Connection => 'Upgrade');
    $response->header('Sec-WebSocket-Accept' => _accept($handshake->{key}));
    if (defined $handshake->{selected_subprotocol}) {
        $response->header(
            'Sec-WebSocket-Protocol' => $handshake->{selected_subprotocol},
        );
    }
    return $response;
}

sub client_request ($class, $url, %option) {
    croak 'client_request(): URL must be a non-empty scalar'
        if !defined($url) || ref($url) || $url eq '';

    my $origin = delete $option{origin};
    croak 'client_request(): origin must be a scalar'
        if defined($origin) && ref($origin);

    my $subprotocols = _checked_subprotocols(
        'client_request()',
        delete($option{subprotocols}) // [],
    );

    my $headers = delete($option{headers}) // [];
    croak 'client_request(): headers must be an array reference'
        if ref($headers) ne 'ARRAY';

    my $host_header = delete $option{host_header};
    croak 'client_request(): host_header must be a scalar'
        if defined($host_header) && ref($host_header);

    my $key = delete $option{key};
    $key = encode_base64(
        Linux::Event::WebSocket::_Random->bytes(16),
        '',
    ) if !defined $key;
    croak 'client_request(): key must be a valid base64-encoded 16-byte value'
        if ref($key) || !_valid_key($key);

    croak 'client_request(): unknown option(s): '
        . join(', ', sort keys %option)
        if %option;

    my @extra;
    for my $pair (@$headers) {
        croak 'client_request(): each header must be a [name, value] pair'
            if ref($pair) ne 'ARRAY' || @$pair != 2;
        my ($name, $value) = @$pair;
        croak 'client_request(): header name and value must be scalars'
            if !defined($name) || ref($name) || !defined($value) || ref($value);
        push @extra, [ "$name", "$value" ];
    }

    my $uri = URI->new("$url");
    my $target = $uri->path;
    $target = '/' if !defined($target) || $target eq '';
    my $query = $uri->query;
    $target .= "?$query" if defined($query) && length($query);

    if (!defined $host_header) {
        $host_header = $uri->authority;
        croak 'client_request(): URL must contain an authority'
            if !defined($host_header) || $host_header eq '';
    }

    my @http_headers = (
        [ Host                    => "$host_header" ],
        [ Upgrade                 => 'websocket' ],
        [ Connection              => 'Upgrade' ],
        [ 'Sec-WebSocket-Key'     => "$key" ],
        [ 'Sec-WebSocket-Version' => '13' ],
    );
    push @http_headers,
        [ 'Sec-WebSocket-Protocol' => join(', ', @$subprotocols) ]
        if @$subprotocols;
    push @http_headers, [ Origin => "$origin" ] if defined $origin;
    push @http_headers, @extra;

    my $request = Linux::Event::HTTP::Request->new(
        method  => 'GET',
        target  => $target,
        version => '1.1',
        headers => \@http_headers,
    );

    my $handshake = bless {
        endpoint_type        => 'client',
        key                  => "$key",
        offered_subprotocols => [ @$subprotocols ],
        selected_subprotocol => undef,
    }, $class;

    return ($handshake, $request);
}

sub validate_client_response ($class, $handshake, $response) {
    croak 'validate_client_response(): handshake object is required'
        if !defined($handshake) || !ref($handshake)
        || !$handshake->isa($class) || $handshake->{endpoint_type} ne 'client';
    croak 'validate_client_response(): response object is required'
        if !defined($response) || !ref($response);

    croak 'WebSocket handshake response status must be 101'
        if $response->status != 101;
    croak 'WebSocket handshake response Upgrade header must contain websocket'
        if !_has_token($response, 'Upgrade', 'websocket');
    croak 'WebSocket handshake response Connection header must contain Upgrade'
        if !_has_token($response, 'Connection', 'Upgrade');

    my $accept = _singleton($response, 'Sec-WebSocket-Accept');
    croak 'WebSocket handshake response has invalid Sec-WebSocket-Accept'
        if $accept ne _accept($handshake->{key});

    croak 'WebSocket handshake response selected an unsupported extension'
        if _header_values($response, 'Sec-WebSocket-Extensions');

    my @protocol = _header_values($response, 'Sec-WebSocket-Protocol');
    croak 'WebSocket handshake response contains duplicate Sec-WebSocket-Protocol'
        if @protocol > 1;
    if (@protocol) {
        my @token = _tokens('Sec-WebSocket-Protocol', $protocol[0]);
        croak 'WebSocket handshake response must select one subprotocol'
            if @token != 1;
        my %offered = map { $_ => 1 } @{$handshake->{offered_subprotocols}};
        croak "WebSocket handshake response selected unknown subprotocol '$token[0]'"
            if !$offered{$token[0]};
        $handshake->{selected_subprotocol} = $token[0];
    }

    return $handshake;
}

sub subprotocol ($class, $handshake) {
    return $handshake->{selected_subprotocol};
}

1;
