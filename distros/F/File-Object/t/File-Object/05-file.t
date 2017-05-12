# Pragmas.
use strict;
use warnings;

# Modules.
use File::Object;
use File::Spec::Functions qw(catfile);
use Test::More 'tests' => 7;
use Test::NoWarnings;

# Test.
my $obj = File::Object->new;
my $ret = $obj->file;
isa_ok($ret, 'File::Object');

# Test.
$obj = File::Object->new(
	'file' => 'file',
	'dir' => ['dir'],
	'type' => 'file',
);
$ret = $obj->file('subdir', 'other_file')->s;
my $right_ret = catfile('dir', 'subdir', 'other_file');
is($ret, $right_ret, 'Test for file() on file with subdir and other_file.');

# Test.
$obj = File::Object->new(
	'file' => 'file',
	'dir' => ['dir'],
	'type' => 'file',
);
$ret = $obj->file('other_file')->s;
$right_ret = catfile('dir', 'other_file');
is($ret, $right_ret, 'Test for file() on file with other_file.');

# Test.
$obj = File::Object->new(
	'file' => 'file',
	'dir' => ['dir'],
	'type' => 'file',
);
$ret = $obj->file(undef, 'other_file')->s;
$right_ret = catfile('dir', 'other_file');
is($ret, $right_ret, 'Test for file() on file with undef subdir and '.
	'other_file.');

# Test.
$obj = File::Object->new(
	'dir' => ['dir'],
	'type' => 'dir',
);
$ret = $obj->file('other_file')->s;
$right_ret = catfile('dir', 'other_file');
is($ret, $right_ret, 'Test for file() on directory with other_file.');

# Test.
$obj = File::Object->new(
	'dir' => ['dir'],
	'type' => 'dir',
);
$ret = $obj->file('subdir', 'other_file')->s;
$right_ret = catfile('dir', 'subdir', 'other_file');
is($ret, $right_ret, 'Test for file() on directory with subdir and '.
	'other_file.');
