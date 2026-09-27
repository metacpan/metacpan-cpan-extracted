package Linux::Event::HTTP::_HTTP2;
use v5.36;
use strict;
use warnings;

use Scalar::Util qw(blessed);

use Linux::Event::HTTP::Request;
use Linux::Event::HTTP::Response;
use Linux::Event::HTTP::Transaction;

our $VERSION = '0.003';

my %FORBIDDEN = map { $_ => 1 } qw(
    connection
    keep-alive
    proxy-connection
    transfer-encoding
    upgrade
);

sub _pairs ($operation, $pairs) {
    die "$operation: header block must be an array reference"
        if ref($pairs) ne 'ARRAY';
    for my $pair (@$pairs) {
        die "$operation: each field must be a [name, value] pair"
            if ref($pair) ne 'ARRAY' || @$pair != 2;
        die "$operation: field name and value must be defined scalars"
            if !defined($pair->[0]) || ref($pair->[0])
            || !defined($pair->[1]) || ref($pair->[1]);
    }
    return $pairs;
}

sub _normal_field ($operation, $name, $value) {
    die "$operation: HTTP/2 field names must be lowercase"
        if $name ne lc $name;

    if ($FORBIDDEN{$name}) {
        die "$operation: HTTP/2 forbids connection-specific field '$name'";
    }

    if ($name eq 'te' && lc($value) ne 'trailers') {
        die "$operation: HTTP/2 TE is limited to trailers";
    }

    return [ $name, $value ];
}

sub _split_header_block ($operation, $pairs, $allowed) {
    _pairs($operation, $pairs);

    my %pseudo;
    my @normal;
    my $saw_normal = 0;

    for my $pair (@$pairs) {
        my ($name, $value) = @$pair;
        if (substr($name, 0, 1) eq ':') {
            die "$operation: pseudo-header follows a regular field"
                if $saw_normal;
            die "$operation: unsupported pseudo-header '$name'"
                if !$allowed->{$name};
            die "$operation: duplicate pseudo-header '$name'"
                if exists $pseudo{$name};
            $pseudo{$name} = $value;
            next;
        }

        $saw_normal = 1;
        push @normal, _normal_field($operation, $name, $value);
    }

    return (\%pseudo, \@normal);
}

sub request_from_headers ($class, $pairs, %option) {
    my $end_stream = delete($option{end_stream}) // 0;
    die 'request_from_headers(): unknown options: '
        . join(', ', sort keys %option)
        if %option;

    my ($pseudo, $normal) = _split_header_block(
        'request_from_headers()',
        $pairs,
        {
            ':method'    => 1,
            ':scheme'    => 1,
            ':authority' => 1,
            ':path'      => 1,
        },
    );

    my $method = $pseudo->{':method'};
    die 'request_from_headers(): missing :method'
        if !defined($method) || $method eq '';

    my ($target, $scheme, $authority);
    if (uc($method) eq 'CONNECT') {
        die 'request_from_headers(): CONNECT requires :authority'
            if !defined($pseudo->{':authority'})
            || $pseudo->{':authority'} eq '';
        die 'request_from_headers(): ordinary CONNECT must omit :scheme and :path'
            if exists($pseudo->{':scheme'}) || exists($pseudo->{':path'});

        $authority = $pseudo->{':authority'};
        $target = $authority;
    } else {
        die 'request_from_headers(): missing :scheme'
            if !defined($pseudo->{':scheme'})
            || $pseudo->{':scheme'} eq '';
        die 'request_from_headers(): missing :path'
            if !defined($pseudo->{':path'})
            || $pseudo->{':path'} eq '';
        die 'request_from_headers(): missing :authority'
            if !defined($pseudo->{':authority'})
            || $pseudo->{':authority'} eq '';

        $scheme = $pseudo->{':scheme'};
        $authority = $pseudo->{':authority'};
        $target = $pseudo->{':path'};
    }

    my $request = Linux::Event::HTTP::Request->new(
        method    => $method,
        target    => $target,
        version   => '2',
        (defined($scheme) ? (scheme => $scheme) : ()),
        authority => $authority,
        headers   => $normal,
    );
    $request->_mark_incomplete if !$end_stream;
    $request->_mark_committed;
    return $request;
}

