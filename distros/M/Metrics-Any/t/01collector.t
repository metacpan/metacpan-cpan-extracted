#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Metrics::Any '$metrics';

ok( defined $metrics, '$metrics global is defined' );

can_ok( $metrics,
   qw( make_counter inc_counter inc_counter_by ));

can_ok( $metrics,
   qw( make_distribution inc_distribution_by ));

can_ok( $metrics,
   qw( make_gauge inc_gauge inc_gauge_by dec_gauge_by dec_gauge set_gauge_to ));

can_ok( $metrics,
   qw( make_timer inc_timer_by ));

done_testing;
