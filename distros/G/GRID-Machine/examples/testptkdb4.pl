#!/usr/local/bin/perl -w
# Execute this program being the user
# that initiated the X11 session
use strict;
use GRID::Machine;

my $host = 'casiano@beowulf.pcg.ull.es';

my $machine = GRID::Machine->new(
   command => "ssh -X $host perl -d:ptkdb", 
);

print $machine->eval(q{ 
  print "$ENV{DISPLAY}\n";
});

my $x = <>;

