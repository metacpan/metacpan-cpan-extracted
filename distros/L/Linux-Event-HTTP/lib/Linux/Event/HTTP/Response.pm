package Linux::Event::HTTP::Response;
use v5.36;
use strict;
use warnings;

use Scalar::Util qw(refaddr);
use utf8 ();

use Linux::Event::HTTP::_HTTP1 ();

our $VERSION = '0.003';

my $EMPTY_HEADERS = [];

sub _byte_string ($operation, $value) {
    die "$operation(): value must be a defined scalar byte string"
        if !defined($value) || ref($value);
    my $bytes = "$value";
    if (utf8::is_utf8($bytes)) {
        die "$operation(): value contains wide characters; encode it to bytes first"
            if !utf8::downgrade($bytes, 1);
    }
    return $bytes;
}

sub new ($class, %args) {
    my $status  = delete($args{status}) // 200;
    my $reason  = delete $args{reason};
    my $version = delete($args{version}) // '1.1';
    my $headers = delete $args{headers};
    my $has_body = exists $args{body};
    my $body = delete $args{body};

    die 'unknown response option: ' . join(', ', sort keys %args)
        if %args;

    _validate_status($status);
    $reason = _validate_reason($reason) if defined $reason;
    $version = _validate_version($version);

    my $self = bless {
        status    => 0 + $status,
        reason    => $reason,
        version   => $version,
        headers   => $EMPTY_HEADERS,
        committed => 0,
        complete  => 0,
        body_kind => undef,
        body      => undef,
    }, $class;

    if (defined $headers) {
        die 'headers must be an array reference of [name, value] pairs'
            if ref($headers) ne 'ARRAY';

        for my $pair (@$headers) {
            die 'each response header must be a [name, value] pair'
                if ref($pair) ne 'ARRAY' || @$pair != 2;
            $self->add_header($pair->[0], $pair->[1]);
        }
    }

    $self->body($body) if $has_body;
    return $self;
}

sub _new ($class, %args) {
    return $class->new(%args);
}

