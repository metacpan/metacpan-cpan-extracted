#!/usr/bin/perl

use v5.10;
use strict;
use warnings;

use Test::More;

use Future;
use Future::Utils qw( repeat try_repeat try_repeat_until_success );

# foreach without otherwise
{
   my $trial_f;
   my $arg;
   my $future = repeat {
      $arg = shift;
      return $trial_f = Future->new;
   } foreach => [qw( one two three )];

   is( $arg, "one", '$arg one for first iteration' );
   $trial_f->done;

   ok( !$future->is_ready, '$future not ready' );

   is( $arg, "two", '$arg two for second iteration' );
   $trial_f->done( "another" );

   ok( !$future->is_ready, '$future not ready' );

   is( $arg, "three", '$arg three for third iteration' );
   $trial_f->done( "result" );

   ok( $future->is_ready, '$future now ready' );
   is( scalar $future->result, "result", '$future->result' );
}

# foreach otherwise
{
   my $last_trial_f;
   my $future = repeat {
      Future->done( "ignore me $_[0]" );
   } foreach => [qw( one two three )],
     otherwise => sub {
        $last_trial_f = shift;
        return Future->fail( "Nothing succeeded\n" );
     };

   is( scalar $future->failure, "Nothing succeeded\n", '$future returns otherwise failure' );
   is( scalar $last_trial_f->result, "ignore me three", '$last_trial_f->result' );

   $future = repeat {
      Future->done( "ignore me" );
   } foreach => [],
     otherwise => sub { Future->fail( "Nothing to do\n" ) };

   is( scalar $future->failure, "Nothing to do\n", '$future returns otherwise failure for empty list' );
}

# foreach on empty list
{
   my $future = repeat { die "Not invoked" } foreach => [];

   ok( $future->is_ready, 'repeat {} on empty foreach without otherwise already ready' );
   is_deeply( [ $future->result ], [], 'Result of empty future' );

   $future = repeat { die "Not invoked" } foreach => [],
      otherwise => sub { Future->done( 1, 2, 3 ) };

   ok( $future->is_ready, 'repeat {} on empty foreach with otherwise already ready' );
   is_deeply( [ $future->result ], [ 1, 2, 3 ], 'Result of otherwise future' );
}

# foreach while
{
   my $future = try_repeat {
      my $arg = shift;
      if( $arg eq "bad" ) {
         return Future->fail( "bad" );
      }
      else {
         return Future->done( $arg );
      }
   } foreach => [qw( bad good not-attempted )],
     while => sub { shift->failure };

   is( scalar $future->result, "good", '$future->result returns correct result for foreach+while' );
}

# foreach until
{
   my $future = try_repeat {
      my $arg = shift;
      if( $arg eq "bad" ) {
         return Future->fail( "bad" );
      }
      else {
         return Future->done( $arg );
      }
   } foreach => [qw( bad good not-attempted )],
     until => sub { !shift->failure };

   is( scalar $future->result, "good", '$future->result returns correct result for foreach+until' );
}

# foreach while + otherwise
{
   my $future = repeat {
      Future->done( $_[0] );
   } foreach => [ 1, 2, 3 ],
     while => sub { $_[0]->result < 2 },
     otherwise => sub { Future->fail( "Failed to find 2" ) };

   is( scalar $future->result, 2, '$future->result returns successful result from while + otherwise' );
}

# try_repeat_until_success foreach
{
   my $future = try_repeat_until_success {
      my $arg = shift;
      if( $arg eq "bad" ) {
         return Future->fail( "bad" );
      }
      else {
         return Future->done( $arg );
      }
   } foreach => [qw( bad good not-attempted )];

   is( scalar $future->result, "good", '$future->result returns correct result for try_repeat_until_success' );
}

# main code dies
{
   my $future = try_repeat {
      $_[1]->failure if @_ > 1; # absorb the previous failure

      die "It failed\n";
   } foreach => [ 1, 2, 3 ];

   is( $future->failure, "It failed\n", 'repeat foreach failure after code exception' );
}

# otherwise code dies
{
   my $future = repeat {
      Future->done;
   } foreach => [],
     otherwise => sub { die "It failed finally\n" };

   is( $future->failure, "It failed finally\n", 'repeat foreach failure after otherwise exception' );
}

done_testing;
