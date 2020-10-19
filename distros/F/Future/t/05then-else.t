#!/usr/bin/perl

use v5.10;
use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Future;

# then done
{
   my $f1 = Future->new;

   my $fdone;
   my $fseq = $f1->then(
      sub {
         is( $_[0], "f1 result", '2-arg then done block passed result of $f1' );
         return $fdone = Future->new;
      },
      sub {
         die "then fail block should not be invoked";
      },
   );

   $f1->done( "f1 result" );

   ok( defined $fdone, '$fdone now defined after $f1 done' );

   $fdone->done( results => "here" );

   ok( $fseq->is_ready, '$fseq is done after $fdone done' );
   is_deeply( [ $fseq->result ], [ results => "here" ], '$fseq->result returns results' );
}

# then fail
{
   my $f1 = Future->new;

   my $ffail;
   my $fseq = $f1->then(
      sub {
         die "then done block should not be invoked";
      },
      sub {
         is( $_[0], "The failure\n", '2-arg then fail block passed failure of $f1' );
         return $ffail = Future->new;
      },
   );

   $f1->fail( "The failure\n" );

   ok( defined $ffail, '$ffail now defined after $f1 fail' );

   $ffail->done( fallback => "result" );

   ok( $fseq->is_ready, '$fseq is done after $ffail fail' );
   is_deeply( [ $fseq->result ], [ fallback => "result" ], '$fseq->result returns results' );
}

# then done fails doesn't trigger fail block
{
   my $f1 = Future->new;

   my $fdone;
   my $fseq = $f1->then(
      sub {
         $fdone = Future->new;
      },
      sub {
         die "then fail block should not be invoked";
      },
   );

   $f1->done( "Done" );
   $fdone->fail( "The failure\n" );

   ok( $fseq->is_ready, '$fseq is ready after $fdone fail' );
   ok( scalar $fseq->failure, '$fseq failed after $fdone fail' );
}

# then_with_f
{
   my $f1 = Future->new;

   my $fseq = $f1->then_with_f(
      sub {
         identical( $_[0], $f1, 'then_with_f done block passed $f1' );
         is( $_[1], "f1 result", 'then_with_f done block passed result of $f1' );
         Future->done;
      },
      sub {
         die "then_with_f fail block should not be called";
      },
   );

   $f1->done( "f1 result" );

   ok( $fseq->is_ready, '$fseq is ready after $f1 done' );
}

done_testing;
