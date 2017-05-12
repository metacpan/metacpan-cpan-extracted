#!/usr/bin/perl
#
# This example takes METARs and TAFs from the standard input, parses them
# and prints them out in a (sort of readable) normalised form
#
# Note that this is a state machine which can take any old rubbish and looks
# for a start of a forecast in the input. It then searches for a blank line
# before looking for the next.
# 
# You can get METARs from ftp://weather.noaa.gov/data/observations/metar
# TAFs from ftp://weather.noaa.gov/data/forecasts/taf/ and 
# from ftp://weather.noaa.gov/data/forecasts/shorttaf/
# directories. This program will parse these files directly
#
# You will need to press <return> twice to get any output if you are entering
# stuff manually.
#
# $Id: cmd_chunks.pl,v 1.1.2.1 2003/02/01 21:04:42 minima Exp $
#
# Copyright (c) 2003 Dirk Koopman G1TLH
#

use strict;
use Geo::TAF;

my $in;
my $t;

while (<STDIN>) {
	chomp;
	if (/^\s*$/) {
		if ($in) {
			$t = new Geo::TAF;
			if ($in =~ /(?:METAR|TAF)/) {
				$t->decode($in);
			} elsif ($in =~ /[QA]\d\d\d\d/) {
				$t->metar($in);
			} else {
				$t->taf($in);
			}
			print_taf($t);
			undef $in;
			undef $t ;
		}
	} else {
		if ($in) {
			$in .= $_;
		} else {
			next unless Geo::TAF::is_weather($_);
			$in = $_;
		}
	}
}

print_taf($t) if $t;

sub print_taf
{
	my $t = shift;
	
	print $t->raw, "\n\n";

	my $spc = "";
	foreach my $c ($t->chunks) {
		print $c->as_chunk, "\n";
	}
	print "\n\n";
}
