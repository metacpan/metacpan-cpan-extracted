package HTTP::Throwable::Role::Status::NotImplemented;
our $AUTHORITY = 'cpan:STEVAN';
$HTTP::Throwable::Role::Status::NotImplemented::VERSION = '0.026';
use Moo::Role;

with(
    'HTTP::Throwable',
    'HTTP::Throwable::Role::BoringText',
);

sub default_status_code { 501 }
sub default_reason      { 'Not Implemented' }

no Moo::Role; 1;

=pod

=encoding UTF-8

=head1 NAME

HTTP::Throwable::Role::Status::NotImplemented - 501 Not Implemented

=head1 VERSION

version 0.026

=head1 DESCRIPTION

The server does not support the functionality required to
fulfill the request. This is the appropriate response when
the server does not recognize the request method and is
not capable of supporting it for any resource.

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

# ABSTRACT: 501 Not Implemented

#pod =head1 DESCRIPTION
#pod
#pod The server does not support the functionality required to
#pod fulfill the request. This is the appropriate response when
#pod the server does not recognize the request method and is
#pod not capable of supporting it for any resource.
#pod
#pod
