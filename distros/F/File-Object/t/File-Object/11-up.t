# Pragmas.
use strict;
use warnings;

# Modules.
use English qw(-no_match_vars);
use File::Object;
use Test::More 'tests' => 14;
use Test::NoWarnings;

# Test.
my $obj = File::Object->new;
my $ret = $obj->up;
isa_ok($ret, 'File::Object');
is($ret->get_dir, 't', 'Test script parent directory.');

# Test.
$obj = File::Object->new;
$ret = $obj->up(1);
isa_ok($ret, 'File::Object');
is($ret->get_dir, 't', 'Test script parent directory.');

# Test.
$ret = $obj->reset->up('BAD_NUMBER');
isa_ok($ret, 'File::Object');
is($ret->get_dir, 't', 'Test script parent directory.');

# Test.
$ret = $obj->reset->up(0);
isa_ok($ret, 'File::Object');
is($ret->get_dir, 't', 'Test script parent directory.');

# Test.
$ret = $obj->reset->up(-1);
isa_ok($ret, 'File::Object');
is($ret->get_dir, 't', 'Test script parent directory.');

# Test.
$obj = File::Object->new(
	'dir' => ['dir'],
	'type' => 'dir',
);
eval {
	$obj->up(2);
};
is($EVAL_ERROR, "Cannot go up.\n", 'Cannot go to upper directory.');

# Test.
$obj = File::Object->new(
	'dir' => ['dir', 'subdir'],
	'file' => 'file',
	'type' => 'file',
);
is($obj->up->get_dir, 'dir', 'Parent directory.');

# Test.
$obj = File::Object->new(
	'dir' => ['dir'],
	'file' => 'file',
	'type' => 'file',
);
eval {
	$obj->up;
};
is($EVAL_ERROR, "Cannot go up.\n", 'Cannot go to upper directory.');
