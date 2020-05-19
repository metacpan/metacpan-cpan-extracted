#/usr/bin/env perl
use Test::Most;
use JSON::Karabiner::Manipulator;
do 't/utility_funcs.pl';












my $tests = 1; # keep on line 17 for ,i (increment and ,d (decrement)

plan tests => $tests;

my $file = glob('~/test_file881.json');

unlink $file;

set_filename 'test_file881.json';
set_save_dir glob('~/');
set_rule_name('some description');
new_manipulator;
add_action('from');
add_key_code('x');
write_file('some title');

is (-f $file, 1, 'writes the file');

unlink $file;
