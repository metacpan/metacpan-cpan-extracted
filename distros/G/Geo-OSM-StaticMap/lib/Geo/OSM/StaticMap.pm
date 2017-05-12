use 5.008;
use strict;
use warnings;

package Geo::OSM::StaticMap;
$Geo::OSM::StaticMap::VERSION = '0.4';
use List::Util qw(min);
use Moose;
use Math::Trig qw(:pi tan deg2rad rad2deg);
use Geo::Distance;

has 'baseurl' => (is => 'rw', isa => 'Str', default => 'http://staticmap.openstreetmap.de/staticmap.php' );
has 'center' => (is => 'rw', isa => 'ArrayRef', lazy => 1, builder => '_build_center', );
has 'zoom' => (is => 'rw', isa => 'Int', lazy => 1, builder => '_build_zoom', );
has 'size' => (is => 'rw', isa => 'ArrayRef', default => sub { [ 500, 350] } );
has 'markers' => (is => 'rw', isa => 'ArrayRef' );
has 'maptype' => (is => 'rw', isa => 'Str', default => 'mapnik' );
has '_radius' => (is => 'rw', isa => 'Num' );
has '_geodistance' => (is => 'rw', isa => 'Object', default => sub { Geo::Distance->new() } );

# ABSTRACT: Generate URLs to Open Street Map static maps

sub url {
    my ( $self, %args ) = @_;

    my $baseurl = $args{baseurl} || $self->baseurl();
    my $markers = $args{markers} || $self->markers();
    my $size    = $args{size}    || $self->size();
    my $maptype = $args{maptype} || $self->maptype();
    my $center  = $args{center}  || $self->center();
    my $zoom    = $args{zoom}    || $self->zoom();

    return sprintf('%s?center=%s&zoom=%s&size=%s&markers=%s&maptype=%s',
        $baseurl,
        join(',', @$center),
        $zoom,
        join('x', @$size),
        join('|', map { join(',', @$_) } @$markers),
        $maptype,
    );
}


sub _build_center {
    my $self = shift;

    my $markers = $self->markers();
    if ( defined $markers and ref $markers eq 'ARRAY' and @$markers > 0 ) {
        my (@lats,@lons);
        foreach my $marker ( @$markers ) {
            # Ignore geo codes in the blue see which look like they actually have
            # no real quality. Hope this will not be a blocker for someone...
            if ( $marker->[0] >= 0
                and $marker->[0] <= 0.9
                and $marker->[1] >= 0
                and $marker->[1] <= 0.9 ) {
                    next;
            }
            push (@lats, $marker->[0]);
            push (@lons, $marker->[1]);
        }
        my @sorted_lats = sort {$a <=> $b} @lats;
        my @sorted_lons = sort {$a <=> $b} @lons;

        # Roughly calculate a bounding box. We do not need to be geo exact here.
        my $sw = { lat => $sorted_lats[0], lon => $sorted_lons[0] };
        my $ne = { lat => $sorted_lats[-1], lon => $sorted_lons[-1] };

        my $midpoint = $self->_midpoint_to( $sw, $ne );

        # Calculate and store the radius of the virtual circle between center and outmost location
        $self->_radius( $self->_geodistance->distance( 'meter', $sw->{lon}, $sw->{lat} => $midpoint->{lon}, $midpoint->{lat} ) );

        $self->markers( $markers );

        return [ $midpoint->{lat}, $midpoint->{lon} ];
    }
    else {
        return [0, 0];
    }

}


sub _build_zoom {
    my $self = shift;

    # center() also calculates the radius which is required to calculate the zoom level
    $self->center();
    return 17 unless defined $self->_radius();

    my $size = $self->size();
    my $map_width_pixels = min($size->[0], $size->[1]);

    # See where we roughly fit
    # http://gis.stackexchange.com/questions/19632/how-to-calculate-the-optimal-zoom-level-to-display-two-or-more-points-on-a-map
    # OSM currently has 18 zoom levels...
    foreach my $zoomlevel ( reverse( 1..18 ) ) {
        my $dim = (256 * $self->_radius() * 2 / 40_000_000 * 2 ** $zoomlevel);
        if ( $dim < $map_width_pixels ) {
            return $zoomlevel;
        }
    }

    return 1;
}


