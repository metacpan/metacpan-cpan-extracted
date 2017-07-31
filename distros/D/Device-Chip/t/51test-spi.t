#!/usr/bin/perl

use strict;
use warnings;

use Test::Builder::Tester;
use Test::More;

use Test::Device::Chip::Adapter;

my $adapter = Test::Device::Chip::Adapter->new;
my $spi = $adapter->make_protocol( 'SPI' )->get;

ok( defined $spi, 'defined $spi' );

{
   test_out( qr/\s*# Subtest: ->write\n/ );
   test_out( '    ok 1 - write' );
   test_out( '    1..1' );
   test_out( 'ok 1 - ->write' );

   $adapter->expect_write( "ABC" );
   $spi->write( "ABC" )->get;
   $adapter->check_and_clear( '->write' );

   test_test( '->write' );
}

{
   test_out( 'ok 1 - ->readwrite return' );
   test_out( qr/\s*# Subtest: ->readwrite\n/ );
   test_out( '    ok 1 - readwrite' );
   test_out( '    1..1' );
   test_out( 'ok 2 - ->readwrite' );

   $adapter->expect_readwrite( "ABC" )
      ->returns( "DEF" );
   is( $spi->readwrite( "ABC" )->get, "DEF", '->readwrite return' );
   $adapter->check_and_clear( '->readwrite' );

   test_test( '->readwrite' );
}

done_testing;
