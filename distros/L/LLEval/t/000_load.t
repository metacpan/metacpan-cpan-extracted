#!perl -w
use strict;
use Test::More tests => 1;

BEGIN {
    use_ok 'LLEval';
}

diag "Testing LLEval/$LLEval::VERSION";
eval { require Mouse };
diag "Mouse/$Mouse::VERSION";
