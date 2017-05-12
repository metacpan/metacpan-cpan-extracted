#!/usr/bin/perl -d:Trace

use lib 'lib', '../lib';	

use File::Stat::Moose;

foreach (1..10) {
    my $size = File::Stat::Moose->new( file => $0, @ARGV )->size;
};
