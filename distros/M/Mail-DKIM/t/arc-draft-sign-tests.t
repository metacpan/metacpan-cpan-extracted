#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 't';

# number of tests currently in the signing yaml
plan tests => 51;

my $nskip = 0;
$nskip = $ARGV[0] if @ARGV > 0;

use ArcTestSuite;

my $Tests = new ArcTestSuite();

$Tests->LoadFile('t/arc_test_suite/arc-draft-sign-tests.yml');
$Tests->SetOperation('sign');
$Tests->RunAllScenarios($nskip);

done_testing();
