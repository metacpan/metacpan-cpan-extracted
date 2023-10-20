#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Future::Buffer;

my $buf = Future::Buffer->new;

# read_unpacked extracts data
{
   $buf->write( "\x01\x02\x03\x04" );

   my $f = $buf->read_unpacked( "C C S>" );
   ok( $f->is_ready, '->read_unpacked is ready' );
   is( [ $f->get ], [ 0x01, 0x02, 0x03*256 + 0x04 ],
      '->read_unpacked extracted packed data' );

   ok( $buf->is_empty, '$buf empty after read_unpacked' );
}

# There's probably a lot more we can test in here but ultimately we'd just
# be testing core's unpack() function and/or the code we copied from
# IO::Handle::Packable to interpret the length of a format upfront.

done_testing;
