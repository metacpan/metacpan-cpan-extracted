#!/usr/bin/perl

use strict;
use warnings;

use Test::Builder::Tester;
use Test::More;

use Future::AsyncAwait 0.47;

use Test::Device::Chip::Adapter;

my $adapter = Test::Device::Chip::Adapter->new;
my $uart = await $adapter->make_protocol( 'UART' );

ok( defined $uart, 'defined $uart' );

{
   test_out( qr/\s*# Subtest: ->write\n/ );
   test_out( "    ok 1 - ->write('ABC')" );
   test_out( "    1..1" );
   test_out( "ok 1 - ->write" );

   $adapter->expect_write( "ABC" );
   await $uart->write( "ABC" );
   $adapter->check_and_clear( '->write' );

   test_test( '->write' );
}

done_testing;
