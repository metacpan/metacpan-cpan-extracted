use 5.006;
use strict;
use warnings;

package Dist::Zilla::Util::RoleDB;

our $VERSION = '0.004001';

# ABSTRACT: Shared code for things that communicate data about dzil roles.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moo qw( has );
use Carp qw( croak );

## no critic (NamingConventions)
my $is_ArrayRef = sub {
  return 'ARRAY' eq ref $_[0] unless $_[1];
  return unless 'ARRAY' eq ref $_[0];
  for ( @{ $_[0] } ) {
    return unless $_[1]->($_);
  }
  1;
};







has items => (
  isa => sub {
    $is_ArrayRef->( $_[0], sub { $_[0]->isa('Dist::Zilla::Util::RoleDB::Entry') } ) or croak 'Must be ArrayRef[ RoleDB::Entry ]';
  },
  is      => ro =>,
  lazy    => 1,
  builder => '_build_items',
);

no Moo;

sub _build_items {
  require Dist::Zilla::Util::RoleDB::Items;
  return [ Dist::Zilla::Util::RoleDB::Items->all() ];
}







sub roles {
  my ($self) = @_;
  return @{ [ sort { $a->name cmp $b->name } @{ $self->items } ] };
}







sub phases {
  my ($self) = @_;
  return @{ [ sort { $a->name cmp $b->name } grep { $_->is_phase } @{ $self->items } ] };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Util::RoleDB - Shared code for things that communicate data about dzil roles.

=head1 VERSION

version 0.004001

=head1 DESCRIPTION

This utility is a hard-coded list of various known C<Dist::Zilla> roles and their properties.

It's not generally usable by most people, and is more useful for query tools, such as

  dzil dumpphases

Certain entries may have additional markers indicating they are C<phase> roles,
and will have relevant data indicating what methods are invoked in that C<phase>.

=head1 METHODS

=head2 C<roles>

Returns a list of all roles in the database, sorted by name.

=head2 C<phases>

Returns a list of all roles that are also phases, sorted by name.

=head1 ATTRIBUTES

=head2 C<items>

Contains all items in this data set, as an array ref.

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
