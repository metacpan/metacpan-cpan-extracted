#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;

my $machine = shift || 'orion.pcg.ull.es';
my $m = GRID::Machine->new( 
  host => $machine,
  perl => 'perl -I/home/casiano/prefix -I/home/casiano/perl',
);

print $m->eval( q{
    local $" = "\n";
    print  "@INC";
  }
);

