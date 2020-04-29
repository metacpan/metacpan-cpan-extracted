#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use_ok( "Metrics::Any::Adapter::Statsd" );
use_ok( "Metrics::Any::Adapter::DogStatsd" );
use_ok( "Metrics::Any::Adapter::SignalFx" );

done_testing;
