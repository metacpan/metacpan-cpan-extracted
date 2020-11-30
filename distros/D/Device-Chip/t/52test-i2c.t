#!/usr/bin/perl

use strict;
use warnings;

use Test::Builder::Tester;
use Test::More;

use Test::Device::Chip::Adapter;

my $adapter = Test::Device::Chip::Adapter->new;
my $i2c = $adapter->make_protocol( 'I2C' )->get;

ok( defined $i2c, 'defined $i2c' );

{
   test_out( qr/\s*# Subtest: ->write\n/ );
   test_out( "    ok 1 - ->write('ABC')" );
   test_out( "    1..1" );
   test_out( "ok 1 - ->write" );

   $adapter->expect_write( "ABC" );
   $i2c->write( "ABC" )->get;
   $adapter->check_and_clear( '->write' );

   test_test( '->write' );
}

{
   test_out( "ok 1 - ->write_then_read return" );
   test_out( qr/\s*# Subtest: ->write_then_read\n/ );
   test_out( "    ok 1 - ->write_then_read('ABC', 3)" );
   test_out( "    1..1" );
   test_out( "ok 2 - ->write_then_read" );

   $adapter->expect_write_then_read( "ABC", 3 )
      ->returns( "DEF" );
   is( $i2c->write_then_read( "ABC", 3 )->get, "DEF", '->write_then_read return' );
   $adapter->check_and_clear( '->write_then_read' );

   test_test( '->write_then_read' );
}

done_testing;
