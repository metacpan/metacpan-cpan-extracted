#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

# writes operate directly over UART so this is the easiest to unit test
use Device::Chip::NoritakeGU_D;

my $chip = Device::Chip::NoritakeGU_D->new( interface => "UART" );

$chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
)->get;

{
   $adapter->expect_write( "\x1F\x4B\x10" );
   $adapter->expect_read( 4 )
      ->returns( "\x10\x02\x00\x08" );

   my $switches = $chip->read_touchswitches->get;
   ok( $switches->{SW4}, 'SW4 indicates touch' );
   is( scalar keys %$switches, 16, 'All 16 keys report a value' );

   $adapter->check_and_clear( '$chip->read_touchswitches' );
}

done_testing;
