#!/usr/bin/perl
use strict;
use Test::More tests => 1;

use Lingua::ZH::Segment;

my $results;

$results = Lingua::ZH::Segment::segment('我要');

#use Data::Dumper;
#print STDERR "\n",Dumper($results);
#print STDERR $results."\n";

is($results,'我 要', 'UTF-8 Words segmentation');

