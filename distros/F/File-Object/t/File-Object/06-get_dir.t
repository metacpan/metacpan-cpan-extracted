use strict;
use warnings;

use File::Object;
use Test::More 'tests' => 7;
use Test::NoWarnings;

# Test.
my $obj = File::Object->new;
is($obj->get_dir, 'File-Object', 'Directory of running script.');

# Test.
is($obj->get_dir(1), 'File-Object', 'Directory of running script.');

# Test.
$obj = File::Object->new(
	'dir' => ['1', '2'],
	'type' => 'dir',
);
is($obj->get_dir, '2', 'Directory sets by constructor.');

# Test.
$obj = File::Object->new(
	'file' => 'file',
	'dir' => [],
	'type' => 'file',
);
is($obj->get_dir, undef, 'Undefined directory.');

# Test.
$obj = File::Object->new(
	'file' => 'file',
	'dir' => ['dir', 'subdir'],
	'type' => 'file',
);
is($obj->get_dir, 'subdir', 'Directory sets by constructor.');

# Test.
is($obj->get_dir(2), 'dir', 'Parent directory sets by constructor.');
