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
my $ret = $obj->interim;
is($ret, undef, 'Get interim version number (not defined).');

# Test.
$obj = Java::Release::Obj->new(
	arch => 'i386',
	interim => 0,
	os => 'linux',
	release => 1,
);
$ret = $obj->interim;
is($ret, 0, 'Get interim version number (defined).');
