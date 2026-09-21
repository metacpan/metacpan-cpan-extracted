package Linux::Event::HTTP::Request;
use v5.36;
use strict;
use warnings;

use Hash::Util::FieldHash qw(fieldhash);
use Scalar::Util qw(reftype);
use utf8 ();

use Linux::Event::HTTP::_HTTP1 ();

our $VERSION = '0.002';

my (
    $NATIVE_METHOD,
    $NATIVE_TARGET,
    $NATIVE_VERSION,
    $NATIVE_BODY_MODE,
    $NATIVE_CONTENT_LENGTH,
    $NATIVE_KEEP_ALIVE,
    $NATIVE_HEADER_COUNT,
    $NATIVE_HEADER_NAME,
    $NATIVE_HEADER_VALUE,
    $NATIVE_HEADER,
    $NATIVE_HEADER_VALUES,
    $NATIVE_DESTROY,
);

BEGIN {
    no strict 'refs';
    $NATIVE_METHOD         = \&{__PACKAGE__ . '::method'};
    $NATIVE_TARGET         = \&{__PACKAGE__ . '::target'};
    $NATIVE_VERSION        = \&{__PACKAGE__ . '::http_version'};
    $NATIVE_BODY_MODE      = \&{__PACKAGE__ . '::body_mode'};
    $NATIVE_CONTENT_LENGTH = \&{__PACKAGE__ . '::content_length'};
    $NATIVE_KEEP_ALIVE     = \&{__PACKAGE__ . '::keep_alive'};
    $NATIVE_HEADER_COUNT   = \&{__PACKAGE__ . '::header_count'};
    $NATIVE_HEADER_NAME    = \&{__PACKAGE__ . '::header_name'};
    $NATIVE_HEADER_VALUE   = \&{__PACKAGE__ . '::header_value'};
    $NATIVE_HEADER         = \&{__PACKAGE__ . '::header'};
    $NATIVE_HEADER_VALUES  = \&{__PACKAGE__ . '::header_values'};
    $NATIVE_DESTROY        = \&{__PACKAGE__ . '::DESTROY'};
}

no warnings 'redefine';

fieldhash my %NATIVE_COMPLETE;

sub CLONE_SKIP { 1 }

sub _is_native ($self) {
    return (reftype($self) // '') eq 'SCALAR';
}

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

sub _validate_method ($method) {
    die 'request method is required' if !defined($method) || ref($method) || $method eq '';
    die 'invalid request method'
        if $method !~ /\A[!#\$%&'*+\-.^_`|~0-9A-Za-z]+\z/;
}

sub _validate_target ($target) {
    die 'request target is required' if !defined($target) || ref($target) || $target eq '';
    my $bytes = _byte_string('target', $target);
    die 'invalid request target' if $bytes =~ /[\x00-\x20\x7f]/;
    return $bytes;
}

sub _validate_version ($version) {
    die 'invalid HTTP version'
        if !defined($version) || ref($version)
        || "$version" !~ /\A[0-9]+(?:\.[0-9]+)?\z/;
}

sub _validate_name ($name) {
    die 'header field name is required' if !defined($name) || ref($name) || $name eq '';
    die 'invalid header field name'
        if $name !~ /\A[!#\$%&'*+\-.^_`|~0-9A-Za-z]+\z/;
}

sub _validate_value ($value) {
    die 'header field value must be defined' if !defined($value) || ref($value);
    my $bytes = _byte_string('header', $value);
    die 'header field value contains invalid control characters'
        if $bytes =~ /[\x00-\x08\x0a-\x1f\x7f]/;
    return $bytes;
}

sub _validate_header_index ($index) {
    die 'header index must be a non-negative integer'
        if !defined($index) || ref($index) || "$index" !~ /\A[0-9]+\z/;
    return 0 + $index;
}

sub _assert_mutable ($self) {
    die 'received request metadata is read-only' if _is_native($self);
    die 'request metadata cannot change after the message is committed'
        if $self->{committed};
}

sub new ($class, %args) {
    my $method  = delete $args{method};
    my $target  = delete $args{target};
    my $version = delete($args{version}) // '1.1';
    my $headers = delete $args{headers};
    my $has_body = exists $args{body};
    my $body = delete $args{body};

    die 'unknown request option: ' . join(', ', sort keys %args) if %args;

    _validate_method($method);
    $target = _validate_target($target);
    _validate_version($version);

    my $self = bless {
        method    => "$method",
        target    => $target,
        version   => "$version",
        headers   => [],
        body_kind => undef,
        body      => undef,
        committed => 0,
        complete  => 1,
    }, $class;

    if (defined $headers) {
        die 'headers must be an array reference of [name, value] pairs'
            if ref($headers) ne 'ARRAY';
        for my $pair (@$headers) {
            die 'each request header must be a [name, value] pair'
                if ref($pair) ne 'ARRAY' || @$pair != 2;
            $self->add_header($pair->[0], $pair->[1]);
        }
    }

    $self->body($body) if $has_body;
    return $self;
}

sub method ($self, @args) {
    if (_is_native($self)) {
        die 'received request metadata is read-only' if @args;
        return $NATIVE_METHOD->($self);
    }
    return $self->{method} if !@args;
    die 'method accepts exactly one value' if @args != 1;
    $self->_assert_mutable;
    _validate_method($args[0]);
    $self->{method} = "$args[0]";
    return $self;
}

sub target ($self, @args) {
    if (_is_native($self)) {
        die 'received request metadata is read-only' if @args;
        return $NATIVE_TARGET->($self);
    }
    return $self->{target} if !@args;
    die 'target accepts exactly one value' if @args != 1;
    $self->_assert_mutable;
    $self->{target} = _validate_target($args[0]);
    return $self;
}

sub target_is_exact ($self) {
    return 1;
}

sub version ($self, @args) {
    if (_is_native($self)) {
        die 'received request metadata is read-only' if @args;
        return $NATIVE_VERSION->($self);
    }
    return $self->{version} if !@args;
    die 'version accepts exactly one value' if @args != 1;
    $self->_assert_mutable;
    if (!defined $args[0]) {
        $self->{version} = undef;
        return $self;
    }
    _validate_version($args[0]);
    $self->{version} = "$args[0]";
    return $self;
}

sub header ($self, $name, @args) {
    _validate_name($name);
    if (_is_native($self)) {
        die 'received request metadata is read-only' if @args;
        return $NATIVE_HEADER->($self, $name);
    }

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
                push @headers, [ "$name", $value ];
                $inserted = 1;
            }
            next;
        }
        push @headers, [ @$pair ];
    }
    push @headers, [ "$name", $value ] if !$inserted;
    $self->{headers} = \@headers;
    return $self;
}

