#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Metrics::Any '$metrics';
use Metrics::Any::Adapter 'Prometheus';

use Net::Prometheus;

my $prom = Net::Prometheus->new;

# counters
{
   $metrics->make_counter( counter =>
      name => [qw( the counter )],
   );

   $metrics->inc_counter( counter => );

   like( $prom->render,
      qr/^the_counter_total 1/m,
      'Net::Prometheus->render contains Counter metric'
   );
}

# distributions
{
   $metrics->make_distribution( distribution =>
      name => [qw( the distribution )],
      units => "bytes",
   );

   $metrics->inc_distribution_by( distribution => 10000 );

   like( $prom->render,
      qr/^the_distribution_bytes_count 1\nthe_distribution_bytes_sum 10000/m,
      'Net::Prometheus->render contains Histogram metric'
   );

   # Buckets
   my @buckets = grep { m/^the_distribution_bytes_bucket/ } split m/\n/, $prom->render;
   is_deeply( \@buckets,
      [
         'the_distribution_bytes_bucket{le="100"} 0',
         'the_distribution_bytes_bucket{le="1000"} 0',
         'the_distribution_bytes_bucket{le="10000"} 1',
         'the_distribution_bytes_bucket{le="100000"} 1',
         'the_distribution_bytes_bucket{le="1000000"} 1',
         'the_distribution_bytes_bucket{le="10000000"} 1',
         'the_distribution_bytes_bucket{le="100000000"} 1',
         'the_distribution_bytes_bucket{le="+Inf"} 1',
      ],
      'Net::Prometheus->render contains correct Histogram buckets'
   );
}

# gauges
{
   $metrics->make_gauge( gauge =>
      name => [qw( the gauge )],
   );

   $metrics->set_gauge_to( gauge => 123 );

   $metrics->inc_gauge_by( gauge => 45 );

   like( $prom->render,
      qr/^the_gauge 168/m,
      'Net::Prometheus->render contains Gauge metric'
   );
}

# timers
{
   $metrics->make_timer( timer =>
      name => "the_timer",
   );

   $metrics->inc_timer_by( timer => 0.25 );

   like( $prom->render,
      qr/^the_timer_seconds_count 1\nthe_timer_seconds_sum 0\.25/m,
      'Net::Prometheus->render contains Histogram metric for timer'
   );
}

done_testing;
