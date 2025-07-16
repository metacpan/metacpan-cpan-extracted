#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use IO::Handle;

use Future::IO;

plan skip_all => "Cannot select() on pipes on Windows" if $^O eq "MSWin32";

# sleep + read IO ready
{
   pipe my ( $rd, $wr ) or die "Cannot pipe() - $!";

   $wr->autoflush();
   $wr->print( "BYTES" );

   my $f = Future->needs_any(
      Future::IO->read( $rd, 5 ),
      Future::IO->sleep( 2 ),
   );

   is( scalar $f->get, "BYTES", 'Future::IO ->sleep ->read concurrently yields bytes' );
}

# sleep + read timeout
{
   pipe my ( $rd, $wr ) or die "Cannot pipe() - $!";

   my $f = Future->needs_any(
      Future::IO->read( $rd, 5 ),
      Future::IO->sleep( 0.2 )->then_done( "timeout" ),
   );

   is( scalar $f->get, "timeout", 'Future::IO ->sleep ->read concurrently yields timeout' );
}

done_testing;