sub add_header ($self, $name, $value) {
    $self->_assert_mutable;
    _validate_name($name);
    $value = _validate_value($value);
    push @{$self->{headers}}, [ "$name", $value ];
    return $self;
}

sub remove_header ($self, $name) {
    $self->_assert_mutable;
    _validate_name($name);
    my $wanted = lc $name;
    $self->{headers} = [ grep { lc($_->[0]) ne $wanted } @{$self->{headers}} ];
    return $self;
}

sub _header_values_list ($self, $name) {
    _validate_name($name);
    return $NATIVE_HEADER_VALUES->($self, $name) if _is_native($self);
    my $wanted = lc $name;
    return map { $_->[1] }
        grep { lc($_->[0]) eq $wanted }
        @{$self->{headers}};
}

sub header_values ($self, $name) {
    return [ $self->_header_values_list($name) ];
}

sub header_count ($self) {
    return $NATIVE_HEADER_COUNT->($self) if _is_native($self);
    return scalar @{$self->{headers}};
}

sub header_name ($self, $index) {
    $index = _validate_header_index($index);
    return undef if $index >= $self->header_count;
    return $NATIVE_HEADER_NAME->($self, $index) if _is_native($self);
    return $self->{headers}[$index][0];
}

sub header_value ($self, $index) {
    $index = _validate_header_index($index);
    return undef if $index >= $self->header_count;
    return $NATIVE_HEADER_VALUE->($self, $index) if _is_native($self);
    return $self->{headers}[$index][1];
}

sub headers_are_lossless ($self) {
    return 1;
}

sub _parse_content_length_values (@values) {
    return undef if !@values;
    my $length;
    for my $value (@values) {
        for my $member (split /,/, $value, -1) {
            $member =~ s/\A[ \t]+//;
            $member =~ s/[ \t]+\z//;
            die 'invalid or conflicting Content-Length'
                if $member eq '' || $member !~ /\A[0-9]+\z/;
            my $number = 0 + $member;
            die 'invalid or conflicting Content-Length'
                if defined($length) && $length != $number;
            $length = $number;
        }
    }
    return $length;
}

sub content_length ($self) {
    return $NATIVE_CONTENT_LENGTH->($self) if _is_native($self);
    return _parse_content_length_values($self->_header_values_list('Content-Length'));
}

