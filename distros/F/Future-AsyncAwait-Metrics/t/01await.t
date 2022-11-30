#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;
use Test::Metrics::Any;

use Future;
use Future::AsyncAwait;
use Future::AsyncAwait::Metrics;

async sub waiter
{
   my ( @f ) = @_;

   foreach my $f ( @f ) {
      await $f;
   }
}

is_metrics_from(
   sub {
      my $f1 = Future->new;
      my $f2 = Future->new;

      my $fret = waiter( $f1, $f2 );

      is_metrics(
         {
            asyncawait_current_subs => 1,
            asyncawait_current_states => 1,
         },
         'Metrics reports one suspended sub before resume'
      );

      $f1->done;
      $f2->done;

      $fret->get;

      is_metrics(
         {
            asyncawait_current_subs => 0,
            asyncawait_current_states => 0,
         },
         'Metrics reports no suspended subs after resume'
      );
   },
   {
      asyncawait_suspends => 2,
      asyncawait_resumes  => 2,

      asyncawait_states_created => 1,
      asyncawait_states_destroyed => 1,
   },
   'Metrics from suspend/resume test'
);

done_testing;
