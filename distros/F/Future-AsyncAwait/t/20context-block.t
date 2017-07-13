#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Future;

use Future::AsyncAwait;

sub Destructor::DESTROY { ${ shift->[0] }++ }

# block with CLEARSV
{
   my $destroyed;

   async sub with_block
   {
      my ( $f ) = @_;

      my $cond = 1;
      if( $cond ) {
         my $x = bless [ \$destroyed ], "Destructor";
         await $f;
      }

      return "result";
   }

   my $f1 = Future->new;
   my $fret = with_block( $f1 );

   ok( !$fret->is_ready, '$fret not immediate with_block' );
   ok( !$destroyed, '$x not yet destroyed' );

   $f1->done;

   is( scalar $fret->get, "result", '$fret now ready after done' );
   ok( $destroyed, '$x was destroyed' );
}

# block with CLEARPADRANGE
{
   my $destroyed;

   async sub with_block_padrange
   {
      my ( $f ) = @_;

      my $cond = 1;
      if( $cond ) {
         my ( $x, $y, $z ) = ( 1, 2, bless [ \$destroyed ], "Destructor" );
         await $f;
      }

      return "done";
   }

   my $f1 = Future->new;
   my $fret = with_block_padrange( $f1 );

   $f1->done;

   is( scalar $fret->get, "done", '$fret now ready after done with padrange' );
   ok( $destroyed, '$z was destroyed' );
}

done_testing;
