#!/usr/local/bin/perl -w
use strict;
use GRID::Machine qw(qc);

my $machine = GRID::Machine->new(host => 'casiano@beowulf.pcg.ull.es');

my $r = $machine->eval(qc q{
  my $h = 1;

  sub dumph {
    print "$h\n";
    $h++
  }

  dumph();
});

print "Result: ".$r->result."\nWarning: ".$r->stderr;

$r = $machine->eval(qc q{
  dumph();
});

print "Result: ".$r->result."\nWarning: ".$r->stderr;
