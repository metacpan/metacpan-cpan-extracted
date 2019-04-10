#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use IO::Handle;

use Future::IO;

plan skip_all => "Cannot select() on pipes on Windows" if $^O eq "MSWin32";

# sleep + sysread IO ready
{
   pipe my ( $rd, $wr ) or die "Cannot pipe() - $!";

   $wr->autoflush();
   $wr->print( "BYTES" );

   my $f = Future->needs_any(
      Future::IO->sysread( $rd, 5 ),
      Future::IO->sleep( 2 ),
   );

   is( scalar $f->get, "BYTES", 'Future::IO ->sleep ->sysread concurrently yields bytes' );
}

# sleep + sysread timeout
{
   pipe my ( $rd, $wr ) or die "Cannot pipe() - $!";

   my $f = Future->needs_any(
      Future::IO->sysread( $rd, 5 ),
      Future::IO->sleep( 0.2 )->then_done( "timeout" ),
   );

   is( scalar $f->get, "timeout", 'Future::IO ->sleep ->sysread concurrently yields timeout' );
}

done_testing;
