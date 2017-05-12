#!perl
use strict;
use warnings;
use Test::More tests => 1;

BEGIN { use_ok 'JS::JSLint' }

diag "Testing JS-JSLint $JS::JSLint::VERSION, Perl $], $^X";
