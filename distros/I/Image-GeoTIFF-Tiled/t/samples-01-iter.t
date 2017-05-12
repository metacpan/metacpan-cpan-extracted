#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 49;
use Image::GeoTIFF::Tiled;

for my $tiff ( <./t/samples/usgs*.tif> ) {
    my $image = Image::GeoTIFF::Tiled->new( $tiff );
    my $w     = $image->width;
    my $l     = $image->length;
    my $iter;

    # Outside image
    $iter = $image->get_iterator_pix( $w, $l, $w + 10, $l + 10 );
    is( $iter, undef, 'Boundary outside image' );

    my @bounds = (
        [ 0,  0,  10, 10 ],
        [ -1, 0,  10, 10 ],
        [ 0,  -1, 10, 10 ],
        [ -1, -1, 10, 10 ],
        [ 0,  0,  63, 63 ],
        [ 0,  0,  64, 64 ]
    );

    my $i1 = $image->get_iterator_pix( @{ $bounds[ 0 ] } );
    my $i2 = $image->get_iterator_pix( @{ $bounds[ 1 ] } );
    my $i3 = $image->get_iterator_pix( @{ $bounds[ 2 ] } );
    my $i4 = $image->get_iterator_pix( @{ $bounds[ 3 ] } );
#    $i1->dump_buffer;
    is( $i1->rows, $i2->rows, '2D data rows' );
    is( $i1->cols, $i2->cols, '2D data cols' );
    is_deeply( $i1->buffer, $i2->buffer, '2D data buffer' );
    is( $i1->rows, $i3->rows, '2D data rows' );
    is( $i1->cols, $i3->cols, '2D data cols' );
    is_deeply( $i1->buffer, $i3->buffer, '2D data buffer' );
    is( $i1->rows, $i4->rows, '2D data rows' );
    is( $i1->cols, $i4->cols, '2D data cols' );
    is_deeply( $i1->buffer, $i4->buffer, '2D data buffer' );
    is( $i2->rows, $i3->rows, '2D data rows' );
    is( $i2->cols, $i3->cols, '2D data cols' );
    is_deeply( $i2->buffer, $i3->buffer, '2D data buffer' );
    is( $i3->rows, $i4->rows, '2D data rows' );
    is( $i3->cols, $i4->cols, '2D data cols' );
    is_deeply( $i3->buffer, $i4->buffer, '2D data buffer' );

    my $i5 = $image->get_iterator_pix( @{ $bounds[ 4 ] } );
    my $i6 = $image->get_iterator_pix( @{ $bounds[ 5 ] } );
    #$i5->dump_buffer;
    #$i6->dump_buffer;
    ok( $i5->rows + 1 == $i6->rows, 'Iterator row diff' );
    ok( $i5->cols + 1 == $i6->cols, 'Iterator col diff' );

    is_deeply(
        $i5->buffer,
        [ map { [ @{ $_ }[ 0 .. 63 ] ] } @{ $i6->buffer }[ 0 .. 63 ] ],
        '2D buffer slice'
    );

    my ( $ok_b, $ok_n ) = ( 1, 1 );
    for my $r ( 0 .. $i5->rows - 1 ) {
        for my $c ( 0 .. $i5->cols - 1 ) {
            my ( $v1, $v2 ) =
                ( $i5->buffer->[ $r ][ $c ], $i6->buffer->[ $r ][ $c ] );
            $ok_b = 0 unless $v1 == $v2;
            $ok_n = 0 unless $i5->next == $v1;
        }
    }
    ok( $ok_b, '2D data buffer' );
    ok( $ok_n, 'next' );
    is( $i5->next, undef, 'next = undef' );

} ## end for my $tiff ( <./t/samples/usgs*.tif>)

{
    # Test adjacencies()
    my $buffer = [ [ 0 .. 2 ], [ 3 .. 5 ], [ 6 .. 8 ] ];
    my $i = Image::GeoTIFF::Tiled::Iterator->new( {
            boundary => [ 0, 0, 2, 2 ],
            buffer   => $buffer
        }
    );
    # local $Data::Dumper::Indent = 0;
    # print Dumper( $tile ), "\n";

    # (0,0)
    is( $i->next, 0, 'next' );
    is_deeply( [ $i->current_coord ], [ 0.5, 0.5 ], '0,0 coordinate' );
    is_deeply( [ $i->current_row, $i->current_col ], [ 0, 0 ], '0,0 row,col' );
    is_deeply(
        [ $i->adjacencies ],
        [
            undef, undef, undef,
            $buffer->[ 0 ][ 1 ],
            $buffer->[ 1 ][ 1 ],
            $buffer->[ 1 ][ 0 ],
            undef, undef
        ],
        'adjacencies - (0,0)'
    );

    # (1,1)
    $i->next until $i->current_row == 1 and $i->current_col == 1;
    is_deeply(
        [ $i->adjacencies ],
        [ 0, 1, 2, 5, 8, 7, 6, 3 ],
        'adjacencies - (1,1)'
    );
}
