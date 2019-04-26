#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use IO::Handle;

use Future::IO;

# ->sysread_exactly yielding bytes
{
   pipe my ( $rd, $wr ) or die "Cannot pipe() - $!";

   $wr->autoflush();

   my $f = Future::IO->sysread_exactly( $rd, 5 );

   $wr->print( "BY" );
   $f->await; # Internal implementation method
   ok( !$f->is_ready, 'Future::IO->sysread_exactly not yet ready' );

   # Pipe should no longer be readable
   my $rvec = '';
   vec( $rvec, $rd->fileno, 1 ) = 1;
   is( select( $rvec, undef, undef, 0.01 ), 0, '$fd filehandle not readable' );

   $wr->print( "TES" );
   is( scalar $f->get, "BYTES", 'Future::IO->sysread_exactly yields all bytes from pipe' );
}

# ->sysread_exactly yielding EOF
{
   pipe my ( $rd, $wr ) or die "Cannot pipe() - $!";

   $wr->autoflush();

   my $f = Future::IO->sysread_exactly( $rd, 5 );

   $wr->print( "BY" );
   $wr->close;
   undef $wr;

   is_deeply( [ $f->get ], [], 'Future::IO->sysread_exactly yields nothing on EOF' );
}

done_testing;
