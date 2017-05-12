#!/usr/bin/perl
use strict; use warnings;
use Games::AssaultCube::Log::Line;
use Data::Dumper;

my $line = Games::AssaultCube::Log::Line->new('[127.0.0.1] BS-Getler fragged BS-ap0cal');
print Dumper $line;
