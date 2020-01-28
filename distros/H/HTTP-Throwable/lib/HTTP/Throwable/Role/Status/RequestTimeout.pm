package HTTP::Throwable::Role::Status::RequestTimeout;
our $AUTHORITY = 'cpan:STEVAN';
$HTTP::Throwable::Role::Status::RequestTimeout::VERSION = '0.027';
use Moo::Role;

with(
    'HTTP::Throwable',
    'HTTP::Throwable::Role::BoringText',
);

sub default_status_code { 408 }
sub default_reason      { 'Request Timeout' }

no Moo::Role; 1;

=pod

=encoding UTF-8

=head1 NAME

HTTP::Throwable::Role::Status::RequestTimeout - 408 Request Timeout

=head1 VERSION

version 0.027

=head1 DESCRIPTION

The client did not produce a request within the
time that the server was prepared to wait. The
client MAY repeat the request without modifications
at any later time.

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

# ABSTRACT: 408 Request Timeout

#pod =head1 DESCRIPTION
#pod
#pod The client did not produce a request within the
#pod time that the server was prepared to wait. The
#pod client MAY repeat the request without modifications
#pod at any later time.
#pod
