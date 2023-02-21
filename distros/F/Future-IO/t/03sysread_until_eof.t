#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use IO::Handle;

use Future::IO;

# ->sysread_until_eof
{
   pipe my ( $rd, $wr ) or die "Cannot pipe() - $!";

   $wr->autoflush();
   $wr->print( "BYTES" );

   my $f = Future::IO->sysread_until_eof( $rd );

   $wr->print( " HERE" );
   $wr->close;

   is( scalar $f->get, "BYTES HERE", 'Future::IO->sysread_until_eof eventually yields all the bytes' );
}

done_testing;
