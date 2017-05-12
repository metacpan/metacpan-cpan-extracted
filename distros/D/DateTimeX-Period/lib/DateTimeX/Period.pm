package DateTimeX::Period;
use parent DateTime;

use 5.006;
use strict;
use warnings FATAL => 'all';

use Carp;
use Try::Tiny;

=head1 NAME

DateTimeX::Period - Provides safe methods to get start and end of period
in all timezones.

=head1 VERSION

This document describes DateTimeX::Period version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

	# Optionally get local timezone
	use DateTime::TimeZone qw();
	my $timezone = DateTime::TimeZone->new( name => 'local' )->name();

	use DateTimeX::Period qw();

	my $dt = DateTimeX::Period->now(
		time_zone => $timezone,
	);
	my $interval_start = $dt->get_start('month');
	my $interval_end   = $dt->get_end('month');

=head1 DESCRIPTION

DateTimeX::Period provides easy yet safe methods to work in period context
such as a day for all timezones. It is a subclass of DateTime, thus benefits
from its great caching.

It is recommended practise to work in UTC and switch to specific timezones only
when needed. IF YOU CAN WORK IN UTC TIME, THEN THIS MODULE IS NOT FOR YOU!!!

Yet sometimes this is not possible and this module may help you. It works
around problems such as Daylight Saving Time ( DST ) that causes DateTime to
throw runtime errors.

=head1 ISSUES THIS MODULE IS TRYING TO SOLVE

1. Assume you want to get start of the month. It's convenient to use
truncate() available in DateTime, however this would throw an error:

 use DateTime;
 my $dt = DateTime->new(
 	year      => 2011,
 	month     => 4,
 	day       => 2,
 	time_zone => 'Asia/Amman'
 );
 $dt->truncate(to => 'month'); # Runtime error

DateTime module throws runtime error, because time between 00:00 - 00:59
01/04/2011 in 'Asia/Amman' did not exist. DateTimeX::Period, on the other hand,
provides get_start method, that returns 01:00 01/04/2011, as that is when month
started. See unit tests for more example that shows that even truncating to
hours can be unsafe!

2. Assume for whatever reason you need to add a day in your code.
Unfortunately, DateTime is unsafe for that:

 use DateTime;
 my $dt = DateTime->new(
 	year      =>2010,
 	month     => 3,
 	day       => 13,
 	minute    => 5,
 	time_zone => 'America/Goose_Bay',
 );
 $dt->add(days => 1); # Runtime error!

Again, 00:05 14/03/2010 did not exist in 'America/Goose_Bay', hence the
runtime error.

3. Assume you are running critical application that needs to get epoch!
Conveniently DateTime has epoch() and for whatever reason you need to perform
some operations, such as these:

 use DateTime;
 my $dt = DateTime->new(
 	year=> 2013,
 	month => 10,
 	day => 26,
 	hour => 23,
 	minute => 59,
	second => 59,
 	time_zone => 'Atlantic/Azores',
 );
 $dt->add( seconds => 1 );    # 2013-10-27T00:00:00  same
 print $dt->epoch();          # 1382832000           diff!!!
 $dt->truncate(to => 'hour'); # 2013-10-27T00:00:00  same
 print $dt->epoch();          # 1382835600           diff!!!

Due to DST, 00:00 occurred twice. DateTime documentation classifies this as
ambiguous and always returns later time! Whereas get_start('hour') would have
returned correct epoch.

=cut

# Valid period keys and labels in preserved order
my @period_lookup = (
    '10 minutes', '10 minutes',
    'hour'      , 'Hour'      ,
    'day'       , 'Day'       ,
    'week'      , 'Week'      ,
    'month'     , 'Month'
);
my ( @ordered_periods, %period_labels );
while (@period_lookup) {
    my $key = shift @period_lookup;
    my $name = shift @period_lookup;
    push(@ordered_periods, $key);
    $period_labels{$key} = $name;
}

=head1 METHODS

=head2 get_start($period)

Returns DateTime object with the start of the given period.

The start date/time depends in which context period is provided:
- if it's a day, than midnight of that day
- if it's a week, than Monday at midnight of that week
- if it's a month, than 1st day at midnight of that month
- and etc.

=cut

sub get_start
{
	my ( $self, $period ) = @_;

	# Unfortunately by design DateTime mutates original object, hence cloning it
	my $dt = $self->clone();

	if ( $period eq '10 minutes' )
	{
		$dt->truncate( to => 'minute')->subtract(minutes => $dt->minute % 10);
		# Perl DateTime library always returns later date, when date occurs
		# twice despite it has ability not to do that. Following while loop
		# checks that start of the 10 minutes period would not be later then
		# original object.
		while ( $dt->epoch > $self->epoch )
		{
			$dt->subtract( minutes => 10 );
		}
		return $dt;
	} elsif ( $period eq 'hour') {
		# truncate to hours is not safe too!!! think of this test case:
		# DateTime->from_epoch(epoch => 1268539500,time_zone => 'America/Goose_Bay')
		# 	->truncate( to => 'hour' );
		#
		# This initialises DateTime object from epoch 1268539500, which
		# corresponds to 2010-03-14 01:05:00, then tries to truncate to hours,
		# but fails/dies, because in some locations such as Newfoundland and
		# Labrador, i.e. ( America/St_Johns ) ( America/Goose_Bay ) on
		# 2010-03-14 clocks moved from 00:01 to 01:01.
		# This library fixes it, by getting start of hour as 00:00 and the end
		# of period 'hour' as 02:00, because 00:01 - 01:01 did not exist.
		try {
			$dt->truncate( to => 'hour' );
		} catch {
			$dt->subtract( minutes => $dt->minute );
		};
		# same reason as with minutes.
		while ($dt->epoch > $self->epoch )
		{
			$dt->subtract( hours => 1 );
		}
		return $dt;
	} elsif ( $period eq 'day') {
		try {
			$dt->truncate( to => 'day' );
		} catch {
			$dt->_get_safe_start('day');
		};
		return $dt;
	} elsif ( $period eq 'week') {
		try {
			$dt->truncate( to => 'week' );
		} catch {
			$dt->_get_safe_start('week');
		};
		return $dt;
	} elsif ( $period eq 'month') {
		try {
			$dt->truncate( to => 'month' );
		} catch {
			$dt->_get_safe_start('month');
		};
		return $dt;
	} else {
		croak "found unknown period '$period'";
	}
}

