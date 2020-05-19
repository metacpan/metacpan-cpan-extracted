#/usr/bin/env perl
use Test::Most;
use JSON::Karabiner;
do 'utility_funcs.pl';












my $tests = 2; # keep on line 17 for ,i (increment and ,d (decrement)

plan tests => $tests;

# test that it dies if file not passed
my $obj;
dies_ok { $obj = JSON::Karabiner->new('some_title', 'file.json', { mod_file_dir => '/this/does/not/exist' } ); } 'dies when directory does not exist';


throws_ok { $obj = JSON::Karabiner->new('some_title', 'file.json', { mod_file_dir => '/this/does/not/exist' } ) } qr/directory.*does not exist/,  'throws proper warning'
