#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use IO::Handle;
use Errno qw( EAGAIN EWOULDBLOCK );

use Metrics::Any '$metrics';
require Metrics::Any::Adapter; # no 'use' yet

sub readall
{
   my $ret = $_[0];
   $_[0] = "";
   return $ret;
}

open my $fh, ">>", \( my $buf = "" );

# fh isn't documented but useful for this unit test
Metrics::Any::Adapter->import( File => fh => $fh );

# Force the adapter to exist
$metrics->adapter;

ok( $metrics, '$metrics is still true' );

# counter
{
   $metrics->make_counter( c => name => "counter" );

   $metrics->inc_counter( c => );

   is( readall( $buf ), "METRIC COUNTER counter +1 => 1\n",
      'Counter metric written' );

   $metrics->inc_counter_by( c => 3 );

   is( readall( $buf ), "METRIC COUNTER counter +3 => 4\n",
      'Counter persists total' );
}

# distribution
{
   $metrics->make_distribution( d => name => "distribution" );

   $metrics->report_distribution( d => 5 );

   is( readall( $buf ), "METRIC DISTRIBUTION distribution +5 => 5/1 [avg=5]\n",
      'Distribution metric written' );

   $metrics->report_distribution( d => 3 );

   is( readall( $buf ), "METRIC DISTRIBUTION distribution +3 => 8/2 [avg=4]\n",
      'Distribution persists total and count' );
}

# gauge
{
   $metrics->make_gauge( g => name => "gauge" );

   $metrics->inc_gauge( g => );

   is( readall( $buf ), "METRIC GAUGE gauge +1 => 1\n",
      'Gauge metric written' );

   $metrics->inc_gauge_by( g => 2 );

   is( readall( $buf ), "METRIC GAUGE gauge +2 => 3\n",
      'Gauge persists total' );
}

# timer
{
   $metrics->make_timer( t => name => "timer" );

   $metrics->report_timer( t => 0.02 );

   is( readall( $buf ), "METRIC TIMER timer +0.02 => 0.02/1 [avg=0.02]\n",
      'Timer metric written' );

   $metrics->report_timer( t => 0.04 );

   is( readall( $buf ), "METRIC TIMER timer +0.04 => 0.06/2 [avg=0.03]\n",
      'Timer persists total and count' );
}

ok( $metrics, '$metrics is still true at EOF' );

done_testing;
