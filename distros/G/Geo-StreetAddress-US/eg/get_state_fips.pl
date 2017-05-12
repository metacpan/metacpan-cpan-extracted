#!/usr/bin/perl

use LWP::Simple;
use strict;

my $data = get("http://www.census.gov/datamap/fipslist/states.txt");
die "Can't load state FIPS codes" unless $data;

my @lines = split /\r?\n/, $data;
my %abbr;

for (@lines) {
    my ($code, $name, $st) = split /=/;
    $abbr{$code} = $st;
}

for (sort keys %abbr) {
    print "    \"$_\" => \"$abbr{$_}\",\n";
}
