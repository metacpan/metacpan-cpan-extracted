#!/usr/bin/perl

use v5.10;
use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Identity;
use Test::Refcount;

use Future;

# done
{
   my $future = Future->new;

   ok( defined $future, '$future defined' );
   isa_ok( $future, "Future", '$future' );
   is_oneref( $future, '$future has refcount 1 initially' );

   ok( !$future->is_ready, '$future not yet ready' );
   is( $future->state, "pending", '$future->state before done' );

   my @on_ready_args;
   identical( $future->on_ready( sub { @on_ready_args = @_ } ), $future, '->on_ready returns $future' );

   my @on_done_args;
   identical( $future->on_done( sub { @on_done_args = @_ } ), $future, '->on_done returns $future' );
   identical( $future->on_fail( sub { die "on_fail called for done future" } ), $future, '->on_fail returns $future' );

   identical( $future->done( result => "here" ), $future, '->done returns $future' );

   is( scalar @on_ready_args, 1, 'on_ready passed 1 argument' );
   identical( $on_ready_args[0], $future, 'Future passed to on_ready' );
   undef @on_ready_args;

   is_deeply( \@on_done_args, [ result => "here" ], 'Results passed to on_done' );

   ok( $future->is_ready, '$future is now ready' );
   ok( $future->is_done, '$future is done' );
   ok( !$future->is_failed, '$future is not failed' );
   is( $future->state, "done", '$future->state after done' );
   is_deeply( [ $future->result ], [ result => "here" ], 'Results from $future->result' );
   is( scalar $future->result, "result", 'Result from scalar $future->result' );

   is_oneref( $future, '$future has refcount 1 at end of test' );
}

# wrap
{
   my $f = Future->new;

   my $future = Future->wrap( $f );

   ok( defined $future, 'Future->wrap(Future) defined' );
   isa_ok( $future, "Future", 'Future->wrap(Future)' );

   $f->done( "Wrapped Future" );
   is( scalar $future->result, "Wrapped Future", 'Future->wrap(Future)->result' );

   $future = Future->wrap( "Plain string" );

   ok( defined $future, 'Future->wrap(string) defined' );
   isa_ok( $future, "Future", 'Future->wrap(string)' );

   is( scalar $future->result, "Plain string", 'Future->wrap(string)->result' );
}

# done chaining
{
   my $future = Future->new;

   my $f1 = Future->new;
   my $f2 = Future->new;

   $future->on_done( $f1 );
   $future->on_ready( $f2 );

   my @on_done_args_1;
   $f1->on_done( sub { @on_done_args_1 = @_ } );
   my @on_done_args_2;
   $f2->on_done( sub { @on_done_args_2 = @_ } );

   $future->done( chained => "result" );

   is_deeply( \@on_done_args_1, [ chained => "result" ], 'Results chained via ->on_done( $f )' );
   is_deeply( \@on_done_args_2, [ chained => "result" ], 'Results chained via ->on_ready( $f )' );
}

# immediately done
{
   my $future = Future->done( already => "done" );

   my @on_done_args;
   identical( $future->on_done( sub { @on_done_args = @_; } ), $future, '->on_done returns future for immediate' );
   my $on_fail;
   identical( $future->on_fail( sub { $on_fail++; } ), $future, '->on_fail returns future for immediate' );

   is_deeply( \@on_done_args, [ already => "done" ], 'Results passed to on_done for immediate future' );
   ok( !$on_fail, 'on_fail not invoked for immediate future' );

   my $f1 = Future->new;
   my $f2 = Future->new;

   $future->on_done( $f1 );
   $future->on_ready( $f2 );

   ok( $f1->is_ready, 'Chained ->on_done for immediate future' );
   ok( $f1->is_done, 'Chained ->on_done is done for immediate future' );
   is_deeply( [ $f1->result ], [ already => "done" ], 'Results from chained via ->on_done for immediate future' );
   ok( $f2->is_ready, 'Chained ->on_ready for immediate future' );
   ok( $f2->is_done, 'Chained ->on_ready is done for immediate future' );
   is_deeply( [ $f2->result ], [ already => "done" ], 'Results from chained via ->on_ready for immediate future' );
}

# fail
{
   my $future = Future->new;

   $future->on_done( sub { die "on_done called for failed future" } );
   my $failure;
   $future->on_fail( sub { ( $failure ) = @_; } );

   identical( $future->fail( "Something broke" ), $future, '->fail returns $future' );

   ok( $future->is_ready, '$future->fail marks future ready' );
   ok( !$future->is_done, '$future->fail does not mark future done' );
   ok( $future->is_failed, '$future->fail marks future as failed' );
   is( $future->state, "failed", '$future->state after fail' );

   is( scalar $future->failure, "Something broke", '$future->failure yields exception' );
   my $file = __FILE__;
   my $line = __LINE__ + 1;
   like( exception { $future->result }, qr/^Something broke at \Q$file line $line\E\.?\n$/, '$future->result throws exception' );

   is( $failure, "Something broke", 'Exception passed to on_fail' );
}

