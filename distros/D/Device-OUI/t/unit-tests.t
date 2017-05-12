#!/usr/bin/env perl
use strict; use warnings;
use Device::OUI;
use FindBin qw( $Bin );
use constant OUI => 'Device::OUI';
BEGIN { require "$Bin/device-oui-test-lib.pl" }

plan tests => 2;

OUI->search_url( 'test-url-%s' );
my $src = 'test-url-AA-BB-CC';
is( OUI->search_url_for( 'AA-BB-CC' ) => $src, "search_url_for AA-BB-CC" );
is( OUI->search_url_for( 'aa:bb:cc' ) => $src, "search_url_for aa:bb:cc" );
