#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use IO::Handle::Packable;

my $fh = IO::Handle::Packable->new;
$fh->open( \my $buffer, "<" );

sub _reset { ( $buffer ) = @_; $fh->seek( 0, 0 ) }

# basic unpack
{
   _reset "\x03\x04result";

   is_deeply( [ $fh->unpack( "c C a6" ) ],
      [ 3, 4, "result" ],
      '$fh->unpack receives values' );
}

# unpack with repeat count
{
   _reset "ABCD";

   is_deeply( [ $fh->unpack( "C4" ) ],
      [ 0x41, 0x42, 0x43, 0x44 ],
      '$fh->unpack understands repeat count' );
}

# unpack with endian
{
   _reset "defg";

   is_deeply( [ $fh->unpack( "I>" ) ],
      [ 0x64656667 ],
      '$fh->unpack understands endian specifiers' );
}

done_testing;
