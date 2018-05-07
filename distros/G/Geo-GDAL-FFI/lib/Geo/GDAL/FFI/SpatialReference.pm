package Geo::GDAL::FFI::SpatialReference;
use v5.10;
use strict;
use warnings;
use Carp;

our $VERSION = 0.04;

sub new {
    my ($class, $arg, @arg) = @_;
    my $sr;
    if (not defined $arg) {
        $sr = Geo::GDAL::FFI::OSRNewSpatialReference();
    } elsif (not @arg) {
        $sr = Geo::GDAL::FFI::OSRNewSpatialReference($arg);
    } else {
        $sr = Geo::GDAL::FFI::OSRNewSpatialReference();
        my $fake = Geo::GDAL::FFI->fake;
        $arg = $fake->get_importer($arg);
        if ($arg->($sr, @arg) != 0) {
            Geo::GDAL::FFI::OSRDestroySpatialReference($sr);
            $sr = 0;
        }
    }
    return bless \$sr, $class if $sr;
    confess Geo::GDAL::FFI::error_msg();
}

sub DESTROY {
    my $self = shift;
    Geo::GDAL::FFI::OSRDestroySpatialReference($$self);
}

sub Export {
    my $self = shift;
    my $format = shift;
    my $fake = Geo::GDAL::FFI->fake;
    my $exporter = $fake->get_exporter($format);
    my $x;
    if ($exporter->($$self, \$x, @_) != 0) {
        confess Geo::GDAL::FFI::error_msg();
    }
    return $x;
}

sub Set {
    my $self = shift;
    my $set = shift;
    my $fake = Geo::GDAL::FFI->fake;
    my $setter = $fake->get_setter($set);
    if ($setter->($$self, @_) != 0) {
        confess Geo::GDAL::FFI::error_msg();
    }
}

sub Clone {
    my $self = shift;
    my $s = Geo::GDAL::FFI::OSRClone($$self);
    return bless \$s, 'Geo::GDAL::FFI::SpatialReference';
}

1;

=pod

=encoding UTF-8

=head1 NAME

Geo::GDAL::FFI::SpatialReference - A spatial reference system in GDAL

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new

Create a new SpatialReference object. 

 my $sr = Geo::GDAL::FFI::SpatialReference->new('WKT here...');

If only one argument is given, it is taken as the well known text
(WKT) associated with the spatial reference system (SRS).

 my $sr = Geo::GDAL::FFI::SpatialReference->new(EPSG => 3067);

If there are more than one argument, the first argument is taken as a
format and the rest of the arguments are taken as arguments to the
format. The list of formats known to GDAL (at the time of this
writing) is EPSG, EPSGA, Wkt, Proj4, ESRI, PCI, USGS, XML, Dict,
Panorama, Ozi, MICoordSys, ERM, Url.

=head2 Export

 $sr->Export($format, @args);

Export a SpatialReference object to a format. The list of formats
known to GDAL (at the time of this writing) is Wkt, PrettyWkt, Proj4,
PCI, USGS, XML, Panorama, MICoordSys, ERM.

=head2 Set

 $sr->Set($proj, @args);

Set projection parameters in a SpatialReference object. The list of
projection parameters known to GDAL (at the time of this writing) is
Axes, ACEA, AE, Bonne, CEA, CS, EC, Eckert, EckertIV, EckertVI,
Equirectangular, Equirectangular2, GS, GH, IGH, GEOS,
GaussSchreiberTMercator, Gnomonic, HOM, HOMAC, HOM2PNO, IWMPolyconic,
Krovak, LAEA, LCC, LCC1SP, LCCB, MC, Mercator, Mercator2SP, Mollweide,
NZMG, OS, Orthographic, Polyconic, PS, Robinson, Sinusoidal,
Stereographic, SOC, TM, TMVariant, TMG, TMSO, TPED, VDG, Wagner, QSC,
SCH.

=head1 LICENSE

This software is released under the Artistic License. See
L<perlartistic>.

=head1 AUTHOR

Ari Jolma - Ari.Jolma at gmail.com

=head1 SEE ALSO

L<Geo::GDAL::FFI>

L<Alien::gdal>, L<FFI::Platypus>, L<http://www.gdal.org>

=cut

__END__;
