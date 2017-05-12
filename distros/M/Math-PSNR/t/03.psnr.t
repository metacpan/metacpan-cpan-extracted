#!perl

use strict;
use warnings;
use utf8;
use Math::PSNR;

BEGIN {
    use Test::Warn;
    use Test::More tests => 2;
}

my ( $expect, $got, $list1, $list2 );
my $psnr = Math::PSNR->new(
    {
        bpp => 8,
        x   => [ 1.1, 2.2, 3.3, 4.4, 5.5 ],
        y   => [ 9.9, 8.8, 7.7, 6.6, 5.5 ],
    }
);

subtest 'Calc PSNR between the different signals' => sub {
    $expect = 33.50083748;
    $got    = $psnr->psnr;
    is( sprintf( "%.7f", $got ), sprintf( "%.7f", $expect ) );
};

subtest 'Calc PSNR between the same allays.' => sub {
    $psnr->x( [ 1, 2, 3, 4 ] );
    $psnr->y( [ 1, 2, 3, 4 ] );
    $expect = 'same';

    warning_is { $got = $psnr->psnr }{ carped => 'Given signals are the same.' };
    is( $got, $expect );
};

done_testing();
