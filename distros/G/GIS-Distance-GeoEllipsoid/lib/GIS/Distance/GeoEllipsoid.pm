package GIS::Distance::GeoEllipsoid;
use 5.008001;
use strictures 2;
our $VERSION = '0.13';

use parent 'GIS::Distance::Formula';

use Geo::Ellipsoid;
use namespace::clean;

my $ellipsoid_args = {
    ellipsoid      => 'WGS84',
    units          => 'degrees' ,
    distance_units => 'kilometer',
    longitude      => 0,
    bearing        => 0,
};

{
    my $default;

    sub _default_ellipsoid {
        $default ||= Geo::Ellipsoid->new( %$ellipsoid_args );
        return $default;
    }
}

sub BUILDARGS {
    my $class = shift;

    if (@_ == 1 and !ref($_[0])) {
        return {
            ellipsoid => Geo::Ellipsoid->new(
                %$ellipsoid_args,
                ellipsoid => $_[0],
            ),
        };
    }

    return $class->SUPER::BUILDARGS( @_ );
}

sub BUILD {
    my ($self) = @_;

    $self->{ellipsoid} ||= _default_ellipsoid();

    return;
}

sub _distance {
    my $self = $GIS::Distance::Formula::SELF;

    my $ellipsoid = $self ? $self->{ellipsoid} : _default_ellipsoid();

    return $ellipsoid->range( @_ );
}

1;
__END__

=encoding utf8

=head1 NAME

GIS::Distance::GeoEllipsoid - Geo::Ellipsoid distance calculations.

=head1 SYNOPSIS

    # Use the default WGS84 ellipsoid:
    my $gis = GIS::Distance->new( 'GeoEllipsoid' );
    
    # Set the ellipsoid:
    my $gis = GIS::Distance->new( 'GeoEllipsoid', 'NAD27' );

=head1 DESCRIPTION

This module is a wrapper around L<Geo::Ellipsoid> for L<GIS::Distance>.

Normally this module is not used directly.  Instead L<GIS::Distance>
is used which in turn interfaces with the various formula classes.

=head1 OPTIONAL ARGUMENTS

=head2 ellipsoid

    my $gis = GIS::Distance->new( 'GeoEllipsoid', 'NAD27' );

Pass the name of an ellipsoid, per L<Geo::Ellipsoid/DEFINED ELLIPSOIDS>.

If not set the default ellipsoid, C<WGS84>, will be used.

=head1 SUPPORT

Please submit bugs and feature requests to the
GIS-Distance-GeoEllipsoid GitHub issue tracker:

L<https://github.com/bluefeet/GIS-Distance-GeoEllipsoid/issues>

=head1 AUTHORS

    Aran Clary Deltac <bluefeet@gmail.com>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

