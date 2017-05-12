#!/usr/bin/perl -I/home/pp2/LGRID_Machine/lib/ -wd
use strict;
use GRID::Machine;

my $host = shift || 'casiano@beowulf';

my $machine = GRID::Machine->new(host => $host, uses => [ 'GRID::Machine' ]);

my $r = $machine->eval(q{
 my $telnet = GRID::Machine->new(host => 'orion');

 gprint "ssh ok";
});

print $r->result;

