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
my $ret = $obj->update;
is($ret, undef, 'Get update version number (not defined).');

# Test.
$obj = Java::Release::Obj->new(
	arch => 'i386',
	os => 'linux',
	release => 1,
	update => 234,
);
$ret = $obj->update;
is($ret, 234, 'Get update version number (defined).');
