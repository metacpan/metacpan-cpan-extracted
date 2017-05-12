#!/usr/bin/perl -w
use strict;
use 5.016;

use rlib;
use Geo::Converter::dms2dd qw {dms2dd};

use English qw /-no_match_vars/;

my $fname = $ARGV[0];
open(my $fh, '<', $fname) or die "Cannot open $fname";

my $hdr = <$fh>;

while (my $line = <$fh>) {
    chomp $line;
    my @flds = split /,/, $line;
    my $lat = $flds[2];
    my $lon = $flds[3];
    my $dd_lat = eval {dms2dd {value => $lat, is_lat => 1}};
    #if ($EVAL_ERROR) {
    #    say $EVAL_ERROR;
    #}
    my $dd_lon = eval {dms2dd {value => $lon, is_lon => 1}};
    #if ($EVAL_ERROR) {
    #    say $EVAL_ERROR;
    #}
}

