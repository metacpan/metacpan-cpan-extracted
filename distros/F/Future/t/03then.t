#!/usr/bin/perl

use v5.10;
use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Refcount;
use Test::Identity;

use Future;

# then success
{
   my $f1 = Future->new;

   my $f2;
   my $fseq = $f1->then(
      sub {
         is( $_[0], "f1 result", 'then done block passed result of $f1' );
         return $f2 = Future->new;
      }
   );

   ok( defined $fseq, '$fseq defined' );
   isa_ok( $fseq, "Future", '$fseq' );

   is_oneref( $fseq, '$fseq has refcount 1 initially' );

   ok( !$f2, '$f2 not yet defined before $f1 done' );

   $f1->done( "f1 result" );

   ok( defined $f2, '$f2 now defined after $f1 done' );

   undef $f1;
   is_oneref( $fseq, '$fseq has refcount 1 after $f1 done and dropped' );

   ok( !$fseq->is_ready, '$fseq not yet done before $f2 done' );

   $f2->done( results => "here" );

   ok( $fseq->is_ready, '$fseq is done after $f2 done' );
   is_deeply( [ $fseq->result ], [ results => "here" ], '$fseq->result returns results' );

   undef $f2;
   is_oneref( $fseq, '$fseq has refcount 1 before EOF' );
}

# then failure in f1
{
   my $f1 = Future->new;

   my $fseq = $f1->then(
      sub { die "then of failed Future should not be invoked" }
   );

   $f1->fail( "A failure\n" );

   ok( $fseq->is_ready, '$fseq is now ready after $f1 fail' );

   is( scalar $fseq->failure, "A failure\n", '$fseq fails when $f1 fails' );
}

# then failure in f2
{
   my $f1 = Future->new;

   my $f2;
   my $fseq = $f1->then(
      sub { return $f2 = Future->new }
   );

   $f1->done;
   $f2->fail( "Another failure\n" );

   ok( $fseq->is_ready, '$fseq is now ready after $f2 fail' );

   is( scalar $fseq->failure, "Another failure\n", '$fseq fails when $f2 fails' );
}

# code dies
{
   my $f1 = Future->new;

   my $fseq = $f1->then( sub {
      die "It fails\n";
   } );

   ok( !defined exception { $f1->done }, 'exception not propagated from done call' );

   ok( $fseq->is_ready, '$fseq is ready after code exception' );
   is( scalar $fseq->failure, "It fails\n", '$fseq->failure after code exception' );
}

# immediately done
{
   my $f1 = Future->done( "Result" );

   my $f2;
   my $fseq = $f1->then(
      sub { return $f2 = Future->new }
   );

   ok( defined $f2, '$f2 defined for immediate done' );

   $f2->done( "Final" );

   ok( $fseq->is_ready, '$fseq already ready for immediate done' );
   is( scalar $fseq->result, "Final", '$fseq->result for immediate done' );
}

# immediately fail
{
   my $f1 = Future->fail( "Failure\n" );

   my $fseq = $f1->then(
      sub { die "then of immediately-failed future should not be invoked" }
   );

   ok( $fseq->is_ready, '$fseq already ready for immediate fail' );
   is( scalar $fseq->failure, "Failure\n", '$fseq->failure for immediate fail' );
}

# done fallthrough
{
   my $f1 = Future->new;
   my $fseq = $f1->then;

   $f1->done( "fallthrough result" );

   ok( $fseq->is_ready, '$fseq is ready' );
   is( scalar $fseq->result, "fallthrough result", '->then done fallthrough' );
}

# fail fallthrough
{
   my $f1 = Future->new;
   my $fseq = $f1->then;

   $f1->fail( "fallthrough failure\n" );

   ok( $fseq->is_ready, '$fseq is ready' );
   is( scalar $fseq->failure, "fallthrough failure\n", '->then fail fallthrough' );
}

