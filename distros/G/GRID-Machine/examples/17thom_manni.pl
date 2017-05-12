#!/usr/bin/perl -w

use strict;
use Data::Dumper;
use GRID::Machine;

my $m = GRID::Machine->new(
  host => 'orion',
  prefix => '/tmp/',
  log => '/tmp',
  err => '/tmp',
  startdir => '/tmp/',
  #debug => 12344,
  wait => 10,
);

my $r = $m->system("hostname");
print Dumper $r;
$r = $m->system('pwd; ls -l ');
print Dumper $r;


