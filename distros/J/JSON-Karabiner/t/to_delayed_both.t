#/usr/bin/env perl
use Test::Most;
use JSON::Karabiner;
do './t/utility_funcs.pl';












my $tests = 1; # keep on line 17 for ,i (increment and ,d (decrement)

plan tests => $tests;

my ($obj, $def, $manip) = gen_def('to_delayed_if_invoked');
lives_ok { $manip->add_action('to_delayed_if_canceled'); } 'can add two delayed_if definitions';


$obj->_dump_json;
