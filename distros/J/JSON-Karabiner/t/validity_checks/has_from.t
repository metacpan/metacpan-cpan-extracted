#/usr/bin/env perl
use Test::Most;
use JSON::Karabiner;
do 'utility_funcs.pl';












my $tests = 3; # keep on line 17 for ,i (increment and ,d (decrement)

plan tests => $tests;

# test that it dies if file not passed
my $obj;
$obj = JSON::Karabiner->new('some_title', 'file.json', {mod_file_dir => "$ENV{HOME}/"});
my $rule = $obj->add_rule('some rule');

my $manip = $rule->add_manipulator;

my $to = $manip->add_action('to');

dies_ok {$obj->_fake_write_file} 'catches manipulator with key';
throws_ok {$obj->_fake_write_file} qr/no 'from'/i, 'throws correct error';

my $from = $manip->add_action('from');
throws_ok {$obj->_fake_write_file} qr/'from'.*is empty/i, 'throws correct error';



$obj->_dump_json;
