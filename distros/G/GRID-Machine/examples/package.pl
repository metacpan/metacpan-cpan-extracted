#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;

my $s = shift || 0;
my $machine = 'casiano@orion.pcg.ull.es';

my $m = GRID::Machine->new( host => $machine, sendstdout => $s);

my $p = $m->eval( 
  q{
    print "Name of the Caller Package: "; 
    return caller(0)
  }
);
print "$p",$p->result,"\n";
