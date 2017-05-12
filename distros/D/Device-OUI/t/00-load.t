#!/usr/bin/env perl
use strict; use warnings;
use Test::More tests => 5;
BEGIN { use_ok( 'Device::OUI' ) }
# This should be a dirt-simple test, it shouldn't try loading the
# device-oui-test-lib.pl file.

ok( my $one = Device::OUI->new( '00-17-F2' ), 'Created an object with an ID' );
isa_ok( $one, 'Device::OUI' );

ok( defined( my $two = Device::OUI->new ), 'Created an empty object' );
isa_ok( $two, 'Device::OUI' );