{
   my $future = Future->new;

   $future->fail( "Something broke", further => "details" );

   ok( $future->is_ready, '$future->fail marks future ready' );

   is( scalar $future->failure, "Something broke", '$future->failure yields exception' );
   is_deeply( [ $future->failure ], [ "Something broke", "further", "details" ],
         '$future->failure yields details in list context' );
}

# fail chaining
{
   my $future = Future->new;

   my $f1 = Future->new;
   my $f2 = Future->new;

   $future->on_fail( $f1 );
   $future->on_ready( $f2 );

   my $failure_1;
   $f1->on_fail( sub { ( $failure_1 ) = @_ } );
   my $failure_2;
   $f2->on_fail( sub { ( $failure_2 ) = @_ } );

   $future->fail( "Chained failure" );

   is( $failure_1, "Chained failure", 'Failure chained via ->on_fail( $f )' );
   is( $failure_2, "Chained failure", 'Failure chained via ->on_ready( $f )' );
}

# immediately failed
{
   my $future = Future->fail( "Already broken" );

   my $on_done;
   identical( $future->on_done( sub { $on_done++; } ), $future, '->on_done returns future for immediate' );
   my $failure;
   identical( $future->on_fail( sub { ( $failure ) = @_; } ), $future, '->on_fail returns future for immediate' );

   is( $failure, "Already broken", 'Exception passed to on_fail for already-failed future' );
   ok( !$on_done, 'on_done not invoked for immediately-failed future' );

   my $f1 = Future->new;
   my $f2 = Future->new;

   $future->on_fail( $f1 );
   $future->on_ready( $f2 );

   ok( $f1->is_ready, 'Chained ->on_done for immediate future' );
   is_deeply( [ $f1->failure ], [ "Already broken" ], 'Results from chained via ->on_done for immediate future' );
   ok( $f2->is_ready, 'Chained ->on_ready for immediate future' );
   is_deeply( [ $f2->failure ], [ "Already broken" ], 'Results from chained via ->on_ready for immediate future' );
}

# die
{
   my $future = Future->new;

   $future->on_done( sub { die "on_done called for failed future" } );
   my $failure;
   $future->on_fail( sub { ( $failure ) = @_; } );

   my $file = __FILE__;
   my $line = __LINE__+1;
   identical( $future->die( "Something broke" ), $future, '->die returns $future' );

   ok( $future->is_ready, '$future->die marks future ready' );

   is( scalar $future->failure, "Something broke at $file line $line\n", '$future->failure yields exception' );
   is( exception { $future->result }, "Something broke at $file line $line\n", '$future->result throws exception' );

   is( $failure, "Something broke at $file line $line\n", 'Exception passed to on_fail' );
}

# call
{
   my $future;

   $future = Future->call( sub { Future->done( @_ ) }, 1, 2, 3 );

   ok( $future->is_ready, '$future->is_ready from immediate Future->call' );
   is_deeply( [ $future->result ], [ 1, 2, 3 ], '$future->result from immediate Future->call' );

   $future = Future->call( sub { die "argh!\n" } );

   ok( $future->is_ready, '$future->is_ready from immediate exception of Future->call' );
   is( $future->failure, "argh!\n", '$future->failure from immediate exception of Future->call' );

   $future = Future->call( sub { "non-future" } );

   ok( $future->is_ready, '$future->is_ready from non-future returning Future->call' );
   like( $future->failure, qr/^Expected __ANON__.*\(\S+ line \d+\) to return a Future$/,
      '$future->failure from non-future returning Future->call' );
}

# unwrap
{
   is_deeply( [ Future->unwrap( Future->done( 1, 2, 3 ) ) ],
              [ 1, 2, 3 ],
              'Future->unwrap Future in list context' );
   is_deeply( [ Future->unwrap( 1, 2, 3 ) ],
              [ 1, 2, 3 ],
              'Future->unwrap plain list in list context' );

   is( scalar Future->unwrap( Future->done( qw( a b c ) ) ),
       "a",
       'Future->unwrap Future in scalar context' );
   is( scalar Future->unwrap( qw( a b c ) ),
       "a",
       'Future->unwrap plain list in scalar context' );
}

# label
{
   my $f = Future->new;

   identical( $f->set_label( "the label" ), $f, '->set_label returns $f' );

   is( $f->label, "the label", '->label returns the label' );

   $f->cancel;
}

# retain
{
   my @args;
   foreach my $method (qw( cancel done fail )) {
      my $f = Future->new;
      is_oneref( $f, 'start with refcount 1' );

      is( $f->retain, $f, '->retain returns original Future' );

      is_refcount( $f, 2, 'refcount is now increased' );

      ok( $f->$method( @args ), "can call ->$method" );
      is_oneref( $f, 'refcount drops when completed' );

      push @args, 'x';
   }
}

# await
{
   my $future = Future->done( "result" );
   identical( $future->await, $future, '->await returns invocant' );
}

# ->result while pending
{
   like( exception { Future->new->result; },
      qr/^Future=HASH\(0x[0-9a-f]+\) is not yet ready /,
      '->result while pending raises exception' );
}

# resolve and reject aliases
{
   my $fdone = Future->resolve( "abc" );
   ok( $fdone->is_done, 'Future->resolve' );

   my $ffail = Future->reject( "def\n" );
   ok( $ffail->is_failed, 'Future->reject' );
}

done_testing;
