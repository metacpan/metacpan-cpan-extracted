#!/usr/bin/env perl

# run this with 'prove -v run_unit_tests' to run them all in verbose mode.

# to test a single class:
# TEST_CLASS='Test::Google::RestApi::SheetsApi4::Range::Col' prove -v t/run_unit_tests.t
#
# to run a single method:
# TEST_CLASS='Test::Google::RestApi::SheetsApi4::Range::Col' TEST_METHOD=test_this prove -v t/run_unit_tests.t
#
# to regenerate mock data from live data (point to your live config and use the provided logger):
# GOOGLE_RESTAPI_CONFIG=~/.google/rest_api.yaml GOOGLE_RESTAPI_LOGGER=t/etc/log4perl.conf prove -v t/run_unit_tests.t 
#
# When doing a lot of bulk live tests, set 'throttle: 1' in your config to avoid 429's.

use strict;
use warnings;

use FindBin;
use Module::Load;

use Test::Class;

use lib "$FindBin::RealBin/../lib";
use lib "$FindBin::RealBin/lib";
use lib "$FindBin::RealBin/unit";

if ($ENV{TEST_CLASS}) {
    load($ENV{TEST_CLASS});
} else {
    load('Test::Class::Load');
    Test::Class::Load->import("$FindBin::RealBin/unit");
}

Test::Class->runtests();
