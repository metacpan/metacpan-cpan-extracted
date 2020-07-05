#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Metrics::Any::Adapter 'Null';
use Metrics::Any '$metrics';

ok( defined $metrics, '$metrics is defined' );
ok( $metrics,         '$metrics appears true before adapter' );

# Force creation of the adapter
$metrics->adapter;

ok( !$metrics,        '$metrics appears false with adapter' );

ok( defined eval { $metrics->make_counter( "events" ); 1 },
   '$metrics->make_counter' ) or diag( $@ );

ok( defined eval { $metrics->inc_counter( "events" ); 1 },
   '$metrics->inc_counter' ) or diag( $@ );

ok( defined eval { $metrics->make_distribution( "bytes" ); 1 },
   '$metrics->make_distribution' ) or diag( $@ );

ok( defined eval { $metrics->report_distribution( "bytes", 20 ); 1 },
   '$metrics->report_distribution' ) or diag( $@ );

ok( defined eval { $metrics->make_gauge( "size" ); 1 },
   '$metrics->make_gauge' ) or diag( $@ );

ok( defined eval { $metrics->inc_gauge_by( "size", 20 ); 1 },
   '$metrics->inc_gauge_by' ) or diag( $@ );

ok( defined eval { $metrics->set_gauge_to( "size", 50 ); 1 },
   '$metrics->set_gauge_to' ) or diag( $@ );

ok( defined eval { $metrics->make_timer( "duration" ); 1 },
   '$metrics->make_timer' ) or diag( $@ );

ok( defined eval { $metrics->report_timer( "duration", 20 ); 1 },
   '$metrics->report_timer' ) or diag( $@ );

ok( !$metrics, '$metrics is still false at EOF' );

done_testing;
