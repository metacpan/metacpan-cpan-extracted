#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Metrics::Any '$metrics',
   name_prefix => [qw( testing )];
use Metrics::Any::Adapter 'Test';

# Force the adapter to exist
$metrics->adapter;

# Prefix is applied
{
   Metrics::Any::Adapter::Test->clear;

   $metrics->make_counter( c => name => [qw( counter )] );
   $metrics->inc_counter( c => );

   $metrics->make_distribution( d => name => [qw( distribution )] );
   $metrics->report_distribution( d => 100 );

   $metrics->make_gauge( g => name => [qw( gauge )] );
   $metrics->inc_gauge( g => );

   $metrics->make_timer( t => name => [qw( timer )] );
   $metrics->report_timer( t => 2 );

   is( Metrics::Any::Adapter::Test->metrics, <<'EOF',
testing_counter = 1
testing_distribution_count = 1
testing_distribution_total = 100
testing_gauge = 1
testing_timer_count = 1
testing_timer_total = 2
EOF
      'Metrics have name prefices' );
}

# Default names
{
   Metrics::Any::Adapter::Test->clear;

   $metrics->make_counter( 'c2' );
   $metrics->inc_counter( c2 => );

   $metrics->make_distribution( 'd2' );
   $metrics->report_distribution( d2 => 100 );

   $metrics->make_gauge( 'g2' );
   $metrics->inc_gauge( g2 => );

   $metrics->make_timer( 't2' );
   $metrics->report_timer( t2 => 2 );

   is( Metrics::Any::Adapter::Test->metrics, <<'EOF',
testing_c2 = 1
testing_d2_count = 1
testing_d2_total = 100
testing_g2 = 1
testing_t2_count = 1
testing_t2_total = 2
EOF
      'Metrics have name prefices' );
}

done_testing;
