#!/usr/bin/perl

use v5.10;
use strict;
use warnings;

use Test2::V0 0.000148; # is_refcount

use Future;

my $__dummy; # to defeat non-closure optimsation

# catch success
{
   my $f1 = Future->new;

   my $cb;
   my $fseq = $f1->catch(
      test => $cb = sub {
         $__dummy++;
         die "catch of successful future should not be invoked";
      },
   );

   ok( defined $fseq, '$fseq defined' );
   isa_ok( $fseq, [ "Future" ], '$fseq' );

   is_oneref( $fseq, '$fseq has refcount 1 initially' );
   is_refcount( $cb, 2, '$cb has refcount 2 captured by catch callback' );

   $f1->done( results => "here" );

   is( [ $fseq->result ], [ results => "here" ], '$fseq succeeds when $f1 succeeds' );

   undef $f1;
   is_oneref( $fseq, '$fseq has refcount 1 before EOF' );
   is_oneref( $cb, '$cb has refcount 1 before EOF' );
}

# catch immediate (RT145699)
{
   my $f1 = Future->new;

   $f1->done();

   my $cb;
   my $fseq = $f1->catch(
      test => $cb = sub {
         $__dummy++;
         die "catch of successful future should not be invoked";
      },
   );

   undef $f1;
   is_oneref( $fseq, '$fseq has refcount 1 before EOF' );
   is_oneref( $cb, '$cb has refcount 1 before EOF' );
}

# catch matching failure
{
   my $f1 = Future->new;

   my $f2;
   my $fseq = $f1->catch(
      test => sub {
         is( $_[0], "f1 failure\n", 'catch block passed result of $f1' );
         return $f2 = Future->done;
      },
   );

   ok( defined $fseq, '$fseq defined' );
   isa_ok( $fseq, [ "Future" ], '$fseq' );

   is_oneref( $fseq, '$fseq has refcount 1 initially' );

   $f1->fail( "f1 failure\n", test => );

   undef $f1;
   is_oneref( $fseq, '$fseq has refcount 1 after $f1 fail and dropped' );

   ok( defined $f2, '$f2 now defined after $f1 fails' );

   ok( $fseq->is_ready, '$fseq is done after $f2 done' );
}

# catch non-matching failure
{
   my $f1 = Future->new;

   my $fseq = $f1->catch(
      test => sub { die "catch of non-matching Failure should not be invoked" },
   );

   $f1->fail( "f1 failure\n", different => );

   ok( $fseq->is_ready, '$fseq is done after $f1 fail' );
   is( scalar $fseq->failure, "f1 failure\n", '$fseq failure' );
}

# catch default handler
{
   my $fseq = Future->fail( "failure", other => )
      ->catch(
         test => sub { die "'test' catch should not match" },
         sub { Future->done( default => "handler" ) },
      );

   is( [ $fseq->result ], [ default => "handler" ],
      '->catch accepts a default handler' );
}

# catch via 'then'
{
   is( scalar ( Future->fail( "message", test => )
            ->then( sub { die "then &done should not be invoked" },
               test => sub { Future->done( 1234 ) },
               sub { die "then &fail should not be invoked" } )->result ),
      1234, 'catch semantics via ->then' );
}

# catch_with_f
{
   my $f1 = Future->new;

   my $fseq = $f1->catch_with_f(
      test => sub {
         ref_is( $_[0], $f1, '$f1 passed to catch code' );
         is( $_[1], "f1 failure\n", '$f1 failure message passed to catch code' );
         Future->done;
      },
   );

   ok( defined $fseq, 'defined $fseq' );
   isa_ok( $fseq, [ "Future" ], '$fseq' );

   $f1->fail( "f1 failure\n", test => );

   ok( $fseq->is_ready, '$fseq is done after $f1 fail' );
}

# catch via 'then_with_f'
{
   my $f1 = Future->new;

   my $fseq = $f1->then_with_f(
      sub { die "then &done should not be invoked" },
      test => sub {
         ref_is( $_[0], $f1, '$f1 passed to catch code' );
         is( $_[1], "f1 failure\n", '$f1 failure message passed to catch code' );
         Future->done;
      }
   );

   $f1->fail( "f1 failure\n", test => );

   ok( $fseq->is_ready, '$fseq is done after $f1 fail' );
}

done_testing;
