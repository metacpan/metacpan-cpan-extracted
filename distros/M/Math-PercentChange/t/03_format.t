#/usr/bin/perl
use warnings;
use strict;
use Test::More tests => 7;
use lib ('lib');

BEGIN { use_ok( 'Math::PercentChange', qw(f_percent_change) ); }

is( f_percent_change(10, 15, "%.03f"), "50.000%", "three digit decimal positive");
is( f_percent_change(10, 5, "%.03f"), "-50.000%", "three digit decimal negative");
is( f_percent_change(10, 15, "%.0d"), "50%", "integer positive");
is( f_percent_change(10, 5, "%.0d"), "-50%", "integer negative");
is( f_percent_change(0, 10), undef, "zero from");
is( f_percent_change(0, 0), undef, "both zero");
