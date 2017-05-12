#!/usr/local/bin/perl -w
use strict;
use GRID::Machine qw(qc);
use Data::Dumper;

my $machine = GRID::Machine->new(host => 'casiano@orion.pcg.ull.es');

my $p = { name => 'Peter', familyname => [ 'Smith', 'Garcia'] };

my $r = $machine->eval( qc(q{ 
    $q = shift; 
    $q->{familyname} 
  }), $p
);

die "$r" unless $r->ok;

