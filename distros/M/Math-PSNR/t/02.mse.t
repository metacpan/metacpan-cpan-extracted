#!perl

use strict;
use warnings;
use utf8;
use Math::PSNR;

BEGIN {
    use Test::Exception;
    use Test::More tests => 6;
}

my ( $expect, $got );
my $psnr = Math::PSNR->new(
    {
        bpp => 8,
        x   => [ 1, 2, 3, 4, 5 ],
        y   => [ 1, 2, 3, 4, 5 ],
    }
);

subtest 'Calc MSE about the same arrays' => sub {
    $expect = 0;
    $got = $psnr->mse;
    is( $got, $expect );
};

subtest 'Calc MSE about the different arrays' => sub {
    $psnr->x( [ 1.1, 2.2, 3.3, 4.4, 5.5 ] );
    $psnr->y( [ 9.9, 8.8, 7.7, 6.6, 5.5 ] );
    $expect = 29.04;
    $got = $psnr->mse;
    is( sprintf( "%.2f", $got ), sprintf( "%.2f", $expect ) );
};

subtest 'Calc MSE between defferent length arrays - 1' => sub {
    $psnr->x( [ 1, 2, 3, 4, 5 ] );
    $psnr->y( [ 1, 2, 3 ] );
    dies_ok { $psnr->mse };
    throws_ok { $psnr->mse } qr/Signals must be the same length./;
};

subtest 'Calc MSE between defferent length arrays - 2' => sub {
    $psnr->x( [ 1, 2, 3 ] );
    $psnr->y( [ 1, 2, 3, 4, 5 ] );
    dies_ok { $psnr->mse };
    throws_ok { $psnr->mse } qr/Signals must be the same length./;
};

subtest 'Give hash reference to x' => sub {
    $psnr->x( { foo => 'test' } );
    dies_ok { $psnr->mse };
    throws_ok { $psnr->mse } qr/Signals must be array reference./;
};

subtest 'Give hash reference to y' => sub {
    $psnr->x( [ 1, 2, 3 ] );
    $psnr->y( { foo => 'test' } );
    dies_ok { $psnr->mse };
    throws_ok { $psnr->mse } qr/Signals must be array reference./;
};
done_testing;