sub _midpoint_to {
    my ($self, $point_one, $point_two) = @_;

    my $lat1 = deg2rad( $point_one->{lat} );
    my $lon1 = deg2rad( $point_one->{lon} );
    my $lat2 = deg2rad( $point_two->{lat} );
    my $dlon = deg2rad( $point_two->{lon} - $point_one->{lon} );

    my $bx = cos( $lat2 ) * cos( $dlon );
    my $by = cos( $lat2 ) * sin( $dlon );

    my $lat3 = atan2( sin( $lat1 ) + sin ( $lat2 ), sqrt( ( ( cos( $lat1 ) + $bx ) ** 2 ) + ( $by ** 2 ) ) );
    my $lon3 = $lon1 + atan2( $by, cos( $lat1 ) + $bx );
    $lon3 -= pi2 while( $lon3 > pi );
    $lon3 += pi2 while( $lon3 <= -(pi) );

    return { lat => rad2deg($lat3), lon => rad2deg($lon3) };
}


__PACKAGE__->meta->make_immutable( inline_constructor => 0 );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Geo::OSM::StaticMap - Generate URLs to Open Street Map static maps

=head1 VERSION

version 0.4

=head1 SYNOPSIS

    my $staticmap = Geo::OSM::StaticMap->new(
        center  => [ 48.213950, 16.336290 ], # lat, lon
        zoom    => 17,
        size    => [ 756, 476 ], # width, height
        markers => [ [ 48.213950, 16.336290, 'red-pushpin' ] ], # lat, lon, marker
        maptype => 'mapnik',
    );

    my $url = $staticmap->url();

    # Alternatively let center and zoom be calculated from markers
    my $staticmap_url = Geo::OSM::StaticMap->new(
        size    => [ 756, 476 ], # width, height
        markers => [ [ 51.8785011494, -0.3767887732, 'ol-marker' ],
                     [ 51.455313, -2.591902, 'ol-marker' ], ],
                     # lat, lon, marker
    )->url();

=head1 DESCRIPTION

Generate URLs for Open Street Map static maps. This is basically a simple
wrapper for staticMapLite L<http://staticmap.openstreetmap.de/>

Map center and zoom level will be (not very exactly) calculated from the coordinates
of markers given if center and zoom parameters are ommited.

If no markers are given, the center parameter will default to 0 lat, 0 lon which
very likely will not be what you need.

Consult L<http://staticmap.openstreetmap.de/> for a list of valid values for
markers and maptype.

=head1 METHODS

=head2 url

Returns URL string to fetch actual static map image via HTTP(S). All parameters
can also be passed to the constructor.

=head3 Parameters

=over

=item baseurl

Baseurl of the static map service. Defaults to L<http://staticmap.openstreetmap.de/>

=item markers

Array reference of array references of latitude and longitude pairs with a marker
specifier.

E.g.
    [ [ 51.8785011494, -0.3767887732, 'ol-marker' ],
      [ 51.455313, -2.591902, 'ol-marker' ], ]

See L<http://staticmap.openstreetmap.de/> for a list of valid values for markers.

=item size

Mapsize string. Width and height separated by 'x'

=item maptype

See L<http://staticmap.openstreetmap.de/> for a list of valid values. Defaults to
'mapnik'

=item center

Array reference to latitude and longitude pair. Will be calculated automatically
of ommited and markers have been given.

=item zoom

OSM zoom level. Will be calculated automatically of ommited and markers have been given.

=back

=head1 Private methods

=head2 _build_center

Builder for the center of the map. Defaults to [0,0] which is not useful in most cases.

Center will be calculated along the markers' bounding box if markers have been given.

=head2 _build_zoom

Builder for the OSM zoom level. Defaults to 17. If no center and no zoom parameters
but markers have been supplied, zoom level will be calculated along the markers'
bounding box

=head2 _midpoint_to

 $self->midpoint_to( { lat => $lat1, lon => $lon1 }, { lat => $lat2, lon => $lon2 } );

Returns the midpoint along a great circle path between the two points.

This function is more or less a copy of Geo::Calc::midpoint_to but without the
baggage the module dependencies of Geo::Calc are bringing in.

=head1 SEE ALSO

=over 4

=item L<Geo::Google::StaticMaps>

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Geo::OSM::StaticMap

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Geo-OSM-StaticMap>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Geo-OSM-StaticMap>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Geo-OSM-StaticMap>

=item * Search CPAN

L<http://search.cpan.org/dist/Geo-OSM-StaticMap>

=back

=head1 ACKNOWLEDGEMENTS

Midpoint calculation inspired by L<Geo::Calc>

=head1 AUTHOR

Michael Kröll <pepl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Michael Kröll.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
