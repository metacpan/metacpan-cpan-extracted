use 5.006;
use strict;
use warnings;

package Dist::Zilla::Util::RoleDB::Entry::Phase;

our $VERSION = '0.004001';

# ABSTRACT: Extracted meta-data about a role that represents a phase

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moo qw( has extends );
use Carp qw( croak );

## no critic (NamingConventions)
my $is_Str = sub { 'SCALAR' eq ref \$_[0] or 'SCALAR' eq ref \( my $val = $_[0] ) };

extends 'Dist::Zilla::Util::RoleDB::Entry';







sub is_phase {
  return 1;
}







has phase_method => (
  isa => sub { $is_Str->( $_[0] ) or croak 'phase_method must be a Str' },
  is            => ro =>,
  required      => 1,
  documentation => q[The method dzil calls on the phase],
);

no Moo;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Util::RoleDB::Entry::Phase - Extracted meta-data about a role that represents a phase

=head1 VERSION

version 0.004001

=head1 METHODS

=head2 C<is_phase>

Returns true.

=head1 ATTRIBUTES

=head2 C<phase_method>

Returns the method C<Dist::Zilla> calls to implement this phase

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
