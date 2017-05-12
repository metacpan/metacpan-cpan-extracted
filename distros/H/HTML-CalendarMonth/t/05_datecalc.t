#!/usr/bin/perl

use strict;
use FindBin;
use lib $FindBin::RealBin;

use testload;

my($test_count, $method);
BEGIN {
  $method = 'Date::Calc';
  $test_count = bulk_count() + odd_count() + woy_count() + 2;
}

use Test::More tests => $test_count;

SKIP: {
  eval "use $method";
  skip("$method not installed", $test_count) if $@;
  check_datetool($method);
  check_bulk_with_datetool($method);
  check_odd_with_datetool($method);
  check_woy_with_datetool($method);
}
