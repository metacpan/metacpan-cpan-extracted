#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Future;
use Future::AsyncAwait;
use Future::AsyncAwait::Hooks;

{
   my @calls;

   my $false = 0;

   async sub func1 {
      my ( $f ) = @_;

      suspend { push @calls, "S1"; }
      resume  { push @calls, "R1"; }

      suspend { push @calls, "S2"; }
      resume  { push @calls, "R2"; }

      {
         # These should not be observed
         suspend { push @calls, "S3"; }
         resume  { push @calls, "R3"; }
      }

      await $f;
   }

   my $f1 = Future->new;
   my $fret = func1( $f1 );

   ok( !$fret->is_done, 'fret still pending' );
   is( \@calls, [qw( S1 S2 )], 'suspend {} blocks were invoked' );

   undef @calls;

   $f1->done;
   ok( $fret->is_done, 'fret now done' );
   is( \@calls, [qw( R2 R1 )], 'resume {} blocks were invoked' );

   $fret->get; # flush out any pending exception
}

# blocks in scope accumulate
{
   my @calls;

   async sub func2 {
      my ( $f1, $f2 ) = @_;

      suspend { push @calls, "S1"; }
      resume  { push @calls, "R1"; }

      await $f1;

      suspend { push @calls, "S2"; }
      resume  { push @calls, "R2"; }

      await $f2;
   }

   my $f1 = Future->new;
   my $f2 = Future->new;

   my $fret = func2( $f1, $f2 );

   push @calls, "<1>";
   $f1->done;
   push @calls, "<2>";
   $f2->done;

   is( \@calls, [qw( S1 <1> R1 S1 S2 <2> R2 R1 )], 'suspend and resume blocks accumulate' );
}

# multiple calls get their own copies
{
   my @calls;

   async sub func3 {
      my ( $id, $f ) = @_;

      suspend { push @calls, "S$id"; }
      resume  { push @calls, "R$id"; }

      await $f;
   }

   my $fretX = func3( x => my $fX = Future->new );
   my $fretY = func3( y => my $fY = Future->new );

   is( \@calls, [qw( Sx Sy )], 'suspend blocks for independent calls' );

   $fX->done;

   is( \@calls, [qw( Sx Sy Rx )], 'resume block for one call invoked' );

   $fY->done;

   is( \@calls, [qw( Sx Sy Rx Ry )], 'resume block for other call invoked' );
}

done_testing;
