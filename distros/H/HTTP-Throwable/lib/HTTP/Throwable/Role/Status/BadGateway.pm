package HTTP::Throwable::Role::Status::BadGateway;
our $AUTHORITY = 'cpan:STEVAN';
$HTTP::Throwable::Role::Status::BadGateway::VERSION = '0.027';
use Moo::Role;

with(
    'HTTP::Throwable',
    'HTTP::Throwable::Role::BoringText',
);

sub default_status_code { 502 }
sub default_reason      { 'Bad Gateway' }

no Moo::Role; 1;

=pod

=encoding UTF-8

=head1 NAME

HTTP::Throwable::Role::Status::BadGateway - 502 Bad Gateway

=head1 VERSION

version 0.027

=head1 DESCRIPTION

The server, while acting as a gateway or proxy, received
an invalid response from the upstream server it accessed
in attempting to fulfill the request.

=head1 AUTHORS

=over 4

=item *

Stevan Little <stevan.little@iinteractive.com>

=item *

Ricardo Signes <rjbs@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: 502 Bad Gateway

#pod =head1 DESCRIPTION
#pod
#pod The server, while acting as a gateway or proxy, received
#pod an invalid response from the upstream server it accessed
#pod in attempting to fulfill the request.
#pod
#pod