=head2 get_end($period)

Returns DateTime object with end of the given period, which is same as start
of the next period.

The end date/time depends in which context period is provided:
- if it's a day, than midnight of the next day
- if it's a week, than Monday at midnight of the following week
- if it's a month, than 1st day at midnight of the following month
- and etc.

In cases where midnight does not exist, the start of those periods are not at
midnight, but this should not affect the end of the period, which is the same
as the start of the next period. If it happens to be not at midnight, which
might happen in case of 'day', 'week' or 'month' try to truncate, if it fails
gracefully fallback to another algorithm.

=cut

sub get_end
{
	my ( $self, $period ) = @_;

	# Get the start of the period
	my $dt = $self->get_start($period);

	# Return start of the period + its duration
	if ( $period eq '10 minutes' )
	{
		return $dt->add( minutes => 10 );
	} elsif ( $period eq 'hour') {
		return $dt->add( hours => 1 );
	} elsif ( $period eq 'day') {
		try {
			$dt->add( days => 1 );
			if ($dt->hour() + $dt->minute() + $dt->second > 0)
			{
				$dt->truncate( to => 'day' );
			}
		} catch {
			$dt->_get_safe_end('day');
		};
		return $dt;
	} elsif ( $period eq 'week') {
		try {
			$dt->add( weeks => 1 );
			if ($dt->hour() + $dt->minute() + $dt->second > 0)
			{
				$dt->truncate( to => 'week' );
			}
		} catch {
			$dt->_get_safe_end('week');
		};
		return $dt;
	} elsif ( $period eq 'month') {
		try {
			$dt->add( months => 1 );
			if ($dt->hour() + $dt->minute() + $dt->second > 0)
			{
				$dt->truncate( to => 'month' );
			}
		} catch {
			$dt->_get_safe_end('month');
		};
		return $dt;
	} else {
		croak "found unknown period '$period'";
	}
}

=head2 get_period_keys()

Returns all period keys in preserved order.

=cut

sub get_period_keys
{
	my ( $self ) = @_;

	return \@ordered_periods;
}

=head2 get_period_label($key)

Returns period label.

=cut

sub get_period_label
{
	my ( $self, $key ) = @_;
	croak "found unknown key '$key'" if (not exists $period_labels{$key} );

	return $period_labels{$key};
}

# Very slow, though necessary fallback algorithms
# Provides method to safely get start of day, week and month
sub _get_safe_start
{
	my ( $dt, $period ) = @_;

	if ( $period eq 'day' ) {
		my $cur_day = $dt->day();

		while ($cur_day == $dt->day()) {
			$dt->subtract( minutes => 5 );
		}
	} elsif ( $period eq 'week' ) {
		my $cur_week = $dt->week();

		while ($cur_week == $dt->week()) {
			$dt->subtract( minutes => 5 );
		}
	} elsif ( $period eq 'month' ) {
		my $cur_month = $dt->month();

		while ($cur_month == $dt->month()) {
			$dt->subtract( minutes => 5 );
		}
	} else {
		croak "found unknown period '$period'";
	}

	$dt->add(minutes => 5);
	return $dt->get_start('10 minutes');
}

# Provides safe methods to get end of the hour, day, week and month
sub _get_safe_end
{
	my ( $dt, $period ) = @_;

	if ( $period eq 'hour' ) {
		my $cur_hour = $dt->hour();

		while ( $cur_hour == $dt->hour() ) {
			$dt->add( minutes => 5 );
		}
	} elsif ( $period eq 'day' ) {
		my $cur_day = $dt->day();

		while ( $cur_day == $dt->day() ) {
			$dt->add( minutes => 5 );
		}
	} elsif ( $period eq 'week' ) {
		my $cur_week = $dt->week();

		while ( $cur_week == $dt->week() ) {
			$dt->add( minutes => 5 );
		}
	} elsif ( $period eq 'month' ) {
		my $cur_month = $dt->month();

		while ( $cur_month == $dt->month() ) {
			$dt->add( minutes => 5 );
		}
	} else {
		croak "found unknown period '$period'";
	}

	return $dt->get_start('10 minutes');
}

=head1 CAVEATS

Start of the week is always Monday.

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/vytas-dauksa/DateTimeX-Period/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DateTimeX::Period

=head1 ACKNOWLEDGEMENTS

This module has been written by Vytas Dauksa <vytas.dauksa@smoothwall.net>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Smoothwall.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

1; # End of DateTimeX::Period
