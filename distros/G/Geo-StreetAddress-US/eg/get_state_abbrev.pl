#!/usr/bin/perl

use LWP::Simple;
use strict;

my $data = get("http://www.usps.com/ncsc/lookups/abbr_state.txt");
die "Can't load abbreviations" unless $data;

$data =~ s/^.*?\r?\n\r?\n//os; # throwaway header

my @lines = split /\r?\n/, $data;
my %abbr;

for (@lines) {
    my ($st, $code) = split /\s\s+/;
    $st = lc $st;
    $st =~ s/(\w{3,})/\u\l$1/gos;
    $abbr{lc $st} = $code;
    last if $code eq "WY";
}

for (sort keys %abbr) {
    print "    \"$_\" => \"$abbr{$_}\",\n";
}
