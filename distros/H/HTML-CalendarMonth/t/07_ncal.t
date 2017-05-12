#!/usr/bin/perl

use strict;
use FindBin;
use lib $FindBin::RealBin;

use testload;

my($test_count, $method);
BEGIN {
  $method = 'ncal';
  $test_count = bulk_count() + odd_count() + woy_count() + 3;
}

use Test::More tests => $test_count;

use constant DTC => 'HTML::CalendarMonth::DateTool';

use_ok(DTC);

SKIP: {
  skip("$method not installed", $test_count - 1) unless DTC->_ncal_cmd;
  check_datetool($method);
  check_bulk_with_datetool($method);
  check_odd_with_datetool($method);
  check_woy_with_datetool($method);
}
