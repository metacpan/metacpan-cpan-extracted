#/usr/bin/env perl
use Test::Most;
use JSON::Karabiner::Manipulator;
do './t/utility_funcs.pl';












my $tests = 16; # keep on line 17 for ,i (increment and ,d (decrement)

plan tests => $tests;

my $manip;
lives_ok { set_title 'some title' } 'can set title';
lives_ok { set_rule_name 'some rule' } 'can set rule name';
lives_ok { $manip = new_manipulator(); } 'can create a manipulator object directly';
my $from;
lives_ok { $from = $manip->add_action('from') } 'can add a from action';
lives_ok { $from->add_key_code('t') } 'can add a from action';
lives_ok { add_action('to') } 'can use DSL for adding actions';
lives_ok { add_condition('device_if') } 'can use DSL for adding conditions';
lives_ok { add_key_code('x') } 'can use DSL for adding data to actions';
dies_ok { add_nonsense('x') } 'does not run invalid methods';
lives_ok { add_key_code 'y' } 'can use DSL without parens';

lives_ok { $manip->_fake_write_file() } 'can fake write a file with manipulator';
lives_ok { $manip->_dump_json; } 'can _dump_json with manipulator';


my ($new_obj, $action, $manip_new) = gen_def('from');

dies_ok { $manip_new->_dump_json } 'cannot dump json from manipulator created with old method';

my ($new_obj2, $action2, $manip_new2) = gen_def('from');
throws_ok { $manip_new2->_dump_json } qr/the _dump_json method cannot/i, 'throws correct error';
dies_ok { $manip_new2->_fake_write_file } 'cannot fake_write with manipulator using old mehod';
throws_ok { $manip_new2->_fake_write_file } qr/the _fake_write method cannot/i, 'throws correct error';
