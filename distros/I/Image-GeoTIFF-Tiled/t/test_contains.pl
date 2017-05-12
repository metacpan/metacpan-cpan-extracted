#!/usr/bin/perl
use strict;
use warnings;

# require this file

sub test_contains {
    my ( $image, $iter, $shp_shape, $proj ) = @_;
    unless ( defined $iter ) {
        fail( 'Iterator undefined' );
        return;
    }
    # Test that each "next" shape pixel is in fact in the shape
    my $fail  = 0;
    my $total = 0;
    my $success;
    while ( defined( my $val = $iter->next ) ) {
        my ( $px, $py ) = $iter->current_coord;
        my ( $x, $y ) =
            map sprintf( "%.6f", $_ ), $image->pix2proj( $px, $py );
        # printf "Testing shape pixel (%.2f,%.2f) (%.2f,%.2f)\n",$px,$py,$x,$y;

        if ( defined $proj ) {
            ( $y, $x ) = $proj->inverse( $x, $y );
        }
        unless (
            $shp_shape->contains_point(
                Geo::ShapeFile::Point->new( X => $x, Y => $y )
            )
            )
        {
            $fail++;
            warn
                sprintf( "Failure at (%.2f,%.2f) - not in shape.\n", $px, $py );
        }
        $total++;
    }
    $success = ( $total - $fail ) / $total;
    ok(
        $success >= 0.99,
        "Geo::ShapeFile::Shape contains agrees with iterator ("
            . sprintf( "%.3f%%", $success * 100 )
            . " success rate)"
      );

# Reverse the buffer values and test the null values are in fact outside the shape
    my @old_buffer = @{ $iter->buffer };
    my $evil_buffer;
    for my $i ( 0 .. @{ $iter->buffer } - 1 ) {
        for my $j ( 0 .. @{ $iter->buffer->[ $i ] } - 1 ) {
            my $val = $iter->buffer->[ $i ][ $j ];
            $evil_buffer->[ $i ][ $j ] =
                # $val == -1 ? 1 : -1;
                defined $val ? undef : 1;
        }
    }
#    print Dumper(\@old_buffer), "\n", Dumper($evil_buffer),"\n";
    $iter->reset;
    $iter->{ buffer } = $evil_buffer;
    $fail             = 0;
    $total            = 0;
    # print "Testing inverted buffer.\n";
    while ( defined( my $val = $iter->next ) ) {
        my ( $x, $y ) =
            map { sprintf( "%.6f", $_ ) }
            $image->pix2proj( $iter->current_coord );
        if ( defined $proj ) {
            ( $y, $x ) = $proj->inverse( $x, $y );
        }
        unless (
            !$shp_shape->contains_point(
                Geo::ShapeFile::Point->new( X => $x, Y => $y )
            )
            )
        {
            $fail = 1;
            # warn "Failure at ($x,$y)";
            warn sprintf( "Failure at (%.2f,%.2f) - in shape.\n",
                $image->proj2pix( $x, $y ) );
        }
        $total++;
    }
    $success = ( $total - $fail ) / $total;
    ok(
        $success >= 0.99,
        "Geo::ShapeFile::Shape contains agrees with iterator ("
            . sprintf( "%.3f%%", $success * 100 )
            . " success rate)"
      );

    $iter->reset;
    $iter->{ buffer } = \@old_buffer;
} ## end sub test_contains

1;
