#!/usr/bin/perl
use 5.014;
use strict;
use warnings;
use Path::Tiny;
use Test::Lib;
use Test::More tests => 2;
use Sample;

my $dataname = path( path($0)->parent, 'sample.xml' );
my $tube = Sample->new( xml => $dataname );

ok( $tube->list_drivers( ), 'List of GraphViz drivers' );
ok( $tube->list_formats( ), 'List of GraphViz output formats' );
