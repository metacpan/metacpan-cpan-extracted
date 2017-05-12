#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;

my $machine = shift || 'orion.pcg.ull.es';
my $m = GRID::Machine->new( host => $machine );

$m->compile( UNAME => q{
    use POSIX qw( uname );
    uname()
  }
);

my @r= $m->call("UNAME")->Results;
local $" = "\n"; print "@r";
