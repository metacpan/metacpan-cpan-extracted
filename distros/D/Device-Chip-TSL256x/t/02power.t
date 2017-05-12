#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Device::Chip::TSL256x;

my $chip = Device::Chip::TSL256x->new;

$chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
)->get;

{
   $adapter->expect_write( "\x80\x03" );

   $chip->power(1)->get;

   $adapter->check_and_clear( '$chip->power' );
}

done_testing;
