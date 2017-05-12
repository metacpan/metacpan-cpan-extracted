package GIS::Distance::Formula::GeoEllipsoid;
$GIS::Distance::Formula::GeoEllipsoid::VERSION = '0.09';
=head1 NAME

GIS::Distance::Formula::GeoEllipsoid - Geo::Ellipsoid distance calculations.

=head1 SYNOPSIS

  my $gis = GIS::Distance->new();
  
  $gis->formula( 'GeoEllipsoid', { ellipsoid => 'WGS84' } );

=head1 DESCRIPTION

This module is a wrapper around L<Geo::Ellipsoid> for
L<GIS::Distance>.

Normally this module is not used directly.  Instead L<GIS::Distance>
is used which in turn interfaces with the various formula classes.

=head1 FORMULA

See the documentation for L<Geo::Ellipsoid>.

=cut

use Types::Standard -types;
use Type::Utils -all;
use Class::Measure::Length qw( length );
use Geo::Ellipsoid;

use Moo;
use strictures 1;
use namespace::clean;

with 'GIS::Distance::Formula';

=head1 ATTRIBUTES

=head2 ellipsoid

  $calc->ellipsoid( 'AIRY' );

Set and retrieve the ellipsoid object.  If a string is passed
then it will be coerced into an object.

=cut

my $ellipsoid_type = declare 'GeoEllipsoid',
    as InstanceOf[ 'Geo::Ellipsoid' ];

coerce $ellipsoid_type,
    from Str,
    via {
        return Geo::Ellipsoid->new(
            units     => 'degrees',
            ellipsoid => $_,
        );
    };

has ellipsoid => (
    is      => 'rw',
    isa     => $ellipsoid_type,
    coerce  => 1,
    default => sub{ Geo::Ellipsoid->new( units=>'degrees' ) },
);

=head1 METHODS

=head2 distance

This method is called by L<GIS::Distance>'s distance() method.

=cut

sub distance {
    my $self = shift;

    return length(
        $self->ellipsoid->range( @_ ),
        'm'
    );
}

1;
__END__

=head1 SEE ALSO

L<GIS::Distanc>

L<Geo::Ellipsoid>

=head1 AUTHOR

Aran Clary Deltac <bluefeet@cpan.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

