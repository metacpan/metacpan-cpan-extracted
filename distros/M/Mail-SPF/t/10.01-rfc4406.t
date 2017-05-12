use strict;
use warnings;
use blib;

use Test::More;

eval("use Mail::SPF::Test");
plan(skip_all => "Mail::SPF::Test required for testing Mail::SPF's RFC compliance") if $@;

require('t/Mail-SPF-Test-lib.pm');

run_spf_test_suite_file('t/rfc4406-tests.yml');
