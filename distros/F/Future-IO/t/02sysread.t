#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use IO::Handle;

use Future::IO;

# ->sysread yielding bytes
{
   pipe my ( $rd, $wr ) or die "Cannot pipe() - $!";

   $wr->autoflush();
   $wr->print( "BYTES" );

   my $f = Future::IO->sysread( $rd, 5 );

   is( scalar $f->get, "BYTES", 'Future::IO->sysread yields bytes from pipe' );
}

# ->sysread yielding EOF
{
   pipe my ( $rd, $wr ) or die "Cannot pipe() - $!";
   $wr->close; undef $wr;

   my $f = Future::IO->sysread( $rd, 1 );

   is_deeply( [ $f->get ], [], 'Future::IO->sysread yields nothing on EOF' );
}

# TODO: is there a nice portable way we can test for an IO error?

# ->sysread can be cancelled
{
   pipe my ( $rd, $wr ) or die "Cannot pipe() - $!";

   $wr->autoflush();
   $wr->print( "BYTES" );

   my $f1 = Future::IO->sysread( $rd, 3 );
   my $f2 = Future::IO->sysread( $rd, 3 );

   $f1->cancel;

   is( scalar $f2->get, "BYT", 'Future::IO->sysread can be cancelled' );
}

done_testing;
