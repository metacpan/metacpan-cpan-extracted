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

# Check that ->write uses Future::IO
{
   my $buf = "";

   no warnings 'redefine';
   local *Future::IO::syswrite_exactly = sub {
      $buf .= $_[2];
      return Future->done( length $_[2] );
   };

   $bp->write( "ABC" );

   is( $buf, "ABC", '->write uses Future::IO->syswrite_exactly' );
}

# Check that ->read uses Future::IO
{
   no warnings 'redefine';
   local *Future::IO::sysread_exactly = sub {
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
