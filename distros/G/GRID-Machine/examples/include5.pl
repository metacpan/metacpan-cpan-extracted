#!/usr/bin/perl -w
use strict;
use GRID::Machine;

my $host = $ENV{GRID_REMOTE_MACHINE};

my $machine = GRID::Machine->new( host => $host);

$machine->include("Include5", exclude => [ qw(two) ], alias => { last => 'LAST' });

for my $method (qw(last LAST one two)) {
  if ($machine->can($method)) {
    print $machine->host." can do $method\n";
  }
}

print $machine->LAST(4..9)->result."\n";
