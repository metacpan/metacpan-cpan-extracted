#!/usr/bin/perl

use v5.14;  # package NAME {BLOCK}
use warnings;

use Test2::V0;

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
   packages => {
      "RedPackage" => 'red',
      "BluePackage" => 'blue',
      "GreenPackage::*" => 'green',
   },
);

{
   package RedPackage;
   use Metrics::Any '$metrics', strict => 0;

   $metrics->make_counter( counter => );
   $metrics->inc_counter( counter => );
}

{
   package BluePackage;
   use Metrics::Any '$metrics', strict => 0;

   $metrics->make_counter( counter => );
   $metrics->inc_counter( counter => );
}

is( \%metricsred, { "RedPackage/counter" => 1 },
   'Metrics routed to red adapter' );

is( \%metricsblue, { "BluePackage/counter" => 1 },
   'Metrics routed to blue adapter' );

is( \%metricsmagenta, { "RedPackage/counter" => 1, "BluePackage/counter" => 1 },
   'Metrics routed to magenta adapter' );

# Package wildcard tests
{
   use Metrics::Any '$metrics';

   is( $metrics->adapter->category_for_package( "GreenPackage::Helper" ), "green",
      'category_for_package accepts wildcard subpackage' );

   is( $metrics->adapter->category_for_package( "GreenPackage" ), "green",
      'category_for_package accepts wildcard package itself' );

   is( $metrics->adapter->category_for_package( "YellowPackage" ), undef,
      'category_for_package does not spinlock on unrecognised package' );
}

done_testing;
