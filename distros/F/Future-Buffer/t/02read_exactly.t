#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Future::Buffer;

my $buf = Future::Buffer->new;

# read_exactly extracts data
{
   $buf->write( "ABCD" );

   my $f = $buf->read_exactly( 4 );
   ok( $f->is_ready, '->read_exactly(4) is ready' );
   is( $f->get, "ABCD", '->read_exactly(4) extracted data' );

   ok( $buf->is_empty, '$buf empty after read_exactly' );
}

# read_exactly waits for complete data
{
   my $f = $buf->read_exactly( 4 );
   ok( !$f->is_ready, '->read_exactly(4) while empty is not ready' );

   $buf->write( "EF" );
   ok( !$f->is_ready, '->read_exactly(4) while only at 2 is not ready' );

   $buf->write( "GH" );

   ok( $f->is_ready, '->read_exactly(4) ready after write 4' );
   is( $f->get, "EFGH", '->read_exactly(4) extracted data' );
}

done_testing;
