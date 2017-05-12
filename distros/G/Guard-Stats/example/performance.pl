#!/usr/bin/perl -w

# usage: $0 <want_time> <number_of_buckets=100> <number_of_iterations=10000>

use strict;
use YAML;

use Guard::Stats;

my $can_stat = eval {
	require Statistics::Descriptive::LogScale;
};

my $size = shift || 100;
my $iter = shift || 10**4;

my $stat = Guard::Stats->new(
	time_stat => $can_stat && "Statistics::Descriptive::LogScale" );

my @bucket;
for (1..$iter) {
	$bucket[ $size * rand() ] = $stat->guard;
	if (my $obj = $bucket[ $size * rand() ]) {
		$obj->is_done || $obj->end;
	};
	$bucket[ $size * rand() ] = undef;
};

print "Stats: ".Dump($stat->get_stat);
print "Times: ".Dump($stat->get_stat_time);
