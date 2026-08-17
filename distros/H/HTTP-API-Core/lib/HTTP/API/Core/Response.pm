package HTTP::API::Core::Response;

use strict;
use warnings;
use JSON::PP qw(decode_json);
use HTTP::API::Core::Error;
use HTTP::API::Core::RateLimit;

sub new {
    my ($class, %args) = @_;
    return bless {
        status  => $args{status},
        reason  => $args{reason},
        headers => { map { lc($_) => $args{headers}{$_} } keys %{ $args{headers} || {} } },
        content => defined($args{content}) ? $args{content} : '',
        method  => $args{method},
        url     => $args{url},
        elapsed => $args{elapsed},
    }, $class;
}

sub status      { $_[0]->{status} }
sub reason      { $_[0]->{reason} }
sub headers     { +{ %{ $_[0]->{headers} } } }
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
sub header      { my ($self, $name) = @_; return $self->{headers}{lc $name} }
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

Provide response status and request metadata. C<headers> returns a copy.

=head2 elapsed

Returns transport elapsed time when available.

=head2 request_id

Returns the first non-empty C<X-Request-Id>, C<Request-Id>, or
C<X-Correlation-Id> value.

=cut
