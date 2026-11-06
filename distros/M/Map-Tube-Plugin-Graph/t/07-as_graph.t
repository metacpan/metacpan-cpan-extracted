#!/usr/bin/perl
use 5.014;
use strict;
use warnings;
use Path::Tiny;
use Test::Lib;
use Test::More tests => 1;
use Sample;

my $dataname = path( path($0)->parent, 'sample.xml' );
my $tube = Sample->new( xml => $dataname );

my $g = $tube->as_graph( );
isnt( scalar $g->successors('Station B'), 0, 'Graph representation' );
