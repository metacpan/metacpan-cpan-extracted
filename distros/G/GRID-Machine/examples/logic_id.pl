#!/usr/bin/perl -w
use strict;
use GRID::Machine;

my $m1 = GRID::Machine->new( host => shift());
my $m2 = GRID::Machine->new( host => shift());
my $m3 = GRID::Machine->new( host => shift());

print $m1->logic_id."\n";
print $m2->logic_id."\n";
print $m3->logic_id."\n";
