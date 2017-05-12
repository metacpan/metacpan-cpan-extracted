#!/usr/bin/perl -w

# $Id: fetch_weather.pl,v 1.1.2.2 2003/02/03 01:42:40 minima Exp $

# this has been taken from Geo::METAR and modified
#
# Brief Description
# =================
#
# fetch_temp.pl is a program that demonstrates how to get the current
# temperature from a nearby (or not) airport using Geo::METAR and the
# LWP modules.
#
# Given an airport site code on the command line, fetch_temp.pl
# fetches the current temperature and displays it on the
# command-line. For fun, here are some example airports:
#
# LA     : KLAX
# Dallas : KDFW
# Detroit: KDTW
# Chicago: KMDW
#
# and of course: EGSH (Norwich)
#
#

# Get the site code.
my ($debug, $raw);
my @sort;
while ($ARGV[0] =~ /^-/ && @ARGV > 1) {
	my @f = split //, shift @ARGV;
	shift @f;
	foreach $f (@f) {
		push @sort, 'taf' if $f eq 't' && ! grep $_ eq 'taf', @sort; 
		push @sort, 'staf' if $f eq 's' && ! grep $_ eq 'staf', @sort; 
		push @sort, 'metar' if $f eq 'm' && ! grep $_ eq 'metar', @sort; 
		$debug++ if $f eq 'x';
		$raw++ if $f eq 'r';
	}
}
push @sort, 'metar' unless @sort;

my $site_code = uc shift @ARGV;

die "Usage: $0 [-mts] <site_code>\n" unless $site_code;

# Get the modules we need.

use Geo::TAF;
use LWP::UserAgent;
use strict;

my $sort;

foreach $sort (@sort) {

	my $ua = new LWP::UserAgent;

	my $req = new HTTP::Request GET =>
		"http://weather.noaa.gov/cgi-bin/mget$sort.pl?cccc=$site_code";
	
	my $response = $ua->request($req);
	
	if ($response->is_success) {
		
		# Yep, get the data and find the METAR.
		
		my $m = new Geo::TAF;
		my $data;
		$data = $response->as_string;               # grap response
		$data =~ s/\n//go;                          # remove newlines
		$data =~ m/($site_code\s\d+Z.*?)</go;       # find the METAR string
		my $metar = $1;                             # keep it
		
		# Sanity check
		
		if (length($metar)<10) {
			die "METAR is too short! Something went wrong.";
		}
		
		# pass the data to the METAR module.
		if ($sort =~ /taf$/) {
			$m->taf($metar);
		} else {
			$m->metar($metar);
		}
		print $m->raw, "\n" if $raw;
		print join "\n", $m->as_chunk_strings, "\n" if $debug;
		print $m->as_string, "\n";
		
	} else {
		
		print $response->as_string, "\n";
		
	} 
	print "\n";
}

exit 0;


