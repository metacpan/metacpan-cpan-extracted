#!/usr/bin/perl
use strict;
use warnings;
use Games::Tetris::Complete::Shape;
use Test::More;

my $shape = Games::Tetris::Complete::Shape->new(
    grid => [ ' +', '++', '+ ' ],
    ulx  => 1,
    uly  => 2,
);
isa_ok( $shape, 'Games::Tetris::Complete::Shape' );
is( $shape->char, '+', 'char' );
is( $shape->nx,   2,   'nx' );
is( $shape->ny,   3,   'ny' );

# Covered Points
my @covers = ( [ 2, 2 ], [ 3, 1 ], [ 3, 2 ], [ 4, 1 ] );
is_deeply( [ $shape->covered_points ], \@covers, 'covered_points' );
for my $y ( 0 .. 5 ) {
    for my $x ( 0 .. 5 ) {
        if ( grep { $y == $_->[ 0 ] and $x == $_->[ 1 ] } @covers ) {
            ok( $shape->covers( $y, $x ), "covers ($y,$x)" );
        }
        else {
            ok( !$shape->covers( $y, $x ), "not covers ($y,$x)" );
        }
    }
}

done_testing( 5 + 6 * 6 );
