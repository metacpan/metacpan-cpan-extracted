#!/usr/bin/perl

use strict;
use FindBin;
use lib $FindBin::RealBin;

use testload;

my $test_count;
BEGIN { $test_count = narrow_count() }

use Test::More tests => $test_count;

use HTML::CalendarMonth::Locale;

check_narrow();
