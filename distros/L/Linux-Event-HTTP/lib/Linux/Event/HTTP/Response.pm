package Linux::Event::HTTP::Response;
use v5.36;
use strict;
use warnings;

use Scalar::Util qw(refaddr);
use utf8 ();

use Linux::Event::HTTP::_HTTP1 ();

our $VERSION = '0.001';

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
        if !$self->is_mutable;
    return;
}

sub status ($self, @args) {
    return $self->{status} if !@args;

    die 'status accepts exactly one value' if @args != 1;
    $self->_assert_mutable;
    _validate_status($args[0]);
    $self->{status} = 0 + $args[0];
    return $self;
}

sub reason ($self, @args) {
    return $self->{reason} if !@args;

    die 'reason accepts exactly one value' if @args != 1;
    $self->_assert_mutable;
    $self->{reason} = defined($args[0]) ? _validate_reason($args[0]) : undef;
    return $self;
}

sub version ($self, @args) {
    return $self->{version} if !@args;

    die 'version accepts exactly one value' if @args != 1;
    $self->_assert_mutable;
    if (!defined $args[0]) {
        $self->{version} = undef;
        return $self;
    }
    $self->{version} = _validate_version($args[0]);
    return $self;
}

sub header ($self, $name, @args) {
    $name = _validate_name($name);

    if (!@args) {
        my $wanted = lc $name;
        for my $pair (@{$self->{headers}}) {
            return $pair->[1] if lc($pair->[0]) eq $wanted;
        }
        return undef;
    }

    die 'header setter accepts exactly one value' if @args != 1;
    $self->_assert_mutable;
    my $value = _validate_value($args[0]);
    my $wanted = lc $name;
    my @headers;
    my $inserted = 0;

    for my $pair (@{$self->{headers}}) {
        if (lc($pair->[0]) eq $wanted) {
            if (!$inserted) {
                push @headers, [ $name, $value ];
                $inserted = 1;
            }
            next;
        }
        push @headers, [ @$pair ];
    }
    push @headers, [ $name, $value ] if !$inserted;
    $self->{headers} = \@headers;

    return $self;
}

sub add_header ($self, $name, $value) {
    $self->_assert_mutable;
    $name = _validate_name($name);
    $value = _validate_value($value);
    $self->{headers} = []
        if refaddr($self->{headers}) == refaddr($EMPTY_HEADERS);
    push @{$self->{headers}}, [ $name, $value ];
    return $self;
}

sub remove_header ($self, $name) {
    $self->_assert_mutable;
    $name = _validate_name($name);
    my $wanted = lc $name;
    my @kept = grep { lc($_->[0]) ne $wanted } @{$self->{headers}};
    $self->{headers} = \@kept;
    return $self;
}

sub _header_values_list ($self, $name) {
    $name = _validate_name($name);
    my $wanted = lc $name;
    return map { $_->[1] }
        grep { lc($_->[0]) eq $wanted }
        @{$self->{headers}};
}

sub header_values ($self, $name) {
    return [ $self->_header_values_list($name) ];
}

sub header_count ($self) {
    return scalar @{$self->{headers}};
}

sub _validate_header_index ($index) {
    die 'header index must be a non-negative integer'
        if !defined($index) || ref($index) || "$index" !~ /\A[0-9]+\z/;
    return 0 + $index;
}

sub header_name ($self, $index) {
    $index = _validate_header_index($index);
    return undef if $index >= @{$self->{headers}};
    return $self->{headers}[$index][0];
}

