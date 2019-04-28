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
   $wr->print( "BYTES" );

   my $f = Future::IO->sysread_exactly( $rd, 5 );

   my @read;
   no warnings 'redefine';
   local *IO::Handle::sysread = sub {
      my ( $fh, undef, $len ) = @_;
      push @read, $len;
      return CORE::sysread( $fh, $_[1], 1 );
   };

   is( scalar $f->get, "BYTES", 'Future::IO->sysread_exactly eventually yields all the bytes' );

   is_deeply( \@read, [ 5, 4, 3, 2, 1 ], 'IO::Handle->sysread override worked' );
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