sub response_from_headers ($class, $pairs, %option) {
    my $end_stream = delete($option{end_stream}) // 0;
    die 'response_from_headers(): unknown options: '
        . join(', ', sort keys %option)
        if %option;

    my ($pseudo, $normal) = _split_header_block(
        'response_from_headers()',
        $pairs,
        { ':status' => 1 },
    );

    my $status = $pseudo->{':status'};
    die 'response_from_headers(): missing :status'
        if !defined($status) || $status eq '';

    my $response = Linux::Event::HTTP::Response->new(
        status  => $status,
        version => '2',
        headers => $normal,
    );
    $response->_commit;
    $end_stream ? $response->_mark_complete : $response->_mark_incomplete;
    return $response;
}

sub _outbound_normal_fields ($operation, $message) {
    my @fields;
    for my $index (0 .. $message->header_count - 1) {
        my $name = lc $message->header_name($index);
        my $value = $message->header_value($index);
        push @fields, _normal_field($operation, $name, $value);
    }
    return @fields;
}

sub request_headers ($class, $request) {
    die 'request_headers(): requires a Linux::Event::HTTP::Request'
        if !blessed($request)
        || !$request->isa('Linux::Event::HTTP::Request');
    die 'request_headers(): Request version must be 2'
        if ($request->version // '') ne '2';

    my @block = ([ ':method', $request->method ]);

    if (uc($request->method) eq 'CONNECT') {
        my $authority = $request->authority;
        die 'request_headers(): CONNECT requires authority'
            if !defined($authority) || $authority eq '';
        push @block, [ ':authority', $authority ];
    } else {
        my $scheme = $request->scheme;
        my $authority = $request->authority;
        die 'request_headers(): HTTP/2 Request requires scheme'
            if !defined($scheme) || $scheme eq '';
        die 'request_headers(): HTTP/2 Request requires authority'
            if !defined($authority) || $authority eq '';
        push @block,
            [ ':scheme', $scheme ],
            [ ':authority', $authority ],
            [ ':path', $request->target ];
    }

    push @block, _outbound_normal_fields('request_headers()', $request);
    return \@block;
}

sub response_headers ($class, $response) {
    die 'response_headers(): requires a Linux::Event::HTTP::Response'
        if !blessed($response)
        || !$response->isa('Linux::Event::HTTP::Response');
    die 'response_headers(): Response version must be 2'
        if ($response->version // '') ne '2';

    my @block = ([ ':status', '' . $response->status ]);
    push @block, _outbound_normal_fields('response_headers()', $response);
    return \@block;
}

sub server_transaction_from_headers ($class, $pairs, $controller, %option) {
    die 'server_transaction_from_headers(): controller must be an object'
        if !blessed($controller);

    my $request = $class->request_from_headers($pairs, %option);
    my $response = Linux::Event::HTTP::Response->new(
        status  => 200,
        version => '2',
    );

    my $transaction = Linux::Event::HTTP::Transaction->_new(
        request    => $request,
        controller => $controller,
    );
    $transaction->_activate;
    $transaction->_set_response($response);

    return $transaction;
}

1;

__END__

=head1 NAME

Linux::Event::HTTP::_HTTP2 - private HTTP/2 message mapping helpers

=head1 DESCRIPTION

This is a private implementation boundary between an HTTP/2 protocol engine and
the public Linux::Event::HTTP message/Transaction model.

HTTP/2 pseudo-headers are consumed here and never exposed through the ordinary
Request or Response header list.

The nghttp2 integration owns frame, HPACK, stream, SETTINGS, GOAWAY, and
flow-control mechanics. This module owns translation between that wire model and
Linux::Event::HTTP Request, Response, and Transaction objects.

=cut
