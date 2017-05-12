#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;

my $machine = shift || 'orion.pcg.ull.es';
my $m = GRID::Machine->new( host => $machine );

my $r = $m->compile(one => q{ print "one\n"; });

$r = $m->compile(
  one => q{ print "1"; }, 
  politely => 1 # Don't overwrite if exists
);
print $r->errmsg."\n";

$r= $m->call("one");
print $r; # prints "one"
