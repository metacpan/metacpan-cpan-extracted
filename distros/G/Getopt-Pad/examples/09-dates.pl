#!/usr/bin/env perl

# Dates and lengths of time in natural language: the 'date' and 'duration'
# types, a fixed 'timezone', and 'processValue' turning a duration into a
# number of seconds. Both types need DateTime::Format::Natural; without it,
# GetOptions stops with a spec error that names the module.
#
# Try:
#   perl examples/09-dates.pl --since yesterday --keep-for '2 weeks'
#   perl examples/09-dates.pl --since 'last monday' --at '2026-10-06 14:00'
#   perl examples/09-dates.pl --timeout '2 hours'
#   perl examples/09-dates.pl --since soon               (fails: not a date)
#   perl examples/09-dates.pl --keep-for 1h              (fails: units are written out)
#   perl examples/09-dates.pl --help                     (defaults shown as written)

use v5.26;
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use DateTime;
use Getopt::Pad;

# A DateTime::Duration keeps months, days and minutes apart; adding it to
# the current time converts them with the real calendar.
sub inSeconds {
	my ($opt, $duration) = @_;
	my $now = DateTime->now;
	return $now->clone->add_duration($duration)->subtract_datetime_absolute($now)->seconds;
}

my $opt = GetOptions(
	options => {
		'since'    => { type => 'date', default => '7 days ago', help => 'Report changes since this date' },
		'at'       => { type => 'date', timezone => 'UTC', help => 'When to run, in UTC' },
		'keep-for' => { type => 'duration', default => '30 days', help => 'How long to keep old backups' },
		'timeout'  => { type => 'duration', default => '90 seconds', processValue => \&inSeconds, help => 'How long to wait, read as seconds' },
	},
	description => 'Demonstrate the date and duration types.',
);

sub describeDate {
	my ($date) = @_;
	return 'undef' if !defined $date;
	return sprintf('%s (%s)', $date, $date->time_zone->name);
}

my ($months, $days, $minutes) = $opt->keepFor->in_units(qw(months days minutes));

say 'since   = ', describeDate($opt->since);
say 'at      = ', describeDate($opt->at);
printf "keepFor = %d months, %d days, %d minutes\n", $months, $days, $minutes;
say 'timeout = ', $opt->timeout, ' seconds';
say 'cutoff  = ', DateTime->now->subtract_duration($opt->keepFor), ' (now minus keepFor)';
