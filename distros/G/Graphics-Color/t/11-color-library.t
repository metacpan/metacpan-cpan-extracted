use strict;
use warnings;
use Test::More;

use Graphics::Color::RGB;

eval "use Color::Library";
plan skip_all => "Color::Library required for testing Color::Library support"
    if $@;

plan tests => 3;

my $rgb = Graphics::Color::RGB->from_color_library('svg:blue');
cmp_ok($rgb->red, '==', 0, 'red');
cmp_ok($rgb->green, '==', 0, 'green');
cmp_ok($rgb->blue, '==', 1, 'blue');


