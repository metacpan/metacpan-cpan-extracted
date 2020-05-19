#/usr/bin/env perl
use Test::Most;
use JSON::Karabiner;
do 't/utility_funcs.pl';












my $tests = 16; # keep on line 17 for ,i (increment and ,d (decrement)

plan tests => $tests;
my ($obj, $cond, $manip) = gen_cond('frontmost_application_if');
lives_ok { $cond->add_bundle_identifiers('one', 'two', 'three'); } 'some description';
my $cond2;
lives_ok {$cond2 = $manip->add_condition('frontmost_application_unless') } 'some description';
lives_ok {$cond2->add_bundle_identifiers('four', 'five', 'six') } 'some description';
lives_ok {$cond2->add_description('hello') } 'some description';
lives_ok {$cond2->add_file_paths('paths', 'one', 'two') } 'some description';
my $cond3;
lives_ok {$cond3 = $manip->add_condition('device_if') } 'some description';
lives_ok {$cond3->add_identifier('vendor_id' => 5, 'product_id' => 2222) } 'some description';
lives_ok {$cond3->add_identifier('vendor_id' => 9, 'product_id' => 2000) } 'some description';
lives_ok {$cond3->add_description('describe me!') } 'some description';
my $cond4;
lives_ok {$cond4 = $manip->add_condition('keyboard_type_if') } 'some description';
lives_ok {$cond4->add_keyboard_types('key1', 'key2') } 'some description';
lives_ok {$cond4->add_description('sloopy joe') } 'some description';
my $cond5;
lives_ok {$cond5 = $manip->add_condition( 'variable_if' ) } 'some description';
lives_ok {$cond5->add_variable('one' => 'two') } 'some description';
my $cond6;
lives_ok {$cond6 = $manip->add_condition( 'event_changed_if' ) } 'some description';
lives_ok {$cond6->add_value( 'true' ) } 'some description';
$obj->_dump_json;
