package GeoJSONTests;

use strict;
use warnings;

use Class::Load qw/ load_class /;
use JSON ();

my $json = JSON->new->pretty->canonical(1)->utf8;

my %DEFAULT_ARGS = (
    Point => { coordinates => [ 1, 2 ] },
    MultiPoint => { coordinates => [ [ 1, 2 ], [ 3, 4 ] ] },
    LineString => { coordinates => [ [ 1, 2 ], [ 3, 4 ] ] },
    MultiLineString =>
        { coordinates => [ [ [ 1, 2 ], [ 3, 4 ] ], [ [ 5, 6 ], [ 7, 8 ] ] ] },
    Polygon => {
        coordinates => [ [ [ 1, 2 ], [ 3, 4 ], [ 5, 6 ], [ 7, 8 ], [ 1, 2 ] ] ]
    },
    MultiPolygon => {
        coordinates => [
            [ [ [ 1, 2 ], [ 3, 4 ], [ 5, 6 ], [ 7, 8 ], [ 1, 2 ] ] ],
            [ [ [ 9, 8 ], [ 7, 6 ], [ 5, 4 ], [ 3, 2 ], [ 9, 8 ] ] ]
        ],
    },
    Feature => { geometry => { type => 'Point', coordinates => [ 1, 2 ] } },
    FeatureCollection => {
        features => [
            {   type     => 'Feature',
                geometry => { type => 'Point', coordinates => [ 1, 2 ] }
            },
            {   type     => 'Feature',
                geometry => {
                    type        => 'MultiPoint',
                    coordinates => [ [ 1, 2 ], [ 3, 4 ] ]
                }
            },
        ],
    },
    CRS => {
        type       => 'name',
        properties => { name => 'urn:ogc:def:crs:OGC:1.3:CRS84' }
    },
);

sub types { sort keys %DEFAULT_ARGS }

sub geometry_types {
    sort grep { $DEFAULT_ARGS{$_}->{coordinates} } keys %DEFAULT_ARGS;
}

sub json {
    my ( $class, $type, $args ) = @_;

    return $type eq 'CRS'
        ? $json->encode($args)
        : $json->encode( { type => $type, %{$args} } );
}

sub object {
    my ( $class, $type, $args ) = @_;

    my $object_class = 'Geo::JSON::' . $type;

    load_class $object_class;

    $args ||= $DEFAULT_ARGS{$type};

    my $construct_args = $type eq 'CRS' ? $args : { type => $type, %{$args} };

    return $object_class->new($construct_args);
}

sub tests {
    return (
        {   name  => 'Point, 2 dimensions',
            class => 'Point',
            args  => { coordinates => [ 1, 2 ] },
        },
        {   name  => 'Point, 3 dimensions',
            class => 'Point',
            args  => { coordinates => [ 1, 2, 3 ] },
        },
        {   name  => 'Point, lat/long floating points',
            class => 'Point',
            args  => { coordinates => [ 57.596278, -13.687306, 21.4 ] },
        },
        {   name  => 'Point, with extra dimensions (ignored)',
            class => 'Point',
            args => { coordinates => [ 57.596278, -13.687306, 21.4, 1, 2, 3 ] },
        },
        {   class => 'MultiPoint',
            args  => { coordinates => [ [ 1, 2, 3 ], [ 4, 5, 6 ] ] },
            compute_bbox => [ 1, 2, 3, 4, 5, 6 ],
        },
        {   class => 'LineString',
            args  => { coordinates => [ [ 1, 2, 3 ], [ 4, 5, 6 ] ] },
            compute_bbox => [ 1, 2, 3, 4, 5, 6 ],
        },
        {   class => 'MultiLineString',
            args  => {
                coordinates => [
                    [ [ 1, 2, 3 ], [ 4, 5, 6 ] ],    #
                    [ [ 7, 8, 9 ], [ 0, 0, 0 ] ]
                ]
            },
            compute_bbox => [ 0, 0, 0, 7, 8, 9 ],
        },
        {   class => 'Polygon',
            args  => {
                coordinates =>
                    [ [ [ 1, 2 ], [ 3, 4 ], [ 5, 6 ], [ 7, 8 ], [ 1, 2 ] ] ],
            },
            compute_bbox => [ 1, 2, 7, 8 ],
        },
        {   name  => 'Polygon with holes',
            class => 'Polygon',
            args  => {
                coordinates => [
                    [ [ 1, 1 ], [ 10, 1 ], [ 10, 10 ], [ 1, 10 ], [ 1, 1 ] ],
                    [ [ 5, 3 ], [ 5,  4 ], [ 4,  4 ],  [ 4, 3 ],  [ 5, 3 ] ],
                    [ [ 8, 8 ], [ 8,  9 ], [ 9,  9 ],  [ 9, 8 ],  [ 8, 8 ] ],
                ],
            },
            compute_bbox => [ 1, 1, 10, 10 ],
        },
        {   name  => 'Polygon with bbox',
            class => 'Polygon',
            args  => {
                bbox => [ 1, 2, 7, 8 ],
                coordinates =>
                    [ [ [ 1, 2 ], [ 3, 4 ], [ 5, 6 ], [ 7, 8 ], [ 1, 2 ] ] ],
            },
            compute_bbox => [ 1, 2, 7, 8 ],
        },
    );
}

1;

