#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;

my $ips = GRID::Machine->new( host => 'casiano@orion.pcg.ull.es',
  sendstdout => 0,
);

my $p = $ips->eval( 'caller(0)');
print $p->result,"\n";
