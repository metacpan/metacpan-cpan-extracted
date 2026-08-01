#!/usr/bin/perl
use 5.014;
use strict;
use warnings FATAL => 'all';
use File::Spec;
use Test::Lib;
use Test::More tests => 1;
use Sample;

my @localdir = File::Spec->splitdir($0);
pop(@localdir);
my $dataname = File::Spec->catfile( @localdir, 'sample.xml' );
my $tube = Sample->new( xml => $dataname );

my $g = $tube->as_graph( );
isnt( scalar $g->successors('Station B'), 0, 'Graph representation' );
