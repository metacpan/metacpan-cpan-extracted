#!/usr/local/bin/perl -w
use strict;
use GRID::Machine qw(is_operative);
use Data::Dumper;

my $host = 'casiano@orion.pcg.ull.es';

my $machine = GRID::Machine->new( 
      host => $host,
      cleanup => 1,
      sendstdout => 1,
   );

my $dir = $machine->getcwd->result;
print "$dir\n";

$machine->include(shift() || "Include2");

for my $method (qw(one two three four five six seven twoexample)) {
  if ($machine->can($method)) {
    print $machine->host." can do $method\n";
    print Dumper($machine->$method());
  }
}
