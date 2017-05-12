#!perl

use strict;
use warnings;
use utf8;
use Math::PSNR;

BEGIN {
    use Test::Warn;
    use Test::More tests => 2;
}

my $psnr = Math::PSNR->new(
    {
        bpp => 8,
        x   => {
            r => [ 1.1, 2.2, 3.3, 4.4, 5.5 ],
            g => [ 1.1, 2.2, 3.3, 4.4, 5.5 ],
            b => [ 1.1, 2.2, 3.3, 4.4, 5.5 ],
        },
        y => {
            r => [ 9.9, 8.8, 7.7, 6.6, 5.5 ],
            g => [ 9.9, 8.8, 7.7, 6.6, 5.5 ],
            b => [ 9.9, 8.8, 7.7, 6.6, 5.5 ],
        },
    }
);

my ($got, $expect);

subtest 'Calc PSNR (RGB) - 1' => sub {
    $got = $psnr->psnr_rgb;
    $expect = 33.50083748;
    is( sprintf( "%.7f", $got ), sprintf( "%.7f", $expect ));
};

subtest 'Calc PSNR (RGB) between the same hash.' => sub {
    $expect = 'same';
    $psnr->x(
        {
            r => [ 1, 2, 3, 4, 5 ],
            g => [ 1, 2, 3, 4, 5 ],
            b => [ 1, 2, 3, 4, 5 ],
        }
    );
    $psnr->y(
        {
            r => [ 1, 2, 3, 4, 5 ],
            g => [ 1, 2, 3, 4, 5 ],
            b => [ 1, 2, 3, 4, 5 ],
        }
    );
    warning_is {$got = $psnr->psnr_rgb}{ carped => 'Given signals are the same.'};
    is($got, $expect);
};

done_testing;
