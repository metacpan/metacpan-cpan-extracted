#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use DateTimeX::Period qw();

my ( $dt, $keys );

my $minute = 60;
my $hour   = 60 * 60;
my $day    = 60 * 60 * 24;

# Following epoch is special in UTC, as it is start of the month, week, day,
# hour and 10 minutes
my $start = 1409529600; # Monday 01/09/2014 00:00:00

sub test_start
{
	my ( $epoch, $period, $comment ) = @_;
	my $dt = DateTimeX::Period->from_epoch( epoch => $epoch);

	is( $dt->get_start($period)->epoch(), $start, $comment );
}

# add random number of seconds and try to get the start of the period
test_start($start +  9 * $minute, '10 minutes', 'Get the start of 10 minutes');
test_start($start + 59 * $minute, 'hour',       'Get the start of hour');
test_start($start + 23 * $hour,   'day',        'Get the start of day');
test_start($start +  6 * $day,    'week',       'Get the start of week');
test_start($start + 29 * $day,    'month',      'Get the start of month');

# Try to get the start of the interval, when it matches the start
test_start($start,                '10 minutes', '10 minutes boundary test');
test_start($start,                'hour',       'hour boundary test');
test_start($start,                'day',        'day boundary test');
test_start($start,                'week',       'week boundary test');
test_start($start,                'month',      'month boundary test');

sub test_end
{
	my ( $expectation, $period, $comment ) = @_;
	my $dt = DateTimeX::Period->from_epoch( epoch => $start);

	is( $dt->get_end($period)->epoch(), $expectation, $comment );
}

test_end($start + 10 * $minute, '10 minutes', 'Get the end of 10 minutes');
test_end($start +  1 * $hour,   'hour',       'Get the end of hour');
test_end($start +  1 * $day,    'day',        'Get the end of day');
test_end($start +  7 * $day,    'week',       'Get the end of week');
test_end($start + 30 * $day,    'month',      'Get the end of month');

done_testing();
