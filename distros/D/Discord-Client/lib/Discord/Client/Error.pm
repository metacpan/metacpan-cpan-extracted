package Discord::Client::Error;

use v5.26;
use strict;
use warnings;
use overload '""' => sub { $_[0]->{message} }, fallback => 1;

our $VERSION = '0.002';

sub new {
    my ( $class, %args ) = @_;

    # Producers sanitize their own fields; this value object preserves them as supplied.
    return bless \%args, $class;
}

# Accessors expose optional diagnostic fields without interpreting transport payloads.
sub message { $_[0]->{message} }
sub category { $_[0]->{category} }
sub status { $_[0]->{status} }
sub discord_code { $_[0]->{discord_code} }
sub request_id { $_[0]->{request_id} }
sub details { $_[0]->{details} }
sub close_code { $_[0]->{close_code} }
sub event { $_[0]->{event} }

1;

__END__

=encoding UTF-8

=head1 NAME

Discord::Client::Error - SDK failure details

=head1 SYNOPSIS

    # Inspect a failed SDK Future without logging credentials.
    my ($message, $category, $error) = $future->failure;
    my $status = $error->status;
    my $code = $error->discord_code;

=head1 DESCRIPTION

Failure details for SDK Futures and error callbacks. Stringification returns
C<message>. SDK-produced messages omit credentials, raw bodies and exceptions.
Unavailable fields return undef. HTTP status and Discord error code are separate.

=head1 METHODS

=head2 new

C<new(message =E<gt> ..., category =E<gt> ..., field_pairs)> returns an Error.
It stores supplied fields without validation or sanitization; the SDK sanitizes
its own errors before construction.

=head2 message

Returns the error message.

=head2 category

Returns the failure category, such as C<request>, C<handler> or C<shutdown>.
REST categories are described in L<Discord::Client::REST/ERRORS AND CANCELLATION>.

=head2 status

Returns the HTTP status code or undef.

=head2 discord_code

Returns the Discord error code or undef.

=head2 request_id

Returns the request ID or undef.

=head2 details

Returns additional error details or undef.

=head2 close_code

Returns the Gateway close code or undef.

=head2 event

Returns the event associated with the error or undef.

=head1 LICENSE

Apache License 2.0.

=cut
