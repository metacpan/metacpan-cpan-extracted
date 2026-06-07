#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

require Metrics::Any::Adapter::Statsd;
require Metrics::Any::Adapter::DogStatsd;
require Metrics::Any::Adapter::SignalFx;

pass( 'Modules loaded' );
done_testing;
