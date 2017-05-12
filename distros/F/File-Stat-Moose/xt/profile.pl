#!/usr/bin/perl -d:DProf

use lib 'lib', '../lib';

use File::Stat::Moose;

foreach (1..10000) {
    my $size = File::Stat::Moose->new( file => $0, @ARGV )->size;
};

print "tmon.out data collected. Call dprofpp\n";
