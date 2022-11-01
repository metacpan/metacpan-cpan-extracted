#!/usr/bin/perl -w
use strict;
BEGIN { 
    unshift @INC, 'lib';
};

use Test::More tests => 5784 + 10;
use Test::NoWarnings;

eval "use Graphics::ColorNames 0.20, qw( hex2tuple tuple2hex )";
ok( not $@ );
tie my %colors, 'Graphics::ColorNames', 'GrayScale';
ok(1);
is(keys %colors, 5784);

for my $name (keys %colors) {
    my @RGB = hex2tuple( $colors{$name} );
    is(tuple2hex(@RGB), $colors{$name} );
}

is( uc $colors{'gray123'},  '7B7B7B');
is( uc $colors{'greybb'},   'BBBBBB');
is( uc $colors{'grey50%'},  '7F7F7F');
is( uc $colors{'blue50%'},  '00007F');
is( uc $colors{'yellow10'}, '101000');
is( uc $colors{'purple110'},'6E006E');

exit (0);
