#!/usr/bin/evn perl

# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Hash-GuavaRing.t'

#########################

use strict;
use warnings;

# use Data::Dumper;

use Test::More tests => 1+6+12*3;
BEGIN { use_ok('Hash::GuavaRing') };

my @nodes = map { { name => "node-".$_} } 0..2;

my $ring = Hash::GuavaRing->new(
	nodes => \@nodes,
);

is_deeply ($ring->get(1), $nodes[0], 'key = 1 -> node-0');
is_deeply ($ring->get(2), $nodes[0], 'key = 2 -> node-0');
is_deeply ($ring->get(3), $nodes[2], 'key = 3 -> node-2');
is_deeply ($ring->get(4), $nodes[1], 'key = 4 -> node-1');
is_deeply ($ring->get(5), $nodes[1], 'key = 5 -> node-1');
is_deeply ($ring->get(6), $nodes[2], 'key = 6 -> node-2');


my @nodes = map { { name => "node-".$_} } 0..12;

my $ring = Hash::GuavaRing->new(
	nodes => \@nodes,
);

for (0..2) {
	is_deeply ($ring->get(1),  $nodes[6],  'key = 1  -> node-6');
	is_deeply ($ring->get(2),  $nodes[6],  'key = 2  -> node-6');
	is_deeply ($ring->get(3),  $nodes[8],  'key = 3  -> node-8');
	is_deeply ($ring->get(4),  $nodes[12], 'key = 4  -> node-12');
	is_deeply ($ring->get(5),  $nodes[10], 'key = 5  -> node-10');
	is_deeply ($ring->get(6),  $nodes[9],  'key = 6  -> node-9');
	is_deeply ($ring->get(7),  $nodes[11], 'key = 7  -> node-11');
	is_deeply ($ring->get(8),  $nodes[4],  'key = 8  -> node-4');
	is_deeply ($ring->get(9),  $nodes[7],  'key = 9  -> node-7');
	is_deeply ($ring->get(10), $nodes[7],  'key = 10 -> node-7');
	is_deeply ($ring->get(11), $nodes[12], 'key = 11 -> node-12');
	is_deeply ($ring->get(12), $nodes[10], 'key = 12 -> node-10');
}