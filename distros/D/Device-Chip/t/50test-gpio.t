#!/usr/bin/perl

use strict;
use warnings;

use Test::Builder::Tester;
use Test::More;

use Test::Device::Chip::Adapter;

my $adapter = Test::Device::Chip::Adapter->new;
my $gpio = $adapter->make_protocol( 'GPIO' )->get;

{
   test_out( '    # Subtest: ->write_gpios' );
   test_out( '    ok 1 - write_gpios' );
   test_out( '    1..1' );
   test_out( 'ok 1 - ->write_gpios' );

   $adapter->expect_write_gpios( { A => 1, B => 0 } );
   $gpio->write_gpios( { A => 1, B => 0 } )->get;
   $adapter->check_and_clear( '->write_gpios' );

   test_test( '->write_gpios' );
}

{
   test_out( 'ok 1 - ->read_gpios returns values' );
   test_out( '    # Subtest: ->read_gpios' );
   test_out( '    ok 1 - read_gpios' );
   test_out( '    1..1' );
   test_out( 'ok 2 - ->read_gpios' );

   $adapter->expect_read_gpios( [ 'A', 'B' ] )
      ->returns( { A => 1, B => 0 } );
   is_deeply( $gpio->read_gpios( [ 'A', 'B' ] )->get, { A => 1, B => 0 },
      '->read_gpios returns values' );
   $adapter->check_and_clear( '->read_gpios' );

   test_test( '->read_gpios' );
}

done_testing;
