#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Errno qw( EINVAL EPIPE );
use IO::Handle;

use Future::IO;

my $errstr_EPIPE = do {
   # On MSWin32 we don't get EPIPE, but EINVAL
   local $! = $^O eq "MSWin32" ? EINVAL : EPIPE; "$!";
};

# ->syswrite success
{
   pipe my ( $rd, $wr ) or die "Cannot pipe() - $!";

   my $f = Future::IO->syswrite( $wr, "BYTES" );

   is( scalar $f->get, 5, 'Future::IO->syswrite yields written count' );

   $rd->read( my $buf, 5 );
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

# ->syswrite can be cancelled
{
   pipe my ( $rd, $wr ) or die "Cannot pipe() - $!";

   my $f1 = Future::IO->syswrite( $wr, "BY" );
   my $f2 = Future::IO->syswrite( $wr, "TES" );

   $f1->cancel;

   is( scalar $f2->get, 3, 'Future::IO->syswrite after cancelled one still works' );

   $rd->read( my $buf, 3 );
   is( $buf, "TES", 'Cancelled Future::IO->syswrite did not write bytes' );
}

done_testing;
