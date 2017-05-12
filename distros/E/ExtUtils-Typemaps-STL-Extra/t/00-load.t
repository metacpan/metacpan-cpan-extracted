#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok('ExtUtils::Typemaps::STL::Extra') || print "Bail out!\n";
}

diag(
"Testing ExtUtils::Typemaps::STL::Extra $ExtUtils::Typemaps::STL::Extra::VERSION, Perl $], $^X"
);
