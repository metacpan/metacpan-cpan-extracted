#!/usr/bin/env perl

use lib 'lib';
use Test::Most;

use Getopt::Type::Tiny ();

pass "We were able to lood our primary modules";

diag "Testing Getopt::Type::Tiny Getopt::Type::Tiny:VERSION, Perl $], $^X";

done_testing;