sub is_complete ($self) { !!$self->{complete} }
sub is_mutable ($self) { $self->{committed} ? 0 : 1 }
sub headers_are_lossless ($self) { 1 }
sub has_buffered_body ($self) { ($self->{body_kind} // '') eq 'scalar' ? 1 : 0 }

sub _assert_mutable ($self) {
    die 'response metadata cannot change after message commit'
        if $self->{committed};
    return;
}

sub status ($self, @args) {
    if (!@args) {
        return $self->{status} if exists $self->{status};
        return 200 if $self->{_server_flags};
        return undef;
    }

    die 'status accepts exactly one value' if @args != 1;
    $self->_assert_mutable;
    _validate_status($args[0]);
    $self->{status} = 0 + $args[0];
    $self->{_server_flags} &= ~1 if exists $self->{_server_flags};
    return $self;
}

sub reason ($self, @args) {
    return $self->{reason} if !@args;

    die 'reason accepts exactly one value' if @args != 1;
    $self->_assert_mutable;
    $self->{reason} = defined($args[0]) ? _validate_reason($args[0]) : undef;
    $self->{_server_flags} &= ~1 if exists $self->{_server_flags};
    return $self;
}

sub version ($self, @args) {
    if (!@args) {
        return $self->{version} if exists $self->{version};
        my $flags = $self->{_server_flags} // 0;
        return ($flags & 4) ? '1.0' : '1.1' if $flags;
        return undef;
    }

    die 'version accepts exactly one value' if @args != 1;
    $self->_assert_mutable;
    if (!defined $args[0]) {
        $self->{version} = undef;
        $self->{_server_flags} &= ~1 if exists $self->{_server_flags};
        return $self;
    }
    $self->{version} = _validate_version($args[0]);
    $self->{_server_flags} &= ~1 if exists $self->{_server_flags};
    return $self;
}

sub header ($self, $name, @args) {
    if (!@args) {
        $name = _validate_name($name);
        my $wanted = lc $name;
        my $headers = $self->{headers} // $EMPTY_HEADERS;
        for my $pair (@$headers) {
            return $pair->[1] if lc($pair->[0]) eq $wanted;
        }
        return undef;
    }

    die 'header setter accepts exactly one value' if @args != 1;
    Linux::Event::HTTP::Response::_set_header_native(
        $self, $name, $args[0],
    );
    return $self;
}

sub add_header ($self, $name, $value) {
    $self->_assert_mutable;
    $name = _validate_name($name);
    $value = _validate_value($value);
    my $headers = $self->{headers};
    if (!defined($headers) || refaddr($headers) == refaddr($EMPTY_HEADERS)) {
        $headers = $self->{headers} = [];
    }
    push @$headers, [ $name, $value ];
    $self->{_server_flags} &= ~3 if exists $self->{_server_flags};
    return $self;
}

sub remove_header ($self, $name) {
    $self->_assert_mutable;
    $name = _validate_name($name);
    my $wanted = lc $name;
    my $headers = $self->{headers} // $EMPTY_HEADERS;
    my @kept = grep { lc($_->[0]) ne $wanted } @$headers;
    $self->{headers} = \@kept;
    $self->{_server_flags} &= ~3 if exists $self->{_server_flags};
    return $self;
}

sub _header_values_list ($self, $name) {
    $name = _validate_name($name);
    my $wanted = lc $name;
    my $headers = $self->{headers} // $EMPTY_HEADERS;
    return map { $_->[1] }
        grep { lc($_->[0]) eq $wanted }
        @$headers;
}

sub header_values ($self, $name) {
    return [ $self->_header_values_list($name) ];
}

sub header_count ($self) {
    my $headers = $self->{headers} // $EMPTY_HEADERS;
    return scalar @$headers;
}

sub _validate_header_index ($index) {
    die 'header index must be a non-negative integer'
        if !defined($index) || ref($index) || "$index" !~ /\A[0-9]+\z/;
    return 0 + $index;
}

sub header_name ($self, $index) {
    $index = _validate_header_index($index);
    my $headers = $self->{headers} // $EMPTY_HEADERS;
    return undef if $index >= @$headers;
    return $headers->[$index][0];
}

sub header_value ($self, $index) {
    $index = _validate_header_index($index);
    my $headers = $self->{headers} // $EMPTY_HEADERS;
    return undef if $index >= @$headers;
    return $headers->[$index][1];
}

sub content_length ($self) {
    my @values = $self->_header_values_list('Content-Length');
    return undef if !@values;
    die 'response must not contain multiple Content-Length fields' if @values != 1;
    die 'response Content-Length must be a decimal number'
        if $values[0] !~ /\A[0-9]+\z/;
    return 0 + $values[0];
}

sub _body_bytes ($operation, $body) {
    die "$operation(): body must be a defined scalar byte string"
        if !defined($body) || ref($body);

    my $bytes = "$body";
    if (utf8::is_utf8($bytes)) {
        die "$operation(): body contains wide characters; encode it to bytes first"
            if !utf8::downgrade($bytes, 1);
    }
    return $bytes;
}

sub body ($self, @args) {
    return $self->{body} if !@args;

    die 'body accepts exactly one value' if @args != 1;
    Linux::Event::HTTP::Response::_set_body_native(
        $self, $args[0],
    );
    return $self;
}

sub _set_received_body ($self, $body) {
    die 'received response body can only be attached after message commit'
        if !$self->{committed};
    die 'received response body has already been attached'
        if defined $self->{body_kind};

    $self->{body_kind} = 'scalar';
    $self->{body} = _body_bytes('received body', $body);
    return $self;
}

sub _begin_stream_body ($self) {
    $self->_assert_mutable;
    die 'response_body(): Response already has a complete scalar body'
        if ($self->{body_kind} // '') eq 'scalar';
    die 'response_body(): Response already has an incremental body producer'
        if ($self->{body_kind} // '') eq 'stream';

    $self->{body_kind} = 'stream';
    $self->{complete} = 0;
    $self->{_server_flags} &= ~3 if exists $self->{_server_flags};
    return $self;
}

sub _has_scalar_body ($self) {
    return $self->has_buffered_body;
}

sub _has_incremental_body ($self) {
    return ($self->{body_kind} // '') eq 'stream';
}

sub _scalar_body ($self) {
    return $self->{body};
}

sub _commit ($self) {
    $self->{committed} = 1;
    return $self;
}

sub _is_committed ($self) {
    return !!$self->{committed};
}

sub _mark_complete ($self) {
    $self->{complete} = 1;
    return;
}

sub _mark_incomplete ($self) {
    $self->{complete} = 0;
    return;
}

sub _validate_status ($status) {
    die 'response status must be an integer between 100 and 599'
        if !defined($status) || ref($status) || "$status" !~ /\A[0-9]{3}\z/
        || $status < 100 || $status > 599;
}

sub _validate_reason ($reason) {
    my $bytes = _byte_string('reason', $reason);
    die 'response reason phrase contains invalid control characters'
        if $bytes =~ /[\x00-\x08\x0a-\x1f\x7f]/;
    return $bytes;
}

sub _validate_version ($version) {
    my $bytes = _byte_string('version', $version);
    die 'invalid HTTP version' if $bytes !~ /\A[0-9]+(?:\.[0-9]+)?\z/;
    return $bytes;
}

sub _validate_name ($name) {
    my $bytes = _byte_string('response header field name', $name);
    die 'response header field name is required' if $bytes eq '';
    die 'invalid response header field name'
        if $bytes !~ /\A[!#\$%&'*+\-.^_`|~0-9A-Za-z]+\z/;
    return $bytes;
}

sub _validate_value ($value) {
    my $bytes = _byte_string('response header field value', $value);
    die 'response header field value contains invalid control characters'
        if $bytes =~ /[\x00-\x08\x0a-\x1f\x7f]/;
    return $bytes;
}

1;

__END__

=head1 NAME

Linux::Event::HTTP::Response - HTTP response message

=head1 SYNOPSIS

    my $res = Linux::Event::HTTP::Response->new(
        status => 200,
        headers => [
            [ 'Content-Type', 'text/plain' ],
        ],
        body => "hello\n",
    );

Server callbacks receive the same class:

    on_request => sub ($conn, $req, $res) {
        $res->status(200);
        $res->body("hello\n");
    };

=head1 DESCRIPTION

C<Linux::Event::HTTP::Response> represents one HTTP response message.

The same class is used for HTTP/1 and HTTP/2, and for both locally constructed
outgoing responses and received client responses.

A Response contains message data only. It is not a socket, Transaction,
connection, or writable transport.

Locally constructed Responses are mutable until protocol commit. Received
Responses are read-only.

Incoming client bodies are streaming-first. C<body> contains received body data
only when bounded buffering was requested explicitly.

=head1 CONSTRUCTOR

    my $res = Linux::Event::HTTP::Response->new(
        status  => 200,
        reason  => 'OK',
        version => '1.1',
        headers => [ ... ],
        body    => $bytes,
    );

C<status> defaults to 200 and C<version> defaults to C<1.1>.

HTTP/2 responses use version C<2> and do not serialize an HTTP/1 reason phrase.

=head1 METHODS

=head2 status

Gets or, while mutable, sets a status from 100 through 599.

=head2 reason

Gets or, while mutable, sets the optional HTTP/1 reason phrase.

HTTP/2 does not send a reason phrase.

=head2 version

Gets or, while mutable, sets the HTTP version.

=head2 header

Gets the first matching field value.

On a mutable Response, the setter replaces all fields of the same
case-insensitive name with one field.

=head2 add_header

Adds another header field without removing existing same-name fields.

=head2 remove_header

Removes all fields with the supplied case-insensitive name.

=head2 header_values

Returns an array reference containing all matching values in message order.

=head2 header_count, header_name, header_value

Provide exact indexed access to the lossless header list.

=head2 headers_are_lossless

Returns true.

=head2 content_length

Returns the declared Content-Length as an integer, or undef when absent.

=head2 body

Gets or, while mutable, sets a complete scalar body.

Setting a scalar body marks that message body complete. It does not itself mean
the bytes have already been written to a transport.

For a received client Response, C<body> returns data only when bounded
C<buffer_body> handling was requested. Otherwise body bytes remain incremental.

=head2 has_buffered_body

True when a complete scalar body is locally available.

=head2 is_complete

True when the complete message body boundary is known or has been reached.

=head2 is_mutable

True until protocol commit.

=head1 SEE ALSO

L<Linux::Event::HTTP::Request>, L<Linux::Event::HTTP::Transaction>,
L<Linux::Event::HTTP::Client>, L<Linux::Event::HTTP::Server>.

=cut
