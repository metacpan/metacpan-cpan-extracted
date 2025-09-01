#!/usr/bin/perl -w
use strict;
BEGIN {
    unshift @INC, 'lib'
};

use Test::More tests => 242 + 6;
use Test::NoWarnings;

eval "use Graphics::ColorNames 0.20, qw( hex2tuple tuple2hex )";
ok( not $@ );
tie my %colors, 'Graphics::ColorNames', 'PantoneReport';
is(keys %colors, 242, 'all colors are there');

for my $name (keys %colors) {
    my @RGB = hex2tuple( $colors{$name} );
    is(tuple2hex(@RGB), $colors{$name}, $name);
}

is(uc $colors{'blue_izis'},  '5B5EA6', 'checked blue izis value');
is(uc $colors{'blue_stone'}, '577284', 'checked blue stone value');
is(uc $colors{'eden'},       '264E36', 'checked eden value');

exit (0);

