#!/usr/bin/perl

use v5.14;  # package NAME {BLOCK}
use warnings;

use Test::More;

use Metrics::Any '$metrics', strict => 0;

package Metrics::Any::Adapter::_ToHash {
   sub new {
      my $class = shift;
      return bless { h => shift }, $class;
   }

   sub make_counter {}
   sub make_distribution {}
   sub make_gauge {}
   sub make_timer {}

   sub _inc { $_[0]->{h}->{$_[1]} += $_[2] }
   no warnings 'once';
   *inc_counter_by = *report_distribution = *inc_gauge_by = *report_timer = \&_inc;
}

my %metrics1;
my %metrics2;

require Metrics::Any::Adapter;
Metrics::Any::Adapter->import( Tee =>
   [ _ToHash => \%metrics1 ],
   [ _ToHash => \%metrics2 ],
);

$metrics->inc_counter( counter => );
$metrics->report_distribution( distribution => 5 );
$metrics->inc_gauge( gauge => );
$metrics->report_timer( timer => 0.1 );

my %expect = (
   'main/counter'      => 1,
   'main/distribution' => 5,
   'main/gauge'        => 1,
   'main/timer'        => 0.1,
);

is_deeply( \%metrics1, \%expect, 'Metrics reported to first adapter' );
is_deeply( \%metrics2, \%expect, 'Metrics reported to second adapter' );

done_testing;
