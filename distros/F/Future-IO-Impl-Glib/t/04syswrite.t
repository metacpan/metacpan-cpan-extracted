#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Errno qw( EINVAL EPIPE );
use IO::Handle;

use Future::IO;
use Future::IO::Impl::Glib;

my $errstr_EPIPE = do {
   # On MSWin32 we don't get EPIPE, but EINVAL
   local $! = $^O eq "MSWin32" ? EINVAL : EPIPE; "$!";
};

# ->syswrite success
{
   pipe my ( $rd, $wr ) or die "Cannot pipe() - $!";
   $wr->blocking( 0 );

   # Attempt to fill the pipe
   $wr->syswrite( "X" x 4096 ) for 1..256;

   my $f = Future::IO->syswrite( $wr, "BYTES" );

   ok( !$f->is_ready, '$f is still pending' );

   # Now make some space
   $rd->read( my $buf, 4096 );

   is( scalar $f->get, 5, 'Future::IO->syswrite yields written count' );

   # Drain it
   1 while $rd->sysread( $buf, 4096 ) == 4096;

   is( $buf, "BYTES", 'Future::IO->syswrite wrote bytes' );
}

# ->syswrite yielding EPIPE
{
   pipe my ( $rd, $wr ) or die "Cannot pipe() - $!";
   $rd->close; undef $rd;

   local $SIG{PIPE} = 'IGNORE';

   my $f = Future::IO->syswrite( $wr, "BYTES" );

   ok( !eval { $f->get }, 'Future::IO->syswrite fails on EPIPE' );

   is_deeply( [ $f->failure ],
      [ "syswrite: $errstr_EPIPE\n", syswrite => $wr, $errstr_EPIPE ],
      'Future::IO->syswrite failure for EPIPE' );
}

done_testing;
