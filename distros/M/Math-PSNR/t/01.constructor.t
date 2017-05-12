#!perl

use strict;
use warnings;
use utf8;
use Math::PSNR;

BEGIN {
    use Test::Exception;
    use Test::More tests => 11;
}

my $psnr;

subtest 'Set bpp by constructor' => sub {
    $psnr = Math::PSNR->new(
        {
            bpp => 2,
            x   => [ 1, 2, 3, 4, 5 ],
            y   => [ 1, 2, 3, 4, 5 ],
        }
    );
    is( $psnr->bpp,       2, 'Is bpp set value' );
    is( $psnr->max_power, 3, 'Is max power right' );
};

subtest 'Set default bpp value' => sub {
    $psnr = Math::PSNR->new(
        {
            x => [ 1, 2, 3, 4, 5 ],
            y => [ 1, 2, 3, 4, 5 ],
        }
    );
    is( $psnr->bpp,       8,   'Is bpp default value' );
    is( $psnr->max_power, 255, 'Is max power default value' );
};

subtest 'Set bpp manually' => sub {
    $psnr->bpp(4);
    is( $psnr->max_power, 15, 'Is max power changed and right' );
};

subtest 'Not set x' => sub {
    dies_ok {
        Math::PSNR->new( { y => [ 1, 2, 3, 4, 5 ], } );
    }
    'Die cause of x was not set.';
};

subtest 'Not set y' => sub {
    dies_ok {
        Math::PSNR->new( { x => [ 1, 2, 3, 4, 5 ], } );
    }
    'Die cause of y was not set';
};

subtest 'Set illegal bpp' => sub {
    dies_ok { $psnr->bpp('foo') } 'Die cause of bpp is not integer';
};

subtest 'Set illegal max_power' => sub {
    dies_ok { $psnr->_set_max_power('bar') }
    'Die cause of max_power is not integer';
};

subtest 'Ignore setting max_power by constructor' => sub {
    $psnr = Math::PSNR->new(
        {
            bpp       => 2,
            x         => [ 1, 2, 3, 4, 5 ],
            y         => [ 1, 2, 3, 4, 5 ],
            max_power => 512,
        }
    );
    is( $psnr->max_power, 3,
        'Ignore setting max_power by constructor. It is not 512.' );
};

subtest 'Set illegal x' => sub {
    dies_ok { $psnr->x('foo') } 'Die cause of x is not hash or array';
};

subtest 'Set illegal y' => sub {
    dies_ok { $psnr->y('bar') } 'Die cause of y is not hash or array';
};

subtest 'Is not provided default setter' => sub {
    dies_ok { $psnr->max_power(1) };
};

done_testing;
