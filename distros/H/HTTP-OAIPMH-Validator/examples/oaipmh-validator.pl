#!/usr/bin/env perl

=head1 NAME

oaipmh-validator.pl -- OAI-PMH Data Provider Validator

=head1 SYNOPSIS

oaipmh-validator.pl [[baseURL]]

Will run validator on and OAI-PMH data provider at baseURL. Will 
show progress of the validation.

  -d  show debugging output
  -h  this help

=cut

use strict;

use lib qw(lib);

use HTTP::OAIPMH::Validator;
use Try::Tiny;
use Getopt::Std;
use Pod::Usage;

my %opt;
(getopts('dh',\%opt)&&!$opt{h}) || pod2usage();

foreach my $base_url (@ARGV) {
    print "\n# RUNNING VALIDATION FOR $base_url\n";
    my $val = HTTP::OAIPMH::Validator->new( base_url=>$base_url,
                                            debug=>$opt{d} );
    $val->log->fh(\*STDOUT); $|=1;
    try {
        $val->run_complete_validation;
    } catch {
        warn "\noops, validation didn't run to completion: $_\n";
    };
    print "\n## Validation status of data provider ".$val->base_url." is ".$val->status."\n";
}
