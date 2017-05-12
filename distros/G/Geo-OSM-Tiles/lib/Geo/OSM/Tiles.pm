package Geo::OSM::Tiles;

use 5.006001;
use strict;
use warnings;
use Math::Trig;

=head1 NAME

Geo::OSM::Tiles - Calculate tile numbers for OpenStreetMap

=head1 SYNOPSIS

  use Geo::OSM::Tiles qw( :all );

  $zoom = 13;
  $lat = 49.60055;
  $lon = 11.01296;
  $tilex = lon2tilex($lon, $zoom);
  $tiley = lat2tiley($lat, $zoom);
  $path = tile2path($tilex, $tiley, $zoom);
  $tileurl = "http://tile.openstreetmap.org/$path";

=head1 DESCRIPTION

This module provides functions for calculating the path to a map tile
at OpenStreetMap out of geographic coordinates.  The path of a tile at
OSM has the form C<$zoom/$tilex/$tiley.png>.  The numbering scheme is
documented in the OSM wiki, see the link below.

=cut

require Exporter;

our $VERSION = '0.04';

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	lon2tilex lat2tiley tile2path
        checklonrange checklatrange
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

=head2 C<lon2tilex($lon, $zoom)>

Returns C<$tilex> for the tile at longitude C<$lon> and zoom level
C<$zoom>.  The longitude must be in the range C<-180.0 <= $lon < 180.0>.
The zoom level must be a non-negative integer.

=cut

sub lon2tilex
{
    my ($lon, $zoom) = @_;

    return int( ($lon+180)/360 * 2**$zoom );
}

=head2 C<lat2tiley($lat, $zoom)>

Returns C<$tiley> for the tile at latitude C<$lat> and zoom level
C<$zoom>.  The latitude must be in the range C<-85.0511 <= $lat <= 85.0511>.
The zoom level must be a non-negative integer.

=cut

sub lat2tiley
{
    my ($lat, $zoom) = @_;
    my $lata = $lat*pi/180;

    return int( (1 - log(tan($lata) + sec($lata))/pi)/2 * 2**$zoom );
}

=head2 C<tile2path($tilex, $tiley, $zoom)>

Composes the path to the tile at C<$tilex>, C<$tiley>, and C<$zoom> at
the OSM server.  C<$tilex> and C<$tiley> must be integers in the range
C<0..2**$zoom-1>.  The supported range of zoom levels depends on the
tile server.  The maximum zoom for the Osmarender layer is 17, it is
18 for the Mapnik layer.

=cut

sub tile2path
{
    my ($tilex, $tiley, $zoom) = @_;

    return "$zoom/$tilex/$tiley.png";
}

=head2 C<checklonrange($lonmin, $lonmax)>

Checks whether C<$lonmin> and C<$lonmax> are within the allowed range
of the longitude argument to C<lon2tilex>.  Returns
C<($lonmin, $lonmax)> unchanged if they are ok or corrected values if
not.

=cut

sub checklonrange
{
    my ($lonmin, $lonmax) = @_;

    # The bounds are choosen such that they give the correct results up
    # to zoom level 30 (zoom levels up to 18 actually make sense):
    # lon2tilex(-180.0, 30) == 0
    # lon2tilex(179.9999999, 30) == 1073741823 == 2**30 - 1
    $lonmin = -180.0 if $lonmin < -180.0;
    $lonmin = 179.9999999 if $lonmin > 179.9999999;
    $lonmax = -180.0 if $lonmax < -180.0;
    $lonmax = 179.9999999 if $lonmax > 179.9999999;

    return ($lonmin, $lonmax);
}

=head2 C<checklatrange($latmin, $latmax)>

Checks whether C<$latmin> and C<$latmax> are within the allowed range
of the latitude argument to C<lat2tiley>.  Returns
C<($latmin, $latmax)> unchanged if they are ok or corrected values if
not.

=cut

sub checklatrange
{
    my ($latmin, $latmax) = @_;

    # The bounds are choosen such that they give the correct results up
    # to zoom level 30 (zoom levels up to 18 actually make sense):
    # lat2tiley(85.0511287798, 30) == 0
    # lat2tiley(-85.0511287798, 30) == 1073741823 == 2**30 - 1
    $latmin = -85.0511287798 if $latmin < -85.0511287798;
    $latmin = 85.0511287798 if $latmin > 85.0511287798;
    $latmax = -85.0511287798 if $latmax < -85.0511287798;
    $latmax = 85.0511287798 if $latmax > 85.0511287798;

    return ($latmin, $latmax);
}

1;

__END__

=head1 SEE ALSO

L<http://wiki.openstreetmap.org/wiki/Slippy_map_tilenames>

=head1 AUTHOR

Rolf Krahl E<lt>rotkraut@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2008-2010 by Rolf Krahl

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
