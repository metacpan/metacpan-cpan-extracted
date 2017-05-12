package Global::Context::AuthToken;
{
  $Global::Context::AuthToken::VERSION = '0.003';
}
use Moose::Role;
# ABSTRACT: an authentication token

use namespace::autoclean;


has uri => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);

sub as_string { $_[0]->uri }

has agent => (
  is   => 'ro',
  isa  => 'Defined',
  required => 1,
);

1;

__END__

=pod

=head1 NAME

Global::Context::AuthToken - an authentication token

=head1 VERSION

version 0.003

=head1 OVERVIEW

Global::Context::AuthToken is a role.

AuthToken objects represent the means by which a request was authenticated and
a handle by which actions can be checked for authorization.

They have two required attributes: C<uri>, which must be a string, and
C<agent>, which must be a value pointing to the user.

It is expected that any serious use of Global::Context will use a non-trivial
AuthToken class that has more stringent requirements.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
