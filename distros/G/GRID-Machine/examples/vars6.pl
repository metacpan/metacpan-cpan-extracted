#!/usr/local/bin/perl -w
use strict;
use GRID::Machine qw(qc);

my $machine = GRID::Machine->new(host => 'casiano@beowulf.pcg.ull.es');

my $r = $machine->eval(qc q{
  my $h = 1;

  use vars '$dumph';
  $dumph = sub {
    print "$h";
    $h++;
  };

  $dumph->();
});

print "$r\n";

$r = $machine->eval(qc q{
  $dumph->();
});

print "$r\n";

