#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Future::Buffer;

my $buf = Future::Buffer->new;

# multiple writes can be combined
{
   $buf->write( "abcd" );
   $buf->write( "efgh" );

   is( $buf->read_atmost( 8192 )->get, "abcdefgh",
      '->read_atmost after two ->writes' );
}

done_testing;
