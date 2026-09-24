package InternetData::OauthError;

use strict;
use warnings;

use parent 'InternetData::Error';

our $VERSION = '1.6.1';

# The authorization server refused an OAuth request, with the reason it gave.
# `kind` follows the status like any other failure's. Never retryable: every
# refusal answers the request exactly as it was sent.
sub new {
    my ($class, %args) = @_;
    my $code = $args{error_code};
    my $description = $args{error_description};
    my $self = $class->SUPER::new(
        kind => $args{kind} || 'bad_request',
        status => $args{status},
        message => defined $description ? "$code: $description" : $code,
    );
    $self->{error_code} = $code;
    $self->{error_description} = $description;
    return $self;
}

# The subtype for a refusal. A code we have never seen stays this base type.
sub _from {
    my ($class, %args) = @_;
    my $type = $args{error_code} eq 'access_denied' ? 'InternetData::OauthAccessDeniedError'
        : $args{error_code} eq 'expired_token' ? 'InternetData::OauthExpiredTokenError'
        : $class;
    return $type->new(%args);
}

sub error_code { $_[0]->{error_code} }
sub error_description { $_[0]->{error_description} }
sub retryable { 0 }

package InternetData::OauthAccessDeniedError;

use strict;
use warnings;

our @ISA = ('InternetData::OauthError');
our $VERSION = '1.6.1';

package InternetData::OauthExpiredTokenError;

use strict;
use warnings;

our @ISA = ('InternetData::OauthError');
our $VERSION = '1.6.1';

1;

__END__

=head1 NAME

InternetData::OauthError - an OAuth request the authorization server refused

=head1 SYNOPSIS

    my $token = eval { $client->oauth->poll_device_token('your-client-id', $device) };
    if (my $error = $@) {
        die 'the sign-in was refused' if ref $error && $error->isa('InternetData::OauthAccessDeniedError');
        die 'the code ran out' if ref $error && $error->isa('InternetData::OauthExpiredTokenError');
        die $error;
    }

=head1 DESCRIPTION

A L<InternetData::Error>, so code catching every failure the client reports still
catches this one. C<kind> follows the status, and a C<401> here means the client
ID is not registered, never the API key, which these requests do not carry.
C<retryable> is always 0.

Two subclasses name the refusals that end a sign-in:
B<InternetData::OauthAccessDeniedError>, when the person refused it, and
B<InternetData::OauthExpiredTokenError>, when the device code expired or was
already used. A poll that outlives the code raises the second itself, with no
C<status>.

=head1 METHODS

=head2 error_code

The OAuth C<error> code, such as C<slow_down> or C<invalid_grant>.

=head2 error_description

The server's C<error_description>, or C<undef> when it sent none.

=head2 status

The HTTP status, or C<undef> for a refusal made locally.

=cut
