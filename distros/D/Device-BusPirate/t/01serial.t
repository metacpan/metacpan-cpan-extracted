#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Device::BusPirate;
use lib "t/lib";
use TestBusPirate;

my $bp = Device::BusPirate->new(
   fh => [], # unused
);

# Check that ->write uses ->_syswrite
{
   my $buf = "";

   no warnings 'redefine';
   local *Device::BusPirate::_syswrite = sub {
      $buf .= $_[2];
   };

   $bp->write( "ABC" );

   is( $buf, "ABC", '->write invokes _syswrite' );
}

# Check that ->read uses Future::IO
{
   no warnings 'redefine';
   local *Future::IO::sysread = sub {
      return Future->done( "DEF" );
   };

   is( $bp->read( 3, "read uses Future::IO->sysread" )->get, "DEF",
      'result of ->read' );
}

# write
{
   expect_write "GHI";

   $bp->write( "GHI" );

   check_and_clear '->write';
}

# read
{
   expect_read "JKL";

   is( $bp->read( 3 )->get, "JKL",
      'result of ->read' );

   check_and_clear '->read';
}

done_testing;
