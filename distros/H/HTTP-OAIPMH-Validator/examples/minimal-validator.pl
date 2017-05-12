#!/usr/bin/env perl
use strict;
use lib qw(lib);
use HTTP::OAIPMH::Validator;
use Try::Tiny;
foreach my $base_url (@ARGV) {
    print "\n# RUNNING VALIDATION FOR $base_url\n";
    my $val = HTTP::OAIPMH::Validator->new( base_url=>$base_url );
    $val->log->fh(\*STDOUT); $|=1;
    try {
	$val->run_complete_validation;
    } catch {
	warn "\noops, validation didn't run to completion: $_\n";
    };
    print "\n## Validation status of data provider ".$val->base_url." is ".$val->status."\n";
}
