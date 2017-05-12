#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;
use Data::Dumper;

my $machine = GRID::Machine->new(host => 'casiano@orion.pcg.ull.es');

my $p = { name => 'Peter', familyname => [ 'Smith', 'Garcia'] };

my $r = $machine->eval( q{ $q = shift; $q->{familyname} }, $p);

die  Dumper($r) unless $r->ok;

print "Still alive\n";
