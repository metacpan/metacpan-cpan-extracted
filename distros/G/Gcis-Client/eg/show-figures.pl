#!/usr/bin/env perl

use Gcis::Client;
use Data::Dumper;
binmode STDOUT, ":utf8";
use v5.10;

my @reports = qw[
 usgcrp-ocpfy2010
 ccsp-ocpfy2008
 gcrp-ocpfy2009
 ccsp-ocpfy2003
 ccsp-ocpfy2013
 usgcrp-climate-impacts-foundation-report-2000
 ccsp-ocpfy2007
 ccsp-ocp-fy2006
 usgcrp-ocpfy2012
 ccsp-ocpfy2004and2005
];

my $base = "http://data-stage.globalchange.gov";

my $client = Gcis::Client->new(url => $base );

for my $report_identifier (@reports) {
    my $figures = $client->get("/report/$report_identifier/figure");
    for my $figure (@$figures) {
        say "$base/report/$report_identifier/figure/$figure->{identifier} : ";
        say "title : ".$figure->{title};
        say "caption : ".$figure->{caption};
        say "---";
    }
}



