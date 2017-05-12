#!/usr/bin/perl

use utf8;

use strict;
use warnings;

use Data::Dumper;

use Ham::APRS::FAP qw(parseaprs);
use Time::HiRes qw(sleep time);

my $lines = 0;
my $parse_ok = 0;
my $location_packet = 0;

my $start_t = time();

my $l;
while ($l = <>) {
	if ($l =~ /^(\d+)\s+(.*)[\r\n]+$/) {
		$lines++;
		
		my %p;
		my $ret = parseaprs($2, \%p);
		
		print "$1 $2\n$ret";
		foreach my $k ('resultcode', 'type', 'srccallsign', 'dstcallsign', 'objectname', 'itemname', 'symbolcode', 'symboltable', 'latitude', 'longitude', 'comment', 'messaging') {
			if (defined $p{$k}) {
				print " $k '$p{$k}'";
			}
		}
		#print Dumper(\%p);
		print "\n";
		
		next if ($ret != 1);
		
		$parse_ok++;
		
		next if (!defined $p{'type'} || $p{'type'} ne 'location');
		$location_packet++;
	}
}

my $end_t = time();
my $dur_t = $end_t - $start_t;

warn sprintf("parsed $lines lines in %.3f s: %.0f lines/s\n", $dur_t, $lines / $dur_t);
warn sprintf("$parse_ok (%.1f %% of total lines) parsed correctly using FAP\n", $parse_ok / $lines * 100);
warn sprintf("$location_packet (%.1f %% of total, %.1f %% of parsed) were location packets\n", $location_packet / $lines * 100, $location_packet / $parse_ok * 100);

