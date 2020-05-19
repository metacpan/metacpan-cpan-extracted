#/usr/bin/env perl
use Test::Most;
use JSON::Karabiner;
do 't/utility_funcs.pl';












my $tests = 20; # keep on line 17 for ,i (increment and ,d (decrement)

plan tests => $tests;

my ($obj, $def) = gen_def('to_delayed_if_canceled');
run_to_tests('to_delayed_if_canceled');

$obj->_dump_json;
