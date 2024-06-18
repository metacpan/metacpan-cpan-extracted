#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 22;

use Test::Differences qw/ eq_or_diff /;

use Math::RNG::Microsoft        ();
use Math::RNG::Microsoft::FCPro ();

# TEST:FILTER(MULT(2))
foreach my $class ( 'Math::RNG::Microsoft', 'Math::RNG::Microsoft::FCPro', )
{
    {
        my $r = $class->new( seed => 1 );

        # TEST
        is( $r->rand(), 41, "First result for seed 1 is 41." );

        # TEST
        is( $r->rand(), 18_467, "2nd result for seed 1 is 18,467." );

        # TEST
        is( $r->rand(), 6_334, "3rd result for seed 1 is 6,334." );
    }

    {
        my $r = $class->new( seed => 24 );

        my @orig = ( 0 .. 9 );

        my $ret = scalar( $r->shuffle( scalar( \@orig ) ) );

        # TEST
        eq_or_diff(
            \@orig,
            [ 1, 7, 9, 8, 4, 5, 3, 2, 0, 6 ],
            'Array was shuffled.',
        );

        # TEST
        is( $ret, scalar( \@orig ), 'shuffle returns the same array.' );
    }

}

# TEST:ENDFILTER()

# TEST:FILTER(MULT(2))
foreach my $class ( 'Math::RNG::Microsoft', 'Math::RNG::Microsoft::FCPro', )
{
    {
        my $r = $class->new( seed => 1 );

        # TEST
        is( $r->rand(), 41, "First result for seed 1 is 41." );

        # TEST
        is( $r->rand(), 18_467, "2nd result for seed 1 is 18,467." );

        # TEST
        is( $r->rand(), 6_334, "3rd result for seed 1 is 6,334." );
    }

    {
        my $r = $class->new( seed => 24 );

        my @orig = ( 0 .. 9 );

        my $ret = scalar( $r->fresh_shuffle( \@orig ) );

        # TEST
        eq_or_diff(
            $ret,
            [ 1, 7, 9, 8, 4, 5, 3, 2, 0, 6 ],
            'Return was shuffled.',
        );

        # TEST
        isnt(
            $ret,
            scalar( \@orig ),
            'fresh_shuffle does not return the same array.'
        );

        # TEST
        eq_or_diff( scalar( \@orig ), [ 0 .. 9 ], 'orig was not shuffled.', );
    }

}

# TEST:ENDFILTER()
