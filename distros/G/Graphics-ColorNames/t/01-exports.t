#!/usr/bin/perl

use Test::Most;

use lib 't/lib';

use_ok( 'Graphics::ColorNames', qw/ all_schemes hex2tuple tuple2hex / );

ok my @schemes = all_schemes(), 'all_schemes';

cmp_deeply( \@schemes, supersetof(qw/ X Test /), 'minimum set of schemes' );

is_deeply [ hex2tuple('010203') ], [ 1, 2, 3 ], 'hex2tuple';

is_deeply [ hex2tuple('ffeedd') ], [ 255, 238, 221 ], 'hex2tuple';

is tuple2hex( 1, 2, 3 ) => '010203', 'tuple2hex';

is tuple2hex( 255, 238, 221 ) => 'ffeedd', 'tuple2hex';

done_testing;
