#!/usr/bin/perl
use strict;
use Test::More tests => 1;

use Lingua::ZH::Segment;

my $results;

$results = Lingua::ZH::Segment::segment('我要');

#use Data::Dumper;
#print STDERR "\n",Dumper($results);

is($results,'我 要', 'Big5 Words segmentation');

