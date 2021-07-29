#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

BEGIN {
   $ENV{METRICS_ANY_DISABLE} = "APackage,ANamespace::*";
}

use Metrics::Any::Adapter 'Test';
require Metrics::Any::Adapter::Test;

package APackage {
   use Metrics::Any '$metrics';
   $metrics->adapter;

   Test::More::ok( !$metrics, '$metrics is false in disabled package' );

   $metrics->make_counter( c => name => [qw( counter )] );
   $metrics->inc_counter( c => );

   Test::More::is( Metrics::Any::Adapter::Test->metrics, "",
      'No metrics in disabled package' );
}

package ANamespace {
   use Metrics::Any '$metrics';
   $metrics->adapter;

   Test::More::ok( !$metrics, '$metrics is false in disabled namespace' );

   $metrics->make_counter( c => name => [qw( counter )] );
   $metrics->inc_counter( c => );

   Test::More::is( Metrics::Any::Adapter::Test->metrics, "",
      'No metrics in disabled namespace' );
}

package ANamespace::here {
   use Metrics::Any '$metrics';
   $metrics->adapter;

   Test::More::ok( !$metrics, '$metrics is false in subpackage of disabled namespace' );

   $metrics->make_counter( c => name => [qw( counter )] );
   $metrics->inc_counter( c => );

   Test::More::is( Metrics::Any::Adapter::Test->metrics, "",
      'No metrics in subpackage of disabled namespace' );
}

package BPackage {
   use Metrics::Any '$metrics';

   Test::More::ok( $metrics, '$metrics is true in non-disabled package' );

   $metrics->make_counter( c => name => [qw( counter )] );
   $metrics->inc_counter( c => );

   Test::More::is( Metrics::Any::Adapter::Test->metrics, <<'EOF',
counter = 1
EOF
      'Metrics in non-disabled package still work' );
}

done_testing;
