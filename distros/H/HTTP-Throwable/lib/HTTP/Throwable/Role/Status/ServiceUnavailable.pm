package HTTP::Throwable::Role::Status::ServiceUnavailable;
our $AUTHORITY = 'cpan:STEVAN';
$HTTP::Throwable::Role::Status::ServiceUnavailable::VERSION = '0.026';
use Types::Standard qw(Str);

use Moo::Role;

with(
    'HTTP::Throwable',
    'HTTP::Throwable::Role::BoringText',
);

sub default_status_code { 503 }
sub default_reason      { 'Service Unavailable' }

has 'retry_after' => ( is => 'ro', isa => Str );

around 'build_headers' => sub {
    my $next    = shift;
    my $self    = shift;
    my $headers = $self->$next( @_ );
    if ( my $retry = $self->retry_after ) {
        push @$headers => ('Retry-After' => $retry);
    }
    $headers;
};

no Moo::Role; 1;

=pod

=encoding UTF-8

=head1 NAME

HTTP::Throwable::Role::Status::ServiceUnavailable - 503 Service Unavailable

=head1 VERSION

version 0.026

=head1 DESCRIPTION

The server is currently unable to handle the request due to
a temporary overloading or maintenance of the server. The
implication is that this is a temporary condition which will
be alleviated after some delay. If known, the length of the
delay MAY be indicated in a Retry-After header. If no
Retry-After is given, the client SHOULD handle the response as
it would for a 500 response.

  Note: The existence of the 503 status code does not imply that a
  server must use it when becoming overloaded. Some servers may wish
  to simply refuse the connection.

=head1 AUTHORS

=over 4

=item *

Stevan Little <stevan.little@iinteractive.com>

=item *

Ricardo Signes <rjbs@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Infinity Interactive, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: 503 Service Unavailable

#pod =head1 DESCRIPTION
#pod
#pod The server is currently unable to handle the request due to
#pod a temporary overloading or maintenance of the server. The
#pod implication is that this is a temporary condition which will
#pod be alleviated after some delay. If known, the length of the
#pod delay MAY be indicated in a Retry-After header. If no
#pod Retry-After is given, the client SHOULD handle the response as
#pod it would for a 500 response.
#pod
#pod   Note: The existence of the 503 status code does not imply that a
#pod   server must use it when becoming overloaded. Some servers may wish
#pod   to simply refuse the connection.
#pod
#pod
