#!perl

use strict;
use warnings;
use utf8;
use Math::PSNR;

BEGIN {
    use Test::Exception;
    use Test::More tests => 9;
}

my $psnr = Math::PSNR->new(
    {
        bpp => 8,
        x   => {
            r => [ 1, 2, 3, 4, 5 ],
            g => [ 1, 2, 3, 4, 5 ],
            b => [ 1, 2, 3, 4, 5 ],
        },
        y => {
            r => [ 1, 2, 3, 4, 5 ],
            g => [ 1, 2, 3, 4, 5 ],
            b => [ 1, 2, 3, 4, 5 ],
        },
    }
);

sub _tear_down {
    $psnr->x(
        {
            r => [ 1.1, 2.2, 3.3, 4.4, 5.5 ],
            g => [ 1.1, 2.2, 3.3, 4.4, 5.5 ],
            b => [ 1.1, 2.2, 3.3, 4.4, 5.5 ],
        }
    );
    $psnr->y(
        {
            r => [ 1.1, 2.2, 3.3, 4.4, 5.5 ],
            g => [ 1.1, 2.2, 3.3, 4.4, 5.5 ],
            b => [ 1.1, 2.2, 3.3, 4.4, 5.5 ],
        }
    );
}

my ( $expect, $got );

subtest 'Calc MSE (RGB) the same hash' => sub {
    $expect = 0;
    $got = $psnr->mse_rgb;
    is( $got, $expect );
};

subtest 'Calc MSE (RGB) the different hash' => sub {
    $psnr->x(
        {
            r => [ 1.1, 2.2, 3.3, 4.4, 5.5 ],
            g => [ 1.1, 2.2, 3.3, 4.4, 5.5 ],
            b => [ 1.1, 2.2, 3.3, 4.4, 5.5 ],
        }
    );
    $psnr->y(
        {
            r => [ 9.9, 8.8, 7.7, 6.6, 5.5 ],
            g => [ 9.9, 8.8, 7.7, 6.6, 5.5 ],
            b => [ 9.9, 8.8, 7.7, 6.6, 5.5 ],
        }
    );
    $got    = $psnr->mse_rgb;
    $expect = 29.04;
    is( $got, $expect );
};

subtest 'Give array as signal x' => sub {
    $psnr->x( [ 1.1, 2.2, 3.3, 4.4, 5.5 ] );
    dies_ok { $psnr->mse_rgb } 'Die cause of giving array to x';
    throws_ok { $psnr->mse_rgb } qr/Signals must be hash reference\./;
    _tear_down;
};

subtest 'Give array as signal y' => sub {
    $psnr->y( [ 1.1, 2.2, 3.3, 4.4, 5.5 ] );
    dies_ok { $psnr->mse_rgb };
    throws_ok { $psnr->mse_rgb } qr/Signals must be hash reference\./;
    _tear_down;
};

subtest 'Illegal hash about signal x' => sub {
    $psnr->x(
        {
            r => [ 1.1, 2.2, 3.3, 4.4 ],
            g => [ 1.1, 2.2, 3.3, 4.4, 5.5 ],
            b => [ 1.1, 2.2, 3.3, 4.4, 5.5 ],
        }
    );
    dies_ok { $psnr->mse_rgb };
    throws_ok { $psnr->mse_rgb }
qr/Each elements of signal must be the same length\. Please check out the length of 'r', 'g', and 'b' of signal x\./;

    $psnr->x(
        {
            r => [ 1.1, 2.2, 3.3, 4.4, 5.5 ],
            g => [ 1.1, 2.2, 3.3, 4.4 ],
            b => [ 1.1, 2.2, 3.3, 4.4, 5.5 ],
        }
    );
    dies_ok { $psnr->mse_rgb };
    throws_ok { $psnr->mse_rgb }
qr/Each elements of signal must be the same length\. Please check out the length of 'r', 'g', and 'b' of signal x\./;

    $psnr->x(
        {
            r => [ 1.1, 2.2, 3.3, 4.4, 5.5 ],
            g => [ 1.1, 2.2, 3.3, 4.4, 5.5 ],
            b => [ 1.1, 2.2, 3.3, 4.4 ],
        }
    );
    dies_ok { $psnr->mse_rgb };
    throws_ok { $psnr->mse_rgb }
qr/Each elements of signal must be the same length\. Please check out the length of 'r', 'g', and 'b' of signal x\./;

    $psnr->x(
        {
            r => 1,
            g => [ 1.1, 2.2, 3.3, 4.4, 5.5 ],
            b => [ 1.1, 2.2, 3.3, 4.4, 5.5 ],
        }
    );
    dies_ok { $psnr->mse_rgb };
    throws_ok { $psnr->mse_rgb } qr/Value of 'r' must be numerical array reference\./;

    $psnr->x(
        {
            r => [ 1.1, 2.2, 3.3, 4.4, 5.5 ],
            g => 1,
            b => [ 1.1, 2.2, 3.3, 4.4, 5.5 ],
        }
    );
    dies_ok { $psnr->mse_rgb };
    throws_ok { $psnr->mse_rgb } qr/Value of 'g' must be numerical array reference\./;

    $psnr->x(
        {
            r => [ 1.1, 2.2, 3.3, 4.4, 5.5 ],
            g => [ 1.1, 2.2, 3.3, 4.4, 5.5 ],
            b => 1,
        }
    );
    dies_ok { $psnr->mse_rgb };
    throws_ok { $psnr->mse_rgb } qr/Value of 'b' must be numerical array reference\./;

    _tear_down;
};

