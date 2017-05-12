#/usr/bin/perl
use warnings;
use strict;
use Test::More tests => 7;
use lib ('lib');

BEGIN { use_ok( 'Math::PercentChange', qw(f_percent_change) ); }

is( f_percent_change(10, 15, "%.03f", 1), "50.000", "three digit decimal positive no perc");
is( f_percent_change(10, 5, "%.03f", 1), "-50.000", "three digit decimal negative no perc");
is( f_percent_change(10, 15, "%.0d", 1), "50", "integer positive no perc");
is( f_percent_change(10, 5, "%.0d", 1), "-50", "integer negative no perc");
is( f_percent_change(0, 10), undef, "zero from");
is( f_percent_change(0, 0), undef, "both zero");
