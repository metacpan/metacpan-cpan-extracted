#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

require Metrics::Any;
require Metrics::Any::Adapter;
require Metrics::Any::Collector;

require Metrics::Any::AdapterBase::Stored;

require Metrics::Any::Adapter::File;
require Metrics::Any::Adapter::Null;
require Metrics::Any::Adapter::Stderr;
require Metrics::Any::Adapter::Tee;
require Metrics::Any::Adapter::Test;

pass( "Modules loaded" );
done_testing;
