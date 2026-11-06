#!/usr/bin/perl
use 5.014;
use strict;
use warnings;
use Path::Tiny;
use Test::Lib;
use Test::More tests => 4;
use Sample;

my $dataname = path( path($0)->parent, 'sample.xml' );
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
