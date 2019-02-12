#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok('Math::MatrixLUP') || print "Bail out!\n";
}

diag("Testing Math::MatrixLUP $Math::MatrixLUP::VERSION, Perl $], $^X");
