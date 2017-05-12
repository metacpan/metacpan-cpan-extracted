#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More;

BEGIN{ use_ok( 'Math::FitRect', 'fit_rect', 'crop_rect' ) }

# fit_rect

is_deeply(
    fit_rect( 10 => 5 ),
    {w=>5, h=>5, x=>0, y=>0},
    'fit a larger square in to a smaller square',
);

is_deeply(
    fit_rect( 2 => 7 ),
    {w=>7, h=>7, x=>0, y=>0},
    'fit a smaller square in to a larger square',
);

is_deeply(
    fit_rect( [10,5] => [8,8] ),
    {w=>8, h=>4, x=>0, y=>2},
    'fit a larger rectangle in to a smaller rectangle',
);

is_deeply(
    fit_rect( [7,6] => [10,14] ),
    {w=>10, h=>9, x=>0, y=>3},
    'fit a smaller rectangle in to a larger rectangle',
);

# crop_rect

is_deeply(
    crop_rect( 10 => 5 ),
    {w=>5, h=>5, x=>0, y=>0},
    'crop a larger square in to a smaller square',
);

is_deeply(
    crop_rect( 2 => 7 ),
    {w=>7, h=>7, x=>0, y=>0},
    'crop a smaller square in to a larger square',
);

is_deeply(
    crop_rect( [10,5] => [8,8] ),
    {w=>16, h=>8, x=>-3, y=>0},
    'crop a larger rectangle in to a smaller rectangle',
);

is_deeply(
    crop_rect( [7,6] => [10,14] ),
    {w=>16, h=>14, x=>-2, y=>0},
    'crop a smaller rectangle in to a larger rectangle',
);

done_testing;
