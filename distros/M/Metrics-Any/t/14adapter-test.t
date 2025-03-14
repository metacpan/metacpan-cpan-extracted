#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Metrics::Any '$metrics';
use Metrics::Any::Adapter 'Test';

# Force the adapter to exist
$metrics->adapter;

ok( $metrics, '$metrics is still true' );

# unlabelled
{
   Metrics::Any::Adapter::Test->clear;

   $metrics->make_counter( abc => name => "the_ABC_counter" );
   $metrics->make_counter( def => name => [qw( the DEF counter )] );

   $metrics->inc_counter( 'abc' );

   $metrics->inc_counter( 'def' );
   $metrics->inc_counter( 'def' );
   $metrics->inc_counter( 'def' );

   is( Metrics::Any::Adapter::Test->metrics,
      "the_ABC_counter = 1\n" .
      "the_DEF_counter = 3\n",
      'Metrics::Any::Adapter::Test->metrics for basic metrics'
   );
}

# with labels
{
   Metrics::Any::Adapter::Test->clear;

   $metrics->make_counter( ghi =>
      name   => "the_GHI_counter",
      labels => [qw( label )],
   );
   $metrics->make_counter( jkl =>
      name   => "the_JKL_counter",
      labels => [qw( x y )],
   );

   # inc by ARRAYref
   $metrics->inc_counter( ghi => [ label => "value" ] );
   $metrics->inc_counter( jkl => [ x => 10, y => 20 ] );
   is( Metrics::Any::Adapter::Test->metrics,
      "the_GHI_counter label:value = 1\n" .
      "the_JKL_counter x:10 y:20 = 1\n",
      'Metrics::Any::Adapter::Test->metrics after increment with label by ARRAYref'
   );

   # inc by HASHref
   $metrics->inc_counter( ghi => { label => "value" } );
   $metrics->inc_counter( jkl => { x => 10, y => 20 } );
   is( Metrics::Any::Adapter::Test->metrics,
      "the_GHI_counter label:value = 2\n" .
      "the_JKL_counter x:10 y:20 = 2\n",
      'Metrics::Any::Adapter::Test->metrics after increment with label by HASHref'
   );

   # legacy inc by list of values
   $metrics->inc_counter( ghi => "value" );
   $metrics->inc_counter( jkl => 10, 20 );

   is( Metrics::Any::Adapter::Test->metrics,
      "the_GHI_counter label:value = 3\n" .
      "the_JKL_counter x:10 y:20 = 3\n",
      'Metrics::Any::Adapter::Test->metrics after increment with label by legacy value list'
   );
}

# distributions
{
   Metrics::Any::Adapter::Test->clear;

   $metrics->make_distribution( distribution => name => "the_ABC_distribution" );

   $metrics->report_distribution( distribution => 150 );

   is( Metrics::Any::Adapter::Test->metrics,
      "the_ABC_distribution_count = 1\n" .
      "the_ABC_distribution_total = 150\n",
      'Metrics::Any::Adapter::Test->metrics after ->report_distribution'
   );
}

# gauges
{
   Metrics::Any::Adapter::Test->clear;

   $metrics->make_gauge( gauge => name => "the_ABC_gauge" );

   $metrics->set_gauge_to( gauge => 30 );

   is( Metrics::Any::Adapter::Test->metrics,
      "the_ABC_gauge = 30\n",
      'Metrics::Any::Adapter::Test->metrics after ->set_gauge_to'
   );

   $metrics->inc_gauge_by( gauge => 10 );

   is( Metrics::Any::Adapter::Test->metrics,
      "the_ABC_gauge = 40\n",
      'Metrics::Any::Adapter::Test->metrics after ->inc_gauge_by'
   );
}

# timers
{
   Metrics::Any::Adapter::Test->clear;

   $metrics->make_timer( timer => name => "the_ABC_timer" );

   $metrics->report_timer( timer => 0.02 );

   is( Metrics::Any::Adapter::Test->metrics,
      "the_ABC_timer_count = 1\n" .
      "the_ABC_timer_total = 0.02\n",
      'Metrics::Any::Adapter::Test->metrics after ->report_timer'
   );
}

# full distributions
{
   Metrics::Any::Adapter::Test->clear;

   Metrics::Any::Adapter::Test->use_full_distributions;

   $metrics->make_distribution( fulldist => name => "the_full_distribution" );

   $metrics->report_distribution( fulldist => 1 );
   $metrics->report_distribution( fulldist => 2 );
   $metrics->report_distribution( fulldist => 3 );

   is( Metrics::Any::Adapter::Test->metrics,
      "the_full_distribution[1] = 1\n" .
      "the_full_distribution[2] = 1\n" .
      "the_full_distribution[3] = 1\n" .
      "the_full_distribution_count = 3\n",
      'Metrics::Any::Adapter::Test->metrics after ->report_distribution on full distribution'
   );
}

# batch mode is supported
{
   Metrics::Any::Adapter::Test->clear;

   my $called;

   my $batch_ok = $metrics->add_batch_mode_callback( sub {
      $called++;
      $metrics->inc_counter_by( abc => 100 );
      $metrics->set_gauge_to( gauge => 25 );
   } );
   ok( $batch_ok, 'Test adapter supports batch mode' );

   ok( !$called, 'Batch mode callback not yet invoked' );

   is( Metrics::Any::Adapter::Test->metrics,
      "the_ABC_counter = 100\n" .
      "the_ABC_gauge = 25\n",
      'Metrics::Any::Adapter::Test->metrics contains batch-reported values' );
   ok( $called, 'Batch mode callback invoked by ->metrics' );
}

ok( $metrics, '$metrics is still true at EOF' );

done_testing;
