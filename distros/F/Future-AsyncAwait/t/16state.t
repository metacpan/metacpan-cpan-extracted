#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Future;

use Future::AsyncAwait;

# sequential
{
   async sub with_state
   {
      state $var = 5;

      await $_[0];

      return "<$var>";
   }

   my $f1 = Future->new;
   my $fret1 = with_state( $f1 );

   $f1->done;

   is( scalar $fret1->get, "<5>", '$fret now ready after done' );

   my $f2 = Future->new;
   my $fret2 = with_state( $f2 );

   $f2->done;

   is( scalar $fret2->get, "<5>", '$fret now ready after done a second time' );
}

# concurrent (RT139821)
{
   async sub with_state2
   {
      state $var = 10;

      await $_[0];

      return "<$var>";
   }

   my @f = map { Future->new } 1 .. 2;
   my @fret = map { with_state2 $_ } @f;

   $f[0]->done;
   $f[1]->done;

   is( scalar $fret[0]->get, '<10>', 'Result of first invocation' );
   is( scalar $fret[1]->get, '<10>', 'Result of second invocation' );
}

done_testing;
