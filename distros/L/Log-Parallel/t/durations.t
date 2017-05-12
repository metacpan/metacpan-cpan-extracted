#!/usr/bin/perl 

use strict;
use warnings;
use Test::More qw(no_plan);
use Log::Parallel::Durations;
use Time::JulianDay;

my $finished = 0;

END { ok($finished, 'finished') }

my ($timeinfo, @range);

($timeinfo, @range) = frequency_and_span(
	{
		frequency	=> 'on the 3rd wednesday each month',
	},
	julian_day(2008, 4, 20),
	julian_day(2008, 3, 1),
	julian_day(2008, 9, 20),
);

is($timeinfo, undef, "april 20th, 2008 isn't a 3rd wednesday");
is(scalar(@range), 0, "april 20th, 2008 isn't a 3rd wednesday");

($timeinfo, @range) = frequency_and_span(
	{
	},
	julian_day(2008, 4, 16),
	julian_day(2008, 3, 1),
	julian_day(2008, 9, 20),
);

ok($timeinfo, "every day is a day");
is(scalar(@range), 1, "a day is one day long");


($timeinfo, @range) = frequency_and_span(
	{
		frequency	=> 'on the 3rd wednesday each month',
	},
	julian_day(2008, 4, 16),
	julian_day(2008, 3, 1),
	julian_day(2008, 9, 20),
);

ok($timeinfo, "april 16th, 2008 is a 3rd wednesday");
is(scalar(@range), 31, 'march has 31 days');

($timeinfo, @range) = frequency_and_span(
	{
		frequency	=> 'every 3 weeks',
	},
	julian_day(2008, 3, 22),
	julian_day(2008, 3, 1),
	julian_day(2008, 9, 20),
);

ok($timeinfo, "the 22nd is 3 weeks after the 1st");
is(scalar(@range), 21, '3 weeks is 21 days');

($timeinfo, @range) = frequency_and_span(
	{
		frequency	=> 'every 3 weeks',
	},
	julian_day(2008, 3, 21),
	julian_day(2008, 3, 1),
	julian_day(2008, 9, 20),
);

ok(! $timeinfo, "the 21st is not 3 weeks after the 1st");

($timeinfo, @range) = frequency_and_span(
	{
		frequency	=> 'every week',
	},
	julian_day(2008, 3, 22),
	julian_day(2008, 3, 1),
	julian_day(2008, 9, 20),
);

is(scalar(@range), 7, 'a week is 7 days');

($timeinfo, @range) = frequency_and_span(
	{
		frequency	=> 'every week',
	},
	julian_day(2008, 3, 21),
	julian_day(2008, 3, 1),
	julian_day(2008, 9, 20),
);

ok(! $timeinfo, "a week doesn't end every day");

($timeinfo, @range) = frequency_and_span(
	{
		frequency	=> 'on the 19th',
	},
	julian_day(2008, 3, 21),
	julian_day(2008, 3, 1),
	julian_day(2008, 9, 20),
);

ok(! $timeinfo, "the 19th is not the 21st");

($timeinfo, @range) = frequency_and_span(
	{
		frequency	=> 'on the 19th',
	},
	julian_day(2008, 2, 19),
	julian_day(2008, 2, 1),
	julian_day(2008, 9, 20),
);

ok($timeinfo, "the 19th is the 19th");
is(scalar(@range), 31, 'januaray has 31 days');

($timeinfo, @range) = frequency_and_span(
	{
		frequency	=> 'on the 19th',
	},
	julian_day(2008, 3, 19),
	julian_day(2008, 3, 1),
	julian_day(2008, 9, 20),
);

is(scalar(@range), 29, 'february sometimes has 29 days');

eval {
	($timeinfo, @range) = frequency_and_span(
		{
			frequency	=> 'on the 19nd',
		},
		julian_day(2008, 3, 19),
		julian_day(2008, 3, 1),
		julian_day(2008, 9, 20),
	);
};

ok($@, "we are pedants about numbers");

$finished = 1;
