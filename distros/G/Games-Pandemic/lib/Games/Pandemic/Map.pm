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

package Games::Pandemic::Map;
{
  $Games::Pandemic::Map::VERSION = '1.120510';
}
# ABSTRACT: pandemic map information

use File::Spec::Functions qw{ catdir catfile };
use Moose                 0.92;
use MooseX::Has::Sugar;
use MooseX::SemiAffordanceAccessor;

use Games::Pandemic::Card::City;
use Games::Pandemic::Card::Special::Airlift;
use Games::Pandemic::Card::Special::Forecast;
use Games::Pandemic::Card::Special::GovernmentGrant;
use Games::Pandemic::Card::Special::OneQuietNight;
use Games::Pandemic::Card::Special::ResilientPopulation;
use Games::Pandemic::City;
use Games::Pandemic::Disease;
use Games::Pandemic::Utils;

# -- accessors

has _cities => (
    ro, auto_deref,
    lazy,       # _diseases() needs to be built before
    traits  => ['Array'],
    isa     => 'ArrayRef[Games::Pandemic::City]',
    builder => '_cities_builder',
    handles => {
        all_cities => 'elements',       # my @c = $map->all_cities;
        city       => 'get',            # my $c = $map->city(23);
        _find_city => 'first',
    }
);

has _diseases => (
    ro, auto_deref,
    traits  => ['Array'],
    isa     => 'ArrayRef[Games::Pandemic::Disease]',
    builder => '_diseases_builder',
    handles => {
        all_diseases => 'elements',     # my @d = $map->all_diseases;
        disease      => 'get',          # my $d = $map->disease(0);
    },
);

has max_infections => ( ro, lazy_build, isa => 'Int' );

has name => ( ro, isa => 'Str', builder => '_build_name' );

has start_city => (
    ro, weak_ref,
    lazy,     # _cities needs to be built before
    isa      => 'Games::Pandemic::City',
    builder  => '_start_city_builder',
);

has start_diseases => ( ro, auto_deref, lazy_build, isa=>'ArrayRef[Int]' );


# -- default builders / finishers


sub DEMOLISH {
    my $self = shift;
    debug( "~map: " . $self->name . "\n" );
}


sub _cities_builder {
    my $self = shift;

    my @cities;
    foreach my $d ( $self->_raw_cities ) {
        my ($name, $disid, $xreal, $yreal, $x, $y, $neighbours) = @$d;
        my $disease = $self->disease($disid);
        my $city = Games::Pandemic::City->new(
            id      => scalar(@cities),
            name    => $name,
            xreal   => $xreal,
            yreal   => $yreal,
            coordx  => $x,
            coordy  => $y,
            disease => $disease,
            _map    => $self,
            neighbour_ids => $neighbours,
        );
        push @cities, $city;
    }
    return \@cities;
}

sub _diseases_builder {
    my $self = shift;

    my @diseases;
    foreach my $d ( $self->_raw_diseases ) {
        my ($id, $name, $colors, $nb) = @$d;
        my $disease = Games::Pandemic::Disease->new(
            name   => $name,
            colors => $colors,
            nbmax  => $nb,
            id     => $id,
            _map   => $self,
        );
        push @diseases, $disease;
    }
    return \@diseases;
}


sub _start_city_builder {
    my $self = shift;
    my $id   = $self->_raw_start_city;
    my $city = $self->city($id);
    $city->build_station;
    return $city;
}


# -- public methods


sub background_path {
    my $self = shift;
    return catfile( $self->sharedir, 'background.jpg' );
}



sub sharedir {
    my $self = shift;
    return catdir( $SHAREDIR, 'maps', $self->name );
}



sub cards {
    my $self = shift;
    my @citycards =
        map { Games::Pandemic::Card::City->new(city=>$_) }
        $self->all_cities;
    my @special =
        map { my $class = "Games::Pandemic::Card::Special::$_"; $class->new }
        $self->_raw_special_cards;
    return (@citycards, @special);
}



sub disease_cards {
    my $self = shift;
    return
        map { Games::Pandemic::Card::City->new(city=>$_) }
        $self->all_cities;
}



sub find_city {
    my ($self, $name) = @_;
    return $self->_find_city( sub { $_[0]->name eq $name } );
}


sub infection_rates { die "should be implemented in child class."; }


no Moose;
__PACKAGE__->meta->make_immutable;

1;


=pod

=head1 NAME

Games::Pandemic::Map - pandemic map information

=head1 VERSION

version 1.120510

=head1 METHODS

=head2 my $bgpath = $map->background_path;

Return the path the background image of the map.

=head2 my $dir = $map->sharedir;

Return the path to the private directory C<$dir> where C<$map> stores
various files.

=head2 my @cards = $map->cards;

Return a list of C<Games::Pandemic::Card>: special event cards depending
on the map, plus one card per city defined in the map. They will be used
for the regular deck. Note that the cards will B<not> be shuffled.

=head2 my @cards = $map->disease_cards;

Return a list of C<Games::Pandemic::Card::City>, one per city defined in
the map. They will be used for the infection deck. Note that the cards
will B<not> be shuffled.

=head2 my $city = $map->find_city( $name );

=head2 my @rates = $map->infection_rates;

Return the infection rates. It's a list of numbers, which offset is the
number of epidemics already encountered.

=for Pod::Coverage DEMOLISH

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Jerome Quelin.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut


__END__

