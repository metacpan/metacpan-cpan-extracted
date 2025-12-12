# This code is part of Perl distribution Mail-Message version 4.00.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message::Field::Date;{
our $VERSION = '4.00';
}

use parent 'Mail::Message::Field::Structured';

use warnings;
use strict;

use Log::Report   'mail-message', import => [ qw/__x error/ ];

use POSIX qw/mktime tzset/;

#--------------------

my $dayname = qr/Mon|Tue|Wed|Thu|Fri|Sat|Sun/;
my @months  = qw/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/;
my %monthnr; { my $i; $monthnr{$_} = ++$i for @months }
my %tz      = qw/EDT -0400  EST -0500  CDT -0500  CST -0600
				MDT -0600  MST -0700  PDT -0700  PST -0800
				UT  +0000  GMT +0000/;

sub parse($)
{	my ($self, $string) = @_;

	my ($dn, $d, $mon, $y, $h, $min, $s, $z) = $string =~ m/
		 ^	\s*
			(?: ($dayname) \s* \, \s* )?         # dayname (optional)
			( 0?[1-9] | [12][0-9] | 3[01] ) \s+  # day
			( [A-Z][a-z][a-z]|[0-9][0-9]  ) \s+  # month
			( (?: 19 | 20 | ) [0-9][0-9]  ) \s+  # year
			( [0-1]?[0-9] | 2[0-3] )        \s*  # hour
				[:.] ( [0-5][0-9] )         \s*  # minute
			(?: [:.] ( [0-5][0-9] ) )?      \s*  # second (optional)
			( [+-][0-9]{4} | [A-Z]+ )?           # zone
			\s*
		$ /x or return undef;

	$dn //= '';
	$dn   =~ s/\s+//g;
	$mon  = $months[$mon-1] if $mon =~ /[0-9]+/;   # Broken mail clients

	$y   += 2000 if $y < 50;
	$y   += 1900 if $y < 100;

	$z  ||= '-0000';
	$z    = $tz{$z} || '-0000' if $z =~ m/[A-Z]/;

	$self->{MMFD_date} = sprintf "%s%02d %s %04d %02d:%02d:%02d %s",
		(length $dn ? "$dn, " : ''), $d, $mon, $y, $h, $min, $s // 0, $z;

	$self;
}

sub produceBody() { $_[0]->{MMFD_date} }
sub date() { $_[0]->{MMFD_date} }

#--------------------

sub addAttribute($;@)
{	my $self = shift;
	error __x"no attributes for date fields.";
}


sub time()
{	my $date = shift->{MMFD_date};
	my ($d, $mon, $y, $h, $min, $s, $z) = $date =~ m/
		^ (?:\w\w\w\,\s+)? (\d\d)\s+(\w+)\s+(\d\d\d\d) \s+ (\d\d)\:(\d\d)\:(\d\d) \s+ ([+-]\d\d\d\d)? \s* $
	/x;

	my $oldtz = $ENV{TZ};
	$ENV{TZ}  = 'UTC';
	tzset;
	my $timestamp = mktime $s, $min, $h, $d, $monthnr{$mon}-1, $y-1900;
	if(defined $oldtz) { $ENV{TZ}  = $oldtz } else { delete $ENV{TZ} }
	tzset;

	$timestamp += ($1 eq '-' ? 1 : -1) * ($2*3600 + $3*60)
		if $z =~ m/^([+-])(\d\d)(\d\d)$/;
	$timestamp;
}

#--------------------

1;
