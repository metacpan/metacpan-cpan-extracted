#/usr/bin/env perl
use Test::Most;
use JSON::Karabiner;
do 'utility_funcs.pl';












my $tests = 2; # keep on line 17 for ,i (increment and ,d (decrement)

plan tests => $tests;

SKIP: {
  skip 'no needed yet', 2, 1; 

# test that it dies if file not passed
my $obj;
$obj = JSON::Karabiner->new('some_title', 'file.json', {mod_file_dir => '/tmp'});
my $rule = $obj->add_rule('some rule');

my $manip = $rule->add_manipulator;

my $from = $manip->add_action('from');
$from->add_optional_modifiers('any');

dies_ok {$obj->write_file} 'catches modifiers without keys';
throws_ok {$obj->write_file} qr/modifiers/, 'throws correct error';
$obj->_dump_json;
}
