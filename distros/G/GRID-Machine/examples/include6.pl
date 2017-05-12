#!/usr/bin/perl -w
use strict;
use GRID::Machine;
use Data::Dumper;

my $host = $ENV{GRID_REMOTE_MACHINE};

my $machine = GRID::Machine->new( host => $host);

$machine->include("Include6");

print $machine->last(4..9)."\n";

my $r = $machine->LASTitem(4..9);
print Dumper($r);

print $machine->one(4..9)."\n";
