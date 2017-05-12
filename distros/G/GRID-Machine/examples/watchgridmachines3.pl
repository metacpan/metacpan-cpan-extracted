#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use IO::Select;

use GRID::Machine;
use GRID::Machine::Group;

my @secs = (2, 1, 4, 3, 7, 5, 1, 8..100);

my @MACHINE_NAMES = split /\s+/, $ENV{MACHINES};
my @m = map { GRID::Machine->new(host => $_) } @MACHINE_NAMES;

my $group = GRID::Machine::Group->new(cluster => \@m);

my @r = $group->sub(do_something =>  q{
                      my $arg = shift; 
                      sleep $arg; 
                      SERVER->host().":$arg" 
                    });

my @args = map { [ $secs[$_] ] } 0..2*$#MACHINE_NAMES;
my $r = $group->do_something(args => \@args);

print Dumper($r);

