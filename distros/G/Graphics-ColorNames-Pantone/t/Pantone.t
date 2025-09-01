#!/usr/bin/perl -w
use strict;
BEGIN { 
    unshift @INC, 'lib';
};

use Test::More tests => 1091 + 7;
use Test::NoWarnings;

eval "use Graphics::ColorNames 0.20, qw( hex2tuple tuple2hex )";
ok( not $@ );
tie my %colors, 'Graphics::ColorNames', 'Pantone';
ok(1);
is(keys %colors, 1091);

for my $name (keys %colors) {
    my @RGB = hex2tuple( $colors{$name} );
    is(tuple2hex(@RGB), $colors{$name} );
}

is( uc $colors{'100'},     'FFFF7D');
is( uc $colors{'251'},     'DE9CFF');
is( uc $colors{'8142x'},   '3047FF');

exit (0);
