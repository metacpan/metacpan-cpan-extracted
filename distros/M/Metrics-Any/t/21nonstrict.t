#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;
use Test::Fatal;

use Metrics::Any '$metrics',
   strict => 0;
use Metrics::Any::Adapter 'Test';

# Force the adapter to exist
$metrics->adapter;

# without labels
{
   Metrics::Any::Adapter::Test->clear;

   $metrics->inc_counter( auto_counter => );

   $metrics->report_distribution( auto_distribution => 5 );

   $metrics->inc_gauge( auto_gauge => );

   $metrics->report_timer( auto_timer => 0.1 );

   is( Metrics::Any::Adapter::Test->metrics, <<'EOF',
auto_counter = 1
auto_distribution_count = 1
auto_distribution_total = 5
auto_gauge = 1
auto_timer_count = 1
auto_timer_total = 0.1
EOF
      'Metrics are registered' );
}

# labelled
{
   Metrics::Any::Adapter::Test->clear;

   $metrics->inc_counter( by_ARRAY => [ one => 1 ] );
   $metrics->inc_counter( by_HASH  => [ two => 2 ] );

   is( Metrics::Any::Adapter::Test->metrics, <<'EOF',
by_ARRAY one:1 = 1
by_HASH two:2 = 1
EOF
      'Metrics are registered with labels' );
}

done_testing;
