#!/usr/bin/perl

use LWP::Simple;
use strict;

my $data = get("http://www.usps.com/ncsc/lookups/abbr_suffix.txt");
die "Can't load abbreviations" unless $data;

$data =~ s/^.*?\r?\n\r?\n//os; # throwaway header

my @lines = split /\r?\n/, $data;
my %abbr;

for (@lines) {
    my ($s1, $s2, $std) = split /\s+/;
    for ($s1, $s2) {
	$abbr{lc $_} = lc $std unless $std eq $_;
    }
}

for (sort keys %abbr) {
    print "    $_\t=> \"$abbr{$_}\",\n";
}
