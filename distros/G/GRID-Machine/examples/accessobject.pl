#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;

my $m = GRID::Machine->new( host => 'beowulf');

$m->sub(installed => q { return  keys %{SERVER->stored_procedures}; });
my @functions = $m->installed()->Results;
local $" = "\n";
print "@functions\n";
