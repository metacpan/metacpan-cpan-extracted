#!/usr/bin/perl

use 5.010;
use strict;
use warnings;
use Test::More;
use File::Slurp;
use HTCondor::Queue::Parser;

my @condor_q =  read_file( 't/input.txt' ) ;

ok (scalar(@condor_q) > 100, 'Dummy input file is here');

my $cparser = HTCondor::Queue::Parser->new();

ok($cparser, 'Condor::QueueParser instance ok');

my %schedds_map = $cparser->load_schedds_xml(\@condor_q);

ok (scalar(keys %schedds_map) == 2, "We got 2 schedulers here");

foreach my $schedd (keys %schedds_map) {
	ok($schedds_map{$schedd}{'xml'}, "Got an xml for $schedd");

}

%schedds_map = $cparser->convert_to_compatible_xml(\%schedds_map);
%schedds_map = $cparser->xml_to_hrefs(\%schedds_map);

foreach my $schedd (keys %schedds_map) {
	ok($schedds_map{$schedd}{'href'}, "Got a perl href for $schedd");
}


 foreach my $schedd (keys %schedds_map) {
	ok(length($cparser->schedd_json(\%schedds_map, $schedd)) > 2000,  "JSON Length is big enough to contain something relevant");
 }


done_testing();
