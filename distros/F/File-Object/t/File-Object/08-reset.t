use strict;
use warnings;

use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use File::Object;
use File::Spec::Functions qw(catdir catfile splitdir);
use FindBin qw($Bin $Script);
use Test::More 'tests' => 18;
use Test::NoWarnings;

# Test.
my $obj = File::Object->new(
	'type' => 'dir',
);
my $right_ret1 = catdir(splitdir($Bin));
is($obj->s, $right_ret1, 'Directory of running directory.');
$obj->dir('subdir');
my $right_ret2 = catdir(splitdir($Bin), 'subdir');
is($obj->s, $right_ret2, 'Actual directory with subdirectory.');
$obj->reset;
is($obj->s, $right_ret1, 'Directory of running script.');

# Test.
$obj = File::Object->new(
	'dir' => ['dir1'],
	'type' => 'dir',
);
is($obj->s, 'dir1', 'Directory defined in constructor.');
$obj->dir('dir2');
is($obj->s, catdir('dir1', 'dir2'), 'Directory with subdirectory.');
$obj->reset;
is($obj->s, 'dir1', 'Directory defined in constructor.');

# Test.
$obj = File::Object->new(
	'dir' => ['dir1'],
	'type' => 'dir',
);
is($obj->s, 'dir1', 'Directory defined in constructor.');
$obj->file('file1');
is($obj->s, catdir('dir1', 'file1'), 'Directory with file.');
$obj->reset;
is($obj->s, 'dir1', 'Directory defined in constructor.');
$obj->file('file1');
is($obj->s, catdir('dir1', 'file1'), 'Directory with file after reset.');

# Test.
$obj = File::Object->new(
	'type' => 'file',
);
is($obj->s, catfile($Bin, $Script), 'Running file.');
$obj->file('other_file');
is($obj->s, catfile($Bin, 'other_file'), 'Other file in actual directory.');
$obj->reset;
is($obj->s, catfile($Bin, $Script), 'Running file.');

# Test.
eval {
	File::Object->new(
		'dir' => ['dir'],
		'file' => undef,
		'type' => 'file',
	);
};
is($EVAL_ERROR, "Bad file constructor with undefined 'file' parameter.\n",
	'Bad \'File::Object\' file constructor.');
clean();

# Test.
$obj = File::Object->new(
	'dir' => ['dir'],
	'file' => 'file',
	'type' => 'file',
);
is($obj->s, catfile('dir', 'file'), 'Path to file defined in constructor.');
$obj->file('other_file');
is($obj->s, catfile('dir', 'other_file'), 'Path to other file.');
$obj->reset;
is($obj->s, catfile('dir', 'file'), 'Path to file defined in constructor.');
