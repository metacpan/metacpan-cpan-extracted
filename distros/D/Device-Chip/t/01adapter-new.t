#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Device::Chip::Adapter;

{
   package Device::Chip::Adapter::ForTesting;
   # Cheat
   $INC{"Device/Chip/Adapter/ForTesting.pm"} = __FILE__;

   sub new_from_description
   {
      return [ @_ ];
   }
}

is_deeply(
   Device::Chip::Adapter->new_from_description( "ForTesting" ),
   [ "Device::Chip::Adapter::ForTesting" ],
   'Optionless constructor' );

is_deeply(
   Device::Chip::Adapter->new_from_description( "ForTesting:" ),
   [ "Device::Chip::Adapter::ForTesting" ],
   'Optionless constructor with colon' );

is_deeply(
   Device::Chip::Adapter->new_from_description( "ForTesting:one=1,two=2" ),
   [ "Device::Chip::Adapter::ForTesting", one => 1, two => 2 ],
   'Constructor with options' );

is_deeply(
   Device::Chip::Adapter->new_from_description( "ForTesting:yes,no=0" ),
   [ "Device::Chip::Adapter::ForTesting", yes => 1, no => 0 ],
   'Constructor with options' );

done_testing();
