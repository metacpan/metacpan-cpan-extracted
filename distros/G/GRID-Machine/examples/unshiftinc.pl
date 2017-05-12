#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;

my $m = GRID::Machine->new( 
  host => 'orion.pcg.ull.es',
  unshiftinc => [ qw(/home/casiano/prefix /home/casiano/perl) ],
);

print $m->eval(q{ local $" = "\n"; print  "@INC"; });
