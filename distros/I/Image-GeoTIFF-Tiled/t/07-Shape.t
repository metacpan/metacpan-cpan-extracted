#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
$Data::Dumper::Indent   = 0;
$Data::Dumper::Deepcopy = 1;
use Test::More tests => 33;
use Image::GeoTIFF::Tiled;
#use Image::GeoTIFF::Tiled::Shape;

# Local horizontal vertex
my %hv = (
    true =>
        [ [ [ 0, 1 ], [ 0, 0 ], [ 1, 1 ] ], [ [ 2, 2 ], [ 3, 3 ], [ 2, 2 ] ], ],
    false => [
        [ [ 0, 0 ], [ 1, 1 ], [ 2, 2 ] ],
        [ [ 1, 1 ], [ 1, 1 ], [ 2, 2 ] ],
        [ [ 2, 2 ], [ 1, 1 ], [ 0, 0 ] ]
    ]
);

for ( @{ $hv{ true } } ) {
    is( Image::GeoTIFF::Tiled::Shape::_local_hvertex( @{ $_ } ),
        1, 'local vertex' );
}
for ( @{ $hv{ false } } ) {
    is( Image::GeoTIFF::Tiled::Shape::_local_hvertex( @{ $_ } ),
        0, 'non-local vertex' );
}

# Test custom shapes
my $shape = {
    boundary => [ 0, 0, 2, 3 ],
    points => [ [ 0, 0 ], [ 0, 2 ], [ 1, 3 ], [ 2, 1 ], [ 0, 0 ] ],
    num_parts => 6,
    parts     => [
        [ [ 0, 0 ], [ 0, 2 ] ],
        [ [ 2, 1 ], [ 0, 0 ] ],
        [ [ 0, 0 ], [ 0, 0 ] ],
        [ [ 1, 3 ], [ 2, 1 ] ],
        [ [ 0, 2 ], [ 1, 3 ] ],
        [ [ 1, 3 ], [ 1, 3 ] ],
    ],
    get => [
        [ -1, [] ],
        [ 0,  [ 0, 1 ] ],
        [ 1,  [ 0, 1.75 ] ],
        [ 2,  [ 0.5, 1.25 ] ],
        [ 3,  [] ]
    ],
};
my @shapes = ( {
        %$shape,
        pixels =>
            [ 
                    [ 1,     undef, undef ],
                    [ 1,     1,     undef ],
                    [ 1,     undef, undef ],
                    [ undef, undef, undef ]
            ],
    },
    {
        %$shape,
        pixels =>
            [ 
                [ 5,     undef, undef ],
                [ 5,     5,     undef ],
                [ 5,     undef, undef ],
                [ undef, undef, undef ]
            ],
    },
);

for my $tiff ( <./t/samples/usgs*.tif> ) {
    my $image = Image::GeoTIFF::Tiled->new( $tiff );

    my $exp = shift @shapes;
    my ( $b, $p ) = ( $exp->{ boundary }, $exp->{ points } );
    my $s = Image::GeoTIFF::Tiled::Shape->new( {
            x_min => $b->[ 0 ],
            y_min => $b->[ 1 ],
            x_max => $b->[ 2 ],
            y_max => $b->[ 3 ]
        }
    );
    is( $s->x_min, $b->[ 0 ], 'x_min' );
    is( $s->y_min, $b->[ 1 ], 'y_min' );
    is( $s->x_max, $b->[ 2 ], 'x_max' );
    is( $s->y_max, $b->[ 3 ], 'y_max' );
    my @b = $s->boundary;
    is_deeply( \@b, $b, 'boundary' );
    my @c = $s->corners;
    my $c = [
        [ $b->[ 0 ], $b->[ 1 ] ],    # ul
        [ $b->[ 2 ], $b->[ 1 ] ],    # ur
        [ $b->[ 2 ], $b->[ 3 ] ],    # lr
        [ $b->[ 0 ], $b->[ 3 ] ],    # ll
    ];
    is_deeply( \@c, $c, 'corners' );
    # Points
    $s->add_point( @{ $_ } ) for @{ $p };
    $s->finish_loading;
    is( $s->num_parts, 6, 'number of parts' );
#    print( Dumper($s->as_array),"\n" );
    print( Dumper( $s->as_array ), "\n" )
        unless is_deeply( $s->as_array, $exp->{ parts }, 'parts' );
    for my $g ( @{ $exp->{ get } } ) {
        my $got = $s->get_x( $g->[ 0 ] );
        my $got_xs;
        is_deeply( $got, $g->[ 1 ], 'get_x' );
    }
    # Test when fed to TIFF
    my $iter = $image->get_iterator( $s );
    $iter->dump_buffer;
    is_deeply( $iter->buffer, $exp->{ pixels }, 'Iterator values' );

} ## end for my $tiff ( <./t/samples/usgs*.tif>)
