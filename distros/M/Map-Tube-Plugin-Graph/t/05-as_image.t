#!/usr/bin/perl
use 5.014;
use strict;
use warnings FATAL => 'all';
use File::Spec;
use Test::Lib;
use Test::More tests => 4;
use Sample;

my @localdir = File::Spec->splitdir($0);
pop(@localdir);

my $dataname = File::Spec->catfile( @localdir, 'sample.xml' );
my $tube = Sample->new( xml => $dataname );
my ($diagram, $teststr);
eval { $diagram = $tube->as_image( ); };
is( $@, '' );
$teststr = substr( $diagram, 0, 5);
is( $teststr, 'iVBOR', 'PNG of map in base64 format' );

eval { $diagram = $tube->as_image('Line 1'); };
is( $@, '' );
$teststr = substr( $diagram, 0, 5);
is( $teststr, 'iVBOR', 'PNG of line in base64 format' );
