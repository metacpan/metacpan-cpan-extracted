#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;
use MyLocal;

my $host = 'casiano@beowulf.pcg.ull.es';

my $machine = GRID::Machine->new(host => $host, remotelibs => [ qw(MyRemote) ]);

$machine->send_operation( "MYTAG");
my ($type, $result) = $machine->read_operation();

die $result unless $type eq 'RETURNED';
print $result;

