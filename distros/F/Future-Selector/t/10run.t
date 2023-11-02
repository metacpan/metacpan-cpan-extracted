#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;

use Future;
use Future::Selector;

# ->run
{
   my $selector = Future::Selector->new;

   my $count = 0;
   $selector->add(
      data => "loop",
      gen  => sub {
         return Future->fail( "Stop now\n" ) if $count > 3;
         $count++;
         return Future->done;
      },
   );

   my $run_f = $selector->run;

   ok( $run_f->is_ready, '->run completed after failure' );
   is( scalar $run_f->failure, "Stop now\n",
      'failure from ->run future' );
}

# ->run_until_ready
{
   my $selector = Future::Selector->new;

   my $f = Future->new;
   my $count = 0;
   $selector->add(
      data => "loop",
      gen  => sub {
         $count++;
         $f->done( "Ready" ) if $count > 5;
         return Future->done;
      },
   );

   my $run_f = $selector->run_until_ready( $f );

   ok( $run_f->is_ready, '->run_until_ready completed' );
   is( $count, 6, 'Loop stopped after 6 iterations' );
   is( [ $run_f->get ], [ "Ready" ], 'run future yields completion result' );
}

done_testing;
