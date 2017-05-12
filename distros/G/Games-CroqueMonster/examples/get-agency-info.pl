#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use lib '../lib' ;
use Games::CroqueMonster;

die "usage: $0 <agency name> [<api password>]\n" unless(@ARGV);
my $agency = shift(@ARGV);
my $api_key = shift(@ARGV);

my $cm = Games::CroqueMonster->new( agency_name => $agency, api_key => $api_key);
my $agency_data = $cm->agency();
print "Agency info: \n",Dumper($agency_data),"\n";
