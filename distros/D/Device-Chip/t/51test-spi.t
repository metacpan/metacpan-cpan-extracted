#!/usr/bin/perl

use v5.26;
use warnings;

use Test::Builder::Tester;
use Test2::V0;

use Future::AsyncAwait 0.47;

use Test::Device::Chip::Adapter;

my $adapter = Test::Device::Chip::Adapter->new;
my $spi = await $adapter->make_protocol( 'SPI' );

ok( defined $spi, 'defined $spi' );

{
   test_out( qr/\s*# Subtest: ->write\n/ );
   test_out( "    ok 1 - ->write('ABC')" );
   test_out( "    1..1" );
   test_out( "ok 1 - ->write" );

   $adapter->expect_write( "ABC" );
   await $spi->write( "ABC" );
   $adapter->check_and_clear( '->write' );

   test_test( '->write' );
}

{
   test_out( "ok 1 - ->readwrite return" );
   test_out( qr/\s*# Subtest: ->readwrite\n/ );
   test_out( "    ok 1 - ->readwrite('ABC')" );
   test_out( "    1..1" );
   test_out( "ok 2 - ->readwrite" );

   $adapter->expect_readwrite( "ABC" )
      ->will_done( "DEF" );
   is( await $spi->readwrite( "ABC" ), "DEF", '->readwrite return' );
   $adapter->check_and_clear( '->readwrite' );

   test_test( '->readwrite' );
}

done_testing;
