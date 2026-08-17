package HTTP::API::Core::Error;

use strict;
use warnings;
use overload '""' => 'as_string', fallback => 1;

sub new {
    my ($class, %args) = @_;
    return bless \%args, $class;
}

sub message     { $_[0]->{message} }
sub category    { $_[0]->{category} }
sub status      { $_[0]->{status} }
sub method      { $_[0]->{method} }
sub url         { $_[0]->{url} }
sub retryable   { $_[0]->{retryable} ? 1 : 0 }
sub retry_after { $_[0]->{retry_after} }
sub elapsed     { $_[0]->{elapsed} }
sub request_id  { $_[0]->{request_id} }
sub response    { $_[0]->{response} }
sub body        { $_[0]->{response} ? $_[0]->{response}->content : undef }
sub text        { $_[0]->{response} ? $_[0]->{response}->text : undef }
sub headers     { $_[0]->{response} ? $_[0]->{response}->headers : {} }
sub header      { $_[0]->{response} ? $_[0]->{response}->header($_[1]) : undef }
sub json        { $_[0]->{response} ? $_[0]->{response}->json : undef }
sub rate_limit  { $_[0]->{response} ? $_[0]->{response}->rate_limit : undef }
sub as_string   { defined($_[0]->{message}) ? $_[0]->{message} : 'HTTP API core error' }

1;

__END__

=head1 NAME

HTTP::API::Core::Error - Structured errors from HTTP::API::Core

=head1 DESCRIPTION

HTTP::API::Core throws structured error objects. The C<category> value is the
primary machine-readable classification. Human-readable C<message> wording is
diagnostic and should not be parsed for program logic.

The stable categories are C<encode>, C<decode>, C<transport>, C<http>, and
C<hook>.

=head1 METHODS

=head2 message, category, status, method, url

Basic structured error metadata.

=head2 retryable, retry_after

Retry-related metadata.

=head2 elapsed, request_id

Observability metadata when available.

=head2 response

Returns the associated L<HTTP::API::Core::Response> for HTTP/decode errors,
or C<undef> when no response exists.

=head2 body, text

Return associated raw response content, or C<undef> when there is no response.

=head2 headers

Returns a defensive copy of response headers. Without a response, returns an
empty hash reference.

=head2 header($name)

Returns one response header, or C<undef> when no response exists.

=head2 json

Explicitly decodes the associated response body as JSON using the response
object's C<json> semantics. Without a response, returns C<undef>.

=head2 rate_limit

Returns normalized rate-limit metadata when an associated response exists.

=head2 as_string

Returns the human-readable diagnostic message. Exact message wording is not
part of the machine-readable compatibility contract.

=cut
