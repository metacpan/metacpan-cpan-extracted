#/usr/bin/env perl
use Test::Most;
use JSON::Karabiner::Manipulator;
do './t/utility_funcs.pl';












my $tests = 4; # keep on line 17 for ,i (increment and ,d (decrement)

plan tests => $tests;

lives_ok { set_rule_name('big time'); } 'can set rule name';
lives_ok { new_manipulator; } 'can create a manipulator object directly';
add_action 'from';
add_key_code 'x';


add_action 'to';
add_key_code 'y';

#_dump_json;

lives_ok { _fake_write_file('Some title', 'some.json')} 'can fake write file with file name';

lives_ok { new_manipulator; } 'can add a new manipulator';
add_action 'from';
add_key_code 'a';

add_action 'to';
add_key_code 'b';

#_dump_json;

_fake_write_file();
