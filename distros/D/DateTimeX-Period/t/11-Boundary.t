#!/usr/bin/env perl

use warnings;
use strict;

use Test::More;
use Test::Exception;
use DateTimeX::Period qw();

my $dt;
my $day = 60*60*24; # a day in seconds

# Test that library works in year > 2038
my $friday = 4126032000; # Friday 01/10/2100 00:00:00

lives_ok {
	$dt = DateTimeX::Period->from_epoch( epoch => $friday + 8 * $day )
} 'Lives ok on year > 2038';

# Checking that start of October for year 2100 is Friday 01/10/2100 00:00:00
is(
	$dt->get_start('month')->epoch(),
	$friday,
	'Checking that module works correctly in year 2100'
);

# Test week boundary, which crosses month boundary, i.e. end of the week is
# after the 1st of month, but start of the week is before the 1st.
$dt = DateTimeX::Period->new(
	year => 2014,
	month => 2,
	day   => 2,
);

is (
	$dt->get_start('week')->ymd(),
	'2014-01-27',
	'can get start of the week that passes month boundary during the week.'
);

is (
	$dt->get_end('week')->ymd(),
	'2014-02-03',
	'can get end of the week that passes month boundary during the week.'
);

done_testing();