subtest 'Illegal hash about signal y' => sub {
    $psnr->y(
        {
            r => [ 1.1, 2.2, 3.3, 4.4 ],
            g => [ 1.1, 2.2, 3.3, 4.4, 5.5 ],
            b => [ 1.1, 2.2, 3.3, 4.4, 5.5 ],
        }
    );
    dies_ok { $psnr->mse_rgb };
    throws_ok { $psnr->mse_rgb }
qr/Each elements of signal must be the same length\. Please check out the length of 'r', 'g', and 'b' of signal y\./;

    $psnr->y(
        {
            r => [ 1.1, 2.2, 3.3, 4.4, 5.5 ],
            g => [ 1.1, 2.2, 3.3, 4.4 ],
            b => [ 1.1, 2.2, 3.3, 4.4, 5.5 ],
        }
    );
    dies_ok { $psnr->mse_rgb };
    throws_ok { $psnr->mse_rgb }
qr/Each elements of signal must be the same length\. Please check out the length of 'r', 'g', and 'b' of signal y\./;

    $psnr->y(
        {
            r => [ 1.1, 2.2, 3.3, 4.4, 5.5 ],
            g => [ 1.1, 2.2, 3.3, 4.4, 5.5 ],
            b => [ 1.1, 2.2, 3.3, 4.4 ],
        }
    );
    dies_ok { $psnr->mse_rgb };
    throws_ok { $psnr->mse_rgb }
qr/Each elements of signal must be the same length\. Please check out the length of 'r', 'g', and 'b' of signal y\./;

    $psnr->y(
        {
            r => 1,
            g => [ 1.1, 2.2, 3.3, 4.4, 5.5 ],
            b => [ 1.1, 2.2, 3.3, 4.4, 5.5 ],
        }
    );
    dies_ok { $psnr->mse_rgb };
    throws_ok { $psnr->mse_rgb } qr/Value of 'r' must be numerical array reference\./;

    $psnr->y(
        {
            r => [ 1.1, 2.2, 3.3, 4.4, 5.5 ],
            g => 1,
            b => [ 1.1, 2.2, 3.3, 4.4, 5.5 ],
        }
    );
    dies_ok { $psnr->mse_rgb };
    throws_ok { $psnr->mse_rgb } qr/Value of 'g' must be numerical array reference\./;

    $psnr->y(
        {
            r => [ 1.1, 2.2, 3.3, 4.4, 5.5 ],
            g => [ 1.1, 2.2, 3.3, 4.4, 5.5 ],
            b => 1,
        }
    );
    dies_ok { $psnr->mse_rgb };
    throws_ok { $psnr->mse_rgb } qr/Value of 'b' must be numerical array reference\./;

    _tear_down;
};

subtest 'Different signal length' => sub {
    $psnr->y(
        {
            r => [ 1.1, 2.2, 3.3 ],
            g => [ 1.1, 2.2, 3.3 ],
            b => [ 1.1, 2.2, 3.3 ],
        }
    );
    dies_ok { $psnr->mse_rgb };
    throws_ok { $psnr->mse_rgb }
    qr/Signal length are different between 'Signal x' and 'Signal y'\./;

    _tear_down;
};

subtest 'Incomplete hash about signal x' => sub {
    $psnr->x(
        {
            g => [ 1, 2, 3, 4, 5 ],
            b => [ 1, 2, 3, 4, 5 ],
        }
    );
    dies_ok { $psnr->mse_rgb };
    throws_ok { $psnr->mse_rgb } qr/Hash of signal must have key of 'r'\./;

    $psnr->x(
        {
            r => [ 1, 2, 3, 4, 5 ],
            b => [ 1, 2, 3, 4, 5 ],
        }
    );
    dies_ok { $psnr->mse_rgb };
    throws_ok { $psnr->mse_rgb } qr/Hash of signal must have key of 'g'\./;

    $psnr->x(
        {
            r => [ 1, 2, 3, 4, 5 ],
            g => [ 1, 2, 3, 4, 5 ],
        }
    );
    dies_ok { $psnr->mse_rgb };
    throws_ok { $psnr->mse_rgb } qr/Hash of signal must have key of 'b'\./;

    _tear_down;
};

subtest 'Incomplete hash about signal y' => sub {
    $psnr->y(
        {
            g => [ 1, 2, 3, 4, 5 ],
            b => [ 1, 2, 3, 4, 5 ],
        }
    );
    dies_ok { $psnr->mse_rgb };
    throws_ok { $psnr->mse_rgb } qr/Hash of signal must have key of 'r'\./;

    $psnr->y(
        {
            r => [ 1, 2, 3, 4, 5 ],
            b => [ 1, 2, 3, 4, 5 ],
        }
    );
    dies_ok { $psnr->mse_rgb };
    throws_ok { $psnr->mse_rgb } qr/Hash of signal must have key of 'g'\./;

    $psnr->y(
        {
            r => [ 1, 2, 3, 4, 5 ],
            g => [ 1, 2, 3, 4, 5 ],
        }
    );
    dies_ok { $psnr->mse_rgb };
    throws_ok { $psnr->mse_rgb } qr/Hash of signal must have key of 'b'\./;

    _tear_down;
};

done_testing;
