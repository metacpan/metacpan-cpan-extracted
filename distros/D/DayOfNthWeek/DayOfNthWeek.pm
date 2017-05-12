package Date::DayOfNthWeek;

our $VERSION = '1.0';

use 5.005;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(day_week last_week first_week) ]  );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

sub day_week($$) {

	my $day = shift;
	my $week = shift;
	
	die "your day is out of the range 0 - 6 Sunday==0\n" unless ((0 <= $day) && ( $day <= 6));
	die "Your week of the month is out of range (Range is 1-6)\n" unless ((1 <= $week) && ( $week <= 6));

	my (undef,undef,undef,$mday,undef,undef,$wday,undef,undef) = localtime;

# return unless the days match
	return 0 unless $wday == $day; 

	my $date = $mday-1;

	my %hash = ();

	for my $c (0 ..6 ) {
		my $a  = $date+$c;
		my $key = $a%7;
		my $w    = (int($a/7))+1;
		$hash{$key} = $w;
	}	
	
	my $q = $hash{$wday};

	return 0 unless $q == $week;

	return 1;
}

sub last_week($) {

	my $day  = shift;

	die "your day is out of the range 0 - 6   Sunday==0\n" unless ((0 <= $day) && ( $day <= 6));

	my (undef,undef,undef,$mday,$mon,$year,$wday,undef,undef) = localtime;

	return 0 unless $wday == $day; # return unless the days match

	my $max = 0;

	# how many days in the month?
	#  0   1   2   3   4   5   6   7   8   9   10  11
	# Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec
    # 31  28  31  30  31  30  31  31  30  31  30  31

	# This is laid out like this because using || was not giving me the correct
    # answer each time.

	if ($mon == 0 ) { $max=31;}     # January
                                 	# if the month is February is it a leap year?
	elsif ($mon == 1 ) {                            # This is to account for leap
		if ( $year % 4 ) { $max = 28; }             # years.  Which works like this:
		else {                                      # if year%4 != 0  it is a
			if  ( $year % 100 ) { $max = 28; }      # non-leap year, so Feb has 28 days.
			else { $max = 29; }                     # If year%4 == 0 it could be a leap
		}                                           # year.  If the year ends in 00,
	}                                               # Feb has 28 days, otherwise it
                                                    # has 29 days and is a leap year.
	elsif ($mon == 2 ) {$max=31; }  # March
	elsif ($mon == 3 ) {$max=30; }  # April
	elsif ($mon == 4 ) {$max=31; }  # May
	elsif ($mon == 5 ) {$max=30; }  # June
	elsif ($mon == 6 ) {$max=31; }  # July
	elsif ($mon == 7 ) {$max=31; }  # August
	elsif ($mon == 8 ) {$max=30; }  # September
	elsif ($mon == 9 ) {$max=31; }  # October
	elsif ($mon == 10 ) {$max=30; } # November
	elsif ($mon == 11 ) {$max=31; } # December
	else  { die "your month is out of the range 0 - 11\n"; }


	return 1 if $mday == $max;   # if it is the last day of the month, it has to be the last week of the month.

    my $diff = $max - $mday;

	return 0 if ($diff > 6);     # date can't be in the last week because 
                                 # there is more than 7 days left in the month.

	if (($wday == 6) && ($diff >0)) {
		return 0;
	}
	elsif (($wday == 5) && ($diff >1)) {
		return 0;
	}
	elsif (($wday == 4) && ($diff >2)) {
		return 0;
	}
	elsif (($wday == 3) && ($diff >3)) {
		return 0;
	}
	elsif (($wday == 2) && ($diff >4)) {
		return 0;
	}
	elsif (($wday == 1) && ($diff >5)) {
		return 0;
	}
	elsif (($wday == 0) && ($diff >6)) {
		return 0;
	}
	else {
		return 1;
	}
}

sub first_week($) {

	my $day = shift;

	die "your day is out of the range 0 - 6   Sunday==0\n" unless ((0 <= $day) && ( $day <= 6));

	my (undef,undef,undef,$mday,undef,undef,$wday,undef,undef) = localtime;

	return 0 if $mday > 7;         # can't be the first week of the month if it is after the 7th

	return 0 unless $wday == $day; # return unless the days match

	return 0 if ($mday-$day) > 1; # 

	return 1;
}


