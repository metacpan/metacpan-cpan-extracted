#!perl

use strict;
use warnings;

use Test::More;
use HTTP::Date qw(str2time parse_date);

# Regression/characterization test for GitHub #10 (rt.cpan.org #94151).
#
# Numeric-only slash dates are parsed in day/month/year order (the ISO and
# common European convention), NOT US month/day/year order.  This is a
# deliberate, documented contract: changing it would silently re-interpret
# existing dates for every downstream caller.
#
# So '3/12/2014' is 12 March-style ordering => day 3, month 12 (December),
# and '3/13/2014' is rejected because 13 is not a valid month.

is(
    str2time( '3/12/2014 0:00', 'GMT' ),
    str2time( '3 Dec 2014 0:00', 'GMT' ),
    'numeric N/N/YYYY uses day/month order: 3/12 == 3 December'
);

is( str2time( '3/13/2014 0:00', 'GMT' ),
    undef, 'second field is the month: 13 is invalid, so undef' );

is( str2time( '13/3/2014 0:00', 'GMT' ),
    str2time( '13 Mar 2014 0:00', 'GMT' ),
    'day may exceed 12: 13/3 == 13 March' );

# parse_date reports the same day/month ordering.
is_deeply(
    [ ( parse_date('3/12/2014') )[ 0, 1, 2 ] ],
    [ 2014, 12, 3 ],
    'parse_date(3/12/2014) => year 2014, month 12, day 3'
);

done_testing;
