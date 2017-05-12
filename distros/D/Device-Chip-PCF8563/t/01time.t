#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Device::Chip::PCF8563;

my $chip = Device::Chip::PCF8563->new;

$chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
)->get;


# ->write_time
{
   $adapter->expect_write( "\x02" . "\x10\x11\x12\x15\x00\x02\x14" );

   $chip->write_time( 10, 11, 12, 15, 2-1, 2014-1900, 0 )->get;

   $adapter->check_and_clear( '$chip->write_time' );
}

# ->read_time
{
   $adapter->expect_write_then_read( "\x02", 7 )
      # chip sometimes returns junk bits as 1s
      ->returns( "\x10\x11\x92\x15\x40\x02\x14" );

   is_deeply( [ $chip->read_time->get ], [ 10, 11, 12, 15, 2-1, 2014-1900, 0 ],
      '$chip->read_time returns time' );

   $adapter->check_and_clear( '$chip->read_time' );
}

done_testing;
