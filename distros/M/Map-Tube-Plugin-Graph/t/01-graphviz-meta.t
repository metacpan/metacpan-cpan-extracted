#!/usr/bin/perl
use 5.014;
use strict;
use warnings;
use File::Spec;
use Test::Lib;
use Test::More tests => 2;
use Sample;

my @localdir = File::Spec->splitdir($0);
pop(@localdir);
my $dataname = File::Spec->catfile( @localdir, 'sample.xml' );
my $tube = Sample->new( xml => $dataname );

ok( $tube->list_drivers( ), 'List of GraphViz drivers' );
ok( $tube->list_formats( ), 'List of GraphViz output formats' );
