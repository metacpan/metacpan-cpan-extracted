use strict;
use warnings;

use Java::Release::Obj;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Java::Release::Obj->new(
	arch => 'i386',
	os => 'linux',
	release => 1,
);
my $ret = $obj->patch;
is($ret, undef, 'Get patch version number (not defined).');

# Test.
$obj = Java::Release::Obj->new(
	arch => 'i386',
	os => 'linux',
	patch => 1,
	release => 1,
);
$ret = $obj->patch;
is($ret, 1, 'Get patch version number (defined).');
