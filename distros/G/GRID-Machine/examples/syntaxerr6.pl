#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;
use Data::Dumper;

my $machine = GRID::Machine->new(host => 'casiano@orion.pcg.ull.es');

my $p = { name => 'Peter', familyname => [ 'Smith', 'Garcia'] };

my $r = $machine->sub(chuchu => q{ $q = shift; $q->{familyname} });

die  Dumper($r) unless $r->ok;

print "Still alive\n";
