#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok('Math::Random::PCG32') || print "Bail out!\n";
}

diag("Testing Math::Random::PCG32 $Math::Random::PCG32::VERSION, Perl $], $^X");
