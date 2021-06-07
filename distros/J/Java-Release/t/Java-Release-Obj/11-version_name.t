use strict;
use warnings;

use Java::Release::Obj;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Java::Release::Obj->new(
	arch => 'i386',
	os => 'linux',
	release => 1,
);
my $ret = $obj->version_name;
is($ret, 'Java 1 GA', 'Get version name (only release).');

# Test.
$obj = Java::Release::Obj->new(
	arch => 'i386',
	os => 'linux',
	release => 1,
	update => 234,
);
$ret = $obj->version_name;
is($ret, 'Java 1 Update 234', 'Get version name (release and update).');

# Test.
$obj = Java::Release::Obj->new(
	arch => 'i386',
	os => 'linux',
	interim => 3,
	release => 1,
	update => 234,
);
$ret = $obj->version_name;
is($ret, 'Java 1 Major 3 Update 234', 'Get version name (release, interim and update).');
