#!/usr/bin/perl -w
use strict;
use GRID::Machine;
use Data::Dumper;

my $host = $ENV{GRID_REMOTE_MACHINE} ||shift;

my $machine = GRID::Machine->new(host => $host, prefix => q{perl5lib/});

my $r = $machine->modput('Parse::Eyapp', 'Parse::Eyapp::');

$r = $machine->eval(q{
    use Parse::Eyapp;

    print Parse::Eyapp->VERSION."\n";
  }
);
print Dumper($r);  
