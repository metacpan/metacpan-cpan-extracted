#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use Test::More;

use lib 't';

unless ( $ENV{ARC_TESTING} ) {
    plan( skip_all => "ARC tests currently a work in progress" );
}

use ArcTestSuite;

my $Tests = ArcTestSuite->new();

$Tests->LoadFile( 't/arc_test_suite/arc-draft-validation-tests.yml' );
$Tests->SetOperation( 'validate' );
$Tests->RunAllScenarios();

done_testing();

#print Dumper( $Tests->{ 'tests' } );

