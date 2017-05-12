#!/usr/bin/perl

use strict;
use Time::HiRes qw[ usleep ];
use FindBin;
use lib "$FindBin::Bin/../lib";

use Device::Arduino::LCD;

my $lcd = Device::Arduino::LCD->new;
$lcd->clear;

$lcd->init_bargraph;

# a short graph.
for my $s (0 .. 7) {
  for my $i (0 .. 8) {
    $lcd->graph(8-$i , 2, $s);
    $lcd->graph($i, 2, $s+1);
    usleep 100_000;
  }
  $lcd->graph(0, 2, $s);
}

sleep 1;
$lcd->clear;


# a tall graph.
for my $s (0 .. 7) {
  for my $i (0 .. 16) {
    $lcd->tallgraph(16-$i, $s);
    $lcd->tallgraph($i,  $s+1);
    usleep 75_000;
  }
  $lcd->graph(0, 2, $s);
}

sleep 1;
$lcd->clear;
