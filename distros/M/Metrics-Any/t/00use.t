#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use_ok( "Metrics::Any" );
use_ok( "Metrics::Any::Adapter" );
use_ok( "Metrics::Any::Collector" );

use_ok( "Metrics::Any::Adapter::File" );
use_ok( "Metrics::Any::Adapter::Null" );
use_ok( "Metrics::Any::Adapter::Stderr" );
use_ok( "Metrics::Any::Adapter::Test" );

done_testing;
