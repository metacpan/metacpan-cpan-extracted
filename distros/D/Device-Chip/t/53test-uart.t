#!/usr/bin/perl

use v5.26;
use warnings;

use Test::Builder::Tester;
use Test2::V0;

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

# uart read buffering
{
   test_out( "ok 1 - ->read future yields data" );
   test_out( qr/\s*# Subtest: ->read\n/ );
   test_out( "    ok 1 - No calls made" );
   test_out( "    1..1" );
   test_out( "ok 2 - ->read" );

   $adapter->use_read_buffer;

   my $f = $uart->read( 16 );
   $adapter->write_read_buffer( "here is the data" );
   is( await $f, "here is the data", '->read future yields data' );
   $adapter->check_and_clear( '->read' );

   test_test( '->read from buffer' );
}

done_testing;
