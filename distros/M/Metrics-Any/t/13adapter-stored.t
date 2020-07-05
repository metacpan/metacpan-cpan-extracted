#!/usr/bin/perl

use v5.14;  # package NAME {BLOCK}
use warnings;

use Test::More;

use Metrics::Any '$metrics';

package Metrics::Any::Adapter::localTestAdapter {
   use base "Metrics::Any::AdapterBase::Stored";

   # push to an array
   sub store_distribution
   {
      my ( undef, $storage, $amount ) = @_;
      push @$storage, $amount;
      return $storage;
   }

   # summarize
   sub store_timer
   {
      my ( undef, $storage, $duration ) = @_;
      $storage->{total} += $duration;
      $storage->{count} += 1;
      return $storage;
   }
}

use Metrics::Any::Adapter 'localTestAdapter';

{
   $metrics->make_counter( counter => );
   $metrics->make_distribution( distribution => );
   $metrics->make_gauge( gauge => );
   $metrics->make_timer( timer => );

   $metrics->inc_counter( counter => );

   $metrics->report_distribution( distribution => 1 );
   $metrics->report_distribution( distribution => 3 );
   $metrics->report_distribution( distribution => 5 );

   $metrics->inc_gauge_by( gauge => 5 );

   $metrics->report_timer( timer => 2 );
   $metrics->report_timer( timer => 4 );

   # Also test labels

   $metrics->make_counter( labeled_counter =>
      labels => [qw( x y )],
   );
   $metrics->inc_counter( labeled_counter => { x => 10, y => 20 } );

   my @walkdata;
   Metrics::Any::Adapter->adapter->walk( sub {
      my ( $type, $name, $labels, $value ) = @_;
      push @walkdata, [ $type, $name, $labels, $value ];
   } );

   is_deeply( \@walkdata, [
      [ counter => counter => [], 1 ],

      [ distribution => distribution => [], [ 1, 3, 5 ] ],

      [ gauge => gauge => [], 5 ],

      [ counter => labeled_counter => [ x => 10, y => 20 ], 1 ],

      [ timer => timer => [], { total => 6, count => 2 } ],
   ], 'metrics to ->walk' );
}

done_testing;
