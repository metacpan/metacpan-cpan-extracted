#/usr/bin/perl
use warnings;
use strict;
use Test::More tests => 8;
use lib ('lib');

BEGIN { use_ok( 'Math::PercentChange', qw(f_percent_change) ); }

is( f_percent_change(10, 15), "50.00%", "positive");
is( f_percent_change(10, 5), "-50.00%", "negative");
is( f_percent_change(7, 5), "-28.57%", "less");
is( f_percent_change(5, 7), "40.00%", "greater");
is( f_percent_change(-10, 0), "100.00%", "negative from");
is( f_percent_change(0, 10), undef, "zero from");
is( f_percent_change(0, 0), undef, "both zero");
