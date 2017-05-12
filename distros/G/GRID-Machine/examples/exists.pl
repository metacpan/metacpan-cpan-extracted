#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;

my $host = shift || 'casiano@orion.pcg.ull.es';

my $machine = GRID::Machine->new(host => $host);

$machine->sub( one => q{ print "one\n" });

print "<".$machine->exists(q{one}).">\n";
print "<".$machine->exists(q{two}).">\n";
