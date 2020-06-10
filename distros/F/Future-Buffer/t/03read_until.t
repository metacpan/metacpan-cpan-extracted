#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Future::Buffer;

my $buf = Future::Buffer->new;

# read_until extracts data
{
   $buf->write( "ABCD" );

   my $f = $buf->read_until( "D" );
   ok( $f->is_ready, '->read_until("D") is ready' );
   is( $f->get, "ABCD", '->read_until("D") extracted data' );

   ok( $buf->is_empty, '$buf empty after read_until' );
}

# read_until waits for complete data
{
   my $f = $buf->read_until( "H" );
   ok( !$f->is_ready, '->read_until("H") while empty is not ready' );

   $buf->write( "EF" );
   ok( !$f->is_ready, '->read_until("H") while only at 2 is not ready' );

   $buf->write( "GH" );

   ok( $f->is_ready, '->read_until("H") ready after write 4' );
   is( $f->get, "EFGH", '->read_until("H") extracted data' );
}

done_testing;
