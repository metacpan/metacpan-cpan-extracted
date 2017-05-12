#!/usr/bin/env perl
use strict; use warnings;
use FindBin qw( $Bin );
BEGIN { require "$Bin/device-oui-test-lib.pl" }
use constant one => "$Bin/test-one.txt";

if ( $ENV{ 'ONLINE_TESTS' } ) {
    plan tests => 5;
} else {
    plan skip_all => 'Set ONLINE_TESTS to run the live network tests';
}

rm( one );
ok( Device::OUI->cache_file( one ), "set cache file one" );
is( Device::OUI->cache_file, one, "cache file one set ok" );
is( Device::OUI->mirror_file, 1, "mirror succeeded for one" );
is( Device::OUI->mirror_file, 0, "mirror indicated no changes" );
ok(1, 'foo' );
