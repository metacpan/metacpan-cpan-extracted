#!/usr/bin/perl

use v5.10;
use strict;
use warnings;

use Test::More;

use Future;
use Future::Utils qw( repeat );

# generate without otherwise
{
   my $trial_f;
   my $arg;

   my $i = 0;
   my $future = repeat {
      $arg = shift;
      return $trial_f = Future->new;
   } generate => sub { $i < 3 ? ++$i : () };

   is( $arg, 1, '$arg 1 for first iteration' );
   $trial_f->done;

   ok( !$future->is_ready, '$future not ready' );

   is( $arg, 2, '$arg 2 for second iteratoin' );
   $trial_f->done( "not yet" );

   ok( !$future->is_ready, '$future still not ready' );

   is( $arg, 3, '$arg 3 for third iteration' );
   $trial_f->done( "result" );

   ok( $future->is_ready, '$future now ready' );
   is( scalar $future->result, "result", '$future->result' );
}

# generate otherwise
{
   my $last_trial_f;
   my $i = 0;
   my $future = repeat {
      Future->done( "ignore me $_[0]" );
   } generate => sub { $i < 3 ? ++$i : () },
     otherwise => sub {
        $last_trial_f = shift;
        return Future->fail( "Nothing succeeded\n" );
     };

   is( scalar $future->failure, "Nothing succeeded\n", '$future returns otherwise failure' );
   is( scalar $last_trial_f->result, "ignore me 3", '$last_trial_f->result' );

   $future = repeat {
      Future->done( "ignore me" );
   } generate => sub { () },
     otherwise => sub { Future->fail( "Nothing to do\n" ) };

   is( scalar $future->failure, "Nothing to do\n", '$future returns otherwise failure for empty generator' );
}

# Probably don't need much more testing since most combinations are test with
# foreach - while/until, die, etc..

done_testing;
