#!/usr/bin/perl -w
use strict;
use Data::Dumper;

use GRID::Machine;
use GRID::Machine::Group;

my @MACHINE_NAMES = split /\s+/, ($ENV{MACHINES} || '');
@MACHINE_NAMES = ('', '') unless @MACHINE_NAMES;
my @m = map { GRID::Machine->new(host => $_) } @MACHINE_NAMES;

my $group = GRID::Machine::Group->new(cluster => \@m);

my @r = $group->sub(do_something => q{ 1; });

my $r = $group->do_something( replicate => [] );

$Data::Dumper::Terse = 1;
print Dumper($r);

