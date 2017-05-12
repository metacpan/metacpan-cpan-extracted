# Pragmas.
use strict;
use warnings;

# Modules.
use File::Object;
use File::Spec::Functions qw(catdir catfile);
use Test::More 'tests' => 9;
use Test::NoWarnings;

# Test.
my $obj = File::Object->new(
	'dir' => [1, 2, 3],
	'file' => 'ex1.txt',
	'type' => 'file',
);
is($obj->s, catfile('1', '2', '3', 'ex1.txt'),
	'(dir+file) Serialization of path in constructor values.');
$obj->file('ex2.txt');
is($obj->s, catfile('1', '2', '3', 'ex2.txt'),
	'(dir+file) Serialization of path with changed filename.');
$obj->set->file('ex1.txt');
is($obj->s, catfile('1', '2', '3', 'ex1.txt'), 
	'(dir+file) Set constructor values. Serialization of path with '.
	'changed filename.');
$obj->reset;
is($obj->s, catfile('1', '2', '3', 'ex2.txt'),
	'(dir+file) Reset constructor values. '.
	'Serialization of path in constructor values.');

# Test.
$obj = File::Object->new(
	'dir' => [1, 2, 3],
	'type' => 'dir',
);
is($obj->s, catdir('1', '2', '3'),
	'(dir) Serialization of path in constructor values.');
$obj->dir('4');
is($obj->s, catdir('1', '2', '3', '4'),
	'(dir) Serialization of path with added directory.');
$obj->set->up;
is($obj->s, catdir('1', '2', '3'), 
	'(dir) Set constructor values. Serialization of path with upper '.
	'directory.');
$obj->reset;
is($obj->s, catdir('1', '2', '3', '4'), '(dir) Reset constructor values. '.
	'Serialization of path in constructor values.');
