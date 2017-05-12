#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;

my $machine = GRID::Machine->new(host => 'casiano@beowulf.pcg.ull.es');

my $r = $machine->eval(q{
#line 9  "vars3.pl"
  my $h;

  sub dumph {
    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Terse = 1;
    print Dumper($h)."\n";
  }

  $h = [map {$_*$_} (4..9)];

  dumph($h);

  $h = [map {$_*$_} (1..3)];
  dumph($h);
});

print "$r\n";

