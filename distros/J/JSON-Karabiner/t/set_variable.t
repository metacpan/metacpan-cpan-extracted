#/usr/bin/env perl
use Test::Most;
use JSON::Karabiner;
do './t/utility_funcs.pl';












my $tests = 1; # keep on line 17 for ,i (increment and ,d (decrement)

plan tests => $tests;

my ($obj, $def) = gen_def('to_delayed_if_invoked');
lives_ok { $def->add_set_variable('blah', '3'); } 'can set a variable';


$obj->_dump_json;
