
package Log::Parallel::Durations;

use strict;
use warnings;
require Exporter;
use List::EvenMoreUtils qw(keys_to_regex);
use Lingua::EN::Inflect qw(PL);
use Time::JulianDay;

our @ISA = qw(Exporter);
our @EXPORT = qw(frequency_and_span);

my %span = (
	#	   days months
	day	=> [ 1,  0 ],
	week	=> [ 7,  0 ],
	month	=> [ 0,  1 ],
	quarter	=> [ 0,  3 ],
	year	=> [ 0, 12 ],
);

my %translations = qw(
	daily		day
	weekly		week
	monthly		month
	yearly		year
	quarterly	quarter
);

my %weekdays = qw(
	sun 0		sunday 0
	mon 1		monday 1
	tue 2		tuesday 2
	wed 3		wednesday 3
	thu 4		thursday 4
	fri 5		friday 5
	sat 6		saturday 6
);


my %spans = map { PL($_) => $span{$_} } keys %span;
my %singular = map { PL($_) => $_ } keys %span;
my $re_trans = keys_to_regex(%translations);
my $re_span = keys_to_regex(%span);
my $re_spans = keys_to_regex(%spans);
my $re_wday = keys_to_regex(%weekdays);

my %timely = map { $translations{$_} => $_ } keys %translations;

my $re_nth = qr/(?:((?:[23]?1(?=st))|(?:2?2(?=nd))|(2?3(?=rd))|(?:(?:1\d|2?[04-9]|30)(?=th)))..)/;
my $re_small_nth = qr/(?:((?:1(?=st))|(?:2(?=nd))|(3(?=rd))|(?:4(?=th)))..)/;

sub match_span
{
	my ($jd, $from, $count, $type) = @_;
	my ($sd, $sm) = @{$span{$type}};
	die if $sd && $sm;
	if ($sd) {
		return 1 if ($jd - $from) % ($count * $sd) == 0;
		return 0;
	}
	my ($y, $m, $d) = inverse_julian_day($jd);
	my ($fy, $fm, $fd) = inverse_julian_day($from);
	return 0 unless $d == $fd;
	my $md = $m - $fm + $y*12 - $fy*12;
	return 1 if $md % ($count * $sm) == 0;
	return 0;
}


#use Tie::Function::Examples;
#tie my %yyyymmdd, 'Tie::Function::Examples',
#	sub {
#		my ($y, $m, $d) = inverse_julian_day($_[0]);
#		return sprintf("%d-%02d-%02d", $y, $m, $d);
#	};

