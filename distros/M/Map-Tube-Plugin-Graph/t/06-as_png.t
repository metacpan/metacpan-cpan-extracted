#!/usr/bin/perl
use 5.014;
use strict;
use warnings;
use File::Spec;
use Test::Lib;
use Test::More tests => 4;
use Sample;

my @localdir = File::Spec->splitdir($0);
pop(@localdir);
my $dataname = File::Spec->catfile( @localdir, 'sample.xml' );
my $tube = Sample->new( xml => $dataname );

my ($diagram, $teststr);
eval { $diagram = $tube->as_png('Line 1'); };
is( $@, '' );
$teststr = substr( $diagram, 1, 3);
is( $teststr, 'PNG', 'PNG in binary format' );

eval { $diagram = $tube->as_png('Line 1', format => 'gv'); };
is( $@, '' );
like( $diagram, qr/^digraph\s/, 'as_png() but with GV format' );
