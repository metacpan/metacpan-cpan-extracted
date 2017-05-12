use 5.006;
use strict;
use warnings;

package Dist::Zilla::Util::RoleDB::Items;

our $VERSION = '0.004001';

# ABSTRACT: An aggregate provisioned index of roles

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

my @items;









sub all {
  return @items if @items;
  _add_items();
  return @items;
}

sub _add_items {
  require Dist::Zilla::Util::RoleDB::Items::Core;
  push @items, Dist::Zilla::Util::RoleDB::Items::Core->all;
  require Dist::Zilla::Util::RoleDB::Items::ThirdParty;
  push @items, Dist::Zilla::Util::RoleDB::Items::ThirdParty->all;
  return;
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Util::RoleDB::Items - An aggregate provisioned index of roles

=head1 VERSION

version 0.004001

=head1 METHODS

=head2 C<all>

Returns all items in this item set, as a list

    my @entries = $class->all();.

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
