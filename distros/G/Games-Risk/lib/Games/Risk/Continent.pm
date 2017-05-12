#
# This file is part of Games-Risk
#
# This software is Copyright (c) 2008 by Jerome Quelin.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#
use 5.010;
use strict;
use warnings;

package Games::Risk::Continent;
# ABSTRACT: continent object
$Games::Risk::Continent::VERSION = '4.000';
use List::MoreUtils qw{ all };
use Moose;
use MooseX::Has::Sugar;
use MooseX::SemiAffordanceAccessor;

use Games::Risk::Logger qw{ debug };


# -- attributes


has id    => ( ro, isa=>'Int', required );
has name  => ( ro, isa=>'Str', required );
has bonus => ( ro, isa=>'Int', required );
has color => ( ro, isa=>'Str', required );
has map   => ( ro, isa=>'Games::Risk::Map', required, weak_ref );
has countries => ( rw, auto_deref, isa=>'ArrayRef[Games::Risk::Country]' );


# -- finalizer

sub DEMOLISH { debug( "~continent " . $_[0]->name ."\n" ); }


# -- public methods


sub is_owned {
    my ($self, $player) = @_;

    return all { $_->owner eq $player } $self->countries;
}


__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Games::Risk::Continent - continent object

=head1 VERSION

version 4.000

=head1 DESCRIPTION

This module implements a map continent, with all its characteristics.
The word continent is a bit loose, since for some maps it can be either
a region, a suburb... or a planet! :-)

=head1 ATTRIBUTES

=head2 id

Unique id assigned to the continent.

=head2 bonus

Number of bonus armies given when a player controls every country in the
continent.

=head2 name

Continent name.

=head2 color

Color of the continent to flash it.

=head2 map

Reference to the parent map (weak ref to a L<Games::Risk::Map> object).

=head2 countries

The L<Games::Risk::Country> objects belonging to this continent.

=head1 METHODS

=head2 is_owned

    my $p0wned = $continent->is_owned( $player );

Return true if C<$player> is the owner of all C<$continent>'s countries.

=for Pod::Coverage DEMOLISH

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2008 by Jerome Quelin.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
