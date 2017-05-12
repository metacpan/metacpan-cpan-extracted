#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;

my $machine = shift || 'orion.pcg.ull.es';
my $m = GRID::Machine->new( host => $machine );

$m->compile(one => q{print "one\n"; });

$m->compile(one => q{ print "1\n"; });

my $r= $m->call("one");
print $r; # 1
