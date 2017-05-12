#
# This file is part of Games-Pandemic
#
# This software is Copyright (c) 2009 by Jerome Quelin.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 2, June 1991
#
use 5.010;
use strict;
use warnings;

package Games::Pandemic::City;
{
  $Games::Pandemic::City::VERSION = '1.120510';
}
# ABSTRACT: pandemic city object

use Moose 0.92;
use MooseX::Has::Sugar;
use MooseX::SemiAffordanceAccessor;

use Games::Pandemic::Utils;


# -- accessors

# WARNING: do not use y as an attribute name, since it confuses the
# hell out of xgettext when one tries to access $foo->y. indeed, it
# will skip random portions of your file, without any warning.
# therefore, i'm using coordx / coordy.
has id      => ( ro, required, isa => 'Int' );
has name    => ( ro, required, isa => 'Str' );
has coordx  => ( ro, required, isa => 'Num' );
has coordy  => ( ro, required, isa => 'Num' );
has xreal   => ( ro, required, isa => 'Num' );
has yreal   => ( ro, required, isa => 'Num' );
has disease => ( ro, required, weak_ref, isa => 'Games::Pandemic::Disease' );
has _map    => ( ro, required, weak_ref, isa => 'Games::Pandemic::Map' );



has has_station => (
    rw,
    traits  => ['Bool'],
    isa     => 'Bool',
    default => 0,
    handles => {
        build_station => 'set',
        quash_station => 'unset',
    }
);

#
# _infections is an array of integer. the indexes are the disease ids,
# and the values are the number of disease items on the city.
#
# private methods provided:
#  . my $nb = $city->_get_infection($id);
#    return the number of item for disease $id in the $city.
#    see public method get_infection()
#
#  . $city->_set_infection($id, $nb);
#    set the new number $nb of items for disease $id in the $city.
#    see public method infect()
#
has _infections => (
    ro,
    traits  => ['Array'],
    isa     => 'ArrayRef[Int]',
    default => sub { [] },
    handles => {
        _get_infection => 'get',
        _set_infection => 'set',
    },
);

has neighbour_ids => (
    ro, required,
    traits   => ['Array'],
    isa      => 'ArrayRef',
    handles  => { _neighbour_ids => 'elements' },
);


# -- default builders / finishers

sub DEMOLISH {
    my $self = shift;
    #debug( "~city: " . $self->name . "\n" );
}


# -- public methods


sub neighbours {
    my $self = shift;
    my $map = $self->_map;
    return map { $map->city($_) } $self->_neighbour_ids;
}



sub infect {
    my ($self, $nb, $disease) = @_;
    $nb      //= 1;
    $disease //= $self->disease;

    # FIXME: check for eradication

    # perform the infection
    my $id  = $disease->id;
    my $old = $self->_get_infection($id) // 0; # FIXME//padre
    my $new = $old + $nb;
    my $max = $self->_map->max_infections;

    # check for outbreak
    my $outbreak = 0;
    if ( $new > $max ) {
        $new      = $max;
        $outbreak = 1;
    }

    # store new infection state & return outbreak status
    $self->_set_infection( $id, $new );
    return $outbreak, $new-$old;
}



sub get_infection {
    my ($self, $disease) = @_;
    return $self->_get_infection( $disease->id ) // 0; # FIXME//padre
}



sub treat {
    my ($self, $disease, $nb) = @_;
    my $before = $self->get_infection($disease);
    $self->_set_infection( $disease->id, $before-$nb );
}




no Moose;
__PACKAGE__->meta->make_immutable;

1;


=pod

=head1 NAME

Games::Pandemic::City - pandemic city object

=head1 VERSION

version 1.120510

=head1 DESCRIPTION

This module implements a class for city objects, used in Pandemic. They
have different attributes:

=over 4

=item * name: the city name

=item * xreal: the x coord of the city

=item * yreal: the y coord of the city

=item * coordx: the x coord where city information will be put

=item * coordy: the y coord where city information will be put

=item * disease: a ref to a C<Games::Pandemic::Disease> object, which is
the disease which will infect the city by default

=back

=head1 METHODS

=head2 $city->build_station;

Create a research station in the city.

=head2 $city->quash_station;

Remove the research station that was in the city.

=head2 my $bool = $city->has_station;

Return true if the city has a research station.

=head2 my @cities = $city->neighbours;

Return a list of C<Games::Pandemic::City>, which are the direct
neighbours of C<$city>.

=head2 my ($outbreak, $nbreal) = $city->infect( [ $nb [, $disease] ] )

Infect C<$city> with C<$nb> items of C<$disease>. Return true if an
outbreak happened following this infection, false otherwise. If an
outbreak happened, return also the real number of items used (since a
city can only hold up to a maximum number of disease items).

C<$nb> defaults to 1, and C<$disease> to the city disease.

=head2 my $nb = $city->get_infection( $disease );

Return the number of C<$disease> items for the C<$city>.

=head2 $city->treat( $disease, $nb );

Remove C<$nb> items from C<$disease> in C<$city>.

=for Pod::Coverage DEMOLISH

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Jerome Quelin.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut


__END__


