#!/usr/bin/perl
use strict;
use warnings;

use GRID::Cluster;
use Data::Dumper;

my $cluster = GRID::Cluster->new(max_num_np => {orion => 1, europa => 1},);

my @commands = ("uname -a", "echo Hello");
my $result = $cluster->qx(@commands);

print Dumper($result);
