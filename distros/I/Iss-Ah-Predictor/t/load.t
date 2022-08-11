#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
  use_ok('ISS::AH::Predictor') || print "Bail out!\n";
}

diag("Testing ISS::AH::Predictor $ISS::AH::Predictor::VERSION, Perl $], $^X");
