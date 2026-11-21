package HTTP::API::Core::Response;

use strict;
use warnings;
use JSON::PP qw(decode_json);
use HTTP::API::Core::Error;
use HTTP::API::Core::RateLimit;

sub new {
    my $class = shift;
    die "response constructor options must be key/value pairs\n" if @_ % 2;
    die "constructor option names must be scalars\n"
        if grep { ref($_) ne '' } @_[ grep { $_ % 2 == 0 } 0 .. $#_ ];
    my %args = @_;

    die "response status must be a valid HTTP status\n"
        if !defined($args{status})
        || ref($args{status}) ne ''
        || $args{status} !~ /\A[0-9]{3}\z/
        || $args{status} < 100
        || $args{status} > 599;

    my $headers = defined($args{headers}) ? $args{headers} : {};
    die "response headers must be a hash reference\n" if ref($headers) ne 'HASH';
    die "response header names must be scalars\n"
        if grep { ref($_) ne '' } keys %$headers;
    for my $value (values %$headers) {
        next if !defined($value) || ref($value) eq '';
        die "response header values must be scalars, arrays of scalars, or undef\n"
            if ref($value) ne 'ARRAY'
            || grep { defined($_) && ref($_) ne '' } @$value;
    }

    for my $name (qw(reason content method url elapsed)) {
        die "response $name must be a scalar or undef\n"
            if defined($args{$name}) && ref($args{$name}) ne '';
    }

    # Conflicting case-insensitive header names are ambiguous. Never let
    # hash iteration order decide which value controls retry behavior.
    my (%normalized_headers, %conflicts);
    for my $name (keys %$headers) {
        my $key = lc $name;
        my $value = $headers->{$name};
        if (exists $normalized_headers{$key}) {
            $conflicts{$key} = 1
                if !_same_header_values($normalized_headers{$key}, $value);
        }
        $normalized_headers{$key} = ref($value) eq 'ARRAY'
            ? [ @$value ] : $value;
    }
    $normalized_headers{$_} = undef for keys %conflicts;

    return bless {
        status  => $args{status},
        reason  => $args{reason},
        headers => \%normalized_headers,
        content => defined($args{content}) ? $args{content} : '',
        method  => $args{method},
        url     => $args{url},
        elapsed => $args{elapsed},
    }, $class;
}

# Compare values without stringifying array references (or choosing a
# case-insensitive duplicate arbitrarily).
sub _same_header_values {
    my ($left, $right) = @_;
    return 0 if ref($left) ne ref($right);

    if (ref($left) eq 'ARRAY') {
        return 0 if @$left != @$right;
        for my $i (0 .. $#$left) {
            return 0 if defined($left->[$i]) != defined($right->[$i]);
            return 0 if defined($left->[$i]) && $left->[$i] ne $right->[$i];
        }
        return 1;
    }

    return 1 if !defined($left) && !defined($right);
    return defined($left) && defined($right) && $left eq $right;
}

# Scalar accessors are intentionally conservative: identical repeated values
# are unambiguous, while conflicting values do not control API policy.
sub _scalar_header_value {
    my ($value) = @_;
    return $value if ref($value) ne 'ARRAY';
    return undef if !@$value;

    my $first = $value->[0];
    for my $item (@$value) {
        return undef if defined($first) != defined($item);
        return undef if defined($first) && $first ne $item;
    }
    return $first;
}

sub status      { $_[0]->{status} }
sub reason      { $_[0]->{reason} }
sub headers {
    my ($self) = @_;
    my %headers = %{ $self->{headers} };
    for my $name (keys %headers) {
        $headers{$name} = [ @{ $headers{$name} } ]
            if ref($headers{$name}) eq 'ARRAY';
    }
    return \%headers;
}
sub content     { $_[0]->{content} }
sub text        { $_[0]->{content} }
sub has_content { length($_[0]->{content}) ? 1 : 0 }

sub content_type {
    my ($self) = @_;
    my $value = $self->header('content-type');
    return undef if !defined $value || $value eq '';
    $value =~ s/\s*;.*\z//;
    $value =~ s/^\s+|\s+$//g;
    return lc $value;
}

sub is_json {
    my ($self) = @_;
    my $type = $self->content_type;
    return 0 if !defined $type;
    return 1 if $type eq 'application/json';
    return 1 if $type =~ m{\Aapplication/[a-z0-9.!#\$&^_+\-]+\+json\z}i;
    return 0;
}

sub method  { $_[0]->{method} }
sub elapsed { $_[0]->{elapsed} }

sub request_id {
    my ($self) = @_;
    for my $name (qw(x-request-id request-id x-correlation-id)) {
        my $value = $self->header($name);
        return $value if defined $value && length $value;
    }
    return undef;
}

sub url        { $_[0]->{url} }
sub is_success { $_[0]->{status} >= 200 && $_[0]->{status} < 300 }
sub header {
    my ($self, $name) = @_;
    die "response header name must be a defined scalar\n"
        if !defined($name) || ref($name) ne '';
    return _scalar_header_value($self->{headers}{lc $name});
}
sub rate_limit  { HTTP::API::Core::RateLimit->from_headers($_[0]->{headers}) }

sub json {
    my ($self) = @_;
    return undef if $self->{content} !~ /\S/;

    my $decoded = eval { decode_json($self->{content}) };
    if ($@) {
        die HTTP::API::Core::Error->new(
            category => 'decode',
            status   => $self->{status},
            method   => $self->{method},
            url      => $self->{url},
            response => $self,
            message  => "failed to decode JSON response: $@",
        );
    }
    return $decoded;
}

1;

__END__

=head1 NAME

HTTP::API::Core::Response - HTTP API response object

=head1 RESPONSE BODY

=head2 content

Returns the raw response body exactly as supplied by the transport.

=head2 text

An alias for C<content>. No charset transcoding is performed.

=head2 has_content

Returns true when the raw response body has non-zero length.

=head2 json

Decodes the response body as JSON. An empty or whitespace-only body returns
C<undef>. JSON decoding is explicit: C<json> attempts to decode regardless of
the response Content-Type header, and throws a structured C<decode> error when
non-empty content is not valid JSON.

=head1 CONTENT TYPE

=head2 content_type

Returns the lower-cased media type from C<Content-Type>, excluding parameters
such as C<charset>. Returns C<undef> when the header is absent.

=head2 is_json

Returns true for C<application/json> and structured syntax suffix media types
ending in C<+json>, such as C<application/problem+json>.

=head1 METADATA

=head2 status, reason, headers, header, method, url

Provide response status and request metadata. C<headers> returns a defensive
copy, including copies of array references for repeated headers such as
C<Set-Cookie>. C<header($name)> returns a scalar for a single value or
identical repeated values; conflicting repeated values return C<undef>.
Case-insensitively duplicated header names with matching values are preserved;
conflicting values become C<undef> rather than being chosen arbitrarily.

=head2 elapsed

Returns transport elapsed time when available.

=head2 request_id

Returns the first non-empty C<X-Request-Id>, C<Request-Id>, or
C<X-Correlation-Id> value.

=cut
