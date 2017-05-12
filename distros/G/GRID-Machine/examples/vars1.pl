#!/usr/local/bin/perl -w
use strict;
use GRID::Machine qw(qc);

my $machine = GRID::Machine->new(host => 'casiano@beowulf.pcg.ull.es');

$machine->eval(q{
  our $h;
  $h = [4..9]; 
});

my $r = $machine->eval(qc q{
  $h = [map {$_*$_} @$h];
});

die $r unless $r->noerr;
