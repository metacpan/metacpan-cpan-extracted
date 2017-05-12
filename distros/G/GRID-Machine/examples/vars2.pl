#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;

my $machine = GRID::Machine->new(host => 'casiano@beowulf.pcg.ull.es');

$machine->eval(q{
  use vars qw{$h};
  $h = [4..9]; 
});

my $r = $machine->eval(q{
  $h = [map {$_*$_} @$h];
  use Data::Dumper;
  local $Data::Dumper::Indent = 0;
  local $Data::Dumper::Terse = 1;
  print Dumper($h);
});

print "$r\n";