sub frequency_and_span
{
	my ($job, $jd, $jd_from_limit, $jd_to_limit) = @_;

#print "F&S: $job->{name} $yyyymmdd{$jd} $yyyymmdd{$jd_from_limit} $yyyymmdd{$jd_to_limit} $job->{frequency}\n";

#if $job->{frequency} && $job->{frequency} ne 'daily';

	return unless $jd >= $jd_from_limit && $jd <= $jd_to_limit;

	my $frequency = $job->{frequency} || 'daily';

	$frequency =~ s/\b($re_trans)\b/every $translations{$1}/g;

	my ($yyyy, $mm, $dd) = inverse_julian_day($jd);
	my ($name, $count, $default_span);

	if ($frequency =~ /^\s*(?:every\s+)?(\d+)\s+($re_spans)$/i) {
		$count = $1;
		$name = $singular{$2};
		$default_span = "$count $name";
		return unless match_span($jd, $jd_from_limit, $count, $name);
	} elsif ($frequency =~ /^\s*every\s+($re_span)/i) {
		$count = 1;
		$name = $1;
		$default_span = "$count $name";
		return unless match_span($jd, $jd_from_limit, $count, $name);
	} elsif ($frequency =~ /^\s*every\s+$re_nth\s+day\s+each\s+month\s*$/i) {
		$name = "month";
		$count = 1;
		return unless $dd == $1;
		$default_span = "1 month";
	} elsif ($frequency =~ /^\s*(?:each\s+month,?\s+)?on\s+the\s+$re_nth(?:\s+(?:of\s+)?each\s+month)?\s*$/i) {
		$name = "month";
		$count = 1;
		return unless $dd == $1;
		$default_span = "1 month";
	} elsif ($frequency =~ /^\s*every\s+($re_wday)\s*$/i) {
		my $dow = $weekdays{lc($2)};
		return unless $dow = day_of_week($jd);
		$name = "week";
		$count = 1;
		$default_span = "1 week";
	} elsif ($frequency =~ /^\s*(?:every|on\s+the)\s$re_small_nth\s+($re_wday)(?:\s+(?:of\s+)?each\s+month)?\s*$/i) {
		$name = "month";
		$count = 1;
		$default_span = "1 month";
		my $nth = $1;
		my $dow = $weekdays{lc($2)};
		return unless $dow = day_of_week($jd);
		my $weeknum = int(($dd - 1)/ 7) + 1;
		return unless $weeknum == $nth;
	} elsif ($frequency =~ /^\s*range\s*$/) {
		return unless $jd == $jd_to_limit;
		my ($from_yyyy, $from_mm, $from_dd) = inverse_julian_day($jd_from_limit);
		my ($yyyy, $mm, $dd) = inverse_julian_day($jd_to_limit);
		return ({
			YYYY		=> $yyyy,
			FROM_YYYY	=> $from_yyyy,
			MM		=> $mm,
			FROM_MM		=> $from_mm,
			DD		=> $dd,
			FROM_DD		=> $from_dd,
			DURATION	=> 'range',
			FROM_JD		=> $jd_from_limit,
			JD		=> $jd,
		}, $jd_from_limit .. $jd_to_limit);
	} else {
		require Carp;
		Carp::confess "could not parse frequency '$frequency'";
	}

	my $timespan = $job->{timespan} || $default_span;

	my $duration;
	my $spancount;
	my $spanname;
	if ($timespan =~ /^(\d+)\s+($re_spans)$/) {
		$spancount = $singular{$1};
		$spanname = $2;
	} elsif ($timespan =~ /^(\d+)\s+($re_span)$/) {
		$spancount = $1;
		$spanname = $2;
	} elsif ($timespan =~ /^\s*all ?time\s*$/) {
		return unless $jd == $jd_to_limit;
		$spancount = 0;
	} else {
		die "can't parse timespan '$timespan'";
	}

	my ($spand, $spanm) = @{$span{$spanname}};
	my $fy = $yyyy;
	my $fm = $mm - $spanm * $spancount;
	while ($fm < 1) {
		$fy -= 1;
		$fm += 12;
	}
	my $fromjd = julian_day($fy, $fm, $dd);
	$fromjd -= $spand * $spancount;
	$fromjd += 1;		# don't overlap

	if ($count == 1) {
		$duration ||= $timely{$name};
	} else {
		$duration ||= "$count$name";
	}
	my ($from_yyyy, $from_mm, $from_dd) = inverse_julian_day($fromjd);

	return ({
		YYYY		=> $yyyy,
		FROM_YYYY	=> $from_yyyy,
		MM		=> $mm,
		FROM_MM		=> $from_mm,
		DD		=> $dd,
		FROM_DD		=> $from_dd,
		DURATION	=> $duration,
		FROM_JD		=> $fromjd,
		JD		=> julian_day($yyyy, $mm, $dd),
	}, $fromjd .. $jd);
}

1;

__END__

=head1 NAME

 Log::Parallel::Durations - parse duration specifications

=head1 SYNOPSIS

 use Log::Parallel::Durations;

 my $job = {
	frequency => 'daily',
	timespan => '30 days',
 };
 my $jd = Time::JulianDay::julian_day(2008, 10, 22);
 my $jd_from_limit = Time::JulianDay::julian_day(2008, 8, 22);
 my $jd_to_limit = Time::JulianDay::julian_day(2008, 12, 14);

 ($timespec, @jd_range) = frequency_and_span($job, $jd, $jd_from_limit, $jd_to_limit);

=head1 DESCRIPTION

This is a helper module for the L<process_logs>.   It parses
duration and frequency specifications.

It understands frequencies:

 daily
 every 3 days
 every week
 each month on the 13th
 on the 1st each month
 on the 1st of each month
 every Tuesday
 on the 3rd Wednesday of each month

It understands durations:

 3 days
 1 quarter
 2 years

The API meets the needs of L<process_logs>.  Given a start time
(C<$jd_from_limit>) and an end time (C<$jd_to_limit>) and a particular
day (C<$jd>) and a structure that specifies the duration and frequency
(C<$job>), it will return undef unless the particular day (C<$jd>) 
happens to meet the specification.  Most jobs are expected to run
daily so most of the time this is efficient.

All dates are in Julian Days.  Use L<Time::JulianDay>.

See the code for more details.


=head1 LICENSE

This package may be used and redistributed under the terms of either
the Artistic 2.0 or LGPL 2.1 license.

