#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;

my $machine = GRID::Machine->new( 
      host => 'casiano@orion.pcg.ull.es',
      startdir => '/tmp',
   );

my $r = $machine->sub(byref => q{ $_[0] = 4; });
die $r->errmsg unless $r->ok;

my ($x, $y) = (1, 1);

$y = $machine->byref($x)->result;

print "$x, $y\n"; # 1, 4