# then cancel
{
   my $f1 = Future->new;
   my $fseq = $f1->then( sub { die "then done of cancelled Future should not be invoked" } );

   $fseq->cancel;

   ok( $f1->is_cancelled, '$f1 is cancelled by $fseq cancel' );

   $f1 = Future->new;
   my $f2;
   $fseq = $f1->then( sub { return $f2 = Future->new } );

   $f1->done;
   $fseq->cancel;

   ok( $f2->is_cancelled, '$f2 cancelled by $fseq cancel' );
}

# then dropping $fseq doesn't fail ->done
{
   local $SIG{__WARN__} = sub {};

   my $f1 = Future->new;
   my $fseq = $f1->then( sub { return Future->done() } );

   undef $fseq;

   is( exception { $f1->done; }, undef,
      'Dropping $fseq does not cause $f1->done to die' );
}

# Void context raises a warning
{
   my $warnings;
   local $SIG{__WARN__} = sub { $warnings .= $_[0]; };

   Future->done->then(
      sub { Future->new }
   );
   like( $warnings,
         qr/^Calling ->then in void context /,
         'Warning in void context' );
}

# Non-Future return is upgraded
{
   my $f1 = Future->new;

   my $fseq = $f1->then( sub { "result" } );
   my $fseq2 = $f1->then( sub { Future->done } );

   is( exception { $f1->done }, undef,
       '->done with non-Future return from ->then does not die' );

   is( scalar $fseq->result, "result",
       'non-Future return from ->then is upgraded' );

   ok( $fseq2->is_ready, '$fseq2 is ready after failure of $fseq' );

   my $fseq3;
   is( exception { $fseq3 = $f1->then( sub { "result" } ) }, undef,
      'non-Future return from ->then on immediate does not die' );

   is( scalar $fseq3->result, "result",
       'non-Future return from ->then on immediate is upgraded' );
}

# then_with_f
{
   my $f1 = Future->new;

   my $f2;
   my $fseq = $f1->then_with_f(
      sub {
         identical( $_[0], $f1, 'then_with_f block passed $f1' );
         is( $_[1], "f1 result", 'then_with_f block pased result of $f1' );
         return $f2 = Future->new;
      }
   );

   ok( defined $fseq, '$fseq defined' );

   $f1->done( "f1 result" );

   ok( defined $f2, '$f2 defined after $f1->done' );

   $f2->done( "f2 result" );

   ok( $fseq->is_ready, '$fseq is done after $f2 done' );
   is( scalar $fseq->result, "f2 result", '$fseq->result returns results' );
}

# then_done
{
   my $f1 = Future->new;

   my $fseq = $f1->then_done( second => "result" );

   $f1->done( first => );

   ok( $fseq->is_ready, '$fseq done after $f1 done' );
   is_deeply( [ $fseq->result ], [ second => "result" ], '$fseq->result returns result for then_done' );

   my $fseq2 = $f1->then_done( third => "result" );

   ok( $fseq2->is_ready, '$fseq2 done after ->then_done on immediate' );
   is_deeply( [ $fseq2->result ], [ third => "result" ], '$fseq2->result returns result for then_done on immediate' );

   my $f2 = Future->new;
   $fseq = $f2->then_done( "result" );
   $f2->fail( "failure" );

   is( scalar $fseq->failure, "failure", '->then_done ignores failure' );
}

# then_fail
{
   my $f1 = Future->new;

   my $fseq = $f1->then_fail( second => "result" );

   $f1->done( first => );

   ok( $fseq->is_ready, '$fseq done after $f1 done' );
   is_deeply( [ $fseq->failure ], [ second => "result" ], '$fseq->failure returns result for then_fail' );

   my $fseq2 = $f1->then_fail( third => "result" );

   ok( $fseq2->is_ready, '$fseq2 done after ->then_fail on immediate' );
   is_deeply( [ $fseq2->failure ], [ third => "result" ], '$fseq2->failure returns result for then_fail on immediate' );

   my $f2 = Future->new;
   $fseq = $f2->then_fail( "fail2" );
   $f2->fail( "failure" );

   is( scalar $fseq->failure, "failure", '->then_fail ignores failure' );
}

done_testing;
