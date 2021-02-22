use strict;
use warnings;

use File::Object;
use File::Spec::Functions qw(catdir);
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = File::Object->new;
my $ret = $obj->dir;
isa_ok($ret, 'File::Object');

# Test.
$obj = File::Object->new(
	'dir' => ['dir'],
	'type' => 'dir',
);
$ret = $obj->dir('subdir', undef)->s;
my $right_ret = catdir('dir', 'subdir');
is($ret, $right_ret, 'Test for dir() with subdir and undef.');
