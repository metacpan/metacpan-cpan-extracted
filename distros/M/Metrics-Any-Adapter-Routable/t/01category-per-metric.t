#!/usr/bin/perl

use v5.14;  # package NAME {BLOCK}
use warnings;

use Test2::V0;

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

require Metrics::Any::Adapter;
Metrics::Any::Adapter->import( Routable =>
   # categories => [qw( red blue )],
   targets => [
      [ red  => _ToHash => \my %metricsred ],
      [ blue => _ToHash => \my %metricsblue ],
      [ [qw( red blue )] => _ToHash => \my %metricsmagenta ],
   ],
);

$metrics->make_counter( redcounter =>
   category => "red" );
$metrics->inc_counter( redcounter => );

$metrics->make_counter( bluecounter =>
   category => "blue" );
$metrics->inc_counter( bluecounter => );

is( \%metricsred, { "main/redcounter" => 1 },
   'Metrics routed to red adapter' );

is( \%metricsblue, { "main/bluecounter" => 1 },
   'Metrics routed to blue adapter' );

is( \%metricsmagenta, { "main/redcounter" => 1, "main/bluecounter" => 1 },
   'Metrics routed to magenta adapter' );

done_testing;
