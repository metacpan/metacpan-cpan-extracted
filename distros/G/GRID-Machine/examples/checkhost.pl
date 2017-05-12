#!/usr/local/bin/perl -w
use strict;
use GRID::Machine qw(is_operative);
use Data::Dumper;

my $host = 'casiano@beowulf.pcg.ull.es';

my $machine = GRID::Machine->new(
   command => ['ssh', '-X', $host, 'perl'], 
);

print $machine->eval(q{ 
  print "Host: ".SERVER->host."\n";
  print "$ENV{DISPLAY}\n";
});

