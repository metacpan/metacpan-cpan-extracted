#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;

my $machine = shift || 'orion.pcg.ull.es';
my $m = GRID::Machine->new( host => $machine );

my $f = $m->open('uname -a |');
my $x = <$f>;
print "UNAME result: $x\n"