sub header_value ($self, $index) {
    $index = _validate_header_index($index);
    return undef if $index >= @{$self->{headers}};
    return $self->{headers}[$index][1];
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
    $self->_assert_mutable;
    die 'body(): response already has an incremental body producer'
        if ($self->{body_kind} // '') eq 'stream';

    $self->{body_kind} = 'scalar';
    $self->{body} = _body_bytes('body', $args[0]);
    $self->{complete} = 1;
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

    my $response = Linux::Event::HTTP::Response->new(
        status => 200,
        headers => [
            [ 'Content-Type', 'text/plain' ],
        ],
        body => "hello\n",
    );

Server callbacks receive the same Response class:

    sub on_request ($conn, $req, $res) {
        $res->status(200);
        $res->header('Content-Type', 'text/plain');
        $res->body("hello\n");
    }

=head1 DESCRIPTION

C<Linux::Event::HTTP::Response> represents one HTTP response message. It is not
a socket, transaction, connection, or writable transport handle. The same
message class is used for locally constructed outgoing responses and parsed
incoming client responses.

Its public message API conforms directly to the C<Uniform::HTTP> 0.02 message
contract by behavior without inheriting from a Uniform class. Duplicate fields,
field order, original field-name spelling, buffered-body state, completeness,
and mutability are reported explicitly while transport and Transaction state
remain outside the message.

A Response owns status, reason, version, headers, complete scalar-body data, and
message completion state. It does not retain its peer Request or the Connection
that happens to carry it. Exchange lifecycle, output progress, cancellation,
Upgrade, and incremental body production belong to
L<Linux::Event::HTTP::Transaction> and the protocol Connection.

Selecting a complete scalar C<body> on a locally constructed Response makes the
message body complete immediately. That does not mean the message has been
written to a transport. Incremental body production is selected through the
owning Transaction; the Response records only that its body is incomplete until
the producer announces its final bytes.

A received client Response normally exposes body bytes incrementally through the
Client callback path. If the caller explicitly requests bounded whole-body
buffering, C<body> returns that completed scalar after the message boundary is
reached. Received response metadata remains committed and read-only either way.

=head1 METHODS

=head2 new

Constructs a mutable response message. C<status> defaults to 200 and C<version>
defaults to C<1.1>. C<headers> is an optional array reference of C<[name,
value]> pairs. C<body> is an optional complete scalar byte body.

=head2 status

Gets or sets an HTTP response status from 100 through 599 before message commit.

=head2 reason

Gets or sets the optional HTTP/1 reason phrase before message commit. Passing
C<undef> clears it; no standard reason phrase is synthesized.

=head2 version

Gets or sets the HTTP version before message commit. Passing C<undef> clears the
represented version; an HTTP executor will reject an unset version when needed.

=head2 header

Gets the first matching field value. The setter form replaces all fields of the
same ASCII case-insensitive name with one field at the position of the first
occurrence, or appends it when absent.

=head2 add_header

Adds another header field while preserving existing same-name fields.

=head2 remove_header

Removes all fields with the supplied ASCII case-insensitive name.

=head2 header_values

Returns an array reference containing all matching values in message order. An
absent field returns an empty array reference. Values are never implicitly
comma-joined.

=head2 header_count, header_name, header_value

Provide exact indexed access to fields in message order while preserving the
original field names. A non-negative index beyond the end returns C<undef>;
negative and non-integer indexes are programmer errors.

=head2 headers_are_lossless

Returns true because duplicate occurrences, inter-field order, and original
field-name spelling are retained.

=head2 content_length

Returns the declared Content-Length as an integer, or undef when absent.

=head2 body

Gets or sets the complete scalar byte body. Setting it is available only while a
locally constructed Response is mutable and declares that its message body is
complete. Incremental output is selected through the owning Transaction rather
than through the Response message. Passing C<undef> is an error; an explicit
empty body is C<''>.

For a received client Response, the getter returns the complete body only when
the client was explicitly asked to buffer it within a bounded limit. Otherwise
received body bytes remain incremental and C<body> returns undef.

=head2 has_buffered_body

Returns true only when a complete scalar body buffer is locally available,
including an explicit empty buffer.

=head2 is_complete

Returns whether the complete HTTP message body is known or its final boundary
has been reached. This is deliberately independent of whether an outgoing
message has started or finished writing to a transport.

=head2 is_mutable

Returns true until the Response metadata is committed to protocol execution and
false afterward. Mutators throw once the Response is committed.

=head1 SEE ALSO

L<Uniform::HTTP>, L<Linux::Event::HTTP::Request>,
L<Linux::Event::HTTP::Transaction>.

=cut
