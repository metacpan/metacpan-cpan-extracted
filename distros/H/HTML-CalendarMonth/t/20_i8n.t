#!/usr/bin/perl

use strict;
use FindBin;
use lib $FindBin::RealBin;

use testload;

my $test_count;
BEGIN { $test_count = i8n_count() + 1 }

use Test::More tests => $test_count;

use HTML::CalendarMonth::Locale;

my @stoof = HTML::CalendarMonth::Locale->locales;
ok(@stoof > 20, 'i8n: ' . scalar @stoof . ' locale ids retreived');
check_i8n();
