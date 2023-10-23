#!/usr/bin/perl

use v5.14;
use warnings;

use Future::AsyncAwait;

use Test2::V0;
use Test::Future::IO;

use Device::Chip::Adapter::UART;

my $controller = Test::Future::IO->controller;

my $adapter = Device::Chip::Adapter::UART->new( fh => "DummyFH" );

{
   $controller->expect_syswrite( "DummyFH", "ABCD" );

   await $adapter->write( "ABCD" );

   $controller->check_and_clear( '$adapter->write' );
}

done_testing;
