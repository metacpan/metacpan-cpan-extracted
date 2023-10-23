#!/usr/bin/perl

use v5.14;
use warnings;

use Future::AsyncAwait;

use Test2::V0;
use Test::Future::IO 0.05;

use Device::Chip::Adapter::UART;

my $controller = Test::Future::IO->controller;

my $adapter = Device::Chip::Adapter::UART->new( fh => "DummyFH" );
$controller->use_sysread_buffer( "DummyFH" )
   ->indefinitely;

{
   $controller->write_sysread_buffer( "DummyFH", "ABCD" );

   is( await $adapter->read( 4 ), "ABCD",
      '->read yields data' );

   $controller->check_and_clear( '$adapter->read' );
}

done_testing;
