#!/usr/bin/perl

use strict;
use FindBin;
use lib $FindBin::RealBin;

use testload;

use HTML::CalendarMonth::DateTool;

my($test_count, $detected);
BEGIN {
  $test_count = bulk_count() + 1;
  eval { $detected = HTML::CalendarMonth::DateTool->new };
}

use Test::More tests => $test_count;

ok($detected, 'auto-detected a datetool');

SKIP: {
  skip("no datetools installed", $test_count - 1) unless $detected;
  check_bulk_with_datetool();
}