sub body ($self, @args) {
    if (_is_native($self)) {
        die 'received request body is delivered incrementally and is not buffered by Request'
            if @args;
        return undef;
    }
    return $self->{body} if !@args;
    die 'body accepts exactly one value' if @args != 1;
    $self->_assert_mutable;
    die 'body(): Request already has an incremental body producer'
        if ($self->{body_kind} // '') eq 'stream';
    $self->{body_kind} = 'scalar';
    $self->{body} = _byte_string('body', $args[0]);
    $self->{complete} = 1;
    return $self;
}

sub has_buffered_body ($self) {
    return 0 if _is_native($self);
    return ($self->{body_kind} // '') eq 'scalar' ? 1 : 0;
}

sub is_complete ($self) {
    if (_is_native($self)) {
        return $NATIVE_COMPLETE{$self} if exists $NATIVE_COMPLETE{$self};
        return $NATIVE_BODY_MODE->($self) eq 'none' ? 1 : 0;
    }
    return !!$self->{complete};
}

sub is_mutable ($self) {
    return 0 if _is_native($self);
    return $self->{committed} ? 0 : 1;
}

sub _begin_stream_body ($self) {
    $self->_assert_mutable;
    die 'request_body(): Request already has a complete scalar body'
        if ($self->{body_kind} // '') eq 'scalar';
    die 'request_body(): Request already has an incremental body producer'
        if ($self->{body_kind} // '') eq 'stream';
    $self->{body_kind} = 'stream';
    $self->{complete} = 0;
    return $self;
}

sub _has_scalar_body ($self) {
    return $self->has_buffered_body;
}

sub _has_incremental_body ($self) {
    return 0 if _is_native($self);
    return ($self->{body_kind} // '') eq 'stream';
}

sub _mark_complete ($self) {
    if (_is_native($self)) {
        $NATIVE_COMPLETE{$self} = 1;
    } else {
        $self->{complete} = 1;
    }
    return $self;
}

sub _mark_incomplete ($self) {
    die 'cannot mark a received Request incomplete' if _is_native($self);
    $self->{complete} = 0;
    return $self;
}

sub _mark_committed ($self) {
    die 'cannot commit a received Request' if _is_native($self);
    $self->{committed} = 1;
    return $self;
}

sub _http1_body_mode ($self) {
    die '_http1_body_mode is only available for a parsed HTTP/1 request'
        if !_is_native($self);
    return $NATIVE_BODY_MODE->($self);
}

sub _http1_keep_alive ($self) {
    die '_http1_keep_alive is only available for a parsed HTTP/1 request'
        if !_is_native($self);
    return $NATIVE_KEEP_ALIVE->($self);
}

sub DESTROY ($self) {
    return if !_is_native($self);
    $NATIVE_DESTROY->($self);
    return;
}

1;

__END__

=head1 NAME

Linux::Event::HTTP::Request - HTTP request message

=head1 SYNOPSIS

    my $request = Linux::Event::HTTP::Request->new(
        method => 'POST',
        target => '/items',
        headers => [
            [ 'Content-Type', 'application/json' ],
        ],
        body => $bytes,
    );

=head1 DESCRIPTION

C<Linux::Event::HTTP::Request> represents one HTTP request message. The same
class is used for locally constructed outgoing requests and parsed incoming
requests.

Locally constructed requests are mutable until the HTTP transaction commits
them for transmission. Parsed incoming requests expose committed, read-only
metadata. HTTP/1 parser state remains native and lazy: method, target, and
header strings are materialized as Perl scalars only when requested.

The public message API conforms directly to the C<Uniform::HTTP> 0.02 message
contract by behavior; it does not inherit from a Uniform class. Duplicate header
occurrences, inter-field order, original field-name spelling, and the exact
request-target are preserved. Connection, Transaction, streaming, retry, and
protocol-handoff state remain outside the Request.

The Request does not own a socket or a transaction. Incremental body transfer
belongs to the transaction/connection layer. C<body> is only the convenience
representation for a complete scalar body; incoming bodies are not implicitly
buffered into the Request object.

=head1 METHODS

=head2 new

Constructs a mutable request message. C<method> and C<target> are required.
C<version> defaults to C<1.1>. C<headers> is an optional array reference of
C<[name, value]> pairs so duplicates and field order are preserved. C<body> is
an optional complete scalar byte body.

=head2 method

Gets the request method. A locally constructed request may set it before the
message is committed.

=head2 target

Gets the request target exactly as it appears in the HTTP message. A locally
constructed request may set it before commit.

=head2 target_is_exact

Returns true. Linux::Event::HTTP preserves the exact Request target rather than
reconstructing it from decomposed URL or routing state.

=head2 version

Gets the HTTP version, such as C<1.1>. A locally constructed request may set it
before commit. Passing C<undef> clears the represented version; an HTTP/1
executor will reject an unset version when transmission is attempted.

=head2 header

    my $host = $request->header('Host');
    $request->header('Accept', 'application/json');

Returns the first matching field value. On a mutable local Request, the setter
form replaces all fields of the same ASCII case-insensitive name with one field
at the position of the first occurrence, or appends it when absent.

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
Parsed HTTP/1 requests have already had conflicting values rejected.

=head2 body

Gets or sets the complete scalar byte body of a locally constructed Request.
Incremental outgoing bodies are selected through the owning Transaction rather
than through the Request message. Incoming bodies are delivered incrementally
by the transaction/connection layer and are not implicitly accumulated here.
Passing C<undef> as a body is an error; an explicit empty body is C<''>.

=head2 has_buffered_body

Returns true only when a complete scalar body buffer is locally available,
including an explicit empty buffer. Parsed incoming Request bodies are streamed
by the surrounding protocol layer and therefore return false.

=head2 is_complete

Returns whether the complete message body boundary has been reached. A locally
constructed scalar-body request is complete immediately; an outgoing or incoming
streamed request becomes complete only when the protocol layer reaches its final
body boundary.

=head2 is_mutable

Returns true only while a locally constructed Request has not been committed for
transmission. Parsed incoming Requests are read-only and return false.

=cut
