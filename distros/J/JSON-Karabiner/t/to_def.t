#/usr/bin/env perl
use Test::Most;
use JSON::Karabiner;
do './t/utility_funcs.pl';












my $tests = 20; # keep on line 17 for ,i (increment and ,d (decrement)

plan tests => $tests;
run_to_tests('to');
