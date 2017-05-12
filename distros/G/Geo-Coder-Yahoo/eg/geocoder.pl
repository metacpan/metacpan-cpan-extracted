#!/usr/bin/perl
use strict;
use warnings;
use lib '../lib';
use Geo::Coder::Yahoo;

my $g = Geo::Coder::Yahoo->new(appid => 'perl-geocoder-test');

my $location = shift or die qq[$0 "location"\n];

my $locations = $g->geocode(location => $location);

use Data::Dumper; 
warn Data::Dumper->Dump([\$locations], [qw(loc)]);
