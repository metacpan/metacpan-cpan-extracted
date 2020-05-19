#/usr/bin/env perl
use Test::Most;
use JSON::Karabiner;
do 't/utility_funcs.pl';












my $tests = 10; # keep on line 17 for ,i (increment and ,d (decrement)

plan tests => $tests;

my ($obj, $def) = gen_def('from');
dies_ok { $def->add_consumer_key_code } 'can add consumer key code';
lives_ok { $def->add_consumer_key_code('blah') } 'can add consumer key code';
dies_ok { $def->add_any('key_code') } 'dies if you try to add mutually exclusive properties';
dies_ok { $def->add_key_code('7') } 'dies if you try to add mutually exclusive properties';
dies_ok { $def->add_pointing_button('left') } 'dies if you try to add mutually exclusive properties';

lives_ok { $def->add_optional_modifiers('any') } 'can add modifiers';
lives_ok { $def->add_mandatory_modifiers('command', 'right_shift') } 'can add modifiers';
dies_ok { $def->add_mandatory_modifiers('command', 'right_shift') } 'cannot re-add modifiers';
lives_ok { $def->add_simultaneous('key_code', 'a', 'b', 'c') } 'can add simultaneous';
lives_ok { $def->add_simultaneous('consumer_key_code', 'a', 'b', 'c') } 'can add simultaneous';

$obj->_dump_json;
