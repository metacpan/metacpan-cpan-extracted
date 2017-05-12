#!/usr/bin/perl -w
use strict;
use GRID::Machine;
use Data::Dumper;

my $host = $ENV{GRID_REMOTE_MACHINE} ||shift;

my $machine = GRID::Machine->new(host => $host,);

print Dumper($machine->installed('Data::Dumper'));
print Dumper($machine->installed('Does::Not::Exist::Yet'));
