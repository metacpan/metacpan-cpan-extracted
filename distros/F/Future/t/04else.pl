use v5.10;
use strict;
use warnings;

use Test2::V0 0.000148; # is_refcount

use Future;

my $__dummy; # to defeat non-closure optimsation

# else success
{
   my $f1 = Future->new;

   my $cb;
   my $fseq = $f1->else(
      $cb = sub { $__dummy++; die "else of successful future should not be invoked" }
   );

   ok( defined $fseq, '$fseq defined' );
   isa_ok( $fseq, [ "Future" ], '$fseq' );
   is_refcount( $cb, 2, '$cb has refcount 2 captured by else callback' );

   is_oneref( $fseq, '$fseq has refcount 1 initially' );

   $f1->done( results => "here" );

   is( [ $fseq->result ], [ results => "here" ], '$fseq succeeds when $f1 succeeds' );

   undef $f1;
   is_oneref( $fseq, '$fseq has refcount 1 before EOF' );
   is_oneref( $cb, '$cb has refcount 1 before EOF' );
}

# else failure
{
   my $f1 = Future->new;

   my $f2;
   my $fseq = $f1->else(
      sub {
         is( $_[0], "f1 failure\n", 'then fail block passed result of $f1' );
         return $f2 = Future->new;
      }
   );

   ok( defined $fseq, '$fseq defined' );
   isa_ok( $fseq, [ "Future" ], '$fseq' );

   is_oneref( $fseq, '$fseq has refcount 1 initially' );

   ok( !$f2, '$f2 not yet defined before $f1 fails' );

   $f1->fail( "f1 failure\n" );

   undef $f1;
   is_oneref( $fseq, '$fseq has refcount 1 after $f1 fail and dropped' );

   ok( defined $f2, '$f2 now defined after $f1 fails' );

   ok( !$fseq->is_ready, '$fseq not yet done before $f2 done' );

   $f2->done( results => "here" );

   ok( $fseq->is_ready, '$fseq is done after $f2 done' );
   is( [ $fseq->result ], [ results => "here" ], '$fseq->result returns results' );

   undef $f2;
   is_oneref( $fseq, '$fseq has refcount 1 before EOF' );
}

# Double failure
{
   my $f1 = Future->new;

   my $f2;
   my $fseq = $f1->else(
      sub { return $f2 = Future->new }
   );

   $f1->fail( "First failure\n" );
   $f2->fail( "Another failure\n" );

   is( scalar $fseq->failure, "Another failure\n", '$fseq fails when $f2 fails' );
}

# code dies
{
   my $f1 = Future->new;

   my $fseq = $f1->else( sub {
      die "It fails\n";
   } );

   ok( lives { $f1->fail( "bork" ) }, 'exception not propagated from fail call' );

   ok( $fseq->is_ready, '$fseq is ready after code exception' );
   is( scalar $fseq->failure, "It fails\n", '$fseq->failure after code exception' );
}

# immediate fail
{
   my $f1 = Future->fail( "Failure\n" );

   my $cb;
   my $f2;
   my $fseq = $f1->else(
      $cb = sub { return $f2 = Future->new }
   );

   ok( defined $f2, '$f2 defined for immediate fail' );

   $f2->fail( "Another failure\n" );

   ok( $fseq->is_ready, '$fseq already ready for immediate fail' );
   is( scalar $fseq->failure, "Another failure\n", '$fseq->failure for immediate fail' );
   is_oneref( $cb, '$cb has refcount 1 before EOF' );
}

# immediate done
{
   my $f1 = Future->done( "It works" );

   my $fseq = $f1->else(
      sub { die "else block invoked for immediate done future" }
   );

   ok( $fseq->is_ready, '$fseq already ready for immediate done' );
   is( scalar $fseq->result, "It works", '$fseq->result for immediate done' );
}

# else cancel
{
   my $f1 = Future->new;
   my $fseq = $f1->else( sub { die "else of cancelled future should not be invoked" } );

   $fseq->cancel;

   ok( $f1->is_cancelled, '$f1 is cancelled by $fseq cancel' );

   $f1 = Future->new;
   my $f2;
   $fseq = $f1->else( sub { return $f2 = Future->new } );

   $f1->fail( "A failure\n" );
   $fseq->cancel;

   ok( $f2->is_cancelled, '$f2 cancelled by $fseq cancel' );
}

# Non-future return is upgraded
{
   my $f1 = Future->new;

   my $fseq = $f1->else( sub { "result" } );
   my $fseq2 = $f1->else( sub { Future->done } );

   ok( lives { $f1->fail( "failed\n" ) },
       '->fail with non-future return from ->else does not die' );

   is( scalar $fseq->result, "result",
       'non-future return from ->else is upgraded' );

   ok( $fseq2->is_ready, '$fseq2 is ready after failure of $fseq' );

   my $fseq3;
   ok( lives { $fseq3 = $f1->else( sub { "result" } ) },
      'non-future return from ->else on immediate does not die' );

   is( scalar $fseq3->result, "result",
       'non-future return from ->else on immediate is upgraded' );
}

# else_with_f
{
   my $f1 = Future->new;

   my $f2;
   my $fseq = $f1->else_with_f(
      sub {
         ref_is( $_[0], $f1, 'else_with_f block passed $f1' );
         is( $_[1], "f1 failure\n", 'else_with_f block pased failure of $f1' );
         return $f2 = Future->new;
      }
   );

   ok( defined $fseq, '$fseq defined' );

   $f1->fail( "f1 failure\n" );

   ok( defined $f2, '$f2 defined after $f1->fail' );

   $f2->done( "f2 result" );

   ok( $fseq->is_ready, '$fseq is done after $f2 done' );
   is( scalar $fseq->result, "f2 result", '$fseq->result returns results' );
}

# Void context raises a warning
{
   my $warnings;
   local $SIG{__WARN__} = sub { $warnings .= $_[0]; };

   Future->done->else(
      sub { Future->new }
   );
   like( $warnings,
         qr/^Calling ->else in void context /,
         'Warning in void context' );
}

# else_done
{
   my $f1 = Future->new;

   my $fseq = $f1->else_done( second => "result" );

   $f1->fail( first => );

   ok( $fseq->is_ready, '$fseq done after $f1 done' );
   is( [ $fseq->result ], [ second => "result" ], '$fseq->result returns result for else_done' );

   my $fseq2 = $f1->else_done( third => "result" );

   ok( $fseq2->is_ready, '$fseq2 done after ->else_done on immediate' );
   is( [ $fseq2->result ], [ third => "result" ], '$fseq2->result returns result for else_done on immediate' );

   my $f2 = Future->new;
   $fseq = $f2->else_done( "result2" );
   $f2->done( "result" );

   is( scalar $fseq->result, "result", '->else_done ignores success' );
}

# else_fail
{
   my $f1 = Future->new;

   my $fseq = $f1->else_fail( second => "result" );

   $f1->fail( first => );

   ok( $fseq->is_ready, '$fseq done after $f1 done' );
   is( [ $fseq->failure ], [ second => "result" ], '$fseq->failure returns result for else_fail' );

   my $fseq2 = $f1->else_fail( third => "result" );

   ok( $fseq2->is_ready, '$fseq2 done after ->else_fail on immediate' );
   is( [ $fseq2->failure ], [ third => "result" ], '$fseq2->failure returns result for else_fail on immediate' );

   my $f2 = Future->new;
   $fseq = $f2->else_fail( "failure" );
   $f2->done( "result" );

   is( scalar $fseq->result, "result", '->else_fail ignores success' );
}

done_testing;
