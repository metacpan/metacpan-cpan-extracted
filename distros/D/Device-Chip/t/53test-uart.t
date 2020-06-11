#!/usr/bin/perl

use strict;
use warnings;

use Test::Builder::Tester;
use Test::More;

use Test::Device::Chip::Adapter;

my $adapter = Test::Device::Chip::Adapter->new;
my $uart = $adapter->make_protocol( 'UART' )->get;

ok( defined $uart, 'defined $uart' );

{
   test_out( qr/\s*# Subtest: ->write\n/ );
   test_out( '    ok 1 - write' );
   test_out( '    1..1' );
   test_out( 'ok 1 - ->write' );

   $adapter->expect_write( "ABC" );
   $uart->write( "ABC" )->get;
   $adapter->check_and_clear( '->write' );

   test_test( '->write' );
}

done_testing;
