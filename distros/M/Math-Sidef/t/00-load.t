#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok('Math::Sidef') || print "Bail out!\n";
}

diag("Testing Math::Sidef $Math::Sidef::VERSION, Perl $], $^X");
