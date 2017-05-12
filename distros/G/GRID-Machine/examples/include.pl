#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;

my $host = $ENV{GRID_REMOTE_MACHINE} || 'casiano@orion.pcg.ull.es';

my $machine = GRID::Machine->new( host => $host);

$machine->include(shift() || "Include");

for my $method (qw(one two three four five six)) {
  if ($machine->can($method)) {
    print $machine->host." can do $method\n";
    print $machine->$method();
  }
}