1;
__END__


=head1 NAME

Date::DayOfNthWeek - Simple Perl module for finding the first, last or
the Nth (Sun .. Sat) of the month.

=head1 SYNOPSIS

  use Date::DayOfNthWeek;

  # Sunday = 0, just like in localtime()

  my $wday = 2;

  # See if today is first Tuesday of the month
  my $first = first_week($wday);

  # See if today is last Tuesday of the month 
  my $last  = last_week($wday);

  # See if today is 3rd Tuesday of the month 

  my $week = 3;
  my $last  = day_week($wday,$week);


=head1 ABSTRACT

Date::DayOfNthWeek - Simple Perl module for finding out if today is
the first, last or the Nth (Sun .. Sat) of the month.

Has three functions:
	last_week($);  # today is in the last week of the month
	first_week($); # today is in the first week of the month
	day_week($,$); # today is in the Nth week of the month

I wrote this to send out use in a cron job to send out reminders about
the Morris County Perl Mongers monthly meetings.  Using Date::Calc and
Date::Manip where more than what I needed.

This only works for finding information about TODAY, no future
calculations.  If you want that use Date::Calc or Date::Manip.  This is meant to 


=head1 DESCRIPTION

Date::DayOfNthWeek - Simple Perl module for finding the first, last or
the Nth (Sun .. Sat) of the month.

A week is considered to start on Sunday.  There may be 1 .. 7 days in
the first week of the month.

Has three functions:

	first_week($); # day is in the first week of the month

Takes an int between 0 and 6 and returns 1 if today is 
the first [Sun - Sat] of the month 

	last_week($);  # day is in the last week of the month

Takes an int between 0 and 6 and returns 1 if today is 
the last [Sun - Sat] of the month 

	day_week($,$); # day is in the Nth week of the month

Takes an int between 0 and 6 [Sun - Sat] and an int for week of the
month [1-6].  Returns 1 if today is the that day of the Nth week of
the month.

=head2 EXAMPLE

I wrote this to send out use in a cron job to send out reminders about
the Morris County Perl Mongers (MCPM) monthly meetings.  Using
Date::Calc and Date::Manip were more than what I needed.

I am using this to send out a reminder about the MCPM meetings.  We
meet in a local Irish Pub on the 3rd Tuesday of the month.

#!/usr/local/bin/perl

use Date::DayOfNthWeek qw(day_week);

my $d = 2; # set to the day of week I want -- SUNDAY=0
my $w = 2; # set to the week PRIOR to the meeting so I can send out the reminder

my $ok = day_week($d,$w);

if ($ok) { &nextweek; }
else     {
    my $ww = $w+1;             # keeps me from changing the value of $w 
	if ($ww > 6) { $ww = 1; }  # fixes range input errors for wrapping to next week
	$ok = day_week($d,$ww);
	if ($ok) { &tonight; }
	else {
		$d--;                   # see if this is the day before the meeting
		if ($d < 0) { $d = 6; } # fixes range input error for wrapping to previous week day
		$ok = day_week($d,$w);
		&tomorrow if $ok;		
	}
} 

sub nextweek { print "Meeting is next week\n"; }
sub tomorrow { print "Meeting is tomorrow\n";  }
sub tonight  { print "Meeting is tonight\n";   }

=head2 FORMULA

The formula for calculating the week is:

(int(((Day of the Month - 1)+ Day of the Week)/7))+1


	my %hash = ();

	for my $c (0 ..6 ) {
		my $a  = $date+$c;
		my $key = $a%7;
		my $w    = (int($a/7))+1;
		$hash{$key} = $w;
	}	
	
	my $q = $hash{$wday};

The trick is the hash and using the mod operation.  If you don't do something
like this there are several cases where the answer is wrong.  This way is 100% 
accurate.

See the Examples directory for more info and test scripts.

Here are some fact that make the test info quicker to check

The 1st is always in week #1
The 8th is always in week #2
The 15th is always in week #3
The 22nd is always in week #4
The 29th is always in week #5

A month can have 4-6 weeks.

=head2 EXPORT

None by default

=head1 SEE ALSO

localtime(), examples distributed with module

=head1 AUTHOR

Andy Murren, E<lt>amurren@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002 by Andy Murren

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
