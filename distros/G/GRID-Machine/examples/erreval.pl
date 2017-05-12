#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;

my $machine = shift || 'casiano@orion.pcg.ull.es';

my $ips = GRID::Machine->new( host => $machine );

# The function does not exists. Error at run time
my $p = $ips->eval( 'chuchu(0)');
die $p->errmsg,"\n" unless $p->ok;
