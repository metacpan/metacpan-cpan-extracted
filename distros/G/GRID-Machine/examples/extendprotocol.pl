#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;

my $name = shift;
my $host = 'casiano@beowulf.pcg.ull.es';

my $machine = GRID::Machine->new(host => $host, remotelibs => [ qw(MyRemote) ]);

$machine->send_operation( "MYTAG", $name);
my ($type, $result) = $machine->read_operation();

die $result unless $type eq 'RETURNED';
print $result;

