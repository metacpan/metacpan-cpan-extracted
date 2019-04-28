#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use IO::Handle;

use Future::IO;

# ->syswrite_exactly writing bytes
{
   pipe my ( $rd, $wr ) or die "Cannot pipe() - $!";

   my $f = Future::IO->syswrite_exactly( $wr, "ABC" );

   my @written;
   no warnings 'redefine';
   local *IO::Handle::syswrite = sub {
      my ( $fh, $bytes ) = @_;
      push @written, $bytes;
      return CORE::syswrite( $fh, substr $bytes, 0, 1 );
   };

   is( scalar $f->get, 3, 'Future::IO->syswrite_exactly eventually writes all bytes' );

   is_deeply( \@written, [ "ABC", "BC", "C" ], 'IO::Handle->syswrite override worked' );

   $rd->read( my $buf, 3 );
   is( $buf, "ABC", 'Future::IO->syswrite_exactly wrote bytes' );
}

done_testing;
