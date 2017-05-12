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

package Games::Risk::Country;
# ABSTRACT: map country
$Games::Risk::Country::VERSION = '4.000';
use Hash::NoRef;
use List::AllUtils qw{ any };
use Moose;
use MooseX::Aliases;
use MooseX::Has::Sugar;
use MooseX::SemiAffordanceAccessor;

use Games::Risk::Logger qw{ debug };


# -- attributes


has name        => ( ro, isa=>'Str', required );
has continent   => ( ro, isa=>'Games::Risk::Continent', required, weak_ref );
has id          => ( ro, isa=>'Int', required, alias=>'greyval' );
has coordx      => ( ro, isa=>'Int', required );
has coordy      => ( ro, isa=>'Int', required );
has connections => ( ro, isa=>'ArrayRef[Int]', required, auto_deref );


has armies => ( rw, isa=>'Int' );
has owner  => ( rw, isa=>'Games::Risk::Player', weak_ref );




# a hash containing weak references (thanks Hash::NoRef) to prevent
# circular references to lock memory
has _neighbours => (
    ro, lazy_build,
    isa     =>'HashRef',
    traits  => [ 'Hash' ],
    handles => {
        neighbours   => 'values',
        is_neighbour => 'exists',
    },
);



# -- builders & finalizer

sub DEMOLISH { debug( "~country " . $_[0]->name ."\n" ); }

sub _build__neighbours {
    my $self = shift;
    my $map  = $self->continent->map;

    my %hash;
    tie %hash , 'Hash::NoRef';

    my @neighbours =
        map { $map->country_get($_) }
        $self->connections;
    @hash{ @neighbours } = @neighbours;

    return \%hash;
}



__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Games::Risk::Country - map country

=head1 VERSION

version 4.000

=head1 DESCRIPTION

This module implements a map country, with all its characteristics. The
word country is a bit loose, since for some maps it can be either a
region, a suburb... or a planet!  :-)

=head1 ATTRIBUTES

=head2 name

The country name.

=head2 continent

A L<Games::Risk::Continent> object in which the country is located.

=head2 greyval

An integer between 1 and 254 corresponding at the grey (all RGB values
set to C<greyval()>) used to draw the country on the grey-scale map.

=head2 id

Alias for C<greyval>.

=head2 coordx

The x location of the country capital.

=head2 coordy

The y location of the country capital.

=head2 connections

A list of country ids that can be accessed from the country. Note that
it's not always reciprocical (connections can be one-way).

=head2 owner

A C<Games::Risk::Player> object currently owning the country.

=head2 armies

Number of armies currently in the country.

=head1 METHODS

=head2 neighbours

    my @neighbours = $country->neighbours;

Return the list of C<$country>'s neighbours (L<Games::Risk::Country>
objects).

=head2 is_neighbour

    my $bool = $country->is_neighbour( $c );

Return true if C<$country> is a neighbour of country C<$c>, false
otherwise.

=for Pod::Coverage DEMOLISH

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2008 by Jerome Quelin.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
