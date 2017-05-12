#!/usr/local/bin/perl -w
use strict;
use GRID::Machine;

my $m = GRID::Machine->new( host => shift(), class => 'Unix' );

