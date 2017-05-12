#!/usr/local/bin/perl -w
use strict;
use GRID::Machine qw(is_operative);
use Data::Dumper;

my $machine = GRID::Machine->new(host => 'casiano@orion.pcg.ull.es');

my $p = {
  name => 'Peter', 
  familyname => [ 'Smith', 'Garcia'],
  age => 31
};

print Dumper($machine->eval(q{ 
  my $q = shift;

  $q->{familyname}

  }, $p
));
