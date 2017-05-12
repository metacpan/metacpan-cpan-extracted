#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Identity;
use Test::Refcount;

use Future;

{
   my $f1 = Future->new;

   my $called = 0;
   my $fseq = $f1->followed_by( sub {
      $called++;
      identical( $_[0], $f1, 'followed_by block passed $f1' );
      return $_[0];
   } );

   ok( defined $fseq, '$fseq defined' );
   isa_ok( $fseq, "Future", '$fseq' );

   is_oneref( $fseq, '$fseq has refcount 1 initially' );
   # Two refs; one in lexical $f1, one in $fseq's cancellation closure
   is_refcount( $f1, 2, '$f1 has refcount 2 initially' );

   is( $called, 0, '$called before $f1 done' );

   $f1->done( results => "here" );

   is( $called, 1, '$called after $f1 done' );

   ok( $fseq->is_ready, '$fseq is done after $f1 done' );
   is_deeply( [ $fseq->get ], [ results => "here" ], '$fseq->get returns results' );

   is_oneref( $fseq, '$fseq has refcount 1 before EOF' );
   is_oneref( $f1, '$f1 has refcount 1 before EOF' );
}

{
   my $f1 = Future->new;

   my $called = 0;
   my $fseq = $f1->followed_by( sub {
      $called++;
      identical( $_[0], $f1, 'followed_by block passed $f1' );
      return $_[0];
   } );

   ok( defined $fseq, '$fseq defined' );
   isa_ok( $fseq, "Future", '$fseq' );

   is_oneref( $fseq, '$fseq has refcount 1 initially' );

   is( $called, 0, '$called before $f1 done' );

   $f1->fail( "failure\n" );

   is( $called, 1, '$called after $f1 failed' );

   ok( $fseq->is_ready, '$fseq is ready after $f1 failed' );
   is_deeply( [ $fseq->failure ], [ "failure\n" ], '$fseq->get returns failure' );

   is_oneref( $fseq, '$fseq has refcount 1 before EOF' );
}

# code dies
{
   my $f1 = Future->new;

   my $fseq = $f1->followed_by( sub {
      die "It fails\n";
   } );

   ok( !defined exception { $f1->done }, 'exception not propagated from code call' );

   ok( $fseq->is_ready, '$fseq is ready after code exception' );
   is( scalar $fseq->failure, "It fails\n", '$fseq->failure after code exception' );
}

# Cancellation
{
   my $f1 = Future->new;

   my $fseq = $f1->followed_by(
      sub { die "followed_by of cancelled Future should not be invoked" }
   );

   $fseq->cancel;

   ok( $f1->is_cancelled, '$f1 cancelled by $fseq->cancel' );

   $f1 = Future->new;
   my $f2 = Future->new;

   $fseq = $f1->followed_by( sub { $f2 } );

   $f1->done;
   $fseq->cancel;

   ok( $f2->is_cancelled, '$f2 cancelled by $fseq->cancel' );

   $f1 = Future->done;
   $f2 = Future->new;

   $fseq = $f1->followed_by( sub { $f2 } );

   $fseq->cancel;

   ok( $f2->is_cancelled, '$f2 cancelled by $fseq->cancel on $f1 immediate' );
}

# immediately done
{
   my $f1 = Future->done;

   my $called = 0;
   my $fseq = $f1->followed_by(
      sub { $called++; return $_[0] }
   );

   is( $called, 1, 'followed_by block invoked immediately for already-done' );
}

# immediately done
{
   my $f1 = Future->fail("Failure\n");

   my $called = 0;
   my $fseq = $f1->followed_by(
      sub { $called++; return $_[0] }
   );

   is( $called, 1, 'followed_by block invoked immediately for already-failed' );
}

# immediately code dies
{
   my $f1 = Future->done;

   my $fseq;

   ok( !defined exception {
      $fseq = $f1->followed_by( sub {
         die "It fails\n";
      } );
   }, 'exception not propagated from ->followed_by on immediate' );

   ok( $fseq->is_ready, '$fseq is ready after code exception on immediate' );
   is( scalar $fseq->failure, "It fails\n", '$fseq->failure after code exception on immediate' );
}

# Void context raises a warning
{
   my $warnings;
   local $SIG{__WARN__} = sub { $warnings .= $_[0]; };

   Future->done->followed_by(
      sub { Future->new }
   );

   like( $warnings,
         qr/^Calling ->followed_by in void context at /,
         'Warning in void context' );
}

# Non-Future return raises exception
{
   my $f1 = Future->new;

   my $file = __FILE__;
   my $line = __LINE__+1;
   my $fseq = $f1->followed_by( sub {} );
   my $fseq2 = $f1->followed_by( sub { Future->done } );

   ok( !exception { $f1->done },
       '->done with non-Future return from ->followed_by does not die' );

   like( $fseq->failure,
       qr/^Expected __ANON__\(\Q$file\E line $line\) to return a Future/,
       'Failure from non-Future return from ->followed_by' );

   ok( $fseq2->is_ready, '$fseq2 is ready after failure of $fseq' );

   my $fseq3;
   ok( !exception { $fseq3 = $f1->followed_by( sub {} ) },
      'non-Future return from ->followed_by on immediate does not die' );

   like( $fseq3->failure,
       qr/^Expected __ANON__\(.*\) to return a Future/,
       'Failure from non-Future return from ->followed_by on immediate' );
}

done_testing;
